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

tile_names = {
[0] = "open";
[7] = "wall";
[18] = "tree";
[21] = "small tree";
[24] = "grass";
[36] = "whirlpool";
[39] = "obstacle";
[41] = "water";
[51] = "waterfall";
[113] = "door";
[145] = "PokéMon Friend PokéMon Magazine";
[147] = "pc";
[148] = "radio";
[149] = "town map";
[150] = "Pokémon Merchandising";
[151] = "television";
[157] = "mirror image";
[159] = "incense";
}

object_tiles = {
[18] = true;
[21] = true;
[36 ] = true;
[96] = true;
[147] = true;
}


function tile_name(id)
if tile_names[id] then
return tile_names[id]
end
return id
end

--Returns an object table for a specified tile id, if that id matches a given tile object.
function object(tile_id, x, y)
if object_tiles[tile_id] then
return {name = tile_name(tile_id), x=x, y=y, id = tile_name(tile_id), type="object"}
end
return nil
end