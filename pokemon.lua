require "a-star"
serpent = require "serpent"
local inputbox = require "Inputbox"
scriptpath = debug.getinfo(1, "S").source:sub(2):match("^.*\\")
EAST = 1
WEST = 2
SOUTH = 4
NORTH = 8
TEXTBOX_PATTERN = "\x79\x7a\x7a\x7a\x7a\x7a\x7a\x7a\x7a\x7a\x7a\x7a\x7a\x7a\x7a\x7a\x7a\x7a\x7a\x7b"
language_names = {}
function load_language(code)
local t = {"chars.lua", "fonts.lua", "ram.lua", "sprites.lua"}
for i, v in ipairs(t) do
local f = loadfile(scriptpath .. "\\lang\\" .. code .. "\\" .. v)
if f ~= nil then
f()
end
end
end
load_language("en")

dofile("screen.lua")
dofile("info.lua")
dofile("tiles.lua")
dofile("navigation.lua")
dofile("view.lua")



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

function translate(char, above)
if chars[char] then
if above then
return chars[above*256+char] or chars[char]
end
return chars[char]
else
return " "
end
end


function read_coords()
local x, y = get_player_xy()
tolk.output("x " .. x .. ", y " .. y)
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
local x, y = get_player_xy()
local map_id = get_map_id()
local s = get_name(mapid, item)
if item.x then
s = s .. ": " .. direction(x, y, item.x, item.y)
end
if item.facing then
s = s .. " facing " .. facing_to_string(item.facing)
end
tolk.output(s)
end

function get_map_blocks()
-- map width, height in blocks
local width = memory.readbyteunsigned(RAM_MAP_WIDTH)
local height = memory.readbyteunsigned(RAM_MAP_HEIGHT)
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
local collision_bank = memory.readbyteunsigned(RAM_COLLISION_BANK)
local collision_addr = memory.readword(RAM_COLLISION_ADDR)
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
local path
local width = memory.readbyteunsigned(RAM_MAP_WIDTH)
local height = memory.readbyteunsigned(RAM_MAP_HEIGHT)

if obj.type == "connection" then
if obj.direction == "north" then
dest_y = 0
for dest_x = 0, width*2-1 do
if not inpassible_tiles[get_collision_data_xy(dest_x+4, dest_y+3)] then
path = find_path_to_xy(dest_x, dest_y)
end
if path ~= nil then break end
end
elseif obj.direction == "south" then
dest_y = height*2-1
for dest_x = 0, width*2-1 do
if not inpassible_tiles[get_collision_data_xy(dest_x+4, dest_y+5)] then
path = find_path_to_xy(dest_x, dest_y)
end
if path ~= nil then break end
end
elseif obj.direction == "east" then
dest_x = width*2-1
for dest_y = 0, height*2-1 do
if not inpassible_tiles[get_collision_data_xy(dest_x+5, dest_y+4)] then
path = find_path_to_xy(dest_x, dest_y)
end
if path ~= nil then break end
end
elseif obj.direction == "west" then
dest_x = 0
for dest_y = 0, height*2-1 do
if not inpassible_tiles[get_collision_data_xy(dest_x+3, dest_y+4)] then
path = find_path_to_xy(dest_x, dest_y)
end
if path ~= nil then break end
end
end
else
path = find_path_to_xy(obj.x, obj.y, true)
end
if path == nil then
tolk.output("no path")
return
end
speak_path(clean_path(path))
end

function find_path_to_xy(dest_x, dest_y, search)
local player_x, player_y = get_player_xy()
local collisions = get_map_collisions()
local allnodes = {}
local width = #collisions[0]
local start = nil
local dest = nil
-- set all the objects to walls
for i, object in ipairs(get_objects()) do
collisions[object.y][object.x] = 7
end
for i, warp in ipairs(get_warps()) do
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
return path
end

function clean_path(path)
local start = path[1]
local new_path = {}
for i, node in ipairs(path) do
if i > 1 then
local last = path[i-1]
table.insert(new_path, only_direction(last.x, last.y, node.x, node.y))
end -- i > 1
end -- for
return group_unique_items(new_path)
end

function speak_path(path)
for _, v in ipairs(path) do
tolk.output(v[2] .. " " .. v[1])
end
end -- function


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
if names[id] then
print("there were names.")
name = inputbox.inputbox("Rename map", "Enter a new name for " .. names[id][obj_id], names[id][obj_id])
else
print("No names.")
name = inputbox.inputbox("Rename map", "Enter a new name for " .. get_map_name(id), get_map_name(id))
end
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
if lines[line+1]:match('\xc2\xa5') then
tolk.output(lines[line+1])
end
if in_options and not lines[line+1]:match("^%s*$") then
tolk.output(lines[line+1])
end
end
BAR_LENGTH = 6

function get_enemy_health()
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
local enemy = read_bar(RAM_TEXT+(2*20)+4)
if enemy == nil then
return nil
else
return string.format("%d of %d", enemy, BAR_LENGTH)
end
end

function read_enemy_health()
local health = get_enemy_health()
if health == nil then
tolk.output("no bar found")
else
tolk.output(enemy_health)
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

function read_keyboard()
local x = memory.readbyte(RAM_KEYBOARD_X)
local y = memory.readbyte(RAM_KEYBOARD_Y)
local t = KEYBOARD_UPPER
if screen.lines[17]:match(KEYBOARD_UPPER_STRING) ~= nil then
t = KEYBOARD_LOWER
end
local word = t[y+1][x+1] or "unknown"
tolk.output(word)
end

