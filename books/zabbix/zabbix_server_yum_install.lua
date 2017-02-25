--
-- Created by IntelliJ IDEA.
-- User: guang
-- Date: 2016-12-17
-- Time: 21:52
--

assert(mysql_host, "mysql主机名/IP未定义")
assert(mysql_user, "mysql用户名未定义")
assert(mysql_sock, "mysql sock路径未定义")
assert(zabbix_host, "zabbix主机名/IP未定义")
assert(zabbix_pass, "zabbix数据库连接密码未定义")


local zabbix_yum = "http://repo.zabbix.com/zabbix/3.0/rhel/6/x86_64/zabbix-release-3.0-1.el6.noarch.rpm"
local cmds = {
    "rpm -ivh ".. zabbix_yum,
    "yum install zabbix-server-mysql zabbix-web-mysql -y",

    [[mysql -h]]..mysql_host..[[ -u]]..mysql_user..[[ -p]]..mysql_pass..[[ -e "create database zabbix character set utf8 collate utf8_bin;"]],
    [[mysql -h]]..mysql_host..[[ -u]]..mysql_user..[[ -p]]..mysql_pass..[[ -e "grant all privileges on zabbix.* to zabbix@]]..zabbix_host..[[ identified by ']]..zabbix_pass..[[';"]],
    [[cd /usr/share/doc/zabbix-server-mysql-3* && zcat create.sql.gz | mysql -h ]]..mysql_host..[[ -u]]..mysql_user..[[ -p]]..mysql_pass.." zabbix",

    [=[sed -i "s/#[[:space:]]\(DBHost=localhost\)/\1/" /etc/zabbix/zabbix_server.conf ]=],
    [=[sed -i "s/#[[:space:]]\(DBPassword=\)/\1]=]..zabbix_pass..[=[/" /etc/zabbix/zabbix_server.conf]=],
    [=[sed -ri "s@#[[:space:]](DBSocket=).*@\1]=]..mysql_sock..[=[@" /etc/zabbix/zabbix_server.conf]=],

    [[ setenforce 0 && service zabbix-server restart && chmod 755 -R /etc/zabbix/web/]],
    [[iptables -I INPUT -d ]]..HOST.Ip..[[ --dport 10051 -j ACCEPT]],
}
HOST:Cmd(cmds)
