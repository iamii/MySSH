--
-- User: iaai
-- Date: 17-3-10
-- Time: 下午9:52
--
require ("books/php/php")

local zabbix = PLAYLISTINFO
-- 源码安装php
-- [[
local p = php:new({tarfile="php-5.6.28.tar.gz", prefix="/usr/local/"})
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
--]]
-- 安装nginx
require ("books/nginx/nginx")
local n = nginx:new({
    conf = {
        ["nginx.conf"] = {
            {
                -- 指定运行nginx服务的用户
                user = "nginx",
                --group
                -- 启动进程，通常设置成和CPU的数量相等 number|auto;
                worker_processes = 1,
                -- 配置nginx进程PID文件路径
                -- pid = "/var/run/nginx.pid",
                -- 配置错误日志的存储路径
                -- -- 此指令可在全局块，Http块，Server块以及location块中配置
                -- -- error_log = logs/error.log|stderr [debug | info | notice | warn | erro | crit | alert | emerg];
                -- -- 默认如下： 指定的文件对于运行NGINX进程的用户必须要有可写权限
                error_log = "/var/log/error.log debug",

                -- 引入其它配置文件，指定的文件对于运行NGINX进程的用户必须要有可写权限,
                -- -- 此指令可以放在配置文件的任意地方
                --include = file,
            },
            -- 工作模式及连接数上限
            events = {
                -- 配置事件驱动模型
                -- -- select库 linux windows都支持
                -- -- poll库仅linux2.1.23以上支持
                -- -- epoll库仅linux2.5.44以上支持, 高效
                -- -- rtsig 、/dev/poll、eventport
                use = "epoll",

                --每个worker process进程的最大并发连接数
                worker_connections = 1024,

                -- 设置网络连接的序列化，防止多个进程对连接的争抢，
                --accept_mutex = "on | off",
                -- 设置每个worker process一次是否可接受多个新到达的网络连接
                --multi_accept = "on | off",

            },
            http = {
                {
                    -- 设定mime类型,类型由mime.type文件定义
                    include = {
                        "mime.types",
                        "conf.d/*.conf",
                    },
                },
                {
                    -- 设定日志格式
                    log_format = {
                        main = [=['\$remote_addr - \$remote_user [\$time_local] \"\$request\" '
                            '\$status  \$body_bytes_sent \"\$http_referer\" '
                            '\"\$http_user_agent\" \"\$http_x_forwarded_for\"']=],
                    },

                },
                {
                    --服务访问日志
                    -- -- 此指令可在Http块，Server块以及location块中配置
                    -- -- access_log = "logs/access.log combined buffer=32k flush=5s",
                    access_log = "/var/log/nginx/access.log main",
                },

                default_type = "application/octet-stream",

                -- 配置是否允许sendfile方式传输文件
                -- -- 此指令可在Http块，Server块以及location块中配置
                sendfile = "on",
                --
                tcp_nopush = "on",
                tcp_nodelay = "on",

                -- server_tag = "off",
                -- server_info = "off",
                server_tokens = "off",

                types_hash_max_size = 2048,
                --
                -- 每个worker process每次调用sendfile传输的数据最大值
                -- -- 此指令可在Http块，Server块以及location块中配置
                sendfile_max_chunk = "128k",
                -- 配置连接超时时间,
                -- -- 此指令可以在http块，server块或location块配置
                -- -- keepalive_timeout = timeout [header_timeout],
                keepalive_timeout = "75s",
                -- 每连接可接受的最大请求次数
                -- -- 此指令还可以出现在server块和location块中
                keepalive_requests = 100,
                --[[
                server = {
                    {
                        -- 配置网络监听
                        -- listen address[:port] [default_server] [setfib=number] [backlog=number]
                        -- -- [rcvbuf=size] [sndbuf=size] [deferred] [accept_filter=filter] [bind] [ssl];
                        listen = {8080,},
                        --
                        server_name = {"*.xxx.com", [=[~^www\d+\.myserver\.com$]=], "192.168.18.200"},
                        location = {
                            ["/"] = {
                                ["return"]=[=[301 https://www.xxx.com$request_uri]=],
                            },
                            ["= /404.html"] = {
                                root = "/usr/share/nginx/html",
                            },
                        },
                        error_page = {
                            ["/404.html"] = {404},
                            ["/50x.html"] = {500, 502, 503},
                        },
                    },
                },
                --]]
            },
        },
        ["conf.d/default.conf"] = {
            server = {
                {
                    listen = {80,"default_server"},
                    index = "index.php index.html index.html",
                    root = "/usr/share/zabbix",
                    location = {
                        ["/"] = {
                            try_files = '$uri $uri/ /index.php?$args',
                        },
                       ["~ .*\\.(php)?$"] = {
                           {
                               expires = "-1s",
                           },
                           {
                               try_files = '$uri =404',
                           },
                           {
                               fastcgi_split_path_info = '^(.+\\.php)(/.+)$',
                           },
                           {
                               include = "fastcgi_params",
                           },
                           {
                               fastcgi_param = 'PATH_INFO $fastcgi_path_info',
                           },
                           {
                               fastcgi_index = "index.php",
                           },
                           {
                               fastcgi_param = 'SCRIPT_FILENAME $document_root$fastcgi_script_name',
                           },
                           {
                               fastcgi_pass = "127.0.0.1:9000",
                           },
                       },
                    },
                } ,
            },
        },
    },
}
)
n:yumInstall()

Cmd{"service nginx restart"}
--]====]

HOST:Send({dst="agenthost", info="done"})
