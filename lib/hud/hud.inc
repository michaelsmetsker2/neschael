;
; neschael
; lib/hud/hud.inc
;
; various consants, macros, and memory addresses realting to the heads up display/status bar and sprite zero hit.
;

    ; offset in background CHR for the start of numbers and letters
  NUMBERTILE_INDEX = $DC

    ; ppu offset from start of nametable for start of the hud
  STARTING_OFFSET = $50

  ; for use during NMI
.MACRO UpdateHud
    ; set ppu addr to the start of the hud
  LDA #>_NAMETABLE_A
  STA _PPUADDR
  LDA #STARTING_OFFSET
  STA _PPUADDR

  LDY #$00
@tile_loop:
  LDA HUD_BUFFER, Y
  STA _PPUDATA
  INY

  CPY #$09
  BNE @tile_loop
.ENDMACRO
