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
        host="localhost",
        port=3306,
        root_user = "root",
        root_pass=[====[!@#$%^]====],
    }
    o.port = o.port or 3306
    setmetatable(o, self)
    self.__index = self
    return o
end

function mysql:yumInstall()
    Cmd("service mysqld status")
    if ERR.Code == 1 then
        Cmd{
            "yum install mysql-server -y",
            "iptables -I INPUT 2 -p tcp --dport "..self.port.." -d "..HOST.Ip.." -j ACCEPT"
        }
    end
end

function mysql:start()
    Cmd("service mysqld status")
    if ERR.Code == 3 then
        Cmd("service mysqld restart")
    end
end


function mysql:secure_installation(time)
    assert(self.root_pass, "mysql root_pass未指定")
    time = time or 30
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
        HOST:RunIa(ia_input, time)
    end
end

-- 赋权
function mysql:grant(db, user, host, privileges, identified)
        Cmd{
            -- [[mysql -h]].. self.host..[[ -P ]]..self.port ..[[ -u]].. self.root_user ..[[ -p]].. self.root_pass..
            [[mysql -hlocalhost -P]]..self.port ..[[ -u]].. self.root_user ..[[ -p]].. self.root_pass..
                    [[ -e "grant ]]..privileges..[[ on ]]..db..[[ to ]]..user..[[@]].. host ..
                    [[ identified by ']]..identified..[[';"]],
            [[mysql -hlocalhost -P]]..self.port ..[[ -u]].. self.root_user ..[[ -p]].. self.root_pass..
                    [[ -e "flush privileges;"]],
        }
end

function mysql:createdb(db)
        Cmd{
            [[mysql -hlocalhost -P]]..self.port..[[ -u]].. self.root_user ..[[ -p]].. self.root_pass..
                    [[ -e "create database ]]..db..[[ character set utf8 collate utf8_bin;"]],
        }
end

function mysql:exec(cmd)
    -- [=[
    Cmd{
        [[mysql --default-character-set=utf8 -hlocalhost -P]]..self.port..[[ -u]].. self.root_user ..[[ -p]].. self.root_pass..
                [[ -e "]]..cmd..[["]],
    }
    --]=]
end

function mysql:impsqlfile(sqlfile)
    Cmd{
        [[mysql --default-character-set=utf8 -hlocalhost -P]]..self.port..[[ -u]].. self.root_user ..[[ -p]].. self.root_pass..[[ < ]]..sqlfile
    }
end

function mysql:rep_backup(database)
     Cmd( [[mysqldump -hlocalhost --skip-comments --skip-lock-tables --single-transaction --flush-logs --master-data=1 ]]..
             [[ -u]]..self.root_user..
             [[ -p]]..self.root_pass..
             [[ -P]]..self.port..
             [[ --databases ]].. database )
end