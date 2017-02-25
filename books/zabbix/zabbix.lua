zabbix = {API = zabbixx(),ip="127.0.0.1",user="Admin",pass="zabbix"}

function zabbix:new(o)
    o = o or {}  -- 如果用户没有提供table，则创建一个
    setmetatable(o, self)
    self.__index = self
    return o, self.API:Init("http://"..o.ip.."/api_jsonrpc.php", o.user, o.pass)
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
    if not res.Error then
        assert(not false, res.Error)
    end
    return res.result.itemids[1]
end