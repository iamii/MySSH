--
-- Created by IntelliJ IDEA.
-- User: guang
-- Date: 2016-12-17
-- Time: 20:23
--
local lpath
if os.getenv("OS") == "Windows_NT" then
    lpath = [[D:\Documents\downloads\]]
else
    lpath = [[/home/iaai/Downloads/]]
end

local uppath = [[/opt/]]
local filename = "php-5.6.28"
local prefix = "/usr/local/"..filename

HOST:PutFile(lpath ..filename..".tar.gz", uppath..filename..".tar.gz")

local cmds = {
    "yum install gcc gcc-c++ make gd-devel libjpeg-devel libpng-devel libxml2-devel bzip2-devel libcurl-devel bison -y",

    "cd "..uppath.." && tar zxvf "..filename..".tar.gz",

    "cd "..uppath..filename..
            " && ./configure --prefix="..prefix.." --with-config-file-path="..prefix.."/etc "..
            " --with-bz2 --with-curl --enable-bcmath --enable-sockets --disable-ipv6 --with-gd " ..
            " --with-jpeg-dir=/usr/local --with-png-dir=/usr/local --with-freetype-dir=/usr/local " ..
            " --enable-gd-native-ttf --with-iconv-dir=/usr/local --enable-mbstring --enable-calendar --with-gettext "..
            " --with-libxml-dir=/usr/local --with-zlib --with-pdo-mysql=mysqlnd --with-mysqli=mysqlnd --with-mysql=mysqlnd "..
            " --enable-dom --enable-xml --enable-fpm --with-libdir=lib64 && make clean && make -j 4 && make install",

    "cp "..uppath..filename.."/php.ini-production "..prefix.."/php.ini",

    "cd "..prefix..[[/etc && \cp php-fpm.conf.default php-fpm.conf]],

    prefix.."/sbin/php-fpm",

    "netstat -tnlp | grep 9000",
}

HOST:Cmd(cmds)



