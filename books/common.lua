ERR = nil
function Cmd(cmd)
    if type(cmd) ~= "table" then
        ERR = HOST:Cmd{cmd, }
    else
        ERR = HOST:Cmd(cmd)
    end
    return ERR
end

function Ia(cmd, timeout)
    ERR = HOST:RunIa(cmd, timeout)
    return ERR
end

function Upload(lfile, rfile)
    -- ERR = HOST:Cmd{"ls "..rfile}
    --if ERR.Code == 2 then
        if (HOST:PutFile(lfile, rfile)) ~= nil then
            print(lfile.." upload failed..")
            os.exit()
        end
    -- else
    --    print(lfile.." existed..")
    --end
    return ERR
end

function Download(rfile, lfile)
    if (HOST:GetFile(rfile, lfile)) ~= nil then
        print(rfile.." download failed..")
        os.exit()
    end
    return ERR
end

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

function Setfkv(file, key, value, add)
    Cmd("grep -E '^#?"..key.."[[:space:]]' "..file)
    if ERR.Code == 0 and add == false then
        Cmd{[=[sed -i 's,^#*\(]=]..key..
                [=[[[:space:]]\).*$,\1 ]=]..value..
                [=[,' ]=]..file,
        }
    elseif add == true then
            Cmd("echo "..key.." "..value.." >> "..file)
    end
    return ERR
end