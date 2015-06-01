require "a-star"
serpent = require "serpent"
FLAGFILE = "flag"
EAST = 1
WEST = 2
SOUTH = 4
NORTH = 8
-- characters table
chars = {}
chars[0x7F] = " "
chars[0x80] = "A"
chars[0x81] = "B"
chars[0x82] = "C"
chars[0x83] = "D"
chars[0x84] = "E"
chars[0x85] = "F"
chars[0x86] = "G"
chars[0x87] = "H"
chars[0x88] = "I"
chars[0x89] = "J"
chars[0x8A] = "K"
chars[0x8B] = "L"
chars[0x8C] = "M"
chars[0x8D] = "N"
chars[0x8E] = "O"
chars[0x8F] = "P"
chars[0x90] = "Q"
chars[0x91] = "R"
chars[0x92] = "S"
chars[0x93] = "T"
chars[0x94] = "U"
chars[0x95] = "V"
chars[0x96] = "W"
chars[0x97] = "X"
chars[0x98] = "Y"
chars[0x99] = "Z"
chars[0x9A] = "("
chars[0x9B] = ")"
chars[0x9C] = ":"
chars[0x9D] = ";"
chars[0x9E] = "["
chars[0x9F] = "]"
chars[0xA0] = "a"
chars[0xA1] = "b"
chars[0xA2] = "c"
chars[0xA3] = "d"
chars[0xA4] = "e"
chars[0xA5] = "f"
chars[0xA6] = "g"
chars[0xA7] = "h"
chars[0xA8] = "i"
chars[0xA9] = "j"
chars[0xAA] = "k"
chars[0xAB] = "l"
chars[0xAC] = "m"
chars[0xAD] = "n"
chars[0xAE] = "o"
chars[0xAF] = "p"
chars[0xB0] = "q"
chars[0xB1] = "r"
chars[0xB2] = "s"
chars[0xB3] = "t"
chars[0xB4] = "u"
chars[0xB5] = "v"
chars[0xB6] = "w"
chars[0xB7] = "x"
chars[0xB8] = "y"
chars[0xB9] = "z"
chars[0xC0] = "Ä"
chars[0xC1] = "Ö"
chars[0xC2] = "Ü"
chars[0xC3] = "ä"
chars[0xC4] = "ö"
chars[0xC5] = "ü"
chars[0xD0] = "'d"
chars[0xD1] = "'l"
chars[0xD2] = "'m"
chars[0xD3] = "'r"
chars[0xD4] = "'s"
chars[0xD5] = "'t"
chars[0xD6] = "'v"
chars[0xE0] = "'"
chars[0xE3] = "-"
chars[0xE6] = "?"
chars[0xE7] = "!"
chars[0xE8] = "."
chars[0xE9] = "&"
chars[0xEA] = "é"
chars[0xEB] = "?"
chars[0xEC] = "?"
chars[0xED] = "?"
chars[0xEE] = "?"
chars[0xEF] = "?"
chars[0xF0] = "¥"
chars[0xF1] = "×"
chars[0xF3] = "/"
chars[0xF4] = ","
chars[0xF5] = "?"
chars[0xF6] = "0"
chars[0xF7] = "1"
chars[0xF8] = "2"
chars[0xF9] = "3"
chars[0xFA] = "4"
chars[0xFB] = "5"
chars[0xFC] = "6"
chars[0xFD] = "7"
chars[0xFE] = "8"
chars[0xFF] = "9"

assert(package.loadlib("MushReader.dll", "luaopen_audio"))()
assert(package.loadlib("audio.dll", "luaopen_audio"))()
nvda.say("ready")
fp = io.open("names.lua", "rb")
if fp ~= nil then
names = fp:read("*all")
res, names = serpent.load(names)
io.close(fp)
end
if names == nil then
nvda.say("Unable to load names file.")
names = {}
end

function translate(char)
if chars[char] then
return chars[char]
else
return " "
end
end

function flagged()
local f = io.open(FLAGFILE, "r")
if f ~= nil then
local data = f:read("*a")
io.close(f)
os.remove(FLAGFILE)
return true, data
else
return false, nil
end
end

function get_text()
local textstart = 0xc4a0
local text = ""
for i = 0, 359 do
local char = memory.readbyteunsigned(textstart+i)
char = translate(char)
if i == 358 and char == "?" then
char = " "
end
text = text .. char
end
return text
end

