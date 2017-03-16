--
-- Created by IntelliJ IDEA.
-- User: guang
-- Date: 2016-12-13
-- Time: 20:54

-- 总超时时间
TIMEOUT = 3000
-- 所有服务器都连接上才可执行脚本
GO_WITH_ALL_DONE = true
-- 初始化时等待SSH连接完成再返回
WAIT_CONN_INIT = false

local zabbix={
    host="192.168.18.200",
    web={
        user = "Admin",
        pass = "zabbix",
    },
    mysqlcfg = {
        host = "192.168.18.200",
        port = "0",
        db = "zabbix",
        user = "zabbix",
        pass = "zabbix123",
        root_user = "root",
        root_pass = "abcdefg",
        sock = "/var/lib/mysql/mysql.sock"
    }
}
-- 服务器列表定义
SERVERS = {
    -- [[
    zabbixhost = { ip = "192.168.18.200", port = 22, user = "root", auth = "pw", passwd= "123", timeout = 2,
        st="file", script = "./books/zabbix/install_zabbix.lua", },
    mysqlhost = { ip = "192.168.18.200", port = 22, user = "root", auth = "pw", passwd= "123", timeout = 2,
        st="file", script = "./books/zabbix/install_mysql.lua", },
    nginxhost = { ip = "192.168.18.200", port = 22, user = "root", auth = "pw", passwd= "123", timeout = 2,
        st="file", script = "./books/zabbix/install_nginx_php.lua", },
        --]]
    agenthost={ ip = "192.168.18.201", port = 22, user = "root", auth = "pw", passwd= "123", timeout = 2,
        st="file", script = "./books/zabbix/custem_item_test.lua", },
}

-- 创建playlist
pl1 = playlist()

-- 完成服务器列表初始化
if not pl1:Init(SERVERS, zabbix, TIMEOUT, WAIT_CONN_INIT) then
    -- 尝试开始执行各服务器对应的Lua文件
    pl1:Start(GO_WITH_ALL_DONE)
end



