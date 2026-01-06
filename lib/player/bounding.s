;
; neschael
; lib/player/bounding.s
;
; handles bounding an collision for the player
;

.SEGMENT "CODE"

.INCLUDE "lib/game/gameData.inc"
.INCLUDE "lib/player/player.inc"

.EXPORT update_position_x

		; pixel values where the screen will scroll instead of move the player
	SCROLL_THRESHOLD_LEFT  = $55
	SCROLL_THRESHOLD_RIGHT = $AB
		
	tmpDeltaX         = $15 ; signed 8.8, proposed change in x direction, can change based on collision
	tmpProposedXFinal = $17 ; unsigned 8.8, high byte is mainly used

	tmpProposedScroll = $10 ; signed, proposed scroll ammount in pixels before bounding

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
	STA tmpProposedXFinal
	LDA positionX+1
	ADC tmpDeltaX+1
	STA tmpProposedXFinal+1

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
	LDA tmpProposedXFinal+1
	
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

	LDA tmpProposedXFinal+1
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
