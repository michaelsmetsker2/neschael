;
; neschael
; data/system/ppu.inc
;
; PPU-Related assembler directives for Nintendo Entertainment System assembly language.
; And some PPU related macros.
;

; The PPU (Picture Processing Unit) generates a composite video signal with 240 lines of pixels.
; Reference: https://wiki.nesdev.com/w/index.php/PPU

;
; PPU MEMORY MAP
;
; --------------------------------------- $4000
; Empty
; --------------------------------------- $3F20
; Sprite Palette
; --------------------------------------- $3F10
; Image Palette
; --------------------------------------- $3F00
; Empty
; --------------------------------------- $3000
; Attribute Table 3
; --------------------------------------- $2FC0
; Name Table 3 (32x30 tiles)
; --------------------------------------- $2C00
; Attribute Table 2
; --------------------------------------- $2BC0
; Name Table 2 (32x30 tiles)
; --------------------------------------- $2800
; Attribute Table 1
; --------------------------------------- $27C0
; Name Table 1 (32x30 tiles)
; --------------------------------------- $2400
; Attribute Table 0
; --------------------------------------- $23C0
; Name Table 0 (32x30 tiles)
; --------------------------------------- $2000
; Pattern Table 1 (256x2x8, may be VROM)
; --------------------------------------- $1000
; Pattern Table 0 (256x2x8, may be VROM)
; --------------------------------------- $0000
;

; VRAM Addresses
_NAMETABLE_B = $2400
_NAMETABLE_A = $2000
_NAMETABLE_C = $2800
_NAMETABLE_D = $2c00
_ATTR_A      = $23c0
_ATTR_B      = $27c0
_ATTR_C      = $2bc0
_ATTR_D      = $2fc0

; ------+-----+---------------------------------------------------------------
; $2000 | RW  | PPU Control Register 1
;       | 0-1 | Name Table Address:
;       |     |
;       |     |           +-----------+-----------+
;       |     |           | 2 ($2800) | 3 ($2C00) |
;       |     |           +-----------+-----------+
;       |     |           | 0 ($2000) | 1 ($2400) |
;       |     |           +-----------+-----------+
;       |     |
;       |     | Remember that because of the mirroring there are only 2  
;       |     | real Name Tables, not 4. Also, PPU will automatically
;       |     | switch to another Name Table when running off the current
;       |     | Name Table during scroll (see picture above).
;       |   2 | Vertical Write, 1 = PPU memory address increments by 32:
;       |     |
;       |     |    Name Table, VW=0          Name Table, VW=1
;       |     |   +----------------+        +----------------+
;       |     |   |----> write     |        | | write        |
;       |     |   |                |        | V              |
;       |     |
;       |   3 | Sprite Pattern Table Address, 1 = $1000, 0 = $0000.
;       |   4 | Screen Pattern Table Address, 1 = $1000, 0 = $0000.
;       |   5 | Sprite Size, 1 = 8x16, 0 = 8x8.
;       |   6 | PPU Master/Slave Mode, not used in NES.
;       |   7 | VBlank Enable, 1 = generate interrupts on VBlank.
; ------+-----+---------------------------------------------------------------
_PPUCTRL    = $2000           ; Reference: https://wiki.nesdev.com/w/index.php/PPU_registers#PPUCTRL

; ------+-----+---------------------------------------------------------------
; $2001 | RW  | PPU Control Register 2
;       |   0 | Unknown (???)
;       |   1 | Image Mask, 0 = don't show left 8 columns of the screen.
;       |   2 | Sprite Mask, 0 = don't show sprites in left 8 columns. 
;       |   3 | Screen Enable, 1 = show picture, 0 = blank screen.
;       |   4 | Sprites Enable, 1 = show sprites, 0 = hide sprites.
;       | 5-7 | Background Color, 0 = black, 1 = blue, 2 = green, 4 = red.
;       |     | Do not use any other numbers as you may damage PPU hardware.
; ------+-----+---------------------------------------------------------------
_PPUMASK    = $2001           ; Reference: https://wiki.nesdev.com/w/index.php/PPU_registers#PPUMASK

; ------+-----+---------------------------------------------------------------
; $2002 | R   | PPU Status Register
;       | 0-5 | Unknown (???)
;       |   6 | Hit Flag, 1 = Sprite refresh has hit sprite #0.
;       |     | This flag resets to 0 when screen refresh starts.
;       |   7 | VBlank Flag, 1 = PPU is in VBlank state.
;       |     | This flag resets to 0 when VBlank ends or CPU reads $2002.
; ------+-----+---------------------------------------------------------------
_PPUSTATUS  = $2002         ; Reference: https://wiki.nesdev.com/w/index.php/PPU_registers#PPUSTATUS

