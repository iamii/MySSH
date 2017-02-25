--
-- Created by IntelliJ IDEA.
-- User: guang
-- Date: 2017-01-01
-- Time: 11:14
--
require("./books/common")
require("./books/openssl/openssl")

filebeat = {}
filebeat.templ =
    {
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

function filebeat:installed()
   Cmd("ls "..self.pdir..self.version)
   if ERR.Code == 2 then
    return false
   else
    return true
   end
end

function filebeat:install()
    local lpath
    if os.getenv("OS") == "Windows_NT" then
        lpath = [[D:\Documents\downloads\]]
    else
        lpath = [[/home/iaai/Downloads/]]
    end
    -- setup jdk
    dofile([[books/jdk/jdk_bin_install.lua]])
    -- upload && tar
    Upload(lpath..self.version..".tar.gz", self.pdir..self.version..".tar.gz")
    Cmd("cd "..self.pdir.." && tar zxvf "..self.version..".tar.gz")

end

function filebeat:addconf(filename)
    local template
    local out = BUFFER()
    HOST:Config(template, self.templ, out)
    Cmd([[echo -e "]]..out:String()..[[" > ]]..self.pdir..self.version.."/"..filename)
end

function filebeat:runconf(filename)
    local ia_in = {
        "cd "..self.pdir..self.version, "\n",
        "nohup ./filebeat -c "..filename.." & ", "\n"
    }
    Ia(ia_in, 300)
end


