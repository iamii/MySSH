--
-- User: iaai
-- Date: 17-4-25
-- Time: 上午11:40
--
require ("books/common")

mysql_clusters = {}

function mysql_clusters:new(o)
    o = o or {
        nodes = {
            sql1 = { ip = "192.168.18.201", port = 22,
                user = "root", auth = "pw", passwd= "123", keyfile = "test",
                timeout = 2, script = "", st="file"},
            sql2 = { ip = "192.168.18.202", port = 22,
                user = "root", auth = "pw", passwd= "123", keyfile = "test",
                timeout = 2, script = "", st="file"},
        },
        clusters = {
            cluster1 = {
                type = "master_slave",
                -- status = "new",
                backup = {
                    --db = {"test", "world"},
                    db = {"test"},
                    user = "backup",
                    pass = "abcdefg",
                },
                master={
                    sql1 = {
                        ["server-id"] = 11,
                        mysqlinfo = {host = "192.168.18.201", root_user = "root", root_pass = [==[123]==]},
                    },
                },
                slave = {
                    sql2 = {
                        ["server-id"] = 22,
                        mysqlinfo = {host = "192.168.18.202", root_user = "root", root_pass = [==[123]==]},
                    },
                }
            },

        },
    }

    setmetatable(o, self)
    self.__index = self
    return o
end

function mysql_clusters:setup()
    for k, v in pairs(self.clusters) do
        -- 主从复制
        if v.type == "master_slave" then
            for ck, cv in pairs(v.master) do
                self.nodes[ck].st = "file"
                self.nodes[ck].script = "books/mysql/master_server.lua"
            end
            for ck, cv in pairs(v.slave) do
                self.nodes[ck].st = "file"
                self.nodes[ck].script = "books/mysql/slave_server.lua"
            end
            PL_RUN(self.nodes, self.clusters[k])
        end
    end


end


