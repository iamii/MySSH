--
-- User: iaai
-- Date: 17-4-25
-- Time: 下午5:17
--
require("books/mysql/mysql")


local cluster = PLAYLISTINFO

local m = mysql:new(cluster.master[HOST.Name].mysqlinfo)

local my_cnf = {
    mysql = {
        ["default-character-set"] = "utf8",
    },
    client = {
        ["default-character-set"] = "utf8",
    },
    mysqld = {
        port = m.port,
        "skip-external-locking",
        ["server-id"] = cluster.master[HOST.Name]["server-id"],
        ["log-bin"] = "mysql-bin",
        ["log-error"] = "/var/log/mysql-err.log",
        ["default-storage-engine"]="INNODB",
        ["init_connect"]="'SET NAMES utf8'",
        ["character-set-server"] = "utf8",
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

local dbs = ""
for i = 1, #cluster.backup.db do
    dbs = dbs .. cluster.backup.db[i].." "
    table.insert(my_cnf.mysqld["replicate-wild-do-table"], cluster.backup.db[i]..".%")
end

Cmd([=[echo "]=]..Table2ini(my_cnf)..[=[" > /etc/my.cnf ]=])

m:yumInstall()
m:start()
m:secure_installation()

--在master上为每个slave创建用于同步的专用用户
for _, v in pairs(cluster.slave) do
    m:grant("*.*", cluster.backup.user, v.mysqlinfo.host, "replication slave", cluster.backup.pass)
end

-- 备份后传送给slave
m:rep_backup(dbs)

if ERR.Code == 0 then
    HOST:Send({info=ERR.Msg})
else
    print("备份数据库："..dbs.."失败。")
end



--[==[
-- 只读锁表
m:exec([[FLUSH TABLES WITH READ LOCK]])

--发送二进制日志文件及偏移
m:exec([[show master status\G]])
local msg =ERR.Msg

local file = msg:match(".-%sFile:%s+(.-%d+)%s")
local pos = msg:match(".-%sPosition:%s+(.-%d+)%s")

DEBUG(msg.."\n", file, pos)
--]==]
