;
; neschael
; lib/hud/hud.inc
;
; various consants, macros, and memory addresses realting to the heads up display/status bar and sprite zero hit.
;

  ; for use during NMI
.MACRO UpdateHud
    ; set ppu addr to the start of the hud
  LDA #>_NAMETABLE_A
  STA _PPUADDR
  LDA #$50
  STA _PPUADDR

    ; draw starting hud tiles
  LDY #$00
@tile_loop:
  LDA HUD_BUFFER, Y
  STA _PPUDATA
  INY

  CPY #$09
  BNE @tile_loop
.ENDMACRO