function text_to_lines(text)
local lines = {}
for i = 1, 360, 20 do
table.insert(lines, text:sub(i, i+19))
end
return lines
end

function read_text()
local text = get_text()
local lines = text_to_lines(text)
for i, line in pairs(lines) do
line = line:gsub("^%s*(.-)%s*$", "%1")
if line ~= "" then
nvda.say(line)
end
end
end

function read_coords()
local y = memory.readbyte(0xdcb7)
local x = memory.readbyte(0xdcb8)
if not on_map() then
nvda.say("Not on a map")
return
end

nvda.say("x " .. x .. ", y " .. y)
end

function get_warps()
local mapgroup, mapnumber = get_map_gn()
local eventstart = memory.readword(0xd1a6)
local bank = memory.readbyte(0xd1a3)
eventstart = (bank*16384) + (eventstart - 16384)
local warps = memory.gbromreadbyte(eventstart+2)
local results = {}
local warp_table_start = eventstart+3
for i = 1, warps do
local start = warp_table_start+(5*(i-1))
local warpy = memory.gbromreadbyte(start)
local warpx = memory.gbromreadbyte(start+1)
local idx = get_map_id()
local name = "Warp " .. i
table.insert(results, {x=warpx, y=warpy, name=name, type="warp", id="warp_" .. i})
end
return results
end

function get_signposts()
local eventstart = memory.readword(0xd1a6)
local bank = memory.readbyte(0xd1a3)
local mapgroup, mapnumber = get_map_gn()
eventstart = (bank*16384) + (eventstart - 16384)
local warps = memory.gbromreadbyte(eventstart+2)
local ptr = eventstart + 3 -- start of warp table
ptr = ptr + (warps * 5) -- skip them
-- skip the xy triggers too
local xt = memory.gbromreadbyte(ptr)
ptr = ptr + (xt * 8)+1
local signposts = memory.gbromreadbyte(ptr)
ptr = ptr + 1
-- read out the signposts
local results = {}
for i = 1, signposts do
local posty = memory.gbromreadbyte(ptr)
local postx = memory.gbromreadbyte(ptr+1)
local name = "signpost " .. i
local post = {x=postx, y=posty, name=name, type="signpost", id="signpost_" .. i}
table.insert(results, post)
ptr = ptr + 5 -- point at the next one
end
return results
end

function get_objects()
local ptr = 0xd71e+16 -- skip the player
local liveptr = 0xd81e -- live objects
local results = {}
for i = 1, 15 do
local y = memory.readbyte(ptr+0x02)
local x = memory.readbyte(ptr+0x03)
local object_struct = memory.readbyte(ptr)
-- we have map object structs, and object structs. If the first byte of the
-- map object struct is not 0xff, use that to look up the object struct,
-- and get its coords.
-- if object is on screen and on the map
if object_struct ~= 0xff and y ~= 255 then
local l = 0xd4fe+((object_struct-1)*40)
x = memory.readbyte(l+0x12)
y = memory.readbyte(l+0x13)
end
local name = "Object " .. i .. string.format(", %x", ptr)
if y ~= 255 then
if memory.readbyte(liveptr+i) == 0 then
table.insert(results, {x=x-4, y=y-4, name=name, type="object", id="object_" .. i})
end
end
ptr = ptr + 16
end
return results
end

function get_connections()
local connections = memory.readbyte(0xd1a8)
local function hasbit(x, p)
return x % (p + p) >= p
end
local results = {}
local function add_connection(dir)
local name = dir .. " connection"
table.insert(results, {type="connection", direction=dir, name=name, id="connection_" .. dir})
end

if hasbit(connections, NORTH) then
add_connection("north")
end
if hasbit(connections, SOUTH) then
add_connection("south")
end
if hasbit(connections, EAST) then
add_connection("east")
end
if hasbit(connections, WEST) then
add_connection("west")
end
return results
end

function get_map_info()
local mapgroup, mapnumber = get_map_gn()
local results = {group=mapgroup, number=mapnumber, objects={}}
for i, warp in ipairs(get_warps()) do
table.insert(results.objects, warp)
end
for i, signpost in ipairs(get_signposts()) do
table.insert(results.objects, signpost)
end
for i, connection in ipairs(get_connections()) do
table.insert(results.objects, connection)
end
for i, object in ipairs(get_objects()) do
table.insert(results.objects, object)
end
return results
end

