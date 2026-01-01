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
; $00-$1F:      Subroutine Scratch Memory
;-------------------------------------------------------------------------------
; $20-$FF:      Reserved for high I/O variables, see data/zeropage.inc
;-------------------------------------------------------------------------------
; $0100-$01FF:  The Stack
;-------------------------------------------------------------------------------
; $0200-$02FF:  OAM Sprite Memory
;-------------------------------------------------------------------------------
; $0300-$034D:  Horizontal scroll buffer, see data/scrollBuffer.inc
;-------------------------------------------------------------------------------
; $034E-$07FF:  General Purpose RAM
;-------------------------------------------------------------------------------
.INCLUDE "data/zeropage.inc"     ; a more detailed map of the zeropage, and constants
.INCLUDE "data/scrollBuff.inc"

; =================================================================================================
;  ROM (PRG) Data
; =================================================================================================

.SEGMENT "CODE"

  ; system related subroutines constants and macros
.INCLUDE "lib/system/ppu.inc"  ; only constants 
.INCLUDE "lib/system/ppu.s"
.INCLUDE "lib/system/cpu.s"
.INCLUDE "lib/system/apu.s"

  ; main libraries
.INCLUDE "lib/game.s"
.INCLUDE "lib/player.s"
.INCLUDE "lib/scrolling.s"

  ; main entry point after the syste from reset interrupt
.PROC main
    ; initialize basic systems and enable visuals
  JSR Game::init
  JSR Player::init
  EnableVideoOutput

  ; the main game loop
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

; Interrupt service routines
.INCLUDE "lib/isr/reset.s"
.INCLUDE "lib/isr/nmi.s"
.INCLUDE "lib/isr/custom.s"

; Temporary includes ===========================================================================
.INCLUDE "data/background/canvas.asm"
.INCLUDE "data/background/testLevel.inc"

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
  ; Addresses for interrupts, must be in this order
.WORD ISR_NMI
.WORD isr_reset
.WORD isr_custom

; End of neschael.s