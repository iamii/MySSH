--
-- Created by IntelliJ IDEA.
-- User: guang
-- Date: 2017-01-07
-- Time: 16:21
--

require("books/common")

lvs = {
    --[[
    --services = {lvsinstance1, lvsinstance2}
    --]]
    services={},
}

function lvs:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function lvs:add_services(tag, service)
    self.services[tag]=service
end

function lvs:install_service(tag)
    local ss = {
        dss = [==[
require("./books/lvs/lvsinstance")
local l = lvsinstance:new(PLAYLISTINFO)
l:add_virtual_service()
        ]==],

        rss = [===[
require("./books/common")

if GetLinuxVersion().ker >= "2.6" then
    local msg = PLAYLISTINFO
    local vip = string.split(msg.vservice, ":")[1]
    local type = msg.lvs_type
    if type == "dr" then
        Cmd{
           "/sbin/ifconfig lo down",
           "/sbin/ifconfig lo up",
           "echo 1 > /proc/sys/net/ipv4/conf/lo/arp_ignore",
           "echo 2 > /proc/sys/net/ipv4/conf/lo/arp_announce",
           "echo 1 > /proc/sys/net/ipv4/conf/all/arp_ignore",
           "echo 2 > /proc/sys/net/ipv4/conf/all/arp_announce",
           "/sbin/ifconfig lo:0 "..vip.." broadcast "..vip..
                   " netmask 255.255.255.255 up",
           "/sbin/route add -host "..vip.." dev lo:0",
        }
    elseif type == "nat" then
        print("nat模式，只需要real server的网关指向direcctor server")
    end

    -- [=[
    Cmd{
        [[yum -y install httpd && service httpd restart && service iptables stop && echo "]]..HOST.Ip..[[" > /var/www/html/index.html]],
    }
    --]=]
end
        ]===]
    }
    local service = self.services[tag]
    if service then
        -- dr需要先在director上定义eth0:0
        for _, v in pairs(service.direc_servers) do
            v.st="string"
            v.script = ss.dss
        end
        PL_RUN(service.direc_servers, service)

        for _, v in pairs(service.real_servers) do
            v.st="string"
            v.script = ss.rss
        end

         PL_RUN(service.real_servers, service)
    end
end
