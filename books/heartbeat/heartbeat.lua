--
-- Created by IntelliJ IDEA.
-- User: iaai
-- Date: 17-1-17
-- Time: 下午3:13
-- To change this template use File | Settings | File Templates.
--
require("books/common")

hb = {}

function hb:new(o)
    o = o or {
        version="3.0.4",    -- heartbeat version
        nodes={},           -- 节点
        resources={},       -- 资源
        constraints={       -- 约束
            locations={},   -- 位置
            orders={},      -- 顺序
            colocations={}  -- 排列
        },
        hacf={},
        authkeys={}, }

    setmetatable(o, self)
    self.__index = self

    return o
end

-- 添加节点
function hb:addnodes(nodes)
    self.nodes = nodes
end

-- 在每个节点上添加所有节点的hostname信息
function hb:sethostnames()
    for k, v in pairs(self.nodes) do
        v.st = "file"
        v.script="./books/heartbeat/sethostnames.lua"
        -- v.st = "string"
        -- v.script=sethostnames_scripts[1]
    end

    PL_RUN(self.nodes, self.nodes)

end

-- 同步时时间并添加crond
function hb:ntpdate()
    local s = [===[
    HOST:Cmd{"yum install ntpdate -y", "ntpdate ntp.ubuntu.com"}
    ]===]

    for _, v in pairs(self.nodes) do
        v.st= "string"
        v.script = s
    end
    PL_RUN(self.nodes)
end

-- SSH互信
function hb:exchangekeys()
    -- ==============获取keys
    -- 用table仅仅是为了在编辑器中可以折叠代码 = =
    local getkey = {
        [====[
        require("books/sshd/sshd")

        SSHD.keygen("rsa")
        Cmd("cat $HOME/.ssh/id_rsa.pub")
        Cmd("cat /etc/ssh/ssh_host_rsa_key.pub")

        ]====]
    }
    for _, v in pairs(self.nodes) do
        -- v.st = "file"
        -- v.script="./books/heartbeat/getkeys.lua"
        v.st= "string"
        v.script = getkey[1]
    end

    local pl = PL_RUN(self.nodes, self.nodes)

    -- tkey={host={ip, id_isa.pub, host_rsa.pub}}
    local tkey={}
    local ip, id_isa_pub, host_rsa_pub
    for host, _ in pairs(self.nodes) do
            ip = self.nodes[host].ip
        for time, roc in pl:GetHistory(host)() do
            if roc.Cmd == "cat $HOME/.ssh/id_rsa.pub" then
                id_isa_pub = roc.Out
            elseif roc.Cmd == "cat /etc/ssh/ssh_host_rsa_key.pub" then
                host_rsa_pub = roc.Out
            end
        end
        tkey[host] = {ip=ip, id_isa= id_isa_pub, host_rsa= host_rsa_pub }
    end

    -- ===============设置keys
    local addkey = {
        [====[
        require("books/sshd/sshd")
        local tkey = PLAYLISTINFO

        for host, v in pairs(tkey) do
            SSHD.addpubkey("root", v.id_isa)
            SSHD.addknownhost(v.ip, "root", v.host_rsa)
        end

        -- 设置sshd_config
        SSHD.set("RSAAuthentication", "yes")
        SSHD.set("UseDNS", "no")
        SSHD.set("PubkeyAuthentication", "yes")
        SSHD.set("AuthorizedKeysFile", ".ssh/authorized_keys")

        SSHD.restart()
        ]====]
    }

    for _, v in pairs(self.nodes) do
        v.st = "string"
        v.script= addkey[1]
    end

    PL_RUN(self.nodes, tkey)

end

function hb:install()
    -- service sshd restart之后，好像配置低的话，要很久才能连接上。
    local t={}
    for h, v in pairs(self.nodes) do
        v.st = "file"
        v.script="./books/heartbeat/install.lua"
        -- v.st= "string"
        -- v.script = getkey[1]
        t[h] = v.timeout
        v.timeout=20
    end

    PL_RUN(self.nodes, self)

    for h, v in pairs(self.nodes) do
        v.timeout = t[h]
    end
end

-- 添加资源
function hb:addresource(nodename, res)
    if self.resources[nodename] then
        self.resources[nodename] = self.resources[nodename].." "..res
    else
        self.resources[nodename] = " "..res
    end
end

function hb:sethacf(key, value)
    self.hacf[key]=value
end

function hb:setauthkeys(authtype, key)
    local type= { crc = 1, sha1 = 2, md5 = 3, }
    local t = type[authtype]
    if t then
        self.authkeys["authNum"] = t
        self.authkeys["authType"] = authtype
        self.authkeys["authKey"] = key
    else
        print("hb authkeys 类型配置错误.")
        os.exit()
    end
end

-- 启动
function hb:start()
    local s = [[
        HOST:Cmd{
        "yum -y install httpd",
        "echo "..HOST.Ip.." > /var/www/html/index.html",
        "service iptables stop",
        "service heartbeat start",
        }
    ]]
    for _, v in pairs(self.nodes) do
        v.st= "string"
        v.script = s
    end

    PL_RUN(self.nodes)
end

