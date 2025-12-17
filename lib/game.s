;
; neschael
; lib/game.s
;
; write some stuff here
;

.SCOPE Game

  ; === Initialize rendering and starting graphics ===
  .PROC init
    JSR load_palette_data
    JSR load_sprite_data
    JSR load_background_data  

  .ENDPROC

  ; === read button presses from joypad 1 and find what are new presses ===
  .PROC read_joypad_1
    LDA BTN_DOWN
    tay              ; store previousely held inputs in Y
    LDA #1
    STA _JOYPAD_1      ; latch buttons states
    STA BTN_DOWN     ; Clear pressed buttons
    LSR              ; A = 0
    STA _JOYPAD_1      ; release button latch
  @loop:             ; Fill BTN_DOWN with all buttons down
    LDA _JOYPAD_1
    LSR
    ROL BTN_DOWN
    BCC @loop
    TYA
    EOR BTN_DOWN
    and BTN_DOWN
    STA BTN_PRESSED  ; Fill BTN_PRESSED with only new presses
    RTS
  .ENDPROC

.ENDSCOPE

; === update the render flag so the game logic will wait on NMI ===
.MACRO SetRenderFlag
  LDA #%10000000
  ORA GAME_FLAGS
  STA GAME_FLAGS
.ENDMACRO

.MACRO UnsetRenderFlag
  LDA #%01111111
  AND GAME_FLAGS
  STA GAME_FLAGS
.ENDMACRO

; End of neschael.s