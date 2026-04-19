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
	.BYTE $FF
	.BYTE $FF
	.BYTE $FF
	.BYTE $FF
	.BYTE <(Solid::col_x-1)

collision_index_x_high:
	.BYTE >(Empty::col_x-1)
	.BYTE >(LevelEnd::both-1)
	.BYTE >(SteepSlope::Up::col_x-1)
	.BYTE >(SteepSlope::Down::col_x-1)
	.BYTE $FF
	.BYTE $FF
	.BYTE $FF
	.BYTE $FF
	.BYTE >(Solid::col_x-1)


collision_index_y_low:
	.BYTE <(Empty::col_y-1)
	.BYTE <(LevelEnd::both-1)
	.BYTE <(SteepSlope::Up::col_y-1)
	.BYTE <(SteepSlope::Down::col_y-1)
	.BYTE $FF
	.BYTE $FF
	.BYTE $FF
	.BYTE $FF
	.BYTE <(Solid::col_y-1)

collision_index_y_high:
	.BYTE >(Empty::col_y-1)
	.BYTE >(LevelEnd::both-1)
	.BYTE >(SteepSlope::Up::col_y-1)
	.BYTE >(SteepSlope::Down::col_y-1)
	.BYTE $FF
	.BYTE $FF
	.BYTE $FF
	.BYTE $FF
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
  
  ; ID: 1, solid ground
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
		  ; only do anything if airborne (land or bonk)
		LDA motionState
		CMP #MotionState::Airborne
		BNE @return

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
    LDA #MotionState::Still
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

  ; ID: 2, ; triggers the end of the level
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

	; ID: 3-4 45 degree slope collision up and down
.SCOPE SteepSlope
	.SCOPE Up 
		.PROC col_x
		
			RTS
		.ENDPROC

		.PROC col_y
			LDA tmpProposedPosFinal+1
			AND #%11111000
			STA $10
			LDA tmpCollisionPointX
			AND #%00000111
			ORA $10
			STA tmpProposedPosFinal+1

			RTS
		.ENDPROC

	.ENDSCOPE

	.SCOPE Down

		.PROC col_x
			RTS	
		.ENDPROC

		test_offset_down:
			.BYTE $00, $01, $02, $03, $04, $05, $06, $07

		.PROC col_y

			LDA tmpProposedPosFinal+1
			AND #%00000111
			STA $10

		.IF 0 ; conditionally snapping will just make higher speed collisions pass through more
			CMP #$06
			BCS @collide
			BCC @collide
		  LDA #MotionState::Airborne
			STA motionState
			RTS
		.ENDIF

		@collide:
			LDY tmpCollisionPointX
			INY
			INY
			TYA
			AND #%00000111
			STA $E0
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
			LDA #MotionState::Still
			STA motionState

		@done:
			RTS
		.ENDPROC

	.ENDSCOPE
.ENDSCOPE