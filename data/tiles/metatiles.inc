;metatiles layout
;;;;;;;;;;;
; 00 ; 01 ;
;;;;;;;;;;;
; 02 ; 03 ;
;;;;;;;;;;;

metatiles:
  .WORD test_block_1a, test_block_1b, test_sky___1a

test_block_1a:
  .BYTE $01, $02, $11, $12
test_block_1b:
  .BYTE $00, $00, $02, $02
test_sky___1a:
  .BYTE $00, $03, $03, $00