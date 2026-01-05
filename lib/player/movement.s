;
; neschael
; lib/player/movement.s
;
; handles the players movement physics and input
;

.SEGMENT "CODE"

.INCLUDE "data/system/cpu.inc"
.INCLUDE "lib/memory/gameData.inc"
.INCLUDE "lib/player/player.inc"

.IMPORT update_position_x

.EXPORT update_player_movement

.PROC update_player_movement
		JSR set_target_velocity_x
		JSR accelerate_x
		JSR update_vertical_motion  ; y is after set_target_velocity_x so heading is already updated for hor boost
																	; and before apply_velocity_x so the boost can be applied frame one
		JSR update_position_x
		RTS
.ENDPROC

.PROC set_target_velocity_x
		; TODO check input, eventually use a lookup tabledepending on tile?
		; heading is also updated in this subproccess
		LDA GameData::btnDown
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
		LDA GameData::btnDown
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
@check_jump:                 ; can only start a new jump from the ground
		LDA GameData::btnPressed
		AND #_BUTTON_A
		BNE @begin_jump            ; branch if a new jump is detected
		LDA #0
		STA velocityY              ; dont move if on the ground and not jumping ; this can be changed for colision implemenetations?
		STA velocityY+1
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
@horizontal_boost:
		; don't apply horizontal boost if the player is standstill
		LDA velocityX
		BEQ @airborne 
		LDA velocityX+1
		BEQ @airborne
		; add vertical velocity boost in heading direction
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
		JSR update_jump_velocity
		JSR apply_velocity_y        ; these are not in update so an early exit can save cpu cycles
		JSR bound_position_y
		RTS
.endproc

.PROC update_jump_velocity ; this updates mid air velocity
		; Determine if velocity decelerates slow or fest based on button hold
		LDY #0                      ; lookup table offset for BASE_FALL_SPEED
		BIT playerFlags
		BPL @decelerate             ; branch if held jump isn't set
		LDA GameData::btnDown
		AND #_BUTTON_A
		BEQ @newly_fast             ; branch if A isn't held
		; check velocity threshold

		LDA velocityY+1
		CMP #Jump::DECELERATION_THRESHOLD
		BPL @newly_fast             ; branch if velocity is past threshold
		LDY #2                      ; SLOW_FALL_SPEED offset
		JMP @decelerate
@newly_fast:                  ; for first times using fast falling set flag
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
		RTS
fall_speeds:
		.BYTE <Jump::BASE_FALL_DECCEL, >Jump::BASE_FALL_DECCEL
		.BYTE <Jump::SLOW_FALL_DECCEL, >Jump::SLOW_FALL_DECCEL
.ENDPROC

.PROC apply_velocity_y ; add current velocity to the position
		CLC
		LDA velocityY     ; low byte
		ADC positionY     ; add signed velocity low
		STA positionY
		LDA velocityY+1   ; high byte
		ADC positionY+1   ; add carry
		STA positionY+1
		RTS
.ENDPROC

.PROC bound_position_y
		LDA positionY+1

@check_landing: ; This will need to be changed for collision
		CMP #Jump::FLOOR_HEIGHT ; remember y increases downward :)
		BCS @land
		RTS
@land:
		; clamp position to the landing height
		LDA #00
		STA positionY ; clear low byte
		LDA #Jump::FLOOR_HEIGHT
		STA positionY+1
		LDA #MotionState::Still ; update motion state, idk how this will
														; end up working with movement
		STA motionState
		RTS
.ENDPROC
