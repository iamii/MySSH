--
-- -------------------
require("books/common")
require("books/elk/metricbeat")

Cmd("yum -y install ntpdate && ntpdate ntp.ubuntu.com ")

local logstash_ip

local mb = metricbeat:new({pdir="/opt/", version="metricbeat-5.2.2-linux-x86_64"})
if not mb:installed() then
    mb:binInstall()
end
-- [[
local msg = HOST:Wait({src="elkserver"})
if msg.Msg.info.key == "IP" then
    logstash_ip = msg.Msg.info.value
else
    print("未收到期望的消息")
    os.exe()
end

Upload(logstash_ip..".crt","/etc/pki/tls/certs/"..logstash_ip..".crt")

mb.templ.output.logstash.ssl.certificate_authorities = {"/etc/pki/tls/certs/"..logstash_ip..".crt", }
mb.templ.output.logstash.hosts[1] = logstash_ip..":5044"

mb:addconf("sys_logs")
--]]

mb:runconf("sys_logs")
