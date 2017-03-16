require("books/common")

zabbix = {API = zabbixx() }

function zabbix:new(o)
    o = o or {
        host=HOST.Ip,
        port="10051",
        web={
            user = "Admin",
            pass = "zabbix",
        },
        mysqlcfg = {
            host = HOST.Ip,
            port = "0",
            db = "zabbix",
            user = "zabbix",
            pass = "zabbix123",
            root_pass = "abcdefg",
            sock = "/var/lib/mysql/mysql.sock"
        }
    }

    assert(o.host, "这个我只能在你SSH连接到的机器上面装zabbix")
    assert(o.mysqlcfg, "未定义zabbix的mysql配置信息, mysqlcfg")
    assert(o.mysqlcfg.host, "未定义mysql主机，mysqlcfg.host")
    assert(o.mysqlcfg.user, "未定义mysql连接用户名, mysqlcfg.user")
    assert(o.mysqlcfg.pass, "未定义mysql连接用户名, mysqlcfg.pass")
    assert(o.mysqlcfg.root_pass, "未定义mysql root密码, mysqlcfg.root_pass")

    o.port = o.port or "10051"
    o.mysqlcfg.port =  o.mysqlcfg.port or 0
    o.mysqlcfg.db =  o.mysqlcfg.db or "zabbix"
    o.mysqlcfg.sock = o.mysqlcfg.sock or "/var/lib/mysql/mysql.sock"

    setmetatable(o, self)
    self.__index = self


    if not o.web or not o.web.user or not o.web.pass then
        return o
    else
        return o, self.API:Init("http://"..o.host.."/api_jsonrpc.php", o.web.user, o.web.pass)
    end
end

--[[
function zabbix:call(method, params)
end
--]]

function zabbix:getGroupsByNames(groupsNameTable)
    local getGroups = {
        filter = {
            name = groupsNameTable
        }
    }
    --[[
    for i = 1, #groupsNameTable do
        print(groupsNameTable[i])
    end
    --]]

    return self.API:HostGroupsGet(getGroups)
end

function zabbix:getTemplatesByNames(templatesNameTable)
    local templateget = {
        method = "template.get",
        params = {
            output = "extend",
            filter = {
                    host = templatesNameTable
                }
            }
        }
    return self.API:CallWithError(templateget.method, templateget.params)
end

function zabbix:createHostWithIp(hostName, ip, port, groups, templates)

    --  获取群组id
    local gids = {}
    local res, err = self:getGroupsByNames(groups)
    if not err then
        for i = 1, #res do
            -- print(res[i].GroupId, res[i].name)
            gids[i] = {
                groupid = res[i].GroupId
            }
        end
    else
        return err
    end

    --  获取模板id
    local tids = {}
    local res, err = self:getTemplatesByNames(templates)
    if not err then
        for i = 1, #res.result do
            -- print(res.result[i].templateid, res.result[i].name)
            tids[i] = {
                templateid = res.Result[i].templateid
            }
         end
    else
        return err
    end

    --
    local hostcreate ={
        method = "host.create",
        params = {
            host = hostName,
            interfaces = {
                {
                    type = 1,
                    main = 1,
                    useip = 1,
                    ip = ip,
                    dns = "",
                    port = port,
                }

            },
            groups = gids,
            templates = tids,
        }
    }

    local res, err = self.API:CallWithError(hostcreate.method, hostcreate.params)

    if not err then
        if not res.Error then
            return res.result.hostids[1]
        else
            return res.Error
        end
    else
        printerr(err)
        return err
    end

    return nil
end

function zabbix:getHostIpInterface(hostids)
    local pGetInter = {
        method = "hostinterface.get",
        params = {
            output = "extend",
            hostids = hostids,
            filter = {
                useip = 1,
            }
        }
    }
    return self.API:CallWithError(pGetInter.method, pGetInter.params)
end

local function getTypeId (typeName)
    local Type = {
        "Zabbix agent",
        "SNMPv1 agent",
        "Zabbix trapper",
        "simple check",
        "SNMPv2 agent",
        "Zabbix internal",
        "SNMPv3 agent",
        "Zabbix agent (active)",
        "Zabbix aggregate",
        "web item",
        "external check",
        "database monitor",
        "IPMI agent",
        "SSH agent",
        "TELNET agent",
        "calculated",
        "JMX agent",
        "SNMP trap",
    }

    for i = 1, #Type do
        if Type[i] == typeName then
            return i-1
        end
    end
end

local function getValueTypeId(valueTypeName)
    local values = {
        "numeric float",
        "character",
        "log",
        "numeric unsigned",
        "text",
    }

    for i = 1, #values do
        if values[i] == valueTypeName then
            return i-1
        end
    end
end

--[[
-- 不能仅通过appName来获取application id
function zabbix:getApplicationsId(appName)
    local pGAID = {
        method = "application.get",
        params = {
            output = "extend",
            -- output = "applicationidid",
            filter = {
                name = appName,
            }
        }
    }

    return self.API:CallWithError(pGAID.method, pGAID.params)
end
--]]

