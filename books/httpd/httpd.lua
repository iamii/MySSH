--
-- Created by IntelliJ IDEA.
-- User: guang
-- Date: 2016-12-20
-- Time: 09:21
-- To change this template use File | Settings | File Templates.
--
require ("books/common")

httpd = {}

function httpd:new(o)
   o = o or {
       config = {
           -- 隐藏版本号等信息
           ServerTokers = "Prod",
           -- 服务器保存其配置、出错和日志文件等的根目录
            -- 不要在目录路径后加斜杠
           ServerRoot = "/etc/httpd",
           -- pidfile
           PidFile="run/httpd.pid",
           Timeout = 60,
           -- 关闭/启用长连接，(一次连接，多次请求)
           KeepAlive = "Off",
           -- 同一连接中请求的超时时间
           KeepAliveTimeout = 15,
           -- IfModule
           IfModule = {
               ["prefork.c"]={
                   -- 启动时服务器启动的进程数
                   StartServers = 8,
                   -- 保有的备用进程的最小数目
                   MinSpareServers  = 5,
                   -- 保有的备用进程的最大数目
                   MaxSpareServers = 20,
                   -- 服务器允许配置进程数的上限
                   ServerLimit = 256,
                   -- 同时最多能发起访问个数
                   MaxClients = 256,
                   -- 一个服务进程允许的最大请求数
                   MaxRequestsPerChild = 4000,
               },
               ["worker.c"]={
                   StartServers = 4,
                   MinSpareServers  = 300,
                   MaxSpareServers = 25,
                   ServerLimit = 75,
                   MaxClients = 25,
                   MaxRequestsPerChild = 0,
               },
               ["mod_userdir.c"]={
                   UserDir = "disabled",
               },
               ["mod_mime_magic.c"]={
                   MIMEMagicFile = "conf/magic",
               },
               ["mod_dav_fs.c"]= {
                   DAVLockDB = "/var/lib/dav/lockdb",
               },
           },
           Listen = {80, 8080},
           LoadModule = {
               auth_basic_module="modules/mod_auth_basic.so,",
               auth_digest_module="modules/mod_auth_digest.so",
               authn_file_module="modules/mod_authn_file.so",
               authn_alias_module="modules/mod_authn_alias.so",
               authn_anon_module="modules/mod_authn_anon.so",
               authn_dbm_module="modules/mod_authn_dbm.so",
               authn_default_module="modules/mod_authn_default.so",
               authz_host_module="modules/mod_authz_host.so",
               authz_user_module="modules/mod_authz_user.so",
               authz_owner_module="modules/mod_authz_owner.so",
               authz_groupfile_module="modules/mod_authz_groupfile.so",
               authz_dbm_module="modules/mod_authz_dbm.so",
               authz_default_module="modules/mod_authz_default.so",
               ldap_module="modules/mod_ldap.so",
               authnz_ldap_module="modules/mod_authnz_ldap.so",
               include_module="modules/mod_include.so",
               log_config_module="modules/mod_log_config.so",
               logio_module="modules/mod_logio.so",
               env_module="modules/mod_env.so",
               ext_filter_module="modules/mod_ext_filter.so",
               mime_magic_module="modules/mod_mime_magic.so",
               expires_module="modules/mod_expires.so",
               deflate_module="modules/mod_deflate.so",
               headers_module="modules/mod_headers.so",
               usertrack_module="modules/mod_usertrack.so",
               setenvif_module="modules/mod_setenvif.so",
               mime_module="modules/mod_mime.so",
               dav_module="modules/mod_dav.so",
               status_module="modules/mod_status.so",
               autoindex_module="modules/mod_autoindex.so",
               info_module="modules/mod_info.so",
               dav_fs_module="modules/mod_dav_fs.so",
               vhost_alias_module="modules/mod_vhost_alias.so",
               negotiation_module="modules/mod_negotiation.so",
               dir_module="modules/mod_dir.so",
               actions_module="modules/mod_actions.so",
               speling_module="modules/mod_speling.so",
               userdir_module="modules/mod_userdir.so",
               alias_module="modules/mod_alias.so",
               substitute_module="modules/mod_substitute.so",
               rewrite_module="modules/mod_rewrite.so",
               proxy_module="modules/mod_proxy.so",
               proxy_balancer_module="modules/mod_proxy_balancer.so",
               proxy_ftp_module="modules/mod_proxy_ftp.so",
               proxy_http_module="modules/mod_proxy_http.so",
               proxy_ajp_module="modules/mod_proxy_ajp.so",
               proxy_connect_module="modules/mod_proxy_connect.so",
               cache_module="modules/mod_cache.so",
               suexec_module="modules/mod_suexec.so",
               disk_cache_module="modules/mod_disk_cache.so",
               cgi_module="modules/mod_cgi.so",
               version_module="modules/mod_version.so",

    },
           Include = "conf.d/*.conf",
           User = "apache",
           Group = "apache",
           ServerAdmin = "root@localhost",
           ServerName = "www.test.com:80",
           UseCannonicalName= "Off",
           DocumentRoot = "/var/www/html",
           Directory = {
               ["/"]= {
                   Options = "FollowSymLinks",
                   AllowOverride = "None",
               },
               ["/var/www/html"]= {
                   Options = {"Indexes", "FollowSymLinks"},
                   AllowOverride = "None",
                   Order = "allow, deny",
                   Allow = "from all",
               },
               ["/var/www/icons"]= {
                   Options = {"Indexes", "MultiViews", "FollowSymLinks"},
                   AllowOverride = "None",
                   Order = "allow, deny",
                   Allow = "from all",
               },
               ["/var/www/cgi-bin"]= {
                   Options = {"None"},
                   AllowOverride = "None",
                   Order = "allow, deny",
                   Allow = "from all",
               },
           },
           DirectoryIndex = {"index.html", "index.html.var" },
           AccessFileName = ".htaccess",
           Files = {
               ["~ \"^\.ht\""] = {
                   Order = "allow, deny",
                   Deny = "from all",
                   Satisfy = "All",
               },
           },
           TypesConfig = "/etc/mime.types",
           DefaultType = "text/plain",
           HostnameLookups = "Off",
           ErrorLog = "logs/error_log",
           LogLevel = "warn",
           LogFormat = {
               [["%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined]],
               [["%h %l %u %t \"%r\" %>s %b" common]],
               [["%{Referer}i -> %U" referer]],
               [[ "%{User-agent}i" agent]],
           },
           CustomLog="logs/access_log combined",
           ServerSignature="On",
           Alias = {
               ["/icons/"] = {
                   [["/var/www/icons/"]],
               },
               ["/error/"] = {
                   [["/var/www/error/"]]
               },

           },
           ScriptAlias = {
               ["/cgi-bin"]={[["/var/www/cgi-bin/"]]},
           },
           IndexOptions = {"FancyIndexing", "VersionSort", "NameWidth=*", "HTMLTable", "Charset=UTF-8"},
           AddIconByEncoding = {"(CMP,/icons/compressed.gif)", "x-compress", "x-gzip"},
           AddIconByType = {
               {"(TXT,/icons/text.gif) text/*"},
               {"(IMG,/icons/image2.gif) image/*"},
               {"(SND,/icons/sound2.gif) audio/*"},
               {"(VID,/icons/movie.gif) video/*"},
           },
           AddIcon = {
               "/icons/binary.gif .bin .exe",
               "/icons/binhex.gif .hqx",
               "/icons/tar.gif .tar",
               "/icons/world2.gif .wrl .wrl.gz .vrml .vrm .iv",
               "/icons/compressed.gif .Z .z .tgz .gz .zip",
               "/icons/a.gif .ps .ai .eps",
               "/icons/layout.gif .html .shtml .htm .pdf",
               "/icons/text.gif .txt",
               "/icons/c.gif .c",
               "/icons/p.gif .pl .py",
               "/icons/f.gif .for",
               "/icons/dvi.gif .dvi",
               "/icons/uuencoded.gif .uu",
               "/icons/script.gif .conf .sh .shar .csh .ksh .tcl",
               "/icons/tex.gif .tex",
               "/icons/bomb.gif /core",

               "/icons/back.gif ..",
               "/icons/hand.right.gif README",
               "/icons/folder.gif ^^DIRECTORY^^",
               "/icons/blank.gif ^^BLANKICON^^",
           },
           DefaultIcon="/icons/unknown.gif",
           ReadmeName="README.html",
           HeaderName="HEADER.html",
           IndexIgnore = {".??*", "*~", "*#", "HEADER*", "README*", "RCS", "CVS", "*,v", "*,t"},
           AddLanguage = {
               "ca .ca",
               "cs .cz .cs",
               "da .dk",
               "de .de",
               "el .el",
               "en .en",
               "eo .eo",
               "es .es",
               "et .et",
               "fr .fr",
               "he .he",
               "hr .hr",
                "it .it",
                "ja .ja",
                "ko .ko",
                "ltz .ltz",
                "nl .nl",
                "nn .nn",
                "no .no",
                "pl .po",
                "pt .pt",
                "pt-BR .pt-br",
                "ru .ru",
                "sv .sv",
                "zh-CN .zh-cn",
                "zh-TW .zh-tw",

            },
           LanguagePriority={"en", "ca", "cs", "da", "de", "el", "eo", "es", "et", "fr", "he", "hr", "it", "ja", "ko", "ltz", "nl", "nn", "no", "pl", "pt", "pt-BR", "ru", "sv", "zh-CN", "zh-TW",},
           ForceLanguagePriority="Prefer Fallback",
           AddDefaultCharset="UTF-8",
           AddType={"application/x-compress .Z", "application/x-gzip .gz .tgz", "application/x-gzip .gz .tgz", "application/x-pkcs7-crl .crl", "text/html .shtml"},
           AddHandler = {"type-map var", },
           AddOutputFilter = {"INCLUDES .shtml"},
    }
   }

    setmetatable(o, self)
    self.__index = self
    return o
end

function httpd:install()
    local cmds = {
        "yum install httpd -y",
        "service httpd restart",
        "setenforce 0",
        [[iptables -I INPUT -p tcp -d ]]..HOST.Ip..[[ --dport 80 -j ACCEPT]],
    }

    Cmd(cmds)
end
