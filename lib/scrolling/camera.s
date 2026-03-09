;
; neschael
; lib/scrolling/camera/s
;
; handles the ammount to scroll the camera and lookahead based
; needs to be ran after both x and y collision is complete
;

.INCLUDE "lib/player/player.inc"
.INCLUDE "lib/game/gameData.inc"
.INCLUDE "lib/game/levelData.inc"

.EXPORT update_camera

	MIDPOINT = $80             ; pixel position of the middle of the screen
	TARGET_OFFSET_LEFT = $E2   ; -30, max pixel offset for lookahead left
	TARGET_OFFSET_RIGHT = $1E  ; 30

	; unsafe memory constants (in scratch memory)
	tmpProposedScroll   = $00 ; signed,       proposed scroll ammount in pixels before bounding


.PROC update_camera

	; see if we have overshot the midpoint
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
.if 0
  CLC
  LDA tmpProposedScroll
  ADC lookaheadOffset
    ; should never overflow
  ADC screenPosX
  STA $01   ; low byte, amount into new nametable
  LDA screenPosX+1
  ADC #$00
  STA $02   ; high byte, nametable index
  
  	; compare high byte to the level size
	LDY #LEVEL_SIZE_OFFSET
	LDA (levelPtr), Y
	CMP $2
	BNE @done ; branch if defferent, (no bounding)
    ; we are overshot
    ; remove ammount overshot from the lookahead


	JMP @remove_overshoot

  
@done:
  RTS
  .ENDIF


; FIXME 
	LDA tmpProposedScroll
	CLC

	BIT velocityX+1			; see what to bound based on direction
	BMI @difference_zero
@difference_level_end: ; find the difference betweent the screenPos and end of the level
	ADC screenPosX
	STA $11							; low byte, ammount overshot
	LDA screenPosX+1
	ADC #$00
	STA $12							; high byte, background index

	; compare high byte to the level size
	LDY #LEVEL_SIZE_OFFSET
	LDA (levelPtr), Y
	CMP $12
	BNE @apply_scroll ; branch if defferent, (no bounding)

	JMP @remove_overshoot

@difference_zero:
  ;LDA tmpProposedScroll
	;CLC
	ADC screenPosX
	STA $11                 ; low byte, ammount we may have overshot by 
	LDA screenPosX+1
	ADC #$FF
	BPL @apply_scroll       ; test sign of difference high byte, branch if no overshoot

@remove_overshoot:
	LDA lookaheadOffset
	SEC
	SBC $11 					      ; subtract the overshoot from the proposed scroll
	STA lookaheadOffset
  LDA #$00
  STA scrollAmount
  RTS

@apply_scroll:
	LDA tmpProposedScroll
	STA scrollAmount
	RTS
.ENDPROC