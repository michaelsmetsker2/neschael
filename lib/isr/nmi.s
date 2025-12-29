;
; first_nes
; lib/isr/nmi.s
;
; non maskable interrupt, this is called during vblank and is where graphis are updated
;

.PROC ISR_NMI
    ; return early if game logic hasn't been updated yet (drop frame)
  BIT gameFlags
  BPL drop_frame       
  
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




  SpriteDMA          ; refresh sprites

  BIT _PPUSTATUS     ; reset VBlank flag & PPU latch
  LDA #$00           ; reset VRAM address pointer
  STA _PPUADDR       ; high byte
  STA _PPUADDR       ; low byte

set_scroll:          ; set the scroll as writes to VRAM will offest it
  LDA scroll
  STA _PPUSCROLL
  LDA #$00
  STA _PPUSCROLL

  EnableVideoOutput ; incase it was turned off for updating vram
  UnsetRenderFlag

drop_frame:
  RTI                             ; Return from interrupt 
.ENDPROC

; End of lib/isr/nmi.s
