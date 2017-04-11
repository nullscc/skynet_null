local crypt = require "crypt"
local skynet = require "skynet"
local cluster = require "cluster"
local serverlist = require "serverlist"

local server = {
	port = 10000,
	multilogin = false,	-- disallow multilogin
	name = ".login",    -- 注册的名字
}

local user_online = {}
local user_login = {}

-- 认证函数
-- 一般是服务器拿着token去sdk那里认证，如果认证通过了则让它通过
-- 如果不接sdk情况，那么客户端发过来的token可以是用户名密码+服务器名字+token的组合
function server.auth_handler(token)
	-- the token is base64(user)@base64(server):base64(password)
	local user, server, password = token:match("([^@]+)@([^:]+):(.+)")
	user = crypt.base64decode(user)
	server = crypt.base64decode(server)
	password = crypt.base64decode(password)
	assert(password == "password", "Invalid password")
	return server, user
end

-- 登录函数，这里的 <server uid> 就是上面 auth_handler 返回的 <server, user>
-- 认证成功以后会把 subid 发给客户端，客户端拿到 subid 以后就可以配合 secret 去与游戏服务器交互了
function server.login_handler(server, uid, secret)
	-- only one can login, because disallow multilogin
	local last = user_online[uid]
	if last then
		local ok = pcall(cluster.call, last.server, ".gated", "kick", uid, last.subid)
        if ok then
            user_online[uid] = nil
        end
	end

    -- 因为 cluster.call 会让出执行，所以二次确认是否已经登录
	if user_online[uid] then
		error(string.format("user %s is already online", uid))
	end

	-- 去游戏服务器拿subid，这样游戏服务器就知道uid、secret
	local ok, subid = pcall(cluster.call, server, ".gated", "login", uid, secret)
	if not ok then
		error("get subid from gameserver error")
	end
	user_online[uid] = {subid = subid , server = server}
	return subid..serverlist["game"]
end

local CMD = {}

function CMD.logout(uid, subid)
	local u = user_online[uid]
	if u then
		print(string.format("%s@%s is logout", uid, u.server))
		user_online[uid] = nil
	end
end

function server.command_handler(command, ...)
	local f = assert(CMD[command])
	return f(...)
end

return server