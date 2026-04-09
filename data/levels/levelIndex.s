;
; neschael
; data/levels/levelIndex.s
;
; lookup table of information relating to various levels
;

.EXPORT level_index_low
.EXPORT level_index_high

.IMPORT test_level_2
.IMPORT mouth_level

level_index_low:
  .BYTE <mouth_level, <test_level_2

level_index_high:
  .BYTE >mouth_level, >test_level_2