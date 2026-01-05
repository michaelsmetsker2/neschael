;
; neschael
; lib/memory/scrollBuffer.inc
; 
; locations and definitions of memory constants that are allocated in the SCROLLBUFF segment 
;


.SCOPE ScrollBuffer

      ; addresses in the ppu to place the top tile of each column
        ; both left and right addresses are needed as the NMI doesnt know what way we are scrolling
    addrHigh      = $0300  ; nametable address
    addrLowLeft   = $0301  ; offset left
    addrLowRight  = $0302
    colLeft       = $0303 ; uncompressed tile data for left column
    colRight      = $031F
    attribute     = $033B ; attribute data shared by both columns, 4 tiles per attribute vertically

.ENDSCOPE