;
; neschael
; data/levels/levelData.inc
;
; offsets and information about the level data format
;

LEVEL_SIZE_OFFSET = $06
POSITION_OFFSET = $04 ; x and y player starting posisions

; TODO make this formally
; level data format
; each level should include
; starting x and y positions
; length of the level, in screens
; pointers to tile attribute and pointer data
; music?