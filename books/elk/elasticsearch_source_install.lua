require("./books/common")

elasticsearch = {}

function elasticsearch:new(o)
    o = o or {pdir="/opt/", version="elasticsearch-5.1.1" }
    if not o.pdir or not o.version then
        return nil
    end

    setmetatable(o, self)
    self.__index = self
    return o
end

function elasticsearch:installed()
    Cmd("ls "..self.pdir..self.version)
    if ERR.Code == 2 then
        return false
    else
        return true
    end
end

function elasticsearch:install()
    local lpath
    if os.getenv("OS") == "Windows_NT" then
        lpath = [[D:\Documents\downloads\]]
    else
        lpath = [[/home/iaai/Downloads/]]
    end
    local listenIP = "localhost"

    -- setup jdk
    dofile([[books/jdk/jdk_bin_install.lua]])

    -- "ulimit unlimited"
    -- vm.max_map_count=26144
    Cmd("grep ^vm.max_map_count= /etc/sysctl.conf")
    if ERR.Code == 1 then
        Cmd("echo -e vm.max_map_count=11262144 >> /etc/sysctl.conf".." && sysctl -p")
    else
        Cmd("sysctl -w vm.max_map_count=11262144")
    end

    -- max number of threads 2048
    Cmd{"grep '^elk soft nproc' /etc/security/limits.d/90-nproc.conf"}
    if ERR.Code == 1 then
        Cmd("echo -e 'elk soft nproc 2048' >> /etc/security/limits.d/90-nproc.conf")
    end

    -- upload && tar
    Upload(lpath..self.version..".tar.gz", self.pdir..self.version..".tar.gz")
    Cmd("cd "..self.pdir.." && tar zxvf "..self.version..".tar.gz")

    -- edit elasticsearch.yml
    Cmd("grep ^network.host " ..self.pdir..self.version.."/config/elasticsearch.yml")
    if ERR.Code == 1 then
        Cmd("echo -e network.host: '"..listenIP.."' >> "..self.pdir..self.version.."/config/elasticsearch.yml")
    end

    -- adduser elk
    Cmd{"useradd -MU -s /sbin/nologin elk ",
        "chown elk.elk "..self.pdir..self.version.." -R"}
end

-- run elasticsearch
function elasticsearch:run()
    local ia_input = {
        ". /etc/profile", "\n",
        "ulimit -n 65536", "\n",    -- max file descripter
        "sudo -E -u elk "..self.pdir..self.version.."/bin/elasticsearch -d", "\n"}
    Ia(ia_input, 30)
end
