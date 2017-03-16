--
-- User: iaai
-- Date: 17-3-10
-- Time: 下午3:56
--
-- 安装配置mysql
require ("books/mysql/mysql")

local msg = HOST:Wait({src="playlist"})

local zabbix = msg.Msg.info

local m = mysql:new(zabbix.mysqlcfg)
m:yumInstall()
m:secure_installation()

local t = zabbix.mysqlcfg.host
zabbix.mysqlcfg.host = "localhost"
m:createdb(zabbix.mysqlcfg.db)
m:grant(
    "*.*",
    zabbix.mysqlcfg.root_user,
    zabbix.host,
    "all privileges",
    zabbix.mysqlcfg.root_pass
)

m:grant(
    zabbix.mysqlcfg.db..".*",
    zabbix.mysqlcfg.user,
    zabbix.host,
    "all privileges",
    zabbix.mysqlcfg.pass
)



zabbix.mysqlcfg.host = t
HOST:Send({dst = "zabbixhost", info="done"})
