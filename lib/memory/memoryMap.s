;
; neschael
; lib/memory/memoryMap.s
;
; memory map, allocates and creates labels for all chunks of memory used
;

.EXPORT SCRATCH
.EXPORT PLAYER_DATA
.EXPORT GAME_DATA
.EXPORT HUD_BUFFER
.EXPORT AUDIO_DATA

.EXPORT shadowOam

.EXPORT scrollBuffAddr
.EXPORT scrollBuffData
.EXPORT scrollBuffAttr

.EXPORT dbufTile1
.EXPORT dbufAttr1
.EXPORT dbufTile2
.EXPORT dbufAttr2

.EXPORT entStream1
.EXPORT entStream2

.EXPORT entityPool

;-------------------------------------------------------------------------------
; Zero Page
;-------------------------------------------------------------------------------
.SEGMENT "ZEROPAGE" ; first page of memory, faster I/O
; $00-$1F:      General use Subroutine Scratch Memory
  SCRATCH:      .RES 32

; $20-$3F:      Player data, states and animation, see lib/player/init.s      
  PLAYER_DATA:  .RES 32

; $40-$BE :     Game data, see lib/player/game.inc
  GAME_DATA:    .RES 127

; $BF-$D7:      Tile data to be drawn in the hud during vblank
  HUD_BUFFER:   .RES 25

; $D8-$FF:      Audio data and streams
  AUDIO_DATA:   .RES 40

;-------------------------------------------------------------------------------
; $0100-$01FF:  The Stack
;-------------------------------------------------------------------------------
; $0200-$02FF:  OAM Sprite Memory
.SEGMENT "SHADOW_OAM"
  shadowOam:     .RES 256
;-------------------------------------------------------------------------------
; $0300-$033D:  Horizontal scroll buffer, see lib/scrolling/scrolling.inc
.SEGMENT "SCROLL_BUFF" ; used to align after OAM
  scrollBuffAddr:  .RES 3   ; ppu addreses to draw to during NMI
  scrollBuffData:  .RES 48  ; tile data to be drawn
  scrollBuffAttr:  .RES 6   ; address data to be drawn
;-------------------------------------------------------------------------------
; $033E-$051C: decompressed draw buffers for tile, attribute, and entity data See. lib/decompression/decompress.s
  dbufTile1:   .RES 192
  dbufAttr1:   .RES 48
  dbufEnt1:    .RES 2
  entStream1:  .RES 2  ; memory address of the entity spawn streams that corrolate to the backgrounds.
  
  dbufTile2:   .RES 192
  dbufAttr2:   .RES 48
  dbufEnt2:    .RES 2 
  entStream2:  .RES 2
;-------------------------------------------------------------------------------
; $051D-$06FF:  General Purpose RAM

; $0700 - Undetermined ; TODO all 256 bytes are not needed, this should be all within one page of memory
.SEGMENT "ENTITY_POOL"
  entityPool:  .RES 256