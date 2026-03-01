;   
; nechael
; lib/player/collision/collision.s
;
; subroutines containing logic concerning what happens when a collision is detected 
;

.INCLUDE "lib/player/collision/collision.inc"
.INCLUDE "lib/player/player.inc"
.INCLUDE "lib/game/gameData.inc"

.IMPORT background_index ; TODO this is temp until level pointers

.IMPORT dbufTile1
.IMPORT dbufTile2

.IMPORT metatiles
.IMPORT mult_13

.EXPORT enact_collision_x
.EXPORT enact_collision_y
.EXPORT find_collision

	OVERSCAN_OFFSET = $10 ; offset y position in draw buffer by 16 pixels to account for overscan

	tmpTilePointer = $08 ; pointer to the metatile being checked for collision

; lookup table of collision reactions for both x and y interactions
.SCOPE CollisionsX
  empty: ;=============================================================================================
    RTS
		
  solid: ;=============================================================================================
		; find proposed world position
		CLC
		LDA tmpProposedPosFinal+1
		ADC screenPosX

    BIT velocityX+1
    BPL @solid_right       			; branch based on direction
  @solid_left:
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

    JMP @solid_done
  @solid_right:
		; find ammount overshot tile boundary
		AND #%00000111
		STA $16

		; remove ammount overshot from deltaX
		SEC
		LDA tmpDeltaX+1
		SBC $16 
		STA tmpDeltaX+1		

  @solid_done:
		; zero velocity
		LDA #$00
		STA velocityX
		STA velocityX+1
    RTS

  hazard: ;============================================================================================
    RTS
.ENDSCOPE

.SCOPE CollisionsY
  empty: ;=============================================================================================
		LDA #MotionState::Airborne
		STA motionState
		RTS
		
  solid: ;=============================================================================================
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

  hazard: ;=============================================================================================
    RTS
.ENDSCOPE

collision_index_y:
	.WORD CollisionsY::empty-1
	.WORD CollisionsY::solid-1
	.WORD CollisionsY::hazard-1
collision_index_x:
	.WORD CollisionsX::empty-1
	.WORD CollisionsX::solid-1
	.WORD CollisionsX::hazard-1

  ; TODO this is mostly duplicate code 
	; uses rts trick to jump to the correct collision subproccess
	; BUG these will crash when jumping to uninitialized metatiles, could add a check to ensure this doesnt happen
.PROC enact_collision_x
	ASL
	TAX
	
	LDA collision_index_x+1, x
	PHA 
	LDA collision_index_x, x
	PHA
	RTS
.ENDPROC
.PROC enact_collision_y
	ASL
	TAX
	
	LDA collision_index_y+1, x
	PHA 
	LDA collision_index_y, x
	PHA
	RTS
.ENDPROC

	; finds the collision data at tmpCollisionPoint and return with it in Accumulator
.PROC find_collision

	; find draw buffer
	LDA tmpCollisionPointX+1
	AND #%00000001
	BNE @nt_1
@nt_0:
	LDY #<dbufTile1
	LDX #>dbufTile1
	JMP @set_buf
@nt_1:
	LDY #<dbufTile2
	LDX #>dbufTile2
@set_buf:
	STY tmpTilePointer
	STX tmpTilePointer+1

; set the collision pointer to the correct metcolumn
@find_meta_column:
	LDA tmpCollisionPointX  
	LSR A
	LSR A
	LSR A
	STA $0A ; store /8 tile index X for later
	LSR	A   ; / 16 to get index of metacolumn
	TAY
		;offset tilepointer to the correct column
	CLC
	LDA mult_13,Y	
	ADC tmpTilePointer
	STA tmpTilePointer
	LDA tmpTilePointer+1
	ADC #$00
	STA tmpTilePointer+1

@find_meta_tile: ; offset the pointer to the correct metatile in the column
	LDA tmpCollisionPointY
	SEC
	
	SBC #OVERSCAN_OFFSET ; compensating for overscan
	LSR A
	LSR A
	LSR A
	STA $0B ; store /8 tile index Y for later
	LSR A   ; / 16 for metatile index
	TAY
	
	LDA (tmpTilePointer), Y ; get the value of the metatile

	; update the pointer to the correct metatiles data
	ASL  					; *2 for byte offset
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
  ; return collision in ACC
	LDA (tmpTilePointer), Y
	RTS
.ENDPROC