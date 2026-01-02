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

    ; Overflow flag is unneffected since the gameFlags check
  BVC skip_draw   ; drawFlag is clear, skip drawing
  
    ; Copy the data from the scrolling buffer to the PPU
      ; Macros are defined in data/scrolling.s
  DrawOffscreenTiles
  ;DrawOffscreenAttributes

  ; reset drawing flag
    LDA gameFlags
    AND #%10111111
    STA gameFlags

  EnableVideoOutput ; resets the ppu draw thing to 1 byte (inneficient?)
skip_draw:

  SpriteDMA          ; refresh sprites

  BIT _PPUSTATUS     ; reset VBlank flag & PPU latch
  LDA #$00           ; reset VRAM address pointer
  STA _PPUADDR       ; high byte
  STA _PPUADDR       ; low byte

set_scroll:          ; set the scroll as writes to VRAM will offest it
  LDA screenPosX
  STA _PPUSCROLL
  LDA #$00
  STA _PPUSCROLL

  EnableVideoOutput ; incase it was turned off for updating vram
  UnsetRenderFlag ; THIS IS a duplicate macro call, temp ======================

  RTI                             ; Return from interrupt 
.ENDPROC

; End of lib/isr/nmi.s
