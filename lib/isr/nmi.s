;
; first_nes
; lib/isr/nmi.s
;
; non maskable interrupt, this is called during vblank and is where graphis are updated
;

.PROC isr_nmi

  BIT gameFlags
  BMI @continue ; return early if logic hasn't finished this frame (drop frame)
  RTI
@continue:
  BVC @skip_draw           ; if drawFlag is clear, skip drawing

  DrawOffscreenTiles       ; copy buffer data to PPU. see lib/scrolling.s
  DrawOffscreenAttributes
  ResetDrawFlag

@skip_draw:
  SpriteDMA         ; refresh sprites
  ResetPPUAddress
  SetScroll         ; sets the scroll as vram writes offset it
  EnableVideoOutput ; incase it was turned off for updating vram

  UnsetRenderFlag
  RTI                             ; Return from interrupt 
.ENDPROC

; End of lib/isr/nmi.s