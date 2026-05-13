;
; neschael
; data/palettes/palettes.s
; 
; background and sprite palettes ordered for ppu copying during level load

.EXPORT palettes

palettes:

  ; background
p_meat:
  .BYTE $07, $06, $05  
p_yellow:
  .BYTE $36, $17, $0F  
p_blue:
  .BYTE $27, $17, $0F
p_hud:
  .BYTE $30, $00, $0F
p_player:
  .BYTE $15, $19, $27