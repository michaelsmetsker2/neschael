;
; first_nes
; lib/isr/nmi.s
;
; non maskable interrupt, this is called during vblank and is where graphis are updated
;

.PROC ISR_NMI
  BIT gameFlags 
  BPL drop_frame       ; return early if game logic hasn't been updated yet (drop frame)
  
  INC scroll ; temp, increments the horizontal scroll by one pixel ===========================

swap_check:      ; check to see if the scroll has reached the end of the nametables, if so swap them
  LDA scroll
  BNE check_done ; load nametable
swap:
  LDA nametable
  EOR #$01       ; flip
  STA nametable  
check_done:

  NewColumnCheck:
    LDA scroll
    AND #%00000111            ; throw away higher bits to check for multiple of 8
    BNE NewColumnCheckDone    ; done if lower bits != 0
    JSR draw_column           ; if lower bits = 0, draw a new column
    
    lda columnNumber
    clc
    adc #$01             ; go to next column
    and #%01111111       ; only 128 columns of data, throw away top bit to wrap
    sta columnNumber
  NewColumnCheckDone:

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

  LDA scroll
  STA _PPUSCROLL        ; write the horizontal scroll count register

  LDA #$00         ; no vertical scrolling
  STA _PPUSCROLL

  EnableVideoOutput ; incase it was turned off for updating vram
  UnsetRenderFlag

drop_frame:
  RTI                             ; Return from interrupt 
.ENDPROC

; End of lib/isr/nmi.s
