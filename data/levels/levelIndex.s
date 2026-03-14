;
; neschael
; data/levels/levelIndex.s
;
; lookup table of information relating to various levels
;

.EXPORT level_index

.IMPORT test_level

level_index:
  .WORD test_level, test_level