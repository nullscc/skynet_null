local skynet = require "skynet"
local mysql = require "mysql"
local CDbConn = class()
local conf

local function connect( c )
    if c then
        conf = c
    end
    assert(conf, "not structure yet")
    local db = assert(mysql.connect{
			host = conf.host,
			port = conf.port,
			database = conf.database,
			user = conf.user,
			password = conf.password,
			max_packet_size = conf.max_packet_size or 1024 * 1024
		}, "mysql connect fail")
    db:query("set charset utf8")
    return db
end

function CDbConn:ctor(conf)
    self.mysqldb = connect(conf)
end

function CDbConn:query( sql )
    -- skynet.errormore("query", sql)
    local statu, data = pcall(self.mysqldb.query, self.mysqldb, sql)
    if not statu then
        self.mysqldb = connect()
        statu, data = pcall(self.mysqldb.query, self.mysqldb, sql)
        if not statu then
            error("run sql", sql, "fail!!!")
        end
    end
    return data
end

function CDbConn:close()
    mysqldb:disconnect()
end

return CDbConn
