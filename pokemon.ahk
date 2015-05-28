#ifwinactive ahk_exe vba.exe
f1::
fileAppend, , %a_scriptdir%\flag
return
f2::
fileAppend, coords, %a_scriptdir%\flag
return
f3::
fileAppend, signposts, %a_scriptdir%\flag
return
f4::
fileAppend, tiles, %a_scriptdir%\flag
return

^+l::
send !tln
winWaitActive Lua Script
control, editPaste, %a_scriptdir%\pokemon.lua, Edit1
controlclick, button2
send {esc}
return

#ifwinactive
