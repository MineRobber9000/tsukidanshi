# Tsukidanshi Spec

The point of this document is to serve as a hub for all of my thoughts regarding
how Tsukidanshi is going to be implemented.

This spec is also super in flux and nothing is necessarily set in stone quite yet.

## Memory Map

|Start|End|Use|
|-|-|-|
|0000|3FFF|ROM Bank 1 (or first half of cartridge)|
|4000|7FFF|ROM Bank *n* (or second half of cartridge)|
|8000|9FFF|VRAM|
|A000|BFFF|Cartridge RAM/storage|
|C000|EFFF|Variable RAM|
|F000|F0FF|Sprite Memory|
|F100|F15F|Palettes|
|F160|F17F|RNG State|
|F180|F1FF|Reserved|
|F200|F2FF|Music Wave Data Buffer|
|F300|F3FF|SFX Wave Data Buffer|
|F400|FEFF|Reserved|
|FF00|FFFF|Hardware Registers|

Eventually, the plan is for cartridges to be able be configured for banked execution or unbanked execution. If banked execution is desired, then each bank must fit in 16 KB or less when compiled to bytecode; however, cartridges are not limited in number of banks when done in this manner (with the tradeoff that banks cannot interact with each other outside of sharing variable space). If banked execution is not desired, then the space available to the first bank doubles, at the cost of the 32 KB limit being a hard limit. However, for the time being, only the unbanked execution mode is available.

While code *can* read ROM, it's extremely discouraged to do so; Different Lua VMs can (and will) compile bytecode into different representations, so the contents of any one ROM location cannot be ensured. (Theoretically, one could examine the chunk header to determine what environment they're running on.)

### VRAM

|Start|End|Use|
|-|-|-|
|8000|8FFF|Character memory|
|9000|9FFF|64x64 Tilemap|

Characters are stored in 2bpp format like in the GameBoy.

```
Tile:                                     Image:

.33333..                     .33333.. -> 01111100 -> $7C
22...22.                                 01111100 -> $7C
11...11.                     22...22. -> 00000000 -> $00
2222222. <-- digits                      11000110 -> $C6
33...33.     represent       11...11. -> 11000110 -> $C6
22...22.     color                       00000000 -> $00
11...11.     numbers         2222222. -> 00000000 -> $00
........                                 11111110 -> $FE
                             33...33. -> 11000110 -> $C6
                                         11000110 -> $C6
                             22...22. -> 00000000 -> $00
                                         11000110 -> $C6
                             11...11. -> 11000110 -> $C6
                                         00000000 -> $00
                             ........ -> 00000000 -> $00
                                         00000000 -> $00
```

The tilemap is stored left to right, top to bottom; one byte is one tile.

### Cartridge RAM/storage

