require "a-star"
serpent = require "serpent"
local inputbox = require "Inputbox"
scriptpath = debug.getinfo(1, "S").source:sub(2):match("^.*\\")
FLAGFILE = scriptpath .. "flag"
EAST = 1
WEST = 2
SOUTH = 4
NORTH = 8
-- characters table
dofile("chars.lua")
dofile("sprites.lua")
dofile("fonts.lua")

function is_printable_screen()
local s = ""
for i = 0, 15 do
s = s .. string.char(memory.readbyte(0x8800+i))
end
if fonts[s] then
return true
else
return false
end
end

function load_table(file)
local res, t
fp = io.open(file, "rb")
if fp ~= nil then
local data = fp:read("*all")
res, t = serpent.load(data)
io.close(fp)
end
return res, t
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

function get_text_lines()
local raw_text = memory.readbyterange(0xc4a0, 360)
local printable = is_printable_screen()
local lines = {}
local line = ""
local menu_position = nil
for i = 1, 360, 20 do
for j = 0, 19 do
local char = raw_text[i+j]
if char == 0xed then
menu_position = i
end
if i+j == 359 and char == 0xee then
char = " "
end
if printable then
char = translate(char)
else
char = " "
end
line = line .. char
end
table.insert(lines, line)
line = ""
end -- i
return lines, menu_position
end

last17 = ""
function read_text(args, auto)
local lines = get_text_lines()
if auto then
if trim(lines[15]) == trim(last17) then
lines[15] = ""
end
last17 = lines[17]
end
for i, line in pairs(lines) do
line = trim(line)
if line ~= "" then
tolk.output(line)
end
end
end

function trim(s)
return s:gsub("^%s*(.-)%s*$", "%1")
end

function parse_menu_header()
local ptr = 0xcf81
local results = {}
results.flags = memory.readbyte(ptr)
results.start_y = memory.readbyte(ptr+1)
results.start_x = memory.readbyte(ptr+2)
results.end_y = memory.readbyte(ptr+3)
results.end_x = memory.readbyte(ptr+4)
results.ptr = memory.readword(ptr+5)
return results
end

function get_outer_menu_text(text)
local header = parse_menu_header()
local lines = get_text_lines()
local s = ""
for i = header.end_y+1, 18 do
local line = trim(lines[i])
if i == 15 and line == trim(last17) then
line = ""
end
if line ~= "" then
s = s .. line .. "\n"
end
end
return s
end

function read_coords()
local y = memory.readbyte(0xdcb7)
local x = memory.readbyte(0xdcb8)
if not on_map() then
tolk.output("Not on a map")
return
end

tolk.output("x " .. x .. ", y " .. y)
end

function get_warps()
local current_mapid = get_map_id()
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
local mapid = memory.gbromreadbyte(start+3)*256+memory.gbromreadbyte(start+4)
local name = "Warp " .. i
local mapname = get_map_name(mapid)
if mapname ~= "" then
name = mapname
end
local warp = {x=warpx, y=warpy, name=name, type="warp", id="warp_" .. i}
warp.name = get_name(current_mapid, warp)
table.insert(results, warp)
end
return results
end

function get_signposts()
local eventstart = memory.readword(0xd1a6)
local bank = memory.readbyte(0xd1a3)
local mapid = get_map_id()
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
post.name = get_name(mapid, post)
table.insert(results, post)
ptr = ptr + 5 -- point at the next one
end
return results
end

function get_name(mapid, obj)
return (names[mapid] or {})[obj.id] or obj.name
end

function get_objects()
local ptr = 0xd71e+16 -- skip the player
local liveptr = 0xd81e -- live objects
local results = {}
local width = memory.readbyteunsigned(0xd19f)
local height = memory.readbyteunsigned(0xd19e)
local mapid = get_map_id()
for i = 1, 15 do
local sprite = memory.readbyte(ptr+0x01)
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
if sprites[sprite] ~= nil then
name = sprites[sprite]
end
if y ~= 255 and y-4 <= height*2 and x-4 <= width*2 then
if memory.readbyte(liveptr+i) == 0 then
local obj = {x=x-4, y=y-4, name=name, type="object", id="object_" .. i}
obj.name = get_name(mapid, obj)
table.insert(results, obj)
end
end
ptr = ptr + 16
end
local collisions = get_map_collisions()
for y = 0, #collisions do
for x = 0, #collisions[0] do
if collisions[y][x] == 147 then
table.insert(results, {name="PC", x=x, y=y, id="pc", type="object"})
end
end
end
return results
end

