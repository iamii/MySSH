--
-- Created by IntelliJ IDEA.
-- User: guang
-- Date: 2016-12-17
-- Time: 20:23
--
require("books/common")

php = {}

function php:new(o)
    o = o or {tarfile="php-5.6.30.tar.gz", prefix="/usr/local/" }

    o.ppath, o.version, o.exten = string.match(o.tarfile, "^(php%-(%d+%.%d+%.%d+))%.(.*)$")

    if o.prefix and o.ppath and o.version and o.exten then
        o.prefix = o.prefix.. o.ppath

        setmetatable(o, self)
        self.__index = self

        return o
    else
        print("获取信息失败 ", "prefix:", o.prefix, " ppath:", o.ppath, " version:", o.version, " exten:",o.exten)
    end
end

function php:installed(phppath)
    Cmd("ls "..phppath)
    if ERR.Code == 0 then
        return true
    else
        return false
    end
end

function php:srcInstall()
    local lpath = GetLocalPath()
    local uppath = [[/tmp/]]

        if self:installed(self.prefix) then
            print("php已安装到: "..self.prefix)
        else
            if not self.tarfile then
                print("未配置： tarfile, 不能通过源码方式安装")
                return -1
            end

            HOST:PutFile(lpath ..self.tarfile, uppath..self.tarfile)
            Cmd{
                "yum install gcc gcc-c++ make gd-devel libjpeg-devel libpng-devel libxml2-devel bzip2-devel libcurl-devel bison -y",
                "cd "..uppath.." && tar zxvf ".. self.tarfile,
                "cd "..uppath.. self.ppath ..
                        " && ./configure --prefix="..self.prefix.." --with-config-file-path="..self.prefix.."/etc "..
                        " --with-bz2 --with-curl --enable-bcmath --enable-sockets --disable-ipv6 --with-gd " ..
                        " --with-jpeg-dir=/usr/local --with-png-dir=/usr/local --with-freetype-dir=/usr/local " ..
                        " --enable-gd-native-ttf --with-iconv-dir=/usr/local --enable-mbstring --enable-calendar --with-gettext "..
                        " --with-libxml-dir=/usr/local --with-zlib --with-pdo-mysql=mysqlnd --with-mysqli=mysqlnd --with-mysql=mysqlnd "..
                        " --enable-dom --enable-xml --enable-fpm --with-libdir=lib64 && make clean && make -j 4 && make install",
                -- "cp "..uppath.. ppath .."/php.ini-production  "..prefix.."/php.ini",
                "cp "..uppath.. self.ppath .."/php.ini-production  "..self.prefix.."/etc/php.ini",
                "cd "..self.prefix..[[/etc && \cp php-fpm.conf.default php-fpm.conf]],
                self.prefix.."/sbin/php-fpm",
                "netstat -tnlp | grep 9000",
            }
        end
end


function php:setINI(key, value)
    local phpIni = self.prefix.."/etc/php.ini"
    Setfkv(phpIni, key, value, false, "=", ";")
end

function php:runFpm()
    Cmd{
        "killall php-fpm && killall php-fpm",
        self.prefix.."/sbin/php-fpm",
    }
end



