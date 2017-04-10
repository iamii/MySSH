--
-- Created by IntelliJ IDEA.
-- User: guang
-- Date: 2017-01-01
-- Time: 11:14
--
require("books/common")
require("books/openssl/openssl")

filebeat = {}
filebeat.templ = {
        filebeat = {
            prospectors = {
                {
                    paths = {"/var/log/nginx/access.log",},
                    fields = {type="nginx_logs"},
                },
            }
        },
        output = {
             logstash = {
                 enabled = true,
                 hosts = {
                     "localhost:5043",
                 },
                 ssl={
                     -- enable = true,
                     -- certificate = "./logstash-forwarder.crt",
                     -- certificate_key = "./logstash-forwarder.key",
                     certificate_authorities = {"./logstash.crt",}
                 },
                 timeout = 15
             }
        }
    }

function filebeat:new(o)
    o = o or {pdir="/opt/", version="filebeat-5.1.1-linux-x86_64" }
    if not o.pdir or not o.version then
        return nil
    end
    setmetatable(o, self)
    self.__index = self
    return o
end

function filebeat:installed(path)
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

function filebeat:binInstall()
    if self:installed() then
        print("filebeat 已安装了。")
        return -1
    end

    local lpath = GetLocalPath()
    -- setup jdk
    require("books/jdk/jdk")
    local j=jdk:new()
    j:binInstall()

    -- upload && tar
    Upload(lpath..self.version..".tar.gz", self.pdir..self.version..".tar.gz")
    Cmd("cd "..self.pdir.." && tar zxvf "..self.version..".tar.gz")
end

function filebeat:addconf(filename)
    Cmd("ls "..self.pdir..self.version.."/"..filename)
    if ERR.Code == 2 then
        local template
        local out = BUFFER()
        HOST:TemplConfig(template, self.templ, out)
        Cmd([[echo -e "]]..out:String()..[[" > ]]..self.pdir..self.version.."/"..filename)
    else
        print("filebeat addconf ", filename, "已经存在")
    end
end

function filebeat:runconf(filename)
    Cmd([[ps aux | grep -v grep | grep "filebeat.*]]..filename..[["]])
    if ERR.Code == 1 then
        local ia_in = {
            "cd "..self.pdir..self.version, "\n",
            "nohup ./filebeat -c "..filename.." & ", "\n"
        }
        Ia(ia_in, 300)
    else
        print("filebeat runconf ", filename, "已经运行")
    end
end


