;
; neschael
; data/memory/scrollBuffer.inc
;
; Horizontal scroll buffer, this section of ram will contain uncompressed background data proccessed out of VBLANK to
; be copied to VRAM during NMI.
;

  COLUMN_LENGTH          = $1C  ; the amount of tiles per the column
  ATTRIBUTE_TABLE_OFFSET = $03C0  ; PPU offset from the beggining of the nametable to the attribute data

.SEGMENT "SCROLL_BUFF"
.SCOPE ScrollBuffer

      ; addresses in the ppu to place the top tile of each column
        ; both left and right addresses are needed as the NMI doesnt know what way we are scrolling
    addrHigh:     .res 1  ; nametable address
    addrLowLeft:  .res 1  ; offset left
    addrLowRight: .res 1
    colLeft:      .res 28 ; uncompressed tile data for left column
    colRight:     .res 28
    attribute:    .res 8 ; attribute data shared by both columns, 4 tiles per attribute vertically

.ENDSCOPE