1. Get vba rerecording. I used this one:
http://vba-rerecording.googlecode.com/files/vba-v24m-svn-r480.7z

2. Get a pokemon crystal rom.

3. Extract vba rerecording, and rename the exe to vba.exe (or edit the script).

4. Run pokemon.ahk. It needs autohotkey.

5. Run vba.exe.
6. Go to the Options menu, Head-Up Display, Show Speed, None (alt-o, h, s, enter)
Without this, NVDA reads the title bar every time it changes.
7. Optional, turn down the sound. Options, Audio, Volume (alt o, a, v)
That's the configuration done. Now load the rom (File, Open),
Then load the lua script (tools, lua, New Lua script window).
From there, load pokemon.lua, press run. It should say ready, alt tab out and back in again

The script assigns:
f1 - read on screen text, if any.
f2 - read warps
f3 - read signposts
