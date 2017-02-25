--
-- Created by IntelliJ IDEA.
-- User: guang
-- Date: 2016-12-17
-- Time: 21:42
--
require("./books/common")

local epel_repo = [==[
[epel]
name=Extra Packages for Enterprise Linux 6 - $basearch
baseurl=http://download.fedoraproject.org/pub/epel/6/$basearch
#mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=epel-6&arch=$basearch
failovermethod=priority
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-6



[epel-debuginfo]
name=Extra Packages for Enterprise Linux 6 - $basearch - Debug
#baseurl=http://download.fedoraproject.org/pub/epel/6/$basearch/debug
mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=epel-debug-6&arch=$basearch
failovermethod=priority
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-6
gpgcheck=1

[epel-source]
name=Extra Packages for Enterprise Linux 6 - $basearch - Source
#baseurl=http://download.fedoraproject.org/pub/epel/6/SRPMS
mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=epel-source-6&arch=$basearch
failovermethod=priority
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-6
gpgcheck=1
]==]

local epel_yum = "http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm"

Cmd("service nginx status")
-- 未处理 先yum epel安装，安装如果报错，再修改baseurl/mirror
if ERR.Code == 1 then
     Cmd{
         "rpm -ivh ".. epel_yum,
         "echo -e '"..epel_repo.."' > /etc/yum.repos.d/epel.repo",
         "yum clean metadata && yum clean all && rpm --rebuilddb",
         "yum install nginx -y",
         "service nginx restart",
         "iptables -I INPUT 1 -p tcp --dport 80 -m state --state NEW -j ACCEPT",
     }
end

