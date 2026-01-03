;   
; nechael
; lib/scrolling.s
;
; subroutines related to SCROLLING_BUFF, when scrolling thresholds are reached, it will uncompress
; and store level data while the PPU is writing. This takes leaves less logic for NMI
;

; ==============================================================================
; These macros are to be used in NMI to draw from the buffer
; ==============================================================================

.MACRO DrawOffscreenTiles
    ; copy uncompressed nametable data to the PPU at the correct memory location
    
  LDA #%00000100        ; set to increment +32 mode
  STA _PPUCTRL
  
@left:
    ; set the PPU to write to the correct nametable and the top of the left column
  LDX ScrollBuffer::addrHigh
  STX _PPUADDR
  LDA ScrollBuffer::addrLowLeft
  STA _PPUADDR

  LDY #$00
@left_loop: ; loop through the whole column
  LDA ScrollBuffer::colLeft, y
  STA _PPUDATA
  INY

  CPY #COLUMN_LENGTH
  BNE @left_loop

@right:
     ; set the PPU to write to the correct nametable and the top of the right column
  STX _PPUADDR                    ; start from the same nametable (high byte)
  LDA ScrollBuffer::addrLowRight  
  STA _PPUADDR

  LDY #$00
@right_loop: ; loop through the whole column
  LDA ScrollBuffer::colRight, y
  STA _PPUDATA
  INY

  CPY #COLUMN_LENGTH
  BNE @right_loop
.ENDMACRO

.MACRO DrawOffscreenAttributes
  ; copy uncompressed attribute data to the PPU at the correct memory location

    ; derive the attribute collumn offset from the tile column offset
  LDA ScrollBuffer::addrLowLeft ; left or right, doesn't matter data is truncated
  AND #%00011111                ; keep only the tile x, 0-31
  LSR
  LSR
    
  CLC
  ADC ATTRIBUTE_TABLE_OFFSET ; add the low byte of the attribute table
  
  LDY #$00

  LDX ScrollBuffer::addrHigh ; nametable high byte
@loop:
  STX _PPUADDR

  STA _PPUADDR ; low byte offset
  CLC
  ADC #$08

  LDA ScrollBuffer::attribute, y
  STA _PPUDATA
  INY

  CPY #$08
  BNE @loop
.ENDMACRO

; resets the draw gameflag
.MACRO ResetDrawFlag
  LDA gameFlags
  AND #%10111111
  STA gameFlags
.ENDMACRO

.SCOPE Scrolling

    COLUMN_Y_OFFSET        = $20 ; the offset of the low bytes, since we don't draw the top 8 scanlines   

  ; === unsafe memory constants ===

    tmpMetatileIndex       = $1B ; 16 bit, index of the metatile to draw
    tmpBufferPointer       = $13 ; low bye first, points to data to be read to the buffer

    tmpOldScrollPos        = $15 ; 16 bit, previous scroll position

  ; apply the scrollAmount, swap nametables and fill the scroll buffer if neccessary
  .PROC scroll_screen

    LDA scrollAmount
    BEQ @done            ; return early if no scroll is needed 

      ;store the previous scroll position
    LDA screenPosX
    STA tmpOldScrollPos
    LDA screenPosX+1
    STA tmpOldScrollPos+1

  @update_scroll_position:
    LDA screenPosX
    CLC
    ADC scrollAmount     ; add low byte
    STA screenPosX

    LDA screenPosX+1     ; add carry
    ADC #$00
    BIT scrollAmount     ; check sign of scrollAmount
    BPL @positive
  @negative:
    SBC #$01             ; add $FF (-1) to extend teh sign to the high byte           
  @positive:
    STA screenPosX+1

  @check_nametable_boundary:
    CMP tmpOldScrollPos+1
    BEQ @check_metatile_boundary ; branch if we havn't scrolled onto a new nametable

    LDA nametable
    EOR #$01                ; flip nametable
    STA nametable  

  @check_metatile_boundary: ; see if we crossed into a new metatile so we must draw more
    LDA tmpOldScrollPos
    LSR
    LSR
    LSR
    LSR
    STA $00
    LDA tmpOldScrollPos+1
    ASL
    ASL
    ASL
    ASL
    ORA $00
    STA $00                   ; $00 now holds last frames metatile index

    LDA screenPosX
    LSR
    LSR
    LSR
    LSR
    STA $01
    LDA screenPosX+1
    ASL
    ASL
    ASL
    ASL
    ORA $01
    STA $01                   ; $01 now holds current frames metatile index

    CMP $00
    BEQ @reset_scroll_amount  ; if we're on the same metatile, don't draw

    JSR Scrolling::Buffer::fill_scroll_buffer
  @reset_scroll_amount:
    LDA #$00
    STA scrollAmount
  @done:
    RTS
  .ENDPROC

