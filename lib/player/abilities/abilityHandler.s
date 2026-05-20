;
; neschael
; lib/player/abilities/abilityHandler.s
;
; handles cycling and executing the correct charge abilities
;

.IMPORT vertical_boost


.EXPORT cycle_abilities
.EXPORT execute_ability_up
.EXPORT execute_ability_down

.INCLUDE "lib/game/gameData.inc"
.INCLUDE "data/system/cpu.inc"

  ; a new unlocked ability if start or select are pressed
.PROC cycle_abilities
  LDA btnPressed
  AND #_BUTTON_START
  BEQ @check_select
  
  ; TODO cycle

@check_select:
  LDA btnDown
  AND #_BUTTON_SELECT
  BNE :+
  RTS
:

  ; TODO cycle

  RTS
.ENDPROC

.PROC execute_ability_up

  JMP vertical_boost
  RTS
.ENDPROC

.PROC execute_ability_down
  RTS
.ENDPROC