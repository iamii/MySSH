--
-- User: iaai
-- Date: 17-3-27
-- Time: 上午10:48
--

require ("books/common")

keepalived = {}

function keepalived:new(o)
    o = o or {
        hanodes = {},
        lvsnodes = {},
        ct = {
            global_defs = {
                --[[
                notification_email = {
                    "315313343@qq.com",
                },
                notification_email_from = "abcdefg@abc.com",
                smtp_server = "smtp.abc.com",
                smtp_connect_timeout = "30",
                "enable_traps",
                --]]
                router_id = "host163",
            },
            -- [====[
            --[[
            static_ipaddress= {},
            static_routes = {},
            vrrp_script = {},
            --]]
            ["vrrp_instance VI_1"] = {
                    -- 指定Keepalived的角色，
                    -- -- MASTER表示此主机是主用服务器，BACKUP表示是备用服务器。
                    state       = "MASTER",
                    -- #指定HA监测网络的接口。
                    interface   =   "eth1",
                    -- 虚拟路由标识，这个标识是一个数字，并且同一个vrrp实例使用唯一的标识，
                    -- 即同一个vrrp_instance下，MASTER和BACKUP必须是一致的。
                    virtual_router_id   = "51",
                    -- 定义优先级，数字越大，优先级越高，
                    -- -- 在一个vrrp_instance下，MASTER的优先级必须大于BACKUP的优先级。
                    priority    = "100",
                    -- 设定MASTER与BACKUP负载均衡器之间同步检查的时间间隔，单位是秒。
                    advert_int  = "1",
                    -- 设定验证类型和密码。
                    -- -- 设置验证类型，主要有PASS和AH两种。
                    -- -- 设置验证密码，在一个vrrp_instance下，
                    -- -- MASTER与BACKUP必须使用相同的密码才能正常通信。
                    authentication  = {
                        auth_type="PASS",
                        auth_pass="135246",
                        },
                    -- 设置虚拟IP地址，可以设置多个虚拟IP地址，每行一个。
                    virtual_ipaddress   ={
                        "192.168.18.100",
                    },
                    -- 用于设置发送多播包的地址，如果不设置，将使用绑定的网卡所对应的IP地址。
                    -- mcast_src_ip = "",
                    -- 用于设定在切换到Master状态后延时进行Gratuitous arp请求的时间。
                    garp_master_delay="10",
                    -- 用于设置一些额外的网络监控接口，其中任何一个网络接口出现故障，Keepalived都会进入FAULT状态。
                    -- track_interface = {},
                    -- MASTER 故障恢复之后，是否抢占回来
                    "nopreempt",
                    preemtp_delay = "300",
                },
            --[[
            vrrp_sync_group = {
                group={},
                notify_backup = "",
                notify_master = "",
                notify_fault = "",
                notify_stop = "",
            },
            --]]
            ["virtual_server 192.168.18.100 80"] = {
                -- 设置虚拟服务器的开始，后面跟虚拟IP地址和服务端口，IP与端口之间用空格隔开。
                    -- 设置健康检查的时间间隔，单位是秒。
                    delay_loop = 3,
                    -- 设置负载调度算法，可用的调度算法有rr、wrr、lc、wlc、lblc、sh、dh等，
                    -- -- 常用的算法有rr和wlc。
                    lb_algo = "rr",
                    -- 设置LVS实现负载均衡的机制，有NAT、TUN和DR三个模式可选。
                    lb_kind= "DR",
                    -- 会话保持时间，单位秒。
                    -- -- 这个选项对动态网页是非常有用的，为集群系统中的session共享提供了一个很好的解决方案。
                    -- -- 有了这个会话保持功能，用户的请求会一直分发到某个服务节点，直到超过这个会话的保持时间。
                    -- -- 需要注意的是，这个会话保持时间是最大无响应超时时间，也就是说，
                    -- -- 用户在操作动态页面时，如果在50秒内没有执行任何操作，那么接下来的操作会被分发到另外的节点，
                    -- -- 但是如果用户一直在操作动态页面，则不受50秒的时间限制。
                    -- persistence_timeout = "60",
                    --此选项是配合persistence_timeout的，后面跟的值是子网掩码，表示持久连接的粒度。
                    -- -- 默认是255.255.255.255，也就是一个单独的客户端IP。
                    -- -- 如果将掩码修改为255.255.255.0，那么客户端IP所在的整个网段的请求都会分配到同一个real server上。
                    -- persistence_granularity = "255.255.255.255",
                    -- 指定转发协议类型，有TCP和UDP两种可选
                    protocol = "TCP",
                    -- 节点状态从Master到Backup切换时，暂不启用real server节点的健康检查。
                    "ha_suspend",
                    -- 在通过HTTP_GET/ SSL_GET做健康检测时，指定的Web服务器的虚拟主机地址。
                    -- virtualhost = "",
                    -- 备用节点，在所有real server失效后，这个备用节点会启用。
                    -- sorry_server = {},
                    ["real_server 192.168.18.202 80"] = {
                            -- 权重
                            weight = "3",
                            -- 检测到real server节点失效后，把它的“weight”值设置为0，而不是从IPVS中删除。
                            -- "inhibit_on_failure",
                            -- 在检测到real server节点服务处于UP状态后执行的脚本。
                            -- notify_up = "",
                            -- 在检测到real server节点服务处于DOWN状态后执行的脚本。
                            -- notify_down = "",
                            TCP_CHECK={
                                -- 健康检查的端口，如果无指定，默认是real_server指定的端口。
                                connect_port=80,
                                -- 无响应超时时间，单位是秒。
                                connect_timeout=3,
                                -- 重试次数，
                                nb_get_retry = 3,
                                -- 重试间隔
                                delay_before_retry = 3,
                            },
                            --[[
                            HTTP_GET={
                                    url = {
                                        -- 指定HTTP/SSL检查的URL信息，可以指定多个URL。
                                        path = {"/index.html",},
                                        -- SSL检查后的摘要信息，这些摘要信息可以通过genhash命令工具获取。例如：genhash -s 192.168.12.80 -p 80 -u /index.html。
                                        digest = "e6c271eb5f017f280cf97ec2f51b02d3",
                                        -- 指定HTTP检查返回正常状态码的类型，一般是200。
                                        status_code = 200,
                                    },
                                    -- 端口。
                                    connect_port = 80,
                                    -- 表示通过此地址来发送请求对服务器进行健康检查。
                                    bindto = "",
                                    -- 无响应超时时间，单位是秒。
                                    connect_timeout = 3,
                                    -- 重试次数，
                                    nb_get_retry = 3,
                                    -- 重试间隔
                                    delay_before_retry = 2,
                                },
                            -- SSL_GET同HTTP_GET
                            -- SSL_GET={},

                            -- SMTP_CHECK={},
                            -- MISC健康检查方式可以通过执行一个外部程序来判断real server节点的服务状态
                            MISC_CHECK = {
                                -- 用来指定一个外部程序或者一个脚本路径
                                misc_path = "/usr/local/bin/script.sh",
                                -- 设定执行脚本的超时时间
                                misc_timeout = 5,
                                -- 示是否启用动态调整real server节点权重，“!misc_dynamic”表示不启用，相反则表示启用。
                                -- -- 在启用这功能后，Keepalived的healthchecker进程将通过退出状态码来动态调整real server节点的“weight”值，
                                -- -- 如果返回状态码为0，表示健康检查正常，real server节点权重保持不变；如果返回状态码为1，表示健康检查失败，
                                -- -- 那么就将real server节点权重设置为0；如果返回状态码为2~255之间任意数值，表示健康检查正常，
                                -- -- 但real server节点的权重将被设置为返回状态码减2，
                                -- -- 例如返回状态码为10，real server节点权重将被设置为8（10-2）。
                                "! misc_dynamic",
                            },
                            -- ]]
                        },
                ["real_server 192.168.18.203 80"] = {
                    -- 权重
                    weight = "3",
                    -- 检测到real server节点失效后，把它的“weight”值设置为0，而不是从IPVS中删除。
                    -- "inhibit_on_failure",
                    -- 在检测到real server节点服务处于UP状态后执行的脚本。
                    -- notify_up = "",
                    -- 在检测到real server节点服务处于DOWN状态后执行的脚本。
                    -- notify_down = "",
                    TCP_CHECK={
                        -- 健康检查的端口，如果无指定，默认是real_server指定的端口。
                        connect_port=80,
                        -- 无响应超时时间，单位是秒。
                        connect_timeout=3,
                        -- 重试次数，
                        nb_get_retry = 3,
                        -- 重试间隔
                        delay_before_retry = 3,
                    },
                    --[[
                    HTTP_GET={
                            url = {
                                -- 指定HTTP/SSL检查的URL信息，可以指定多个URL。
                                path = {"/index.html",},
                                -- SSL检查后的摘要信息，这些摘要信息可以通过genhash命令工具获取。例如：genhash -s 192.168.12.80 -p 80 -u /index.html。
                                digest = "e6c271eb5f017f280cf97ec2f51b02d3",
                                -- 指定HTTP检查返回正常状态码的类型，一般是200。
                                status_code = 200,
                            },
                            -- 端口。
                            connect_port = 80,
                            -- 表示通过此地址来发送请求对服务器进行健康检查。
                            bindto = "",
                            -- 无响应超时时间，单位是秒。
                            connect_timeout = 3,
                            -- 重试次数，
                            nb_get_retry = 3,
                            -- 重试间隔
                            delay_before_retry = 2,
                        },
                    -- SSL_GET同HTTP_GET
                    -- SSL_GET={},

                    -- SMTP_CHECK={},
                    -- MISC健康检查方式可以通过执行一个外部程序来判断real server节点的服务状态
                    MISC_CHECK = {
                        -- 用来指定一个外部程序或者一个脚本路径
                        misc_path = "/usr/local/bin/script.sh",
                        -- 设定执行脚本的超时时间
                        misc_timeout = 5,
                        -- 示是否启用动态调整real server节点权重，“!misc_dynamic”表示不启用，相反则表示启用。
                        -- -- 在启用这功能后，Keepalived的healthchecker进程将通过退出状态码来动态调整real server节点的“weight”值，
                        -- -- 如果返回状态码为0，表示健康检查正常，real server节点权重保持不变；如果返回状态码为1，表示健康检查失败，
                        -- -- 那么就将real server节点权重设置为0；如果返回状态码为2~255之间任意数值，表示健康检查正常，
                        -- -- 但real server节点的权重将被设置为返回状态码减2，
                        -- -- 例如返回状态码为10，real server节点权重将被设置为8（10-2）。
                        "! misc_dynamic",
                    },
                    -- ]]
                },
                ["real_server 192.168.18.204 80"] = {
                    -- 权重
                    weight = "3",
                    -- 检测到real server节点失效后，把它的“weight”值设置为0，而不是从IPVS中删除。
                    -- "inhibit_on_failure",
                    -- 在检测到real server节点服务处于UP状态后执行的脚本。
                    -- notify_up = "",
                    -- 在检测到real server节点服务处于DOWN状态后执行的脚本。
                    -- notify_down = "",
                    TCP_CHECK={
                        -- 健康检查的端口，如果无指定，默认是real_server指定的端口。
                        connect_port=80,
                        -- 无响应超时时间，单位是秒。
                        connect_timeout=3,
                        -- 重试次数，
                        nb_get_retry = 3,
                        -- 重试间隔
                        delay_before_retry = 3,
                    },
                    --[[
                    HTTP_GET={
                            url = {
                                -- 指定HTTP/SSL检查的URL信息，可以指定多个URL。
                                path = {"/index.html",},
                                -- SSL检查后的摘要信息，这些摘要信息可以通过genhash命令工具获取。例如：genhash -s 192.168.12.80 -p 80 -u /index.html。
                                digest = "e6c271eb5f017f280cf97ec2f51b02d3",
                                -- 指定HTTP检查返回正常状态码的类型，一般是200。
                                status_code = 200,
                            },
                            -- 端口。
                            connect_port = 80,
                            -- 表示通过此地址来发送请求对服务器进行健康检查。
                            bindto = "",
                            -- 无响应超时时间，单位是秒。
                            connect_timeout = 3,
                            -- 重试次数，
                            nb_get_retry = 3,
                            -- 重试间隔
                            delay_before_retry = 2,
                        },
                    -- SSL_GET同HTTP_GET
                    -- SSL_GET={},

                    -- SMTP_CHECK={},
                    -- MISC健康检查方式可以通过执行一个外部程序来判断real server节点的服务状态
                    MISC_CHECK = {
                        -- 用来指定一个外部程序或者一个脚本路径
                        misc_path = "/usr/local/bin/script.sh",
                        -- 设定执行脚本的超时时间
                        misc_timeout = 5,
                        -- 示是否启用动态调整real server节点权重，“!misc_dynamic”表示不启用，相反则表示启用。
                        -- -- 在启用这功能后，Keepalived的healthchecker进程将通过退出状态码来动态调整real server节点的“weight”值，
                        -- -- 如果返回状态码为0，表示健康检查正常，real server节点权重保持不变；如果返回状态码为1，表示健康检查失败，
                        -- -- 那么就将real server节点权重设置为0；如果返回状态码为2~255之间任意数值，表示健康检查正常，
                        -- -- 但real server节点的权重将被设置为返回状态码减2，
                        -- -- 例如返回状态码为10，real server节点权重将被设置为8（10-2）。
                        "! misc_dynamic",
                    },
                    -- ]]
                },
            --]====]
        },
        },
    }

    setmetatable(o, self)
    self.__index = self
    return o
end


function keepalived:install()
    -- [[
    for k, v in pairs(self.hanodes) do
        v.script = "books/keepalived/installkeepalived.lua"
        v.st = "file"
    end

    PL_RUN(self.hanodes, self)

    --]]
    for k, v in pairs(self.lvsnodes) do
        v.script = "books/keepalived/installl_realserver.lua"
        v.st="file"
    end

    PL_RUN(self.lvsnodes, {vservice="192.168.18.100:80", lvs_type="dr"})
end

