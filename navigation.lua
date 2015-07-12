--This script handles automatic announcement of tile changes around the user.


announce_navigation = true
modified_pathfinding = false
directions = {"up", "down", "left", "right"}
previous_tiles = {-1, -1, -1, -1}
current_tiles = {-1, -1, -1, -1}



function read_tiles()
--Read surrounding tiles.
local down = memory.readbyte(0xc2fa)
local up = memory.readbyte(0xc2fb)
local left = memory.readbyte(0xc2fc)
local right = memory.readbyte(0xc2fd)
previous_tiles = {current_tiles[1], current_tiles[2], current_tiles[3], current_tiles[4]}
current_tiles = {up, down, left, right}
end

function announce_tiles()
--Announces tile changes around the user if announce_navigation is set to true and there are in fact changes.
read_tiles()
announce = ""
if announce_navigation==false then
return
end
for d = 1,#directions do
if announce_navigation and current_tiles[d]~=previous_tiles[d] then
announce = announce..directions[d].." "
if announce_navigation and current_tiles[d]~=previous_tiles[d] then
announce = announce..tile_name(current_tiles[d]).." "
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
--This function is called by the footstep function used in the main pokemon.lua file.
read_tiles()
if announce_navigation then
announce_tiles()
end
end

function toggle_modified_pathfinding()
modified_pathfinding = not modified_pathfinding
if modified_pathfinding then
tolk.output("Modified pathfinding enabled.")
tiles[18].mod_passable = true
tiles[36].mod_passable = true
tiles[41].mod_passable = true
tiles[51].mod_passable = true
else
tolk.output("Modified pathfinding disabled.")
tiles[18].mod_passable = false
tiles[36].mod_passable = false
tiles[41].mod_passable = false
tiles[51].mod_passable = false
end
end