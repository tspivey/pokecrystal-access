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
if trim(lines[15]) == trim(last17) then
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
if trim(screen.lines[15]) == MSG_HOW_MANY then return true end
return false
end

function output_lines(lines)
for i, line in pairs(lines) do
line = trim(line)
if line ~= "" then
tolk.output(line)
end
end
end -- output_lines

function trim(s)
return s:gsub("^%s*(.-)%s*$", "%1")
end

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
return trim(table.concat(textbox, " "))
end
local header = parse_menu_header()
local lines = get_screen().lines
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
