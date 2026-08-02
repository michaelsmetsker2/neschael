;
; neschael
; lib/player/abilities/abilityHandler.s
;
; handles cycling and executing the correct charge abilities
;

.INCLUDE "lib/game/gameData.inc"
.INCLUDE "data/system/cpu.inc"

.IMPORTZP SCRATCH

.IMPORT vertical_boost
.IMPORT glide_init

.EXPORT cycle_abilities
.EXPORT execute_ability_up
.EXPORT execute_ability_down

ability_up_table_low:
  .BYTE <vertical_boost, <glide_init, <glide_init
ability_up_table_high:
  .BYTE >vertical_boost, >glide_init, >glide_init

ability_down_table_low:
ability_down_table_high:

  ; masks for the unlockFlags to see if an ability is unlocked or not
ability_masks_up:
  .BYTE %00000001, %00000010, %00000100
ability_masks_down:
  .BYTE %00010000, %00100000, %01000000

  ; cycles to a new unlocked ability if start or select are pressed
.PROC cycle_abilities
  LDA btnPressed
  AND #_BUTTON_START
  BEQ @check_select
  
@cycle_ability_down:
  ; increment and mask so wrap on 3
  LDA currentAbilityDown
  CLC
  ADC #$01
  AND #%00000011
  ; check if ability is unlocked
  TAY
  LDA ability_masks_down, Y
  AND unlockFlags
  BNE :+
  ;store zero if ability is not unlocked
  LDY #$00
:
  STY currentAbilityDown

@check_select:
  LDA btnPressed
  AND #_BUTTON_SELECT
  BNE :+
  RTS
:

@cycle_ability_up:
  ; increment and mask so wrap on 3
  LDA currentAbilityUp
  CLC
  ADC #$01
  AND #%00000011
  ; check if ability is unlocked
  TAY
  LDA ability_masks_up, Y
  AND unlockFlags
  BNE :+
  ; store zero if ability is not unlocked
  LDY #$00
:
  STY currentAbilityUp

  RTS
.ENDPROC

.PROC execute_ability_up
  ; pointer to the proccess of the correct ability
  abilityPtr = SCRATCH

  LDY currentAbilityUp
  LDA ability_up_table_low, Y
  STA abilityPtr
  LDA ability_up_table_high, Y
  STA abilityPtr+1

  JMP (abilityPtr)
.ENDPROC

.PROC execute_ability_down
  ; TODO implement
  RTS
.ENDPROC