--
-- Created by IntelliJ IDEA.
-- User: iaai
-- Date: 17-1-19
-- Time: 下午4:27
-- To change this template use File | Settings | File Templates.
--
require("books/sshd/sshd")

SSHD.keygen("rsa")

Cmd("cat $HOME/.ssh/id_rsa.pub")
Cmd("cat /etc/ssh/ssh_host_rsa_key.pub")


