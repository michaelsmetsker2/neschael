;
; neschael
; lib/game/gameData.inc
;
; memory constants and explinations for variables stored in the game data section of zeropage $40-$FF and
; macros concerning them
;

.IMPORTZP GAME_DATA

  ; gameFlags holds major flags for the state of the Game
  ; bit 0-3: unused
  ; bit 4:   levelFlag, set when a new level needs to be loaded
  ; bit 5:   audioFlag, set when audio is enabled
  ; bit 6:   drawFlag, set when data from the scroll buffer should be copied to VRAM next NMI
  ; bit 7:   renderFlag, indicates that logic is complete and vram can be updated
gameFlags      = GAME_DATA

  ; use buttom masks to see what is held
btnPressed     = GAME_DATA + 1  ; New button presses this frame
btnDown        = GAME_DATA + 2  ; All buttons currently being pressed

nametable      = GAME_DATA + 3  ; which primary nametable to use, 0 or 1
screenPosX     = GAME_DATA + 4  ; 16 bit, pixel position of the left side of the screen relative to the world start
scrollAmount   = GAME_DATA + 6  ; signed, the ammount to scroll the screen by the end of the frame

levelId        = GAME_DATA + 7  ; level to load, corolates to index of the level_index lookup table
levelPtr       = GAME_DATA + 8  ; 16 bit, points to the level data of the current level

spriteCount    = GAME_DATA + 10 ; ammount of unreserved sprites used by entities, determines whether to spawn more

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