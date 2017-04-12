local skynet = require "skynet"
require "skynet.manager"
local mysql = require "mysql"
local CDbConn = require("CDbConn")
local pstr = require "common.str"
local CMD = {}
local pool = {}

local maxconn
local index = 2
local function getconn()
	local db = pool[index]
	assert(db)
	index = index + 1
	if index > maxconn then
		index = 2
	end
	return db
end

function CMD.start(conf)
	maxconn = conf.maxconn--tonumber(skynet.getenv("mysql_maxconn")) or 10
	assert(maxconn >= 2)
	for i=1, maxconn do
        local db = CDbConn.new(conf)
        table.insert(pool, db)
    end
end

local function query(db, sql)
	local data = db:query(sql)
	if type(data) ~= "table" then
		return data
	end
	assert(data.err == nil, "execute sql:"..sql.." err:"..pstr.table2Str(data))
	return data
end

function CMD.execute(sql)
	local db = getconn()
	return query(db, sql)
end

function CMD.execute_getautoid(sql)
	local db = getconn()
	query(db, sql)
	return query(db, "SELECT LAST_INSERT_ID();")
end

function CMD.backup( sql )
	local db = pool[1]
	query(db, sql)
end

function CMD.stop()
	for _, dbconn in pairs(pool) do
		dbconn:close()
	end
	pool = {}
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, ...)
		local f = assert(CMD[cmd], cmd .. "not found")
		skynet.retpack(f(...))
		skynet.errormore("-----mysqlpoll return")
	end)

--	skynet.register(SERVICE_NAME)
end)
