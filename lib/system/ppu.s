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
  LDA #%10010000   ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
  ORA nametable    ; select correct nametable for bit 0
  STA _PPUCTRL
  
  LDA #%00011110   ; enable sprites, enable background, no clipping on left side
  STA _PPUMASK
.ENDMACRO

; Refresh DRAM-stored sprite data before it decays.
  ; sprites are copies from memory $0200
.MACRO SpriteDMA
  LDA     #$00
  STA     _OAMADDR               ; Set the low byte (00) of the RAM address
  LDA     #$02
  STA     _OAMDMA                ; set the high byte (02) of the RAM address
                                  ; This automatically starts the transfer
.ENDMACRO

; set the scroll as writes to VRAM will offest it
.MACRO SetScroll
  LDA screenPosX
  STA _PPUSCROLL
  LDA #$00
  STA _PPUSCROLL
.ENDMACRO

; resets ppu flags and the vram latch
.MACRO ResetPPUAddress
  BIT _PPUSTATUS     ; reset VBlank flag & PPU latch
  LDA #$00           ; reset VRAM address pointer
  STA _PPUADDR       ; high byte
  STA _PPUADDR       ; low byte
.ENDMACRO

; waits for the vblank flag, this is slightly inconsist and
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

.PROC initialize_nametables
  
  ;1 0f

  LDY #$00
@loop:
  ; fill
  ; we will directly be calling
  JSR Scrolling::Buffer::fill_scroll_buffer

  DrawOffscreenTiles       ; copy buffer data to PPU. see lib/scrolling.s
  DrawOffscreenAttributes
  ; draw

  INY
  CPY $10       ; 16 metacolumns
  BEQ @done
  JMP @loop
@done:
  RTS
.ENDPROC

.PROC initialize_attributes
  RTS ;TODO
.ENDPROC

; End of lib/shared_code/ppu.s
