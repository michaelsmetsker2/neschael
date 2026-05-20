;
; neschael
; lib/player/movement.s
;
; handles the players movement physics and input
; todo this file has potential cycle saves by using tail calls
;
; TODO go throgh *everything* and make use of the overflow flag

.SEGMENT "CODE"

.INCLUDE "data/system/cpu.inc"
.INCLUDE "lib/game/gameData.inc"
.INCLUDE "lib/player/player.inc"

.IMPORT update_position_x
.IMPORT update_position_y
.IMPORT update_sloped_position

.IMPORT execute_ability_up
.IMPORT execute_ability_down

.EXPORT update_player_movement

.PROC update_player_movement
	JSR set_target_velocity_x
	JSR handle_abilities
	JSR accelerate_x
	JSR update_vertical_motion  ; y is after set_target_velocity_x so heading is already updated for jump's speed boost
																; and before apply_velocity_x so the jump boost can be applied frame one
	JSR update_position_x				; x collision first to avoid getting stuck on walls
	JSR update_position_y
	RTS
.ENDPROC

	; sets the target velocity to accelerate to, also updates heading
.PROC set_target_velocity_x
	LDA btnDown
	AND #_BUTTON_RIGHT
	BEQ @check_left
		; change heading to 0 (right)
	LDA playerFlags
	AND #%10111111
	STA playerFlags
		; set target velocity
	LDA #<Velocities::RIGHT_WALK_TARGET
	STA targetVelocityX
	LDA #>Velocities::RIGHT_WALK_TARGET
	STA targetVelocityX+1
	RTS
@check_left:
	LDA btnDown
	AND #_BUTTON_LEFT
	BEQ @no_direction
		; change heading to 1 (left)
	LDA playerFlags
	ORA #%01000000
	STA playerFlags
		; set target velocity
	LDA #<Velocities::LEFT_WALK_TARGET
	STA targetVelocityX
	LDA #>Velocities::LEFT_WALK_TARGET
	STA targetVelocityX+1
	RTS
@no_direction:
		; heading remains the same as last frame
	LDA #$00
	STA targetVelocityX
	STA targetVelocityX+1
	RTS
.ENDPROC

	; apply give the player the correct velocity to push them toward their target
.PROC accelerate_x
		; Having a target of 0 (holding nothing) in air will not slow you down
		; NOTE probably inneficient to check this first
	LDA targetVelocityX         
	ORA targetVelocityX+1
	BNE @accelerate             ;branch if target is not zero
	LDA motionState
	;CMP #MotionState::Airborne ; redundant as Airborne is zero
	BNE @accelerate             ; branch if on the ground
	RTS                         ; return early
@accelerate:
	; find the difference between the target and current velocities
	SEC
	LDA targetVelocityX
	SBC velocityX
	STA $00
	LDA targetVelocityX+1
	SBC velocityX+1
	STA $01

	ORA $00             ; exit if the player is at the target velocity
	BEQ @done

	LDA #<BASE_ACCELERATION
	STA $04
	LDA #>BASE_ACCELERATION
	STA $05

	; check sign of velocity difference
	BIT $01
	BPL @apply_acceleration ; if the difference is positive, accelerate to the right
	; invert the acceleration if we're accelerating left
	LDA #0
	SEC
	SBC $04
	STA $04
	LDA #0
	SBC $05
	STA $05

@apply_acceleration:
	; add the acceleration to the velocity
	CLC
	LDA velocityX
	ADC $04
	STA velocityX
	LDA velocityX+1
	ADC $05
	STA velocityX+1

	; recompute updated difference between velocity and target
	SEC
	LDA targetVelocityX
	SBC velocityX   				; only need carry
	LDA targetVelocityX+1
	SBC velocityX+1
	; if the sign of the difference has flipped, then velocity was overshot
	EOR $01
	BPL @done
	; clamp to the target on overshoot
	LDA targetVelocityX
	STA velocityX
	LDA targetVelocityX+1
	STA velocityX+1

@done:
	RTS
.ENDPROC

	; sets the correct velocity and states for the players y movement
.PROC update_vertical_motion
		; skip to update jump velocity if player is currently airborne
	LDA motionState  
	CMP #MotionState::Airborne
	BNE @check_jump
	JMP update_jump_velocity

@check_jump:
	LDA btnPressed
	AND #_BUTTON_A
	BNE @begin_jump            ; grounded and not jumping, break
	RTS

@begin_jump:
		; set the holding jump flag
	LDA playerFlags
	ORA #%10000000
	STA playerFlags

