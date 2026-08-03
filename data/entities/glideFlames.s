;
; neschael
; data/entities/glideFlames.s
;
; entity for the visual component of the flames for the glide ability
;

.INCLUDE "lib/game/entities/entityData.inc"
.INCLUDE "lib/game/gameData.inc"
.INCLUDE "lib/player/player.inc"
.INCLUDE "data/system/cpu.inc"

.EXPORT glide_flames

	tmpAnimationTimer    = UpdateParams::SAFE_SCRATCH
	tmpPositionY         = UpdateParams::SAFE_SCRATCH+1

SPRITE_COUNT = $01 ; how sprites to allocate in oam for this
BASE_SPRITE  = $10 ; sprite to increment by animation timer

		; sprite header
glide_flames:
	.WORD update_func-1, init_func-1, remove_func-1
	.BYTE SPRITE_COUNT

	; this proccess should only be called from the entityHandler, The memory it inherites is in the UpdateParams scope
.PROC update_func

	; check if we are still holding the glide button
	LDA btnDown
	AND #_BUTTON_UP
	BNE :+
	JMP remove_func
:

	LDA motionState
	CMP #MotionState::Grounded
	BCC :+
	JMP remove_func
:

	LDA positionY+1
	STA tmpPositionY
	INC tmpPositionY

	; increment and clamp animation timer, (0-3)
	LDY #Slot::PARAM_OFFSET
	LDA (UpdateParams::slotPtr), Y
	CLC
	ADC #$01
	AND #%00000111
	STA (UpdateParams::slotPtr), Y
	; CLC should still be clear
	LSR
	CLC
	ADC #BASE_SPRITE
	STA tmpAnimationTimer

	LDY oamOffset
	; Y
	LDA tmpPositionY
	STA unreservedOam, Y
	INY
	; Tile
	LDA tmpAnimationTimer
	STA unreservedOam, Y
	INY
	; Attribute
	LDA #$00 
	STA unreservedOam, Y
	INY
	; X
	LDA positionX+1
	STA unreservedOam, Y
	INY
	STY oamOffset

	; safe increment of oamOffset
	LDA oamOffset
	CMP #SPRITE_CAP * 4
	BCC @done
	LDA #$00
	STA oamOffset
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

	; clear param 1 (animation timer)
	LDA #$00
	LDY #Slot::PARAM_OFFSET
	STA (InitParams::slotPtr), Y
	
	; garbage data in slot is fine update takes place on frame one and most is unused

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