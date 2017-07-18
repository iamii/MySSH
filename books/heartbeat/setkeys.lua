--
-- Created by IntelliJ IDEA.
-- User: iaai
-- Date: 17-1-19
-- Time: 下午4:27
-- To change this template use File | Settings | File Templates.
--
require("books/sshd/sshd")

local msg = HOST:Wait({src="playlist"})

local tkey = msg.Msg.Info

for host, v in pairs(tkey) do
    SSHD.addpubkey("root", v.id_isa)
    SSHD.addknownhost(v.ip, "root", v.host_rsa)
end

-- 设置sshd_config
SSHD.set("RSAAuthentication", "yes")
SSHD.set("PubkeyAuthentication", "yes")
SSHD.set("AuthorizedKeysFile", ".ssh/authorized_keys")

SSHD.reload()