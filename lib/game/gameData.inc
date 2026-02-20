;
; neschael
; lib/game/gameData.inc
;
; memory constants and explinations for variables stored in the game data section of zeropage $40-$FF and
; macros concerning them
;

  ; gameFlags holds major flags for the state of the Game
  ; bit 0-4: unused
  ; bit 5:   audioFlag, set when audio is enabled
  ; bit 6:   drawFlag, set when data from the scroll buffer should be copied to VRAM next NMI
  ; bit 7:   renderFlag, indicates that logic is complete and vram can be updated
gameFlags      = $40

  ; use buttom masks to see what is held
btnPressed     = $41  ; New button presses this frame
btnDown        = $42  ; All buttons currently being pressed

nametable      = $43  ; which primary nametable to use, 0 or 1
screenPosX     = $44  ; 16 bit, pixel position of the left side of the screen relative to the world start
scrollAmount   = $46  ; signed, the ammount to scroll the screen by the end of the frame

levelId        = $47  ; element number of the current level in the level_index lookup table
levelPtr       = $48  ; 16 bit, points to the level data of the current level
; TODO gameState ; for main menu, game, credits?

; update the render flag so the game logic will wait on NMI
.MACRO SetRenderFlag
  LDA gameFlags
  ORA #%10000000
  STA gameFlags
.ENDMACRO

.MACRO UnsetRenderFlag
  LDA gameFlags
  AND #%01111111
  STA gameFlags
.ENDMACRO