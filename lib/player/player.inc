;
; nsechael
; lib/player/player.inc
; 
; player related memory constants, these are already allocated in the zeropage
;

.IMPORTZP PLAYER_DATA
    ; velocity
  targetVelocityX = PLAYER_DATA       ; Signed Fixed Point 8.8
  velocityX       = PLAYER_DATA + 2   ; Signed Fixed Point 8.8
  velocityY       = PLAYER_DATA + 4   ; Signed Fixed Point 8.8

    ; integer part can be used as the pixel positions of the sprite
  positionX       = PLAYER_DATA + 6   ; Unsigned Fixed Point 8.8 screen position +/- lookahead offset
  positionY       = PLAYER_DATA + 8   ; Unsigned Fixed Point 8.8

  motionState     = PLAYER_DATA + 10  ; See .ENUM MotionState

  animationTimer  = PLAYER_DATA + 11  ; determines the current frame of the walking animation

  storedVelocity  = PLAYER_DATA + 12  ; Unsigned 8.8 ammount of boost stored
  chargeCounter   = PLAYER_DATA + 14  ; counter that determines how much boost is stored per tick

  playerFlags     = PLAYER_DATA + 15  ; holds various player flags in various bit positions
                                        ; 0-4 unused
                                        ; 5   chargeState, if player is charging boost 0 for no
                                        ; 6   heading, 0 for right, 1 for left
                                        ; 7   slowJump flag if the player has been holding A since the start of the jump

  lookaheadOffset = PLAYER_DATA + 16  ; signed, cammera offset from players position in px

  ; chargable flag
  CHARGE_STATE_MASK = %00100000
  HEADING_MASK      = %01000000

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
  Still = 0 ; TODO mostly unused? combine with walk to be grounded?
  Walk = 1
  Sliding = 2 ; TODO remove due to down ability?
  Airborne = 3 
.ENDENUM