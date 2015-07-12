function get_map_gn()
local mapgroup = memory.readbyte(RAM_MAP_GROUP)
local mapnumber = memory.readbyte(RAM_MAP_NUMBER)
return mapgroup, mapnumber
end

function get_map_id()
local group, number = get_map_gn()
return group*256+number
end

function get_map_name(mapid)
if names[mapid] ~= nil and names[mapid]["map"] ~= nil then
return names[mapid]["map"]
elseif language_names[mapid] ~= nil and language_names[mapid].map ~= nil then
return language_names[mapid].map
elseif default_names[mapid] ~= nil and default_names[mapid].map ~= nil then
return default_names[mapid].map
else
return ""
end
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
local obj = {x=x-4, y=y-4, name=name, type="object", id="object_" .. i, facing=facing}
obj.name = get_name(mapid, obj)
table.insert(results, obj)
end
end
ptr = ptr + 16
end
local collisions = get_map_collisions()
for y = 0, #collisions do
for x = 0, #collisions[0] do
table.insert(results, object(collisions[y][x], x, y))
end
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


-- Returns true or false indicating whether we're on a map or not.
function on_map()
local mapgroup, mapnumber = get_map_gn()
if (mapnumber == 0 and mapgroup == 0) or memory.readbyte(RAM_IN_BATTLE) ~= 0 then
return false
else
return true
end
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


function get_player_xy()
return memory.readbyte(RAM_PLAYER_X), memory.readbyte(RAM_PLAYER_Y)
end
