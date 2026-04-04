;
; neschael
; lib/game/entities/entityHelpers.s
;
; helper routines and macros to be used in multiple entities
;

.INCLUDE "lib/game/entities/entityData.inc"
.INCLUDE "lib/game/gameData.inc"

.EXPORT populate_slot

.PROC populate_slot

    ; add the entity ID to the pool and set state to active
  LDA #%10000000
  ORA InitParams::entityId
  LDY #$00
  STA (InitParams::slotPtr), Y

@populate_x_position:
    ; muliply metatile by 16 to get pixel offset 
  LDA InitParams::metatileIndex
  LSR A
  LSR A
  LSR A
  LSR A
    ; add to screen scroll to get world position store in slot
  CLC
  ADC screenPosX
  LDY #Slot::X_POS_OFFSET
  STA (InitParams::slotPtr), Y ; store low byte
  LDA screenPosX+1
  BCC :+
  ADC #$00                     ; conditionally add carry
  :
  INY
  STA (InitParams::slotPtr), Y ; store high byte

@populate_y_position:
  LDX #$00
  LDA (InitParams::entityData, X)
  AND #%11110000 ; mask just the Y position
  INY
  ; TODO add offset for hud and overscan
  STA (InitParams::slotPtr), Y ; store the position

@populate_params: ; copy the param byte to the slot
  DEY ; decrement Y from 3 to 2, the offset of params in level data
  LDA (InitParams::entityData), Y
  LDY #Slot::PARAM_OFFSET
  STA (InitParams::slotPtr), Y

  RTS
.ENDPROC