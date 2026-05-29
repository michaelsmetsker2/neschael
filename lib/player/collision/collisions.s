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
	.IF 0 ; FIXME determine if needed
			; if the player is currently on a slope
		LDA motionState
		CMP #SLOPE_STATES_START
		BCS @slope_check
	.ENDIF
      ; sets the motionState, for edge case for walking off a platform
  	LDA #MotionState::Airborne
		STA motionState
		RTS
		
	.IF 0 ; FIXME determine if needed
	@slope_check:
		LDA tmpCollisionPointY
		AND #%11111000
		STA tmpCollisionPointY

		INC tmpCollisionPointY
		

		INC	tmpProposedPosFinal+1 
		JMP ShallowSlope::Up::col_y


		JSR find_collision

	@determine_slope:
		LDA $0F
		BEQ @reset_state                ; just air, quick return for most cases

		DEC tmpProposedPosFinal+1       ; assume a slope is hit, correct if otherwise
	
		CMP #CollisionType::steepSlopeUp
		BNE :+
		JMP SteepSlope::Up::col_y
	:	CMP #CollisionType::shallowSlopeUp
 		BNE :+
		JMP ShallowSlope::Up::col_y
	:	CMP #CollisionType::steepSlopeDown
 		BNE :+
		JMP SteepSlope::Down::col_y
	:	CMP #CollisionType::shallowSlopeDown
		BNE :+
		JMP ShallowSlope::Down::col_y
	
	: INC tmpProposedPosFinal+1 		; correct position if assumed wrong
			; fall through on unknown
	@reset_state: ; set the motion state and return
	  LDA #MotionState::Airborne
    STA motionState
	@return:
		RTS
	.ENDIF

  .ENDPROC
.ENDSCOPE

  ; ID: 1, ; triggers the end of the level
.SCOPE LevelEnd
  .PROC both
			; since there are multiple collision checks this can run multiple times in a single frame
			; skip if the load level flag is already set to avoid incrementing the level multiple times
		LDA gameFlags
		AND #%00010000
		BNE @done

			; set the levelFlag
		LDA gameFlags
		ORA #%00010000
		STA gameFlags

			; load the next level in the index
		INC levelId

	@done:
		RTS
  .ENDPROC
.ENDSCOPE

	; ID: 2-3 45 degree slope collision up and down
.SCOPE SteepSlope
	.SCOPE Up 
		.PROC col_x
				; if we are currently grounded and colliding with a slope, set the motionState to the slope
			LDA motionState
			CMP #MotionState::Grounded
			BNE @done

			LDA #MotionState::SteepSlopeUp
			STA motionState
		@done:
			RTS	
		.ENDPROC

		.PROC col_y
				; find the correct y offset relative to the players current x position
			LDA tmpCollisionPointX
			AND #%00000111 ; 0-7
			EOR #%00000111 ; reverse order
			CLC
			ADC #$01       ; 1-8
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

		.PROC col_y
				; find the correct y offset relative to the players current x position
			LDA tmpCollisionPointX
			SEC
			SBC #PLAYER_RIGHT_FOOT_OFFSET
			AND #%00000111			; 0-7
			CLC
			ADC #$01						; 1-8
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

	; ID: 4-5 30ish degree slope collision up and down
.SCOPE ShallowSlope
	.SCOPE Up
		.PROC col_x
				; if we are currently grounded and colliding with a slope, set the motionState to the slope
			LDA motionState
			CMP #MotionState::Grounded
			BNE @done

			LDA #MotionState::ShallowSlopeUp
			STA motionState
		@done:
			RTS	
		.ENDPROC

		.PROC col_y
				; find the correct y offset relative to the players current x position
			LDA tmpCollisionPointX
			AND #%00001111
			LSR A								; 0-7
			EOR #%00000111      ; reverse order
			CLC
			ADC #$01            ; 1-8
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

			LDA #MotionState::SteepSlopeDown
			STA motionState
		@done:
			RTS	
		.ENDPROC

		.PROC col_y
				; find the correct y offset relative to the players current x position
			LDA tmpCollisionPointX
			SEC
			SBC #PLAYER_RIGHT_FOOT_OFFSET
			AND #%00001111
			LSR A							; 0-7
			CLC
			ADC #$01					; 1-8
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
			; clamp tmpPositionY to match position 
		LDA tmpCollisionPointY
		AND #%11111000
		STA tmpCollisionPointY

	@secondary_slope_check:
			; check 1px above players feet for a slope
		DEC tmpCollisionPointY
			; the current collision point is the last thing checked (lower right foot)
		JSR find_collision
		STA $0F

			; conditionally check the left foot if no slope was found
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
		BCS @determine_slope
		INC tmpCollisionPointX+1

	@determine_slope:
		LDA $0F
		BEQ @reset_state                ; just air, quick return for most cases

		DEC tmpProposedPosFinal+1       ; assume a slope is hit, correct if otherwise
	
		CMP #CollisionType::steepSlopeUp
		BNE :+
		JMP SteepSlope::Up::col_y
	:	CMP #CollisionType::shallowSlopeUp
 		BNE :+
		JMP ShallowSlope::Up::col_y
	:	CMP #CollisionType::steepSlopeDown
 		BNE :+
		JMP SteepSlope::Down::col_y
	:	CMP #CollisionType::shallowSlopeDown
		BNE :+
		JMP ShallowSlope::Down::col_y
	
	: INC tmpProposedPosFinal+1 		; correct position if assumed wrong
			; fall through on unknown
	@reset_state: ; set the motion state to grounded and return
	  LDA #MotionState::Grounded
    STA motionState
	@return:
		RTS

  .ENDPROC
.ENDSCOPE