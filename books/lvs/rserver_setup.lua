--
-- Created by IntelliJ IDEA.
-- User: guang
-- Date: 2017-01-08
-- Time: 14:39

--[[
arp_annouce：Define different restriction levels for announcing the local source IP address from IP packets in ARP requests sent on interface；
0 - (default) Use any local address, configured on any interface.
1 - Try to avoid local addresses that are not in the target's subnet for this interface.
2 - Always use the best local address for this target. -- <==总是使用最佳本地地址-- 发送ARP通告时，(如果有多个接口/IP)只在网络上通告与之相匹配的最佳地址

arp_ignore: Define different modes for sending replies in response to received ARP requests that resolve local target IP address.
0 - (default): reply for any local target IP address, configured on any interface.
1 - reply only if the target IP address is local address configured on the incoming interface. -- <== 只响应目标IP地址是配置在请求进入的接口上的ARP请求
2 - reply only if the target IP address is local address configured on the incoming interface and both with the sender's IP address are part from same subnet on this interface.
3 - do not reply for local address configured with scope host, only resolutions for golbal and link addresses are replied.
4-7 - reserved
8 - do not reply for all local addresse
--]]
require("./books/common")

Cmd("uname -r")
local version = ERR.Msg

if version >= "2.6" then
    local msg = HOST:Wait({})
    local vip = msg.Msg.info.vip
    local type = msg.Msg.info.type
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
end

