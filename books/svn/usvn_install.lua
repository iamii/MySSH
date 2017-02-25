--
-- Created by IntelliJ IDEA.
-- User: guang
-- Date: 2016-12-20
-- Time: 09:29
-- To change this template use File | Settings | File Templates.
--
local mysql_host = "localhost"
local mysql_root_pass = "123456"
local usvn_admin_pass = "87654321"
local filename = "usvn-1.0.7"
local wpath = "/var/www/"..filename

HOST:PutFile([[d:\Documents\Download\]]..filename..".zip", "/opt/"..filename..".zip")

--[[
--	On "public" folder USVN should have:
temporary write access for install
read access
Good rights on "public".
On "config" folder USVN should have:
permanent write access
permanent read access
Good rights on "config".
--]]

local cmds = {
    "setenforce 0 && service iptables stop",
    "yum -y install "..
            "unzip httpd subversion mod_dav_svn php php-mysql "..
            "mysql-server perl-DBI perl-DBD-mysql mysql-devel mod_auth_mysql",
    "svnserve --version",
    "cd /opt && unzip "..filename..".zip",
    [[mv /opt/]]..filename..[[ /var/www/]],
    -- [=[
    [[cd ]]..wpath..[[ && ]]..
            [[mkdir files && ]]..
            [[chown apache.apache config public && chown -R apache.apache files ]],
    --]=]
    "service httpd restart && service mysqld restart",
    "mysqladmin -u root password "..mysql_root_pass,
    "chkconfig httpd on",
    "chkconfig mysqld on",
    "chkconfig svnserve on",
}

HOST:Cmd(cmds)

local config_ini = [[
[general]
url.base = "/usvn"
translation.locale = "zh_CN"
timezone = "Asia/Shanghai"
system.locale = "aa_DJ.utf8"
template.name = "usvn"
site.title = "USVN"
site.ico = "medias/usvn/images/logo_small.tiff"
site.logo = "medias/usvn/images/logo_trans.png"
subversion.path = "]]..wpath..[[/files/"
subversion.passwd = "]]..wpath..[[/files/htpasswd"
subversion.authz = "]]..wpath..[[/files/authz"
subversion.url = "http://]]..HOST.Ip..[[/usvn/svn/"
database.adapterName = "PDO_MYSQL"
database.prefix = "usvn_"
database.options.host = ]]..mysql_host.."\n"..
[[database.options.username = "root"
database.options.password = ]]..mysql_root_pass.."\n"..
[[database.options.dbname = "usvn"
update.checkforupdate = "0"
update.lastcheckforupdate = "0"
version = "1.0.7"
]]

HOST:Cmd{"echo -e '"..config_ini.."' > "..wpath.."/config/tempconfig.ini" }

HOST:Cmd{"php "..wpath.."/app/install/install-cli.php -l admin -p " ..usvn_admin_pass..
        " -a " ..wpath.."/public/.htaccess -c "..wpath.."/config/tempconfig.ini"}

local apache_Dir = [[
Alias /usvn "]]..wpath..[[/public"
<Directory "]]..wpath..[[/public">
    Options +SymLinksIfOwnerMatch
    AllowOverride All
    Order allow,deny
    Allow from all
</Directory>
<Location /usvn/svn/>
	ErrorDocument 404 default
	DAV svn
	Require valid-user
	SVNParentPath ]]..wpath..[[/files/svn
	SVNListParentPath off
	AuthType Basic
	AuthName "USVN"
	AuthUserFile ]]..wpath..[[/files/htpasswd
	AuthzSVNAccessFile ]]..wpath..[[/files/authz
</Location>
]]

HOST:Cmd{"echo -e '"..apache_Dir.."' >> /etc/httpd/conf.d/usvn.conf" }

HOST:Cmd{"service httpd restart" }

HOST:Cmd{"curl " ..HOST.Ip.. "/usvn/install.php"}



