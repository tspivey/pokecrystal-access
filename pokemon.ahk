#ifwinactive ahk_exe vba.exe
f1::flagwrite("previous")
f2::flagwrite("current")
f3::flagwrite("next")
f4::flagwrite("text")
f5::flagwrite("tiles")
f6::flagwrite("coords")
/::flagwrite("pathfind")
+f2::
inputBox, name, Name Item
if ErrorLevel {
return
}
flagwrite("name " . name)
return
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
