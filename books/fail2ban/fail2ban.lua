--
-- User: iaai
-- Date: 17-3-31
-- Time: 上午9:07
--
require ("books/common")

fail2ban = {}

function fail2ban:new(o)
    o = o or {
        ["fail2ban.d"]= {
            --[[
            -- file
            ["fail2ban.local"] = {
            -- section
                ["[Definition]"]={
                    -- key = value
                    logtarget = "/var/log/fail2ban.log"
                },
            },
            --]]
        },
        ["filter.d"] = {},
        ["action.d"] = {},
        ["jail.d"] = {},
    }

    setmetatable(o, self)
    self.__index = self

    return o
end

-- ---------------------
-- set_conf  --覆盖写入
-- 向目录pdir的配置文件file中输出ini配置项section_table

function fail2ban:set_conf(pdir,file, section_table)
    if not self[pdir] then
        print(pdir,"不正确。")
        return
    end

    if type(section_table) == "table" then
        TableJoin(self[pdir],
            {
                [file] = section_table
            }
        )
    else
        self[pdir][file] = section_table
    end
    -- [[
        -- ----self:jaild_add_conf("test.local")
    local ini = Table2ini(self[pdir][file])
    Cmd{
        "cp /etc/fail2ban/"..pdir.."/"..file ..
                " /etc/fail2ban/"..pdir.."/"..os.date("%Y-%m-%d_%H_%M_%S.bak", os.time()),
        [=[echo ']=]..ini..[=[' > /etc/fail2ban/]=]..pdir..[=[/]=]..file,
    }
    --]]
end

function fail2ban:jail_d_conf(file, section_table)
    self:set_conf("jail.d", file, section_table)
end

function fail2ban:fail2ban_d_conf(file, section_table)
    self:set_conf("fail2ban.d", file, section_table)
end

function fail2ban:action_d_conf(file, section_table)
    self:set_conf("action.d", file, section_table)
end

function fail2ban:filter_d_conf(file, section_table)
    self:set_conf("filter.d", file, section_table)
end

function fail2ban:install()
    if Cmd("which fail2ban-client").Code ~= 0 then
        if Cmd("python --version").Msg > "2.4" then
            InstallEPEL()
            Cmd{
                "yum install -y fail2ban && chkconfig --add fail2ban && chkconfig fail2ban on ",
            }
            if ERR.Code == 0 then
                self:set_conf("fail2ban.d", "fail2ban.local", {
                    Definition = {
                        logtarget = "/var/log/fail2ban.log"
                    }
                }
                )
            end

        end
    else
        print("fail2ban 已安装.")
    end
end

function fail2ban:restart()
    Cmd("service fail2ban restart")
end

