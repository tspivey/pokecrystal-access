#ifwinactive ahk_exe vba.exe
f1::flagwrite("")
f2::flagwrite("coords")
f3::flagwrite("signposts")
f4::flagwrite("tiles")

^+l::
send !tln
winWaitActive Lua Script
control, editPaste, %a_scriptdir%\pokemon.lua, Edit1
controlclick, button2
send {esc}
return

#ifwinactive

flagwrite(x) {
fileAppend, %x%, %a_scriptdir%\flag
}
