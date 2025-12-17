;
; neschael
; neshcael.s
;
; a hopefully functional platformer game for nes
;

; iNES File header, used by NES emulators
.SEGMENT "HEADER"
.INCLUDE "data/header/header.inc"

; =================================================================================================
;  ZeroPage, first 256 bytes of RAM for quick access
; =================================================================================================

.SEGMENT "ZEROPAGE"
  ; RAM VARIABLES

      ; gameFlags holds major flags for the state of the Game
      ; bit 0-6: unused
      ; bit 7:   renderFlag, indivates that state updates are complete and vram can be updated
  GAME_FLAGS:   .res 1  

  POINTER_LOW:  .res 1   ; General purpose 16bit pointer low and high bits
  POINTER_HIGH: .res 1

      ; use buttom masks to see what is held
  BTN_PRESSED:  .res 1  ; New button presses this frame
  BTN_DOWN:     .res 1  ; All buttons currently being pressed

  playerX:      .res 1  ; Player X position
  playerY:      .res 1  ; Player Y position
  playerSpeedX: .res 1  ; Player speed in x direction
  playerSpeedY: .res 1  ; Player speed in y direction

; this stands for rocket propelled grenade
; =================================================================================================
;  ROM (RPG) Data
; =================================================================================================
.SEGMENT "CODE"

  ; system related subroutines constants and macros
.INCLUDE "lib/system/cpu.s"
.INCLUDE "lib/system/apu.s"
.INCLUDE "lib/system/ppu.inc"  ; only constants 
.INCLUDE "lib/system/ppu.s"

.include "lib/game.s"

; Interrupt service routines
.INCLUDE "lib/isr/reset.s"
.INCLUDE "lib/isr/nmi.s"
.INCLUDE "lib/isr/custom.s"

.PROC main
  JSR Game::init
  EnableVideoOutput

game_loop:
  JSR Game::read_joypad_1

  ; Move LEFT
  LDA BTN_DOWN
  AND #_BUTTON_LEFT
  BEQ @skip_left
  JSR MoveLuigiLeft
@skip_left:

  ; Move RIGHT
  LDA BTN_DOWN
  AND #_BUTTON_RIGHT
  BEQ @skip_right
  JSR MoveLuigiRight
@skip_right:



  SetRenderFlag
@wait_for_render:       ; Loop until NMI has finished for the current frame
  BIT GAME_FLAGS
  BMI @wait_for_render
  JMP game_loop
  RTS                   ; shouldn't ever get called
.ENDPROC  

; Temporary includes
.INCLUDE "lib/sprite/basic_movement.s"
.INCLUDE "data/background/background.inc" ; this will be redone when scrolling is a thing

; Palette data
.SEGMENT "PALETTE"
.INCLUDE "data/palette/example.inc"

; Sprite data
.SEGMENT "SPRITES"
.INCLUDE "data/sprites/small_luigi.inc"

; Graphics tile data, used by the sprites
.SEGMENT "TILES"
.INCBIN "data/tiles/mario.chr"

.SEGMENT "VECTORS"
; Addresses must be in this order
.WORD ISR_NMI
.WORD isr_reset
.WORD isr_custom

; End of neschael.s