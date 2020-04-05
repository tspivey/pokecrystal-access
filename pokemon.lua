require "a-star"
require "guide"
local log = require "log"
require "name"
require "strlib"
require "tile"
require "trail"
local inputbox = require "inputbox"
log.usecolor = false
log.level = "info"
scriptpath = debug.getinfo(1, "S").source:sub(2):match("^.*\\")
EAST = 1
WEST = 2
SOUTH = 4
NORTH = 8
TEXTBOX_PATTERN = "\x79\x7a\x7a\x7a\x7a\x7a\x7a\x7a\x7a\x7a\x7a\x7a\x7a\x7a\x7a\x7a\x7a\x7a\x7a\x7b"
language_names = {}
camera_x = -1
camera_y = -1
pathfind_switch = false

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

function is_printable_screen()
local s = ""
for i = 0, 15 do
s = s .. string.char(memory.readbyte(RAM_SCREEN+i))
end
if fonts[s] then
return true
else
return false
end
end

function load_names()
local res, names = name.load_table("names.lua")
if res == nil then
names = {}
end
return names
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

function get_screen()
local raw_text = memory.readbyterange(RAM_TEXT, 360)
local printable = is_printable_screen()
local lines = {}
local tile_lines = {}
local line = ""
local tile_line = ""
local menu_position = nil
local line_number = 0
for i = 1, 360, 20 do
line_number = line_number + 1
for j = 0, 19 do
local char = raw_text[i+j]
tile_line = tile_line .. string.char(char)
if char == 0xed then
menu_position = i
end
if i+j == 359 and char == 0xee then
char = 0x7f
end
if printable then
if language == "ja" then
above = (tile_lines[line_number-1] or ""):sub(j+1)
if above ~= "" then above = string.byte(above) else above=nil end
if above == 0x7f then above = nil end
char = translate(char, above)
else
char = translate(char)
end
else -- not printable
char = " "
end
line = line .. char
end
table.insert(lines, line)
table.insert(tile_lines, tile_line)
line = ""
tile_line = ""
end -- i
return {lines=lines, menu_position=menu_position, tile_lines=tile_lines, keyboard_showing=keyboard_showing,
get_outer_menu_text=get_outer_menu_text, get_textbox=get_textbox}
end

last17 = ""
last_textbox_text = nil
function read_text(auto)
local lines = get_screen().lines
if auto then
if strlib.trim(lines[15]) == strlib.trim(last17) then
log.debug("Repeated last17 " .. lines[15])
lines[15] = ""
end
last17 = lines[17]
local textbox = get_textbox()
if textbox and should_read_textbox() then
textbox_text = table.concat(textbox, "")
if textbox_text ~= last_textbox_text then
output_lines(textbox)
end
last_textbox_text = textbox_text
return
else -- no textbox here
last_textbox_text = nil
end -- textbox
end -- auto
output_lines(lines)
end

function should_read_textbox()
if (screen.tile_lines[3]:match("\x60\x61") or screen.tile_lines[10]:match("\x60\x61")) then return true end
if strlib.trim(screen.lines[15]) == MSG_HOW_MANY then return true end
return false
end

function output_lines(lines)
for i, line in pairs(lines) do
line = strlib.trim(line)
if line ~= "" then
tolk.output(line)
end
end
end -- output_lines

function parse_menu_header()
local ptr = RAM_MENU_HEADER
local results = {}
results.flags = memory.readbyte(ptr)
results.start_y = memory.readbyte(ptr+1)
results.start_x = memory.readbyte(ptr+2)
results.end_y = memory.readbyte(ptr+3)
results.end_x = memory.readbyte(ptr+4)
results.ptr = memory.readword(ptr+5)
return results
end

function get_outer_menu_text(screen)
local textbox = screen:get_textbox()
if textbox then
return strlib.trim(table.concat(textbox, " "))
end
local header = parse_menu_header()
local lines = get_screen().lines
local s = ""
for i = header.end_y+1, 18 do
local line = strlib.trim(lines[i])
if i == 15 and line == strlib.trim(last17) then
log.debug("Repeated last17 " .. line)
line = ""
end
if line ~= "" then
s = s .. line .. "\n"
end
end
return s
end

function read_coords()
local x, y = get_player_xy()
log.debug("Player coordinates x = " .. x .. ", y = " .. y)
tolk.output("x " .. x .. ", y " .. y)
end