function get_map_gn()
local mapgroup = memory.readbyte(0xdcb5)
local mapnumber = memory.readbyte(0xdcb6)
return mapgroup, mapnumber
end

function get_map_id()
local group, number = get_map_gn()
return group*256+number
end

-- Returns true or false indicating whether we're on a map or not.
function on_map()
local mapgroup, mapnumber = get_map_gn()
if (mapnumber == 0 and mapgroup == 0) or memory.readbyte(0xd22d) ~= 0 then
return false
else
return true
end
end

function direction(x, y, destx, desty)
print("x " .. x .. " y " .. y .. " destx " .. destx .. " desty " .. desty)
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

function read_tiles()
local down = memory.readbyte(0xc2fa)
local up = memory.readbyte(0xc2fb)
local left = memory.readbyte(0xc2fc)
local right = memory.readbyte(0xc2fd)
nvda.say(string.format("up %d down %d left %d right %d", up, down, left, right))
end

memory.registerexec(0x292c, function()
local type = memory.readbyteunsigned(0xd4e4)
if type == 0x18 then
audio.play("sounds\\grass.wav", 0, 0, 30)
else
audio.play("sounds\\step.wav", 0, 0, 30)
end
end)

function handle_user_actions()
res, data = flagged()
if not res then
return
end
nvda.stop()
local command, args = data:match("^([a-z_]+) *(.*)$")
print("parsing " .. command)
if commands[command] ~= nil then
local fn, needs_map = unpack(commands[command])
if needs_map and not on_map() then
nvda.say("Not on a map.")
return
end
fn(args)
end
end

function read_current_item()
local info = get_map_info()
reset_current_item_if_needed(info)
read_item(info.objects[current_item])
end

function reset_current_item_if_needed(info)
if info.group*256+info.number ~= current_map then
current_item = 1
current_map = info.group*256+info.number
end
end

function read_next_item()
local info = get_map_info()
reset_current_item_if_needed(info)
current_item = current_item + 1
if current_item > #info.objects then
current_item = 1
end
read_current_item()
end

function read_previous_item()
local info = get_map_info()
reset_current_item_if_needed(info)
current_item = current_item - 1
if current_item == 0  or current_item > #info.objects then
current_item = #info.objects
end
read_current_item()
end

function pathfind()
local info = get_map_info()
reset_current_item_if_needed(info)
local obj = info.objects[current_item]
find_path_to(obj)
end

function read_item(item)
local y = memory.readbyte(0xdcb7)
local x = memory.readbyte(0xdcb8)
local map_id = get_map_id()
local s = item.name
if names[map_id] ~= nil and names[map_id][item.id] ~= nil then
s = names[map_id][item.id]
end
if item.x then
s = s .. ": " .. direction(x, y, item.x, item.y)
end
nvda.say(s)
end

function get_map_blocks()
-- map width, height in blocks
local width = memory.readbyteunsigned(0xd19f)
local height = memory.readbyteunsigned(0xd19e)
local row_width = width+6 -- including border
ptr = 0xc800 -- start of overworld
-- there is a border of 3 blocks on each edge of the map.
local blocks = {}
for y = 0, height - 1 do
for x = 0, width - 1 do
local block = memory.readbyteunsigned(ptr+(width+6)*3+(y*row_width)+(x+3))
blocks[y] = blocks[y] or {}
blocks[y][x] = block
end
end
return blocks
end

function get_map_collisions()
local blocks = get_map_blocks()
local width = #blocks[0]
local collisions = {}
function add_collision(x, y, type)
collisions[y] = collisions[y] or {}
collisions[y][x] = type
end
local collision_bank = memory.readbyteunsigned(0xd1df)
local collision_addr = memory.readword(0xd1e0)
collision_addr = (collision_bank * 16384) + (collision_addr - 16384)

for y = 0, #blocks do
for x = 0, width do
-- Each block is a 2x2 walkable tile. The collision data is
-- (top left, top right, bottom left, bottom right).
-- We have block data for the first half of the xy pair here.
local block_index = blocks[y][x]
local ptr = collision_addr + (block_index * 4)
add_collision(x*2, y*2, memory.gbromreadbyte(ptr))
add_collision(x*2+1, y*2, memory.gbromreadbyte(ptr+1))
add_collision(x*2, y*2+1, memory.gbromreadbyte(ptr+2))
add_collision(x*2+1, y*2+1, memory.gbromreadbyte(ptr+3))
end -- x
end -- y
return collisions
end

