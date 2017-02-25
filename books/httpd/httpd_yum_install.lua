--
-- Created by IntelliJ IDEA.
-- User: guang
-- Date: 2016-12-20
-- Time: 09:21
-- To change this template use File | Settings | File Templates.
--
local cmds = {
    "yum install httpd -y",
    "service httpd restart",
    "setenforce 0",
    [[iptables -I INPUT -p tcp -d ]]..HOST.Ip..[[ --dport 80 -j ACCEPT]],
}

HOST:Cmd(cmds)

