;
; neschael
; data/entities/testEntity.s
;  
; temp test entity definition and implementation for building the entity system
;

.INCLUDE "lib/game/entities/entityData.inc"
.INCLUDE "lib/game/gameData.inc"

.EXPORT test_entity

.IMPORT populate_slot

test_entity:
  .WORD update_func-1, init_func-1, remove_func-1
  .BYTE $04 ; how sprites to allocate in oam for this

  ; these functions need to be passed the memory location of their ram or index of a certain pool
.PROC update_func

  ; find the x position of the test sprite
  SEC
  LDY #Slot::X_POS_OFFSET
  LDA (UpdateParams::slotPtr), Y
  SBC screenPosX
  TAX

  INY
  LDA (UpdateParams::slotPtr), Y
  SBC screenPosX+1
  BNE @done  

  ; write test sprite data to oam
  LDY #Slot::Y_POS_OFFSET
  LDA (UpdateParams::slotPtr), Y

  LDY UpdateParams::oamOffset
  STA unreservedOam, Y
  INY

  LDA $0205
  STA unreservedOam, Y
  INY

  LDA $0206
  STA unreservedOam, Y
  INY

  TXA
  STA unreservedOam, Y
  INY
  STY UpdateParams::oamOffset
  
  @done:
  RTS
.ENDPROC

.PROC init_func

  JSR populate_slot

  RTS
.ENDPROC

.PROC remove_func
  ; decrement the sprite count
  RTS
.ENDPROC

