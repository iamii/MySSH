--
-- Created by IntelliJ IDEA.
-- User: guang
-- Date: 2017-01-18
-- Time: 11:33
-- To change this template use File | Settings | File Templates.
--
require("books/common")

local hosts = PLAYLISTINFO

for host, _ in pairs(hosts) do
    if HOST.Ip == hosts[host].ip then
        Cmd("hostname "..host)
    end
    -- [==[
        -- print(HOST.Ip, hosts[host].ip, host)
        if Cmd([[grep ]]..host..[[ /etc/hosts]]).Code == 0 then
            Cmd([=[sed -i '/^.*]=]..host..[=[/d' /etc/hosts]=])
        end
        Cmd([[echo -e "]]..hosts[host].ip..[[ ]]..host..[[" >> /etc/hosts]])
    --]==]
end
