--
-- User: iaai
-- Date: 17-4-25
-- Time: 下午5:18
-- [[

require ("books/mysql/mysql")

local cluster = PLAYLISTINFO

local m = mysql:new(cluster.slave[HOST.Name].mysqlinfo)

local my_cnf = {
    client = {
        ["default-character-set"] = "utf8",
    },
    mysqld = {
        port = m.port,
        "skip-external-locking",
        ["server-id"] = cluster.slave[HOST.Name]["server-id"],
        ["log-bin"] = "mysql-bin",
        ["log-error"] = "/var/log/mysql-err.log",
        ["default-storage-engine"]="INNODB",
        ["character-set-server"] = "utf8",
        ["default-character-set"] = "utf8",
        ["collation-server"] = "utf8_general_ci",
        ["replicate-wild-do-table"] = {
            "下面的真不是段子了",
        },
        binlog_format = "mixed",
        --[[
        test = {
            "下面的是啥玩意儿",
            aaa = "111",
            "bbb",
            ccc = {
               "下面的真不是段子了",
                "abc",
                "def",
            }
        }
        --]]
    }
}

for i = 1, #cluster.backup.db do
    table.insert(my_cnf.mysqld["replicate-wild-do-table"], cluster.backup.db[i]..".%")
end

Cmd([=[echo "]=]..Table2ini(my_cnf)..[=[" > /etc/my.cnf ]=])

m:yumInstall()
m:start()
m:secure_installation()

for k, v in pairs(cluster.master) do
    local msg = HOST:Wait({src=k}).Msg.info
    -- CHANGE MASTER TO MASTER_LOG_FILE='mysql-bin.000026', MASTER_LOG_POS=106;
    local replaceFunc = function (str)
        local st = "master_host='"..v.mysqlinfo.host.."', "
                .."master_user='"..cluster.backup.user.."', "
                .."master_password='"..cluster.backup.pass.."'"
        return str ..", ".. st
    end

    local master_data_info = msg:match("MASTER_LOG_POS=%d*")
    local sql=msg:gsub(master_data_info, replaceFunc)
    sql = sql:gsub("`","")
    m:exec("stop slave;")
    m:exec(sql)
    m:exec("start slave;")
    m:exec([[show slave status\G]])
    DEBUG(ERR.Msg)
end




