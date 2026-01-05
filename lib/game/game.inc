;
; neschael
; lib/game/game.inc
;
; game related macros
;

; update the render flag so the game logic will wait on NMI
.MACRO SetRenderFlag
  LDA GameData::gameFlags
  ORA #%10000000
  STA GameData::gameFlags
.ENDMACRO

.MACRO UnsetRenderFlag
  LDA GameData::gameFlags
  AND #%01111111
  STA GameData::gameFlags
.ENDMACRO