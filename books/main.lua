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

-- 服务器列表定义
-- 服务器列表定义
SERVERS = {

    bes1 = { ip = "192.168.18.201", port = 22, user = "root", auth = "pw", passwd= "123", timeout = 2, st="file",
        script = "./books/tomcat/tomcatsetup.lua", },
    bes2 = { ip = "192.168.18.202", port = 22, user = "root", auth = "pw", passwd= "123", timeout = 2, st="file",
        script = "./books/tomcat/tomcatsetup.lua", },
    nginx1 = { ip = "192.168.18.200", port = 22, user = "root", auth = "pw", passwd= "123", timeout = 2, st="file",
        script = "./books/nginx/test_nginx.lua", },
    redis1 = { ip = "192.168.18.203", port = 22, user = "root", auth = "pw", passwd= "123", timeout = 2, st="file",
        script = "./books/redis/test_redis.lua", },
}

-- 创建playlist
pl1 = playlist()

-- 完成服务器列表初始化
if not pl1:Init(SERVERS, nil, TIMEOUT, WAIT_CONN_INIT) then
    -- 尝试开始执行各服务器对应的Lua文件
    pl1:Start(GO_WITH_ALL_DONE)
end

