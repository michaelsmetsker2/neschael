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

  tmpSpriteX    = UpdateParams::SAFE_SCRATCH    ; 16 bit, relative x position to the screen scroll
  tmpSpriteY    = UpdateParams::SAFE_SCRATCH+2
  tmpSpriteAttr = UpdateParams::SAFE_SCRATCH+3
  tmpSpriteTile = UpdateParams::SAFE_SCRATCH+4

SPRITE_COUNT = $04 ; how sprites to allocate in oam for this

test_entity:
  .WORD update_func-1, init_func-1, remove_func-1
  .BYTE SPRITE_COUNT

  ; this proccess should only be called from the entityHandler, The memory it inherites is in the UpdateParams scope
.PROC update_func

    ; populate sprite values
  LDY #Slot::Y_POS_OFFSET
  LDA (UpdateParams::slotPtr), y
  STA tmpSpriteY

  LDA $0205
  STA tmpSpriteTile
  LDA $0206
  STA tmpSpriteAttr

    ; calculate relative screen position, subtract the screen scroll from the entities position
  LDY #Slot::X_POS_OFFSET
  LDA (UpdateParams::slotPtr), Y
  SEC
  SBC screenPosX
  STA tmpSpriteX ; low byte (pixel)
  TAX            ; store for easy access

  INY ; increments to the high byte
  LDA (UpdateParams::slotPtr), Y
  SBC screenPosX+1
  STA tmpSpriteX+1 ; high byte (nametable)



@check_valid: ; see if the sprite has moved far enough to be removed

  BEQ @valid ; always valid if on the same screen as the player

    ; the sprite must fall within the spawn point threshold to not be removed
  LDA tmpSpriteX
  CMP #ENTITY_SPAWN_LEFT+1   ; Spawn point when scrolling left
  BCS @valid 

    ; check if position is on a spawnPoint
  TXA                        ; = LDA tmpSpriteX, resets cpu flags
  BEQ @check_fresh           ; entity lies on right spawnpoint
  CMP #ENTITY_SPAWN_LEFT 
  BEQ @check_fresh           ; entity lies on left spawnpoint
  JMP remove_func            ; entity is to far offscreen, remove it

@check_fresh:
    ; see if the entity has just spawned in
  LDY #Slot::PARAM_2_OFFSET
  LDA (UpdateParams::slotPtr), Y
  AND #%10000000    ; mask the drawnFlag
  BEQ :+
  JMP remove_func       ; entity is not new, remove it
:
  RTS               ; entity has just spawned, don't remove it, but don't draw either

@valid:

    ; set the fresh flag
  LDY #Slot::PARAM_2_OFFSET
  LDA #%10000000
  ORA (UpdateParams::slotPtr), Y
  STA (UpdateParams::slotPtr), Y

  JSR draw

    ; increment y position to the next row
  CLC
  LDA tmpSpriteY
  ADC #$08
  STA tmpSpriteY

  JSR draw

    ; return Y position to original
  LDY #Slot::Y_POS_OFFSET
  LDA (UpdateParams::slotPtr), y
  STA tmpSpriteY

    ; increment x position to the next column
  CLC
  LDA tmpSpriteX
  ADC #$08
  STA tmpSpriteX
  BCC :+
  INC tmpSpriteX+1
:

  JSR draw

    ; increment y position again
  CLC
  LDA tmpSpriteY
  ADC #$08
  STA tmpSpriteY

  JSR draw


  RTS
.ENDPROC

.PROC init_func
  JSR populate_slot
  RTS
.ENDPROC

.PROC remove_func
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
.ENDPROC

.PROC draw
    ; offscreen, return early
  LDA tmpSpriteX+1
  BNE @done

  LDY oamOffset

  LDA tmpSpriteY
  STA unreservedOam, Y
  INY

  LDA tmpSpriteTile
  STA unreservedOam, Y
  INY

  LDA tmpSpriteAttr
  STA unreservedOam, Y
  INY

  LDA tmpSpriteX
  STA unreservedOam, Y
  INY
  STY oamOffset


    ; temp safe increment of oamOffset
  LDA oamOffset
  CMP #SPRITE_CAP * 4
  BCC @done

  LDA #$00
  STA oamOffset

@done:
  RTS
.ENDPROC