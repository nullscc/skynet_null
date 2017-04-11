local msgserver = require "snax.msg_server"
local crypt = require "crypt"
local skynet = require "skynet"
require "skynet.manager"
local cluster = require "cluster"

local server = {}
local users = {}		-- uid -> u
local username_map = {}		-- username -> u
local internal_id = 0
local agent_pool = {}

-- 缓存的包的个数
server.expired_number = 128

local max_agent
local curr_agent

-- 此服务的消息处理函数，对应 CMD.init()
function server.init_handler()
	local maxclient = (tonumber(skynet.getenv("maxclient")) or 1024)
	local n = maxclient // 10
	for i = 1, n do
		local agent = assert(skynet.newservice("agent"), string.format("precreate agent %d of %d error", i, n))
		table.insert(agent_pool, agent)
	end
	max_agent = 2 * maxclient
	curr_agent = n
end

-- 与登陆服握手成功后回调
function server.auth_handler(username, fd)
	local uid = msgserver.userid(username)

	skynet.send(users[uid].agent, "lua", "auth", uid, fd)	-- 通知agent认证成功，玩家真正处于登录状态了
end

-- 握手成功后回调
function server.online_handler(uid, fd)
	skynet.send(users[uid].agent, "lua", "online", uid, fd)
end

-- 此服务的消息处理函数，对应 CMD.login()
-- 在客户端与登陆服登录过程中，被登陆服务器调用
-- 这样游戏服务器就知道了这个用户的secret
local node_name =  skynet.getenv("nodename")
function server.login_handler(uid, secret)
	if users[uid] then
		local errmsg = string.format("%d is already login", uid)
		error(errmsg)
	end

	internal_id = internal_id + 1
	local username = msgserver.username(uid, internal_id, node_name)
	local agent = table.remove(agent_pool)
	if not agent then
		if curr_agent < max_agent then
			agent = skynet.newservice "agent"
			curr_agent = curr_agent + 1
		else
			error("too many agents")
		end
	end

	local u = {
		username = username,
		agent = agent,
		uid = uid,
		subid = internal_id,
	}

	-- trash subid (no used)
	skynet.send(agent, "lua", "login", uid, internal_id, secret)
	users[uid] = u
	username_map[username] = u

	msgserver.login(username, secret)

	-- you should return unique subid
	return internal_id
end

-- call by agent
-- 此服务的消息处理函数，对应 CMD.logout()
function server.logout_handler(uid, subid)
	local u = users[uid]
	if u then
		local username = msgserver.username(uid, subid, node_name)
		assert(u.username == username)
		msgserver.logout(u.username)
		users[uid] = nil
		username_map[u.username] = nil
		
		pcall(cluster.call, "login", ".login_master", "logout", uid, subid)
		table.insert(agent_pool, u.agent)
	end
end

-- call by login server
-- 此服务的消息处理函数，对应 CMD.kick()
-- 玩家登录 登录服务器，发现用户已登录到其他游戏服务器，调用此函数踢掉
function server.kick_handler(uid, subid)
	local u = users[uid]
	if u then
		local username = msgserver.username(uid, subid, node_name)
		assert(u.username == username)
		-- NOTICE: logout may call skynet.exit, so you should use pcall.
		pcall(skynet.call, u.agent, "lua", "logout")
	else
		--这里是为了防止msgserver崩溃后，未通知loginserver而导致卡号
		pcall(cluster.call, "login", ".login_master", "logout", uid, subid)
	end
end

-- call by self (when socket disconnect)
function server.disconnect_handler(username)
	local u = username_map[username]
	if u then
		skynet.call(u.agent, "lua", "afk")
	end
end

-- call by self (when recv a request from client)
function server.request_handler(username, msg)
	--local uid = msgserver.userid(username)
	local u = username_map[username]
	print("----server.request_handler", u.agent, username, msg)
	skynet.redirect( u.agent,skynet.self(), "client", 0, msg)
	-- skynet.send(u.agent, "client", msg)
end

-- call by self (when gate open)
function server.register_handler(name)

end

-- 获取所有的在线agent列表
function server.get_agents()
	local agnets = {}
	for k, v in pairs(users) do
		agents[k] = v.agent
	end
	return agents
end

-- 获取在线玩家uid所对应的agent
function server.get_agent(uid)
	if users[uid] then
		return users[uid].agent
	end
end

function server.is_online(uid)
	if users[uid] then
		return true
	else
		return false
	end
end

msgserver.start(server)		-- 启动游戏服务器
skynet.register("."..SERVICE_NAME)
