;   
; nechael
; lib/player/collision.s
;
; subroutines containing logic concerning what happens when a collision is detected 
;

.INCLUDE "lib/player/collision.inc"
.INCLUDE "lib/player/player.inc"
.INCLUDE "lib/game/gameData.inc"

.IMPORT background_index ; TODO this is temp until level pointers
.IMPORT metatiles

.EXPORT enact_collision_x
.EXPORT enact_collision_y
.EXPORT find_collision

	tmpTilePointer = $08 ; pointer to the metatile being checked for collision

; lookup table of collision reactions for both x and y interactions
.SCOPE CollisionsX
  empty: ;=============================================================================================
    RTS
		
  solid: ;=============================================================================================

		; world position mod 8, is the ammount into a tile
		CLC
		LDA tmpProposedPosFinal+1
		ADC screenPosX
		AND #%00000111
		STA $16

    BIT velocityX+1
    BPL @solid_right       ; branch if checking right
  @solid_left:
    SEC
    LDA #$08               ; subtract overshoot from 8 overshoot left
    SBC $16 
    STA $16

    CLC
    LDA tmpDeltaX+1
    ADC $16
    STA tmpDeltaX+1

    JMP @solid_done
  @solid_right:

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
  LDA #$03
  
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
    LDX tmpProposedPosFinal+1
		INX
		TXA
    AND #%11111000  					; allign to the top of the tile
    SEC
    SBC #$01   						    ; move up one pixel
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
		ADC #$07									; move down the player height minus one
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
	LSR	A   ; / 16 to get index of metacolumn
	ASL A   ; * 2 for byte offset
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
	SEC
	SBC #$10 ; TODO make this a const, this is compensating for the overscan
	LSR A
	LSR A
	LSR A
	STA $0B ; store /8 tile index Y for later
	LSR A ; / 16 for metatile index
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