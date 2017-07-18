--
-- User: iaai
-- Date: 17-5-9
-- Time: 下午2:24
--

require "books/redis/redis"

local r = redis:new()

r:yuminstall()
r:start()
HOST:Send({info="redis done."})