;
; neschael
; data/levels/levelIndex.s
;
; lookup table of information relating to various levels
;

.EXPORT level_index

.IMPORT test_level
.IMPORT test_level_2

level_index:
  .WORD test_level_2, test_level