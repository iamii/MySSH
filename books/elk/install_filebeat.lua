--
-- -----------------
-- install nginx for test only
require("books/nginx/nginx")
local n=nginx:new()
n:yumInstall()
-- -------------------
require("books/common")
require("books/elk/filebeat")

Ntpdate()

local logstash_ip

local fb = filebeat:new({pdir="/opt/", version="filebeat-5.4.1-linux-x86_64"})
if not fb:installed() then
    fb:binInstall()
end
-- [[
--复制logstash证书，下载到本地，再上传，；也可以，直接scp，或cat 再 echo
local msg = HOST:Wait({src="elkserver"})
if msg.Msg.info.key == "IP" then
    logstash_ip = msg.Msg.info.value
else
    print("未收到期望的消息")
    os.exe()
end

Upload(logstash_ip..".crt","/etc/pki/tls/certs/"..logstash_ip..".crt")

fb.templ.output.logstash.ssl.certificate_authorities = {"/etc/pki/tls/certs/"..logstash_ip..".crt", }
fb.templ.output.logstash.hosts[1] = logstash_ip..":5043"

fb:addconf("nginx_logs")
--]]

fb:runconf("nginx_logs")
