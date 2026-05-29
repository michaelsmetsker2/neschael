neschael aka munch aka InJest
this is an NES game written in 6502 compiled in ca65
has not been tested on real hardware

tools used:
  [yy-chr.net](https://www.romhacking.net/utilities/958/)
  [Tiled](https://www.mapeditor.org/)
  NEXXT studio
  mesen
  vscode

#### level creation instructions
(this proccess is easier on linux)

1. run `make tools` to build level creations scripts

2. New tiles are made by directly editing data/tiles/neschael.chr in [yychr.net](https://www.romhacking.net/utilities/958/) (my prefered way) or in NEXXT studio

3. New metatiles can be assembled in NEXXT studio by opening the session data/tiles/raw/meta.nss and saved by with:
 File > Export > Tileset as image > Full tileset, and overwriting data/tiles/raw/metas.bmp
 AND
 File > Canvas > Save as ASM, overwrite data/tiles/raw/metas.asm
  ​
 To asign collision to metatiles open tools/tiled/neschael.tiled-project as a project in tiled
 in metas.tsx, edit the cutom tile properties to the corospoding collision values in lib/player/collision/collision.inc inside the CollisionType ENUM
 ​
 Finally run the /tools/generateMetatiles script **from** the tools folder

4. levels can be assembled in same tiled project using the `metas` tilesets for the tiles layer, the `atributes` tileset for the attrubute layer, and `numbers` tileset for the spawn layer
  ​
  levels are exported to tools/tiled/exports and should be named export.csv
  then run /tools/formatCanvas script **from** the tools folder

5. the output can be found in tools/level.s, change LEVELNAME to the name of your choice. This can be used to overwrite an existing level or be added into data/levels/levelIndex.s the first level in the index is loaded at launch