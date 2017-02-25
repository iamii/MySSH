--
-- Created by IntelliJ IDEA.
-- User: guang
-- Date: 2017-01-18
-- Time: 11:33
-- To change this template use File | Settings | File Templates.
--
    require("books/common")

    local msg = HOST:Wait({src="playlist"})

    local hosts = msg.Msg.Info

    for host, v in pairs(hosts) do
        -- [==[
        if HOST.Ip == hosts[host].ip then
            Cmd("hostname "..host)
        end

        Cmd([[grep ]]..host..[[ /etc/hosts]])
        if ERR.Code == 0 then
            Cmd([=[sed -i '/^]=]..host..[=[.*/d' /etc/hosts]=])
        end
        Cmd([[echo -e "]]..hosts[host].ip..[[ ]]..host..[[" >> /etc/hosts]])
        --]==]
    end
