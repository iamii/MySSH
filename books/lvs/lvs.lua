--
-- Created by IntelliJ IDEA.
-- User: guang
-- Date: 2017-01-07
-- Time: 16:21
--

require("./books/common")

-- real_servers = {service="", weight=""}
lvs = {vservice="ip:port", scheduler="rr/wrr/wlc/...", service_type = "tcp/udp/fwm", persistent="30", firewallflag="-s xxx -d xxx -i eth0 --dport 80", firewallmark="88", real_servers = {}, dip=""}

local function check_kernel_version()
    Cmd("uname -r")
    return ERR.Msg
end

function lvs:new(o)
    if check_kernel_version() >= "2.6" then
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

function lvs:setpersistent(timeout)
    self.persistent = "-p "..timeout
end

function lvs:setfirewallparam(flag, mark)
    self.firewallflag = flag
    self.firewallmark = mark
end

function lvs:add_service(lvs_type)
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

    -- lvs转发类型 nat/dr --还没看tun，不支持
    local lt
    if lvs_type == "dr" then
        lt = "-g"
        local t = string.split(self.vservice, ":")
        if not t then
            print("服务定义错误，格式为 ip:port")
            os.exit()
        end
        local vip = t[1]

        Cmd{
            "/sbin/ifconfig eth0:1 "..vip.." broadcast "..vip..
                    " netmask 255.255.255.255 up",
            "/sbin/route add -host "..vip.." dev eth0:1",
        }
    elseif lvs_type == "nat" then
        Cmd("echo 1 > /proc/sys/net/ipv4/ip_forward")
        lt = "-m"
        print("===别忘记配置real server的网关为director server===")
    else
        print("未支持的lvs类型")
        os.exit()
    end


    if st ~= nil and lt ~= nil then
        -- firewall mark  太麻烦，未测试
        if st == "-f" then
            Cmd{
                "ipvsadm -A -f "..self.firewallmark.." -s "..self.scheduler.." "..self.persistent,
                "iptables -t mangle -A PREROUTING "..self.firewallflag.." -j MARK --set-mark "..self.firewallmark
            }


            for k, v in pairs(self.real_servers) do  -- 未处理 -a 添加 realserver时只要RIP，
                Cmd(
                    "ipvsadm -a -f "..self.firewallmark.." -r "..string.split(v.service,":")[1]..
                            " "..lt.." -w "..v.weight
                )
            end
        else    -- tcp/udp
            Cmd{
                 "ipvsadm -A "..st.." "..self.vservice.." -s "..self.scheduler.." "..self.persistent,
            }

            for k, v in pairs(self.real_servers) do
                Cmd(
                   "ipvsadm -a "..st.." "..self.vservice.." -r "..v.service..
                           " "..lt.." -w "..v.weight
                )
            end
        end
    end
end

function lvs:list_service()
    if self.service_type == "tcp" then
        Cmd("ipvsadm -l -t "..self.vservice)
    elseif self.service_type == "udp" then
        Cmd("ipvsadm -l -u "..self.vservice)
    else
        print("未支持的服务类型:", self.service_type)
        os.exit()
    end
end

function lvs:add_real_server(realserver)
    table.insert(self.real_servers, realserver)
end
