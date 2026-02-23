;
; neschael
; lib/memory/memoryMap.s
;

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
.SEGMENT "SCROLL_BUFF"
  addresses:   .res 3
  tileData:    .res 52
  attribute:   .res 7
;-------------------------------------------------------------------------------
; $033E-Undetermined ; TODO decompress bufferse for tile and attribute data
  dbufTile1:   .res 208



; ???-$07FF:  General Purpose RAM