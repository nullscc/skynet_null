local skynet = require "skynet"
local gateserver = require "snax.gateserver"
local netpack = require "netpack"
local crypt = require "crypt"
local socketdriver = require "socketdriver"
local assert = assert
local b64encode = crypt.base64encode
local b64decode = crypt.base64decode

local server = {}

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
}

local user_online = {}
local handshake = {}
local connection = {}

function server.userid(username)
	-- base64(uid)@base64(server)#base64(subid)
	local uid, servername, subid = username:match "([^@]*)@([^#]*)#(.*)"
	return b64decode(uid), b64decode(subid), b64decode(servername)
end

function server.username(uid, subid, servername)
	return string.format("%s@%s#%s", b64encode(uid), b64encode(servername), b64encode(tostring(subid)))
end

function server.logout(username)
	local u = user_online[username]
	user_online[username] = nil
	if u.fd then
		gateserver.closeclient(u.fd)
		connection[u.fd] = nil
	end
end

function server.login(username, secret)
	assert(user_online[username] == nil)
	user_online[username] = {
		secret = secret,
		version = 0,
		index = 0,
		username = username,
	}
end

function server.ip(username)
	local u = user_online[username]
	if u and u.fd then
		return u.ip
	end
end

function server.start(conf)
	local expired_number = conf.expired_number or 128

	local handler = {}

	-- 'lua'类型消息的消息处理函数
	local CMD = {
		login = assert(conf.login_handler),
		logout = assert(conf.logout_handler),
		kick = assert(conf.kick_handler),
		init = assert(conf.init_handler),
		get_agents = assert(conf.get_agents),
		get_agent = assert(conf.get_agent),
		is_online = assert(conf.is_online),
	}

	function handler.command(cmd, source, ...)
		local f = assert(CMD[cmd])
		return f(...)
	end

	function handler.open(source, gateconf)
		local servername = assert(gateconf.servername)
		return conf.register_handler(servername)
	end

	function handler.connect(fd, addr)
		handshake[fd] = addr
		gateserver.openclient(fd)
	end

	function handler.disconnect(fd)
		handshake[fd] = nil
		local c = connection[fd]
		if c then
			c.fd = nil
			connection[fd] = nil
			if conf.disconnect_handler then
				conf.disconnect_handler(c.username)
			end
		end
	end

	handler.error = handler.disconnect

	local auth_handler = conf.auth_handler
	local online_handler = conf.online_handler

	-- atomic , no yield
	local function do_auth(fd, message, addr)
		local username, index, hmac = string.match(message, "([^:]*):([^:]*):([^:]*)")
		local u = user_online[username]
		if u == nil then
			return "404 User Not Found"
		end
		local idx = assert(tonumber(index))
		hmac = b64decode(hmac)

		if idx <= u.version then
			return "403 Index Expired"
		end

		local text = string.format("%s:%s", username, index)
		local v = crypt.hmac_hash(u.secret, text)	-- equivalent to crypt.hmac64(crypt.hashkey(text), u.secret)
		if v ~= hmac then
			return "401 Unauthorized"
		end

		u.version = idx
		u.fd = fd
		u.ip = addr
		connection[fd] = u

		auth_handler(username, fd)
	end

	local function auth(fd, addr, msg, sz)
		local message = netpack.tostring(msg, sz)
		local ok, result = pcall(do_auth, fd, message, addr)
		if not ok then
			skynet.error(result)
			result = "400 Bad Request"
		end

		local close = result ~= nil

		if result == nil then
			result = "200 OK"
		end

		socketdriver.send(fd, netpack.pack(result))

		if close then
			gateserver.closeclient(fd)
		else
			local username = string.match(message, "([^:]*):([^:]*):([^:]*)")
			local uid = server.userid(username)
			online_handler(uid, fd)
		end
	end

	local request_handler = assert(conf.request_handler)

	local function do_request(fd, message)
		local u = assert(connection[fd], "invalid fd")
		local ok, result = pcall(conf.request_handler, u.username, message)
	end

	local function request(fd, msg, sz)
		local message = skynet.tostring(msg, sz)
		local ok, err = pcall(do_request, fd, message)
		-- not atomic, may yield
		if not ok then
			skynet.error(string.format("Invalid package %s : %s", err, message))
			if connection[fd] then
				gateserver.closeclient(fd)
			end
		end
	end

	-- 第一个包为握手包
	function handler.message(fd, msg, sz)
		local addr = handshake[fd]
		if addr then
			auth(fd,addr,msg,sz)
			handshake[fd] = nil
		else
			request(fd, msg, sz)
		end
	end

	return gateserver.start(handler)
end

return server
