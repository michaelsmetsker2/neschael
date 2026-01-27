;
; nechael
; lib/player/sprite.s
; 
; updates the player's sprites based on its motion state and heading
;

.SEGMENT "CODE"

.INCLUDE "data/system/ppu.inc"
.INCLUDE "lib/player/player.inc"

.EXPORT update_player_sprite

.PROC update_player_sprite
    ;JSR update_motion_state
    JSR update_animation_frame
    JSR update_heading
    JSR update_sprite_position
    RTS
.ENDPROC

; update the currently displayed player sprite based on motion_state and time
.PROC update_animation_frame
	; TODO add all the motionstate stuff

	LDA motionState
	CMP #MotionState::Airborne
	BNE @grounded
@Airborne:
	BIT velocityY+1
	BPL @falling

@rising:
	LDA #$04
	JMP @write
@falling:
	LDA #$05
	JMP @write


@grounded:
	INC animationTimer
	LDA animationTimer
	LSR A
	LSR A
	LSR A
	AND #%00000011
	TAY
	LDA test_frames, Y
@write:
	STA $0200 + _OAM_TILE 
	RTS
test_frames:
	.BYTE $01, $02, $01, $03
.ENDPROC

; changed the direction the player sprite is facing based on heading
.PROC update_heading
    ; heading is already set during x movement
    LDA playerFlags
    AND #%01000000
    STA $0B
    LDA $0200 + _OAM_ATTR
    AND #%10111111
    ORA $0B
    STA $0200 + _OAM_ATTR
.ENDPROC

; copies the sprite x and y variables to the players data
.PROC update_sprite_position
    LDA positionX+1
    STA $0200 + _OAM_X
    LDY positionY+1
    DEY                     ; NES displays sprites one pixel lower than they should, this counteracts that
    STY $0200 + _OAM_Y
    RTS
.ENDPROC
