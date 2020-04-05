module ( "guide", package.seeall )
require "a-star"

function find_path_to(obj, width, height, player_x, player_y, collisions, objects, warps, inpassible_tiles)
local path

if obj.type == "connection" then
if obj.direction == "north" then
dest_y = 0
for dest_x = 0, width*2-1 do
if not inpassible_tiles[get_collision_data_xy(dest_x+4, dest_y+3)] then
path = find_path_to_xy(dest_x, dest_y, false, player_x, player_y, collisions, objects, warps, inpassible_tiles)
end
if path ~= nil then break end
end
elseif obj.direction == "south" then
dest_y = height*2-1
for dest_x = 0, width*2-1 do
if not inpassible_tiles[get_collision_data_xy(dest_x+4, dest_y+5)] then
path = find_path_to_xy(dest_x, dest_y, false, player_x, player_y, collisions, objects, warps, inpassible_tiles)
end
if path ~= nil then break end
end
elseif obj.direction == "east" then
dest_x = width*2-1
for dest_y = 0, height*2-1 do
if not inpassible_tiles[get_collision_data_xy(dest_x+5, dest_y+4)] then
path = find_path_to_xy(dest_x, dest_y, false, player_x, player_y, collisions, objects, warps, inpassible_tiles)
end
if path ~= nil then break end
end
elseif obj.direction == "west" then
dest_x = 0
for dest_y = 0, height*2-1 do
if not inpassible_tiles[get_collision_data_xy(dest_x+3, dest_y+4)] then
path = find_path_to_xy(dest_x, dest_y, false, player_x, player_y, collisions, objects, warps, inpassible_tiles)
end
if path ~= nil then break end
end
end
else
if obj.name == "clerk" then -- clerk facing right
dest_x = obj.x+1
else
dest_x = obj.x
end
if obj.name == "nurse" then -- nurse facing down
dest_y = obj.y+1
else
dest_y = obj.y
end
path = find_path_to_xy(dest_x, dest_y, true, player_x, player_y, collisions, objects, warps, inpassible_tiles)
end
return path
end

function find_path_to_xy(dest_x, dest_y, search, player_x, player_y, collisions, objects, warps, inpassible_tiles)
local allnodes = {}
local width = #collisions[1]
local start = nil
local dest = nil
-- set all the objects to walls
for i, object in ipairs(objects) do
collisions[object.y][object.x] = 7
end
for i, warp in ipairs(warps) do
if warp.x ~= dest_x and warp.y ~= dest_y then
collisions[warp.y][warp.x] = 7
end
end
if inpassible_tiles[collisions[dest_y][dest_x]] then
local to_search = {
{dest_y+1, dest_x};
{dest_y-1, dest_x};
{dest_y-2, dest_x};
{dest_y, dest_x+1};
{dest_y, dest_x-1};
{dest_y, dest_x+2};
{dest_y, dest_x-2};
}
if search then
for i, pos in ipairs(to_search) do
if collisions[pos[1]] ~= nil and collisions[pos[1]][pos[2]] ~= nil and not inpassible_tiles[collisions[pos[1]][pos[2]]] then
dest_y = pos[1]
dest_x = pos[2]
break
end
end
else
return nil
end
end
-- generate the all nodes list for pathfinding, and track the start and end nodes
for y = 1, #collisions do
for x = 1, width do
local n = {x=x, y=y, type=collisions[y][x]}
table.insert(allnodes, n)
if x == player_x and y == player_y then
start = n
end
if x == dest_x and y == dest_y then
dest = n
end
end -- x
end -- y
local valid = function (node, neighbor)
if node.type == 0xa0 and neighbor.x == node.x+2 and neighbor.y == node.y then
return true
elseif node.type == 0xa1 and neighbor.x == node.x-2 and neighbor.y == node.y then
return true
elseif node.type == 0xa2 and neighbor.x == node.x and neighbor.y == node.y-y then
return true
elseif node.type == 0xa3 and neighbor.x == node.x and neighbor.y == node.y+2 then
return true
elseif astar.dist_between(node, neighbor) ~= 1 then
return false
elseif inpassible_tiles[neighbor.type] then
return false
end
return true
end -- valid
return astar.path(start, dest, allnodes, true, valid)
end

