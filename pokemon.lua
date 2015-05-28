FLAGFILE = "flag"
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
dofile("names.lua")

assert(package.loadlib("MushReader.dll", "luaopen_audio"))()
assert(package.loadlib("audio.dll", "luaopen_audio"))()
nvda.say("ready")
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
local data = f:read()
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

function read_text()
local text = get_text()
text = text:gsub("^%s*(.-)%s*$", "%1")
if text ~= "" then
nvda.say(text)
end
end

function read_coords()
local y = memory.readbyte(0xdcb7)
local x = memory.readbyte(0xdcb8)
local mapgroup = memory.readbyte(0xdcb5)
local mapnumber = memory.readbyte(0xdcb6)
if mapnumber == 0 and mapgroup == 0 then
nvda.say("Not on a map")
return
end

nvda.say("x " .. x .. ", y " .. y)
local eventstart = memory.readword(0xd1a6)
local bank = memory.readbyte(0xd1a3)
eventstart = (bank*16384) + (eventstart - 16384)
local warps = memory.gbromreadbyte(eventstart+2)
nvda.say(warps .. " warps")
local warp_table_start = eventstart+3
for i = 1, warps do
local start = warp_table_start+(5*(i-1))
local warpy = memory.gbromreadbyte(start)
local warpx = memory.gbromreadbyte(start+1)
local warpdir = direction(x, y, warpx, warpy)
nvda.say("warp " .. i .. " " .. warpdir)
end
end

function read_signposts()
local y = memory.readbyte(0xdcb7)
local x = memory.readbyte(0xdcb8)
local eventstart = memory.readword(0xd1a6)
local bank = memory.readbyte(0xd1a3)
local mapgroup = memory.readbyte(0xdcb5)
local mapnumber = memory.readbyte(0xdcb6)
if mapnumber == 0 and mapgroup == 0 then
nvda.say("Not on a map")
return
end
names = postnames[(mapgroup*256)+mapnumber] or {}
print("bank " .. bank .. "eventstart " .. eventstart)
eventstart = (bank*16384) + (eventstart - 16384)
print("new eventstart " .. eventstart)
local warps = memory.gbromreadbyte(eventstart+2)
local ptr = eventstart + 3 -- start of warp table
ptr = ptr + (warps * 5) -- skip them
-- skip the xy triggers too
local xt = memory.gbromreadbyte(ptr)
print(xt .. " xt")
ptr = ptr + (xt * 8)+1
local signposts = memory.gbromreadbyte(ptr)
nvda.say(signposts .. " signposts")
ptr = ptr + 1
-- read out the signposts
for i = 1, signposts do
local posty = memory.gbromreadbyte(ptr)
local postx = memory.gbromreadbyte(ptr+1)
local dir = direction(x, y, postx, posty)
name = names[i] or ("signpost " .. i)
nvda.say(name .. ": " .. dir)
ptr = ptr + 5 -- point at the next one
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

counter = 0
oldtext = "" -- last text seen
while true do
emu.frameadvance()
counter = counter + 1
res, data = flagged()
if res then
if data == "coords" then
read_coords()
elseif data == "signposts" then
read_signposts()
elseif data == "tiles" then
read_tiles()
else
read_text()
end
end

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
