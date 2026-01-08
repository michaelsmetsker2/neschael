;metatiles layout
;;;;;;;;;;;
; 00 ; 01 ;
;;;;;;;;;;;
; 02 ; 03 ;
;;;;;;;;;;;

.EXPORT metatiles

.ENUM CollisionType ; TODO find a good file for this
  empty = 0
  solid = 1
  hazard = 2
  bounceH = 3
  bounceV = 4
  ; special?
  ; slope l/r?
.ENDENUM


metatiles:
  .WORD test_block_1a, test_block_1b, test_sky___1a

test_block_1a:
  .BYTE $01, $02, $11, $12 ; tile data
                           ; two bytes (4 nibbles) collision data

test_block_1b:
  .BYTE $00, $00, $02, $02
test_sky___1a:
  .BYTE $00, $03, $03, $00