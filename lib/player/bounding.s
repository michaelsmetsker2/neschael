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

		; pixel values where the screen will scroll instead of move the player
	SCROLL_THRESHOLD_LEFT  = $55
	SCROLL_THRESHOLD_RIGHT = $AB

	PLAYER_HEAD_OFFSET     = $0  ; zero pixels to players head
	PLAYER_FEET_OFFSET     = $08 ; 8 pixels to players feet
		
	; unsafe memory constants (in scratch memory)

	tmpDeltaX           = $00 ; signed 8.8,   proposed position change in either X, can change based on collision
	tmpProposedScroll   = $04 ; signed,       proposed scroll ammount in pixels before bounding

	tmpProposedPosFinal = $02 ; unsigned 8.8, proposed position after velocity is applied, high byte is mainly used


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

	; calculate the proposed end position of the change
	CLC
	LDA positionX    ; simple 16 bit addition
	ADC tmpDeltaX
	STA tmpProposedPosFinal
	LDA positionX+1
	ADC tmpDeltaX+1
	STA tmpProposedPosFinal+1

	; TODO here would be collision checking,
	; a collision would edit deltaX and zero velocity

	JSR check_scroll

		; add deltax to the position, simple 16 bit addition
	CLC
	LDA positionX
	ADC tmpDeltaX
	STA positionX
	LDA positionX+1
	ADC tmpDeltaX+1
	STA positionX+1
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

	LDA tmpProposedPosFinal+1
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
  STA $50
  ; set the collision pointer to the correct collider table

  JSR enact_collision_y
  LDA $50



; set the pointer and preserver the accumulator

  BEQ @apply_velocity
; TODO this is temporary, we will have a lookup table of collision functions?
@collide:
	; this temporarily only does solid collisions
	; zero velocity
	LDA #$00
	STA velocityY
	STA velocityY+1
	; clamp position
	LDA #$00
	STA tmpProposedPosFinal

	LDA tmpProposedPosFinal+1
	AND #%11111000					; allign to the top of the tile
	SEC
	SBC #$01						    ; move up one pixel
	STA tmpProposedPosFinal+1

	; set motion state
	LDA #MotionState::Still
	STA motionState
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
	CLC                       ; player pos plus world pos
	LDA screenPosX
	ADC positionX+1           ; high byte is pixel position
	STA tmpCollisionPointX
	LDA screenPosX+1
	ADC #$00									; add carry
	STA tmpCollisionPointX+1

	; set Y offset depending on the sign of the velocity
	LDA #PLAYER_FEET_OFFSET     ; used if player is grounded or moving down
	BIT velocityY+1
	BPL @add_offset_y
	LDA motionState
	CPY MotionState::Airborne
	BNE @add_offset_y
	LDA #PLAYER_HEAD_OFFSET			; player is airborne and moving up
@add_offset_y:	
	CLC
	LDA tmpProposedPosFinal+1 ; highy byte is pixel position
	ADC #$08									; offset to toes
	STA tmpCollisionPointY

	JSR find_collision ; load accumulator with collision data
  STA $1F
  
@check_collision_right:
	CLC
	LDA tmpCollisionPointX
	ADC #$08 									; offest to right foot
	STA tmpCollisionPointX
	LDA tmpCollisionPointX+1
	ADC #$00
	STA tmpCollisionPointX+1 ; add carry

	JSR find_collision       ; load accumulator with data again
  TAX
  CMP $1F                  ; see which check has the higher prioriy collision
  BCS @done                ; branch if accumulator has the highest pri already
  LDA $1F
  RTS
@done:
  TXA ; BUG it is a mystery why i have to TAX and TXA it should work without but alas z 
	RTS
.ENDPROC