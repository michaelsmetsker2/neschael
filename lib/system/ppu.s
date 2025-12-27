;
; neschael
; lib/system/ppu.s
;
; PPU-related routines and macros
;


; enables and disable various rendering flags
.MACRO DisableVideoOutput
  LDA #%00000000
  STA _PPUCTRL    ; disable NMI
  STA _PPUMASK    ; disable rendering
.ENDMACRO

.MACRO EnableVideoOutput
  LDA #%10010000  ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
  STA _PPUCTRL
  LDA #%00011110  ; enable sprites, enable background, no clipping on left side
  STA _PPUMASK
.ENDMACRO

; waits for the vblank flag, this is slightly inconsist and and
  ; NMI should be used instead
.PROC wait_for_vblank
  @vblank_wait_loop:
  BIT _PPUSTATUS
  BPL @vblank_wait_loop
  RTS
.ENDPROC

; loads color and position information to RAM
.PROC load_palette_data
  LDA _PPUSTATUS           ; read PPU status to reset the high/low latch
  LDA #$3F
  STA _PPUADDR             ; write the high byte of the palette RAM, $3F00
  LDA #$00
  STA _PPUADDR             ; write the low byte of the palette RAM, $3F00
  LDX #$00
@load_palettes_loop:
  LDA palette, x
  STA _PPUDATA            ; Write to PPU
  INX
  CPX #$20
  BNE @load_palettes_loop ; break if all 32 bytes are copied
  RTS
.ENDPROC 

.PROC load_background_data ; loads all starting background name and attribute tables
  LDA _PPUSTATUS           ; read PPU status to reset the high/low latch
  LDA #$20
  STA _PPUADDR             ; write high and low bytes of address  $2000 
  LDa #$00
  STA _PPUADDR
  
  LDA #<background         ; point to address of background label
  STA POINTER_LOW
  LDA #>background
  STA POINTER_HIGH
  LDX #$00
  LDY #$00
@loop:
  LDA (POINTER_LOW),Y      ; copy one background/attribute byte from address in pointer + Y
  STA _PPUDATA             ; runs 256*4 times
  INY                      ; inside loop counter / byte offset
  CPY #$00                
  BNE @loop         ; run inside loop 256 times before continuing
  INC POINTER_HIGH         ; increment high byte
  INX                      ; increment outside loop counter
  CPX #$08                 ; needs to happen $04 times, to copy 1KB data
  BNE @loop
  RTS

.ENDPROC

.PROC initialize_nametables
  LDA #$00
  STA nametable
  STA scroll
  STA columnNumber
@loop:
  JSR draw_column
  LDA scroll
  CLC
  ADC #$08         ; increment to next column
  STA scroll
  INC columnNumber ; increment column number
  LDA columnNumber
  CMP #$20
  BNE @loop        ; draw 32 rows (the whole nametable)

    ; draw the first column of the second nametable
  LDA #$01
  STA nametable
  LDA #$00
  STA scroll
  JSR draw_column
  INC columnNumber

  LDA #$00        ; set increment mode back to +1
  STA _PPUCTRL
  RTS
.ENDPROC

; temp ========================================================
columnLow = $00        ; points to the start of the address in ppu to draw to     
columnHigh = $01
sourceLow = $02        ; points to the start of the tile data in rom
sourceHigh = $03

.PROC draw_column
  ; drawsa  new collumn directly offscreen to the right
  LDA scroll       ; find the PPU address of the new column's start
  LSR A
  LSR A
  LSR A            ; shift right 3 times to devide by 8 (tile width)
  STA columnLow    ; $00 to $1F, screen is 32 tiles wide

  LDA nametable    ; find the high bit using the current nametable
  EOR #$01         ; flip bit
  ASL A
  ASL A            ; shift up to $00 or $04
  CLC 
  ADC #$20         ; add high byte of ase nametable adress ($2000)
  STA columnHigh   ; so high byte should be $20 or $24

  LDA columnNumber ; columnNumber * 32 is column data offset
  
  ASL A
  ASL A
  ASL A
  ASL A
  ASL A             
  STA sourceLow
  LDA columnNumber
  LSR A
  LSR A
  LSR A
  STA sourceHigh
  
  LDA sourceLow       ; column data start + offset = address to load column data from
  CLC 
  ADC #LOW(columnData)
  STA sourceLow
  LDA sourceHigh
  ADC #HIGH(columnData)
  STA sourceHigh

DrawColumn:
  LDA #%00000100        ; set to increment +32 mode
  STA $2000
  
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA columnHigh
  STA $2006             ; write the high byte of column address
  LDA columnLow
  STA $2006             ; write the low byte of column address
  LDX #$1E              ; copy 30 bytes
  LDY #$00
DrawColumnLoop:
  LDA [sourceLow], y
  STA $2007
  INY
  DEX
  BNE DrawColumnLoop

  RTS
  
.ENDPROC

; End of lib/shared_code/ppu.s
