;
; neschael
; lib/game/game.s
;
; main game loop subroutines
;

.INCLUDE "data/memory/zeropage.inc"
.INCLUDE "data/system/cpu.inc"

.IMPORT draw_first_screen

.SEGMENT "CODE"

.EXPORT game_init
.EXPORT read_joypad_1

.PROC game_init
    ; Initialize rendering and starting graphics
  JSR draw_first_screen

.ENDPROC

.PROC read_joypad_1
    ; read button presses from joypad 1 and find what are new presses
  LDA btnDown
  tay              ; store previousely held inputs in Y
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