--
-- Created by IntelliJ IDEA.
-- User: guang
-- Date: 2017-01-01
-- Time: 11:51
--

openssl = {}

function openssl:new(o)
    o = o or {private = "/etc/pki/tls/private/", certs = "/etc/pki/tls/certs/", cnf= "/etc/pki/tls/openssl1.cnf"}
    if not o.private or not o.certs then
        return nil
    else
        Cmd{
            "mkdir -p "..o.private.." "..o.certs,
            "cp /etc/pki/tls/openssl.cnf "..o.cnf
        }
    end
    setmetatable(o, self)
    self.__index = self
    return o
end


local function addiptov3_ca(ossl, ip)
    Cmd([=[grep "^subjectAltName[[:space:]]=[[:space:]]IP\:" ]=]..ossl.cnf)
    if ERR.Code == 1 then
        Cmd([=[sed -i '/\[[[:space:]]v3_ca[[:space:]]\]/asubjectAltName = IP:]=]..ip..[=[' ]=]..ossl.cnf)
    elseif ERR.Code == 0 then
         Cmd([[sed -i 's@\(^subjectAltName.*IP\:\).*$@\1]]..ip..[[@' ]]..ossl.cnf)
    end
end

function openssl:addipcert(hostip)
    addiptov3_ca(self, hostip)
    Cmd{
        "openssl req -config "..self.cnf..
                " -x509 -days $((100*365))"..
                " -batch -nodes -newkey rsa:2048 "..
                " -keyout "..self.private.. hostip ..".key "..
                " -out "..self.certs.. hostip ..".crt "
    }
end
