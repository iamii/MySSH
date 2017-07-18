require("books/common")
require("books/openssl/openssl")

metricbeat = {}
metricbeat.templ = {
    metricbeat = {
        modules = {
            {
                metricsets = {
                    "cpu",
                    "load",
                    "core",
                    "diskio",
                    "filesystem",
                    "fsstat",
                    "memory",
                    "network",
                    "process",
                },
                module = "system",
            },
        },

        enable = true,
        period = "10s",
        processes = {
            "\".*\"",
        },
    },
    output = {
        logstash = {
            enabled = true,
            hosts = {
                "192.168.18.1:5043",
            },
            ssl={
                 -- enable = true,
                 -- certificate = "./logstash-forwarder.crt",
                 -- certificate_key = "./logstash-forwarder.key",
                 certificate_authorities = {"./logstash.crt",}
            },
            timeout = 15,
            flush_interval = "10s",
        }
    }
}

function metricbeat:new(o)
    o = o or {pdir="/opt/", version="metricbeat-5.2.2-linux-x86_64" }
    if not o.pdir or not o.version then
        return nil
    end
    setmetatable(o, self)
    self.__index = self
    return o
end

function metricbeat:installed(path)
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

function metricbeat:binInstall()
    if self:installed() then
        print("metricbeat 已安装了。")
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

function metricbeat:addconf(filename)
    Cmd("ls "..self.pdir..self.version.."/"..filename)
    if ERR.Code == 2 then
        local template
        local out = BUFFER()
        TEMPLCONFIG(template, self.templ, out)
        Cmd([[echo -e "]]..out:String()..[[" > ]]..self.pdir..self.version.."/"..filename)
    else
        print("metricbeat addconf ", filename, "已经存在")
    end
end

function metricbeat:runconf(filename)
    Cmd([[ps aux | grep -v grep | grep "metricbeat.*]]..filename..[["]])
    if ERR.Code == 1 then
        local ia_in = {
            "cd "..self.pdir..self.version, "\n",
            "nohup ./metricbeat -e -c "..filename.." & ", "\n"
        }
        Ia(ia_in, 300)
    else
        print("metricbeat runconf ", filename, "已经运行")
    end
end
