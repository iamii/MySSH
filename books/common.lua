ERR = nil
HOST = HOST
PLAYLISTINFO = PlayListInfo

-- 创建执行列表
function PL_RUN(servers, golbal, TIMEOUT, GO_WITH_ALL_DONE, WAIT_CONN_INIT)
    -- 总超时时间
    TIMEOUT = TIMEOUT or 600
    -- 所有服务器都连接上才可执行脚本
    GO_WITH_ALL_DONE = GO_WITH_ALL_DONE or true
    -- 初始化时等待SSH连接完成再返回
    WAIT_CONN_INIT =  WAIT_CONN_INIT or false

    -- 服务器列表定义

    -- 创建playlist
    local pl = playlist()

    -- 完成服务器列表初始化
    if not pl:Init(servers, golbal, TIMEOUT, WAIT_CONN_INIT) then
        -- 尝试开始执行各服务器对应的Lua文件 -- 返回pl.servers
        pl:Start(GO_WITH_ALL_DONE)
        -- 打印历史记录
        -- [[
        -- pl:ShowHistories()
        --]]
        return pl
    end
    return nil
end

-- 执行命令
function Cmd(cmd)
    if type(cmd) ~= "table" then
        ERR = HOST:Cmd{cmd, }
    else
        ERR = HOST:Cmd(cmd)
    end
    return ERR
end

-- "交互式执行命令"
function Ia(cmd, timeout)
    ERR = HOST:RunIa(cmd, timeout)
    return ERR
end

-- 上传单文件
function Upload(lfile, rfile)
    ERR= HOST:PutFile(lfile, rfile)
    -- ERR = HOST:Cmd{"ls "..rfile}
    --if ERR.Code == 2 then
        if ERR ~= nil then
            print(lfile.." upload failed..")
            os.exit()
        end
    -- else
    --    print(lfile.." existed..")
    --end
    return ERR
end

-- 下载单文件
function Download(rfile, lfile)
    ERR = HOST:GetFile(rfile, lfile)
    if ERR ~= nil then
        print(rfile.." download failed..")
        os.exit()
    end
    return ERR
end

