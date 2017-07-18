--
-- Created by IntelliJ IDEA.
-- User: guang
-- Date: 2017-01-07
-- Time: 16:21
--

require("./books/common")

-- real_servers = {service="", weight=""}
lvsinstance = {
    -- 虚拟服务的IP端口
    vservice="ip:port",
    -- 调度模式
    scheduler="rr/wrr/wlc/...",
    -- 服务类型 tcp udp fwm(防火墙标记)
    service_type = "tcp/udp/fwm",
    -- 持久化时间(s)
    persistent="",
    -- 防火墙标记参数
    firewallflag="-s xxx -d xxx -i eth0 --dport 80",
    -- 防火墙标记号
    firewallmark="88",
    -- 物理服务器列表
    real_servers = {},
    -- 转发服务器列表
    direc_servers = {},
}

function lvsinstance:new(o)
    if GetLinuxVersion().ker >= "2.6" then
        Cmd{
            -- "service iptables stop ",
            -- "chkconfig iptables off",
            "iptables -F && iptables -Z",
            "yum install ipvsadm -y"
        }
        o = o or {}
        setmetatable(o, self)
        self.__index = self
        return o
    else
        print("内核版本太低，请手动安装ipvs模块。")
        return nil
    end
end

function lvsinstance:setfirewallparam(flag, mark)
    self.firewallflag = flag
    self.firewallmark = mark
end

function lvsinstance:add_virtual_service()
    -- 服务类型 tpc/udp/firewall mark
    local st
    if self.service_type == "tcp" then
        st = "-t"
    elseif self.service_type == "udp" then
        st = "-u"
    elseif self.service_type == "fwm" then
        st = "-f"
    else
         print("未支持的服务类型")
         os.exit()
    end

    -- lvsinstance转发类型 nat/dr --还没看tun，不支持
    local lt
    if self.lvs_type == "dr" then
        lt = "-g"
        local t = string.split(self.vservice, ":")
        if not t then
            print("服务定义错误，格式为 ip:port")
            os.exit()
        end
        local vip = t[1]

        Cmd{
            "/sbin/ifconfig eth0:1 "..vip.." broadcast "..vip.. " netmask 255.255.255.255 up",
            "/sbin/route add -host "..vip.." dev eth0:1"
        }

    elseif self.lvs_type == "nat" then
        Cmd("echo 1 > /proc/sys/net/ipv4/ip_forward")
        lt = "-m"
        print("===别忘记配置real server的网关为director server===")
    else
        print("未支持的lvsinstance类型")
        os.exit()
    end


    if st ~= nil and lt ~= nil then
        -- firewall mark  未测试
        if self.persistent and self.persistent ~= "" then
            self.persistent = "-p "..self.persistent
        else
            self.persistent = ""
        end

        if st == "-f" then
            Cmd{
                "ipvsadm -A -f "..self.firewallmark.." -s "..self.scheduler.." "..self.persistent,
                "iptables -t mangle -A PREROUTING "..
                    self.firewallflag.." -j MARK --set-mark "..self.firewallmark
            }

            for _, v in pairs(self.real_servers) do  -- 未处理 -a 添加 realserver时只要RIP，
                    Cmds{
                        "ipvsadm -a -f "..self.firewallmark.." -r "..string.split(v.service,":")[1]..
                            " "..lt.." -w "..v.weight
                    }
            end
        else    -- tcp/udp
            Cmd{
                 "ipvsadm -A "..st.." "..self.vservice.." -s "..self.scheduler.." "..self.persistent,
            }

            for _, v in pairs(self.real_services) do
                Cmd(
                   "ipvsadm -a "..st.." "..self.vservice.." -r "..v.service..
                           " "..lt.." -w "..v.weight
                )
            end
        end
    end
end

function lvsinstance:list_service()
    if self.service_type == "tcp" then
        Cmd("ipvsadm -l -t "..self.vservice)
    elseif self.service_type == "udp" then
        Cmd("ipvsadm -l -u "..self.vservice)
    else
        print("未支持的服务类型:", self.service_type)
        os.exit()
    end
end

function lvsinstance:add_real_server(realserver)
    if type(realserver) == "table" then
        lvsinstance.real_servers = realserver
    elseif type(realserver) == "string" then
        table.insert(self.real_servers, realserver)
    end
end