function get_warps()
local current_mapid = get_map_id()
local eventstart = memory.readword(RAM_MAP_EVENT_HEADER_POINTER)
local bank = memory.readbyte(RAM_MAP_SCRIPT_HEADER_BANK)
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
local eventstart = memory.readword(RAM_MAP_EVENT_HEADER_POINTER)
local bank = memory.readbyte(RAM_MAP_SCRIPT_HEADER_BANK)
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
local ptr = RAM_MAP_OBJECTS+16 -- skip the player
local liveptr = RAM_LIVE_OBJECTS -- live objects
local results = {}
local width = memory.readbyteunsigned(RAM_MAP_WIDTH)
local height = memory.readbyteunsigned(RAM_MAP_HEIGHT)
local mapid = get_map_id()
for i = 1, 15 do
local sprite = memory.readbyte(ptr+0x01)
local y = memory.readbyte(ptr+0x02)
local x = memory.readbyte(ptr+0x03)
local facing = memory.readbyte(ptr+0x04)
local object_struct = memory.readbyte(ptr)
-- we have map object structs, and object structs. If the first byte of the
-- map object struct is not 0xff, use that to look up the object struct,
-- and get its coords.
-- if object is on screen and on the map
local l
if object_struct ~= 0xff and y ~= 255 then
if language == "ja" then
l = RAM_OBJECT_STRUCTS+((object_struct)*40)
else
l = RAM_OBJECT_STRUCTS+((object_struct-1)*40)
end
x = memory.readbyte(l+0x12)
y = memory.readbyte(l+0x13)
facing = memory.readbyte(l+0xd)
end
local name = "Object " .. i .. string.format(", %x", ptr)
if sprites[sprite] ~= nil then
name = sprites[sprite]
end
if y ~= 255 and y-4 <= height*2 and x-4 <= width*2 then
if memory.readbyte(liveptr+i) == 0 then
local obj = {x=x-4, y=y-4, name=name, type="object", id="object_" .. i, facing=facing, sprite_id = sprite}
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
local connections = memory.readbyte(RAM_MAP_CONNECTIONS)
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
add_connection("north", memory.readbyte(RAM_MAP_NORTH_CONNECTION)*256+memory.readbyte(RAM_MAP_NORTH_CONNECTION+1))
end
if hasbit(connections, SOUTH) then
add_connection("south", memory.readbyte(RAM_MAP_SOUTH_CONNECTION)*256+memory.readbyte(RAM_MAP_SOUTH_CONNECTION+1))
end
if hasbit(connections, EAST) then
add_connection("east", memory.readbyte(RAM_MAP_EAST_CONNECTION)*256+memory.readbyte(RAM_MAP_EAST_CONNECTION+1))
end
if hasbit(connections, WEST) then
add_connection("west", memory.readbyte(RAM_MAP_WEST_CONNECTION)*256+memory.readbyte(RAM_MAP_WEST_CONNECTION+1))
end
return results
end

function get_map_name(mapid)
if names[mapid] ~= nil and names[mapid]["map"] ~= nil then
log.debug("Map name " .. names[mapid]["map"])
return names[mapid]["map"]
elseif language_names[mapid] ~= nil and language_names[mapid].map ~= nil then
return language_names[mapid].map
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
local mapgroup = memory.readbyte(RAM_MAP_GROUP)
local mapnumber = memory.readbyte(RAM_MAP_NUMBER)
return mapgroup, mapnumber
end

function get_map_id()
local group, number = get_map_gn()
return group*256+number
end

-- Returns true or false indicating whether we're on a map or not.
function on_map()
local mapgroup, mapnumber = get_map_gn()
if (mapnumber == 0 and mapgroup == 0) or memory.readbyte(RAM_IN_BATTLE) ~= 0 then
return false
else
return true
end
end

-- Read current and around tiles
function read_tiles()
local player_x, player_y = get_player_xy()
local collisions = get_map_collisions()
local s = trail.route(player_y, player_x, collisions)

tolk.output(s)
end

-- Playback tile sounds
function play_tile_sound(type, pan, vol, play_stair)
	log.debug(string.format("playing sound for tile 0x%X", type))
	audio.play(scriptpath .. tile.get_tile_sound(type, play_stair), 0, pan, vol)
end

-- reset camera focus when camera_xy equal -1
function reset_camera_focus(player_x, player_y)
	if camera_x == -1 then
		camera_x = player_x
	end
	if camera_y == -1 then
		camera_y = player_y
	end
end

