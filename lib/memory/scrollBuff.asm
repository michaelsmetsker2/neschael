;
; neschael
; data/memory/scrollBuffer.asm
;
; Horizontal scroll buffer, this section of ram will contain uncompressed background data proccessed out of VBLANK to
; be copied to VRAM during NMI.
;


.SEGMENT "SCROLL_BUFF"

    adresses:    .res 3
    TileData:    .res 56
    attribute:   .res 8