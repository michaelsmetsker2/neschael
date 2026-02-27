;
; neschael
; lib/decompression/decompress.s
;
; decompresses lzss encoded level data into buffers in RAM
;


.EXPORT decompress_nametable

.INCLUDE "lib/game/gameData.inc"

	; memory constants
  tmpDataPointer  = $0   ; 16 bit pointer to input data
	tmpLength 			= $02	 ; scratch memory
	temp            = $03	 ; scratch memory

	; buffer locations
	buf    = $033E ; memory location of the buffer

.PROC decompress_nametable
	
	; before this proccess what needs to be set:
		; 0 or 1 in a register, what nametable to update

	; make pointer to the level's background index
	
	LDY #$00
	LDA (levelPtr),Y
	STA $04
	INY
	LDA (levelPtr),Y
	STA $05

	; TODO temp, sets tmpdata pointer to the first background in the level
	DEY
	LDA ($04),Y
	STA tmpDataPointer
	INY
	LDA ($04),Y
	STA tmpDataPointer+1

	JSR lzss_decompress

	RTS
.ENDPROC

.PROC lzss_decompress


	LDX #$00			 ; write index
	LDY #$00			 ; read offset
decomp_loop:
	LDA (tmpDataPointer),y   
	STA tmpLength		 ; store control byte intmpLengthh
	BMI literal		 ; if bit 7 is 1, literals are next
	BEQ done			 ; control byte 00 is end of stream marker
refference:			 ; control byte is a match
	INY
	BNE :+				 ; increment pointer if page boundary crossed
	INC tmpDataPointer+1
	:
	LDA (tmpDataPointer),y
	STY temp			 ; store read index
	TAY						 ; load the reference index
@ref_loop:
	; copy reference index to write index fortmpLengthh
	LDA buf,y
	STA buf,x
	INY
	INX
	DEC tmpLength
	BNE @ref_loop
	LDY temp			 ; restore and increment read offset
	INY
	BNE decomp_loop
	INC tmpDataPointer+1			 ; increment pointer if page boundary crossed
	JMP decomp_loop
literal:
	INY						 ; page safe increment
	BNE :+
	INC tmpDataPointer+1
	:
@lit_loop:
	; write tmpLength amount of literals to buffer
	LDA (tmpDataPointer),y
	STA buf,x
	INY
	BNE :+   		  ; page safe increment
	INC tmpDataPointer+1
	:
	INX
	INC tmpLength
	BNE @lit_loop ; loop intil literal count rolls over
	JMP decomp_loop
done:
	RTS
.ENDPROC
