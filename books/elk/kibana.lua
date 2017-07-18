require("./books/common")

kibana = {}

function kibana:new(o)
    o = o or {pdir="/opt/", version="kibana-5.1.1-linux-x86_64" }
    if not o.pdir or not o.version then
        return nil
    end

    setmetatable(o, self)
    self.__index = self
    return o
end

function kibana:installed(path)
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

function kibana:binInstall()

    if self:installed() then
        print("kibana 已安装了。")
        return -1
    end

    local lpath = GetLocalPath()
    local server_host = "127.0.0.1"
    -- setup jdk
    require("books/jdk/jdk")
    local j=jdk:new()
    j:binInstall()

    -- upload&&tar
    Upload(lpath..self.version..".tar.gz", self.pdir..self.version..".tar.gz")
    Cmd("cd "..self.pdir.." && tar zxvf "..self.version..".tar.gz")

    -- editkibana.yml
    Cmd("grep ^server.host " ..self.pdir..self.version.."/config/kibana.yml")
    if ERR.Code == 1 then
        Cmd("echo -e server.host: '"..server_host.."' >> "..self.pdir..self.version.."/config/kibana.yml")
    end

    -- adduser elk
    Cmd{"useradd -MU -s /sbin/nologin elk ",
        "chown elk.elk "..self.pdir..self.version.." -R"}

end

function kibana:run()
    Cmd([[ps aux | grep -v grep | grep "]]..self.version..[["]])
    if ERR.Code == 1 then
        local ia_input = {
            "sudo -E -u elk nohup "..self.pdir..self.version.."/bin/kibana > /dev/null 2>&1 & ",
            "\n"
        }
        Ia(ia_input, 50)
    else
        print("kibana 已经运行")
    end
end

function kibana:install_nginx()
    -- nginx
    require("books/nginx/nginx")
    local n=nginx:new()
    n:yumInstall()

    local kibana_conf = [[
    server {
         listen 80;
         server_name elk.xxx.com;
         location / {
                proxy_pass http://127.0.0.1:5601;
         #       proxy_http_version 1.1;
         #       proxy_set_header Upgrade $http_upgrade;
         #       proxy_set_header Connection 'upgrade';
         #       proxy_set_header Host $host;
         #       proxy_cache_bypass $http_upgrade;
          }
     }
    ]]

    Cmd([[echo -e "]]..kibana_conf..[[" >> /etc/nginx/conf.d/kibana.conf && nginx -s reload && setenforce 0]])
end



