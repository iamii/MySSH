--
-- Created by IntelliJ IDEA.
-- User: guang
-- Date: 2016-12-13
-- Time: 20:54
require("books/heartbeat/heartbeat")

local h = hb:new()

-- 添加节点
local nodes = {
    test0 = { ip = "192.168.18.200", port = 22,
        user = "root", auth = "pw", passwd= "123", keyfile = "test",
        timeout = 2, script = "", st="file"},
    test1 = { ip = "192.168.18.201", port = 22,
        user = "root", auth = "pw", passwd= "123", keyfile = "test",
        timeout = 2, script = "", st="file"},
    test2 = { ip = "192.168.18.202", port = 22,
        user = "root", auth = "pw", passwd= "123", keyfile = "test",
        timeout = 2, script = "", st="file"},
    --[[
    test3 = { ip = "192.168.18.203", port = 22,
        user = "root", auth = "pw", passwd= "123", keyfile = "test",
        timeout = 2, script = "", st="file"},
    test4 = { ip = "192.168.18.204", port = 22,
        user = "root", auth = "pw", passwd= "123", keyfile = "test",
        timeout = 2, script = "", st="file"},
        --]]
}

h:addnodes(nodes)

-- [=[
-- 在所有节点上配置相应的hosts信息
h:sethostnames()

-- 在所有节点上更新时间
h:ntpdate()

-- 所有节点章交换密钥
h:exchangekeys()

-- 添加集群资源
h:addresource("test0", "IPaddr::192.168.18.100/24/eth0:1/")
h:addresource("test0", "httpd")

-- -- 修改ha.cf文件配置
h:sethacf("logfile", "/var/log/ha-log")
h:sethacf("logfacility", "local0")
h:sethacf("keepalive", "3")
h:sethacf("deadtime", "10")
h:sethacf("warntime", "6")
h:sethacf("initdead", "120")
 -- h:sethacf("udpport", "694", false)
h:sethacf("bcast", "eth0")
h:sethacf("ping", "192.168.18.1")
h:sethacf("auto_failback", "on")
h:sethacf("watchdog", "/dev/watchdog")

-- -- 修改authkeys文件
h:setauthkeys("md5", "Hello!")

-- --
h:install()

h:start()

--]=]
