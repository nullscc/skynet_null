local skynet = require "skynet"
local cluster = require "cluster"

skynet.start(function()
	skynet.uniqueservice("logind")		-- 启动登录服务器
	cluster.open("login")
end)
