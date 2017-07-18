--
-- User: iaai
-- Date: 17-5-9
-- Time: 下午2:06
--

require "books/common"

redis = {}

function redis:new(o)
    o = o or {
        ip = HOST.Ip,
        port = 6379,

    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function redis:yuminstall()
    Cmd("service redis status")
    if ERR.Code ~= 0 then
        InstallEPEL()
        Cmd{
            "yum -y install redis",
            "iptables -I INPUT 2 -p tcp --dport "..self.port.." -j ACCEPT",
        }
        Setfkv("/etc/redis.conf", "bind", "0.0.0.0", false)
    end
end

function redis:start()
    Cmd("service redis status")
    if ERR.Code ~=0 then
        Cmd("service redis start")
    end
end


