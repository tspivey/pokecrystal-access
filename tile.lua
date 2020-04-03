module ( "tile", package.seeall )

function get_tile_sound(type, play_stair)
	if type == 0x14 or type == 0x18 then
		return "sounds\\s_grass.wav"
	elseif type == 0x12 then
		return "sounds\\s_cut.wav"
	elseif type == 0x23 then
		return "sounds\\s_ice.wav"
	elseif type == 0x24 then
		return "sounds\\s_whirl.wav"
	elseif type == 0x29 then
		return "sounds\\s_water.wav"
	elseif type == 0x33 then
		return "sounds\\s_waterfall.wav"
	elseif type > 0xA0 then
		return "sounds\\s_mad.wav"
	elseif play_stair and (type == 0x71 or type == 0x72 or type == 0x76 or type == 0x7B) then
		return "sounds\\s_stair.wav"
	elseif play_stair and type == 0x60 then
		return "sounds\\s_hole.wav"
	else
		return "sounds\\s_default.wav"
	end -- switch tile type
end

