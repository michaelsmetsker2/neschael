;
; neschael
; lib/memory/memoryMap.s
;

.EXPORT PLAYER_DATA

.EXPORT reservedShadowOam
.EXPORT shadowOam

.EXPORT scrollBuffAddr
.EXPORT scrollBuffData
.EXPORT scrollBuffAttr

.EXPORT dbufTile1
.EXPORT dbufAttr1
.EXPORT dbufTile2
.EXPORT dbufAttr2

.EXPORT entityPool

;-------------------------------------------------------------------------------
; System Memory Map
;-------------------------------------------------------------------------------
.SEGMENT "ZEROPAGE" ; first page of memory, faster I/O

; $00-$1F:      General use Subroutine Scratch Memory
  SCRATCH:      .res 32

; $20-3F:       Player data, states and animation, see lib/player/init.s      
  PLAYER_DATA:  .res 32

; $40-$FF:       Game data, see lib/player/game.inc
  GAME_DATA:    .res 192
;-------------------------------------------------------------------------------
; $0100-$01FF:  The Stack
;-------------------------------------------------------------------------------
; $0200-$02FF:  OAM Sprite Memory
.SEGMENT "SHADOW_OAM"
  reservedShadowOam: .res 16
  shadowOam:         .res 240
;-------------------------------------------------------------------------------
; $0300-$033D:  Horizontal scroll buffer, see lib/scrolling/scrolling.inc
.SEGMENT "SCROLL_BUFF" ; used to align after OAM
  scrollBuffAddr:  .res 3   ; ppu addreses to draw to during NMI
  scrollBuffData:  .res 48  ; tile data to be drawn
  scrollBuffAttr:  .res 6   ; address data to be drawn
;-------------------------------------------------------------------------------
; $033E-Undetermined ; TODO decompress buffers for tile and attribute data
  dbufTile1:   .res 192
  dbufAttr1:   .res 48
  dbufTile2:   .res 192
  dbufAttr2:   .res 48

; ???-$06FF:  General Purpose RAM

  ; $0700 - Undetermined ; TODO
.SEGMENT "ENTITY_POOL"
  entityPool:  .res 256