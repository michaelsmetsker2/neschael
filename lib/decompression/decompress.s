;
; neschael
; lib/decompression/decompress.s
;
; decompresses lzss encoded level data into buffers in RAM
;

.IMPORT dbufTile1
.IMPORT dbufTile2

.IMPORT entStream1
.IMPORT entStream2

.EXPORT decompress_nametable

.EXPORT dbuff_addr_low
.EXPORT dbuff_addr_high

.EXPORT stream_addr_low
.EXPORT stream_addr_high

.INCLUDE "lib/game/gameData.inc"
.INCLUDE "data/levels/levelData.inc"

	TILE_BUF_SIZE   = $C0  ; size of the tile buffer, used to increment to attr buffer

	; memory constants
  tmpDataPointer      = $0   ; 16 bit pointer to input data
	tmpLength 			    = $02	 ; scratch memory
	temp                = $03	 ; scratch memory
	tmpBufferPtr        = $04  ; 16 bit pointer to the dbuffer to fill
	tmpWritePtr			    = $06  ; 16 bit pointer to dbuffer, incremented when writing
	tmpBackgroundOffset = $08	 ; background index to decompress
	tmpStreamPtr			  = $09  ; 16 bit pointer to the location to store the spawn stream

dbuff_addr_low:
  .BYTE <dbufTile1, <dbufTile2
dbuff_addr_high:
  .BYTE >dbufTile1, >dbufTile2

stream_addr_low:
	.BYTE <entStream1, <entStream2
stream_addr_high:
	.BYTE >entStream1, >entStream2

.PROC decompress_nametable

		; make a temporary pointer to the level's background index
	LDY #$00
	LDA (levelPtr),Y
	STA $02
	INY
	LDA (levelPtr),Y
	STA $03

	  ;	determine the level background to decompress
	LDA screenPosX+1
	LDX scrollAmount
	BMI @check_end				; increment by one when scrolling right
	CLC
	ADC #$01
@check_end:
		; make sure we're not decompressing past the end of the level
	LDY #LEVEL_SIZE_OFFSET
	CMP (levelPtr),Y
	BCC @offset ; background < level size
	BEQ @offset ; background = level size
	RTS         ; return early if background > level size

@offset:
	ASL A							      ; two bytes per address
	STA tmpBackgroundOffset ; to reuse for the spawn stream
	TAY
	
		; increment tmpdata pointer to the background of the correct nametable
	LDA ($02),Y
	STA tmpDataPointer
	INY
	LDA ($02),Y
	STA tmpDataPointer+1

		; determine what buffer to use depending on scroll direction and primary nametable 
	LDA nametable
	LDX scrollAmount
	BMI @find_buf
	EOR #$01
@find_buf:

	TAY
	LDA dbuff_addr_low,Y
	STA tmpBufferPtr
	STA tmpWritePtr

  LDA dbuff_addr_high,Y
	STA tmpWritePtr+1
	STA tmpBufferPtr+1

	; stores the address of the spawn stream in the corolating stream pointer in zeropage
@setup_streams:
		; make the offset from the start of the first spawnstream pointer
	TYA	; Y still contains the target buffer
	LDA stream_addr_low,Y
	STA tmpStreamPtr
	LDA stream_addr_high,Y
	STA tmpStreamPtr+1

		; make a temporary pointer to the level's spawn stream index
	LDY #$02
	LDA (levelPtr),Y
	STA $02
	INY
	LDA (levelPtr),Y
	STA $03
		; increment the pointer by the background offset to point to the correct address, and store it at tmpStreamPtr
	LDX #$00
	LDY tmpBackgroundOffset
	LDA ($02),Y
	STA (tmpStreamPtr,X)
	INY
	LDA ($02),Y
	LDY #$01
	STA (tmpStreamPtr),Y

	JMP lzss_decompress	

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
	LDY temp			           ; restore and increment read offset
	INY
	BNE decomp_loop
	INC tmpDataPointer+1	   ; increment pointer if page boundary crossed
	JMP decomp_loop
literal:
	INY						           ; page safe increment
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
