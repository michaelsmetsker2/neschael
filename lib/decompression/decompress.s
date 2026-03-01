;
; neschael
; lib/decompression/decompress.s
;
; decompresses lzss encoded level data into buffers in RAM
;

.IMPORT dbufTile1
.IMPORT dbufAttr1
.IMPORT dbufTile2
.IMPORT dbufAttr2

.EXPORT decompress_nametable

.INCLUDE "lib/game/gameData.inc"

	; memory constants
  tmpDataPointer  = $0   ; 16 bit pointer to input data
	tmpLength 			= $02	 ; scratch memory
	temp            = $03	 ; scratch memory
	tmpBufferPtr    = $04  ; 16 bit pointer to the dbuffer to fill
	tmpWritePtr			= $06  ; 16 bit pointer to dbuffer, incremented when writing

	; ACC 0: nametable 0, 1: nametable 1
.PROC decompress_nametable

	; set both pointers to the correct tile buffer
	CMP #$00
	BNE @nametable_1
@nametable_0:
	LDX #<dbufTile1
	LDY #>dbufTile1

	JMP @set_buffer
@nametable_1:
	LDX #<dbufTile2
	LDY #>dbufTile2
@set_buffer:
	STX tmpBufferPtr
	STX tmpWritePtr
	STY tmpWritePtr+1
	STY tmpBufferPtr+1


	; make a temporary pointer to the level's background index
	LDY #$00
	LDA (levelPtr),Y
	STA $02
	INY
	LDA (levelPtr),Y
	STA $03

	LDA #$00
	LDX scrollAmount+1
	BPL @find_backround ; when scrolling right, increment the background by one nametable
	LDA #$01
@find_backround:
	CLC
	ADC screenPosX+1
	ASL A
	TAY
	
	; sets tmpdata pointer to the background of the correct nametable
	LDA ($02),Y
	STA tmpDataPointer
	INY
	LDA ($02),Y
	STA tmpDataPointer+1

	JSR lzss_decompress

	; decompress nametable

	; JSR lzss_decompress

	RTS
.ENDPROC

.MACRO IncrementWritePtr
	INC tmpWritePtr
	BNE :+
	INC tmpWritePtr+1
	:
.ENDMACRO

.PROC lzss_decompress
	; set the write pointer to the same buffer

	LDX #$00       ; stays zero for inincremented pointer
	LDY #$00			 ; read offset
decomp_loop:
	LDA (tmpDataPointer),y   
	STA tmpLength	; store control byte Length
	BMI literal		 ; if bit 7 is 1, literals are next
	BEQ done			 ; control byte 00 is end of stream marker
reference:			 ; control byte is a match
	INY
	BNE :+				 ; increment pointer if page boundary crossed
	INC tmpDataPointer+1
	:
	LDA (tmpDataPointer),y
	STY temp			 ; store read index
	TAY						 ; load the reference index
@ref_loop:
	; copy reference index to write index fortmpLengthh
	LDA (tmpBufferPtr),y
	STA (tmpWritePtr,x) ; x is 0
	INY
	IncrementWritePtr
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
	STA (tmpWritePtr,x)
	INY
	BNE :+   		  ; page safe increment
	INC tmpDataPointer+1
	:
	IncrementWritePtr
	INC tmpLength
	BNE @lit_loop ; loop intil literal count rolls over
	JMP decomp_loop
done:
	RTS
.ENDPROC
