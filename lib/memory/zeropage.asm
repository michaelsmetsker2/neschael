;
; neschael
; data/memory/zeropage.inc
;
; definition and allocation of memory stored int the first $FF bytes of RAM
;

.SEGMENT "ZEROPAGE"
; --- general use scratch data $00-$1F --------------------------------------------
  SCRATCH:      .res 32

; --- player data $20-3F ----------------------------------------------------------
  PLAYER_DATA:  .res 32    ; includes player states and animations, see lib/player/init.s

; --- game data $40-$FF -----------------------------------------------------------
  GAME_DATA:    .res 128