--
-- Created by IntelliJ IDEA.
-- User: iaai
-- Date: 17-1-20
-- Time: 下午1:43
-- To change this template use File | Settings | File Templates.
--
require("books/common")

local hb = PLAYLISTINFO


if hb.version == "3.0.4" then
    InstallEPEL()

    -- yum install heartbeat
    Cmd{
        "yum -y install PyXML cluster-glue cluster-glue-libs resource-agents heartbeat-"..hb.version,
        "cd /usr/share/doc/heartbeat-"..hb.version..
                " && cp  ha.cf haresources authkeys /etc/ha.d/ && chmod 600 /etc/ha.d/authkeys",
    }

    -- edit /etc/ha.d/ha.cf
    for k, v in pairs(hb.hacf) do
        Setfkv("/etc/ha.d/ha.cf", k, v, false, nil, "#")
    end

    for k, _ in pairs(hb.nodes) do
        Setfkv("/etc/ha.d/ha.cf", "node", k, true, nil, "#")
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
