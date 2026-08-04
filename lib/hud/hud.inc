;
; neschael
; lib/hud/hud.inc
;
; various consants, macros, and memory addresses realting to the heads up display/status bar and sprite zero hit.
;

    ; offset in background CHR for the start of numbers and letters
  NUMBERTILE_INDEX = $DC
  LETTERTIEL_INDEX = $E6
  _A = $E6
  _B = $E7
  _C = $E8
  _D = $E9
  _E = $EA
  _F = $EB
  _G = $EC
  _H = $ED
  _I = $EE
  _J = $EF
  _K = $F0
  _L = $F1
  _M = $F2
  _N = $F3
  _O = $F4
  _P = $F5
  _Q = $F6
  _R = $F7
  _S = $F8
  _T = $F9
  _U = $FA
  _V = $FB
  _W = $FC
  _X = $FD
  _Y = $FE
  _Z = $FF

    ; ppu offset from start of nametable for start of the hud
  STARTING_OFFSET = $6A

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
