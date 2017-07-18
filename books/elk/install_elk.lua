--
-- Created by IntelliJ IDEA.
-- User: guang
-- Date: 2016-12-31
-- Time: 20:48
--
require("books/common")

require([[books/elk/elasticsearch]])
require([[books/elk/logstash]])
require([[books/elk/kibana]])

Ntpdate()

local logstash_ip = HOST.Ip
-- [====[
local e = elasticsearch:new({pdir="/opt/", version="elasticsearch-5.4.1"})
if not e:binInstall() then
    e:start()
end

local k = kibana:new({pdir="/opt/", version="kibana-5.4.1-linux-x86_64"})
if not k:binInstall() then
    k:run()
    k:install_nginx()
end

local nginx_log = {
    pattern = [[
NGUSERNAME [a-zA-Z\.\@\-\+_%]+
NGUSER %{NGUSERNAME}
NGINXACCESS %{IPORHOST:clientip} - %{NOTSPACE:remote_user} \[%{HTTPDATE:timestamp}\] \"(?:%{WORD:verb} %{NOTSPACE:request}(?: HTTP/%{NUMBER:httpversion})?|%{DATA:rawrequest})\" %{NUMBER:response} (?:%{NUMBER:bytes}|-) %{QS:referrer} %{QS:agent} %{NOTSPACE:http_x_forwarded_for}
]],
    access_log = [[
input {
    beats {
        port => 5043
        ssl => true
        ssl_certificate => "/etc/pki/tls/certs/]]..logstash_ip..[[.crt"
        ssl_key => "/etc/pki/tls/private/]]..logstash_ip..[[.key"
      }
}

filter {
    mutate { replace => { "type" => "nginx_access" } }
    grok {
        match => { "message" => "%{NGINXACCESS}" }
    }
    date {
        match => [ "timestamp" , "dd/MMM/YYYY:HH:mm:ss Z" ]
    }
    geoip {
        source => "clientip"
    }
}

output {
    elasticsearch { hosts => ["localhost:9200"] }
}
]]
}
local metric_log = {
    [[
input {
     beats	{
        port	=>	5044
        ssl => true
        ssl_certificate => "/etc/pki/tls/certs/]]..logstash_ip..[[.crt"
        ssl_key => "/etc/pki/tls/private/]]..logstash_ip..[[.key"
     }
}
output	{
    elasticsearch	{
        hosts	=>	["http://localhost:9200"]
    index	=>	"%{[@metadata][beat]}-%{+YYYY.MM.dd}"
    document_type	=>	"%{[@metadata][type]}"
    }
}
]]
}
local l = logstash:new({pdir = "/opt/", version = "logstash-5.4.1"})
if not l:binInstall() then
    l:addcert()
    l:addpattern("nginx", nginx_log.pattern)
    l:addconf("test_nginx", nginx_log.access_log)
    l:addconf("test_metric", metric_log[1])

    --]====]
    -- 交换证书
    Download("/etc/pki/tls/certs/"..logstash_ip..".crt", logstash_ip..".crt")

    Cmd("iptables -I INPUT 1 -p tcp --dport 5043 -m state --state NEW -j ACCEPT")
    Cmd("iptables -I INPUT 1 -p tcp --dport 5044 -m state --state NEW -j ACCEPT")
    -- import_dashboards
    local lpath = GetLocalPath()
    local bdfile = "beats-dashboards-5.4.1.zip"
    Upload(lpath.."import_dashboards", l.pdir.."import_dashboards")
    Upload(lpath..bdfile, l.pdir..bdfile)
    Cmd{"chmod u+x "..l.pdir.."/import_dashboards && "..l.pdir.."/import_dashboards -file "..l.pdir..bdfile}
end

l:runconf("test_nginx")
l:runconf("test_metric")
HOST:Send({info = { key = "IP", value = logstash_ip }})
