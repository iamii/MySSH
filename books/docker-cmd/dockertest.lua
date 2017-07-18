-- User: guang
-- Date: 2017-02-27
-- Time: 10:35

require("books/docker-cmd/docker-cmd")

local d = docker:new()

-- [===[
d:install()

-- d:pull("centos:6")
-- d:save("/opt/centos6.tar.gz", "centos:6", "withgz")
-- Download("/opt/centos6.tar.gz", "centos.tar.gz")

local lpath = GetLocalPath()

Upload(lpath.."centos6.tar", "/opt/centos6.tar")

d:load("/opt/centos6.tar", "test/centos:6")

d:images()

--]===]

d.df = {
    -- FROM 指定基础镜像
    FROM = "centos:6",
    -- RUN 执行命令
    RUN = [=[yum -y install httpd && echo "aaaa" > /var/www/html/index.html]=],
    CMD = [=[["/usr/sbin/apachectl", "-D", "FOREGROUND"]]=],
    EXPOSE = "80",
    --[[
    -- COPY	复制文件
    COPY = nil,
    -- ADD	更高级的复制文件
    ADD = "",
    -- CMD	容器启动命令
    CMD = "",
    -- ENTRYPOINT	入口点
    ENTRYPOINT = "",
    -- ENV 设置环境变量
    ENV = "",
    -- ARG 构建参数
    ARG = "",
    -- VOLUME 定义匿名卷
    VOLUME = "",
    -- EXPOSE 暴露端口
    EXPOSE = "",
    -- WORKDIR 指定工作目录
    WORKDIR = "",
    -- USER 指定当前用户
    USER = "",
    -- HEALTHCHECK 健康检查
    HEALTHCHECK = "",
    -- ONBUILD 仅在被做为基础镜像去构建下一级镜像时执行
    --]]
}

d:build("/tmp/dockertest/", "test:v1")

Cmd("docker run -d -P test:v1 && docker ps")

HOST:DisplayHistories()

