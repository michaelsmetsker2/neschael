;
; neschael
; lib/memory/gameData.inc
;
; memory constants and explinations for variables stored in the game data section of zeropage $40-$FF

.SCOPE GameData
    ; gameFlags holds major flags for the state of the Game
    ; bit 0-5: unused
    ; bit 6:   drawFlag, set when data from the scroll buffer should be copied to VRAM next NMI
    ; bit 7:   renderFlag, indicates that logic is complete and vram can be updated
  gameFlags      = $40
  
    ; use buttom masks to see what is held
  btnPressed     = $41  ; New button presses this frame
  btnDown        = $42  ; All buttons currently being pressed

  nametable      = $43  ; which primary nametable to use, 0 or 1
  screenPosX     = $44  ; 16 bit, pixel position o fthe left side of the screen relative to the world start
  scrollAmount   = $46  ; signed, the ammount to scroll the screen
  
.ENDSCOPE