.SEGMENT "ZEROPAGE"
; --- scratch data $00-$1F --------------------------------------------------------
  SCRATCH: .res 30
  POINTER_LOW:  .res 1   ; General purpose 16bit pointer low and high bits
  POINTER_HIGH: .res 1

; --- player data $20-2F ----------------------------------------------------------
  PLAYER_DATA: .res 32    ; includes player states and animations, see lib/player.s


; --- game data $40-$FF -----------------------------------------------------------
      ; gameFlags holds major flags for the state of the Game
      ; bit 0-6: unused
      ; bit 7:   renderFlag, indivates that state updates are complete and vram can be updated
  gameFlags:   .res 1
  
      ; use buttom masks to see what is held
  btnPressed:   .res 1  ; New button presses this frame
  btnDown:      .res 1  ; All buttons currently being pressed

  nametable:    .res 1  ; which primary nametable to use, 0 or 1
  columnNumber: .res 1  ; which column of level data to draw
  scroll:       .res 1  ; pixel position offset of the left side of the screen 