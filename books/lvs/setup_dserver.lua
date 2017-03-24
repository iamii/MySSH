--
-- Created by IntelliJ IDEA.
-- User: guang
-- Date: 2017-01-07
-- Time: 17:17
--

require("./books/lvs/lvsinstance")

local olvs = PLAYLISTINFO

local l = lvsinstance:new(olvs)

l:add_virtual_service()