function zabbix:getHostByName(hostNameTable)
    local pGHI = {
        method = "host.get",
        params = {
            output = "extend",
            filter = {
                host = hostNameTable,
            }
        }
    }
    return self.API:CallWithError(pGHI.method, pGHI.params)
end

function zabbix:createCustomItem(hostName, itemName, itemkey, typeName, valueTypeName, applicationIds, delay)
    local res, gethosterr = zabbix:getHostByName(hostName)
    assert(not gethosterr, "获取主机信息失败")
    local hostid = res.result[1].hostid

    local res, getintererr = zabbix:getHostIpInterface(hostid)
    assert(not getintererr, "获取主机接口信息失败")
    local interfaceId = res.result[1].interfaceid


    local pCCI = {
        method = "item.create",
        params = {
            name = itemName,
            key_ = itemkey,
            type = getTypeId(typeName),
            value_type = getValueTypeId(valueTypeName),
            hostid = hostid,
            -- applications = applicationIds,
            interfaceid = interfaceId,
            delay = delay,
        }
    }

    local res, err = self.API:CallWithError(pCCI.method, pCCI.params)

    assert(not err, "创建自定义监控项失败")
    if res.Error  then
        return res.Error
    else
        return res.result.itemids[1]
    end
end

function zabbix:yumInstallServer()

    assert(self.host==HOST.Ip, "这个我只能在你SSH连接到的机器上面装zabbix")

    local zabbix_yum = "http://repo.zabbix.com/zabbix/3.0/rhel/6/x86_64/zabbix-release-3.0-1.el6.noarch.rpm"

    Cmd{
        "rpm -ivh ".. zabbix_yum,
        "yum install zabbix-server-mysql zabbix-web-mysql -y",

        -- 导入初始数据库
        [[cd /usr/share/doc/zabbix-server-mysql-3* && zcat create.sql.gz | mysql -h ]].. self.mysqlcfg.host ..
                [[ -u]].. self.mysqlcfg.user ..[[ -p]].. self.mysqlcfg.pass.." zabbix",
        --
        [[ setenforce 0 && chmod 755 -R /etc/zabbix/web/]],
        -- HOST.Ip ssh连接的IP
        [[iptables -I INPUT -p tcp -d ]]..self.host..[[ --dport ]]..self.port..[[ -j ACCEPT]],
        --]=]
    }

    --配置数据库连接信息
    self:server_conf("DBHost", self.mysqlcfg.host)
    self:server_conf("DBPassword", self.mysqlcfg.pass)
    if self.mysqlcfg.host == "localhost" then
        self:server_conf("DBSocket", self.mysqlcfg.sock)
    end
end

function zabbix:yumInstallAgent()
    local zabbix_yum = "http://repo.zabbix.com/zabbix/3.0/rhel/6/x86_64/zabbix-release-3.0-1.el6.noarch.rpm"
    Cmd{
        "rpm -ivh ".. zabbix_yum,
        "yum install zabbix-agent -y",
        [[iptables -I INPUT -p tcp -d ]]..HOST.Ip..[[ --dport 10050 -j ACCEPT]],
    }
end

function zabbix:conf_php()

    local cf = [=[
<?php
// Zabbix GUI configuration file.
global \$DB;

\$DB['TYPE']     = 'MYSQL';
\$DB['SERVER']   = ']=]..self.mysqlcfg.host..[=[';
\$DB['PORT']     = ']=]..self.mysqlcfg.port..[=[';
\$DB['DATABASE'] = ']=]..self.mysqlcfg.db..[=[';
\$DB['USER']     = ']=]..self.mysqlcfg.user..[=[';
\$DB['PASSWORD'] = ']=]..self.mysqlcfg.pass..[=[';

// Schema name. Used for IBM DB2 and PostgreSQL.
\$DB['SCHEMA'] = '';

\$ZBX_SERVER      = ']=]..self.host..[=[';
\$ZBX_SERVER_PORT = ']=]..self.port..[=[';
\$ZBX_SERVER_NAME = '';

\$IMAGE_FORMAT_DEFAULT = IMAGE_FORMAT_PNG;
    ]=]

    Cmd([=[echo -e "]=]..cf..[=[" > /etc/zabbix/web/zabbix.conf.php]=])
end

function zabbix:server_conf(key, value)
    Setfkv("/etc/zabbix/zabbix_server.conf", key, value, false, "=", "#")
end

function zabbix:startServer()
    Cmd("service zabbix-server restart")
end

function zabbix:startAgent()
    Cmd("service zabbix-agent restart")
end

function zabbix:addCustem(userparameter, command)
    local zabbix_agentd_conf = "/etc/zabbix/zabbix_agentd.conf"

    local msg = Cmd{
        [=[grep 'UserParameter = ]=]..
                string.sub(userparameter, 1, string.find(userparameter, "%[%*%]")-1)..[=[' ]=] ..
                zabbix_agentd_conf }

    if msg.Code == 1 then
        Cmd{[[echo -e 'UserParameter = ]]..userparameter..
                [[,]]..command..
                [[' >> ]]..zabbix_agentd_conf }
    end
end

function zabbix:agentd_conf(key, value)
    Setfkv("/etc/zabbix/zabbix_agentd.conf", key, value, false, "=", "#")
end