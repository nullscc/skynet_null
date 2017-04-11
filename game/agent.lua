local skynet = require "skynet"
local message = require "message"
local protobuf = require "protobuf"
local dispatcher = require "dispatcher"
local env = require "env"
local lobby_mgr = require "lobby.mgr"
local socket = require "socket"

local UID
local SUB_ID
local SECRET
local FD
local afktime = 0

local gate		-- 游戏服务器gate地址
local CMD = {}

env.send_msg = function (name, msg)
	local pack = message.pack(name, msg)
	socket.write(FD, pack)
end

local sock_dispatcher = dispatcher.new()
env.dispatcher = sock_dispatcher

local running = false

local function logout()
	if running then
		running = false
	end

	if gate then
		skynet.call(gate, "lua", "logout", UID, SUB_ID)
	end

	gate = nil
	UID = nil
	SUB_ID = nil
	SECRET = nil

	ti = {}
	afktime = 0

	-- skynet.exit()
end

-- 玩家登录游服后调用
function CMD.login(source, uid, subid, secret)
	-- you may use secret to make a encrypted data stream
	gate = source
	UID = uid
	SUB_ID = subid
	SECRET = secret

	ti = {}
	afktime = 0
end

-- 玩家登录游服，握手成功后调用
function CMD.auth(source, uid, client_fd)
	FD = client_fd
	if not running then
		running = true
	end
end

function CMD.online(source, uid, client_fd)
	lobby_mgr.register()
	skynet.call("online", "lua", "online", uid, client_fd)
end

function CMD.logout(source)
	-- NOTICE: The logout MAY be reentry
	skynet.error(string.format("%s is logout", UID))
	logout()
end

function CMD.afk(source)
	-- the connection is broken, but the user may back
	afktime = skynet.time()
	skynet.error(string.format("AFK"))
end

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,

	unpack = function (msg, sz)
		local buf = skynet.tostring(msg, sz)
		return message.unpack(buf)
	end,

	dispatch = function (_, _, pbName, msg)
		sock_dispatcher:dispatch(pbName, msg)
	end
}

skynet.start(function()
	-- If you want to fork a work thread , you MUST do it in CMD.login
	skynet.dispatch("lua", function(session, source, command, ...)
		local f = assert(CMD[command])
		local res = f(source, ...)
		if res ~= nil then
			skynet.retpack(res)
		end
	end)
	local finenames = {
	"./proto/player.pb",
	}
    for _, filename in pairs(finenames) do
        protobuf.register_file(filename)
    end
end)
