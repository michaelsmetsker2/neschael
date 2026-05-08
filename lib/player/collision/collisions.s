;   
; nechael
; lib/player/collision/collisions.s
;
; collision index and the code that executes when the player colides with different types of objects
;

.INCLUDE "lib/player/collision/collision.inc"
.INCLUDE "lib/player/player.inc"
.INCLUDE "lib/game/gameData.inc"

.IMPORT find_collision ; an additional collision check is needed sometimes for slopes

.EXPORT collision_index_x_low
.EXPORT collision_index_x_high
.EXPORT collision_index_y_low
.EXPORT collision_index_y_high

collision_index_x_low:
	.BYTE <(Empty::col_x-1)
	.BYTE <(LevelEnd::both-1)
	.BYTE <(SteepSlope::Up::col_x-1)
	.BYTE <(ShallowSlope::Up::col_x-1)
	.BYTE <(SteepSlope::Down::col_x-1)
	.BYTE <(ShallowSlope::Down::col_x-1)
	.BYTE $FF
	.BYTE	$FF 
	.BYTE <(Solid::col_x-1)

collision_index_x_high:
	.BYTE >(Empty::col_x-1)
	.BYTE >(LevelEnd::both-1)
	.BYTE >(SteepSlope::Up::col_x-1)
	.BYTE >(ShallowSlope::Up::col_x-1)
	.BYTE >(SteepSlope::Down::col_x-1)
	.BYTE >(ShallowSlope::Down::col_x-1)
	.BYTE $FF
	.BYTE $FF
	.BYTE >(Solid::col_x-1)


collision_index_y_low:
	.BYTE <(Empty::col_y-1)
	.BYTE <(LevelEnd::both-1)
	.BYTE <(SteepSlope::Up::col_y-1)
	.BYTE <(ShallowSlope::Up::col_y-1)
	.BYTE <(SteepSlope::Down::col_y-1)
	.BYTE <(ShallowSlope::Down::col_y-1)
	.BYTE $FF
	.BYTE $FF
	.BYTE <(Solid::col_y-1)

collision_index_y_high:
	.BYTE >(Empty::col_y-1)
	.BYTE >(LevelEnd::both-1)
	.BYTE >(SteepSlope::Up::col_y-1)
	.BYTE >(ShallowSlope::Up::col_y-1)
	.BYTE >(SteepSlope::Down::col_y-1)
	.BYTE >(ShallowSlope::Down::col_y-1)
	.BYTE $FF
	.BYTE $FF
	.BYTE >(Solid::col_y-1)

  ; ID: 0, no collision
.SCOPE Empty
  .PROC col_x
    RTS
  .ENDPROC

  .PROC col_y
			; if the player is currently on a slope
		LDA motionState
		CMP #SLOPE_STATES_START
		;BCS @slope_check
	
      ; sets the motionState, for edge case for walking off a platform
  	LDA #MotionState::Airborne
		STA motionState
		RTS ; FIXME 

	@slope_check:	
		INC $E0 ; FIXME DEBUG

		LDA tmpCollisionPointY
		AND #%11111000
		STA tmpCollisionPointY

		INC tmpCollisionPointY
		

		INC	tmpProposedPosFinal+1 
		JMP ShallowSlope::Up::col_y


		JSR find_collision

	@determine_slope:
		LDA $0F
		BEQ @reset_state ; just air, quick return for most cases

		CMP #CollisionType::steepSlopeUp
		BEQ @steep_up
		CMP #CollisionType::shallowSlopeUp
 		BEQ @shallow_up
		CMP #CollisionType::steepSlopeDown
		BEQ @steep_down
		CMP #CollisionType::shallowSlopeDown
		BEQ @shallow_down	

			; fall through on unknown
	@reset_state: ; set the motion state to grounded and return
	  LDA #MotionState::Airborne
    STA motionState
		RTS

	@steep_up:
		INC	tmpProposedPosFinal+1 
		JMP SteepSlope::Up::col_y
	@shallow_up:
		INC	tmpProposedPosFinal+1 
		JMP ShallowSlope::Up::col_y
	@steep_down:
		INC	tmpProposedPosFinal+1 
		JMP SteepSlope::Down::col_y
	@shallow_down:
		INC	tmpProposedPosFinal+1 
		JMP ShallowSlope::Down::col_y


  .ENDPROC
.ENDSCOPE

  ; ID: 1, ; triggers the end of the level
.SCOPE LevelEnd
  .PROC both

		; FIXME unfinished make it increment level not just set to 1
		LDA #%00010000
		ORA gameFlags
		STA gameFlags

		LDA #$01
		STA levelId

		RTS
  .ENDPROC
.ENDSCOPE

	; ID: 2-3 45 degree slope collision up and down
