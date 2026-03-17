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
  LDA #$01
  STA $0201
  STA $0202
  STA $0203

; set ppu increment mode to +1
  LDA #%00001000
  STA _PPUCTRL

; TODO set row of nametables all to hud pallete


; draw hud tles  
  LDX #>_NAMETABLE_A
  STX _PPUADDR
  LDA #HUD_START_OFFSET
  STA _PPUADDR

  LDY #$C0
@loop:
  LDA #$B1
  STY _PPUDATA
  INY

  CPY #$00
  BNE @loop

  RTS
.ENDPROC