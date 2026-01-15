;
; neschael
; data/tiles/metatiles.s
;
; contains deffinitions for metatiles and their collision data
;

;metatiles layout
;;;;;;;;;;;
; 00 ; 01 ;
;;;;;;;;;;;
; 02 ; 03 ;
;;;;;;;;;;; collision takes this same format

.EXPORT metatiles

metatiles:
  .WORD test_block_1a, test_sky___1a, test_block_1b, test_block_1c

test_block_1a:
  .BYTE $01, $02, $11, $12 ; tile data
  .BYTE $01, $01, $01, $01 ; collision data

test_sky___1a:
  .BYTE $00, $00, $00, $00
  .BYTE $00, $00, $00, $00

test_block_1b:
  .BYTE $03, $00, $03, $00
  .BYTE $01, $00, $01, $00

test_block_1c:
  .BYTE $00, $00, $03, $03
  .BYTE $00, $00, $01, $01