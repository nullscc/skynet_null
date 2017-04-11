local env = require "env"
local player = require "lobby.player"

local M = {}

function M.login()
	if env.player then
		return
	end

	local player = player.new()

	player:load(data)

	env.player = player
end

function M.heartbeat()
    env.send_msg("player.s2c_heartbeat", {})
end

function M.register()
	env.dispatcher:register("player.c2s_heartbeat", M.heartbeat)
end

return M