@slope_checking:
		; check if the player if jumping from a slope
	LDX #$04 ; assume flat, saves jumping cycles
	LDY motionState
	CPY #MotionState::SteepSlopeUp
	BCC @set_jump_velocity

		; skip to using flat jump velocity if player is stationary
	LDA velocityX+1
	ORA velocityX
	BEQ @set_jump_velocity
	
		; player is on a slope and moving
		; set slope flag to 2 grace frames ; BUG can cause tunneling if a wall is at the end of a slope at high speeds
	LDA playerFlags
	ORA #%00000010
	STA playerFlags

@determine_slope_direction: ; finds whether the player is going up or down a slope
	TYA                       ; Y register contains motionState	
	SEC
	SBC #SLOPE_STATES_START   ; slope index 0-3
	TAY 											; store slope index for later
	LSR A         				    ; 0-1 incline, decline
	STA $00
		; XOR with X direction
	LDA velocityX+1
	ASL
	ROL
	AND #%00000001 		; 1 is left, 0 right
	EOR $00 					; 1 for down, 0 for up
	ASL 							; 0 for down, 2 for up
	STA $00
	
	TYA
	AND #%00000001	  ; 0 steep, 1 shallow
	ORA $00					  ; 0 steep down, 1 shallow down, 2 steep up, 3 shallow up
	TAX

@set_jump_velocity:
		; set vertical velocity based on slope inclination and direction
	LDA jump_vel_low, X
	STA velocityY
	LDA jump_vel_high, X
	STA velocityY+1

		; set motionstate to airborne
	LDA #MotionState::Airborne
	STA motionState

		; only apply the boost if the character is moving
	LDA velocityX+1
	ORA velocityX
	BNE @horizontal_boost
	JMP update_jump_velocity			; skip boost if no velocity found

		; add hortizontal according to heading direction
@horizontal_boost:

	LDA jump_boost_low, X
	STA $00
	LDA jump_boost_high, X 
	STA $01      

	LDA velocityX+1 
	BPL @apply_boost ; if heading is left, invert the boost velocity
@invert_boost:
	LDA #$00
	SEC
	SBC $00
	STA $00
	LDA #$00
	SBC $01
	STA $01
@apply_boost:
	CLC
	LDA velocityX
	ADC $00
	STA velocityX
	LDA velocityX+1
	ADC $01
	STA velocityX+1      
	RTS

		; lookup tables for initial jump velocities and hor boosts based on slope type
		; 0 steep down, 1 shallow down, 2 steep up, 3 shallow up, 4 flat
	jump_vel_low:
		.BYTE <Jump::INITIAL_VELOCITY_STEEP_INC
		.BYTE <Jump::INITIAL_VELOCITY_SHALLOW_INC
		.BYTE <Jump::INITIAL_VELOCITY_STEEP_DEC
		.BYTE <Jump::INITIAL_VELOCITY_SHALLOW_DEC
		.BYTE <Jump::INITIAL_VELOCITY_FLAT
	jump_vel_high:
		.BYTE >Jump::INITIAL_VELOCITY_STEEP_INC
		.BYTE >Jump::INITIAL_VELOCITY_SHALLOW_INC
		.BYTE >Jump::INITIAL_VELOCITY_STEEP_DEC
		.BYTE >Jump::INITIAL_VELOCITY_SHALLOW_DEC
		.BYTE >Jump::INITIAL_VELOCITY_FLAT

	jump_boost_low:
		.BYTE <Jump::HORIZONTAL_BOOST_STEEP_INC
		.BYTE <Jump::HORIZONTAL_BOOST_SHALLOW_INC
		.BYTE <Jump::HORIZONTAL_BOOST_STEEP_DEC
		.BYTE <Jump::HORIZONTAL_BOOST_SHALLOW_DEC
		.BYTE <Jump::HORIZONTAL_BOOST_FLAT
	jump_boost_high:
		.BYTE >Jump::HORIZONTAL_BOOST_STEEP_INC
		.BYTE >Jump::HORIZONTAL_BOOST_SHALLOW_INC
		.BYTE >Jump::HORIZONTAL_BOOST_STEEP_DEC
		.BYTE >Jump::HORIZONTAL_BOOST_SHALLOW_DEC
		.BYTE >Jump::HORIZONTAL_BOOST_FLAT


.ENDPROC

.PROC update_jump_velocity ; updates mid air velocity
		; Determine whether to decelerate slow or fast based on button hold
	LDY #$00                    ; lookup table offset for BASE_FALL_SPEED
	BIT playerFlags
	BPL @decelerate             ; branch if held jump isn't set
	LDA btnDown
	AND #_BUTTON_A
	BEQ @newly_fast             ; branch if A isn't held
	; check velocity threshold

	LDA velocityY+1
	CMP #Jump::DECELERATION_THRESHOLD
	BPL @newly_fast             ; branch if velocity is past threshold
	INY                         ; SLOW_FALL_SPEED offset
	JMP @decelerate