function get_connections()
local connections = memory.readbyte(0xd1a8)
local function hasbit(x, p)
return x % (p + p) >= p
end
local results = {}
local function add_connection(dir, mapid)
local name = dir .. " connection"
local mapname = get_map_name(mapid)
if mapname ~= "" then
name = name .. ", " .. mapname
end
table.insert(results, {type="connection", direction=dir, name=name, id="connection_" .. dir})
end

if hasbit(connections, NORTH) then
add_connection("north", memory.readbyte(0xd1a9)*256+memory.readbyte(0xd1aa))
end
if hasbit(connections, SOUTH) then
add_connection("south", memory.readbyte(0xd1b5)*256+memory.readbyte(0xd1b6))
end
if hasbit(connections, EAST) then
add_connection("east", memory.readbyte(0xd1cd)*256+memory.readbyte(0xd1ce))
end
if hasbit(connections, WEST) then
add_connection("west", memory.readbyte(0xd1c1)*256+memory.readbyte(0xd1c2))
end
return results
end

function get_map_name(mapid)
if names[mapid] ~= nil and names[mapid]["map"] ~= nil then
return names[mapid]["map"]
elseif default_names[mapid] ~= nil and default_names[mapid].map ~= nil then
return default_names[mapid].map
else
return ""
end
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

function only_direction(x, y, destx, desty)
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

function read_tiles()
local down = memory.readbyte(0xc2fa)
local up = memory.readbyte(0xc2fb)
local left = memory.readbyte(0xc2fc)
local right = memory.readbyte(0xc2fd)
tolk.output(string.format("up %d down %d left %d right %d", up, down, left, right))
end

memory.registerexec(0x292c, function()
local type = memory.readbyteunsigned(0xd4e4)
if type == 0x18 then
audio.play(scriptpath .. "sounds\\grass.wav", 0, 0, 30)
else
audio.play(scriptpath .. "sounds\\step.wav", 0, 0, 30)
end
end)

in_options = false
memory.registerexec(0x2d63, function()
if memory.getregister("a") == 57 and memory.getregister("h") == 0x41 and memory.getregister("l") == 0xd0 then
in_options = true
end
end)

function compare(t1, t2)
if #t1 ~= #t2 then
return false
end
for i, v in ipairs(t1) do
if t1[i] ~= t2[i] then
return false
end
end
return true
end

old_pressed_keys = {}
function handle_user_actions()
local kbd = input.read()
local pressed_keys = {}
kbd.xmouse = nil
kbd.ymouse = nil
for k, v in pairs(kbd) do
if v then
table.insert(pressed_keys, k)
end
end
table.sort(pressed_keys)

if #pressed_keys == 0 or compare(pressed_keys, old_pressed_keys) then
old_pressed_keys = pressed_keys
return
end
old_pressed_keys = pressed_keys
local command
for keys, cmd in pairs(commands) do
if compare(keys, pressed_keys) then
command = cmd
break
end
end
if command == nil then
return
end
tolk.silence()
local fn, needs_map = unpack(command)
if needs_map and not on_map() then
tolk.output("Not on a map.")
else
fn(args)
end -- not on map
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
local s = get_name(mapid, item)
if item.x then
s = s .. ": " .. direction(x, y, item.x, item.y)
end
tolk.output(s)
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
tolk.output("no path")
return
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
for i, pos in ipairs(to_search) do
if collisions[pos[1]] ~= nil and collisions[pos[1]][pos[2]] ~= nil and not inpassible_tiles[collisions[pos[1]][pos[2]]] then
dest_y = pos[1]
dest_x = pos[2]
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
path = astar.path(start, dest, allnodes, true, valid)
if not path then
tolk.output("no path")
return
end
local function same_direction(n1, n2)
if (n1.x ~= n2.x and n1.y == n2.y) or (n1.x == n2.x and n1.y ~= n2.y) then
return true
else
return false
end
end
local start = path[1]
local new_path = {}
for i, node in ipairs(path) do
if i > 1 then
local last = path[i-1]
table.insert(new_path, only_direction(last.x, last.y, node.x, node.y))
end -- i > 1
end -- for
for _, v in ipairs(group_unique_items(new_path)) do
tolk.output(v[2] .. " " .. v[1])
end
end -- function

