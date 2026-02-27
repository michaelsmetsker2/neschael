;
; neschael
; lib/decompression/decompress.s
;
; decompresses lzss encoded level data into buffers in RAM
;

.EXPORT lzss_decompress
.EXPORT decompress_nametable

.INCLUDE "lib/game/gameData.inc"

	; memory constants
  tmpDataPointer  = $0   ; 16 bit pointer to input data
	tmpLength 			= $02	 ; scratch memory
	tmpLength       = $03	 ; scratch memory

	; buffer locations
	buf    = $033E ; memory location of the buffer


test_lzss_data:
  .BYTE $FD, $00, $01, $00, $07, $02, $FE, $02, $02, $09, $01, $04, $14, $05, $0C, $FD 
  .BYTE $02, $02, $03, $0A, $14, $FE, $00, $00, $04, $20, $FF, $03, $08, $0B, $05, $2D 
  .BYTE $0D, $25, $26, $3F, $0D, $24, $FE, $00, $03, $0C, $0C, $0B, $80, $FF, $01, $0E 
  .BYTE $8C, $FF, $01, $09, $9B, $04, $A8, $15, $A8, $FF, $01, $05, $CA, $00, $00

.PROC decompress_nametable
	
	; before this proccess what needs to be set:
		; 0 or 1 in a register, what nametable to update
		
	; find the correct background to draw.
		; use level data pointer
		; make pointer to level draw data
	; decompress the correct background data
	; decompress the correct attribute data

	RTS
.ENDPROC

.PROC lzss_decompress


	LDA #<test_lzss_data
	STA tmpDataPointer
	LDA #>test_lzss_data
	STA tmpDataPointer+1 

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
	STY tmpLength			 ; store read index
	TAY						 ; load the reference index
@ref_loop:
	; copy reference index to write index fortmpLengthh
	LDA buf,y
	STA buf,x
	INY
	INX
	DECtmpLengthh
	BNE @ref_loop
	LDY tmpLength			 ; restore and increment read offset
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
	INCtmpLengthh
	BNE @lit_loop ; loop intil literal count rolls over
	JMP decomp_loop
done:
	RTS
.ENDPROC
