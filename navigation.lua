announce_navigation = true
directions = {"up", "down", "left", "right"}
previous_tiles = {-1, -1, -1, -1}
tiles = {-1, -1, -1, -1}



function read_tiles()
local down = memory.readbyte(0xc2fa)
local up = memory.readbyte(0xc2fb)
local left = memory.readbyte(0xc2fc)
local right = memory.readbyte(0xc2fd)
previous_tiles = {tiles[1], tiles[2], tiles[3], tiles[4]}
tiles = {up, down, left, right}
end

function announce_tiles()
read_tiles()
announce = ""
if announce_navigation==false then
return
end
for d = 1,#directions do
if announce_navigation and tiles[d]~=previous_tiles[d] then
announce = announce..directions[d].." "
if announce_navigation and tiles[d]~=previous_tiles[d] then
announce = announce..tiles[d].." "
end
end
end
if #announce>0 then
tolk.output(announce)
end
end

function toggle_navigation()
announce_navigation = not announce_navigation
if announce_navigation then
tolk.output("enabled")
else
tolk.output("disabled")
end
end


function on_move()
read_tiles()
if announce_navigation then
announce_tiles()
end
end

function look_left()
print(#objects[3])
end