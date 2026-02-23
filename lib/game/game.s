;
; neschael
; lib/game/game.s
;
; main game loop subroutines
;

.INCLUDE "data/system/cpu.inc"
.INCLUDE "lib/game/gameData.inc"

.SEGMENT "CODE"

.IMPORT level_index
.IMPORT draw_first_screen

.EXPORT game_init
.EXPORT read_joypad_1
.EXPORT load_level

.PROC game_init

  ; TODO empty proccess
  ; levelID is already 0 so no need to set it

  RTS
.ENDPROC

.PROC load_level

  ClearOamMemory ; remove all current sprites

  ; set the level pointer to the id of levelID
  LDA levelId
  ASL A         ; *2 as 2 bytes for each address
  LDA level_index,Y
  STA levelPtr
  LDA level_index+1,Y
  STA levelPtr+1

    ; set up palletes for current level

    ; Initialize starting graphics

  ; TODO decompress the first two nametables
  JSR draw_first_screen

  RTS
.ENDPROC

.PROC read_joypad_1
    ; read button presses from joypad 1 and find what are new presses
  LDA btnDown
  TAY              ; store previousely held inputs in Y
  LDA #1
  STA _JOYPAD_1      ; latch buttons states
  STA btnDown      ; Clear pressed buttons
  LSR              ; A = 0
  STA _JOYPAD_1      ; release button latch
@loop:             ; Fill BTN_DOWN with all buttons down
  LDA _JOYPAD_1
  LSR
  ROL btnDown
  BCC @loop
  TYA
  EOR btnDown
  and btnDown
  STA btnPressed  ; Fill BTN_PRESSED with only new presses
  RTS
.ENDPROC