-- User: guang
-- Date: 2017-02-27
-- Time: 10:33

-- 总超时时间
TIMEOUT = 3000
-- 所有服务器都连接上才可执行脚本
GO_WITH_ALL_DONE = true
-- 初始化时等待SSH连接完成再返回
WAIT_CONN_INIT = false

-- 服务器列表定义
-- 服务器列表定义
SERVERS = {
    test1 = {
        ip = "192.168.18.200", port = 22,
        user = "root", auth = "pw", passwd= "123", -- keyfile = "test",
        timeout = 2,
        st="file",
        script = "./books/server_log/logtest.lua", },
}

-- 创建playlist
pl1 = playlist()

-- 完成服务器列表初始化
if not pl1:Init(SERVERS, nil, TIMEOUT, WAIT_CONN_INIT) then
    -- 尝试开始执行各服务器对应的Lua文件
    pl1:Start(GO_WITH_ALL_DONE)
end