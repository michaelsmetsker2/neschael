;
; neschael
; lib/player/movement.s
;
; handles the players movement physics and input
;

.SEGMENT "CODE"

.INCLUDE "data/system/cpu.inc"
.INCLUDE "lib/game/gameData.inc"
.INCLUDE "lib/player/player.inc"

.IMPORT update_position_x
.IMPORT update_position_y

.EXPORT update_player_movement

.PROC update_player_movement
		JSR set_target_velocity_x
		JSR accelerate_x
		JSR update_vertical_motion  ; y is after set_target_velocity_x so heading is already updated for hor boost
																	; and before apply_velocity_x so the jump boost can be applied frame one
		JSR charge_boost
    JSR update_position_x				; x collision first to avoid getting stuck on walls
		JSR update_position_y
		RTS
.ENDPROC

.PROC set_target_velocity_x
		; TODO check input, eventually use a lookup tabledepending on tile?
		; heading is also updated in this subproccess
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
		; heading does not change
		LDA #0
		STA targetVelocityX
		STA targetVelocityX+1
		RTS
.ENDPROC

.PROC accelerate_x
		; Having a target of 0 (holding nothing) in air will not slow you down
		;NOTE probably inneficient to check this first
		LDA targetVelocityX         
		ORA targetVelocityX+1
		BNE @accelerate             ;branch if target is not zero
		LDA motionState
		CMP #MotionState::Airborne
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
		; TODO all of that is temp ====================================================================================

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

.PROC update_vertical_motion
		LDA motionState  
		CMP #MotionState::Airborne
		BEQ @airborne              ; branch if player is airborne
@check_jump:                   ; can only start a new jump from the ground
		LDA btnPressed
		AND #_BUTTON_A
		BNE @begin_jump            ; branch if a new jump is detected
		RTS
@begin_jump:
		LDA playerFlags
		ORA #%10000000               ; set the holding jump flag
		STA playerFlags
		; add vertical velocity
		LDA #<Jump::INITIAL_VELOCITY ; update vertical velocity
		STA velocityY
		LDA #>Jump::INITIAL_VELOCITY
		STA velocityY+1
		LDA #MotionState::Airborne   ; set motionState to airborne
		STA motionState

		; only apply the boost if the character is moving
		LDA velocityX+1
		BNE @horizontal_boost
		CLC 
		ADC velocityX
		BNE @horizontal_boost
		JMP @airborne			; skip of no velocity found
		; add vertical velocity boost in heading direction
@horizontal_boost:
		LDA #<Jump::HORIZONRAL_BOOST
		STA $02
		LDA #>Jump::HORIZONRAL_BOOST
		STA $03      

		LDA playerFlags
		AND #%01000000   ; check heading
		BEQ @apply_boost ; if heading is left, invert the boost velocity
		LDA #0
		SEC
		SBC $02					 ; unused, only carry is needed
		LDA #0
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
@airborne:
		JSR update_jump_velocity  ; this are not in update so an early exit can save cpu cycles
		RTS
.ENDPROC

.PROC update_jump_velocity ; this updates mid air velocity
		; Determine if velocity decelerates slow or fest based on button hold
		LDY #0                      ; lookup table offset for BASE_FALL_SPEED
		BIT playerFlags
		BPL @decelerate             ; branch if held jump isn't set
		LDA btnDown
		AND #_BUTTON_A
		BEQ @newly_fast             ; branch if A isn't held
		; check velocity threshold

		LDA velocityY+1
		CMP #Jump::DECELERATION_THRESHOLD
		BPL @newly_fast             ; branch if velocity is past threshold
		LDY #2                      ; SLOW_FALL_SPEED offset
		JMP @decelerate
@newly_fast:                  	; for first times using fast falling set flag
		LDA playerFlags             ; updates the flag to save cpu cycles
		AND #%01111111
		STA playerFlags
