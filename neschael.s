;
; neschael
; neshcael.s
;
; a hopefully functional platformer game for nes :)
;

  ; macro definitions used in main loop
.INCLUDE "lib/game/gameData.inc"

.IMPORT game_init
.IMPORT audio_init

.IMPORT level_init

.IMPORT play_sound_frame
.IMPORT read_joypad_1

.IMPORT update_player_sprite
.IMPORT update_player_movement

.IMPORT scroll_screen

.IMPORT lzss_decompress; TODO a test of decompression

; =================================================================================================
;  ROM (PRG) Data
; =================================================================================================
.SEGMENT "CODE"

.EXPORT main ; jumped to from reset entrypoint

  ; main entry point after the system from reset interrupt
.PROC main
    ; initialize basic systems and variables
  JSR game_init
  JSR audio_init

load_level: ; loads the level in levelId
  JSR level_init
 
  ; the main game loop, runs after each NMI
game_loop:
  ; BUG this is not constant due to conditional buffer drawing
  JSR play_sound_frame ; first thing after NMI so consistant timing


  JSR lzss_decompress ; TODO temp testing

  
  JSR read_joypad_1

  JSR update_player_movement
  JSR update_player_sprite

  JSR scroll_screen

  ; conditionally load a new level based on the levelFlag
  LDA gameFlags
  AND #%00010000 ; mask levelFlag
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

.INCLUDE "data/palettes/palettes.inc"

; Graphics tile data, used by the sprites
.SEGMENT "TILES"
.INCBIN "data/tiles/neschael.chr"

; Addresses for interrupts, must be in this order
.SEGMENT "VECTORS"
.WORD isr_nmi
.WORD isr_reset
.WORD isr_custom