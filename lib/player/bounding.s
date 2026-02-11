;
; neschael
; lib/player/bounding.s
;
; handles bounding an collision for the player
;

.SEGMENT "CODE"

.INCLUDE "lib/game/gameData.inc"
.INCLUDE "lib/player/player.inc"
.INCLUDE "lib/player/collision.inc"

.IMPORT find_collision
.IMPORT enact_collision_x
.IMPORT enact_collision_y

.EXPORT update_position_x
.EXPORT update_position_y
.EXPORT tmpDeltaX

	; pixel values where the screen will scroll instead of move the player
	SCROLL_THRESHOLD_LEFT        = $6A
	SCROLL_THRESHOLD_RIGHT       = $96

	PLAYER_HEAD_OFFSET           = $0  ; zero pixels to players head
	PLAYER_FEET_OFFSET           = $08 ; 7 pixels down to players feet, plus one to check ground
	PLAYER_FEET_RIGHT_OFFSET	   = $07 ; 7 pixels to the right foot of the player

	PLAYER_LEFT_OFFSET           = $FF ; -1 pixel to the left of the character
	PLAYER_RIGHT_OFFSET          = $08 ; 8 pixels, the players width plus an extra for external checking	
	PLAYER_LOWER_OFFSET          = $07 ; vertical offset to lower horizontal check, 1 pixel above ground check
		
	; unsafe memory constants (in scratch memory)
	tmpProposedScroll   = $04 ; signed,       proposed scroll ammount in pixels before bounding

; =====================================================================
; bound X
; =====================================================================

; adds the velocity to the position
.PROC update_position_x
	; copy velocity into deltaX
	LDA velocityX
	STA tmpDeltaX
	LDA velocityX+1
	STA tmpDeltaX+1  

	; see if velocity magnitude is over 8 to warent a mid check
	LDA velocityX+1
	BPL @positive

	EOR #$FF ; two's compliment to turn p0ositive
	CLC
	ADC #$01
@positive:
	CMP #08
	BCC @check_collision

@midpoint_check:	; check collision halfway through the movement to prevent skipping a tile
	; divide deltaX by two and check collision at the midpoint
	LDA tmpDeltaX+1        ; high byte
	ROL A                  ; shift sign bit into cary
	LDA tmpDeltaX+1        ; reload
	ROR A                  ; shift right, pulling sign back
	STA $08
	LDA tmpDeltaX          ; low byte
	ROR A                  ; shift right
	STA $07
	; set the proposed position to the midpoint
	CLC
	LDA positionX
	ADC $07
	STA tmpProposedPosFinal
	LDA positionX+1
	ADC $08
	STA tmpProposedPosFinal+1

	JSR check_collision_x

	TAX 									; reset cpu flags
	BEQ @check_collision  ; use endpoint collision of no collision found

	LDA $07					; update deltaX to the /2 values
	STA tmpDeltaX
	LDA $08
	STA tmpDeltaX+1

	TXA ; put collision data back in accumulator for enacting
	JMP @enact_collision

@check_collision: ; check the collision at the endpoint

	; add position do deltax to find screen position endpoint
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

	JSR check_scroll
	
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
	offset_x = $10	; the correct x ammount to offset the collision point from the characters position

	; calculate the correct x offset based on direction
	LDA #PLAYER_RIGHT_OFFSET
	BIT velocityX+1
	BPL	@offset_position
	LDA #PLAYER_LEFT_OFFSET
	STA offset_x								; store the offset

@offset_position:						; add the offset to the position
	CLC
	ADC tmpProposedPosFinal+1 ; BUG this may overflow when the player at the very end of a level?
	STA $16			          		; store in scratch

@check_top:
	; load collision point x
	CLC
	LDA screenPosX
	ADC $16                   ; add the offest player position plus world position (for right side of the player)
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
	ADC #PLAYER_LOWER_OFFSET			; offset to lower check
	STA tmpCollisionPointY

	JSR find_collision
  CMP $1F                  ; see which check has the higher prioriy collision
  BCS @done                ; branch if accumulator has the highest pri already
  LDA $1F
@done:
	RTS
.ENDPROC

; see if the proposed deltaX would pass the scroll thresholds
.PROC check_scroll
	LDA tmpProposedPosFinal+1
	
	BIT tmpDeltaX+1			; check threshold based on direction
	BMI @left_threshold 
@right_threshold:

	SEC
	SBC #SCROLL_THRESHOLD_RIGHT 
	BCC @no_scroll                 ; proposed position < right threshold, threshold not passed
	; TODO check the ammount we want to scroll with the end of the level

	STA scrollAmount							 ; scroll the ammount the player overshot the threshold
	JMP @end_threshold_check
@left_threshold:

	; ACC contains tmpProposedPosFinal+1
	SEC
	SBC #SCROLL_THRESHOLD_LEFT 
	BCS @no_scroll                 ; proposed position >= left threshold, threshold not passed

	STA tmpProposedScroll 				; see if we actually can scroll
	JSR bound_scroll

@end_threshold_check: ; subtract the ammount scrolled from deltaX
	LDA tmpDeltaX+1
	SEC
	SBC scrollAmount
	STA tmpDeltaX+1

@no_scroll:
	RTS	
.ENDPROC

; see if the proposed scroll ammount hits the borders of the current level
.PROC bound_scroll

	BIT tmpDeltaX+1			; see what to bound based on direction
	BMI @difference_zero

@difference_level_end: ; find the difference betweent the screenPos and end of the level

	;TODO set up this whole thing :)
	JMP @apply_scroll ; TEMP

	JMP @compare_difference

@difference_zero:
	CLC
	LDA screenPosX
	ADC tmpProposedScroll
	STA $11                 ; low byte, ammount we may have overshot by 
	LDA screenPosX+1
	ADC #$FF

@compare_difference:
	BPL @apply_scroll       ; test sign of difference high byte, branch if no overshoot
	LDA tmpProposedScroll
	SEC
	SBC $11 					      ; subtract the overshoot from the proposed scroll
	STA tmpProposedScroll

@apply_scroll:
	LDA tmpProposedScroll
	STA scrollAmount
	RTS
.ENDPROC

; =====================================================================
; bound Y
; =====================================================================

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
  STA $1F
  
@check_collision_right:
	CLC      
	LDA tmpCollisionPointX
	ADC #PLAYER_FEET_RIGHT_OFFSET 									; offest to right side
	STA tmpCollisionPointX
	LDA tmpCollisionPointX+1
	ADC #$00
	STA tmpCollisionPointX+1 ; add carry

	JSR find_collision       ; load accumulator with data again
  CMP $1F                  ; see which check has the higher prioriy collision
  BCS @done                ; branch if accumulator has the highest pri already
  LDA $1F
  RTS
@done:
	RTS
.ENDPROC