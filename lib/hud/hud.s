;
; neschael
; lib/hud/hud.s
;
; supbroccesses relating to the hud bar at the top of the screen
;

.INCLUDE "/data/system/ppu.inc"

.EXPORT hud_init

  ; draw the hud upon level load
.PROC hud_init

  HUD_START_OFFSET = $40 ; ppu offset from nametable 1, skips first two tile rows (overscan) 

    ; sprite zero
  LDA #$1D
  STA $0200
  LDA #$FF
  STA $0201
  LDA #$00
  STA $0202
  LDA #$FE
  STA $0203

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