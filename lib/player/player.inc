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

    ; high byte is pixel position
  positionX       = PLAYER_DATA + 6   ; Unsigned Fixed Point 8.8 screen position +/- lookahead offset
  positionY       = PLAYER_DATA + 8   ; Unsigned Fixed Point 8.8

  motionState     = PLAYER_DATA + 10  ; See .ENUM MotionState

  animationTimer  = PLAYER_DATA + 11  ; determines the current frame of the walking animation

  storedCharge    = PLAYER_DATA + 12  ; Unsigned 8.8 ammount of velocity stored
  chargeCounter   = PLAYER_DATA + 14  ; counter that determines how much boost is stored per tick

  playerFlags     = PLAYER_DATA + 15  ; holds various player flags in various bit positions
                                        ; 0-1 slopeJump   if the player is jumping on a slope, set to 2, disables x collision to avoid snagging for 2 frames
                                        ; 2-4 unused
                                        ; 5   chargeState if player is charging boost 0 for no
                                        ; 6   heading     0 for right, 1 for left
                                        ; 7   slowJump    flag if the player has been holding A since the start of the jump

  lookaheadOffset = PLAYER_DATA + 16  ; signed, cammera offset from players position in px

  SLOPE_JUMP_MASK   = %00000011
  HEADING_MASK      = %01000000

.SCOPE Jump
  MAX_FALL_SPEED         = $07FF ; max fall speed to prevent tunneling
  INITIAL_VELOCITY       = $FC00 ; signed fixed point 8.8 
  HORIZONRAL_BOOST       = $0080 ; amount to slightly boost movement speed when jumping
  SLOW_FALL_DECCEL       = $25   ; deceleration while holding A
  BASE_FALL_DECCEL       = $6B   ; deceleration while free falling
  DECELERATION_THRESHOLD = $FE   ; force slow falling when velocity is greater than this
.ENDSCOPE

.SCOPE Velocities
  RIGHT_WALK_TARGET = $0150 ; signed 8.8 fixed point
  LEFT_WALK_TARGET  = $FEB0 ; signed 8.8 fixed point
.ENDSCOPE

  TEST_ACC = $0011 ; TODO temp

.ENUM MotionState
  Airborne = 0
  Grounded = 1
  SteepSlopeUp = 2
  ShallowSlopeUp = 3
  SteepSlopeDown = 4
  ShallowSlopeDown = 5
.ENDENUM

  SLOPE_STATES_START = MotionState::SteepSlopeUp ; motionstates above this are all sloped