@decelerate: 
		; Perform the deceleration
		CLC 
		LDA fall_speeds,Y
		ADC velocityY
		STA velocityY
		INY
		LDA fall_speeds,Y
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
fall_speeds:
		.BYTE <Jump::BASE_FALL_DECCEL, >Jump::BASE_FALL_DECCEL
		.BYTE <Jump::SLOW_FALL_DECCEL, >Jump::SLOW_FALL_DECCEL
.ENDPROC

; proccess the b button charge ability
.PROC charge_boost
	; check the input
	LDA btnDown
	AND #_BUTTON_B
	BNE @b_pressed     ; branch if b is pressed

@no_press: ; check if we were charging last frame
	LDA playerFlags
	AND #CHARGE_STATE_MASK
	BEQ @done								; no charge, return	
	JSR release_charge			; existing charge, release
	JMP @done	

@b_pressed:
	; check if there is a charge currently ongoing
	LDA playerFlags
	AND #CHARGE_STATE_MASK
	BNE @store_charge

@new_charge:  			; no existing, make a new one 
	; set chargeFlag
	LDA playerFlags
	ORA #CHARGE_STATE_MASK
	STA playerFlags
; reset stored charge and timer
	LDA #$00
	STA storedVelocity
	STA storedVelocity+1
	STA chargeCounter

	; TODO reset other flag?

@store_charge:
	JSR store_charge
@done:
	RTS
.ENDPROC

; proccess adding to an existing charge
.PROC store_charge

	 ; ammount of velocity to store and remove from player
	tmpCurCharge = $01

	LDA #chargeCounter
	LSR
	LSR
	STA tmpCurCharge

	LDA velocityX+1
	AND #%10000000   ; mask sign bit
	STA $00          ; store sign bit in scratch memory for later
	BMI @add_vel

@sub_vel:
	SEC
	LDA velocityX
	SBC tmpCurCharge
	TAX              		 ; low byte in X
	LDA velocityX+1
	SBC #$00             ; subtract carry
	TAY                  ; high byte in Y

	JMP @check_sign
@add_vel:
	CLC
	LDA velocityX
	ADC tmpCurCharge
	TAX                 ; low byte in X
	LDA velocityX+1
	ADC #$00				    ; add carry
	TAY                 ; high byte in Y

@check_sign:
	; high byte should still be in ACC
	AND #%10000000 ; mask sign bit
	CMP $00        ; compare to the velocities sign
	BNE @done      ; sign has fliped, return ; TODO make this flip the no more flag or something?
	
	; sign has not flipped, apply new velocity
	STX velocityX
	STY velocityX+1
	
; maybe add one stored to each tick to dupe velocity a little bit :)
@store_vel: ; increment the ammount of currently stored veloctiy
	CLC
	LDA storedVelocity
	ADC tmpCurCharge
	STA storedVelocity
	LDA storedVelocity+1
	ADC #$00
	STA storedVelocity+1

	INC chargeCounter ; increment the timer upon a succesful charge
@done:
	RTS
.ENDPROC

; releases the stored charge into players velocity
.PROC release_charge
	; reset the chargeState flag
	LDA playerFlags
	AND #%11011111
	STA playerFlags

	; check if heading and direction don't match
	LDA playerFlags
	AND HEADING_MASK
	ASL
	CMP $00          ; sign bit of velocity stored in store_charge
	BNE @get_heading

	; TODO make 1.5 instead of 2x
	; BUG logic may be broken verify
	; double stored velocity
	ASL storedVelocity
	ROL storedVelocity+1

@get_heading:      ; branch based on boost direction
	LDA playerFlags
	AND #HEADING_MASK
	BNE @boost_left

@boost_right: ; add boost (right)
	CLC	
	LDA velocityX
	ADC storedVelocity
	STA velocityX
	LDA velocityX+1
	ADC storedVelocity+1
	STA velocityX+1
	RTS
@boost_left: ; subtract boost (left)
	SEC	
	LDA velocityX
	SBC storedVelocity
	STA velocityX
	LDA velocityX+1
	SBC storedVelocity+1
	STA velocityX+1
	RTS
.ENDPROC