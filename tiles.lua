--This file contains tile ids and related functions.

inpassible_tiles = {
[7]=true;
[18] = true;
[21] = true;
[41] = true;
[144] = true;
[145]=true;
[149] = true;
[178] = true;
}

tiles = {
[0] = {name="open", type="terrain", object=false};
[7] = {name="wall", type="terrain", object=false};
[18] = {name="tree", type="terrain", object=true};
[21] = {name="small tree", type="terrain", object=true};
[24] = {name="grass", type="terrain", object=false};
[36] = {name="whirlpool", type="terrain", object=true};
[39] = {name="obstacle", type="terrain", object=true};
[51] = {name="waterfall", type="terrain", object=false};
[113] = {name="door", type="terrain", object=false};
[122] = {name="stairs", type="terrain", object=false};
[144] = {name="counter", type="terrain", object=false};
[145] = {name="PokéMon Friend PokéMon Magazine", type="terrain", object=false};
[147] = {name="pc", type="object", object=true};
[148] = {name="radio", type="terrain", object=false};
[149] = {name="town map", type="terrain", object=false};
[150] = {name="Pokémon Merchandising", type="terrain", object=false};
[151] = {name="television", type="terrain", object=false};
[157] = {name="mirror image", type="terrain", object=false};
[159] = {name="incense", type="terrain", object=false};
}



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