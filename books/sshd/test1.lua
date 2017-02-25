--
-- Created by IntelliJ IDEA.
-- User: guang
-- Date: 2017-01-16
-- Time: 21:09
-- To change this template use File | Settings | File Templates.
--
require("./books/sshd/sshd")

-- 生成rsa ssh-key

SSHD.keygen("rsa")

local sshuser = "root"
-- cat获取"用户公钥"再发送给test2
Cmd("cat $HOME/.ssh/id_rsa.pub")
local msg = {dst="test2", info={user= sshuser, key=ERR.Msg}}
HOST:Send(msg)

-- 获取test2发送过来的public key
local msg = HOST:Wait({src="test2"})
local user = msg.Msg.Info.user
local pubkey = msg.Msg.Info.key
-- 将"用户公钥"添加到authorized_keys
SSHD.addpubkey(user, pubkey)

-- cat获取"主机公钥"再发送给test2
Cmd("cat /etc/ssh/ssh_host_rsa_key.pub")
local msg = {dst="test2", info={ip=HOST.Ip, key=ERR.Msg}}
HOST:Send(msg)

-- 获取test2发送过来的主机公钥
local usertosave = "root"
local msg = HOST:Wait({src="test2"})
local ip = msg.Msg.Info.ip
local pubkey = msg.Msg.Info.key
-- 将主机公钥添加到用户的known_hosts
SSHD.addknownhost(ip, usertosave, pubkey)

-- 设置sshd_config
SSHD.set("RSAAuthentication", "yes")
SSHD.set("PubkeyAuthentication", "yes")
SSHD.set("AuthorizedKeysFile", ".ssh/authorized_keys")

SSHD.reload()

Cmd("ssh ".. sshuser .."@"..ip.." -i ~".. usertosave .."/.ssh/id_rsa".." whoami")


