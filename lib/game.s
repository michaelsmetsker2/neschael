;
; neschael
; lib/game.s
;
; write some stuff here
;

.SCOPE Game

  .PROC init
      ; Initialize rendering and starting graphics
    JSR load_palette_data
    JSR load_background_data  

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

.ENDSCOPE

; update the render flag so the game logic will wait on NMI
.MACRO SetRenderFlag
  LDA #%10000000
  ORA gameFlags
  STA gameFlags
.ENDMACRO

.MACRO UnsetRenderFlag
  LDA #%01111111
  AND gameFlags
  STA gameFlags
.ENDMACRO

; End of neschael.s