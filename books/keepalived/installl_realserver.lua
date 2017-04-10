require("./books/common")

if GetLinuxVersion().ker >= "2.6" then
    local msg = PLAYLISTINFO
    --[=[
    local tsVs, tsRs

    for k, v in pairs(info.ct) do
        for t in string.gmatch(k, "virtual_server %w+%.%w+%.%w+%.%w+ %d+") do
            local vs =
        end

    end

    --]=]
    local vip = string.split(msg.vservice, ":")[1]
    local type = msg.lvs_type
    -- [=[
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

    Cmd{
        [[yum -y install httpd && service httpd restart && service iptables stop && echo "]]..HOST.Ip..[[" > /var/www/html/index.html]],
    }
    --]=]
end

