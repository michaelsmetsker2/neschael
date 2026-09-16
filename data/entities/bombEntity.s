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

	LDY #Slot::Y_POS_OFFSET
	LDA (UpdateParams::slotPtr), y

	; TODO temp updating Y pos
	CLC
	ADC #$02
	STA tmpSpriteY
	STA (UpdateParams::slotPtr), y


    ; populate sprite values
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
	LDA #$30
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
	LDA positionX
	STA (InitParams::slotPtr), Y
	INY
	LDA positionX+1
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