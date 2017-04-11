local protobuf = require "protobuf"

local M = {}

function M.pack(name, msg)
	local buf = protobuf.encode(name, msg)
	return string.pack(">s2", string.char(#name) .. name .. buf)
end

function M.unpack(buf)
    local namelen = string.unpack("<I1",buf)
	local name = string.sub(buf, 2, 1+namelen)
    local pbbuf = string.sub(buf, 2+namelen)
	local msg = protobuf.decode(name, pbbuf)
	return name, msg
end

return M