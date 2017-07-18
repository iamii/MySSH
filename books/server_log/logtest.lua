--
-- Created by IntelliJ IDEA.
-- User: iaai
-- Date: 17-3-6
-- Time: 上午11:44
-- To change this template use File | Settings | File Templates.

require ("books/server_log/logrotate")
--
Cmd{
    "touch /var/log/log-test-file",
    "head -c 10M < /dev/urandom > /var/log/log-test-file",
}
-- --------------------------------

local log = logrotate:New()

local tmp = {
    "rotate 900",
    "daily",
    "dateext",
    "copytruncate",
    "compress",
    "delaycompress",
    "notifempty",
    "missingok",
    --[[
   -- nocompress           --   不压缩转储
   -- copytruncate         --   打开中的日志转储
   -- nocopytruncate       --   备份日志文件，但是不截断
   -- nocreate             --   不建立新日志
   -- delaycompress        --   延迟压缩，和compress一起使用时，转储的日志文件到下一次转储时才压缩
   -- nodelaycompress      --   转储并压缩
   -- errors address       --   转储时错误信息发送指定地址
   -- ifempty              --   文件为空也转储
   -- notifempty           --   如果文件为空，不转储
   -- mail address         --   发送转储日志到指定邮箱
   -- nomail               --   转储不发邮件
   -- olddir directory     --   转储后的日志文件放入指定的目录，必须和当前日志文件在同一个文件系统
   -- noolddir             --   转储后的日志文件和当前日志文件放在同一个目录下
   -- prerotate/endscript  --   在转储以前需要执行的命令可以放入这个对，这两个关键字必须单独成行
   -- postrotate/endscript --   在转储以后需要执行的命令可以放入这个对，这两个关键字必须单独成行
   -- daily                --   按天存储
   -- weekly               --   按周存储
   -- monthly              --   按月存储
   -- rotate count         --   日志转存保留的前多少份，多余的会被删除
   -- tabootext [+] list   --   让logrotate 不转储指定扩展名的文件，缺省的扩展名是：.rpm-orig, .rpmsave, v, 和 ~
   -- size size            --   当日志文件到达指定的大小时才转储，Size 可以指定 bytes (缺省)以及KB (sizek)或者MB
   -- extension            --   指定转存日志后缀名，例如 .log
   -- dateformat           --   设置日志文件名日期格式默认为 %Y%m%d
   --]]
}

log:AddConf("/tmp/testlogrotate", "/var/log/log-test-file", tmp)

Cmd("grep logrotate /etc/crontab")
if ERR.Code == 1 then
    Cmd([[echo "0 0 * * * `which logrotate` -f /tmp/testlogrotate" >> /var/spool/cron/`whoami`]])
end