function get_block(mapx, mapy)
local width = memory.readbyte(RAM_MAP_WIDTH)
local row_width = width+6
local ptr = 0xc801+row_width
-- now we're on the second row, second column
local skip_rows = math.floor(mapy/2)
local skip_cols = math.floor(mapx/2)
local block = memory.readbyte(ptr+(skip_rows*row_width)+skip_cols)
return block
end
function get_collision_data(block)
local collision_bank = memory.readbyteunsigned(RAM_COLLISION_BANK)
local collision_addr = memory.readword(RAM_COLLISION_ADDR)
collision_addr = (collision_bank * 16384) + (collision_addr - 16384)
return memory.gbromreadbyterange(collision_addr+(block*4), 4)
end

function get_collision_data_xy(mapx, mapy)
local block = get_block(mapx, mapy)
if block == 0 then return 255 end
local data = get_collision_data(block)
if mapx % 2 == 0 then
i = 1
else
i=2
end
if mapy%2 ~= 0 then
i = i + 2
end
return data[i]
end

function keyboard_showing(screen)
if screen.lines[17]:match(KEYBOARD_STRING) ~= nil then
return true
end
return false
end


function handle_keyboard()
col = memory.readbyte(RAM_KEYBOARD_X)
row = memory.readbyte(RAM_KEYBOARD_Y)
if row ~= old_kbd_row or col ~= old_kbd_col then
read_keyboard()
old_kbd_row = row
old_kbd_col = col
end -- if the row/col changed
end -- handle_keyboard

function read_health_if_needed()
if not (last_menu_pos == nil and screen.menu_position ~= nil) then
return
end
enemy_health = get_enemy_health()
if enemy_health == nil then
return
end
tolk.output(screen.lines[11])
tolk.output("enemy health: " .. enemy_health)
end

function facing_to_string(d)
d = bit.rshift(d, 2)
if d == 0 then return "down" end
if d == 1 then return "up" end
if d == 2 then return "left" end
if d == 3 then return "right" end
return "unknown"
end


function get_language_code()
local code = ""
for i = 0, 3 do
code = code .. string.char(memory.gbromreadbyte(0x13f+i))
end
return code
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
[{"I"}] = {toggle_navigation, true},
[{"U", "shift"}] = {orient_to_player, true},
[{"J", "shift"}] = {map_left, true},
[{"I", "shift"}] = {map_up, true},
[{"L", "shift"}] = {map_right, true},
[{"K", "shift"}] = {map_down, true},
[{"P", "shift"}] = {pathfind_map_view, true},
}

tolk = require "tolk"
assert(package.loadlib("audio.dll", "luaopen_audio"))()
tolk.output("ready")
res, names = load_table("names.lua")
if res == nil then
names = {}
end
res, default_names = load_table(scriptpath .. "\\lang\\en\\" .. "default_names.lua")
if res == nil then
tolk.output("Unable to load default names file.")
default_names = {}
end
-- get current language
local code = get_language_code()
-- including everything but english in here, since english is the default
local codemap = {
["BXTJ"] = "ja",
["BYTD"] = "de",
["BYTS"] = "es",
["BYTI"] = "it",
["BYTF"] = "fr",
}
if codemap[code] then
load_language(codemap[code])
language = codemap[code]
res, language_names = load_table(scriptpath .. "\\lang\\" .. codemap[code] .. "\\default_names.lua")
if res == nil then language_names = {} end
end
memory.registerexec(RAM_FOOTSTEP_FUNCTION, function()
announce_tiles()
local type = memory.readbyteunsigned(RAM_STANDING_TILE)
if type == 0x18 then
audio.play(scriptpath .. "sounds\\grass.wav", 0, 0, 30)
elseif type == 0x29 then
audio.play(scriptpath .. "sounds\\ocean.wav", 0, 0, 30)
else
audio.play(scriptpath .. "sounds\\step.wav", 0, 0, 30)
end
end)

in_options = false
memory.registerexec(RAM_BANK_SWITCH, function()
if memory.getregister("a") == 57 and memory.getregister("h") == 0x41 and memory.getregister("l") == 0xd0 then
in_options = true
end
end)

counter = 0
oldtext = "" -- last text seen
current_item = nil
in_keyboard = false
old_kbd_col = nil
old_kbd_row = nil
while true do
emu.frameadvance()
counter = counter + 1
handle_user_actions()
screen = get_screen()
local text = table.concat(screen.lines, "")
if screen:keyboard_showing() then
handle_keyboard()
end -- handling keyboard
if text ~= oldtext then
want_read = true
text_updated_counter = counter
oldtext = text
end
if want_read and (counter - text_updated_counter) >= 20 then
-- if we're in a menu
if screen.menu_position ~= nil then
-- if the menu outer text changed
outer_text = screen:get_outer_menu_text()
if not in_options and last_outer_text ~= outer_text then
-- probably a different menu, mom's questions cause this
if outer_text ~= "" then
tolk.output(outer_text)
end
last_outer_text = outer_text
end
read_health_if_needed()
read_menu_item(screen.lines, screen.menu_position)
last_menu_pos = screen.menu_position
else
last_menu_pos = nil
if in_options then
in_options = false
end
read_text(true)
end
want_read = false
end

end
