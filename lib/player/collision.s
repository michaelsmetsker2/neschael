;   
; nechael
; lib/player/collision.s
;
; subroutines containing logic concerning what happens when a collision is detected 
;

.EXPORT find_collision

.IMPORT background_index ; TODO this is temp until level pointers
.IMPORT metatiles

	tmpTilePointer = $08 ; pointer to the metatile being checked for collision

  ; these are defined and set in the bounding.s file, they are not memory safe. only for use in find_collision
	tmpCollisionPointX  = $05 ; unsigned 16,  world coords at which to find the collision type
	tmpCollisionPointY  = $07 ; unsigned,     screen coords at which to find the collision type 

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


; lookup table of collision reactions for both x and y interactions