@newly_fast:                  	; for first times using fast falling set flag
	LDA playerFlags             ; updates the flag to save cpu cycles
	AND #%01111111
	STA playerFlags
@decelerate: ; Perform the deceleration
	CLC 
	LDA fall_speeds_low,Y
	ADC velocityY
	STA velocityY
	LDA fall_speeds_high,Y
	ADC velocityY+1
	STA velocityY+1

	CMP #$08
	BNE @done

		; clamp to max fall speed if exceeded
	LDA #>Jump::MAX_FALL_SPEED	
	STA velocityY+1
	LDA #<Jump::MAX_FALL_SPEED
	STA velocityY
@done:
	RTS

		; fall speed lookup tables
fall_speeds_low:
	.BYTE <Jump::BASE_FALL_DECCEL, <Jump::SLOW_FALL_DECCEL
fall_speeds_high:
	.BYTE >Jump::BASE_FALL_DECCEL, >Jump::SLOW_FALL_DECCEL
.ENDPROC

	; check for ability or charge button presses
.PROC handle_abilities

	LDX btnDown

@check_up:
	TXA
	AND #_BUTTON_UP
	BEQ @check_down
	JMP execute_ability_up

@check_down:
	TXA
	AND #_BUTTON_DOWN
	BEQ @check_b
	JMP execute_ability_down

@check_b:
		; check input for b button
	TXA
	AND #_BUTTON_B
	BEQ @decay
	JMP handle_charge

@decay:	; no ability is pressed, decay charge if needed
	JMP decay_charge
.ENDPROC

	; take velocity fromt the player and stores it
.PROC handle_charge

		; if targetVelocity isn't zero a direction is held, so enact the boost
	LDA targetVelocityX
	ORA targetVelocityX+1
	BEQ @check_held
	JMP charge_boost

@check_held: ; check if this is the first frame of the b press
	LDA btnPressed
	AND #_BUTTON_B
	BEQ @sustained_press

@new_press:
		; set chargestate
	LDA playerFlags
	ORA #CHARGE_STATE_MASK
	STA playerFlags
		; reset chargeCounter
	LDA #$00
	STA chargeCounter
	JMP @store
	
@sustained_press:
	; a sustained press with no charge state will not initiate a new charge
		; this prevents holding the b button and eating your velocity after a boost
	LDA playerFlags
	AND #CHARGE_STATE_MASK
	BNE @store 
	RTS	; break, no need to store or release

@store:
	LDA velocityX+1
	BMI @add_vel

@sub_vel:
	SEC
	LDA velocityX
	SBC chargeCounter
	TAX              		 ; low byte in X
	LDA velocityX+1
	SBC #$00             ; subtract carry
	TAY                  ; high byte in Y

	JMP @check_sign
@add_vel:
	CLC
	LDA velocityX
	ADC chargeCounter
	TAX                 ; low byte in X
	LDA velocityX+1
	ADC #$00				    ; add carry
	TAY                 ; high byte in Y
		; fall through

@check_sign:
	; high byte should still be in ACC
	EOR velocityX+1
	BMI @done 			; return if sign has flipped

	; sign has not flipped, apply new velocity
	STX velocityX
	STY velocityX+1
	
@store_vel: ; increment the ammount of currently stored veloctiy
	CLC
	LDA storedCharge
	ADC chargeCounter
	STA storedCharge
	BCC :+
	INC storedCharge+1
:

	INC chargeCounter ; increment the counter upon a succesful charge
@done:
	RTS
.ENDPROC

	; releases the stored charge into players velocity
.PROC charge_boost
  	; branch based on boost direction
	BIT playerFlags
	BVS @boost_left

@boost_right: ; add boost (right)
	CLC	
	LDA velocityX
	ADC storedCharge
	STA velocityX
	LDA velocityX+1
	ADC storedCharge+1
	STA velocityX+1
	JMP @reset_charge
@boost_left: ; subtract boost (left)
	SEC	
	LDA velocityX
	SBC storedCharge
	STA velocityX
	LDA velocityX+1
	SBC storedCharge+1
	STA velocityX+1

@reset_charge:
	LDA #$00
	STA storedCharge
	STA storedCharge+1

@reset_chargestate:
	LDA playerFlags
	AND #%11011111
	STA playerFlags

	RTS
.ENDPROC

.PROC decay_charge
	; BUG underflows
	RTS

	LDA playerFlags
	AND #CHARGE_STATE_MASK
	BEQ @done

	SEC
	LDA storedCharge
	SBC #$01
	STA storedCharge
	BCS :+
	DEC storedCharge+1
	:

@done:
	RTS
.ENDPROC