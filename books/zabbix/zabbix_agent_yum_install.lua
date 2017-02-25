--
-- Created by IntelliJ IDEA.
-- User: guang
-- Date: 2016-12-17
-- Time: 21:55
--

local zabbix_yum = "http://repo.zabbix.com/zabbix/3.0/rhel/6/x86_64/zabbix-release-3.0-1.el6.noarch.rpm"
local cmds = {
    "rpm -ivh ".. zabbix_yum,
    "yum install zabbix-agent -y",
}

HOST:Cmd(cmds)