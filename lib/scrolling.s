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

    ; TODO this causes slight inneficiency later when reseting _PPUCTRL
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

  CPY COLUMN_LENGTH
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

  CPY COLUMN_LENGTH
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

.SCOPE scrolling
  
  tmpMetatileIndex = $10 ; 16 bit, index of the metatile to draw to

  COLUMN_Y_OFFSET  = $20 ; the offset of the low bytes, since we don't draw the top 8 scanlines   

  .PROC fill_scroll_buffer

    ; dividing the scroll position by 16 gives the index of the current metatile
    LDA ScreenPosX
    STA tmpMetatileIndex
    LDA ScreenPosX+1
    STA tmpMetatileIndex+1

    ROR tmpMetatileIndex+1
    LSR tmpMetatileIndex
    ROR tmpMetatileIndex+1
    LSR tmpMetatileIndex
    ROR tmpMetatileIndex+1
    LSR tmpMetatileIndex

      ; scroll / 8 = tile position as 8 pixls per tile
    JSR fill_buff_addr_low  ; populate low bytes
    
    ROR tmpMetatileIndex+1
    LSR tmpMetatileIndex

    JSR fill_buff_addr_high ; populate the high address byte of the buffer

    ;jsr to decode and fill the column data
    ;jsr to fill attribute data`

    
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

  .PROC fill_buff_addr_low

      ; slightly inneficient to slip it left again, but more readable
    LDA tmpMetatileIndex ; at this point in the program, this holds the tile index, not metatile
    AND #%00011111       ; now 0 - 31, the tile position relative to nametable start
    TAX

    LDA Player::velocityX+1
    BPL @final
  @left:                 ; if were scrolling left, decrement the position by 2 tiles (one metatile)
    DEX
    DEX
  @final:
    TXA
    AND #%00011111       ; mask bits 5-7 incase of overflow

    CLC
    ADC #COLUMN_Y_OFFSET  ; offset by one row due to overscan
    TAX

    STX ScrollBuffer::addrLowLeft
    INX ; this shouldn't overflow since this is only called on metatile boundries
    STX ScrollBuffer::addrLowRight
  .ENDPROC

.ENDSCOPE

; End of lib/scrolling.s