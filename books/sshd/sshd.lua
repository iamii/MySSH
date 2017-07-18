--
-- Created by IntelliJ IDEA.
-- User: iaai
-- Date: 17-1-15
-- Time: 下午7:21
-- To change this template use File | Settings | File Templates.
--
require("./books/common")

SSHD = {}

function SSHD.keygen(type, keyfile, bits, pwd)
    if type then
        type = " -t "..type
    else
        type = " -t rsa"
    end

    if keyfile then
        keyfile = " -f "..keyfile
    else
        HOST:Cmd{
            "mkdir $HOME/.ssh/ && chmod 700 $HOME/.ssh",
        }
        keyfile = " -f $HOME/.ssh/id_rsa"
    end

    if bits then
        bits = " -b "..bits
    else
        bits = " -b 2048"
    end

    if pwd then
        pwd = " -N "..pwd
    else
        pwd = [[ -N "" ]]
    end

    -- 有覆盖已存在选项?
    HOST:Cmd{[[ssh-keygen ]]..bits..type..keyfile..pwd, }

end

function SSHD.addpubkey(user, key)
    Cmd{"useradd "..user, "mkdir -p ~"..user.."/.ssh" }

    Cmd("grep "..key.." ~"..user.."/.ssh/authorized_keys")
    if ERR.Code ~= 0 then
        Cmd([[echo "]]..key..[[" >> ~]].. user..[[/.ssh/authorized_keys && chmod 600 ~]]..
                user..[[/.ssh/authorized_keys && chown ]]..
                user..[[.]]..user..[[ ~]].. user..[[/.ssh/authorized_keys]])

        Cmd("restorecon -R -v ~"..user.."/.ssh")
    else
        print("指定的key已存在")
    end
end

function SSHD.addknownhost(ip, user, key)
    Cmd{"useradd "..user, "mkdir -p ~"..user.."/.ssh"}
    -- 已存在则删除
    Cmd("grep "..ip.." ~"..user.."/.ssh/known_hosts")
    if ERR.Code == 0 then
        Cmd([=[sed -i '/^]=]..ip..[=[.*/d' ~]=]..
                user..[=[/.ssh/known_hosts]=])
    end

    Cmd(
        [[echo "]]..ip..[[ ]]..key..[[" >> ~]]..
                user..[[/.ssh/known_hosts && chmod 644 ~]]..
                user..[[/.ssh/known_hosts && chown ]]..
                user..[[.]]..user..[[ ~]]..user..[[/.ssh/known_hosts]]
    )
end

function SSHD.set(key, value)
    Cmd{[=[sed -i 's,^#\(]=]..key..
            [=[[[:space:]]\).*$,\1 ]=]..value..
            [=[,' /etc/ssh/sshd_config]=],
    }
end

function SSHD.reload()
    Cmd("service sshd reload")
end

function SSHD.restart()
    Cmd("service sshd restart")
end
