--
-- Created by IntelliJ IDEA.
-- User: guang
-- Date: 2017-01-07
-- Time: 17:17
--

require("./books/lvs/lvs")

local l = lvs:new()

-- l.dip  =   HOST.Ip..":80"
l.vservice  = "192.168.18.100:80"
l.scheduler = "rr"
l.service_type= "tcp"

local real_servers = {
    {service="192.168.18.111:80", weight=1},
    {service="192.168.18.112:80", weight=2},
}

for k, v in pairs(real_servers) do
    l:add_real_server(v)
end
-- l:add_service("nat")
l:setpersistent(30)
l:add_service("dr")
l:list_service()

HOST:Send({info={type="dr", vip=string.split(l.vservice, ":")[1]}})
print("===========dserver done=========")
