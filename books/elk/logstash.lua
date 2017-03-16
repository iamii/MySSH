--
-- Created by IntelliJ IDEA.
-- User: guang
-- Date: 2016-12-26
-- Time: 16:19
-- To change this template use File | Settings | File Templates.
--
require("./books/common")
require("./books/openssl/openssl")

logstash = {}

logstash.ip = HOST.Ip

function logstash:new(o)
    o = o or {pdir = "/opt/", version = "logstash-5.1.1"}
    if not o.pdir or not o.version then
        return nil
    end

    setmetatable(o, self)
    self.__index = self

    return o
end

function logstash:addcert()
    local c = openssl:new()
    c:makeipcert(logstash.ip)
end

function logstash:installed(path)
    if path then
        Cmd("ls "..path)
    else
        Cmd("ls "..self.pdir..self.version)
    end
    if ERR.Code == 2 then
        return false
    else
        return true
    end
end

function logstash:binInstall()
    if self:installed() then
        print("logstash 已安装了。")
        return -1
    end

    local lpath = GetLocalPath()

    -- 安装jdk
    require("books/jdk/jdk")
    local j=jdk:new()
    j:binInstall()

    -- upload && tar
    Upload(lpath..self.version..".tar.gz", self.pdir..self.version..".tar.gz")
    Cmd("cd "..self.pdir.." && tar zxvf "..self.version..".tar.gz")
end

function logstash:addpattern(name, pattern)
    -- test for nginx access log
    local patternsPath = "/opt/"..self.version.."/vendor/bundle/jruby/1.9/gems/logstash-patterns-core-4.0.2/patterns/"

    Cmd("ls "..patternsPath.. name)

    if ERR.Code ==2 then
        Cmd([[echo -e ']]..pattern..[[' > ]]..patternsPath..name)
    end
end

function logstash:addconf(name, conf)
    Cmd("ls "..self.pdir..self.version.."/conf/"..name)
    if ERR.Code == 2 then
        Cmd{
                "mkdir "..self.pdir..self.version.."/conf",
                [[echo -e ']]..conf..[[' > ]]..self.pdir..self.version..[[/conf/]]..name
            }
    end
end


function logstash:runconf(confile)
    Cmd([[ps aux | grep -v grep | grep "logstash.*/conf/]]..confile..[["]])
    if ERR.Code == 1 then
        local ia_in = {
            "cd "..self.pdir..self.version.."/bin","\n",
            ". /etc/profile && nohup ./logstash -f ../conf/"..confile.." &", "\n",
        }
        Ia(ia_in, 30)
    else
        print("logstash:runconf "..confile.."已经运行.")
    end
end

