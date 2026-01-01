;
; neschael
; lib/player.s
;
; this handles the players movement

.SCOPE Player
    ; --- Memory constants ---

    ; velocity
  targetVelocityX   = $20   ; Signed Fixed Point 8.8
  velocityX         = $22   ; Signed Fixed Point 8.8
  velocityY         = $24   ; Signed Fixed Point 8.8
    ; Subpixel location
  positionX         = $26   ; Unsigned Fixed Point 8.8
  positionY         = $28   ; Unsigned Fixed Point 8.8
    ; Screen location
  spriteX           = $2A   ; Unsigned Screen Coordinates
  spriteY           = $2B   ; Unsigned Screen Coordinates 

  motionState       = $2C   ; See `.ENUM MotionState`

  animationFrame    = $2D
  animationTimer    = $2E

  playerFlags       = $2F   ; holds various player flags in various bit positions
                            ; 0-5 unused 
                            ; 6   heading, 0 for right, 1 for left
                            ; 7   if the player has been holding A since the start of the jump

    ; Initialization values
  .SCOPE Initial
    POSITION_X = $3000 ; unsigned 8.8
    POSITION_Y = $8F00 ; unsigned 8.8
    SPRITE_X   = 143   ; screen cords
    SPRITE_Y   = 143   ; screen cords
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
    LEFT_WALK_TARGET  = $FFB0 ; signed 8.8 fixed point
  .ENDSCOPE

      TEST_ACC = $0010 ; temp ====================================================================================================== 

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
    LDA #Initial::SPRITE_X
    STA spriteX
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
    LDA #Initial::SPRITE_Y
    STA spriteY
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

  player_sprite:
    .BYTE Player::Initial::SPRITE_Y, $0, %00000000, Player::Initial::SPRITE_X

  .SCOPE Movement

    .PROC update
      JSR set_target_velocity_x
      JSR accelerate_x
      JSR update_vertical_motion ; y is after set_target_velocity_x so heading is already updated for hor boost
                                   ; and before apply_velocity_x so the boost can be applied frame one
      JSR apply_velocity_x
      JSR bound_position_x
      RTS
    .ENDPROC

    .PROC set_target_velocity_x
        ; check input, eventually use a lookup tabledepending on tile? ===========================
        ; heading is also updated in this subproccess
      LDA btnDown
      AND #_BUTTON_RIGHT
      BEQ @check_left
        ; change heading to 0 (right)
      LDA playerFlags
      AND #%10111111
      STA playerFlags
        ; set target velocity
      LDA #<Velocities::RIGHT_WALK_TARGET
      STA targetVelocityX
      LDA #>Velocities::RIGHT_WALK_TARGET
      STA targetVelocityX+1
      RTS
    @check_left:
      LDA btnDown
      AND #_BUTTON_LEFT
      BEQ @no_direction
        ; change heading to 1 (left)
      LDA playerFlags
      ORA #%01000000
      STA playerFlags
        ; set target velocity
      LDA #<Velocities::LEFT_WALK_TARGET
      STA targetVelocityX
      LDA #>Velocities::LEFT_WALK_TARGET
      STA targetVelocityX+1
      RTS
    @no_direction:
      ; heading does not change
      LDA #0
      STA targetVelocityX
      STA targetVelocityX+1
      RTS
    .ENDPROC

    .PROC accelerate_x
        ; Having a target of 0 (holding nothing) in air will not slow you down
        ;NOTE probably inneficient to check this first
      LDA targetVelocityX         
      ORA targetVelocityX+1
      BNE @accelerate             ;branch if target is not zero
      LDA motionState
      CMP #MotionState::Airborne
      BNE @accelerate             ; branch if on the ground
      RTS                         ; return early
    @accelerate:
        ; find the difference between the target and current velocities
      SEC
      LDA targetVelocityX
      SBC velocityX
      STA $02
      LDA targetVelocityX+1
      SBC velocityX+1
      STA $03

      ORA $02             ; exit if the player is at the target velocity
      BEQ @done

        ; TODO here we would determing what acceleration values to actually use depending on the surface
        ;and we would load the correct accecleration bytes into memory
      LDA #<TEST_ACC
      STA $04
      LDA #>TEST_ACC
      STA $05
       ; TODO all of that is temp ====================================================================================

        ; check sign of velocity difference
      BIT $03
      BPL @apply_acceleration ; if the difference is positive, accelerate to the right
        ; invert the acceleration if we're accelerating left
      LDA #0
      SEC
      SBC $04
      STA $04
      LDA #0
      SBC $05
      STA $05

    @apply_acceleration:
        ; add the acceleration to the velocity
      CLC
      LDA velocityX
      ADC $04
      STA velocityX
      LDA velocityX+1
      ADC $05
      STA velocityX+1

        ; recompute updated difference between velocity and target
      SEC
      LDA targetVelocityX
      SBC velocityX
      STA $06                 ; storing stuff like this is for debugging mostly, it uses cycles so if i need performance, remove
      LDA targetVelocityX+1
      SBC velocityX+1
      STA $07
        ; if the sign of the difference has flipped, then velocity was overshot
      EOR $03
      BPL @done
        ; clamp to the target on overshoot
      LDA targetVelocityX
      STA velocityX
      LDA targetVelocityX+1
      STA velocityX+1

    @done:
      RTS
    .ENDPROC


    .PROC apply_velocity_x
        ; adds the velocity to the position, simple 16 bit addition
      CLC
      LDA positionX
      ADC velocityX
      STA positionX
      LDA positionX+1
      ADC velocityX+1
      STA positionX+1
    .ENDPROC

    .PROC bound_position_x
      LDA positionX+1
      STA spriteX
      RTS ; bounding would go here ========================================================================================
    .ENDPROC

    .PROC update_vertical_motion
      LDA motionState  
      CMP #MotionState::Airborne
      BEQ @airborne              ; branch if player is airborne
    @check_jump:                 ; can only start a new jump from the ground
      LDA btnPressed
      AND #_BUTTON_A
      BNE @begin_jump            ; branch if a new jump is detected
      LDA #0
      STA velocityY              ; dont move if on the ground and not jumping ; this can be changed for colision implemenetations?
      STA velocityY+1
      RTS
    @begin_jump:
      LDA playerFlags
      ORA #%10000000               ; set the holding jump flag
      STA playerFlags
        ; add vertical velocity
      LDA #<Jump::INITIAL_VELOCITY ; update vertical velocity
      STA velocityY
      LDA #>Jump::INITIAL_VELOCITY
      STA velocityY+1
      LDA #MotionState::Airborne   ; set motionState to airborne
      STA motionState
    @horizontal_boost:
        ; don't apply horizontal boost if the player is standstill
      LDA velocityX
      BEQ @airborne 
      LDA velocityX+1
      BEQ @airborne
        ; add vertical velocity boost in heading direction
      LDA #<Jump::HORIZONRAL_BOOST
      STA $07
      LDA #>Jump::HORIZONRAL_BOOST
      STA $08      

      LDA playerFlags
      AND #%01000000   ; check heading
      BEQ @apply_boost ; if heading is left, invert the boost velocity
      LDA #0
      SEC
      SBC $07
      STA $07
      LDA #0
      SBC $08
      STA $08
    @apply_boost:
      CLC 
      LDA velocityX
      ADC $07
      STA velocityX
      LDA velocityX+1
      ADC $08
      STA velocityX+1      
      RTS
    @airborne:
      JSR update_jump_velocity
      JSR apply_velocity_y        ; these are not in update so an early exit can save cpu cycles
      JSR bound_position_y
      RTS
    .endproc

    .PROC update_jump_velocity ; this updates mid air velocity
        ; Determine if velocity decelerates slow or fest based on button hold
      LDY #0                      ; lookup table offset for BASE_FALL_SPEED
      BIT playerFlags
      BPL @decelerate             ; branch if held jump isn't set
      LDA btnDown
      AND #_BUTTON_A
      BEQ @newly_fast             ; branch if A isn't held
        ; check velocity threshold

      LDA velocityY+1
      CMP #Jump::DECELERATION_THRESHOLD
      BPL @newly_fast             ; branch if velocity is past threshold
      LDY #2                      ; SLOW_FALL_SPEED offset
      JMP @decelerate
    @newly_fast:                  ; for first times using fast falling set flag
      LDA playerFlags             ; updates the flag to save cpu cycles
      AND #%01111111
      STA playerFlags
    @decelerate: 
        ; Perform the deceleration
      CLC 
      LDA fall_speeds,Y
      ADC velocityY
      STA velocityY
      INY
      LDA fall_speeds,Y
      ADC velocityY+1
      STA velocityY+1
      RTS
    fall_speeds:
      .BYTE <Jump::BASE_FALL_DECCEL, >Jump::BASE_FALL_DECCEL
      .BYTE <Jump::SLOW_FALL_DECCEL, >Jump::SLOW_FALL_DECCEL
    .ENDPROC

    .PROC apply_velocity_y ; add current velocity to the position
      CLC
      LDA velocityY     ; low byte
      ADC positionY     ; add signed velocity low
      STA positionY
      LDA velocityY+1   ; high byte
      ADC positionY+1   ; add carry
      STA positionY+1
      RTS
    .ENDPROC

    .PROC bound_position_y
      LDA positionY+1
      STA spriteY

    @check_landing: ; This will need to be changed for collision
      CMP #Jump::FLOOR_HEIGHT ; remember y increases downward :)
      BCS @land
      RTS
    @land:
        ; clamp position to the landing height
      LDA #00
      STA positionY ; clear low byte
      LDA #Jump::FLOOR_HEIGHT
      STA positionY+1
      LDA #MotionState::Still ; update motion state, idk how this will
                                ; end up working with movement
      STA motionState
      RTS
    .ENDPROC

  .ENDSCOPE

  .SCOPE Sprite

    .PROC update
      ;JSR update_motion_state
      ;JSR update_animation_frame
      JSR update_heading
      ;JSR update_sprite_tiles
      JSR update_sprite_position
      RTS
    .ENDPROC


    .PROC update_heading
        ; heading is already set during x movement
      LDA playerFlags
      AND #%01000000
      STA $0B
      LDA $0200 + _OAM_ATTR
      AND #%10111111
      ORA $0B
      STA $0200 + _OAM_ATTR
    .ENDPROC

    .PROC update_sprite_position
      LDA spriteX
      STA $0200 + _OAM_X
      LDA spriteY
      STA $0200 + _OAM_Y
      RTS
    .ENDPROC

  .ENDSCOPE

.ENDSCOPE

; end of lib/player.s