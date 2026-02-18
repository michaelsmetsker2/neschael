;
; neschael
; lib/decompression/decompress.s
;
; decompresses lzss encoded level data into buffers in RAM
;

.EXPORT lzss_decompress

test_lzss_data:
	; old before change
  ;;.BYTE $FD, $00, $01, $00, $07, $01, $FE, $02, $02, $09, $0B, $04, $01, $05, $0D, $FD 
  ;;.BYTE $02, $02, $03, $0A, $0D, $FE, $00, $00, $04, $0D, $FF, $03, $08, $27, $05, $0D 
  ;;.BYTE $0D, $1A, $26, $0D, $0D, $4E, $FE, $00, $03, $0C, $75, $0B, $0D, $FF, $01, $0E 
  ;;.BYTE $0D, $FF, $01, $09, $0D, $04, $09, $15, $0D, $FF, $01, $05, $01, $00, $00

  .BYTE $FD, $00, $01, $00, $07, $02, $FE, $02, $02, $09, $01, $04, $14, $05, $0C, $FD 
  .BYTE $02, $02, $03, $0A, $14, $FE, $00, $00, $04, $20, $FF, $03, $08, $0B, $05, $2D 
  .BYTE $0D, $25, $26, $3F, $0D, $24, $FE, $00, $03, $0C, $0C, $0B, $80, $FF, $01, $0E 
  .BYTE $8C, $FF, $01, $09, $9B, $04, $A8, $15, $A8, $FF, $01, $05, $CA, $00, $00

.PROC lzss_decompress

	; vars
  ptr    = $0    ; 16 bit pointer to input data
	length = $02	 ; scratch memory
	temp   = $03	 ; scratch memory
	Buf    = $0400 ; memory location of the buffer

	LDA #<test_lzss_data
	STA ptr
	LDA #>test_lzss_data
	STA ptr+1 

	LDX #$00			 ; write index
	LDY #$00			 ; read offset
decomp_loop:
	LDA (ptr),y   
	STA length		 ; store control byte in length
	BMI literal		 ; if bit 7 is 1, literals are next
	BEQ done			 ; control byte 00 is end of stream marker
refference:			 ; control byte is a match
	INY
	BNE :+				 ; increment pointer if page boundary crossed
	INC ptr+1
	:
	LDA (ptr),y
	STY temp			 ; store read index
	TAY						 ; load the reference index
@ref_loop:
	; copy reference index to write index for length
	LDA Buf,y
	STA Buf,x
	INY
	INX
	DEC length
	BPL @ref_loop
	LDY temp			 ; restore and increment read offset
	INY
	BNE decomp_loop
	INC ptr+1			 ; increment pointer if page boundary crossed
	JMP decomp_loop
literal:
	INY						 ; page safe increment
	BNE :+
	INC ptr+1
	:
@lit_loop:
	; write length amount of literals to buffer
	LDA (ptr),y
	STA Buf,x
	INY
	BNE :+   		  ; page safe increment
	INC ptr+1
	:
	INX
	INC length
	BNE @lit_loop ; loop intil literal count rolls over
	JMP decomp_loop
done:
	RTS
.ENDPROC
