;   
; nechael
; lib/player/collision/collisions.s
;
; collision index and the code that executes when the player colides with different types of objects
;

.INCLUDE "lib/player/collision/collision.inc"
.INCLUDE "lib/player/player.inc"
.INCLUDE "lib/game/gameData.inc"

.EXPORT collision_index_x_low
.EXPORT collision_index_x_high
.EXPORT collision_index_y_low
.EXPORT collision_index_y_high

collision_index_x_low:
	.BYTE <(Empty::col_x-1)
	.BYTE <(LevelEnd::both-1)
	.BYTE <(SteepSlope::Up::col_x-1)
	.BYTE <(SteepSlope::Down::col_x-1)
	.BYTE <(ShallowSlope::Up::col_x-1)
	.BYTE <(ShallowSlope::Down::col_x-1)
	.BYTE $FF
	.BYTE <(SlopeAssist::col_x-1)
	.BYTE <(Solid::col_x-1)

collision_index_x_high:
	.BYTE >(Empty::col_x-1)
	.BYTE >(LevelEnd::both-1)
	.BYTE >(SteepSlope::Up::col_x-1)
	.BYTE >(SteepSlope::Down::col_x-1)
	.BYTE >(ShallowSlope::Up::col_x-1)
	.BYTE >(ShallowSlope::Down::col_x-1)
	.BYTE $FF
	.BYTE >(SlopeAssist::col_x-1)
	.BYTE >(Solid::col_x-1)


collision_index_y_low:
	.BYTE <(Empty::col_y-1)
	.BYTE <(LevelEnd::both-1)
	.BYTE <(SteepSlope::Up::col_y-1)
	.BYTE <(SteepSlope::Down::col_y-1)
	.BYTE <(ShallowSlope::Up::col_y-1)
	.BYTE <(ShallowSlope::Down::col_y-1)
	.BYTE $FF
	.BYTE <(Solid::col_y-1)
	.BYTE <(Solid::col_y-1)

collision_index_y_high:
	.BYTE >(Empty::col_y-1)
	.BYTE >(LevelEnd::both-1)
	.BYTE >(SteepSlope::Up::col_y-1)
	.BYTE >(SteepSlope::Down::col_y-1)
	.BYTE >(ShallowSlope::Up::col_y-1)
	.BYTE >(ShallowSlope::Down::col_y-1)
	.BYTE $FF
	.BYTE >(Solid::col_y-1)
	.BYTE >(Solid::col_y-1)

  ; ID: 0, no collision
.SCOPE Empty
  .PROC col_x
    RTS
  .ENDPROC

  .PROC col_y
      ; sets the motionState, for edge case of walking off a platform
  	LDA #MotionState::Airborne
		STA motionState
		RTS
  .ENDPROC
.ENDSCOPE
  ; ID: 1, ; triggers the end of the level
.SCOPE LevelEnd
  .PROC both

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
			RTS
		.ENDPROC

		.PROC col_y
			RTS
		.ENDPROC

	.ENDSCOPE

	.SCOPE Down
		.PROC col_x

		@check_grounded:
			LDA motionState
			CMP #MotionState::Grounded
			BNE @done 

			; nudge player 1 px to set them on the slope
			DEC positionY+1

			LDA #MotionState::SteepSlopeDown
			STA motionState
		@done:
			RTS	
		.ENDPROC

		test_offset_down:
			.BYTE $00, $01, $02, $03, $04, $05, $06, $07, $08

		.PROC col_y

				; find the correct y offset relative to the players current x position
			LDY tmpCollisionPointX
			INY      ; alligns position offset to the lookup table
			INY			 ; TODO remove these and just fix the lookup table ?
			TYA
			AND #%00000111
			TAY
			LDA test_offset_down, Y
			STA $11

				; zero velocity and fractional position
			LDA #$00
			STA velocityY
			STA velocityY+1
			STA tmpProposedPosFinal

		@clamp:
			LDA tmpProposedPosFinal+1
			AND #%11111000
			ORA $11
			STA tmpProposedPosFinal+1
				; set motion state in case of a land
			LDA #MotionState::SteepSlopeDown
			STA motionState

		@done:
			RTS
		.ENDPROC

	.ENDSCOPE
.ENDSCOPE

	; ID: 4-5 30ish degree slope collision up and down
.SCOPE ShallowSlope
	.SCOPE Up
		.PROC col_x
		@check_grounded:
			LDA motionState
			CMP #MotionState::Grounded
			BNE @done

			LDA tmpProposedPosFinal+1
			;AND #%00000111
			STA $E1
			CMP #$01
			BEQ @done
			; nudge player 1 px to set them on the slope
			DEC positionY+1

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

		@done:
			RTS
		.ENDPROC

	.ENDSCOPE
	 .SCOPE Down
		.PROC col_x
			RTS
		.ENDPROC

		.PROC col_y
			RTS
		.ENDPROC

	.ENDSCOPE
.ENDSCOPE


  ; ID: 7, slope assist semi permiable, no collision horizontally to help jumping on and walking up slopes
.SCOPE SlopeAssist
  .PROC col_x
		RTS

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

	; reuses solid ground y collision
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

		TXA 										; sets negative flag
		BMI @hit_head 					; branch depending on direction

  @land:
			; clamp position to top of tile
    LDA tmpProposedPosFinal+1
    AND #%11111000  					; allign to the top of the tile
		STA tmpProposedPosFinal+1
    	; set motion state
    LDA #MotionState::Grounded
    STA motionState
    RTS

	@hit_head:
			; clamp to bottom of tile
	  LDA tmpProposedPosFinal+1
    AND #%11111000
		CLC
		ADC #$08									; move down one tile 
		STA tmpProposedPosFinal+1
	@return:
		RTS

  .ENDPROC
.ENDSCOPE