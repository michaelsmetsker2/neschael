;
; neschael
; data/palettes/palettes.inc
;


palette:
; background
  .BYTE $00, $07, $06, $05  
  .BYTE $00, $36, $17, $0F  
  .BYTE $00, $27, $17, $0F
  .BYTE $00, $30, $00, $0F   ; HUD

; sprite
  .BYTE $3F, $15, $19, $27   ; controls background color
  .BYTE $00, $02, $38, $3C
  .BYTE $00, $1C, $15, $14
  .BYTE $00, $02, $38, $3C

; fixed never changes
; set is set at level load
; dynamic is set at level load and can be changed mid level

; layout:
; background 1 dynamic
; background 2 set
; background 3 fixed, flesh
; background 4 fixed, HUD

; sprite 1 dynamic, controls background color
; sprite 2 set
; sprite 3 fixed, targets
; sprite 4 fixed, player but hat color determined on level load