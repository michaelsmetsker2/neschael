;
; neschael
; lib/system/ppu.s
;
; PPU-related routines.
;


; enables and disable various rendering flags
.MACRO DisableVideoOutput
  LDA #%00000000
  STA _PPUCTRL    ; disable NMI
  STA _PPUMASK    ; disable rendering
.ENDMACRO

.MACRO EnableVideoOutput
  LDA #%10010000 
  STA _PPUCTRL    ; Enable vertical blank interrupt
  LDA #%00011110 
  STA _PPUMASK    ; Enable rendering and blue background
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

.PROC load_sprite_data
  LDX     #$00
@loadSpritesLoop:
  LDA     sprite, x
  STA     $0200, x         ; Write to OAM buffer in CPU RAMPPU
  INX
  CPX     #24
  BNE     @loadSpritesLoop
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
@outside_loop:
@inside_loop:
  LDA (POINTER_LOW),Y      ; copy one background/attribute byte from address in pointer + Y
  STA _PPUDATA             ; runs 256*4 times
  INY                      ; inside loop counter / byte offset
  CPY #$00                
  BNE @inside_loop         ; run inside loop 256 times before continuing
  INC POINTER_HIGH         ; increment high byte
  INX                      ; increment outside loop counter
  CPX #$04                 ; needs to happen $04 times, to copy 1KB data
  BNE @outside_loop         
  RTS
.ENDPROC

; End of lib/shared_code/ppu.s
