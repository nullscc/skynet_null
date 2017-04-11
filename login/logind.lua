local skynet = require "skynet"
local login = require "snax.loginserver"

local loginmod = skynet.getenv("loginmod")
local server = require(loginmod)

login(server)
