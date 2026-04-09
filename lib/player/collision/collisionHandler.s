;   
; nechael
; lib/player/collision/collisionHandler.s
;
; subroutines concerning finding when and with what the player collides with
;

.INCLUDE "lib/player/collision/collision.inc"

.IMPORT dbufTile1
.IMPORT dbufTile2

.IMPORT metatile_index_low
.IMPORT metatile_index_high
.IMPORT mult_12

.IMPORT collision_index_x_low
.IMPORT collision_index_x_high
.IMPORT collision_index_y_low
.IMPORT collision_index_y_high

.EXPORT enact_collision_x
.EXPORT enact_collision_y
.EXPORT find_collision

	OVERSCAN_OFFSET = $20 ; offset y position in draw buffer by 32 pixels to account for overscan

	tmpTilePointer = $08 ; pointer to the metatile being checked for collision

	; uses rts trick to jump to the correct collision subproccess
	; BUG these will crash when jumping to uninitialized metatiles, could add a check to ensure this doesnt happen
.PROC enact_collision_x
	TAX
	LDA collision_index_x_high, x
	PHA 
	LDA collision_index_x_low, x
	PHA
	RTS
.ENDPROC
.PROC enact_collision_y
	TAX
	LDA collision_index_y_high, x
	PHA 
	LDA collision_index_y_low, x
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
	LDY #<dbufTile1 ; TODO this can be optimized (i beleive will need to count cycles) by using a small lookup table of both addresses
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
	LDA mult_12,Y	
	ADC tmpTilePointer
	STA tmpTilePointer
	BCC :+
	INC tmpTilePointer+1
:

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
	TAY
	LDA metatile_index_low, Y
	STA tmpTilePointer
	LDA metatile_index_high, Y
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