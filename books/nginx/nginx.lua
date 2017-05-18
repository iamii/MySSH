--
require("books/common")

nginx = {}

function nginx:new(o)
    o = o or {
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
                        {
                            listen = {80,"default_server"},
                            --
                            server_name = {"_"},
                        },
                        proxy_redirect = "off",
                        proxy_set_header = { -- 还没处理
                            [=[Host \$host]=],
                            [=[REMOTE-HOST \$remote_addr]=],
                            [=[X-Real-IP \$remote_addr]=],
                            [=[X-Forwarded-For \$proxy_add_x_forwarded_for]=],
                        },
                        client_max_body_size = "10m",
                        client_body_buffer_size = "256k",
                        proxy_connect_timeout = 90,
                        proxy_send_timeout = 90,
                        proxy_read_timeout = 90,
                        proxy_buffer_size  = "256k",
                        proxy_buffers = "4 256k",
                        proxy_busy_buffers_size = "256k";
                        proxy_temp_file_write_size = "256k",
                        proxy_max_temp_file_size = "8m",

                        location = {
                            ["/"] = {
                                --[[
                                root = "html",
                                index = "index.html index.htm",
                                --]]
                                proxy_pass = "http://test"
                            },
                            ["= /50x.html"] = {
                                root = "html",
                            },
                        },
                        error_page = {
                            ["/404.html"] = {404},
                            ["/50x.html"] = {500, 502, 503},
                        },
                        proxy_next_upstream={
                            "http_502", "http_504", "http_404",
                            "error", "timeout", "invalid_header"},
                    },
                },

            },
            ["conf.d/upstream.conf"] = {
                upstream = {
                    test = {
                        --#check interval=3000 rise=2 fall=5 timeout=3000 default_down=false type=http;
                        --[[
                        check = {
                            interval=3000,
                            rise=2,
                            fall=5,
                            timeout=3000,
                            type="http",
                        },
                        --]]

                        --#check_keepalive_requests 1;
                        --check_http_send=[=[HEAD / HTTP/1.0\r\n\r\n]=],
                        -- check_http_expect_alive={"http_2xx", "http_3xx"},

                         --#ip_hash;
                        backendserver = {
                            ["192.168.18.201:8081"] = {weight=1, fail_timeout="5s"},
                            ["192.168.18.202:8081"] = { weight=2, fail_timeout="5s"},
                            ["192.168.18.203:8080"] = {"backup"},
                        },
                        --"least_conn",
                    },
                },
            },
        },
    }

    setmetatable(o, self)
    self.__index = self

    return o
end

function nginx:yumInstall()
    Cmd("service nginx status")
    if ERR.Code ~= 0 then
        InstallEPEL()

        Cmd("yum install nginx -y")
        -- [=[echo -e "]=]..self:getconf(self.conf["nginx.conf"])..[=[" > /etc/nginx/nginx.conf]=],
        for k, v in pairs(self.conf) do
            Cmd([=[echo "]=]..self:getconf(v)..[=[" > /etc/nginx/]=]..k)
        end


        Cmd{
            "setsebool -P httpd_can_network_connect 1",
            "service nginx restart",
            "iptables -I INPUT 1 -p tcp --dport 80 -m state --state NEW -j ACCEPT",
        }
    end
end

function nginx:fun(fn, args, tab)

    local funs = {
        events = function (events)
            local f = "events \t{\n"
            f = f .. self:getconf(events, tab.."\t") .."\n}\n"
            return f
        end,

        http= function (http)
            local f = "http \t{\n"
            f = f .. self:getconf(http, tab.."\t") .."\n}\n"
            return f
        end,

        server = function (servers)
            local f = tab.."server \t{\n"
            for i = 1, #servers do
                f = f .. self:getconf(servers[i], tab.."\t") ..tab.."}\n"
            end
            return f
        end,

        ["include"] =  function(inc)
            local f = ""
            local get = ""
            if type(inc)=="table" and #inc > 0 then
                for i = 1, #inc do
                    --[==[
                    -- 此处可判断include的文件是否存在，
                    -- -- 1判断是否在conf表中，
                    -- -- 2文件系统中存在
                    for k, _ in pairs(self.conf) do
                        Cmd("[[ "..k.." == "..inc[i].." ]]")
                       if ERR.Code == 0 then
                           get = k
                           break
                       else
                           -- DEBUG(k,"不匹配")
                       end
                    end
                    --]==]
                    f = f..tab.."include\t"..inc[i]..";\n"
                end
            end
            -- return f, self:getconf(self.conf[get])
            return f
        end,

        log_format = function(logf)
            local f = ""
            if type(logf) == "table" then
                for k, v in pairs(logf) do
                   f = f ..tab.. "log_format\t".. k.."\t"..v..";\n"
                end
            end
            return f
        end,

        location = function(loc)
            local f = ""
            for k, v in pairs(loc) do
                f = f.. tab .."location\t"..k.."\t{\n"..self:getconf(v, tab.."\t").."\n"..tab.."}\n"
            end
            return f
        end,

        listen = function(lis)
            local f = tab.."listen\t"
            if type(lis) == "table" and #lis >0 then
                for i = 1, #lis do
                    f = f .."\t".. lis[i]
                end
            else
                print("listen 配置有误.")
            end
            return f..";\n"
        end,

        server_name = function(sn)
            local f = tab.."server_name\t"
            if type(sn) == "table" and #sn >0 then
                for i = 1, #sn do
                    f = f .."\t".. sn[i]
                end
            else
                print("server_name 配置有误.")
            end
            return f..";\n"
        end,

        error_page = function(ep)
            local f = ""
            for k, v in pairs(ep) do
                f = f ..tab.. "error_page\t"..table.concat(v," ").."\t\t"..k..";\n"
            end
            return f
        end,

        upstream = function(us)
            local f = ""
            for k, v in pairs(us) do
               f = f .."upstream\t"..k.."\t{\n".. self:getconf(v, tab.."\t").."}\n"
            end
            return f
        end,

        check = function(ck)
            local f = tab.. "check"
            for k, v in pairs(ck) do
                f = f ..tab..k.." = "..v
            end
            return f..";\n"
        end,

        ["check_http_expect_alive"] = function(chea)
            local f = tab.."check_http_expect_alive\t"
            for i = 1, #chea do
                f = f .. tab..chea[i]
            end
            return f..";\n"
        end,

        backendserver = function(bes)
            local f = ""
            for k, v in pairs(bes) do
               f = f..tab.."server\t"..k.."\t"
                for sk, sv in pairs(v) do
                    if type(sk)=="number" then
                        f = f..sv.."\t"
                    else
                        f = f..sk.."=".. sv.."\t"
                    end
                end
                f = f ..";\n"
            end

            return f
        end,

        proxy_next_upstream = function(pnu)
            local f = tab.."proxy_next_upstream"
            for i = 1, #pnu do
                f = f.."\t"..pnu[i]
            end
            return f..";\n"
        end,
    }


    local f = funs[fn]
    if type(f) == "function" then
        return f(args, tab)
    else
        print("Unknow fun key:", fn)
    end
    -- return nil
end

function nginx:getconf(file, tab)
    local confile = ""
    tab = tab or ""
    if type(file) == "table" then
        for k, v in pairs(file) do
            if type(k) == "number" then
                confile = confile..self:getconf(v, tab)
            elseif type(v) == "table" then
                local cf = self:fun(k, v, tab) or ""
                confile = confile ..cf
            else
                confile = confile ..tab.. k .."\t"..v..";\n"
            end
        end
    else
        confile = confile..tab.. file..";\n"
    end

    return confile
end



