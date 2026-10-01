;
; neschael
; data/entities/bombEntity.s
;
; entity entity spawned by using the bomb ability
;

.INCLUDE "lib/game/entities/entityData.inc"
.INCLUDE "lib/game/gameData.inc"
.INCLUDE "lib/player/player.inc"

.EXPORT bomb_entity

	tmpSpriteX    = UpdateParams::SAFE_SCRATCH    ; 16 bit, relative x position to the screen scroll
	tmpSpriteY    = UpdateParams::SAFE_SCRATCH+2

SPRITE_COUNT = $01 ; how sprites to allocate in oam for this

		; sprite header
bomb_entity:
	.WORD update_func-1, init_func-1, remove_func-1
	.BYTE SPRITE_COUNT

	; this proccess should only be called from the entityHandler, The memory it inherites is in the UpdateParams scope
.PROC update_func

@update_position_x:
	LDY #Slot::X_POS_OFFSET
	LDA (UpdateParams::slotPtr), Y
	STA tmpSpriteX
   
    ; calculate pixel position relative to start of screen, subtract the screen scroll from the entities world position
	SEC
	SBC screenPosX
	STA tmpSpriteX ; low byte (pixel)

	INY ; increments to the high byte
	LDA (UpdateParams::slotPtr), Y
	SBC screenPosX+1
	STA tmpSpriteX+1 ; high byte (nametable)	

	LDY #Slot::X_POS_OFFSET
	STA (UpdateParams::slotPtr), Y

eupdate_position_y:
	LDY #Slot::Y_POS_OFFSET
	LDA (UpdateParams::slotPtr), y
	CLC
	ADC #$02
	STA tmpSpriteY
	STA (UpdateParams::slotPtr), y


@update_sprite_values:
	LDY oamOffset
	; Y
	LDA tmpSpriteY
	STA unreservedOam, Y
	INY
	; Tile
	LDA #$04
	STA unreservedOam, Y
	INY
	; Attribute
	LDA #$00 
	STA unreservedOam, Y
	INY
	; X
	LDA tmpSpriteX
	STA unreservedOam, Y
	INY
	STY oamOffset

	; safe increment of oamOffset
	LDA oamOffset
	CMP #SPRITE_CAP * 4
	BCC @done
	LDA #$00
	STA oamOffset

    ; increment the position gravity and collision and such?

@done:
	RTS
.ENDPROC

		; this entity is not triggered from level placement so slot population is unique
.PROC init_func

		; add the entity ID to the pool and set state to active
	LDA #%10000000
	ORA InitParams::entityId
	LDY #$00
	STA (InitParams::slotPtr), Y

		; Store current player X and Y positions in slot for bomb startingn pos
	LDY #Slot::X_POS_OFFSET
	;LDA positionX
	LDA #$30 ; TODO temp
	STA (InitParams::slotPtr), Y
	INY
	;LDA positionX+1
	LDA #$30 ; TODO temp
	STA (InitParams::slotPtr), Y
	INY
	LDA positionY+1
	STA (InitParams::slotPtr), Y

	; garbage in remainging bytes is fine

	RTS
.ENDPROC

.PROC remove_func
		; subtract the sprite ammount from the count
	DEC spriteCount

		; set the entity slot to inactive
	LDA #$00
	TAY
	STA (UpdateParams::slotPtr), Y

	RTS
.ENDPROC