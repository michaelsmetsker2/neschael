;
; neschael
; lib/game/levelData.inc
;
; offsets and information about the level data format
;

ATTRIBUTE_INDEX_OFFSET = $02
LEVEL_SIZE_OFFSET = $08
POSITION_OFFSET = $06 ; x and y player starting posisions

; TODO make this formally
; level data format
; each level should include
; starting x and y positions
; length of the level, in screens
; pointers to tile attribute and pointer data
; music?
