;
; first_nes
; lib/isr/nmi.s
;
; non maskable interrupt, this is called during vblank and is where graphis are updated
;
.PROC ISR_NMI
  BIT GAME_FLAGS
  BPL drop_frame       ; return early if game logic hasn't been updated yet (drop frame)
  
    ; Refresh DRAM-stored sprite data before it decays.
  LDA     #$00
  STA     _OAMADDR               ; Set the low byte (00) of the RAM address
  LDA     #$02
  STA     _OAMDMA                ; set the high byte (02) of the RAM address
                                  ; This automatically starts the transfer

  BIT _PPUSTATUS     ; reset VBlank flag & PPU latch
  LDA #$00
  STA _PPUADDR       ; high byte of VRAM address
  STA _PPUADDR       ; low byte of VRAM address

  UnsetRenderFlag

drop_frame:
  RTI                             ; Return from interrupt 
.ENDPROC

; End of lib/isr/nmi.s
