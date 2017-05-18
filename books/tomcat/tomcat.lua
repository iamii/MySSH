-- User: guang
-- Date: 2017-02-16
-- Time: 11:07

require("books/common")

tomcat ={}

function tomcat:new(o)
    o = o or {
        filename="apache-tomcat-7.0.75.tar.gz",
        CATALINA_HOME="/usr/local/tomcat",
        CATALINA_BASE="/opt/tomcat-instance/test.com",
        instancepath="/usr/tomcat-instance/",
        jdk=jdk:new(
            {
                filename = "jdk-8u121-linux-x64.tar.gz",
                version="jdk1.8.0_121",
                path = "/usr/local/",
            }),
    }

    setmetatable(o, self)
    self.__index = self
    return o
end

function tomcat:installed(path)
    Cmd("ls "..path)
    -- Cmd("service tomcat status")
    if ERR.Code ~= 0 then
        return false
    else
        return true
    end
end

function tomcat:addtestjsp(instance)
    Cmd("ls ".. instance.CATALINA_BASE.."/webapps/ROOT/index.jsp")
    if ERR.Code ~= 0 then
        Cmd{
            "mkdir -p "..instance.CATALINA_BASE.."/webapps/ROOT",
            [[echo "]]..HOST.Ip..[[:::<%=session.getId() %>" >]]..instance.CATALINA_BASE.."/webapps/ROOT/index.jsp"
        }
    else
        print("index.jsp文件已经存在.")
    end
end

function tomcat:adduser(username, instancepath)
    Cmd{
        "id "..username.." || useradd -s /sbin/nologin -d "..instancepath.."/temp "..username,
            "chown -h "..username..":"..username.." "..instancepath,
        "chown -R "..username..":"..username.." "..instancepath.."/"
    }
end

function tomcat:install()
    -- setup jdk
    self.jdk:binInstall()

    if not self:installed(self.CATALINA_HOME) then
        -- 上传文件
        local lpath = GetLocalPath()

        local path = string.match(self.CATALINA_HOME, "/%w+/%w+/")
        -- print(path)
        Upload(lpath..self.filename, path..self.filename)

        local version = string.match(self.filename, "%d+.%d+.%d+")
        -- 解压和连接
        Cmd{
            "cd "..path.." && tar zxvf "..path..self.filename,
            "ln -s "..path.."apache-tomcat-"..version.." "..self.CATALINA_HOME,
        }

        --no 创建普通用户
        -- self:adduser("tomcat", self.CATALINA_HOME)

        --no 添加服务脚本
        -- self:addserverscript(self.CATALINA_HOME, self.CATALINA_HOME, nil)
    else
        print(self.CATALINA_HOME.."已存在")
    end

end

function tomcat:addserverscript(catalina_home, instance)

    local servicescript = {
    [====[
#!/bin/bash
# chkconfig: 2345 80 30
#tomcat: start/stop/restart/status tomcat

# Source function library.
. /etc/rc.d/init.d/functions

#match these values to your environment
####################################################################################
export JAVA_HOME="]====]..self.jdk.path..self.jdk.version..[====["
export CATALINA_HOME="]====].. catalina_home ..[====["
export CATALINA_BASE="]====].. instance.CATALINA_BASE ..[====["
export CLASSPATH=$JAVA_HOME/lib/tools.jar:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/jre/lib/rt.jar
export PATH=$PATH:$JAVA_HOME/bin
export JAVA_OPTS="-server -Xms512m -Xmx512m"
####################################################################################
getPID() {
#PID=$(ps -ef | grep -v 'grep' | grep "${CATALINA_HOME}/conf/logging.properties" | awk \047{print $2}\047)
PID=$(ps -ef | grep -v 'grep' | grep "${CATALINA_BASE}" | awk \047{print $2}\047)
}

start() {
        getPID
        if [[ "${PID}X" != "X" ]]; then
            echo "tomcat is already running"
        else
            echo "tomcat is starting"
            sudo -E -u ]====]..instance.name..[====[ ${CATALINA_HOME}/bin/catalina.sh start
            #tailf ${CATALINA_HOME}/logs/catalina.out
        fi
}

stop() {
        getPID
        if [[ "${PID}X" == "X" ]]; then
            echo "tomcat is not running"
        else
            kill -9 $PID
            echo "tomcat is stop done"
        fi
}

restart() {
        getPID
        if [[ "${PID}X" == "X" ]]; then
            echo "tomcat is not running,and will be start"
            ${CATALINA_HOME}/bin/catalina.sh start
            echo "tomcat is starting"
        else
            kill -9 $PID
            echo "tomcat is stop"
            sudo -E -u ]====]..instance.name..[====[ ${CATALINA_HOME}/bin/catalina.sh start
            echo "tomcat is starting"
            #tailf ${CATALINA_HOME}/logs/catalina.out
        fi
}

status() {
        getPID
        if [[ "${PID}X" == "X" ]]; then
            echo "tomcat is not running!"
            exit 3
        else
            echo "tomcat is running!"
            exit 0
        fi
}

case $1 in
        start   )
                start
                ;;
        stop    )
                stop
                ;;
        restart )
                restart
                ;;
        status  )
                status
                ;;
        *       )
                echo $"Usage: $0 {start|stop|restart|status}"
                exit 2
                ;;