inpassible_tiles = {
[7]=true;
[18] = true;
[21] = true;
[41] = true;
[145]=true;
[149] = true;
[178] = true;
}

function rename_current()
local info = get_map_info()
reset_current_item_if_needed(info)
local id = get_map_id()
local obj_id = info.objects[current_item].id
name = inputbox.inputbox("Name object", "Enter a new name for " .. info.objects[current_item].name, info.objects[current_item].name)
if name == nil then
return
end
names[id] = names[id] or {}
if trim(name) ~= "" then
names[id][obj_id] = trim(name)
else
names[id][obj_id] = nil
end
write_names()
end

function write_names()
local file = io.open("names.lua", "wb")
file:write(serpent.block(names, {comment=false}))
io.close(file)
tolk.output("names saved")
end
function rename_map()
local id = get_map_id()
local obj_id = "map"
name = inputbox.inputbox("Rename map", "Enter a new name for " .. names[id][obj_id], names[id][obj_id])
if name == nil then
return
end
names[id] = names[id] or {}
if trim(name) ~= "" then
names[id][obj_id] = trim(name)
else
names[id][obj_id] = nil
end
write_names()
end

function read_mapname()
local name = get_map_name(get_map_id())
tolk.output(name)
end

function read_menu_item(lines, pos)
local line = math.floor(pos/20)+1
local l = lines[line]
tolk.output(l)
if in_options and not lines[line+1]:match("^%s*$") then
tolk.output(lines[line+1])
end
end
BAR_LENGTH = 6

function read_enemy_health()
local function read_bar(addr)
local count
-- no bar here
if memory.readbyte(addr+BAR_LENGTH) ~= 0x6b then
return nil
end
local total = 0
for i = 0, BAR_LENGTH - 1 do
if memory.readbyte(addr+i) == 0x6a then
total = total +1
end
end
return total
end
local enemy = read_bar(0xc4a0+(2*20)+4)
if enemy == nil then
tolk.output("no bar found")
else
tolk.output(string.format("%d of %d", enemy, BAR_LENGTH))
end
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

commands = {
[{"C"}] = {read_coords, true};
[{"J"}] = {read_previous_item, true};
[{"K"}] = {read_current_item, true};
[{"L"}] = {read_next_item, true};
[{"P"}] = {pathfind, true};
[{"N"}] = {rename_current, true};
[{"T"}] = {read_text, false};
[{"N", "shift"}] = {rename_map, true};
[{"M", "shift"}] = {read_mapname, true};
[{"H"}] = {read_enemy_health, false},
}

tolk = require "tolk"
assert(package.loadlib("audio.dll", "luaopen_audio"))()
tolk.output("ready")
res, names = load_table("names.lua")
if res == nil then
tolk.output("Unable to load names file.")
names = {}
end
res, default_names = load_table("default_names.lua")
if res == nil then
tolk.output("Unable to load default names file.")
default_names = {}
end

counter = 0
oldtext = "" -- last text seen
current_item = nil
while true do
emu.frameadvance()
counter = counter + 1
handle_user_actions()
local text_lines, menu_pos = get_text_lines()
local text = table.concat(text_lines, "")
if text ~= oldtext then
want_read = true
text_updated_counter = counter
oldtext = text
end
if want_read and (counter - text_updated_counter) >= 20 then
-- if we're in a menu
if menu_pos ~= nil then
-- if the menu outer text changed
outer_text = get_outer_menu_text(text)
if not in_options and last_outer_text ~= outer_text then
-- probably a different menu, mom's questions cause this
if outer_text ~= "" then
tolk.output(outer_text)
end
last_outer_text = outer_text
end
read_menu_item(text_lines, menu_pos)
else
if in_options then
in_options = false
end
read_text("", true)
end
want_read = false
end

end
