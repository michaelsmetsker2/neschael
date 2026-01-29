;
; nsechael
; lib/player/player.inc
; 
; player related memory constants, these are already allocated in the zeropage
;

    ; velocity
  targetVelocityX   = $20   ; Signed Fixed Point 8.8
  velocityX         = $22   ; Signed Fixed Point 8.8
  velocityY         = $24   ; Signed Fixed Point 8.8

    ; integer part can be used as the pixel positions of the sprite
  positionX         = $26   ; Unsigned Fixed Point 8.8
  positionY         = $28   ; Unsigned Fixed Point 8.8

  motionState       = $2A   ; See .ENUM MotionState

  animationTimer    = $2B   ; determines the current frame of the walking animation

  playerFlags       = $2C   ; holds various player flags in various bit positions
                            ; 0-4 unused
                            ; 5   chargeState, if player is charging boost 0 for no
                            ; 6   heading, 0 for right, 1 for left
                            ; 7   if the player has been holding A since the start of the jump

  storedVelocity   = $2D   ; Unsigned 8.8 ammount of boost stored
  chargeTarget     = $2F   ; Unsigned 8.8 magnitude of velocit when charge started

.SCOPE Jump
  MAX_FALL_SPEED         = $07FF ; max fall speed to prevent tunneling
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

  TEST_ACC = $0011 ; TODO temp ====================================================================================================== 

.ENUM MotionState
  Still = 0
  Walk = 1
  Sliding = 2 ; TODO remove due to down ability?
  Airborne = 3 
.ENDENUM