; ================================================================================================
; main scroll buffer subroutines
; ================================================================================================
  .SCOPE Buffer

    .PROC fill_scroll_buffer

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

        ; scroll / 8 = tile position as 8 pixls per tile
      JSR fill_buff_addr_low  ; populate low bytes
      JSR fill_buff_addr_high ; populate the high address byte of the buffer

      JSR locate_tile_data    ; populates the buffer pointer
      JSR fill_tile_data      ; fills the buffer
      ; jsr to fill attribute data
      
        ; set draw flag so column will draw next NMI
      LDA gameFlags
      ORA #%01000000
      STA gameFlags
    .ENDPROC

    ; fills the high address byte in the scroll buffer
    .PROC fill_buff_addr_high

      LDA Player::velocityX+1
      BPL @flip_table         ; always draw to opposite nametable when scrolling right
      LDA tmpMetatileIndex
      AND #%00001111          ; if the current tile index % 16 we are at the beginning of thee nametable
      BEQ @flip_table         ; so flip nametable
    @use_current:
      LDA nametable    ; just use the current nametable
      JMP @final

    @flip_table:
      LDA nametable    ; load the current nametable (0 or 1) and flip the bit
      EOR #$01

    @final:            ; convert the nametable to an address
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
      TAX

      LDA Player::velocityX+1
      BPL @final
    @left:                 ; if were scrolling left, decrement the position by 2 tiles (one metatile)
      DEX
      DEX
    @final:
      TXA
      AND #%00011111        ; mask bits 5-7 incase of overflow

      CLC
      ADC #COLUMN_Y_OFFSET  ; offset by one row due to overscan
      TAX

      STX ScrollBuffer::addrLowLeft
      INX                   ; this shouldn't overflow since this is only called on metatile boundries
      STX ScrollBuffer::addrLowRight
      RTS
    .ENDPROC

    .PROC locate_tile_data
        ; update the tmpBufferPointer to point to the location of the column we will draw to the buffer 

      LDA Player::velocityX+1
      BMI @left           ; branch based on scroll direction
    @right:

        ; data wil be pulled from the next background from our current on
      LDY screenPosX+1 ; pixel position / 256 or the high bit of screenPosX is our current background
      INY              ; increment as we buffer the data from the next one
      TYA
      ASL A            ; multiply offset by two, as there are two bytes per address in the lookuptable
      TAY

      LDA background_index, Y   ; load pointer to the correct background
      STA tmpBufferPointer
      INY
      LDA background_index, Y
      STA tmpBufferPointer+1

        ; now point to the correct metacolumn, it is the same index as our current one
      LDA tmpMetatileIndex
      AND #%00001111        ; mask so we get the index of our metatile relative to background
      ASL A                 ; multiply by two to get address offset
      TAY

        ; point to the correct metacolumn from the background's lookup table
      LDA (tmpBufferPointer), Y
      TAX
      INY
      LDA (tmpBufferPointer), Y

      STX tmpBufferPointer
      STA tmpBufferPointer+1
      
      RTS
    @left:
      ; were gonna pull data from the current screen unless we are at metatile index 0
      
      LDA tmpMetatileIndex
      AND #%00001111        ; get index of current metatile relative to background
      BEQ @prev_background  ; if we are at the beginning of a nametable, use the previous
    @cur_background:
        ; use the current background
      TAX                   ; store masked metatile position for use later

        ; use the current background
      LDA screenPosX+1      ; pixel position / 256 or the high bit of screenPosX is our current background
      ASL A                 ; * 2 to get byte offset in backgrounds lookup table
      TAY

      LDA background_index, Y   ; load pointer to the current background
      STA tmpBufferPointer
      INY
      LDA background_index, Y
      STA tmpBufferPointer+1

        ; now load pointer to the current
      DEX                   ; decrement the metatile index as we are loading one to the left
      TXA
      ASL A                 ; *2 to get the byte offset for metacolumn lookup table
      TAY

        ; point to the correct metacolumn from the background's lookup table
      LDA (tmpBufferPointer), Y
      TAX
      INY
      LDA (tmpBufferPointer), Y

      STX tmpBufferPointer
      STA tmpBufferPointer+1

      RTS
    @prev_background:
        ; use the previous backgound
      LDA screenPosX+1      ; pixel position / 256 or the high bit of screenPosX is our current background; 
      TAX
      DEX                   ; decrement to the previous background
      TXA
      ASL A                 ; *2 for byte offset in background lookup table
      TAY
        ; load pointer to the previous background
      LDA background_index, Y
      STA tmpBufferPointer
      INY
      LDA background_index, Y
      STA tmpBufferPointer+1

      LDY #$20          ; last column on the background (16) * 2 is $20
        ; point to the last column in the background
      LDA (tmpBufferPointer), Y
      TAX
      INY
      LDA (tmpBufferPointer), Y

      STX tmpBufferPointer
      STA tmpBufferPointer+1

      RTS
    .ENDPROC

    .PROC fill_tile_data
      ; TODO this is all temp pre metatiles and RTI
      LDY #$00

    @loop:                    ; sets 60 bytes consecutively, both rows of the column
      LDA (tmpBufferPointer), Y
      STA ScrollBuffer::colLeft, Y    
      INY
      CPY #$3C
      BCC @loop

      RTS
    .ENDPROC

  .ENDSCOPE
.ENDSCOPE

; End of lib/scrolling.s