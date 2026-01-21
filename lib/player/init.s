;
; neschael
; lib/player/init.s
;
; initializes and declares player related variables
;

.SEGMENT "CODE"

.INCLUDE "lib/player/player.inc"

.EXPORT player_init

  ; Initialization values
.SCOPE Initial
  POSITION_X = $3000 ; unsigned 8.8
  POSITION_Y = $8F00 ; unsigned 8.8
.ENDSCOPE

player_sprite:
  .BYTE <Initial::POSITION_Y, $1, %00000000, <Initial::POSITION_X

.PROC player_init
  JSR init_x
  JSR init_y
  JSR init_sprite
  RTS
.ENDPROC

.PROC init_x
    ; zero velocity and target velocity
  LDA #%00
  STA targetVelocityX
  STA targetVelocityX+1
  STA velocityX 
  STA velocityX+1
    ; Sets initial X-position to 110 or $06E0 in 12.4 fixed point
  LDA #<Initial::POSITION_X
  STA positionX
  LDA #>Initial::POSITION_X
  STA positionX+1
  RTS   
.ENDPROC

.PROC init_y
    ; zero velocity
  LDA #$00
  STA velocityY 
  STA velocityY+1
    ; Set initial Y-position
  LDA #<Initial::POSITION_Y
  STA positionY
  LDA #>Initial::POSITION_Y
  STA positionY + 1
  RTS
.ENDPROC

.PROC init_sprite
  LDX #$00
@loop:
  LDA player_sprite, x
  STA $0200, x         ; Write to OAM buffer in CPU RAM
  INX
  CPX #4
  BNE @loop
  RTS
.ENDPROC
