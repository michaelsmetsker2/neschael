;
; neschael
; neshcael.s
;
; a hopefully functional platformer game for nes :)
;

  ; macro definitions used in main loop
.INCLUDE "data/system/ppu.inc"
.INCLUDE "data/system/apu.inc"
.INCLUDE "lib/game/gameData.inc"

.IMPORT scroll_screen
.IMPORT game_init
.IMPORT read_joypad_1

.IMPORT player_init
.IMPORT update_player_sprite
.IMPORT update_player_movement

; =================================================================================================
;  ROM (PRG) Data
; =================================================================================================
.SEGMENT "CODE"

.EXPORT main ; jumped to from reset entrypoint

  ; main entry point after the syste from reset interrupt
.PROC main
    ; initialize basic systems and enable visuals
  JSR game_init
  JSR player_init
  EnableVideoOutput
  EnableAudioOutput

  LDA #%10111111 ;Duty 10, Volume F
  STA _SQ1_VOL
 
  LDA #$C9
  STA $4002
  LDA #$00
  STA $4003

  ; the main game loop
game_loop:
  JSR read_joypad_1

  JSR update_player_movement
  JSR update_player_sprite

  JSR scroll_screen

  SetRenderFlag
@wait_for_render:       ; Loop until NMI has finished for the current frame
  BIT gameFlags
  BMI @wait_for_render

  JMP game_loop
  RTS                   ; shouldn't ever get called
.ENDPROC

; Interrupt service routines
.IMPORT isr_reset
.IMPORT isr_nmi
.IMPORT isr_custom

; Graphics tile data, used by the sprites
.SEGMENT "TILES"
.INCBIN "data/tiles/neschael.chr"

; Addresses for interrupts, must be in this order
.SEGMENT "VECTORS"
.WORD isr_nmi
.WORD isr_reset
.WORD isr_custom
