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

sprites: ; FIXME unused
  .BYTE $00, $00, $02, $00
  .BYTE $00, $08, $02, $00
  .BYTE $08, $00, $02, $00
  .BYTE $08, $08, $02, $00

  ; this proccess should only be called from the entityHandler, The memory it inherites is in the UpdateParams scope
.PROC update_func

  tmpSpriteX    = UpdateParams::SAFE_SCRATCH    ; 16 bit, relative x position to the screen scroll
  tmpSpriteY    = UpdateParams::SAFE_SCRATCH+2

@bound_entity:
    ; calculate relative screen position
  SEC
  LDY #Slot::X_POS_OFFSET
  LDA (UpdateParams::slotPtr), Y
  SBC screenPosX
  STA tmpSpriteX ; low byte (pixel)
  TAX

  INY
  LDA (UpdateParams::slotPtr), Y
  SBC screenPosX+1
  STA tmpSpriteX+1 ; high byte (nametable)
  BEQ @draw        ; drawable if on the same screen as the player

    ; if not on the same screen it must fall within the threshhold not to be removed 
  TXA
  CMP #ENTITY_SPAWN_LEFT+1   ; Spawn point when scrolling left
  BCS @draw  ; still sent to draw as following columns may be on screen

    ; check if position is on a spawnPoint
  TXA                        ; reset cpu flags
  BEQ @check_fresh           ; entity lies on right spawnpoint
  CMP #ENTITY_SPAWN_LEFT 
  BEQ @check_fresh           ; entity lies on left spawnpoint
  JMP @remove                ; entity is to far offscreen, remove it

@check_fresh:
    ; see if the entity has just spawned in
  LDY #Slot::PARAM_2_OFFSET
  LDA (UpdateParams::slotPtr), Y
  AND #%10000000    ; mask the drawnFlag
  BNE @remove       ; entity is not new
  RTS               ; entity has just spawned, don't remove it

@remove: ; TODO relocate this labels code
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

@fill_oam:

  LDA tmpSpriteX+1
  BNE @done ; FIXME this should be changed to "next row" not rts

    ; draw the test sprite
  LDY #Slot::Y_POS_OFFSET
  LDA (UpdateParams::slotPtr), Y
  STA tmpSpriteY

  LDA tmpSpriteY
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

  ; TODO defunct? maybe this should only be removed from the update function and 
  RTS
.ENDPROC

