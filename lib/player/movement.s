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
		STA $02
		LDA targetVelocityX+1
		SBC velocityX+1
		STA $03

		ORA $02             ; exit if the player is at the target velocity
		BEQ @done

		; TODO here we would determing what acceleration values to actually use depending on the surface
		;and we would load the correct accecleration bytes into memory
		LDA #<TEST_ACC
		STA $04
		LDA #>TEST_ACC
		STA $05
		; TODO all of that is temp ====================================================================================

		; check sign of velocity difference
		BIT $03
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
		SBC velocityX
		STA $06                 ; storing stuff like this is for debugging mostly, it uses cycles so if i need performance, remove
		LDA targetVelocityX+1
		SBC velocityX+1
		STA $07
		; if the sign of the difference has flipped, then velocity was overshot
		EOR $03
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
		STA $07
		LDA #>Jump::HORIZONRAL_BOOST
		STA $08      

		LDA playerFlags
		AND #%01000000   ; check heading
		BEQ @apply_boost ; if heading is left, invert the boost velocity
		LDA #0
		SEC
		SBC $07
		STA $07
		LDA #0
		SBC $08
		STA $08
@apply_boost:
		CLC 
		LDA velocityX
		ADC $07
		STA velocityX
		LDA velocityX+1
		ADC $08
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
	; check if b button is held down
	LDA btnDown
	AND #_BUTTON_B
	BEQ @no_press
@b_held:           ; check if we were already charging
	LDA playerFlags
	AND #%00100000 	 ; mask chargeState
	BNE @store_charge
@new_charge:       ; start a new charge

	; set chargeStat
	LDA playerFlags
	ORA #%00100000
	STA playerFlags

	; set charge target to current velocity's magnitude
	BIT velocityX+1
	BMI @flip_target
	; velocity is positive so store it 
	LDA velocityX
	STA charge_target
	LDA velocityX+1
	STA charge_target+1
	JMP @store_charge

@flip_target:
	CLC
	LDA velocityX
	EOR #$FF
	ADC #$01
	STA charge_target
	LDA velocityX+1
	EOR #$FF
	ADC #$01
	STA charge_target+1

@store_charge:     ; store current velocity up to target
	BIT velocityX+1
	;BMI @store_neg ; TODO temp
@store_pos: ; TODO TEMP
	
	CLC
	LDA stored_velocity
	ADC #$01
	STA stored_velocity
	LDA stored_velocity+1
	ADC #$00
	STA stored_velocity+1
	RTS
@store_neg:

	RTS

@no_press:
	
	LDA playerFlags
	AND #%00100000
	BEQ @done
@release_charge:

	CLC	
	LDA velocityX
	ADC stored_velocity
	STA velocityX
	LDA velocityX+1
	ADC stored_velocity+1
	STA velocityX+1

	LDA #$00
	STA stored_velocity
	STA stored_velocity+1

	LDA playerFlags
	AND #%00100000
	STA playerFlags
@done:
	RTS
.ENDPROC