## Introduction

The Pokecrystal access project is a set of scripts which provide access to Pokémon Crystal, the famous GameBoy game, for people using a screen reader.
These scripts are designed to work with the VBA-ReRecording GameBoy emulator.
  
## Requirements and installation
1. Download the GameBoy emulator VBA Rerecording
http://vba-rerecording.googlecode.com/files/vba-v24m-svn-r480.7z

1. Get an English pokémon crystal rom.

1. After you have these, extract and run VBA.

1. Go to the Options menu, Head-Up Display, Show Speed, None (alt-o, h, s, enter)
Without this, NVDA reads the title bar every time it changes.
1. Optional but recommended: turn down the sound. In the Options menu, navigate to Audio, Volume (alt o, a, v)

## Starting the game
Each time you run VBA, you'll need to load the rom.
You can do this from the open dialog, or load a recent rom after you've opened it once.

Once the rom is loaded, load the lua script (tools, lua, New Lua script window).
From there, load pokemon.lua, press run. It should say ready, alt tab out and back in again

## Keys
Make sure num lock is off while playing the game, or the keys won't work.

* Standard gameBoy keys: z/x are a/b, enter/backspace start/select and arrows.
* j, k and l - previous, current and next item
* shift k - rename current item
* m - read current map name
* shift M - rename current map
* t - read text on screen, if any
* p - pathfind. This tries to find a path between you and the object selected, or as close as it can get.
* Shift + P - Toggle special skils when using pathfind. For example surf
* y - read current position
* h - read enemy health if in a battle
* r - read the surrounding tiles

### Camera
* s - move the camera left, stopping at walls
* f - move the camera right, stopping at walls
* e - move the camera up, stopping at walls
* c - move the camera down, stopping at walls
* d - move the camera to the player's position
* add shift to s/f/e/c to move the camera, ignoring walls

## Notes
Non-english roms are supported. These include: French, German, Italian, Japanese and Spanish.

## Contact information
If you find a bug, or want to contact me about these scripts, my contact information is below.
for bugs, please send a save state with instructions on how to reproduce the issue from it. You can save a named one with control shift s in the game.

Project homepage: http://allinaccess.com/pca/
Author Email: Tyler Spivey <tspivey@pcdesk.net>
Twitter: @tspivey
Source code: https://github.com/tspivey/pokecrystal-access
