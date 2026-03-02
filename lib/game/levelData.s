;
; neschael
; lib/game/levelData.s
;
; lookup table of information relating to various levels
;

.EXPORT level_index

.IMPORT test_level

level_index:
  .WORD test_level

; TODO make this formally
; level data format
; each level should include
; starting x and y positions
; length of the level, in screens
; pointers to tile attribute and pointer data
; music?

; End of data/levelData.inc