function find_path_to(obj)
local player_y = memory.readbyte(0xdcb7)
local player_x = memory.readbyte(0xdcb8)
local collisions = get_map_collisions()
local allnodes = {}
local width = #collisions[0]
local start = nil
local dest = nil
-- set all the objects to walls
for i, object in ipairs(get_objects()) do
collisions[object.y][object.x] = 7
end
-- if searching for a connection, we scan the edge until we find a free tile.
local function find_free_x(y)
for x = 0, width do
if not inpassible_tiles[collisions[y][x]] then
return x
end
end
end
local function find_Free_y(x)
for y = 0, #collisions do
if not inpassible_tiles[collisions[y][x]] then
return y
end
end
end
if obj.type == "connection" then
if obj.direction == "north" then
dest_y = 0
dest_x = find_free_x(dest_y)
elseif obj.direction == "south" then
dest_y = #collisions
dest_x = find_free_x(dest_y)
elseif obj.direction == "east" then
dest_x = width
dest_y = find_Free_y(dest_x)
elseif obj.direction == "west" then
dest_x = 0
dest_y = find_Free_y(dest_x)
end
else -- not a connection
dest_x = obj.x
dest_y = obj.y
end
if dest_x == nil or dest_y == nil then
nvda.say("no path")
return
end
if inpassible_tiles[collisions[dest_y][dest_x]] then
print(dest_y .. " " .. dest_x .. " is inpassible, searching")
local to_search = {
{dest_y+1, dest_x};
{dest_y-1, dest_x};
{dest_y-2, dest_x};
{dest_y, dest_x+1};
{dest_y, dest_x-1};
{dest_y, dest_x+2};
{dest_y, dest_x-2};
}
for i, pos in ipairs(to_search) do
if collisions[pos[1]] ~= nil and collisions[pos[1]][pos[2]] ~= nil and not inpassible_tiles[collisions[pos[1]][pos[2]]] then
dest_y = pos[1]
dest_x = pos[2]
print("found " .. dest_y .. " " .. dest_x)
break
end
end
end
-- generate the all nodes list for pathfinding, and track the start and end nodes
for y = 0, #collisions do
for x = 0, width do
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
if astar.dist_between(node, neighbor) ~= 1 then
return false
elseif inpassible_tiles[neighbor.type] then
return false
end
return true
end -- valid
path = astar.path(start, dest, allnodes, true, valid)
if not path then
nvda.say("no path")
return
end
for i, node in ipairs(path) do
if i > 1 then
local last = path[i-1]
nvda.say(direction(last.x, last.y, node.x, node.y))
end
end
end

inpassible_tiles = {
[7]=true;
[18] = true;
[21] = true;
[41] = true;
[145]=true;
[149] = true;
}

function rename_current(name)
if not on_map() then
return
end
local info = get_map_info()
reset_current_item_if_needed(info)
local id = get_map_id()
local obj_id = info.objects[current_item].id
names[id] = names[id] or {}
if name ~= "" then
names[id][obj_id] = name
else
names[id][obj_id] = nil
end
write_names()
end

function write_names()
local file = io.open("names.lua", "wb")
file:write(serpent.block(names, {comment=false}))
io.close(file)
nvda.say("names saved")
end
function rename_map(name)
local id = get_map_id()
local obj_id = "map"
names[id] = names[id] or {}
if name ~= "" then
names[id][obj_id] = name
else
names[id][obj_id] = nil
end
write_names()
end

function read_mapname()
local id = get_map_id()
if names[id] == nil or names[id]["map"] == nil then
nvda.say("unknown")
else
nvda.say(names[id]["map"])
end
end

commands = {
coords = {read_coords, true};
tiles = {read_tiles, true};
current = {read_current_item, true};
next = {read_next_item, true};
previous = {read_previous_item, true};
pathfind = {pathfind, true};
name = {rename_current, true};
text = {read_text, false};
mapname = {rename_map, true};
current_mapname = {read_mapname, true};
}

counter = 0
oldtext = "" -- last text seen
current_item = nil
while true do
emu.frameadvance()
counter = counter + 1
handle_user_actions()
local text = get_text()
if text ~= oldtext then
want_read = true
text_updated_counter = counter
oldtext = text
end
if want_read and (counter - text_updated_counter) >= 20 then
read_text()
want_read = false
end

end
