require("books/keepalived/keepalived")

local h = keepalived:new()
h.hanodes = {
        vr0 = { ip = "192.168.18.200", port = 22,
            user = "root", auth = "pw", passwd= "123", keyfile = "test",
            timeout = 2, script = "", st="file"},
        vr1 = { ip = "192.168.18.201", port = 22,
            user = "root", auth = "pw", passwd= "123", keyfile = "test",
            timeout = 2, script = "", st="file"},
}
h.priority = {
    vr0= {state = "MASTER", priority = 100,},
    vr1= {state = "BACKUP", priority = 10,},
}
h.lvsnodes = {
    web1 = { ip = "192.168.18.202", port = 22,
        user = "root", auth = "pw", passwd= "123", keyfile = "test",
        timeout = 2, script = "", st="file"},
    web2 = { ip = "192.168.18.203", port = 22,
        user = "root", auth = "pw", passwd= "123", keyfile = "test",
        timeout = 2, script = "", st="file"},
    -- [[
    test4 = { ip = "192.168.18.204", port = 22,
        user = "root", auth = "pw", passwd= "123", keyfile = "test",
        timeout = 2, script = "", st="file"},
        --]]
}

h:install()


