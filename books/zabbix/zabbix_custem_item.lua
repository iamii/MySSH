require("./books/zabbix")

local zbx, err = zabbix:new{ip="192.168.18.99", user="Admin", pass="zabbix"}

assert(not err, "访问zabbix API失败")

---[====[
-- 创建主机
local res = zbx:createHostWithIp(
    "test server", "192.168.18.111", "10050",
    {"Zabbix servers", "Linux servers"}, -- 群组
    {"Template App MySQL", "Template ICMP Ping" } -- 模板
    )

assert(not err, "创建zabbix host失败")
-- --------------------------------------------
--      安装zabbix_agent
dofile("books\\zabbix_agent_yum_install.lua")

--      在zabbix_agentd.conf文件中定义UserParameter
local zabbix_agentd_conf = "/etc/zabbix/zabbix_agentd.conf"
local userparameter = "check_process[*],/usr/bin/python /tmp/process_port.py $1 $2"

msg = HOST:Cmd{[[grep "UserParameter = check_process" ]]..zabbix_agentd_conf }
if msg.Code == 1 then
    HOST:Cmd{[[echo -e 'UserParameter = ]]..userparameter..[[' >> ]]..zabbix_agentd_conf }
    HOST:Cmd{"service zabbix-agent restart" }
    HOST:PutFile(".\\books\\process_port.py", "/tmp/process_port.py")
end

--]====]
-- 自定义监控项
local res = zabbix:createCustomItem(
    "test server", "check process", "check_process[mysqld,3306]",
    "Zabbix agent", "numeric unsigned", nil,30)
print(res)


