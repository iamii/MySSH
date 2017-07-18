require ("books/common")

InstallEPEL()
Cmd{ "yum install keepalived ipvsadm -y && iptables -F && iptables -Z", }

local info = PLAYLISTINFO
if type(info.priority) == "table" then
    for k, v in pairs(info.priority) do
        if HOST.Name == k then
            info.ct["vrrp_instance VI_1"].state= v.state
            info.ct["vrrp_instance VI_1"].priority= v.priority
            info.ct.global_defs.router_id = k
        end
    end
end

Cmd{
    [[echo ']]..Table2conf(info.ct)..[[' > /etc/keepalived/keepalived.conf]],
    "service keepalived restart"
}


