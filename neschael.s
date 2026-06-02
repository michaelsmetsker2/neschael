;
; neschael
; neshcael.s
;
; a hopefully functional platformer game for nes :)
; built with make on wsl

  ; macro definitions used in main loop
.INCLUDE "lib/game/gameData.inc"

.IMPORT game_init

.IMPORT level_init

.IMPORT play_sound_frame
.IMPORT read_joypad_1
.IMPORT cycle_abilities

.IMPORT update_player_movement
.IMPORT update_camera

.IMPORT scroll_screen

.IMPORT clear_oam
.IMPORT update_player_sprite
.IMPORT update_entities

.IMPORT buffer_hud

;  start of ROM (PRG) data
.SEGMENT "CODE"

.EXPORT main ; jumped to from reset entrypoint

  ; main entry point after the system from reset interrupt
.PROC main
  JSR game_init

load_level: ; loads the level in levelId
  JSR level_init
 
  ; the main game loop, runs after each NMI
game_loop:

    ; first thing after NMI (and zero hit) so timing is consistant
  JSR play_sound_frame
  
  JSR read_joypad_1
  JSR cycle_abilities

  JSR update_player_movement
  JSR update_camera

  JSR scroll_screen
  
  JSR clear_oam
  JSR update_player_sprite
  JSR update_entities

  JSR buffer_hud

    ; conditionally load a new level based on the levelFlag
  LDA gameFlags
  AND #%00010000        ; mask levelFlag
  BNE load_level
  
  SetRenderFlag
@wait_for_render:       ; Loop until NMI has finished for the current frame
  BIT gameFlags
  BMI @wait_for_render

  JMP game_loop
  RTS                   ; should never get called
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