; ------+-----+---------------------------------------------------------------
; $2005 | W   | Screen Scroll Offsets
;       |     | There are two scroll registers, vertical and horizontal, 
;       |     | which are both written via this port. The first value written
;       |     | will go into the Vertical Scroll Register (unless it is >239,
;       |     | then it will be ignored). The second value will appear in the
;       |     | Horizontal Scroll Register. Name Tables are assumed to be
;       |     | arranged in the following way:
;       |     |
;       |     |           +-----------+-----------+
;       |     |           | 2 ($2800) | 3 ($2C00) |
;       |     |           +-----------+-----------+
;       |     |           | 0 ($2000) | 1 ($2400) |
;       |     |           +-----------+-----------+
;       |     |
;       |     | When scrolled, the picture may span over several Name Tables.
;       |     | Remember that because of the mirroring there are only 2 real
;       |     | Name Tables, not 4.
; ------+-----+---------------------------------------------------------------
_PPUSCROLL  = $2005         ; Reference: https://wiki.nesdev.com/w/index.php/PPU_registers#PPUSCROLL

; ------+-----+---------------------------------------------------------------
; $2006 | W   | PPU Memory Address
;       |     | Used to set the address of PPU Memory to be accessed via
;       |     | $2007. The first write to this register will set 6 upper adress
;       |     | bits. The second write will set 8 lower bits.
;       |     | address will increment either by 1 or by 32 after each
;       |     | access to $2007.
; ------+-----+---------------------------------------------------------------
_PPUADDR    = $2006           ; Reference: https://wiki.nesdev.com/w/index.php/PPU_registers#PPUADDR

; ------+-----+---------------------------------------------------------------
; $2007 | RW  | PPU Memory Data
;       |     | Used to read/write the PPU Memory. The address is set via
;       |     | $2006 and increments after each access, either by 1 or by 32.
; ------+-----+---------------------------------------------------------------
_PPUDATA    = $2007           ; Reference: https://wiki.nesdev.com/w/index.php/PPU_registers#PPUDATA


; The OAM (Object Attribute Memory) is internal memory inside the PPU that contains a lookup table 
; of up to 64 sprites, where each table entry consists of 4 bytes.


; ------+-----+---------------------------------------------------------------
; $2003 | W   | Sprite Memory Address
;       |     | Used to set the address of the 256-byte Sprite Memory to be 
;       |     | accessed via $2004. This address will increment by 1 after
;       |     | each access to $2004. Sprite Memory contains coordinates,
;       |     | colors, and other sprite attributes.
; ------+-----+---------------------------------------------------------------
_OAMADDR    = $2003           ; Reference: https://wiki.nesdev.com/w/index.php/PPU_registers#OAMADDR

; ------+-----+---------------------------------------------------------------
; $2004 | RW  | Sprite Memory Data
;       |     | Used to read/write the Sprite Memory. The address is set via
;       |     | $2003 and increments by 1 after each access. Sprite Memory 
;       |     | contains coordinates, colors, and other sprite attributes
;       |     | sprites.
; ------+-----+---------------------------------------------------------------
_OAMDATA    = $2004           ; Reference: https://wiki.nesdev.com/w/index.php/PPU_registers#OAMDATA

; ------+-----+---------------------------------------------------------------
; $4014 | W   | DMA Access to the Sprite Memory
;       |     | Writing a value N into this port causes an area of CPU memory
;       |     | at address $100*N to be transferred into the Sprite Memory.
;       |     | The CPU is suspended while the transfer is taking place.
; ------+-----+---------------------------------------------------------------
_OAMDMA     = $4014            ; Reference: https://wiki.nesdev.com/w/index.php/PPU_registers#OAMDMA

; - Byte 0 (Y Position)
_OAM_Y    = 0

; - Byte 1 (Tile Index)
;
; 76543210
; ||||||||
; |||||||+- Bank ($0000 or $1000) of tiles
; +++++++-- Tile number of top of sprite (0 to 254; bottom half gets the next tile)
_OAM_TILE = 1

; - Byte 2 (Attributes)
;
; 76543210
; ||||||||
; ||||||++- Palette (4 to 7) of sprite
; |||+++--- Unimplemented
; ||+------ Priority (0: in front of background; 1: behind background)
; |+------- Flip sprite horizontally
; +-------- Flip sprite vertically
_OAM_ATTR = 2

; - Byte 3 (X Position)
_OAM_X    = 3

.MACRO DisableVideoOutput
  LDA #%00000000
  STA _PPUCTRL    ; disable NMI
  STA _PPUMASK    ; disable rendering
.ENDMACRO

.MACRO EnableVideoOutput
  LDA #%10010000   ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
  ORA GameData::nametable    ; select correct nametable for bit 0
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
  LDA GameData::screenPosX
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

; clears ppu nametables and attribute data
.MACRO ClearNametables
  LDA #$20
  STA _PPUADDR
  lDA #$00
  STA _PPUADDR

  LDX #$08 ; clear 8 pages, two nametables and attributes
@page:
  LDY #$00
@clear_loop:
  STA _PPUDATA
  INY
  BNE @clear_loop
  DEX
  BNE @page
.ENDMACRO

  ; loads color and position information to RAM
.MACRO LoadPaletteData
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
.ENDMACRO 