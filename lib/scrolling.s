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

; copy uncompressed nametable data to the PPU at the correct memory location
.MACRO DrawOffscreenTiles    
  LDA #%00000100        ; set to increment +32 mode
  STA _PPUCTRL

@left:
    ; set PPU to write to correct nametable and the left column
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

@right: ; set the PPU to write to the correct nametable and the right column
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

; copy uncompressed attribute data to the PPU at the correct memory location
.MACRO DrawOffscreenAttributes

    ; find the high byte to draw to
  LDA ScrollBuffer::addrHigh ; nametable high byte
  CLC
  ADC #>ATTRIBUTE_TABLE_OFFSET
  TAX

    ; derive the attribute collumn offset from the tile column offset
  LDA ScrollBuffer::addrLowLeft ; left or right doesn't matter
  AND #%00011111                ; keep only the tile x
  LSR
  LSR                           ; 4 tiles ber attribute
  CLC
  ADC #<ATTRIBUTE_TABLE_OFFSET    ; add the low byte of the attribute table
  STA $09
  
  LDY #$00 ; loop index
@loop:
  STX _PPUADDR ; high byte
  LDA $09
  STA _PPUADDR ; low byte
  
  CLC
  ADC #$08
  STA $09

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
    LDA screenPosX+1
    
    BIT scrollAmount     ; check sign of scrollAmount
    BPL @positive
  @negative:
    
    ADC #$FF             ; extend sign
    STA screenPosX+1

    JMP @check_nametable_boundary
  @positive:

    ADC #$00             ; add carry
    STA screenPosX+1

  @check_nametable_boundary:
    CMP tmpOldScrollPos+1
    BEQ @check_metatile_boundary ; branch if we havn't scrolled onto a new nametable

    LDA nametable
    EOR #$01                ; flip nametable
    STA nametable  

  @check_metatile_boundary: ; see if we crossed into a new metatile so we must draw more
    LDA tmpOldScrollPos
    EOR screenPosX
    AND #%11110000
    CMP #$00
    BEQ @reset_scroll_amount  ; if we're on the same metatile, don't draw

    JSR Scrolling::Buffer::fill_scroll_buffer
  @reset_scroll_amount:
    LDA #$00
    STA scrollAmount
  @done:
    RTS
  .ENDPROC

  ; fully draws the first screen upon loading a level
  .PROC draw_first_screen
    LDA #$01          ; flip nametable so we start drawing on first screen
    STA nametable

    LDA #$FF          ; set the screen one background back and scroll right
    STA screenPosX+1
    LDA #$00          
    STA screenPosX
    STA $00           ; loop counter

  @draw_loop:
    JSR Buffer::fill_scroll_buffer ; fill and draw from buffer
    DrawOffscreenTiles
    DrawOffscreenAttributes

    CLC
    LDA #$10
    ADC screenPosX      ; increment screen position by one metatile
    STA screenPosX
    LDA #$00
    ADC screenPosX+1
    STA screenPosX+1

    INC $00
    LDA $00
    CMP #$10            ; 16 columns per screen
    BNE @draw_loop      ; loop through screen

      ; reset nametable
    LDA #$00
    STA nametable
      ; fill the buffer once more so the first col of nametable 1 is filled
    JSR Buffer::fill_scroll_buffer

    RTS
  .ENDPROC

  ; ================================================================================================
  ; scroll buffer subroutines
  ; ================================================================================================
  .SCOPE Buffer

    playerVelocity = $22  ; Signed Fixed Point 8.8, players x velocity, see lib/player/init.s

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

        ; scroll / 8 = tile position
      JSR fill_buff_addr_low
      JSR fill_buff_addr_high

      JSR locate_tile_data    ; populates the buffer pointer
      JSR fill_tile_data
      JSR locate_attrib_data
      JSR fill_attrib_data
      
        ; set draw flag so for next NMI
      LDA gameFlags
      ORA #%01000000
      STA gameFlags
    .ENDPROC

    ; fills the high address byte in the scroll buffer
    .PROC fill_buff_addr_high

      LDA playerVelocity+1
      BPL @flip_table         ; draw to opposite nametable when scrolling right
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
      TAX

      LDA playerVelocity+1
      BPL @final
    @left:                 ; if were scrolling left, decrement by one metatile
      DEX
    @final:
      TXA
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

      LDA playerVelocity+1
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
      LDA background_index, Y   ; point to the correct background
      STA tmpBufferPointer
      INY
      LDA background_index, Y
      STA tmpBufferPointer+1

        ; find offset of current metatile column in lookup table
      LDA tmpMetatileIndex
      AND #%00001111        ; get index of current metatile relative to background
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

    ; set the buffer pointer to the location of the attribute data column that we want to copy
    .PROC locate_attrib_data
      LDA playerVelocity+1
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
    .ENDPROC

    ; store the uncompressed attrib data in the buffer
    .PROC fill_attrib_data
      LDY #$00 ; loop index

    @loop:                    ; sets all 8 attribute bytes of the column
      LDA (tmpBufferPointer), Y
      STA ScrollBuffer::attribute, Y    
      INY
      CPY #$08
      BCC @loop

      RTS
    .ENDPROC

  .ENDSCOPE
.ENDSCOPE

; End of lib/scrolling.s