The configuration of this section depends on how the cartridge is configured. Namely, the cartridge lists a number of on-board storage banks, and then (assuming the number of on-board storage banks isn't 0) fills anywhere from none to all of them with arbitrary data. Banks that are not otherwise filled with data are available for the game to write data into, which will be saved in the game's cartridge file.

### Variable RAM

RAM is accessed by way of the cartridge defining global variable names (local variables are illegal in Tsukidanshi code) as referring to certain locations in the Tsukidanshi's memory (any address will work, but only certain addresses can be written to) and having a certain type (string, integer, float, or table of one of the other three). All variables co-exist in memory, and can, if placed poorly, overwrite/corrupt each other.

Variables that do not fit any of the types can only be used as a constant. The first time they are assigned to, their value becomes frozen and cannot be set again (attempting to set an already-set constant will result in an error). However, constants can be of any size and type.

### Hardware Page (FXXX)

The FXXX page is reserved for system functions.

#### Sprite Memory

The sprite memory in the Tsukidanshi ranges from F000 to F0FF, with each sprite taking 4 bytes (ergo, 64 sprites can be defined at any one time). The format is:

|Offset|Means|
|-|-|
|*n\*4*|Sprite Y position|
|*n\*4*+1|Sprite X position|
|*n\*4*+2|Sprite ID|
|*n\*4*+3|Sprite Flags|

The sprite flags are (bits in the order 76543210):

|Bit|Means|
|-|-|
|7|Horizontal flip|
|6|Vertical flip|
|5|Double width|
|4|Double height|
|3|Subtract width from X/Subtract height from Y|
|2-0|Palette number|

Bits 7 and 6 are obvious. If bit 5 is set, the sprite will be 2 tiles wide by 1 tile tall. If bit 4 is set, the sprite will be 1 tile wide by 2 tiles tall. (What happens when they are both set is left as an exercise to the reader. :P) When a sprite is comprised of more than 1 tile, the other tiles are the tiles following in memory (i.e; a sprite with tile ID 4 that is 2 tiles wide will have tile ID 5 as its right side). There are 8 four-color palettes to choose from, stored at F100-F15F.

If bit 3 is set, then the width of the sprite is subtracted from the sprite's X position before rendering, which can be used to scroll a sprite to or from the left; if bit 3 is cleared, then the height of the sprite is subtracted from the sprite's Y position before rendering, allowing for scrolls to or from the bottom of the screen.

Color 0 is always treated as transparent in sprites.

#### Palette

|Offset|Means|
|-|-|
|(*n*\*12)+0|Color 0 Red|
|(*n*\*12)+1|Color 0 Green|
|(*n*\*12)+2|Color 0 Blue|
|(*n*\*12)+3|Color 1 Red|
|(*n*\*12)+4|Color 1 Green|
|(*n*\*12)+5|Color 1 Blue|
|(*n*\*12)+6|Color 2 Red|
|(*n*\*12)+7|Color 2 Green|
|(*n*\*12)+8|Color 2 Blue|
|(*n*\*12)+9|Color 3 Red|
|(*n*\*12)+10|Color 3 Green|
|(*n*\*12)+11|Color 3 Blue|

#### Hardware Registers

The hardware registers at FFXX are special in that they tend to perform some kind of function, as opposed to merely being memory addresses the user can manipulate.

|Start|Length (in bytes)|Use/Meaning|
|-|-|-|
|FF00|1|Controller input|
|FF01|1|Background scroll X|
|FF02|1|Background scroll Y|
|FF03|1|Screen control register|
|FF04|8|RNG output|
|FF0C|1|Sound control register|
|FF0D|1|Music wave data length|
|FF0E|1|SFX wave data length|
|FF0F|240|Reserved|
|FFFC|1|Memory bank|
|FFFD|1|Code bank|
|FFFE|1|Frame count hook|
|FFFF|1|CPU control flags|

Controller input is exposed as a bitfield (7 MSB, 0 LSB):

```
7 6 5 4 3 2 1 0
| | | | | | | \_ Up
| | | | | | \___ Down
| | | | | \_____ Left
| | | | \_______ Right
| | | \_________ A
| | \___________ B
| \_____________ Select
\_______________ Start
```

Background scroll X and Y are in pixels. The screen control register is a bitfield:

```
Bit 7 - Screen enable (1=on, 0=off)
Bit 6 - Background scroll X + 256
Bit 5 - Background scroll Y + 256
Bit 4 - Background scroll X + 128
Bit 3 - Background scroll Y + 128
Bits 2-0 - Background palette
```

The RNG output in FF04 can be read as an int64 or a double-precision float. The
RNG is a XoShiRo256** generator with its state in F160-F17F.

The sound control register is a bitfield:

```
Bit 7 - Music channel on/off
Bit 6 - SFX channel on/off
Bit 4 - Reserved
Bit 3 - Reserved
Bit 2 - Reserved
Bit 1 - Write SFX channel data at the end of this frame
Bit 0 - Write music channel data at the end of this frame
```

Changes in the register take effect after the game code processes the frame (for instance, setting bits 0 and 7 will cause the sound processor to write the music channel data from the music channel write buffer at F2xx into the internal buffer and start playing it). When the channel runs out of audio to play, it will stop automatically and its respective bit will be unset. Games can use this to benchmark if they aren't writing audio fast enough. Note that if you stop a channel (by clearing its respective on/off bit), all queued data for that channel will be lost.

FF0D and FF0E control the length of the data to be written for their respective channels. For instance, if FF0D=B8, and bit 0 of FF0C is set, 184 bytes of sample data will be copied from the write buffer.

The memory bank register swaps out the memory at A000-BFFF. 256 banks are available for a total of 2MB cartridge storage (shared between persistent memory and raw data).

The code bank register swaps out the second code bank when the cartridge has code banks. Writes and reads to this register from a cartridge without code banks are no-ops, and writes to this register from code in the second bank will result in an error.

Setting the frame count hook register to a non-zero value will cause the
`FrameCount` function to be called every however many frames.

The CPU control flags are a bitfield:
```
Bit 7 - Halt flag (halts all execution)
Bits 6-0 - Reserved
```

If the halt flag is set, then after the current hook is done running, no more
code will run.
