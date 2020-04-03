module ( "trail", package.seeall )

function clean_path(path)
local start = path[1]
local new_path = {}
for i, node in ipairs(path) do
if i > 1 then
local last = path[i-1]
table.insert(new_path, direction(last.x, last.y, node.x, node.y))
end -- i > 1
end -- for
return group_unique_items(new_path)
end

function distance(x, y, destx, desty)
local s = ""
if y > desty then
s = y-desty .. " up"
elseif y < desty then
s = desty-y .. " down"
end
if x > destx then
s = s .. " " .. x-destx .. " left"
elseif x < destx then
s = s .. " " .. destx-x .. " right"
end
return s
end

function direction(x, y, destx, desty)
local s = ""
if y > desty then
return "up"
elseif y < desty then
return "down"
elseif x > destx then
return "left"
elseif x < destx then
return "right"
end
return s
end

function group_unique_items(t)
if #t == 0 then return t end
if #t == 1 then return {{t[1], 1}} end
local nt = {}
local last = t[1]
local last_count = 1
for i = 2, #t do
if t[i] == last then
last_count = last_count + 1
else
table.insert(nt, {last, last_count})
last = t[i]
last_count = 1
end
end
table.insert(nt, {last, last_count})
return nt
end

function route(player_y, player_x, collisions)
local s = string.format("Now %d", collisions[player_y][player_x])

-- Check up tile
if player_y > 1 then
	s = s .. string.format(", Up %d", collisions[player_y - 1][player_x])
else -- up is none
	s = s .. ", Up none"
end -- Check up tile

-- Check down tile
if player_y < #collisions then
	s = s .. string.format(", Down %d", collisions[player_y + 1][player_x])
else -- Down is none
	s = s .. ", Down none"
end -- Check down tile

-- Check left tile
if player_x > 1 then
	s = s .. string.format(", Left %d", collisions[player_y][player_x - 1])
else -- left is none
	s = s .. ", Left none"
end -- Check left tile

-- Check right tile
if player_x < #collisions then
	s = s .. string.format(", Right %d", collisions[player_y][player_x + 1])
else -- right is none
	s = s .. ", Right none"
end -- Check right tile

return s
end

