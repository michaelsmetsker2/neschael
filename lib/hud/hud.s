;
; neschael
; lib/hud/hud.s
;
; supbroccesses relating to the hud bar at the top of the screen
;

.INCLUDE "data/system/ppu.inc"
.INCLUDE "lib/player/player.inc"

.IMPORTZP HUD_BUFFER
.IMPORT   shadowOam

.EXPORT   hud_init
.EXPORT buffer_hud

  ; draw the hud upon level load
.PROC hud_init

  HUD_START_OFFSET = $40 ; ppu offset from nametable 1, skips first two tile rows (overscan) 

  SPRITE_ZERO_Y    = $1D
  SPRITE_ZERO_TILE = $FF
  SPRITE_ZERO_ATTR = $00
  SPRITE_ZERO_X    = $FE

@set_sprite_zero:
  LDA #SPRITE_ZERO_Y
  STA shadowOam
  LDA #SPRITE_ZERO_TILE
  STA shadowOam+1
  LDA #SPRITE_ZERO_ATTR
  STA shadowOam+2
  LDA #SPRITE_ZERO_X
  STA shadowOam+3

@set_hud_attr:
    ; set ppu increment mode to +1
  LDA #%00001000
  STA _PPUCTRL

    ; set the palette for hud
  LDA #>_ATTR_A
  STA _PPUADDR
  LDA #<_ATTR_A
  STA _PPUADDR

  LDY #$00
@loop:
  LDA #$FF      ; pallete 3 for all
  STA _PPUDATA
  INY
  CPY #$08      ; loop through first row
  BNE @loop

@draw_base_hud:
    ; set ppu addr to the start of the hud
  LDA #>_NAMETABLE_A
  STA _PPUADDR
  LDA #HUD_START_OFFSET
  STA _PPUADDR

    ; draw starting hud tiles
  LDY #$C0
@tile_loop:
  STY _PPUDATA
  INY

  CPY #$00
  BNE @tile_loop

  RTS
.ENDPROC

  ; adds relevent data to a buffer to be quickly added to the hud during NMI
.PROC buffer_hud
    ; offset in background CHR for the start of numbers and letters
  NUMBERTILE_INDEX = $DC

@buffer_speed:
  LDX velocityX
  LDY velocityX+1
    ; twos compliment if velocity is negative
  TYA
  BPL @low_byte
  TXA
  EOR #$FF
  TAX       ; Invert low byte
  TYA
  EOR #$FF
  TAY       ; Invert high byte
  INX       ; add one
  BNE @low_byte
  INY
@low_byte:
  CLC
  TXA
  LSR A
  LSR A
  LSR A
  LSR A
  ADC #NUMBERTILE_INDEX
  STA HUD_BUFFER+2
  
  TXA
  AND #%00001111
  ADC #NUMBERTILE_INDEX
  STA HUD_BUFFER+3

@high_byte:
  TYA
  LSR A
  LSR A
  LSR A
  LSR A
  ADC #NUMBERTILE_INDEX
  STA HUD_BUFFER
  
  TYA
  AND #%00001111
  ADC #NUMBERTILE_INDEX
  STA HUD_BUFFER+1

  LDA #$00
  STA HUD_BUFFER+4

@buffer_charge:

@lb:
  CLC
  LDA storedCharge
  LSR A
  LSR A
  LSR A
  LSR A
  ADC #NUMBERTILE_INDEX
  STA HUD_BUFFER+7
  
  LDA storedCharge
  AND #%00001111
  ADC #NUMBERTILE_INDEX
  STA HUD_BUFFER+8

@hb:
  LDA storedCharge+1
  LSR A
  LSR A
  LSR A
  LSR A
  ADC #NUMBERTILE_INDEX
  STA HUD_BUFFER+5
  
  LDA storedCharge+1
  AND #%00001111
  ADC #NUMBERTILE_INDEX
  STA HUD_BUFFER+6


  RTS
.ENDPROC