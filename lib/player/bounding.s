;
; neschael
; lib/player/bounding.s
;
; handles bounding an collision for the player
;

.SEGMENT "CODE"

.INCLUDE "lib/game/gameData.inc"
.INCLUDE "lib/player/player.inc"

.IMPORT background_index ; TODO this is temp until level pointers
.IMPORT metatiles

.EXPORT update_position_x
.EXPORT update_position_y

		; pixel values where the screen will scroll instead of move the player
	SCROLL_THRESHOLD_LEFT  = $55
	SCROLL_THRESHOLD_RIGHT = $AB
		
	tmpDeltaX           = $00 ; signed 8.8,   proposed position change in either X, can change based on collision

	tmpProposedPosFinal   = $02 ; unsigned 8.8, proposed position after velocity is applied, high byte is mainly used

	tmpProposedScroll   = $04 ; signed,       proposed scroll ammount in pixels before bounding

	tmpCollisionPointX  = $05 ; unsigned 16,  world coords at which to find the collision type
	tmpCollisionPointY  = $07 ; unsigned,     screen coords at which to find the collision type 

	tmpTilePointer = $08 ; pointer to the metatile being checked for collision

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

.PROC update_position_y

	; find the proposed final position
	CLC
	LDA positionY
	ADC velocityY 				   	; add low bytes
	STA tmpProposedPosFinal
	LDA positionY+1      			; high bytes with carry
	ADC velocityY+1
	STA tmpProposedPosFinal+1 ; pixel position

	; see if we cross a tile boundary
	AND #%11111000 ; mask for just tile index
	STA $10
	LDA positionY+1
	AND #%11111000 ; original tile index
	CMP $10
	BEQ @skip_collision

@check_direction:
	BIT velocityY+1
	BPL @check_land_left ; check head or land depending on falling or rising
@check_head:
	; TODO
	JMP @skip_collision
@check_land_left:

	; set collision point to the correct location (left)
	; set X (unchanged)
	CLC                       ; player pos plus world pos
	LDA screenPosX
	ADC positionX+1           ; high byte is pixel position
	STA tmpCollisionPointX
	LDA screenPosX+1
	ADC #$00									; add carry
	STA tmpCollisionPointX+1
	; set Y (offset 8)
	CLC
	LDA tmpProposedPosFinal+1 ; highy byte is pixel position
	ADC #$08
	STA tmpCollisionPointY

	JSR find_collision ; load accumulator with collision data
	CMP #$00
	BNE @clamp_land
@check_land_right:


	; set collision point to the correct location (right)
	; get collision
	; update accordingly
	; TODO
	JMP @skip_collision

@clamp_land:
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
	SBC #$01								;	 move up one pixel
	STA tmpProposedPosFinal+1

	;	 set motion state
	LDA #MotionState::Still
	STA motionState

@skip_collision:

	LDA tmpProposedPosFinal
	STA positionY
	LDA tmpProposedPosFinal+1
	STA positionY+1 
	RTS
.ENDPROC

	; finds the collision data at tmpCollisionPoint and return with it in Accumulator
.PROC find_collision
	; TODO find the correct level

	; set the collision pointer to the correct background
	LDA tmpCollisionPointX+1 ; upper byte is the current backround
	ASL A                    ; *2 for byte offset
	TAY
	LDA background_index, Y
	STA tmpTilePointer
	INY
	LDA background_index, Y
	STA tmpTilePointer+1

	; set the collision pointer to the correct metcolumn
@find_meta_column:
	LDA tmpCollisionPointX  
	LSR A
	LSR A
	LSR A
	STA $0A ; store /8 tile index X for later
	LSR	A ; / 16 to get index of metacolumn
	ASL A ; * 2 for byte offset
	TAY
	LDA (tmpTilePointer), Y ; update the pointer
	TAX
	INY
	LDA (tmpTilePointer), Y
	STX tmpTilePointer
	STA tmpTilePointer+1

	; TODO temp until compressions find the correct metatile
@find_meta_tile:
	LDA tmpCollisionPointY
	LSR A
	LSR A
	LSR A
	STA $0B ; store /8 tile index Y for later
	LSR A ; / 16 for metatile index
	TAY
	
	LDA (tmpTilePointer), Y ; get the value of the metatile

	; update the pointer to the correct metatiles data
	ASL  										; *2 for byte offset
	TAY
	LDA metatiles, Y
	STA tmpTilePointer
	INY
	LDA metatiles, Y
	STA tmpTilePointer+1

@find_collision:
	  ; find the correct tile 	 
	CLC
	LDA $0A				 ; tile index X
	AND #%00000001 ; left or right column
	STA $0A

	LDA $0B				 ; tile index Y
	AND #%00000001 ; if we are in top or bottom
	ASL A 			   ; * 2 for bottom row offset
	CLC
	ADC $0A        ; add for tile offset
	ADC #$04			 ; add collision data offset for final offset
	TAY

    ; return collision
	LDA (tmpTilePointer), Y
	RTS
.ENDPROC