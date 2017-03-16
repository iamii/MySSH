--
-- Created by IntelliJ IDEA.
-- User: guang
-- Date: 2016-12-17
-- Time: 21:42
--
require("./books/common")

nginx = {}

function nginx:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    return o
end

function nginx:yumInstall()
    Cmd("service nginx status")
    if ERR.Code ~= 0 then
        InstallEPEL()
        Cmd{
            "yum install nginx -y",
            "service nginx restart",
            "iptables -I INPUT 1 -p tcp --dport 80 -m state --state NEW -j ACCEPT",
        }
    end
end




