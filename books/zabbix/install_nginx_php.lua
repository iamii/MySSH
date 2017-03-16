--
-- User: iaai
-- Date: 17-3-10
-- Time: 下午9:52
--

local zabbix = HOST:Wait({src="playlist"}).Msg.info

-- 源码安装php
require ("books/php/php")
local p = php:new({tarfile="php-5.6.30.tar.gz", prefix="/usr/local/"})
p:srcInstall()

-- 编辑 php.ini 参数
p:setINI("post_max_size", "116M")
p:setINI("max_execution_time", "1300")
p:setINI("max_input_time", "1300")
p:setINI("date.timezone", "Asia/Shanghai")
p:setINI("always_populate_raw_post_data", "-1")
p:setINI("mysqli.default_socket", zabbix.mysqlcfg.sock)

p:runFpm()

-- 如果nginx和zabbix不安装在同一服务器，可以不用“同步”,主要是防止yum锁
HOST:Wait({src="zabbixhost"})
-- 安装nginx
require ("books/nginx/nginx")
local n = nginx:new()
n:yumInstall()

-- test
Cmd{"cp /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.test.bak"}
Upload("./books/zabbix/nginx.test.conf", "/etc/nginx/conf.d/default.conf")
Cmd{[=[sed -i "s/root[[:space:]].*;/root \/usr\/share\/zabbix\/;/" /etc/nginx/conf.d/default.conf]=] }
Cmd{"service nginx restart"}
--]====]

HOST:Send({dst="agenthost", info="done"})
