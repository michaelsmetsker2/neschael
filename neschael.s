;
; neschael
; neshcael.s
;
; a hopefully functional platformer game for nes
;

; iNES File header, used by NES emulators
.SEGMENT "HEADER"
.INCLUDE "data/header/header.inc"

;-------------------------------------------------------------------------------
; System Memory Map
;-------------------------------------------------------------------------------
; $00-$1F:    Subroutine Scratch Memory
;             Volatile Memory used for parameters, return values, and temporary
;             / scratch data.
; $20-$FF:    The Remainder of the zero page is reserved for high I/O
;             variables, see data/zeropage.inc
;-------------------------------------------------------------------------------
; $100-$1FF:  The Stack
;-------------------------------------------------------------------------------
; $200-$2FF:  OAM Sprite Memory
;-------------------------------------------------------------------------------
; $300-$7FF:  General Purpose RAM
;-------------------------------------------------------------------------------
.INCLUDE "data/zeropage.inc"

; =================================================================================================
;  ROM (PRG) Data
; =================================================================================================
.SEGMENT "CODE"

  ; system related subroutines constants and macros
.INCLUDE "lib/system/cpu.s"
.INCLUDE "lib/system/apu.s"
.INCLUDE "lib/system/ppu.inc"  ; only constants 
.INCLUDE "lib/system/ppu.s"

.INCLUDE "lib/game.s"

; Interrupt service routines
.INCLUDE "lib/isr/reset.s"
.INCLUDE "lib/isr/nmi.s"
.INCLUDE "lib/isr/custom.s"

.INCLUDE "lib/player.s"

.PROC main
  JSR Game::init
  JSR Player::init
  EnableVideoOutput

game_loop:
  JSR Game::read_joypad_1
  JSR Player::Movement::update
  JSR Player::Sprite::update


  SetRenderFlag
@wait_for_render:       ; Loop until NMI has finished for the current frame
  BIT gameFlags
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
.INCLUDE "data/sprites/player.inc"

; Graphics tile data, used by the sprites
.SEGMENT "TILES"
.INCBIN "data/tiles/neschael.chr"

.SEGMENT "VECTORS"
; Addresses must be in this order
.WORD ISR_NMI
.WORD isr_reset
.WORD isr_custom

; End of neschael.s