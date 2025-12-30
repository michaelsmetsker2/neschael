;
; neschael
; data/scrollBuffer.inc
;
; Horizontal scroll buffer, this section of ram will contain uncompressed background data proccessed out of VBLANK to
; be copied to VRAM during NMI.
;

.SEGMENT "SCROLL_BUFF"
.SCOPE ScrollBuffer

  COLUMN_LENGTH = #$1E

		; addresses in the ppu to place the top tile of each column
			; both left and right addresses are needed as the NMI doesnt know what way we are scrolling
  addrHigh:     .res 1  ; nametable address
  addrLowLeft:  .res 1  ; offset left
  addrLowRight: .res 1
  colLeft:      .res 30 ; uncompressed tile data for left column
  colRight:     .res 30
  attribute:    .res 15 ; attribute data shared by both columns

.ENDSCOPE

; End of data/scrollBuff.inc