;
; neschael
; lib/player/bounding.s
;
; handles bounding an collision for the player
;

    ; pixel values where the screen will scroll instead of move the player
  SCROLL_THRESHOLD_LEFT  = $55
  SCROLL_THRESHOLD_RIGHT = $AB
		
	tmpDeltaX         = $15 ; signed 8.8, proposed change in x direction, can change based on collision
	tmpProposedXFinal = $17 ; unsigned 8.8, high byte is mainly used

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

@check_scroll: 				 ; see of the proposed deltaX would pass the scroll thresholds
	LDA tmpProposedXFinal+1
	
	BIT tmpDeltaX+1
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
	; TODO check the ammount we want to scroll with the left edge of the level

	STA scrollAmount							 ; scroll the ammount the player overshot the threshold

@end_threshold_check: ; subtract the ammount scrolled from deltaX
	LDA tmpDeltaX+1
	SEC
	SBC scrollAmount
	STA tmpDeltaX+1

@no_scroll:
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

; End of lib/player/bounding.s