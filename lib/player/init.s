;
; neschael
; lib/player/init.s
;
; initializes and declares player related variables
;

    ; === Memory constants ===

    ; velocity
  targetVelocityX   = $20   ; Signed Fixed Point 8.8
  velocityX         = $22   ; Signed Fixed Point 8.8
  velocityY         = $24   ; Signed Fixed Point 8.8

    ; integer part can be used as the pixel positions of the sprite
  positionX         = $26   ; Unsigned Fixed Point 8.8
  positionY         = $28   ; Unsigned Fixed Point 8.8

  motionState       = $2A   ; See `.ENUM MotionState`

  animationFrame    = $2B
  animationTimer    = $2C

  playerFlags       = $2D   ; holds various player flags in various bit positions
                            ; 0-5 unused 
                            ; 6   heading, 0 for right, 1 for left
                            ; 7   if the player has been holding A since the start of the jump

  player_sprite:
    .BYTE <Player::Initial::POSITION_Y, $0, %00000000, <Player::Initial::POSITION_X

    ; Initialization values
  .SCOPE Initial
    POSITION_X = $3000 ; unsigned 8.8
    POSITION_Y = $8F00 ; unsigned 8.8
  .ENDSCOPE

  .SCOPE Jump
    FLOOR_HEIGHT           = 143   ; screen cords temp ============================
    INITIAL_VELOCITY       = $FC00 ; signed fixed point 8.8 
    HORIZONRAL_BOOST       = $0080 ; amount to slightly boost movement speed when jumping
    SLOW_FALL_DECCEL       = $25   ; deceleration while holding A
    BASE_FALL_DECCEL       = $6B   ; deceleration while free falling
    DECELERATION_THRESHOLD = $FE   ; greater than this velocity, slow falling
  .ENDSCOPE

  .SCOPE Velocities
    RIGHT_WALK_TARGET = $0150 ; signed 8.8 fixed point
    LEFT_WALK_TARGET  = $FEB0 ; signed 8.8 fixed point
  .ENDSCOPE

      TEST_ACC = $0010 ; TODO temp ====================================================================================================== 

  .ENUM MotionState
    Still = 0
    Walk = 1
    Pivot = 2 ; actively turning around
    Airborne = 3 
    Sliding = 4
  .ENDENUM

  .PROC init
    JSR init_x
    JSR init_y
    JSR init_sprite
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

; end of lib/player/init.s