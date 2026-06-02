;
; nechael
; lib/player/sprite.s
; 
; updates the player's sprites based on its motion state and heading
;

.SEGMENT "CODE"

.INCLUDE "data/system/ppu.inc"
.INCLUDE "lib/player/player.inc"
.INCLUDE "lib/game/gameData.inc"

.IMPORTZP SCRATCH
.IMPORT shadowOam

.EXPORT update_player_sprite

	; sprite constants
	STANDING_SPRITE   = $01
	RIGHT_WALK_SPRITE = $02
	LEFT_WALK_SPRITE  = $03
	RISING_SPRITE     = $04
	FALLING_SPRITE    = $05

	; store heading in scratch memory to avoid recalculating it
	tmpHeading 		    = SCRATCH
	
	PLAYER_OAM_ADDRESS = shadowOam + 4 ; first reserved sprite after sprite zero

.PROC update_player_sprite
	; update the currently displayed player sprite based on motion_state and time and tail call remaining proccesses
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
		; increment animation timer for walk animation
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
	
	JMP update_heading ; tail call to save cycles

walk_frames: ; sprites in the walk animation
	.BYTE STANDING_SPRITE, LEFT_WALK_SPRITE, STANDING_SPRITE, RIGHT_WALK_SPRITE
.ENDPROC

	; changed the direction the player sprite is facing based on heading
.PROC update_heading

		; heading is already set during x movement
	LDA playerFlags
	AND #%01000000
	STA tmpHeading
	STA PLAYER_OAM_ADDRESS + _OAM_ATTR

	JMP update_sprite_position ; tail call for saved cycles
.ENDPROC

	; copies the sprite x and y variables to the players data
.PROC update_sprite_position

@update_player_x:
	LDX positionX+1
	LDA tmpHeading
	BEQ :+
	DEX		          				; decrement the sprites position if facing left as the sprite is asymetrical
	:
	TXA
	STA PLAYER_OAM_ADDRESS + _OAM_X

@update_player_y:
	LDX positionY+1
	DEX 										; NES displays sprites one pixel lower than they should, this counteracts that
	TXA
	LDY #_OAM_Y
	STA PLAYER_OAM_ADDRESS + _OAM_Y
	RTS
.ENDPROC
