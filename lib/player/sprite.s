;
; nechael
; lib/player/sprite.s
; 
; updates the player's sprites based on its motion state and heading
;

.SEGMENT "CODE"

.INCLUDE "data/system/ppu.inc"
.INCLUDE "lib/player/player.inc"

.IMPORTZP SCRATCH
.IMPORT shadowOam

.EXPORT update_player_sprite

	; sprite constants
	STANDING_SPRITE   = $01
	RIGHT_WALK_SPRITE = $02
	LEFT_WALK_SPRITE  = $03
	RISING_SPRITE     = $04
	FALLING_SPRITE    = $05

	PLAYER_OAM_ADDRESS = shadowOam + 4 ; first reserved sprite after sprite zero

	; stores heading in scratch memory to avoid recalculating it
	tmpHeading = SCRATCH

.PROC update_player_sprite
			; FIXME could do tail calls to save many cycles
    JSR update_animation_frame
    JSR update_heading
    JSR update_sprite_position
    RTS
.ENDPROC

; update the currently displayed player sprite based on motion_state and time
.PROC update_animation_frame
	; check if grounded
	LDA motionState
	CMP #MotionState::Airborne
	BNE @grounded
@Airborne:        ; check direction
	LDA velocityY+1
	BEQ @low_speed
	BIT velocityY+1
	BPL @falling
@rising:
	LDA #RISING_SPRITE
	JMP @write

@low_speed:
	LDA #STANDING_SPRITE
	JMP @write
@falling:
	LDA #FALLING_SPRITE 
	JMP @write

@grounded:
	; increment animation timer
	INC animationTimer
	LDA animationTimer
	LSR A
	LSR A
	LSR A
	LSR A
	AND #%00000011
	TAY
	LDA walk_frames, Y
@write:
	STA PLAYER_OAM_ADDRESS + _OAM_TILE 
	RTS
walk_frames:
	.BYTE STANDING_SPRITE, LEFT_WALK_SPRITE, STANDING_SPRITE, RIGHT_WALK_SPRITE
.ENDPROC

; changed the direction the player sprite is facing based on heading
.PROC update_heading
    ; heading is already set during x movement
    LDA playerFlags
    AND #%01000000
    STA tmpHeading
    LDA PLAYER_OAM_ADDRESS + _OAM_ATTR
    AND #%10111111
    ORA tmpHeading
    STA PLAYER_OAM_ADDRESS + _OAM_ATTR
.ENDPROC

; copies the sprite x and y variables to the players data
.PROC update_sprite_position
    LDY positionX+1
		LDA tmpHeading
		BEQ :+
		DEY		          				; decrement the sprites position if facing left as the sprite is asymetrical
		:
    STY PLAYER_OAM_ADDRESS + _OAM_X
    LDY positionY+1
    DEY                     ; NES displays sprites one pixel lower than they should, this counteracts that
    STY PLAYER_OAM_ADDRESS + _OAM_Y
    RTS
.ENDPROC
