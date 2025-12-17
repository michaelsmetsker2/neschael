.SEGMENT "ZEROPAGE"
; --- scratch data $00-$1F --------------------------------------------------------
  POINTER_LOW:  .res 1   ; General purpose 16bit pointer low and high bits
  POINTER_HIGH: .res 1
  SCRATCH: .res 30

; --- player data $20-2F ----------------------------------------------------------
  PLAYER_DATA: .res 16    ; includes player states and animations, see lib/player.s


; --- game data $30-$FF -----------------------------------------------------------
      ; gameFlags holds major flags for the state of the Game
      ; bit 0-6: unused
      ; bit 7:   renderFlag, indivates that state updates are complete and vram can be updated
  GAME_FLAGS:   .res 1
  
      ; use buttom masks to see what is held
  BTN_PRESSED:  .res 1  ; New button presses this frame
  BTN_DOWN:     .res 1  ; All buttons currently being pressed