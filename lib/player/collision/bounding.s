;
; neschael
; lib/player/collision/bounding.s
;
; handles bounding an collision for the player
;

.SEGMENT "CODE"

.INCLUDE "lib/game/gameData.inc"
.INCLUDE "lib/player/player.inc"
.INCLUDE "lib/player/collision/collision.inc"

.IMPORT find_collision
.IMPORT enact_collision_x
.IMPORT enact_collision_y
.IMPORTZP SCRATCH

.EXPORT update_position_x
.EXPORT update_position_y
.EXPORT tmpDeltaX

	; pixel values where the screen will scroll instead of move the player
	SCROLL_THRESHOLD_LEFT        = $6A
	SCROLL_THRESHOLD_RIGHT       = $96

	PLAYER_HEAD_OFFSET           = $0  ; zero pixels to players head
	PLAYER_FEET_OFFSET           = $08 ; 7 pixels down to players feet, plus one to check ground
	PLAYER_FEET_RIGHT_OFFSET	   = $06 ; 6 pixels, the width of the player, acts as thbe player's right foot

; =====================================================================
; bound X
; =====================================================================

; adds the velocity to the position
.PROC update_position_x

	MIDPOINT_THRESHOLD  				 = $04 ; thes speed the player is going at to warrent a mid check
																			; 8 px per frame is the size of a tile.

	; copy velocity into deltaX
	LDA velocityX
	STA tmpDeltaX
	LDA velocityX+1
	STA tmpDeltaX+1  

	; see if velocity magnitude is over threshold to warent a mid check
	LDA velocityX+1
	BPL @check_speed
@negative:
	EOR #$FF ; two's compliment to invert sign
	CLC
	ADC #$01
@check_speed:
	CMP #MIDPOINT_THRESHOLD
	BCC @check_collision		; branch if under the threshold

@midpoint_check:	; check collision halfway through the movement to prevent skipping a tile
	; divide deltaX by two and check collision at the midpoint
	LDA tmpDeltaX+1        ; high byte
	ROL A                  ; shift sign bit into cary
	LDA tmpDeltaX+1
	ROR A                  ; shift right, pulling sign back
	STA $0D
	LDA tmpDeltaX          ; low byte
	ROR A
	STA $0C
		; set the proposed position to the midpoint
	CLC
	LDA positionX
	ADC $0C
	STA tmpProposedPosFinal
	LDA positionX+1
	ADC $0D
	STA tmpProposedPosFinal+1

	JSR check_collision_x 

	TAX 									; reset cpu flags
	BEQ @check_collision  ; use endpoint collision of no collision found

	LDA $0C					; update deltaX to the /2 values
	STA tmpDeltaX
	LDA $0D
	STA tmpDeltaX+1
	TXA ; put collision data back in accumulator for enacting
	JMP @enact_collision
@check_collision: ; check the collision at the endpoint

		; add position to deltax to find screen position endpoint
	CLC
	LDA positionX
	ADC tmpDeltaX
	STA tmpProposedPosFinal
	LDA positionX+1
	ADC tmpDeltaX+1
	STA tmpProposedPosFinal+1
	
	JSR check_collision_x
@enact_collision:
	JSR enact_collision_x

		; add deltaX to position
	CLC
	LDA positionX
	ADC tmpDeltaX
	STA positionX
	LDA positionX+1
	ADC tmpDeltaX+1
	STA positionX+1
	RTS
.ENDPROC

; check if the player collides with anything and return collision data
; returns the collision data in accumulator
.PROC check_collision_x

	PLAYER_LEFT_OFFSET    = $FF ; -1 pixel to the left of the character
	PLAYER_RIGHT_OFFSET   = $07 ; 7 pixels, the players width plus an extra for external checking	
	LOWER_OFFSET          = $07 ; vertical offset to lower horizontal check, 1 pixel above ground check
		
	; calculate the correct x offset based on direction
	LDA #PLAYER_RIGHT_OFFSET
	BIT velocityX+1
	BPL	@offset_position
	LDA #PLAYER_LEFT_OFFSET

@offset_position:						; add the offset to the position
	CLC
	ADC tmpProposedPosFinal+1
	STA $16			          		; store in scratch

@check_top:
	; load collision point x
	CLC
	LDA screenPosX
	ADC $16                   ; add the offset player position plus world position (for right side of the player)
	STA tmpCollisionPointX
	LDA screenPosX+1
	ADC #$00				          ; add carry
	STA tmpCollisionPointX+1
	
	; load y
	LDA positionY+1 ; hight byte of y position (pixel pos)
	STA tmpCollisionPointY

	JSR find_collision
	STA $1F

@check_bottom: ; check again at a lower position
	CLC
	LDA tmpCollisionPointY
	ADC #LOWER_OFFSET			; offset to lower check
	STA tmpCollisionPointY

	JSR find_collision
  CMP $1F                  ; see which check has the higher prioriy collision
  BCS @done                ; branch if accumulator has the highest pri already
  LDA $1F
@done:
	RTS
.ENDPROC

; =============================================================================
; bound Y
; =============================================================================

.PROC update_position_y
		; find the proposed final position
	CLC
	LDA positionY
	ADC velocityY 				   	; add low bytes
	STA tmpProposedPosFinal
	LDA positionY+1      			; high bytes with carry
	ADC velocityY+1
	STA tmpProposedPosFinal+1 ; pixel position

	JSR check_collision_y ; loads the accumulator with the collision data
  JSR enact_collision_y

  ; update the position to the proposed one
@apply_velocity:
	LDA tmpProposedPosFinal
	STA positionY
	LDA tmpProposedPosFinal+1
	STA positionY+1 
	RTS
.ENDPROC

; sets offsets and returns the highest priority collision value in the accumulator
.PROC check_collision_y
	
	tmpCollisionData = SCRATCH

@check_left: ; check collision at top left or bottom left
  ; player pos plus world pos
	CLC                       
	LDA screenPosX
	ADC positionX+1           ; high byte is pixel position
	STA tmpCollisionPointX
	LDA screenPosX+1
	ADC #$00									; add carry
	STA tmpCollisionPointX+1

	; load the accumulator with the appropriate Y offset (head of feet)
	LDA #PLAYER_FEET_OFFSET     ; used if player is grounded or moving down
	LDX motionState
	CPX #MotionState::Airborne
	BNE @add_offset_y
	BIT velocityY+1
	BPL @add_offset_y
  LDA #PLAYER_HEAD_OFFSET			; player is airborne and moving up
@add_offset_y:								; add the offset to the proposed position	
	CLC
	ADC tmpProposedPosFinal+1   ; add offset to the pixel position
	STA tmpCollisionPointY

	JSR find_collision ; load accumulator with collision data
  STA tmpCollisionData
  
@check_collision_right:
	CLC
	LDA tmpCollisionPointX
	ADC #PLAYER_FEET_RIGHT_OFFSET 									; offset to right side
	STA tmpCollisionPointX
	BCC :+	
	INC tmpCollisionPointX+1
:

	JSR find_collision       ; load accumulator with data again
  CMP tmpCollisionData     ; see which check has the higher prioriy collision
  BCS @done                ; branch if left foot has the higher priority
	LDA tmpCollisionData
@done:
	RTS
.ENDPROC