require ("books/zabbix/zabbix")

local msg = HOST:Wait({src="playlist"})
local zabbixcfg = msg.Msg.info

HOST:Wait({src="nginxhost"})

local zbx, err = zabbix:new(zabbixcfg)

assert(not err, "访问zabbix API失败")

-- 创建主机
local res = zbx:createHostWithIp(
    "test server", "192.168.18.201", "10050",
    {"Zabbix servers", "Linux servers"}, -- 群组
    {"Template App MySQL", "Template ICMP Ping" } -- 模板
    )

assert(not err, "创建zabbix host失败")
-- 自定义监控项
local res = zabbix:createCustomItem(
    "test server", "check process", "check_process[sshd,22]",
    "Zabbix agent", "numeric unsigned", nil, 30)
-- print(res)

-- --------------------------------------------
--      安装zabbix_agent
zbx:yumInstallAgent()

--      在zabbix_agentd.conf文件中定义UserParameter
local userparameter = "check_process[*]"
local command = "/usr/bin/python /tmp/process_port.py $1 $2"
Upload([[./books/zabbix/process_port.py]], "/tmp/process_port.py")
zbx:addCustem(userparameter, command)
zbx:agentd_conf("Server", zabbixcfg.host)
zbx:agentd_conf("ServerActive", zabbixcfg.host)

zbx:startAgent()
