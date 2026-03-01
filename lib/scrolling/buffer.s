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

; buffers of uncompressed level data
.IMPORT dbufTile1
.IMPORT dbufAttr1
.IMPORT dbufTile2
.IMPORT dbufAttr2

.EXPORT mult_13
.EXPORT fill_scroll_buffer

  COLUMN_Y_OFFSET        = $40 ; the offset of the low bytes, since we don't draw the top 16 scanlines   

  tmpMetatileIndex       = $1B ; 16 bit, index of the metatile to draw
  tmpBufferPointer       = $13 ; low byte first, points to data to be read to the buffer
  tmpTilePointer         = $15 ; low byte first, points to the metatile to decode

mult_13: ; multiples of thirteen, used for offseting the buffer pointer
  .BYTE $00, $0D, $1A, $27, $34, $41, $4E, $5B, $68, $75, $82, $8F, $9C, $A9, $B6, $C3

.PROC fill_scroll_buffer
; FIXME do i need this garb?
    ; dividing the scroll position by 16 gives the index of the current metatile
  LDA screenPosX
  STA tmpMetatileIndex
  LDA screenPosX+1
  STA tmpMetatileIndex+1

  ROR tmpMetatileIndex+1
  LSR tmpMetatileIndex
  ROR tmpMetatileIndex+1
  LSR tmpMetatileIndex
  ROR tmpMetatileIndex+1
  LSR tmpMetatileIndex
  ROR tmpMetatileIndex+1
  LSR tmpMetatileIndex

    ; scroll / 8 = tile position
  JSR fill_buff_addr_low
  JSR fill_buff_addr_high

  JSR locate_tile_data    ; populates the buffer pointer
  JSR fill_tile_data
  ;JSR locate_attrib_data
  ;JSR fill_attrib_data
  
    ; set draw flag so for next NMI
  LDA gameFlags
  ORA #%01000000
  STA gameFlags
.ENDPROC

; fills the high address byte in the scroll buffer
.PROC fill_buff_addr_high

  LDA scrollAmount
  BPL @flip_table  ; draw to opposite nametable when scrolling right
@use_current:
  LDA nametable    ; use the current when scrolling left
  JMP @final

@flip_table:
  LDA nametable    ; load the current nametable and flip the bit
  EOR #$01

@final:            ; convert nametable to an address
  ASL A
  ASL A            ; shift up to $00 or $04
  CLC 
  ADC #$20         ; add high byte of ase nametable adress ($2000)
  STA ScrollBuffer::addrHigh
.ENDPROC

; fill the low address of the top of each column in ppu memory
.PROC fill_buff_addr_low
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

; update the tmpBufferPointer to point to the location of the column we will draw to the buffer 
.PROC locate_tile_data

; need to find the correct buffer to read from.

  LDA nametable
  LDX scrollAmount
  BNE @find_buf
@right:
    ; when scrolling right, draw to opposite nametable, flip
  EOR #$00000001

@find_buf:
  TAY ; set registers
  BNE @nt_1
@nt_0:
  LDX #<dbufTile1
  LDY #>dbufTile1
  JMP @set_buf
@nt_1:
  LDX #<dbufTile2
  LDY #>dbufTile2
@set_buf:
  STX tmpBufferPointer
  STY tmpBufferPointer+1

  ; find column

    ; find offset of current metatile column in lookup table
  LDA tmpMetatileIndex
  AND #%00001111        ; get index of current metatile relative to background
  TAY
  LDA mult_13, Y

  CLC
  ADC tmpBufferPointer
  STA tmpBufferPointer
  LDA tmpBufferPointer+1
  ADC #$00
  STA tmpBufferPointer+1

  RTS
.ENDPROC

.PROC fill_tile_data

  LDY #$00  ; loop index
  STY $0F
@loop:
    ; set the location of tmpTilePointer to the correct metatile
  LDA (tmpBufferPointer), Y
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
.IF 0
  LDA scrollAmount
  BMI @left           ; branch based on scroll direction
@right:

    ; pull data from the next background
  LDY screenPosX+1 ; pixel position / 256 or the high bit of screenPosX is our current background
  INY              ; increment as we buffer the data from the next one
  TYA
  ASL A            ; multiply offset by two, as there are two bytes per address in the lookuptable
  TAY

  JMP @find_background
@left:
  ; pull data from the current background
  
  LDA screenPosX+1      ; pixel position / 256 or the high bit of screenPosX is our current background
  ASL A                 ; * 2 to get byte offset in backgrounds lookup table
  TAY

@find_background:
  LDA attribute_index, Y   ; point to the correct background
  STA tmpBufferPointer
  INY
  LDA attribute_index, Y
  STA tmpBufferPointer+1

    ; find offset of current attribute column
  LDA tmpMetatileIndex
  AND #%00001110        ; get index of current metatile relative to background
                          ; in the lookup table, 2 bytes per metatile, 2 metatiles per column
  TAY

    ; point to the correct metacolumn from the background's lookup table
  LDA (tmpBufferPointer), Y
  TAX
  INY
  LDA (tmpBufferPointer), Y

  STX tmpBufferPointer
  STA tmpBufferPointer+1

  RTS
.ENDIF

.ENDPROC

; store the uncompressed attrib data in the buffer
.PROC fill_attrib_data
.IF 0
  LDY #$00 ; loop index
@loop:                    ; sets all 7 attribute bytes of the column
  LDA (tmpBufferPointer), Y
  STA ScrollBuffer::attribute, Y    
  INY
  CPY #$07
  BCC @loop

  RTS
.ENDIF
.ENDPROC