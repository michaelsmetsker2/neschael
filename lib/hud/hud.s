;
; neschael
; lib/hud/hud.s
;
; supbroccesses relating to the hud bar at the top of the screen
;

.INCLUDE "data/system/ppu.inc"
.INCLUDE "lib/player/player.inc"
.INCLUDE "lib/hud/hud.inc"
.INCLUDE "lib/game/gameData.inc"

.IMPORTZP HUD_BUFFER
.IMPORT shadowOam

.EXPORT hud_init
.EXPORT buffer_hud

  ; FIXME waste of rom space?
base_hud:
  .BYTE $00, _L, _E, _V, _E, _L, $00, $DC, $DD, $DE, $00, $DC, $DD, $DE, $00, _S, _P, _E, _E, _D, $00, _B, _O, _O, _S, _T, $00, _T, _I, _M, _E, $00
  .BYTE $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01

  ; sets sprite zero and draws hud background upon level load
.PROC hud_init

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

@set_hud_attr: ; pallete data
    ; set ppu increment mode to +1
  LDA #%00001000
  STA _PPUCTRL

    ; sets ppuAddr to start of nametable 1
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
  LDA #$40
  STA _PPUADDR

  LDY #$00
@tile_loop:
  ; set each tile
  LDA base_hud, Y
  STA _PPUDATA
  INY

  CPY #$40
  BNE @tile_loop

  RTS
.ENDPROC

  ; adds relevent data to a buffer to be quickly added to the hud during NMI
.PROC buffer_hud

  LDA #$00
  STA UP_SELECT_HUD
  STA UP_SELECT_HUD+1
  STA UP_SELECT_HUD+2
  STA DOWN_SELECT_HUD
  STA DOWN_SELECT_HUD+1
  STA DOWN_SELECT_HUD+2

  ; clear old, start anew
  LDA #_A
  LDY currentAbilityUp
  STA UP_SELECT_HUD, Y

  LDY currentAbilityDown
  STA DOWN_SELECT_HUD, Y


@buffer_speed:
  LDX velocityX
  LDY velocityX+1
    ; two's compliment if velocity is negative
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
  STA HUD_BUFFER+12
  
  TXA
  AND #%00001111
  ADC #NUMBERTILE_INDEX
  STA HUD_BUFFER+13

@high_byte:
  TYA
  LSR A
  LSR A
  LSR A
  LSR A
  ADC #NUMBERTILE_INDEX
  STA HUD_BUFFER+10
  
  TYA
  AND #%00001111
  ADC #NUMBERTILE_INDEX
  STA HUD_BUFFER+11

  LDA #$00
  STA HUD_BUFFER+14

@buffer_charge:

@lb:
  CLC
  LDA storedCharge
  LSR A
  LSR A
  LSR A
  LSR A
  ADC #NUMBERTILE_INDEX
  STA HUD_BUFFER+17
  
  LDA storedCharge
  AND #%00001111
  ADC #NUMBERTILE_INDEX
  STA HUD_BUFFER+18

@hb:
  LDA storedCharge+1
  LSR A
  LSR A
  LSR A
  LSR A
  ADC #NUMBERTILE_INDEX
  STA HUD_BUFFER+15
  
  LDA storedCharge+1
  AND #%00001111
  ADC #NUMBERTILE_INDEX
  STA HUD_BUFFER+16


  RTS
.ENDPROC