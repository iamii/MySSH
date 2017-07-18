--
-- User: iaai
-- Date: 17-4-13
-- Time: 上午9:32
--

require("books/nginx/nginx")


local ng = nginx:new()

--print(ng:getconf(ng.conf["conf.d/default.conf"]))
--print(ng:getconf(ng.conf["upstream.conf"]))
ng:yumInstall()
