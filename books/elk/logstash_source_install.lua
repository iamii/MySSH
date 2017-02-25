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
    o = o or {pdir = "/opt/", version = "logstash-5.1.1" }
    if not o.pdir or not o.version then
        return nil
    end

    setmetatable(o, self)
    self.__index = self

    --
    local c = openssl:new()
    c:addipcert(logstash.ip)
    return o
end

function logstash:installed()
    Cmd("ls "..self.pdir..self.version)
    if ERR.Code == 2 then
        return false
    else
        return true
    end
end

function logstash:install()
    local lpath
    if os.getenv("OS") == "Windows_NT" then
        lpath = [[D:\Documents\downloads\]]
    else
        lpath = [[/home/iaai/Downloads/]]
    end

    -- 安装jdk
    dofile([[books/jdk/jdk_bin_install.lua]])

    -- upload && tar
    Upload(lpath..self.version..".tar.gz", self.pdir..self.version..".tar.gz")
    Cmd("cd "..self.pdir.." && tar zxvf "..self.version..".tar.gz")
end

function logstash:addpattern(name, pattern)
    -- test for nginx access log
    local patternsPath = "/opt/logstash-5.1.1/vendor/bundle/jruby/1.9/gems/logstash-patterns-core-4.0.2/patterns/"

    Cmd("ls "..patternsPath.. name)

    if ERR.Code ==2 then
        Cmd([[echo -e ']]..pattern..[[' > ]]..patternsPath..name)
    end
end

function logstash:addconf(name, conf)
    Cmd{
            "mkdir "..self.pdir..self.version.."/conf",
            [[echo -e ']]..conf..[[' > ]]..self.pdir..self.version..[[/conf/]]..name
        }
end

function logstash:runconf(confile)
    local ia_in = {
        "cd "..self.pdir..self.version.."/bin","\n",
        ". /etc/profile && nohup ./logstash -f ../conf/"..confile.." &", "\n",
    }
    Ia(ia_in, 30)
end

