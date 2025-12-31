;   
; nechael
; lib/scrolling.s
;
; subroutines related to SCROLLING_BUFF, when scrolling thresholds are reached, it will uncompress
; and store level data while the PPU is writing. This takes leaves less logic for NMI
;

.SCOPE scrolling

.ENDSCOPE

; ==============================================================================
; These macros are to be used in NMI to draw from the buffer
; ==============================================================================

.MACRO DrawOffscreenTiles
    ; copy uncompressed nametable data to the PPU at the correct memory location

    ; TODO this causes slight inneficiency later when reseting _PPUCTRL
  LDA #%00000100        ; set to increment +32 mode
  STA _PPUCTRL

@left:
    ; set the PPU to write to the correct nametable and the top of the left column
  LDA ScrollBuffer::addrHigh
  STA _PPUADDR
  LDA ScrollBuffer::addrLowLeft
  STA _PPUADDR

  LDY #$00
@left_loop: ; loop through the whole column
  LDA ScrollBuffer::colLeft, y
  STA _PPUDATA
  INY

  CPY COLUMN_LENGTH
  BNE @left_loop
@right:
     ; set the PPU to write to the correct nametable and the top of the right column
  LDA ScrollBuffer::addrHigh
  STA _PPUADDR
  LDA ScrollBuffer::addrLowRight
  STA _PPUADDR

  LDY #$00
@right_loop: ; loop through the whole column
  LDA ScrollBuffer::colRight, y
  STA _PPUDATA
  INY

  CPY COLUMN_LENGTH
  BNE @right_loop

.ENDMACRO

.MACRO DrawOffscreenAttributes
  ; copy uncompressed attribute data to the PPU at the correct memory location

    ; derive the attribute collumn offset from the tile column offset
  LDA ScrollBuffer::addrLowLeft ; left or right, doesn't matter data is truncated
  AND #%00011111                ; keep only the tile x, 0-31
  LSR
  LSR
    
  CLC
  ADC ATTRIBUTE_TABLE_OFFSET ; add the low byte of the attribute table
  
  LDY #$00

  LDX ScrollBuffer::addrHigh ; nametable high byte
@loop:
  STX _PPUADDR

  STA _PPUADDR ; low byte offset
  CLC
  ADC #$08

  LDA ScrollBuffer::attribute, y
  STA _PPUDATA
  INY

  CPY #$08
  BNE @loop

.ENDMACRO

; End of lib/scrolling.s