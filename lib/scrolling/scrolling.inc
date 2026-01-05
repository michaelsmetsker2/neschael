;
; neschael
; lib/scrolling/scrolling.inc
;
; macros used for drawing from the scroll buffer during NMI
;

  COLUMN_LENGTH          = $1C  ; the amount of tiles per the column
  ATTRIBUTE_TABLE_OFFSET = $03C0  ; PPU offset from the beggining of the nametable to the attribute data

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
  LDA GameData::gameFlags
  AND #%10111111
  STA GameData::gameFlags
.ENDMACRO