.SCOPE SteepSlope
	.SCOPE Up 
		.PROC col_x
			INC $E0
				; if we are currently grounded and colliding with a slope, set the motionState to the slope
			LDA motionState
			STA $E1
			CMP #MotionState::Grounded
			BNE @done

			LDA #MotionState::SteepSlopeDown
			STA motionState
		@done:
			RTS	
		.ENDPROC

		slope_offset:
			.BYTE $08, $07, $06, $05, $04, $03, $02, $01, $00

		.PROC col_y
				; find the correct y offset relative to the players current x position
			LDA tmpCollisionPointX
			AND #%00000111
			TAY
			LDA slope_offset, Y
			STA $11

				; zero velocity and fractional position
			LDA #$00
			STA velocityY
			STA velocityY+1
			STA tmpProposedPosFinal

		@clamp:
			LDA tmpProposedPosFinal+1
			AND #%11111000
			CLC
			ADC $11
			STA tmpProposedPosFinal+1
				; set motion state in case of a land
			LDA #MotionState::SteepSlopeUp
			STA motionState
			RTS
		.ENDPROC

	.ENDSCOPE

	.SCOPE Down
		.PROC col_x
				; if we are currently grounded and colliding with a slope, set the motionState to the slope
			LDA motionState
			CMP #MotionState::Grounded
			BNE @done

			LDA #MotionState::SteepSlopeDown
			STA motionState
		@done:
			RTS	
		.ENDPROC

		slope_offset:
			.BYTE $00, $01, $02, $03, $04, $05, $06, $07, $08, $09

		.PROC col_y
				; find the correct y offset relative to the players current x position
			LDA tmpCollisionPointX
			SEC
			SBC #PLAYER_RIGHT_FOOT_OFFSET
			AND #%00000111
			TAY
			LDA slope_offset, Y
			STA $11

				; zero velocity and fractional position
			LDA #$00
			STA velocityY
			STA velocityY+1
			STA tmpProposedPosFinal

		@clamp:
			LDA tmpProposedPosFinal+1
			AND #%11111000
			CLC
			ADC $11
			STA tmpProposedPosFinal+1
				; set motion state in case of a land
			LDA #MotionState::SteepSlopeDown
			STA motionState
			RTS
		.ENDPROC
	.ENDSCOPE
.ENDSCOPE

	; ID: 4-5 30ish degree slope collision up and down ( screen stretching fucks with angle :))
.SCOPE ShallowSlope
	.SCOPE Up
		.PROC col_x
				; if we are currently grounded and colliding with a slope, set the motionState to the slope
			LDA motionState
			CMP #MotionState::Grounded
			BNE @done

			LDA #MotionState::SteepSlopeDown ; opposite direction to trigger an above check
			STA motionState
		@done:
			RTS	
		.ENDPROC

		slope_offset:
			.BYTE $08, $07, $06, $05, $04, $03, $02, $01, $00

		.PROC col_y
				; find the correct y offset relative to the players current x position
			LDA tmpCollisionPointX
			AND #%00001111
			LSR A
			TAY
			LDA slope_offset, Y
			STA $11

				; zero velocity and fractional position
			LDA #$00
			STA velocityY
			STA velocityY+1
			STA tmpProposedPosFinal

		@clamp:
			LDA tmpProposedPosFinal+1
			AND #%11111000
			CLC
			ADC $11
			STA tmpProposedPosFinal+1
				; set motion state in case of a land
			LDA #MotionState::ShallowSlopeUp
			STA motionState
			RTS
		.ENDPROC
	.ENDSCOPE

	.SCOPE Down
	.PROC col_x
				; if we are currently grounded and colliding with a slope, set the motionState to the slope
			LDA motionState
			CMP #MotionState::Grounded
			BNE @done

			LDA #MotionState::SteepSlopeUp ; opposite direction to trigger an above check
			STA motionState
		@done:
			RTS	
		.ENDPROC

		slope_offset:
			.BYTE $00, $01, $02, $03, $04, $05, $06, $07, $08

		.PROC col_y
				; find the correct y offset relative to the players current x position
			LDA tmpCollisionPointX
			SEC
			SBC #PLAYER_RIGHT_FOOT_OFFSET
			AND #%00001111
			LSR A
			;TAY
			;LDA slope_offset, Y
			STA $11

				; zero velocity and fractional position
			LDA #$00
			STA velocityY
			STA velocityY+1
			STA tmpProposedPosFinal

		@clamp:
			LDA tmpProposedPosFinal+1
			AND #%11111000
			CLC
			ADC $11
			STA tmpProposedPosFinal+1
				; set motion state in case of a land
			LDA #MotionState::ShallowSlopeDown
			STA motionState
			RTS
		.ENDPROC

	.ENDSCOPE
.ENDSCOPE

  ; ID: 8, solid ground
