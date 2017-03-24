require ("books/lvs/lvs")

local l = lvs:new()

local service1 = {
    -- 实际服务器
    real_servers = {
        realserver1 = {ip = "192.168.18.201", port = 22, user = "root", auth = "pw", passwd= "123", timeout = 2,},
        realserver2 = {ip = "192.168.18.202", port = 22, user = "root", auth = "pw", passwd= "123", timeout = 2,},
    },
    -- 提供的实际服务IP端口,权重
    real_services = {
        {service="192.168.18.201:80", weight=1},
        {service="192.168.18.202:80", weight=2},
    },

    -- 转发服务器
    direc_servers = {
        direcserver1 = { ip = "192.168.18.200", port = 22, user = "root", auth = "pw", passwd= "123", timeout = 2,},
    },
    -- 转发的服务定义
    vservice  = "192.168.18.100:80",
    -- 调度模式
    scheduler = "rr",
    -- 服务类型
    service_type= "tcp",
    -- 转发类型
    lvs_type = "dr",
    -- 持久连接
    persistent="10"
}

local service2 = {
    -- 实际服务器
    real_servers = {
        realserver1 = {ip = "192.168.18.201", port = 22, user = "root", auth = "pw", passwd= "123", timeout = 2,},
        realserver2 = {ip = "192.168.18.202", port = 22, user = "root", auth = "pw", passwd= "123", timeout = 2,},
    },
    -- 提供的实际服务IP端口,权重
    real_services = {
        {service="192.168.18.201:22", weight=2},
        {service="192.168.18.202:22", weight=1},
    },

    -- 转发服务器
    direc_servers = {
        direcserver1 = { ip = "192.168.18.200", port = 22, user = "root", auth = "pw", passwd= "123", timeout = 2,},
    },
    -- 转发的服务定义
    vservice  = "192.168.18.100:22",
    -- 调度模式
    scheduler = "rr",
    -- 服务类型
    service_type= "tcp",
    -- 转发类型
    lvs_type = "dr",
    -- 持久连接
    -- persistent="30"
}

l:add_services("http_service", service1)
l:install_service("http_service")
l:add_services("ssh_service", service2)
l:install_service("ssh_service")

