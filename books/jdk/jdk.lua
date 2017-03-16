--
-- Created by IntelliJ IDEA.
-- User: guang
-- Date: 2016-12-26
-- Time: 21:24
-- To change this template use File | Settings | File Templates.
--
require("books/common")

jdk ={}

function jdk:new(o)
    o = o or {
        filename = "jdk-8u121-linux-x64.tar.gz",
        version="jdk1.8.0_121",
        path = "/usr/local/"
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function jdk:binInstall()
    local lpath = GetLocalPath()

    local jdk_str = [[export JAVA_HOME=]]..self.path..self.version.."\n"..
    [[export PATH=$PATH:$JAVA_HOME/bin
    export CLASSPATH=.:$JAVA_HOME/lib/tools.jar:$JAVA_HOME/lib/dt.jar:$CLASSPATH
    ]]

    Cmd("grep JAVA_HOME="..self.path..self.version.." /etc/profile")
    if ERR.Code == 1 then
        Upload(lpath..self.filename, self.path..self.filename)

        Cmd{
            "cd "..self.path.." && tar zxvf "..self.filename,
            "echo -e '"..jdk_str.."' >> /etc/profile"
        }
    else
        print("JDK环境已添加。")
    end
end
