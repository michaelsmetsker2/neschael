;
; first_nes
; lib/isr/nmi.s
;
; non maskable interrupt, this is called during vblank and is where graphis are updated
;
.PROC ISR_NMI
  BIT gameFlags 
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

  
  INC scroll
swap_check:
  LDA scroll
  BNE check_done ; load nametable
swap:
  LDA nametable
  EOR #$01 ; flip
  STA nametable  

check_done:
  STA _PPUSCROLL ; increment horizontal scroll
  LDA #$00
  STA _PPUSCROLL ; no verticle scrolling





    ;macro will be outdated with the introduction of nametable swapping
  ;EnableVideoOutput ; incase it was turned off for updating vram

  ;;This is the PPU clean up section, so rendering the next frame starts properly.
  LDA #%10010000   ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
  ORA nametable    ; select correct nametable for bit 0
  STA _PPUCTRL
  
  LDA #%00011110   ; enable sprites, enable background, no clipping on left side
  STA _PPUMASK


  UnsetRenderFlag

drop_frame:
  RTI                             ; Return from interrupt 
.ENDPROC

; End of lib/isr/nmi.s
