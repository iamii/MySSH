--
-- Created by IntelliJ IDEA.
-- User: guang
-- Date: 2016-12-17
-- Time: 21:35
--

assert(mysql_root_pass, "mysql root密码未定义")

local cmds = {
    "yum install mysql-server -y",
    "service mysqld restart",
}
HOST:Cmd(cmds)

local ia_input = {
    "mysql_secure_installation",
    "\n",   -- 初始空密码
    "\n",
    "y",
    "\n",
    mysql_root_pass, "\n",
    mysql_root_pass, "\n",
    "y", "\n",
    "n", "\n",
    "y", "\n",
    "y", "\n"
}
HOST:RunIa(ia_input, 30)
