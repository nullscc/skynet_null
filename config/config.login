skynetroot = "./skynet/"
thread = 8
logger = nil
harbor = 0
start = "main"
bootstrap = "snlua bootstrap"	-- The service for bootstrap
luaservice = skynetroot .. "service/?.lua;".."./login/?.lua"
lualoader = skynetroot .. "lualib/loader.lua"
cpath = skynetroot .. "./cservice/?.so"
lua_cpath = skynetroot .. "luaclib/?.so;" .. "./luaclib/?.so"
lua_path = skynetroot .. "lualib/?.lua;".."./login/?.lua"
cluster = "./cluster/cname.lua"

-- 选择登录模式:
-- 本地数据库模式: "locald"
loginmod = "locald"

-- 登陆服外网ip地址
outaddr = "192.168.2.148"
