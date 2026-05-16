;
; neschael
; lib/player/movement.s
;
; handles the players movement physics and input
; todo this file has potential cycle saves by using tail calls
;

.SEGMENT "CODE"

.INCLUDE "data/system/cpu.inc"
.INCLUDE "lib/game/gameData.inc"
.INCLUDE "lib/player/player.inc"

.IMPORT update_position_x
.IMPORT update_position_y
.IMPORT update_sloped_position

.EXPORT update_player_movement

.PROC update_player_movement
	JSR set_target_velocity_x
	JSR update_charge
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

	; TODO here we would determing what acceleration values to actually use depending on the surface
	;and we would load the correct accecleration bytes into memory
	LDA #<TEST_ACC
	STA $04
	LDA #>TEST_ACC
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
	LDA motionState
	CMP #MotionState::SteepSlopeUp
	BCC @set_jump_velocity
	
		; player is on a slope
		; set slope flag to 2 grace frames ; BUG can cause tunneling if a wall is at the end of a slope
	LDA playerFlags
	ORA #%00000010
	STA playerFlags

@determine_slope_direction: ; finds whether the player is going up or down a slope
	TXA                       ; X register contains motionState	
	SEC
	SBC #SLOPE_STATES_START   ; slope index 0-3
	TAY 											; store slope index for later
	LSR A         				    ; 0-1 incline, decline
	STA $00
		; xor with direction
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
	BNE @horizontal_boost
	CLC 
	ADC velocityX
	BNE @horizontal_boost
	JMP update_jump_velocity			; skip if no velocity found

		; add hortizontal according to heading direction
@horizontal_boost:
	LDA #<Jump::HORIZONTAL_BOOST
	STA $02
	LDA #>Jump::HORIZONTAL_BOOST
	STA $03      

	LDA playerFlags
	AND	#HEADING_MASK 
	BEQ @apply_boost ; if heading is left, invert the boost velocity
@invert_boost:
	LDA #$00
	SEC
	SBC $02					 ; unused, only carry is needed
	LDA #$00
	SBC $03
	STA $03
@apply_boost:
	CLC 
	LDA velocityX
	ADC $02
	STA velocityX
	LDA velocityX+1
	ADC $03
	STA velocityX+1      
	RTS

		; lookup tables for initial jump velocity based on slope type
		; 0 steep down, 1 shallow down, 2 steep up, 3 shallow up, 4 flat
	jump_vel_low:
		.BYTE <Jump::INITIAL_VELOCITY_STEEP_DEC
		.BYTE <Jump::INITIAL_VELOCITY_SHALLOW_DEC
		.BYTE <Jump::INITIAL_VELOCITY_STEEP_INC
		.BYTE <Jump::INITIAL_VELOCITY_SHALLOW_INC
		.BYTE <Jump::INITIAL_VELOCITY_FLAT
	jump_vel_high:
		.BYTE >Jump::INITIAL_VELOCITY_STEEP_DEC
		.BYTE >Jump::INITIAL_VELOCITY_SHALLOW_DEC
		.BYTE >Jump::INITIAL_VELOCITY_STEEP_INC
		.BYTE >Jump::INITIAL_VELOCITY_SHALLOW_INC
		.BYTE >Jump::INITIAL_VELOCITY_FLAT
.ENDPROC

.PROC update_jump_velocity ; updates mid air velocity
	; Determine if velocity decelerates slow or fest based on button hold
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

		; small fall speed lookup table for use in update_jump_velocity
fall_speeds_low:
	.BYTE <Jump::BASE_FALL_DECCEL, <Jump::SLOW_FALL_DECCEL
fall_speeds_high:
	.BYTE >Jump::BASE_FALL_DECCEL, >Jump::SLOW_FALL_DECCEL
.ENDPROC

; proccess the b button charge ability
.PROC update_charge

	; TODO pressing up or down check first then return early?

		; check input for b button
	LDA btnDown
	AND #_BUTTON_B
	BEQ @decay_charge     ; decay if b is not pressed

@b_pressed:
		; if targetVelocity isn't zero a direction is held, so release charge
	LDA targetVelocityX
	ORA targetVelocityX+1
	BEQ @store

	JSR release_charge
	RTS

@store:
	JSR store_charge

@decay_charge:

	; if velocity hits zero then start the decay?

	; TODO decay from a timer that is reset each b press
	; if charge not equal zero decrement it

	RTS
.ENDPROC

	; take velocity fromt the player and stores it
.PROC store_charge
		; if this is the first frame the B button has been pressed, reset the charge counter
	LDA btnPressed
	AND #_BUTTON_B
	BEQ :+
	LDA #$50
	STA chargeCounter
:

	LDA velocityX+1
	AND #%10000000   ; mask sign bit
	STA $00          ; store sign bit in scratch memory for later
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

@check_sign:
	; high byte should still be in ACC
	AND #%10000000 ; mask sign bit
	CMP $00        ; compare to the velocities sign
	BNE @done      ; sign has fliped, return
	
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
	INC chargeCounter ; increment the timer upon a succesful charge
@done:
	RTS
.ENDPROC

	; releases the stored charge into players velocity
.PROC release_charge
@get_heading:      ; branch based on boost direction
	LDA playerFlags
	AND #HEADING_MASK
	BNE @boost_left

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
.ENDPROC