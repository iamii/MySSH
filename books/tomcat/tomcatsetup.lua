-- User: guang
-- Date: 2017-02-16
-- Time: 10:55

-- print(package.path)
require("books/tomcat/tomcat")
require([[books/jdk/jdk]])

local t = tomcat:new(
    {
        filename="apache-tomcat-7.0.79.tar.gz",
        CATALINA_HOME="/usr/local/tomcat",
        CATALINA_BASE="/usr/local/tomcat",
        jdk=jdk:new(
            {
                filename = "jdk-8u131-linux-x64.tar.gz",
                version="jdk1.8.0_131",
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
t:addtestjsp(instance1)

local redisinfo = {
    jar_lib_path =  GetLocalPath().."/tomcat-redis-session-manager-master/jar/",
    conf = {
        WatchedResource = "WEB-INF/web.xml",
        Valve = {
            ___attr = {
                className = "com.orangefunction.tomcat.redissessions.RedisSessionHandlerValve",
            },
        },
        Manager = {
            ___attr = {
                className = "com.orangefunction.tomcat.redissessions.RedisSessionManager",
                host = "192.168.18.203",
                port = 6379,
                database = 0,
                maxInactiveInterval = "60",
                -- sessionPersistPolicies="PERSIST_POLICY_1,PERSIST_POLICY_2,..",
                -- sentinelMaster="SentinelMasterName",
                -- sentinels="sentinel-host-1:port,sentinel-host-2:port,..",
                --[[
                 属性解释：

                host redis服务器地址

                port redis服务器的端口号

                database 要使用的redis数据库索引

                maxInactiveInterval session最大空闲超时时间，如果不填则使用tomcat的超时时长，一般tomcat默认为1800 即半个小时

                sessionPersistPolicies	session保存策略，除了默认的策略还可以选择的策略有：

                [SAVE_ON_CHANGE]:每次 session.setAttribute() 、 session.removeAttribute() 触发都会保存.
                    注意：此功能无法检测已经存在redis的特定属性的变化，
                    权衡：这种策略会略微降低会话的性能，任何改变都会保存到redis中.

                [ALWAYS_SAVE_AFTER_REQUEST]: 每一个request请求后都强制保存，无论是否检测到变化.
                    注意：对于更改一个已经存储在redis中的会话属性，该选项特别有用.
                    权衡：如果不是所有的request请求都要求改变会话属性的话不推荐使用，因为会增加并发竞争的情况。
                sentinelMaster	redis集群主节点名称（Redis集群是以分片(Sharding)加主从的方式搭建，满足可扩展性的要求）

                sentinels	redis集群列表配置(类似zookeeper，通过多个Sentinel来提高系统的可用性)

                connectionPoolMaxTotal

                connectionPoolMaxIdle	jedis最大能够保持idel状态的连接数

                connectionPoolMinIdle	与connectionPoolMaxIdle相反

                maxWaitMillis	jedis池没有对象返回时，最大等待时间

                minEvictableIdleTimeMillis

                softMinEvictableIdleTimeMillis

                numTestsPerEvictionRun

                testOnCreate

                testOnBorrow	jedis调用borrowObject方法时，是否进行有效检查

                testOnReturn	jedis调用returnObject方法时，是否进行有效检查

                testWhileIdle

                timeBetweenEvictionRunsMillis

                evictionPolicyClassName

                blockWhenExhausted

                jmxEnabled

                jmxNameBase

                jmxNamePrefix


                -- ]]
            },
        },
    },
}


--t:sessionbyredis(redisinfo, instance1)


t:start(instance1)


local instance2 = {
    path="/opt/tomcat-instance/",
    name = "test2.com",
    connectorport = "8082",
    serverport = "8007",
}
t:addinstance(instance2)
--HOST:Wait({src="redis1"})
t:start(instance2)
