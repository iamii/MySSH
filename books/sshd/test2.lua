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

local testuser = "root"
-- cat获取"用户公钥"再发送给test1
Cmd("cat $HOME/.ssh/id_rsa.pub")
local msg = {dst="test1", info={user=testuser, key=ERR.Msg}}
HOST:Send(msg)

-- 获取test1发送过来的public key
local msg = HOST:Wait({src="test1"})
local user = msg.Msg.Info.user
local pubkey = msg.Msg.Info.key
-- 将"用户公钥"添加到authorized_keys
SSHD.addpubkey(user, pubkey)

-- cat获取"主机公钥"再发送给test1
Cmd("cat /etc/ssh/ssh_host_rsa_key.pub")
local msg = {dst="test1", info={ip=HOST.Ip,  key=ERR.Msg}}
HOST:Send(msg)

-- 获取test1发送过来的主机公钥
local msg = HOST:Wait({src="test1"})
local user = "root"
local ip = msg.Msg.Info.ip
local pubkey = msg.Msg.Info.key
-- 将主机公钥添加到用户的known_hosts
SSHD.addknownhost(ip, user, pubkey)

-- 设置sshd_config
SSHD.set("RSAAuthentication", "yes")
SSHD.set("PubkeyAuthentication", "yes")
SSHD.set("AuthorizedKeysFile", ".ssh/authorized_keys")

SSHD.reload()

Cmd("ssh "..testuser.."@"..ip.." -i ~"..user.."/.ssh/id_rsa".." whoami")