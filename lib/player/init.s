;
; neschael
; lib/player/init.s
;
; initializes and declares player related variables when loading a level
;

.SEGMENT "CODE"

.INCLUDE "lib/player/player.inc"
.INCLUDE "lib/game/gameData.inc"
.INCLUDE "data/levels/levelData.inc"

  ; スパイダーマン
.EXPORT player_init

playerTile      = $0205 ; player's sprite in OAM buffer
playerAttribute = $0206 ; player's attribute byte in OAM buffer

.PROC player_init
  ; load the starting position in pixels from the current level's data
  LDY #POSITION_OFFSET
  LDA (levelPtr),y
  STA positionX+1
  INY
  LDA (levelPtr),y
  STA positionY+1

    ; zero velocity and target velocity
  LDA #$00
  STA targetVelocityX
  STA targetVelocityX+1
  STA velocityX 
  STA velocityX+1
  STA velocityY 
  STA velocityY+1
  ; zero the low byte of the player's position
  STA positionX
  STA positionY

  RTS
.ENDPROC