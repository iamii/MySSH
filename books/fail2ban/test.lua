require("books/fail2ban/fail2ban")

local f2b = fail2ban:new()

f2b:install()

-- [[
local sshPol = {
   jail = {
       ["ssh-iptables"] = {
            enabled  = "true",
            filter   = "sshd",
            action   = "iptables[name=SSH, port=22, protocol=tcp]",
            logpath  = "/var/log/secure",
            maxretry = 5,
            bantime  = 6000,
            findtime  = 600,
            ignoreip = "127.0.0.2/8 192.168.18.1",
        }
   },

}

f2b:jail_d_conf("sshd.local", sshPol.jail)
--]]

local pythonscript = {
    [===[
#!/usr/bin/python
#coding:utf-8

import os, sys
import logging as log
# CRITICAL 50   ERROR 40    WARNING 30      INFO 20     DEBUG  10    NOTSET
log.basicConfig(level=log.DEBUG,
        format='%(levelname)s [line:%(lineno)d] %(message)s',
        datefmt=' %m %d %Y %H:%M:%S',
        filename='/tmp/action_mail_send.log',
        filemode='a')

import smtplib
from email.mime.text import MIMEText


def send_mail(to_list, sub, content):
    user = r'1171872709@qq.com'
    #password = r'ukakodaaouanhssh'
    password = r'ilslpfsspismjddj'
    smtp_serve = r'smtp.qq.com'
    smtp_port = 465

    msg = MIMEText(content)
    msg['Subject'] = sub
    msg['From'] = user
    msg['To'] = to_list

    try:
        server = smtplib.SMTP_SSL(smtp_serve, smtp_port)

        server.set_debuglevel(1)
        server.login(user, password)
        server.sendmail(user, to_list, msg.as_string())
        server.close()
    except Exception, e:
        log.debug('EXCEPTION : %s', e.args)
        #pass

if  __name__ == '__main__':
    log.debug('Get argv %s', sys.argv)
    _to_list = '315313343@qq.com, iaai@vip.qq.com'
    _sub = 'BAN IP: %s, with %s' % (sys.argv[1], sys.argv[2])
    _message = _sub + sys.argv[-1]
    send_mail(_to_list, _sub, _message)
    ]===]
}

local nginxPol = {
    jail = {
        nginx_dos = {
            enabled = "true",
            port = "http, https",
            filter = "nginx_dos",
            logpath = "/var/log/nginx/access.log",
            maxretry = 6,
            findtime = 60,
            bantime = 120,
            -- ["#action"] = [=[iptables-ipset-proto4[name=NGINX_BAN, port="http,https", protocol=tcp]
           action = [=[nginx_dos[filter=httpd-check, cause="60秒内连接超过6次"]]=]
            },
    },
    filter = {
        Definition = {
            failregex = [=[^<HOST> .* .* \[.* .* HTTP/1.* .*]=],
            ignoreregex = "",
        },
    },
    action = {
        Definition = {
            actionban = "/usr/bin/python /etc/fail2ban/action.d/pymail.py <ip> <filter> <cause>"
        },
    },
}

f2b:jail_d_conf("nginx_dos.local", nginxPol.jail)
f2b:filter_d_conf("nginx_dos.local", nginxPol.filter)
f2b:action_d_conf("nginx_dos.local", nginxPol.action)

Cmd([=[echo "]=]..pythonscript[1]..[=[" > /etc/fail2ban/action.d/pymail.py]=])

f2b:restart()
