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

SPRITE_COUNT = $04 ; how sprites to allocate in oam for this

test_entity:
  .WORD update_func-1, init_func-1, remove_func-1
  .BYTE SPRITE_COUNT

  ; these functions need to be passed the memory location of their ram or index of a certain pool
.PROC update_func

  ; check if the sprite is within culling bounds
  SEC
  LDY #Slot::X_POS_OFFSET
  LDA (UpdateParams::slotPtr), Y
  SBC screenPosX
  TAX ; sprite origin pixel position X relative to screen

  INY
  LDA (UpdateParams::slotPtr), Y
  SBC screenPosX+1
  BEQ @draw ; drawable if on the same screen as the player

  ; if not on the same screen it must fall within the threshhold not to be removed 
  TXA
  CMP #$F1   ; Spawn point when scrolling left
  BCS @draw  ; still sent to draw as following columns may be on screen

  ; see if the position is on a potential spawnPoint
  TXA ; reset cpu status
  BEQ @check_fresh ; right of screen spawn position
  CMP #$F0              ; left of screen spawn position 
  BEQ @check_fresh
  ; check fresh flag to see if its been drawn before

  JMP @remove

@check_fresh:
  LDY #Slot::PARAM_2_OFFSET
  LDA (UpdateParams::slotPtr), Y
  AND #%10000000    ; mask the drawnFlag
  BEQ @done         ; entity has just been spawned

@remove:
  ; subtract the sprite ammount from the count
  SEC
  LDA spriteCount
  SBC #SPRITE_COUNT
  STA spriteCount
  ; set the entity slot to inactive
  LDA #$00
  TAY
  STA (UpdateParams::slotPtr), Y
  RTS

@draw:
  ; set the fresh flag
  LDY #Slot::PARAM_2_OFFSET
  LDA #%10000000
  ORA (UpdateParams::slotPtr), Y
  STA (UpdateParams::slotPtr), Y

  ; draw the test sprite
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

  TXA ; retreive hor pixel position from X register
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

  ; TODO defunct? maybe this should only be removed from the update function and 
  RTS
.ENDPROC