-- Moving camera focus
function camera_move(y, x, ignore_wall)
	local player_x, player_y = get_player_xy()
	reset_camera_focus(player_x, player_y)
	camera_y = camera_y + y
	camera_x = camera_x + x

	local collisions = get_map_collisions()
	local pan = (camera_x - player_x) * 5
	local vol = 40 - math.abs(player_y - camera_y)

	-- clipping pan and volume
	if pan > 100 then
		vol = vol - ((pan / 5) - 20)
		pan = 100
	end
	if pan < -100 then
		vol = vol - math.abs((pan / 5) - 20)
		pan = -100
	end
	if vol < 5 then
		vol = 5
	end

	if camera_y >= 0 and camera_x >= 0 and camera_y <= #collisions and camera_x <= #collisions[1] then
		local objects = get_objects()
		for i, obj in pairs(objects) do
			if obj.x == camera_x and obj.y == camera_y then
				if obj.sprite_id == 90 then
					audio.play(scriptpath .. "sounds\\s_boulder.wav", 0, pan, vol)
				elseif obj.sprite_id == 89 then
					audio.play(scriptpath .. "sounds\\s_rock.wav", 0, pan, vol)
				end -- sprite_id
			end -- obj.xy
		end -- for

		log.debug(string.format("camera moving to tile 0x%X", collisions[camera_y][camera_x]))
		if inpassible_tiles[collisions[camera_y][camera_x]] then
			if ignore_wall then
				camera_x = camera_x - x
				camera_y = camera_y - y
			end
			audio.play(scriptpath .. "sounds\\s_wall.wav", 0, pan, vol)
		else
			audio.play(scriptpath .. "sounds\\pass.wav", 0, pan, vol)
			play_tile_sound(collisions[camera_y][camera_x], pan, vol, true)
		end
	else
		log.debug("camera moving to map edge")
		camera_x = camera_x - x
		camera_y = camera_y - y
		audio.play(scriptpath .. "sounds\\s_wall.wav", 0, pan, vol)
	end
end

function set_camera_default()
	camera_x = -1
	camera_y = -1
	camera_move(0, 0, true)
end

function camera_move_left()
	camera_move(0, -1, true)
end

function camera_move_right()
	camera_move(0, 1, true)
end

function camera_move_up()
	camera_move(-1, 0, true)
end

function camera_move_down()
	camera_move(1, 0, true)
end

function camera_move_left_ignore_wall()
	camera_move(0, -1, false)
end

function camera_move_right_ignore_wall()
	camera_move(0, 1, false)
end

function camera_move_up_ignore_wall()
	camera_move(-1, 0, false)
end

function camera_move_down_ignore_wall()
	camera_move(1, 0, false)
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
elseif info.objects[current_item] == nil then
current_item = 1
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

function set_pathfind_switch()
	pathfind_switch = not pathfind_switch

	if pathfind_switch then
		tolk.output("enable special skils.")
		inpassible_tiles[18] = false
		inpassible_tiles[36] = false
		inpassible_tiles[41] = false
		inpassible_tiles[51] = false
	else
		tolk.output("disable special skils.")
		inpassible_tiles[18] = true
		inpassible_tiles[36] = true
		inpassible_tiles[41] = true
		inpassible_tiles[51] = true
	end
end

function pathfind()
local info = get_map_info()
reset_current_item_if_needed(info)
local obj = info.objects[current_item]
navigate_to(obj)
end

function read_item(item)
local x, y = get_player_xy()
local map_id = get_map_id()
local s = get_name(mapid, item)
if item.x then
s = s .. ": " .. trail.distance(x, y, item.x, item.y)
end
if item.facing then
s = s .. " facing " .. facing_to_string(item.facing)
end
log.debug("Reading item " .. s)
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

function navigate_to(obj)
local path
local width = memory.readbyteunsigned(RAM_MAP_WIDTH)
local height = memory.readbyteunsigned(RAM_MAP_HEIGHT)
local player_x, player_y = get_player_xy()
local collisions = get_map_collisions()
local objects = get_objects()
local warps = get_warps()
path = guide.find_path_to(obj, width, height, player_x, player_y, collisions, objects, warps, inpassible_tiles)

local map_id = get_map_id()
local s = get_name(mapid, obj)
if path == nil then
log.debug("No path to " .. s)
tolk.output("no path to " .. s)
else
log.debug("Path to " .. s)
new_path = trail.clean_path(path)
s = ""
for _, v in ipairs(new_path) do
s = s .. v[2] .. " " .. v[1] .. " "
end
if (obj.name == "clerk" or obj.name == "nurse") then
s = s .. "face " .. face_to_string(obj.facing)
end
tolk.output(s)
end
end -- function

