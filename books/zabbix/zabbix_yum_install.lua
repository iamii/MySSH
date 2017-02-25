-- 通过yum安装zabbix
zabbix_pass = "zabbix123"
zabbix_host = "localhost"

mysql_host = "localhost"
mysql_user = "root"
mysql_pass = 123456
mysql_root_pass = 123456
mysql_sock = "/var/lib/mysql/mysql.sock"


dofile("books/php/php_source_install.lua")
dofile("books/mysql/mysql_yum_install.lua")
dofile("books/nginx/nginx_yum_install.lua")
dofile("books/zabbix/zabbix_server_yum_install.lua")
dofile("books/zabbix/zabbix_agent_yum_install.lua")



-- edit php.ini
local phppath = "/usr/local/php-5.6.28/"
local php_ini = phppath ..[[/etc/php.ini]]
local edit_php_ini ={
    [[\cp ]].. phppath ..[[php.ini ]]..php_ini,
    [[sed -i "s/\(^post_max_size = \).*$/\116M/" ]]..php_ini,
    [[sed -i "s/\(^max_execution_time = \).*$/\1300/" ]]..php_ini,
    [[sed -i "s/\(^max_input_time = \).*$/\1300/" ]]..php_ini,
    [[sed -i "s/\;\(date.timezone =\)/\1Asia\/Shanghai/" ]]..php_ini,
    [[sed -i "s/\;\(always_populate_raw_post_data = -1\)/\1/" ]]..php_ini,
    [[sed -ri "s@(mysqli.default_socket =)@\1]]..mysql_sock..[[@" ]]..php_ini,
    [[killall php-fpm && killall php-fpm && killall php-fpm]],
    phppath..[[sbin/php-fpm]],
}

HOST:Cmd(edit_php_ini)

--
HOST:Cmd{"cp /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.test.bak"}
HOST:PutFile("./books/nginx.test.conf", "/etc/nginx/conf.d/default.conf")
HOST:Cmd{[=[sed -i "s/root[[:space:]].*;/root \/usr\/share\/zabbix\/;/" /etc/nginx/conf.d/default.conf]=] }
HOST:Cmd{"service nginx restart"}