esac
    ]====]
    }

    Cmd("ls /etc/init.d/".. instance.name)
    if ERR.Code == 0 then
        print("服务脚本已存在。")
    elseif Cmd("netstat -tnlp | grep "..instance.connectorport).Code == 0 or Cmd("netstat -tnlp | grep "..instance.serverport).Code == 0 then
        print("指定的监听地址：已被占用.")
    else
        Cmd{
            [====[echo -e ']====].. servicescript[1]..[====[' > /etc/init.d/]====].. instance.name,
            "chmod u+x /etc/init.d/".. instance.name,
        }
    end
end

function tomcat:addinstance(instance)
    instance.CATALINA_BASE = instance.path..instance.name
    if not self:installed(self.CATALINA_HOME) then
        self:install()
    end

    if self:installed(instance.CATALINA_BASE) then
        print("实例目录已存在。")
    else
        Cmd{
            -- 创建实例目录
            "mkdir -p "..instance.CATALINA_BASE,
            -- 创建实例所需的子目录
            "cd "..instance.CATALINA_BASE.." && mkdir common logs temp server shared webapps work lib",
            -- 拷贝配置文件
            "cp -a "..self.CATALINA_HOME.."/conf "..instance.CATALINA_BASE,
            "iptables -I INPUT -p tcp -d "..HOST.Ip.." --dport "..instance.connectorport.." -j ACCEPT",
        }

        -- 配置实例
        self:setinstance(instance)
        -- 添加用户
        self:adduser(instance.name, instance.CATALINA_BASE)
        -- 添加服务脚本
        self:addserverscript(self.CATALINA_HOME, instance)
    end
end

function tomcat:setinstance(instance)
    -- 修改端口号
    Cmd{
        [====[sed -i 's@\(<Server port=\)".*"@\1"]====]..
                instance.serverport..[====["@' ]====]..
                instance.CATALINA_BASE..[====[/conf/server.xml]====],
        [====[sed -i 's@\(<Connector port=\)".*"@\1"]====]..
                instance.connectorport..[====["@' ]====]..
                instance.CATALINA_BASE..[====[/conf/server.xml]====],
    }
end

function tomcat:start(instance)
    Cmd("service "..instance.name.." status")
    if ERR.Code ~= 0 then
        Cmd{
            "service "..instance.name.." start",
        }
    end
end



function tomcat:sessionbyredis(redisinfo, instance)
    -- 添加jar到tomcat_base/lib
    -- [[ commons-pool2-2.2.jar  jedis-2.5.2.jar	tomcat-redis-session-manager-2.0.0.jar
    if instance.CATALINA_BASE then
        UploadDir(redisinfo.jar_lib_path, instance.CATALINA_BASE.."/lib/")
    end
    --]]

    -- 修改conf/context.xml
    local rt, str = HOST:ReadFile(instance.CATALINA_BASE.."/conf/context.xml")
    if rt == nil then
        local x = XML()
        local el, err = x:LoadByStr(str)
        if err == nil then
            Merge(el, redisinfo.conf)
            rt = HOST:WriteFile(instance.CATALINA_BASE.."/conf/context.xml", el:SyncToXml())
            if rt then
                print("写入文件失败."..instance.CATALINA_BASE.."/conf/context.xml")
                os.exit(-1)
            end
        else
            print("解析xml文件失败."..instance.CATALINA_BASE.."/conf/context.xml")
            os.exit(-1)
        end
    else
        print("读取文件失败."..instance.CATALINA_BASE.."/conf/context.xml")
        os.exit(-1)
    end
end