inpassible_tiles = {
[7]=true;
[18] = true;
[21] = true;
[36] = true;
[38] = true;
[39] = true;
[41] = true;
[51] = true;
[144]=true;
[145]=true;
[149] = true;
[163] = false;
[165] = false;
[178] = true;
}

function rename_current()
local info = get_map_info()
reset_current_item_if_needed(info)
local id = get_map_id()
local obj_id = info.objects[current_item].id
log.debug("Rename object " .. info.objects[current_item].name)
name = inputbox.inputbox("Name object", "Enter a new name for " .. info.objects[current_item].name, info.objects[current_item].name)
if name == nil then
return
end
names[id] = names[id] or {}
if strlib.trim(name) ~= "" then
names[id][obj_id] = strlib.trim(name)
else
names[id][obj_id] = nil
end
write_names()
end

function write_names()
name.write_table("names.lua", names)
tolk.output("names saved")
end
function rename_map()
local id = get_map_id()
local obj_id = "map"
log.debug("Rename map " .. default_names[id][obj_id])
name = inputbox.inputbox("Rename map", "Enter a new name for " .. default_names[id][obj_id], default_names[id][obj_id])
if name == nil then
return
end
names[id] = names[id] or {}
if strlib.trim(name) ~= "" then
names[id][obj_id] = strlib.trim(name)
else
names[id][obj_id] = nil
end
write_names()
end

function read_mapname()
local name = get_map_name(get_map_id())
log.debug("Map name " .. name)
tolk.output(name)
end

function read_menu_item(lines, pos)
local line = math.floor(pos/20)+1
local l = lines[line]
audio.play(scriptpath .. "sounds\\menusel.wav", 0, (200 * (line - 1) / #lines) - 100, 30)
log.debug("Item name " .. l)
tolk.output(l)
if lines[line+1]:match('\xc2\xa5') then
log.debug("Item C2A5 " .. lines[line+1])
tolk.output(lines[line+1])
end
if in_options and not lines[line+1]:match("^%s*$") then
log.debug("Option name " .. lines[line+1])
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

function get_textbox()
local lines = {}
if screen.tile_lines[13] == TEXTBOX_PATTERN then
for i = 14, 17 do
table.insert(lines, screen.lines[i])
end
return lines
end
return nil
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

function face_to_string(d)
d = bit.rshift(d, 2)
if d == 0 then return "up" end
if d == 1 then return "down" end
if d == 2 then return "rigbt" end
if d == 3 then return "left" end
return "unknown"
end

function get_player_xy()
return memory.readbyte(RAM_PLAYER_X), memory.readbyte(RAM_PLAYER_Y)
end

function get_language_code()
local code = ""
for i = 0, 3 do
code = code .. string.char(memory.gbromreadbyte(0x13f+i))
end
return code
end

commands = {
[{"Y"}] = {read_coords, true};
[{"J"}] = {read_previous_item, true};
[{"K"}] = {read_current_item, true};
[{"L"}] = {read_next_item, true};
[{"P"}] = {pathfind, true};
[{"P", "shift"}] = {set_pathfind_switch, true};
[{"T"}] = {read_text, false};
[{"R"}] = {read_tiles, true};
[{"M"}] = {read_mapname, true};
[{"K", "shift"}] = {rename_current, true};
[{"M", "shift"}] = {rename_map, true};
[{"S"}] = {camera_move_left, true},
[{"F"}] = {camera_move_right, true},
[{"E"}] = {camera_move_up, true},
[{"C"}] = {camera_move_down, true},
[{"D"}] = {set_camera_default, true},
[{"S", "shift"}] = {camera_move_left_ignore_wall, true},
[{"F", "shift"}] = {camera_move_right_ignore_wall, true},
[{"E", "shift"}] = {camera_move_up_ignore_wall, true},
[{"C", "shift"}] = {camera_move_down_ignore_wall, true},
[{"H"}] = {read_enemy_health, false},
}

tolk = require "tolk"
assert(package.loadlib("audio.dll", "luaopen_audio"))()
tolk.output("ready")
names = load_names()
res, default_names = name.load_table(scriptpath .. "\\lang\\en\\" .. "default_names.lua")
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
res, language_names = name.load_table(scriptpath .. "\\lang\\" .. codemap[code] .. "\\default_names.lua")
if res == nil then language_names = {} end
end
memory.registerexec(RAM_FOOTSTEP_FUNCTION, function()
local type = memory.readbyteunsigned(RAM_STANDING_TILE)
camera_x = -1
camera_y = -1
play_tile_sound(type, 0, 30, false)
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
