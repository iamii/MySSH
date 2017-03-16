--
-- Created by IntelliJ IDEA.
-- User: guang
-- Date: 2016-12-17
-- Time: 21:35
--
require ("books/common")

mysql = {}

function mysql:new(o)
    o = o or {
        host=HOST.Ip,
        root_user = "root",
        root_pass=[====[!@#$%^]====],},

    setmetatable(o, self)
    self.__index = self
    return o
end

function mysql:yumInstall()
    Cmd{
        "yum install mysql-server -y",
        "service mysqld restart",
    }
end

function mysql:secure_installation()
    assert(self.root_pass, "mysql root_pass未指定")
    Cmd([[mysql -uroot -e "show databases;"]])
    if ERR.Code == 0 then
        local ia_input = {
            "mysql_secure_installation",
            "\n",   -- 初始空密码
            "\n",
            "y",
            "\n",
            self.root_pass, "\n",
            self.root_pass, "\n",
            "y", "\n",
            "n", "\n",
            "y", "\n",
            "y", "\n"
        }
        HOST:RunIa(ia_input, 30)
    end
end

-- 赋权
function mysql:grant(db, user, host, privileges, identified)
        Cmd{
            [[mysql -h]].. self.host ..[[ -u]].. self.root_user ..[[ -p]].. self.root_pass..
                    [[ -e "grant ]]..privileges..[[ on ]]..db..[[ to ]]..user..[[@]].. host ..
                    [[ identified by ']]..identified..[[';"]],
            [[mysql -h]].. self.host ..[[ -u]].. self.root_user ..[[ -p]].. self.root_pass..
                    [[ -e "flush privileges;"]],
        }
end

function mysql:createdb(db)
        Cmd{
            [[mysql -h]].. self.host ..[[ -u]].. self.root_user ..[[ -p]].. self.root_pass..
                    [[ -e "create database ]]..db..[[ character set utf8 collate utf8_bin;"]],
        }
end