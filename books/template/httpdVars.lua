 httpdVars = {
     Common = {
         DirectoryIndex = "index.html index.php",
         ServerName = "test.test",
         NameVirtualHoste = "*:80",
         DocumentRoote = '"/var/www/html"',
         ServerTokens = "OS",
         ServerRoot = '"/etc/httpd"',
         -- ServerTokens = "OS",
         PidFile = "run/httpd.pid",
         Timeout = 60,
         KeepAlive = "Off",
         MaxKeepAliveRequests = 100,
         KeepAliveTimeout = 1,
         AccessFileName = ".htaccess",
         Include = "conf.d/*.conf",
         User = "apache",
         Group = "apache",
         ServerAdmin = "aaa@bbb.com",
         UseCannoicalName = "off",
         TypesConfig = "/etc/mime.types",
         DefaultType = "text/plain",
         HostnameLookups = "off",
     },
     Directory = {
         {
             value = "/",
             options = {
                 Options = "FollowSynmLinks",
                 AllowOverride = "None",
             }
         },
         {
             value = "/var/www/html",
             options = {
                 Options = "Indexes FollowSymLinks",
                 AllowOverride = "None",
                 Order = "allow,deny",
                 Allow = "from all",
             }
         },
        {
            value = '"/var/www/html/bbs/"',
            options = {
                Options = "FollowSymLinks",
                AllowOverride = "None",
                Order= "allow,deny",
                allow  = "from 192.168.18.0/24",
                deny  = "from 192.168.18.2",
            },
        },
        {
            value = '"/var/www/html/sec/"',
            options = {
                Options = "FollowSymLinks",
                AllowOverride = "None",
                Order = "allow,deny",
                allow = "from 192.168.18.0/24",
                deny = "from 192.168.18.2",
                authtype= "basic",
                authname= "Please input",
                authuserfile= "/etc/httpd/conf/passwd.secret",
                require = "valid-user",
            }
        }
    },
     Listen = {
        80,
        8080,
        8888,
    },
     VirtualHost = {
        {
            value = "*:80",
            options = {
                ServerName = "www.a.com",
                DocumentRoot = "/var/www/html/8000/",
            }
        },
        {
            value = "*:80",
            options = {
                ServerName = "www.b.com",
                DocumentRoot = "/var/www/html/88888/",
            }
        },
    },
     IfModule = {
         {
            modlist = {
                "mod_userdir.c",
            },
             options = {
                 UserDir = "disablesd",
             }
         },
         {
            modlist = {
                "mod_negotiation.c",
                "mod_include.c",
            },
            dirs = {
                value = '"/abc/defg"',
                options = {
                    Options = "Indexes FollowSymLinks",
                }
            },
            options = {
                StartServers = 8,
                MinSpareServers  = 5,
            }
         },
         {
            modlist = {
                "prefork.c",
            },
             options = {
                 StartServers = 8,
                 MinSpareServers = 5,
                 MaxSpareServers =  20,
                 ServerLimit = 256,
                 MaxClients = 256,
                 MaxRequestsPerChild = 400,
             }
         },
         {
             modlist = {
                 "worker.c",
             },
             options = {
                 StartServers = 4,
                 MaxClients = 300,
                 MinSpareThreads = 25,
                 MaxSpareThreads =  75,
                 ThreadsPerChild = 25,
                 MaxRequestsPerChild = 0,
             }
         },
     },
     LoadModule = {
        auth_basic_module = "modules/mod_auth_basic.so",
        auth_digest_module = "modules/mod_auth_digest.so",
        authn_file_module = "modules/mod_authn_file.so",
        authn_alias_module = "modules/mod_authn_alias.so",
        authn_anon_module = "modules/mod_authn_anon.so",
        authn_dbm_module = "modules/mod_authn_dbm.so",
        authn_default_module = "modules/mod_authn_default.so",
        authz_host_module = "modules/mod_authz_host.so",
        authz_user_module = "modules/mod_authz_user.so",
        authz_owner_module = "modules/mod_authz_owner.so",
        authz_groupfile_module = "modules/mod_authz_groupfile.so",
        authz_dbm_module = "modules/mod_authz_dbm.so",
        authz_default_module = "modules/mod_authz_default.so",
        ldap_module = "modules/mod_ldap.so",
        authnz_ldap_module = "modules/mod_authnz_ldap.so",
        include_module = "modules/mod_include.so",
        log_config_module = "modules/mod_log_config.so",
        logio_module = "modules/mod_logio.so",
        env_module = "modules/mod_env.so",
        ext_filter_module = "modules/mod_ext_filter.so",
        mime_magic_module = "modules/mod_mime_magic.so",
        expires_module = "modules/mod_expires.so",
        deflate_module = "modules/mod_deflate.so",
        headers_module = "modules/mod_headers.so",
        usertrack_module = "modules/mod_usertrack.so",
        setenvif_module = "modules/mod_setenvif.so",
        mime_module = "modules/mod_mime.so",
        dav_module = "modules/mod_dav.so",
        status_module = "modules/mod_status.so",
        autoindex_module = "modules/mod_autoindex.so",
        info_module = "modules/mod_info.so",
        dav_fs_module = "modules/mod_dav_fs.so",
        vhost_alias_module = "modules/mod_vhost_alias.so",
        negotiation_module = "modules/mod_negotiation.so",
        dir_module = "modules/mod_dir.so",
        actions_module = "modules/mod_actions.so",
        speling_module = "modules/mod_speling.so",
        userdir_module = "modules/mod_userdir.so",
        alias_module = "modules/mod_alias.so",
        substitute_module = "modules/mod_substitute.so",
        rewrite_module = "modules/mod_rewrite.so",
        proxy_module = "modules/mod_proxy.so",
        proxy_balancer_module = "modules/mod_proxy_balancer.so",
        proxy_ftp_module = "modules/mod_proxy_ftp.so",
        proxy_http_module = "modules/mod_proxy_http.so",
        proxy_ajp_module = "modules/mod_proxy_ajp.so",
        proxy_connect_module = "modules/mod_proxy_connect.so",
        cache_module = "modules/mod_cache.so",
        suexec_module = "modules/mod_suexec.so",
        disk_cache_module = "modules/mod_disk_cache.so",
        cgi_module = "modules/mod_cgi.so",
        version_module = "modules/mod_version.so",
     },
     Files = {
         {
             filematch = [[~ "\.ht"]],
             options = {
                 Order = "allow, deny",
                 Deny = "from all",
                 Statisfy = "All",
             }
         }
     }

 }
