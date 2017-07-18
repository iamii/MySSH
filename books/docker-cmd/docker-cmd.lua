-- User: guang
-- Date: 2017-02-27
-- Time: 10:19


require("books/common")


local function updatekernel()
    local repo={
        [====[
[hop5]
name=www.hop5.in Centos Repository
baseurl=http://www.hop5.in/yum/el6/
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-HOP5
        ]====]
    }
end

local function loadDM()
    Cmd("ls -l /sys/class/misc/device-mapper")
    if ERR.Code ~= 0 then
        Cmd{
            "yum install -y device-mapper",
            "modprobe dm_mod",
        }
    end

end

docker ={}

function docker:new(o)
    o = o or {}

    o.os=GetLinuxVersion()
    o.df = {
        --[====[
        -- FROM 指定基础镜像
        FROM = nil,
        -- RUN 执行命令
        RUN = nil,
        -- COPY	复制文件
        COPY = nil,
        -- ADD	更高级的复制文件
        ADD = nil,
        -- CMD	容器启动命令
        CMD = nil,
        -- ENTRYPOINT	入口点
        ENTRYPOINT = nil,
        -- ENV 设置环境变量
        ENV = nil,
        -- ARG 构建参数
        ARG = nil,
        -- VOLUME 定义匿名卷
        VOLUME = nil,
        -- EXPOSE 暴露端口
        EXPOSE = nil,
        -- WORKDIR 指定工作目录
        WORKDIR = nil,
        -- USER 指定当前用户
        USER = nil,
        -- HEALTHCHECK 健康检查
        HEALTHCHECK = nil,
        -- ONBUILD 仅在被做为基础镜像去构建下一级镜像时执行
        -- ]====]
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function docker:install()
    if self.os.ker < "2.6.32-431" then
        print("版本太低")
        return nil
    elseif self.os.ker < "3.10" then
        print("内核版本低于3.10，建议升级内核，或仅在测试环境使用此docker版本。")

        loadDM()

        InstallEPEL()

        Cmd{
            "yum -y remove docker",
            "sudo yum -y install docker-io",
        }
    else
        print("恭喜版本支持。")
        loadDM()
        Cmd("yum install docker")
    end

    Cmd{
        "service docker restart",
        "docker version",
    }
end

function docker:pull(image)
    Cmd("docker pull "..image)
end

function docker:images()
    Cmd("docker images")
end

function docker:build(contextpath, tag)
    local df=""
    for k, v in pairs(self.df) do
        -- print(k, v)
        -- [[
        if k == "FROM" then
            df =  k.." "..v.."\n"..df
        else
            df = df .."\n".. k .. " " .. v
        end
        --]]
    end
    print(df)
    Cmd{
        "mkdir -p "..contextpath,
        [=[echo ']=]..df..[=[' > ]=]..contextpath..[=[/dockerfile]=],
        "cd "..contextpath.." && docker build -t "..tag.." - < dockerfile",
    }
end

function docker:save(storefile, image, gz)
    if gz then
        Cmd("docker save "..image .." | gzip > ".. storefile)
    else
        Cmd("docker save -o ".. storefile .." "..image)
    end
end

function docker:load(loadfile, imageandtag, gz)
    if gz then
        Cmd("zcat "..loadfile.." | docker import - ".. imageandtag)
    else
        Cmd("docker load < ".. loadfile)
    end
end


