;
; neschael
; lib/scrolling/camera/s
;
; handles the ammount to scroll the camera and lookahead based
; needs to be ran after both x and y collision is complete
;

.INCLUDE "lib/player/player.inc"
.INCLUDE "lib/game/gameData.inc"
.INCLUDE "data/levels/levelData.inc"

.EXPORT update_camera

	MIDPOINT = $80             ; pixel position of the middle of the screen
	TARGET_OFFSET_LEFT        = $DC  ; -35, max pixel offset for lookahead left
	TARGET_OFFSET_RIGHT       = $23  ;  35
		; pixel thresholds for the left and right of the stage, if passed the offset will be cleared
			; these should always be bigger than target offsets
	RESET_OFFSET_THRESH_LEFT  = $32  ; 50
	RESET_OFFSET_THRESH_RIGHT = $CD  ; 255 - 50

	; unsafe memory constants (in scratch memory)
	tmpProposedScroll   = $00  ; signed, proposed scroll ammount in pixels before bounding
	tmpScrollOvershoot  = $01  ; 16 bit, ammount scroll overshoots the boundary

.PROC update_camera
		; check if we have moved past the midpoint
	CLC
	LDA positionX+1
	ADC lookaheadOffset
	SEC
	SBC #MIDPOINT
	BEQ @no_scroll
	PHP	; push results to the stack for later

	BIT velocityX+1			; check overshoot and lookahead based on direction
	BMI @left	
@right:
	PLP
	BCC @no_scroll                  ; proposed position < midpoint, happens at level start, don't scroll
	STA tmpProposedScroll

	LDA lookaheadOffset
	CMP #TARGET_OFFSET_RIGHT
	BEQ @end_threshold_check 
		; see if we are moving fast enough to warrent lookahead
	LDA velocityX+1
	BEQ @end_threshold_check

	INC lookaheadOffset
	INC tmpProposedScroll

	JMP @end_threshold_check
@left:
	PLP
	BCS @no_scroll                 ; proposed position >= midpoint, happens at level end, don't scroll
	STA tmpProposedScroll

	LDA lookaheadOffset
	CMP #TARGET_OFFSET_LEFT
	BEQ @end_threshold_check 
		; see if we are moving fast enough to warrent lookahead
	LDA velocityX+1
	CMP #$FF
	BEQ @end_threshold_check

	DEC lookaheadOffset
	DEC tmpProposedScroll

@end_threshold_check: ; subtract the ammount scrolled from deltaX
	JSR bound_scroll

@update_position:
	LDA positionX+1
	SEC
	SBC scrollAmount
	STA positionX+1

@no_scroll:
	RTS	
.ENDPROC

	; see if the proposed scroll ammount hits the borders of the current level
.PROC bound_scroll
		; preload acc
	LDA tmpProposedScroll
	CLC
		; see what to bound based on direction
	BIT velocityX+1			
	BMI @difference_zero
@difference_level_end: ; find the difference betweent the screenPos and end of the level
	ADC screenPosX
	STA tmpScrollOvershoot							; low byte, ammount overshot
	LDA screenPosX+1
	ADC #$00
	STA tmpScrollOvershoot+1							; high byte, background index

		; compare high byte to the level size
	LDY #LEVEL_SIZE_OFFSET
	LDA (levelPtr), Y
	CMP tmpScrollOvershoot+1
	BNE @apply_scroll ; branch if different, (no bounding)
		; if we are close to the very end of the level, reset the lookahead to prevent teleporting
	LDA #RESET_OFFSET_THRESH_RIGHT
	CMP positionX+1
	BCS @remove_overshoot
	LDA #$00
	STA lookaheadOffset

	JMP @remove_overshoot

@difference_zero:
	ADC screenPosX
	STA tmpScrollOvershoot    ; low byte, ammount we may have overshot by 
	LDA screenPosX+1
	ADC #$FF
	BPL @apply_scroll        ; test sign of difference high byte, branch if no overshoot
			; if we are close to the very start of the level, reset the lookahead to prevet teleporting
	LDA #RESET_OFFSET_THRESH_LEFT
	CMP positionX+1
	BCC @remove_overshoot
	LDA #$00
	STA lookaheadOffset

@remove_overshoot:
		; remove the overshoot from the proposed scroll
	LDA	tmpProposedScroll 
	SEC
	SBC tmpScrollOvershoot
	STA scrollAmount
  RTS

@apply_scroll:
	LDA tmpProposedScroll
	STA scrollAmount
	RTS
.ENDPROC