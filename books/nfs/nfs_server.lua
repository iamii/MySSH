--
-- Created by IntelliJ IDEA.
-- User: guang
-- Date: 2016-12-13
-- Time: 16:56
-- To change this template use File | Settings | File Templates.

-- HOST变量为playlist传递过来
-- 此文件所对应的SSHCLIENT指针,无须定义

local template = [[ {{range .dirs -}}
{{.path}} {{ range .clients }} {{.ip_range}}({{.options}}) {{ end }}
{{ end -}} ]]

local vars = {
    dirs = {
        { path = "/tmp", clients = {
            {ip_range = "*", options = "rw"}}},
        { path = "/etc", clients = {
            {ip_range = "192.168.18.0/24", options = "ro"}}},
    }
}

local out = BUFFER()

HOST:Config(template, vars, out)

-- print(out)

local CMDS = {
    "service iptables stop",
    "yum -y install nfs-utils-* portmap-*",
    "echo -e '"..out:String().."' > /etc/exports",
    "service rpcbind restart && service nfs restart",
    "showmount -e 127.0.0.1",
}

local err = HOST:Cmd(CMDS)

if err.Msg.Code ~= -1 then
    local msg = { dst = "s2", info = { key = "IP", value = HOST.Ip } }
    HOST:Send(msg)
end





