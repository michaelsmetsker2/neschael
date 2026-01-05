;
; neschael
; lib/game/game.inc
;
; game related macros
;

; update the render flag so the game logic will wait on NMI
.MACRO SetRenderFlag
  LDA gameFlags
  ORA #%10000000
  STA gameFlags
.ENDMACRO

.MACRO UnsetRenderFlag
  LDA gameFlags
  AND #%01111111
  STA gameFlags
.ENDMACRO