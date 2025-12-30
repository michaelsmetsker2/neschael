;   
; nechael
; lib/scrolling.s
;
; subroutines related to SCROLLING_BUFF, when scrolling thresholds are reached, it will uncompress
; and store level data while the PPU is writing. This takes leaves less logic for NMI
;

.SCOPE scrolling


.ENDSCOPE

  ; These are macros to be used in NMI, subroutines have more overhead
.MACRO drawOffscreenTiles
    ; copy uncompressed nametable data to the PPU at the correct memory location

    ; this causes slight inneficiency later when reseting _PPUCTRL
  LDA #%00000100        ; set to increment +32 mode
  STA _PPUCTRL

@left:
    ; set the PPU to write to the correct nametable and the top of the left column
  LDA ScrollBuffer::addrHigh
  STA _PPUADDR
  LDA SCrollBuffer::addrLowLeft
  STA _PPUADDR

  LDY #$00
@left_loop: ; loop through the whole column
  LDA ScrollBuffer::colLeft,Y
  STA _PPUDATA
  INY

  CPY COLUMN_LENGTH
  BNE @left_loop
@right:
     ; set the PPU to write to the correct nametable and the top of the right column
  LDA ScrollBuffer::addrHigh
  STA _PPUADDR
  LDA SCrollBuffer::addrLowRight
  STA _PPUADDR

  LDY #$00
@left_loop: ; loop through the whole column
  LDA ScrollBuffer::colRight,Y
  STA _PPUDATA
  INY

  CPY COLUMN_LENGTH
  BNE @right_loop

.ENDMACRO

.MACRO drawOffscreenAttributes
    ; copy uncompressed attribute data to the PPU at the correct memory location

.ENDMACRO

; End of lib/scrolling.s