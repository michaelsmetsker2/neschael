;
; neschael
; neshcael.s
;
; a hopefully functional platformer game for nes :)
;

  ; macro definitions used in main loop
.INCLUDE "data/system/ppu.inc"
.INCLUDE "lib/game/gameData.inc"

.IMPORT game_init
.IMPORT audio_init
.IMPORT player_init

.IMPORT play_sound_frame
.IMPORT read_joypad_1

.IMPORT update_player_sprite
.IMPORT update_player_movement

.IMPORT scroll_screen

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
  JSR audio_init
  EnableVideoOutput
 
  ; the main game loop, triggers after each NMI
game_loop:
  JSR play_sound_frame ; first thing after NMI so consistant timing

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