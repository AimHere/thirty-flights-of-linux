Linux port by David Sinclair
------------------------------

The resulting binaries ought to work with version 24 of
Thirty Flights of Loving and version 11 of Gravity Bone,
both from Blendo Games. If they work with other versions,
then that's a nice bonus.

Various little bits of code here and there have been fiddled around
with in order to make this run on Linux. Therefore any bugs and/or
other inadequacies present in this code might well be my fault and not 
those of any of the previous authors, though they'll retain their
copyrights in the code, where appropriate.

And, to reiterate, this code is based on the work of:

  Quake II, by id Software (idsoftware.com)
  KMQuake II, by Knightmare (markshan.com/knightmare)
  Lazarus, by David Hyde and Mad Dog
  Thirty Flights of Loving and Gravity Bone,
  both from Brendan Chung (blendogames.com)


And uses:
  OGG Vorbis
  ZLib
  Libpng
  Libjpeg
  SDL

David Sinclair, 2013.

-----

This ought to create binary files 'tfol-sdl' and 'kmq2gamei386.so'.

To use, place 'tfol-sdl' in the top level directory,
and place 'kmq2gamei386.so' in the 'baseq2' directory, along
with the .pk3 files and the config file, and any directories
full of resources that came with your game.

Your directory should look something like this:

TFOL
|
-- tfol-sdl
|
-- baseq2
   |
   -- kmq2gamei386.so 
   |
   -- kmq2config.cfg
   |
   -- pak0.pk3
   |
   -- pak1.pk3
   |
   -- pak2.pk3


-----

Dependencies:

This should require 32-bit dev versions of 

libasound2
libGL (libgl1-*-dev:i386 on Debian/Ubuntu should provide this)
libGLU (libglu1-*-dev:i386 should be what you want)
libjpeg62
libxxf86dga
libxxf86vm
libX11
libpng
libsvga

-----

Known bugs:

Camera seems to jump to the side when coming from the menu

Mouse doesn't work properly in fullscreen

Loading and/or Saving doesn't work properly

Lockup when entering Anita's apartment in TFOL

Shadows don't look good


TODO

Fullscreen and Resolution changes are pretty horrible at the moment

Find people to test this on

Cut down on indirection with the RW_IN_foo_fp functions

Use the system SDL libraries, instead of bundling them

Build and run a 64-bit binary
