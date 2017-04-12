local skynet = require "skynet"
local cluster = require "cluster"
local sharedata = require "sharedata"

skynet.start(function()	
	skynet.newservice("debug_console", tonumber(skynet.getenv("debug_port")))

	sharedata.new("settings","@lualib/settings.lua")
	skynet.newservice("redispool")
	
    local nodename = skynet.getenv("nodename")
	local gated = skynet.uniqueservice("gated")
	skynet.call(gated, "lua", "init")				-- 预先分配若干agent
	skynet.call(gated, "lua", "open" , {
		port = tonumber(skynet.getenv("port")) or 8888,
		maxclient = tonumber(skynet.getenv("maxclient")) or 1024,
		servername = nodename,
	})

	cluster.open(nodename)
end)

