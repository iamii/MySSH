-- User: guang
-- Date: 2017-02-16
-- Time: 10:55

-- print(package.path)
require("books/tomcat/tomcat")
require([[books/jdk/jdk_bin_install]])

local t = tomcat:new(
    {
        filename="apache-tomcat-7.0.75.tar.gz",
        CATALINA_HOME="/usr/local/tomcat",
        CATALINA_BASE="/usr/local/tomcat",
        jdk=jdk:new(
            {
                filename = "jdk-8u111-linux-x64.tar.gz",
                version="jdk1.8.0_111",
                path = "/usr/local/",
            })
    })
t:install()

local instance1 = {
    path="/opt/tomcat-instance/",
    name = "test1.com",
    connectorport = "8081",
    serverport = "8006",
}
t:addinstance(instance1)

local instance2 = {
    path="/opt/tomcat-instance/",
    name = "test2.com",
    connectorport = "8082",
    serverport = "8007",
}
t:addinstance(instance2)

-- -------------test
Cmd{
    "service "..instance1.name.." start",
    "service "..instance2.name.." start",
}

