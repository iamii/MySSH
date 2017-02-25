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

function kibana:installed()
    Cmd("ls "..self.pdir..self.version)
    if ERR.Code == 2 then
        return false
    else
        return true
    end
end

function kibana:install()
    local lpath
    if os.getenv("OS") == "Windows_NT" then
        lpath = [[D:\Documents\downloads\]]
    else
        lpath = [[/home/iaai/Downloads/]]
    end
    local server_host = "127.0.0.1"
    -- setup jdk
    dofile([[books/jdk/jdk_bin_install.lua]])

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
    local ia_input = {
        "sudo -E -u elk nohup "..self.pdir..self.version.."/bin/kibana > /dev/null 2>&1 & ",
        "\n"
    }
    Ia(ia_input, 50)

end

function kibana:install_nginx()
    -- nginx
    dofile("./books/nginx/nginx_yum_install.lua")

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



