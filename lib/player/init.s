;
; neschael
; lib/player/init.s
;
; initializes and declares player related variables when loading a level
;

.SEGMENT "CODE"

.INCLUDE "lib/player/player.inc"
.INCLUDE "lib/game/gameData.inc"
.INCLUDE "lib/game/levelData.inc"

playerTile      = $0205 ; player's sprite in OAM buffer
playerAttribute = $0206 ; player's attribute byte in OAM buffer

  ; スパイダーマン
.EXPORT player_init

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

  ; set the player's OAM sprite data
  STA playerAttribute
  LDA #$01
  STA playerTile

  RTS
.ENDPROC