-- 字符串分隔 网上copy的
function string.split(str, delimiter)
    if str==nil or str=='' or delimiter==nil then
        return nil
    end

    local result = {}
    for match in (str..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end

-- 设置配置文件中 key value 形式的值
function Setfkv(file, key, value, add, delimiter, comment)
    if not delimiter then
        delimiter = "[[:space:]]"
    else
        delimiter = "[[:space:]]*"..delimiter.."[[:space:]]*"
    end

    comment = comment or ""

    -- print("---------------------", key, value, add, delimiter, comment)

    local grepstr = [==[grep -E '^]==]..comment..[==[?[[:space:]]?]==]..key..delimiter..[==[' ]==]..file

    Cmd(grepstr)

    if ERR.Code == 0 and add == false then
        -- Cmd([=[sed -i 's,^]=]..comment..[=[*[[:space:]]*\(]=]..key..delimiter..[=[\).*$,\1 ]=]..value.. [=[,' ]=]..file)
        Cmd([=[sed -i 's,^]=]..comment..[=[*\(]=]..key..delimiter..[=[\).*$,\1 ]=]..value.. [=[,' ]=]..file)
    elseif add == true then
        print(key, value, file)
        Cmd("echo "..key.." "..value.." >> "..file)
    end
    return ERR
end

-- 上传时指定本地文件的父目录
function GetLocalPath()
    local lpath
    if os.getenv("OS") == "Windows_NT" then
        lpath = [[D:\Documents\downloads\]]
    else
        lpath = [[/home/iaai/Downloads/]]
    end
    return lpath
end

-- 获取发行版本信息[1]和内核版本[2]
function GetLinuxVersion()
    local d = Cmd("head -1 /etc/issue").Msg
    local k = Cmd("uname -r").Msg
    return {dis=d, ker=k}
end

-- 配置epel
function InstallEPEL()
-- install epel
Cmd("yum install -y epel-release")
--[[
    local epel_repo = {
    [==[
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
]==],
    [===[
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v1.4.5 (GNU/Linux)

mQINBEvSKUIBEADLGnUj24ZVKW7liFN/JA5CgtzlNnKs7sBg7fVbNWryiE3URbn1
JXvrdwHtkKyY96/ifZ1Ld3lE2gOF61bGZ2CWwJNee76Sp9Z+isP8RQXbG5jwj/4B
M9HK7phktqFVJ8VbY2jfTjcfxRvGM8YBwXF8hx0CDZURAjvf1xRSQJ7iAo58qcHn
XtxOAvQmAbR9z6Q/h/D+Y/PhoIJp1OV4VNHCbCs9M7HUVBpgC53PDcTUQuwcgeY6
pQgo9eT1eLNSZVrJ5Bctivl1UcD6P6CIGkkeT2gNhqindRPngUXGXW7Qzoefe+fV
QqJSm7Tq2q9oqVZ46J964waCRItRySpuW5dxZO34WM6wsw2BP2MlACbH4l3luqtp
Xo3Bvfnk+HAFH3HcMuwdaulxv7zYKXCfNoSfgrpEfo2Ex4Im/I3WdtwME/Gbnwdq
3VJzgAxLVFhczDHwNkjmIdPAlNJ9/ixRjip4dgZtW8VcBCrNoL+LhDrIfjvnLdRu
vBHy9P3sCF7FZycaHlMWP6RiLtHnEMGcbZ8QpQHi2dReU1wyr9QgguGU+jqSXYar
1yEcsdRGasppNIZ8+Qawbm/a4doT10TEtPArhSoHlwbvqTDYjtfV92lC/2iwgO6g
YgG9XrO4V8dV39Ffm7oLFfvTbg5mv4Q/E6AWo/gkjmtxkculbyAvjFtYAQARAQAB
tCFFUEVMICg2KSA8ZXBlbEBmZWRvcmFwcm9qZWN0Lm9yZz6JAjYEEwECACAFAkvS
KUICGw8GCwkIBwMCBBUCCAMEFgIDAQIeAQIXgAAKCRA7Sd8qBgi4lR/GD/wLGPv9
qO39eyb9NlrwfKdUEo1tHxKdrhNz+XYrO4yVDTBZRPSuvL2yaoeSIhQOKhNPfEgT
9mdsbsgcfmoHxmGVcn+lbheWsSvcgrXuz0gLt8TGGKGGROAoLXpuUsb1HNtKEOwP
Q4z1uQ2nOz5hLRyDOV0I2LwYV8BjGIjBKUMFEUxFTsL7XOZkrAg/WbTH2PW3hrfS
WtcRA7EYonI3B80d39ffws7SmyKbS5PmZjqOPuTvV2F0tMhKIhncBwoojWZPExft
HpKhzKVh8fdDO/3P1y1Fk3Cin8UbCO9MWMFNR27fVzCANlEPljsHA+3Ez4F7uboF
p0OOEov4Yyi4BEbgqZnthTG4ub9nyiupIZ3ckPHr3nVcDUGcL6lQD/nkmNVIeLYP
x1uHPOSlWfuojAYgzRH6LL7Idg4FHHBA0to7FW8dQXFIOyNiJFAOT2j8P5+tVdq8
wB0PDSH8yRpn4HdJ9RYquau4OkjluxOWf0uRaS//SUcCZh+1/KBEOmcvBHYRZA5J
l/nakCgxGb2paQOzqqpOcHKvlyLuzO5uybMXaipLExTGJXBlXrbbASfXa/yGYSAG
iVrGz9CE6676dMlm8F+s3XXE13QZrXmjloc6jwOljnfAkjTGXjiB7OULESed96MR
XtfLk0W5Ab9pd7tKDR6QHI7rgHXfCopRnZ2VVQ==
=V/6I
-----END PGP PUBLIC KEY BLOCK-----]===],
}
    Cmd{
        "echo '"..epel_repo[1].."' > /etc/yum.repos.d/epel.repo",
        "echo '"..epel_repo[2].."' > /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-6",
        "yum clean metadata && yum clean all && rpm --rebuilddb",
    }
    --]]
end

-- 随机数生成
function Random(b, e)
    math.randomseed(os.time())
    if b and e then
        return math.random(b,e)
    elseif b and not e then
        return math.random(b)
    elseif not b and not e then
        return math.random()
    end
end

-- table2conf
function Table2conf (ctTable, pident)
    local context = ""
    local cident
    if pident  then
        cident = pident .. "\t"
    else
        cident = ""
    end

    if type(ctTable) == "table" then
        for k, v in pairs(ctTable) do
            -- array/list
            if type(k) ~= "number" then
                context = context .. cident ..k
            end

            if type(v) == "table" then
                context = context .. " {\n"
                local vt = Table2conf(v, cident) or ""
                context = context .. vt.. cident .."}\n"
            else
                context = context .. cident.. v .."\n"
            end
        end
    end
    return context
 end

-- tablejoin
function TableJoin(dstTable, src)
    -- [[
    if type(src) == "table" then
        for k, v in pairs(src) do
            -- 如果目标表中已经存在key，则继续比对
            if type(k) == "number" then
                table.insert(dstTable, v)
            elseif dstTable[k] then
                -- 如果上一步的键值也是一个table，则递归调用
                if type(v) == "table" then
                    TableJoin(dstTable[k], v)
                else
                    dstTable[k] = v
                end
            else
                dstTable[k] = v
            end
        end
    else
       table.insert(dstTable, src)
    end
    --]]
 end

-- table2ini
function Table2ini(srcT, pre)
    local coverFun = function(dstT, srcT, pre)
        if type(srcT) == "table" then
            for k, v in pairs(srcT) do
                if type(v) == "table" then
                    if pre and pre ~= "" then
                        coverFun(dstT, v, pre.."."..k)
                    else
                        coverFun(dstT, v, k)
                    end
                else
                    if pre then
                        if not dstT["["..pre.."]"] then
                            dstT["["..pre.."]"] = {}
                        end
                        table.insert(dstT["["..pre.."]"], k.."="..v)
                    else
                        print("没有获取到pre,可能是section未配置正确")
                        return
                    end
                end
            end
        end
    end

    local ttt = {}
    coverFun(ttt, srcT, pre )

    local ini=""
    for k, v in pairs(ttt) do
        ini = ini..k.."\n"
        for i = 1, #v do
            ini = ini..v[i].."\n"
        end
        ini = ini .. "\n"
    end

    return ini
end

