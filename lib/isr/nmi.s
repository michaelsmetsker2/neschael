;
; first_nes
; lib/isr/nmi.s
;
; non maskable interrupt, this is called during vblank and is where graphis are updated
;
.SEGMENT "CODE"

.INCLUDE "data/system/ppu.inc"

.INCLUDE "lib/game/gameData.inc"
.INCLUDE "lib/scrolling/scrolling.inc"
.INCLUDE "lib/hud/hud.inc"

.IMPORTZP HUD_BUFFER

.EXPORT isr_nmi

.PROC isr_nmi

  BIT gameFlags
  BMI @continue ; return early if logic hasn't finished this frame (drop frame)
  RTI
@continue:

  UpdateHud                ; redraws active elements of the hud

  BVC @skip_draw           ; if drawFlag is clear, skip drawing new tiles

  DrawOffscreenTiles       ; copy buffer data to PPU. see lib/scrolling/scrolling.inc
  DrawOffscreenAttributes 
  ResetDrawFlag

@skip_draw:
  SpriteDMA         ; refresh decayed oam sprites
  ResetPPUAddress

    ; start drawing on nametable 0 with no scroll for statur bar
  ResetScroll
  EnableVideoOutput

    ; loop until sprite zero flag is clear
@wait_sprite_0_clear:
  LDA _PPUSTATUS
  AND #%01000000
  BNE @wait_sprite_0_clear

    ; loop untill sprite zero hit
@wait_sprite_0:
  LDA _PPUSTATUS
  AND #%01000000
  BEQ @wait_sprite_0

  SetScroll        ; sets the scroll to the correct position for the rest of the screen
  LDA #%10010000   ; resume drawing on the correct nametable
  ORA nametable
  STA _PPUCTRL

  UnsetRenderFlag
  RTI              ; Return from interrupt 
.ENDPROC