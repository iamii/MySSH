--
-- User: iaai
-- Date: 17-3-6
-- Time: 上午10:37
--
require("./books/common")

logrotate = {
    --[[
    lcf = {
       "compress",              --   通过gzip 压缩转储以后的日志
       "nocompress",           --   不压缩转储
       "copytruncate",         --   打开中的日志转储
       "nocopytruncate",       --   备份日志文件，但是不截断
       "nocreate",             --   不建立新日志
       "delaycompress",        --   延迟压缩，和compress一起使用时，转储的日志文件到下一次转储时才压缩
       "nodelaycompress",      --   转储并压缩
       "errors address",       --   转储时错误信息发送指定地址
       "ifempty",              --   文件为空也转储
       "notifempty",           --   如果文件为空，不转储
       "mail address",         --   发送转储日志到指定邮箱
       "nomail",               --   转储不发邮件
       "olddir directory",     --   转储后的日志文件放入指定的目录，必须和当前日志文件在同一个文件系统
       "noolddir",             --   转储后的日志文件和当前日志文件放在同一个目录下
       "prerotate/endscript",  --   在转储以前需要执行的命令可以放入这个对，这两个关键字必须单独成行
       "postrotate/endscript", --   在转储以后需要执行的命令可以放入这个对，这两个关键字必须单独成行
       "daily",                --   按天存储
       "weekly",               --   按周存储
       "monthly",              --   按月存储
       "rotate count",         --   日志转存保留的前多少份，多余的会被删除
       "tabootext [+] list",   --   让logrotate 不转储指定扩展名的文件，缺省的扩展名是：.rpm-orig, .rpmsave, v, 和 ~
       "size size",            --   当日志文件到达指定的大小时才转储，Size 可以指定 bytes (缺省)以及KB (sizek)或者MB
       "extension",            --   指定转存日志后缀名，例如 .log
       "dateformat",           --   设置日志文件名日期格式默认为 %Y%m%d
    }
    --]]
}

function logrotate:New(o)
    logrotate:Install()
    if ERR.Code == 0 then
        o = o or {}
        setmetatable(o, self)
        self.__index = self

        return o
    else
        print("logrotate 未正确安装")
    end

    return nil
end

function logrotate:Install()
    Cmd("which logrotate")
    if ERR.Code ~= 0 then
        Cmd("yum -y install logrotate crontabs")
    end
end

function logrotate:AddConf(logrotateConfilePath, logFilePath, logrotateConfig)
    local lcf = logFilePath .. " {"
    for i = 1, #logrotateConfig do
        lcf = lcf .."\n\t"..logrotateConfig[i]
    end
    lcf = lcf.."\n}"
    Cmd([[echo -e "]]..lcf..[[" > ]]..logrotateConfilePath)
end


