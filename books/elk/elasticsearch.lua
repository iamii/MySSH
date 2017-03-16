require("books/common")

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

function elasticsearch:installed(path)
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

function elasticsearch:binInstall()
    local lpath =GetLocalPath()
    local listenIP = "localhost"

    if self:installed() then
        print("elasticsearch已安装了。")
        return -1
    end

    -- setup jdk
    require("books/jdk/jdk")
    local j=jdk:new()
    j:binInstall()

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
        "chown elk.elk "..self.pdir..self.version.." -R" }


end

-- run elasticsearch
function elasticsearch:start()
    Cmd([[ps aux | grep -v grep | grep "Elasticsearch -d"]])
    if ERR.Code == 1 then
        local ia_input = {
            ". /etc/profile", "\n",
            "ulimit -n 65536", "\n",    -- max file descripter
            "sudo -E -u elk "..self.pdir..self.version.."/bin/elasticsearch -d", "\n"}
        Ia(ia_input, 30)
    else
        print("elasticsearch 已经运行")
    end
end

function elasticsearch:restart()
    Cmd([[ps aux | grep -v grep | grep "Elasticsearch -d" | awk '{print $2; exit -1}']])
    if ERR.Code == -1 then
        local pid = ERR.Msg
        Cmd("kill -15 "..pid.." || kill -9 "..pid)
        local ia_input = {
            ". /etc/profile", "\n",
            "ulimit -n 65536", "\n",    -- max file descripter
            "sudo -E -u elk "..self.pdir..self.version.."/bin/elasticsearch -d", "\n"}
        Ia(ia_input, 30)
    end
end
