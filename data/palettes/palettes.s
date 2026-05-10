;
; neschael
; data/palettes/palettes.s
;

.ENUM Palettes
  meat
  yellow
  blue
  hud
  player  
.ENDENUM

palletes:

  ; background
p_meat:
  .BYTE $07, $06, $05  
p_yellow:
  .BYTE $36, $17, $0F  
p_blue:
  .BYTE $27, $17, $0F
p_hud:
  .BYTE $30, $00, $0F   ; HUD
p_player:
  .BYTE $15, $19, $27
  
  .BYTE $3F ; background