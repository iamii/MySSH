-- 通过yum安装zabbix

require ("books/zabbix/zabbix")

local zabbixcfg = PLAYLISTINFO
local z = zabbix:new(zabbixcfg)
-- [[
HOST:Wait({src="mysqlhost"})

z:yumInstallServer()
z:yumInstallAgent()
--]]
z:conf_php()
z:startServer()

-- 如果nginx和zabbix不安装在同一服务器，可以不用“同步”,主要是防止yum锁
HOST:Send({dst="nginxhost", info="done"})
