--
-- Created by IntelliJ IDEA.
-- User: guang
-- Date: 2016-12-13
-- Time: 16:56
-- To change this template use File | Settings | File Templates.
--[[
require("./books/common")

helloworld("This is server2")

HOST:ExecCmd("ifconfig eth0", 0)
--]]

HOST:Cmd{"yum install showmount -y"}

local msg = {
    src = "s1",
}
local getmsg = HOST:Wait(msg)

local nfs_server_ip = getmsg.Msg.info.value

local CMDS = {
    "showmount -e "..nfs_server_ip,
    "mount -t nfs "..nfs_server_ip..":/tmp /mnt ",
    "df -h | tail -l",
    -- "echo `date` > /mnt/aaa.txt"
}

HOST:Cmd(CMDS)