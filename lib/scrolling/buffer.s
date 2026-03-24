;
; neschael
; lib/scrolling/buffer.s
;
; subroutines reguarding uncomrpressing data and filling the scroll buffer
;

.SEGMENT "CODE"

.INCLUDE "lib/player/player.inc"
.INCLUDE "lib/game/gameData.inc"
.INCLUDE "lib/scrolling/scrolling.inc"

.INCLUDE "data/tiles/metatiles.s"

  ; from decompress.s
.IMPORT dbuff_addr_high
.IMPORT dbuff_addr_low

.IMPORT check_entities

.EXPORT mult_12
.EXPORT fill_scroll_buffer

  COLUMN_Y_OFFSET        = $80 ; the offset of the low bytes, since we don't draw the top 32 scanlines   
  ATTR_BUFF_OFFSET       = $C0 ; 192, length of the tile draw buffer, used to find the attribute buffer which follows it

  tmpDrawnNt             = $11 ; 0 - 1, whether we are drawing to left or right nametable
  tmpMetatileIndex       = $12 ; index of the metacolumn to draw relative to the background
  tmpBufferPointer       = $13 ; 16 bit, points to data to be read to the buffer
  tmpColumnPointer       = $15 ; 16 bit, pointes to the metacolumn to be read from in dbuffer
  tmpTilePointer         = $17 ; 16 bit, points to the metatile to decode

mult_12: ; multiples of twelve, used for offseting the tile buffer pointer
  .BYTE $00, $0C, $18, $24, $30, $3C, $48, $54, $60, $6C, $78, $84, $90, $9C, $A8, $B4
mult_6:  ; multiples of six, used for offsetting attribute buffer pointer
  .BYTE $00, $06, $0C, $12, $18, $1E, $24, $2A, $30, $36, $3C, $42, $48, $4E, $54, $5A

  ; fill scroll buffer will tail call a check for entities for garunteed uncorrupted pointers
.PROC fill_scroll_buffer

  JSR fill_buff_addr

  JSR locate_tile_data    ; populates the buffer pointer, then tail calls to fill the scroll buffer
  JSR locate_attrib_data
  
    ; set draw flag so for next NMI
  LDA gameFlags
  ORA #%01000000
  STA gameFlags
  
  JMP check_entities
.ENDPROC

; fills the high and low address byte in the scroll buffer
.PROC fill_buff_addr
@high_address:
  LDA nametable
  LDY scrollAmount
  BMI @final  ; draw to opposite nametable when scrolling right
@flip_table:
  EOR #$01

@final:            ; convert nametable to an address
  STA tmpDrawnNt
  
  ASL A
  ASL A            ; shift up to $00 or $04
  CLC 
  ADC #$20         ; add high byte of ase nametable adress ($2000)
  STA ScrollBuffer::addrHigh

@low_address:
  LDA screenPosX ; pixel pos relative to background
  LSR A
  LSR A
  LSR A          ; divide by 8 to find the column index
  AND #%11111110 ; aligns to metatile (prevents errors at speeds over 8)
  TAX

  AND #%00011111        ; mask incase of overflow

  CLC
  ADC #COLUMN_Y_OFFSET  ; offset by one row for overscan
  TAX

  STX ScrollBuffer::addrLowLeft
  INX                   ; this shouldn't overflow since this is only called on metatile boundries
  STX ScrollBuffer::addrLowRight
  RTS
.ENDPROC

; update the tmpColumnPointer to point to the location of the column we will draw to the buffer 
.PROC locate_tile_data
  LDY tmpDrawnNt

  LDA dbuff_addr_low,Y
  STA tmpBufferPointer
  LDA dbuff_addr_high,Y
  STA tmpBufferPointer+1

    ; find offset of current metatile column
@find_column:
  ; divide the scroll position by 16 to get index of the current metatile
  LDA screenPosX
  LSR A
  LSR A
  LSR A
  LSR A
  STA tmpMetatileIndex
  TAY

  LDA mult_12, Y
    ; add offset
  CLC
  ADC tmpBufferPointer
  STA tmpColumnPointer
  LDA tmpBufferPointer+1
  ADC #$00
  STA tmpColumnPointer+1

  JMP fill_tile_data
.ENDPROC

.PROC fill_tile_data

  LDY #$00  ; loop index
  STY $0F
@loop:
    ; set the location of tmpTilePointer to the correct metatile
  LDA (tmpColumnPointer), Y
  ASL A                       ; multiply by two to get lookup table offset
  TAX
  LDA metatiles, X
  STA tmpTilePointer
  INX
  LDA metatiles, X
  STA tmpTilePointer+1

    ; temporarily store the metatile's tile data in scratch memory 
  LDY #$00
  LDA (tmpTilePointer), Y
  STA $06
  INY
  LDA (tmpTilePointer), Y
  STA $07
  INY
  LDA (tmpTilePointer), Y
  STA $08
  INY
  LDA (tmpTilePointer), Y
  STA $09
  INY

    ; set why to the current tile position (*2)
  LDA $0F
  ASL
  TAY
  
    ; store the tile data in the correct spot in the buffer
  LDA $06
  STA ScrollBuffer::colLeft, Y
  LDA $07
  STA ScrollBuffer::colRight, Y
  INY
  LDA $08
  STA ScrollBuffer::colLeft, Y
  LDA $09
  STA ScrollBuffer::colRight, Y

  LDY $0F
  INY       ; increment and conditionally loop
  STY $0F
  CPY #META_COLUMN_LENGTH
  BCC @loop

  RTS
.ENDPROC

; set the buffer pointer to the location of the attribute data column that we want to copy
.PROC locate_attrib_data

  ; increment the buffer pointer to the start of the correct attribute data
  CLC
  LDA tmpBufferPointer
  ADC #ATTR_BUFF_OFFSET
  STA tmpBufferPointer
  BCC :+
  INC tmpBufferPointer+1
:

    ; find offset of current attr column
@find_column:
  LDA tmpMetatileIndex
  LSR A
  TAY
  LDA mult_6, Y ; six  bytes per col
    ;add offset
  CLC
  ADC tmpBufferPointer
  STA tmpColumnPointer
  LDA tmpBufferPointer+1
  ADC #$00
  STA tmpColumnPointer+1

  JMP fill_attrib_data
.ENDPROC

; store the uncompressed attrib data in the buffer
.PROC fill_attrib_data
  LDY #$00 ; loop index
@loop:                    ; sets all 6 attribute bytes of the column
  LDA (tmpColumnPointer), Y
  STA ScrollBuffer::attribute, Y    
  INY
  CPY #ATTR_LENGTH
  BCC @loop

  RTS
.ENDPROC