
mapx= -1
mapy = -1
map = {}
info = {}

function read_map()
map = get_map_collisions()
info = get_map_info()
info.width = (memory.readbyteunsigned(RAM_MAP_WIDTH)*2)-1
info.height = (memory.readbyteunsigned(RAM_MAP_HEIGHT)*2)-1
end

function read_location()
if mapx<0 or mapy<0 then
tolk.output("Current focus not on map. To orient the focus to the position of the player, press shift+u.")
return
end
for o=1, #info.objects do
if info.objects[o].type~="connection" then
if info.objects[o].x==mapx and info.objects[o].y==mapy then
tolk.output(""..info.objects[o].name.." x: "..mapx.." y: "..mapy)
return
end
end
end
tolk.output(""..tile_name(map[mapy][mapx]).." x: "..mapx.." y: "..mapy)
end

function orient_to_player()
mapx, mapy = get_player_xy()
read_map()
tolk.output("oriented to player.")
end

function map_right()
read_map()
if mapx<info.width and mapx>=0 then
mapx = mapx+1
read_location()
end
end

function map_left()
read_map()
if mapx>0 then
mapx = mapx-1
read_location()
end
end

function map_up()
read_map()
if mapy>0 then
mapy = mapy-1
read_location()
end
end

function map_down()
read_map()
if mapy<info.height and mapy>=0 then
mapy = mapy+1
read_location()
end
end

function pathfind_map_view()
local path = find_path_to_xy(mapx, mapy)
if path then
speak_path(clean_path(path))
else
tolk.output("No path.")
end
end