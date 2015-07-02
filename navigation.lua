announce_navigation = true
announce_objects = false

previous_tiles = {-1, -1, -1, -1}
tiles = {-1, -1, -1, -1}
objects = {{}, {}, {}, {}}
directions = {"up", "down", "left", "right"}
coords_directions = {{0, 1}, {0, -1}, {-1, 0}, {1, 0}}


function has_key(t, key)
for k, v in pairs(t) do
if k==key then
return true
end
end
return false
end

function read_tiles()
local down = memory.readbyte(0xc2fa)
local up = memory.readbyte(0xc2fb)
local left = memory.readbyte(0xc2fc)
local right = memory.readbyte(0xc2fd)
previous_tiles = {tiles[1], tiles[2], tiles[3], tiles[4]}
tiles = {up, down, left, right}
end

function near_objects()
local player_x, player_y = get_player_xy()
o = get_map_info()
o = o.objects
objects = {{}, {}, {}, {}}
for i=1, #o do
if o[i].type~="connection" then
relative_x = o[i].x-player_x
relative_y = o[i].y-player_y
print(o[i].name..": "..relative_x..", "..relative_y)
for d=1, #coords_directions do
if relative_x == coords_directions[d][1] and relative_y==coords_directions[d][2] then
objects[d] = o[i]
end
end
end
end
end

function announce_tiles()
read_tiles()
near_objects()
announce = ""
if announce_navigation==false and announce_objects==false then
return
end
for d = 1,#directions do
if (announce_objects and has_key(objects[d], "type")) or (announce_navigation and tiles[d]~=previous_tiles[d]) then
announce = announce..directions[d].." "
if announce_objects and has_key(objects[d], "type") then
announce = announce..objects[d].name.." "
end
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