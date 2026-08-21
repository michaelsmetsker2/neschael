;
; neschael
; data/entities/glideFlames.s
;
; entity entity spawned by using the bomb ability
;

; TODO this is all unfinished

.INCLUDE "lib/game/entities/entityData.inc"
.INCLUDE "lib/game/gameData.inc"
.INCLUDE "lib/player/player.inc"
.INCLUDE "data/system/cpu.inc"

.EXPORT bomb_entity

	tmpAnimationTimer    = UpdateParams::SAFE_SCRATCH
	tmpPositionY         = UpdateParams::SAFE_SCRATCH+1

SPRITE_COUNT = $01 ; how sprites to allocate in oam for this

		; sprite header
bomb_entity:
	.WORD update_func-1, init_func-1, remove_func-1
	.BYTE SPRITE_COUNT

	; this proccess should only be called from the entityHandler, The memory it inherites is in the UpdateParams scope
.PROC update_func

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