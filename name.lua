module ( "name", package.seeall )

local serpent = require "serpent"

function load_table(filename)
local res, t
fp = io.open(filename, "rb")
if fp ~= nil then
local data = fp:read("*all")
res, t = serpent.load(data)
io.close(fp)
end
return res, t
end

function write_table(filename, table)
local file = io.open(filename, "wb")
file:write(serpent.block(table, {comment=false}))
io.close(file)
end