.SCOPE Solid
  .PROC col_x

	    ; find proposed world position
		CLC
		LDA tmpProposedPosFinal+1
		ADC screenPosX

    BIT velocityX+1
    BPL @right       			; branch based on direction
  @left:
		; find ammount overshoot tile boundary
		CLC
		ADC #$FF
		AND #%00000111
		STA $16
		; invert amount for signed math
		SEC
		LDA #$07
		SBC $16
		STA $16 
		
		; remove amount overshot from deltaX
		CLC
    LDA tmpDeltaX+1
		ADC $16
    STA tmpDeltaX+1

    JMP @done
  @right:
		; find ammount overshot tile boundary
		AND #%00000111
		STA $16
		DEC $16	; -1 since player is 7 px wide

		; remove ammount overshot from deltaX
		SEC
		LDA tmpDeltaX+1
		SBC $16 
		STA tmpDeltaX+1		

  @done:
		; zero velocity
		LDA #$00
		STA velocityX
		STA velocityX+1
    RTS
  .ENDPROC

  .PROC col_y
			; return if already grounded
		LDA motionState
		CMP #MotionState::Grounded
		BEQ @return

		LDX velocityY+1 ; store to find direction after zeroing
    	; zero velocity and fractional position
    LDA #$00
    STA velocityY
    STA velocityY+1
    STA tmpProposedPosFinal
	@check_rising: ; see if the player if rising of falling
		TXA 										; sets negative flag with velocity stored in X
		BPL @land

	@hit_head:
			; clamp to top of tile (mask bottom 3 bits)
	  LDA tmpProposedPosFinal+1
    AND #%11111000
		CLC
		ADC #$08									; move down one tile full tile
		STA tmpProposedPosFinal+1
		RTS

  @land:
			; clamp position to top of tile (mask bottom 3 bits)
    LDA tmpProposedPosFinal+1
    AND #%11111000
		STA tmpProposedPosFinal+1
			; clamp tmpPositionX to match position 
		LDA tmpCollisionPointY
		AND #%11111000
		STA tmpCollisionPointY

	@secondary_slope_check:
			; determine if we check 1px above or below the players feet for a slope
		SEC
		LDA motionState
		SBC #SLOPE_STATES_START ; this will give use the index of slope we are on
		BCC @check_above				; check above if not on a slope at all

		LSR											; /2  0 if incline 1 if decline
		ROR A
		STA $10									; MSB is 1 if decline

		LDA velocityX+1
		EOR $10
		BMI @check_below			  ; if the MSB differ, player is going up a slope
		
	@check_above:
			; check 1px above players feet if going up a slope or landing
		DEC tmpCollisionPointY
		JMP @find_secondary_collision

	@check_below:
			; check 1px below if the player is going down a slope
		INC tmpCollisionPointY

	@find_secondary_collision:
			; the current collision point is the last thing checked (lower right foot)
		JSR find_collision
		STA $0F

			; only check the left foot if a slope isn't found on the first one
		SEC
		SBC #SLOPE_COLL_START
		CMP #SLOPE_VARIATIONS
		BCC @determine_slope ; containes 0-3 (a slope ID) 

			; look for a slope at the left foot
		SEC
		LDA tmpCollisionPointX
		SBC #PLAYER_RIGHT_FOOT_OFFSET
		STA tmpCollisionPointX
		BCS :+
		DEC tmpCollisionPointX+1
	:
			; store the collision with the higher priority
		JSR find_collision
		STA $0F

	@revert_collision_point: ; returns collision point x back to what it was before
			; reset tmpCollisionPointX to the right foot as slope calculations expect that
		CLC
		LDA tmpCollisionPointX
		ADC #PLAYER_RIGHT_FOOT_OFFSET
		STA tmpCollisionPointX
		BCS :+
		INC tmpCollisionPointX+1
	:

	@determine_slope:
		LDA $0F
		BEQ @reset_state ; just air, quick return for most cases

		CMP #CollisionType::steepSlopeUp
		BEQ @steep_up
		CMP #CollisionType::shallowSlopeUp
 		BEQ @shallow_up
		CMP #CollisionType::steepSlopeDown
		BEQ @steep_down
		CMP #CollisionType::shallowSlopeDown
		BEQ @shallow_down	

			; fall through on unknown
	@reset_state: ; set the motion state to grounded and return
	  LDA #MotionState::Grounded
    STA motionState
	@return:
		RTS

	@steep_up:
		DEC	tmpProposedPosFinal+1 
		JMP SteepSlope::Up::col_y
	@shallow_up:
		DEC	tmpProposedPosFinal+1 
		JMP ShallowSlope::Up::col_y
	@steep_down:
		DEC	tmpProposedPosFinal+1 
		JMP SteepSlope::Down::col_y
	@shallow_down:
		DEC	tmpProposedPosFinal+1 
		JMP ShallowSlope::Down::col_y

  .ENDPROC
.ENDSCOPE