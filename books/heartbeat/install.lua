--
-- Created by IntelliJ IDEA.
-- User: iaai
-- Date: 17-1-20
-- Time: 下午1:43
-- To change this template use File | Settings | File Templates.
--
require("books/common")

local lpath

if os.getenv("OS") == "Windows_NT" then
    lpath = [[D:\Documents\downloads\]]
else
    lpath = [[/home/iaai/Downloads/]]
end

local msg = HOST:Wait({src="playlist"})
local hb = msg.Msg.info


if hb.version == "3.0.4" then
    local epel_rpm = "epel-release-6-8.noarch.rpm"
    Upload(lpath..epel_rpm, "/opt/"..epel_rpm)

    -- yum install heartbeat
    Cmd{
        "rpm -ivh /opt/"..epel_rpm,
        "yum -y install heartbeat-"..hb.version,
        "cd /usr/share/doc/heartbeat-"..hb.version..
                " && cp  ha.cf haresources authkeys /etc/ha.d/ && chmod 600 /etc/ha.d/authkeys",
    }

    -- edit /etc/ha.d/ha.cf
    for k, v in pairs(hb.hacf) do
        Setfkv("/etc/ha.d/ha.cf", k, v, false)
    end

    for k, _ in pairs(hb.nodes) do
        Setfkv("/etc/ha.d/ha.cf", "node", k, true)
    end

   -- edit /etc/ha.d/haresources
    for host, res in pairs(hb.resources) do
        Setfkv("/etc/ha.d/haresources", host, res, true)
    end

    -- /etc/ha.d/authkeys
    Setfkv("/etc/ha.d/authkeys", "auth", hb.authkeys["authNum"], true)
    Setfkv("/etc/ha.d/authkeys", hb.authkeys["authNum"],
        hb.authkeys["authType"].." "..hb.authkeys["authKey"], true)

end
