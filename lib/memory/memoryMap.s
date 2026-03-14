;
; neschael
; lib/memory/memoryMap.s
;

.EXPORT PLAYER_DATA

.EXPORT scrollBuffAddr
.EXPORT scrollBuffData
.EXPORT scrollBuffAttr

.EXPORT dbufTile1
.EXPORT dbufAttr1
.EXPORT dbufTile2
.EXPORT dbufAttr2

;-------------------------------------------------------------------------------
; System Memory Map
;-------------------------------------------------------------------------------
.SEGMENT "ZEROPAGE" ; first page of memory, faster I/O

; $00-$1F:      General use Subroutine Scratch Memory
  SCRATCH:      .res 32

; $20-3F:       Player data, states and animation, see lib/player/init.s      
  PLAYER_DATA:  .res 32

; $40-$FF:       Game data, see lib/player/game.inc
  GAME_DATA:    .res 128
;-------------------------------------------------------------------------------
; $0100-$01FF:  The Stack
;-------------------------------------------------------------------------------
; $0200-$02FF:  OAM Sprite Memory
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

; ???-$07FF:  General Purpose RAM