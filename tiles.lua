--This file contains tile ids and related functions.

tiles = {
[0] = {name="open", type="terrain", object=false, passable=true, mod_passable=true};
[7] = {name="wall", type="terrain", object=false, passable=false, mod_passable=false};
[18] = {name="tree", type="terrain", object=true, passable=false, mod_passable=false};
[21] = {name="small tree", type="terrain", object=true, passable=false, mod_passable=false};
[24] = {name="grass", type="terrain", object=false, passable=true, mod_passable=true};
[35] = {name="ice", type="terrain", object=false, passable=true, mod_passable=true};
[36] = {name="whirlpool", type="terrain", object=true, passable=true, mod_passable=true};
[39] = {name="obstacle", type="terrain", object=true, passable=false, mod_passable=false};
[41] = {name="water", type="terrain", object=false, passable=false, mod_passable=false};
[51] = {name="waterfall", type="terrain", object=false, passable=false, mod_passable=false};
[113] = {name="door", type="terrain", object=false, passable=false, mod_passable=false};
[118] = {name="gate", type="terrain", object=false, passable=true, mod_passable=true};
[122] = {name="stairs", type="terrain", object=false, passable=false, mod_passable=false};
[126] = {name="gate", type="terrain", object=false, passable=true, mod_passable=true};
[144] = {name="counter", type="terrain", object=false, passable=false, mod_passable=false};
[145] = {name="PokéMon Friend PokéMon Magazine", type="terrain", object=false, passable=false, mod_passable=false};
[147] = {name="pc", type="object", object=true, passable=false, mod_passable=false};
[148] = {name="radio", type="terrain", object=false, passable=false, mod_passable=false};
[149] = {name="town map", type="terrain", object=true, passable=false, mod_passable=false};
[150] = {name="Pokémon Merchandising", type="terrain", object=false, passable=false, mod_passable=false};
[151] = {name="television", type="terrain", object=true, passable=false, mod_passable=false};
[157] = {name="mirror image", type="terrain", object=false, passable=false, mod_passable=false};
[159] = {name="incense", type="terrain", object=false, passable=false, mod_passable=false};
[178] = {name="obstacle", type="terrain", object=false, passable=false, mod_passable=false};
[255] = {name="map boundary", type="terrain", object=false, passable=false, mod_passable=false};
}

--Returns whether a tile can be passed through or not.
function passable(id)
if tiles[id] then
return tiles[id].mod_passable
end
return false
end

--Returns a table of impassable tiles.
function impassable_tiles()
temp = {}
for k, v in pairs(tiles) do
if not passable(k) then
temp[k] = true
end
end
return temp
end

function tile_name(id)
if tiles[id] then
return tiles[id].name
end
return id
end

function tile_type(id)
if tiles[id] then
return tiles[id].type
end
end

--Returns an object table for a specified tile id, if that id matches a given tile object.
function object(tile_id, x, y)
if tiles[tile_id] then
if tiles[tile_id].object then
return {name = tile_name(tile_id), x=x, y=y, id = tile_name(tile_id), type=tile_type(tile_id)}
end
end
return nil
end

function tile_sound(id)
test = audio.play(scriptpath .. "sounds\\"..tile_name(id)..".wav", 0, 0, 30)
if test == 0 then
audio.play(scriptpath .. "sounds\\open.wav", 0, 0, 30)
end
print(type(test))
end