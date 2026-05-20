;
; neschael
; lib/game/game.s
;
; main game loop subroutines
;

.INCLUDE "data/system/cpu.inc"
.INCLUDE "data/system/ppu.inc"
.INCLUDE "data/levels/levelData.inc"
.INCLUDE "lib/game/gameData.inc"

.IMPORT decompress_nametable

.IMPORT level_index_low
.IMPORT level_index_high

.IMPORT draw_first_screen
.IMPORT player_init
.IMPORT entities_init
.IMPORT hud_init

.IMPORT palettes

.EXPORT game_init
.EXPORT read_joypad_1
.EXPORT level_init

.PROC game_init

  ; maybe here i set the fixed paletes and only set dynamic ones on level load 
  ; TODO still empty.

  RTS
.ENDPROC

.PROC level_init
    ; disable output as we will be drawing to the ppu
  DisableVideoOutput 

@clear_level_flag:
  LDA #%11101111
  AND gameFlags
  STA gameFlags

  ClearOamMemory ; remove all current sprites
  JSR entities_init
  
  ; set the level pointer to the id of levelID
  LDY levelId
  LDA level_index_low,Y
  STA levelPtr
  LDA level_index_high,Y
  STA levelPtr+1

  JSR load_level_palettes

    ; TODO set music for current level and clear audio streams

@decompress_starting_nametables:
    ; reset scroll variables so the correct backgrounds load
  LDA #$00
  STA nametable
  STA screenPosX+1
    ; decompress second nametable normally
  JSR decompress_nametable
    ; change primary nametable and scroll pos to decompress first nametable
  LDA #$01
  STA nametable
  LDA #$FF
  STA screenPosX+1
  JSR decompress_nametable
    ; reset values
  LDA #$00
  STA nametable
  STA screenPosX+1

  JSR draw_first_screen
  JSR hud_init
  JSR player_init

  EnableVideoOutput
  RTS

.ENDPROC

  ; loads the data from the pallete tables referenced in the current level's data to the ppu
.PROC load_level_palettes
  LDA _PPUSTATUS           ; read PPU status to reset the high/low latch
  LDA #>_PALETTE_RAM
  STA _PPUADDR             ; write the high byte of the palette RAM
  LDA #<_PALETTE_RAM
  STA _PPUADDR             ; write the low byte of the palette RAM

  LDY #PALETTE_OFFSET ; palette loop index
    ; loop through all 8 of the pallets
@palette_loop:
  LDA (levelPtr), Y ; get the index of the palette to load
    ; multiply index by 3 to get index byte offset
  STA $00
  ASL A
  CLC
  ADC $00
  TAX

    ; store arbitrary value in the first byte
  STA _PPUDATA
    ; copy the palettes three bytes to the PPU
  LDA palettes, X
  STA _PPUDATA  
  INX
  LDA palettes, X
  STA _PPUDATA  
  INX
  LDA palettes, X
  STA _PPUDATA    
  
  INY
  CPY #PALETTE_OFFSET+8
  BNE @palette_loop

@set_background_color:
  LDA #>_PALETTE_RAM
  STA _PPUADDR             ; write the high byte of the palette RAM
  LDA #<_PALETTE_RAM
  STA _PPUADDR             ; write the low byte of the palette RAM

  LDY #BACKGROUND_COLOR_OFFSET
  LDA (levelPtr), Y
  STA _PPUDATA

  RTS
.ENDPROC

.PROC read_joypad_1
    ; read button presses from joypad 1 and find what are new presses
  LDA btnDown
  TAY              ; store previousely held inputs in Y
  LDA #1
  STA _JOYPAD_1    ; latch buttons states
  STA btnDown      ; Clear pressed buttons
  LSR              ; A = 0
  STA _JOYPAD_1    ; release button latch
@loop:             ; Fill btnDown with all buttons down
  LDA _JOYPAD_1
  LSR
  ROL btnDown
  BCC @loop
  TYA
  EOR btnDown
  and btnDown
  STA btnPressed  ; Fill buttonPressed with only new presses
  RTS
.ENDPROC