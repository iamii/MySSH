--
-- Created by IntelliJ IDEA.
-- User: guang
-- Date: 2016-12-31
-- Time: 20:48
--
require("./books/common")

require([[./books/elk/elasticsearch_source_install]])
require([[./books/elk/logstash_source_install]])
require([[./books/elk/kibana_source_install]])

local logstash_ip = HOST.Ip
-- [====[
local e = elasticsearch:new({pdir="/opt/", version="elasticsearch-5.1.1"})
if not e:installed() then
    e:install()
    e:run()
end

local k = kibana:new()
if not k:installed() then
    k:install()
    k:run()
    k:install_nginx()
end

local nginx_pattern = [[
    NGUSERNAME [a-zA-Z\.\@\-\+_%]+
    NGUSER %{NGUSERNAME}
    NGINXACCESS %{IPORHOST:clientip} - %{NOTSPACE:remote_user} \[%{HTTPDATE:timestamp}\] \"(?:%{WORD:verb} %{NOTSPACE:request}(?: HTTP/%{NUMBER:httpversion})?|%{DATA:rawrequest})\" %{NUMBER:response} (?:%{NUMBER:bytes}|-) %{QS:referrer} %{QS:agent} %{NOTSPACE:http_x_forwarded_for}
    ]]

local nginx_access_log = [[
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

local l = logstash:new()
if not l:installed() then
    l:install()
    l:addpattern("nginx", nginx_pattern)
    l:addconf("test_nginx", nginx_access_log)

    --]====]
    -- 交换证书
    Download("/etc/pki/tls/certs/"..logstash_ip..".crt", logstash_ip..".crt")
    HOST:Send({dst = "fbclient", info = { key = "IP", value = logstash_ip }})
    l:runconf("test_nginx")
    Cmd("iptables -I INPUT 1 -p tcp --dport 5043 -m state --state NEW -j ACCEPT")
end
