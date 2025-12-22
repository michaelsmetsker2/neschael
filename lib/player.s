;
; neschael
; lib/player.s
;
; this handles the players movement
;1010000011101100

;reminder, may need to worry about walking off platforms

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
    ; world position
  scrollX           = $2C   ; Unisgned Fixed point 16.8

  motionState       = $2F   ; See `.ENUM MotionState`

  animationFrame    = $30
  animationTimer    = $31

  playerFlags       = $32   ; holds various player flags in various bit positions
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
    SLOW_FALL_DECCEL       = $50   ; deceleration while holding A
    BASE_FALL_DECCEL       = $70   ; deceleration while free falling
    DECELERATION_THRESHOLD = $E0   ; greater than this velocity, slow falling
  .ENDSCOPE

  .SCOPE Velocities
    RIGHT_WALK_TARGET = $0028 ; signed 8.8 fixed point
    LEFT_WALK_TARGET  = $80D8 ; signed 8.8 fixed point
  .ENDSCOPE

  .ENUM Heading ; direction player is facing
    Right = 0
    Left = 1
  .ENDENUM

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
      JSR update_vertical_motion
      JSR set_target_velocity_x
      JSR accelerate_x
      JSR apply_velocity_x
      JSR bound_position_x
      RTS
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

      LDA #<Jump::INITIAL_VELOCITY ; update vertical velocity
      STA velocityY
      LDA #>Jump::INITIAL_VELOCITY
      STA velocityY+1
      LDA #MotionState::Airborne   ; set motionState to airborne
      STA motionState
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
      CMP #Jump::DECELERATION_THRESHOLD    ; NOTE: this only works as both are negative
      BPL @newly_fast             ; branch if velocity is past threshhold
      LDY #2                      ; SLOW_FALL_SPEED offset
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

    .PROC apply_velocity_y ; 6502 handles negative values automatically
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

    .PROC set_target_velocity_x ; TODO change values if aurborne or not =====================================================================
      ; check input
      LDA btnDown
      AND #_BUTTON_RIGHT
      BEQ @check_left
      LDA #<Velocities::RIGHT_WALK_TARGET
      STA targetVelocityX
      LDA #>Velocities::RIGHT_WALK_TARGET
      STA targetVelocityX+1
      
      RTS
    @check_left:
      LDA btnDown
      AND #_BUTTON_LEFT
      BEQ @no_direction
      LDA #<Velocities::LEFT_WALK_TARGET
      STA targetVelocityX
      LDA #>Velocities::LEFT_WALK_TARGET
      STA targetVelocityX+1
      RTS
    @no_direction:
      LDA #0
      STA targetVelocityX
      RTS
    .ENDPROC

    .PROC accelerate_x
      LDA motionState
      CMP #MotionState::Airborne
      BNE @accelerate
    @airborne:
      ; No friction in the air, ignore zero velocity
      LDA targetVelocityX
      BNE @check_directional_velocity  
      RTS 
    @check_directional_velocity:
      LDA velocityX
      BMI @negative
    @positive:
      ; Only accelerate if the target velocity is higher
      CMP targetVelocityX
      BCC @accelerate
      RTS
    @negative:
      CMP targetVelocityX
      BCS @accelerate
      RTS
    @accelerate:
      LDA velocityX
      SEC
      SBC targetVelocityX
      BNE @check_greater
      RTS ; at current targer velocity
    @check_greater: ; player is grounded and needs to slow down
      BMI @lesser
      DEC velocityX ; lookup table should be made for different accelerations ===================================================================================
      RTS
    @lesser: ; velocity needs to raise
      INC velocityX ; lookup table should be made for different accelerations ===================================================================================
      RTS
    .ENDPROC
      
    .PROC apply_velocity_x
      ; Check to see the direction were moving in
      LDA velocityX
      BMI @negative
    @positive:
      ; add the 4.4 to the 12.4
      CLC
      ADC positionX
      STA positionX
      LDA #0
      ADC positionX + 1
      STA positionX + 1
      RTS
    @negative:
      ; probably is a better way to do this, inverts negative then subtracts it
      LDA #0
      SEC
      SBC velocityX
      STA $00
      LDA positionX
      SEC
      SBC $00
      STA positionX
      LDA positionX + 1
      SBC #0
      STA positionX + 1
      RTS
    .ENDPROC

    .PROC bound_position_x
      ; convert fixed point position into screen coords
      LDA positionX
      STA $00
      LDA positionX + 1
      STA $01
      LSR $01
      ROR $00
      LSR $01
      ROR $00
      LSR $01
      ROR $00
      LSR $01
      ROR $00
      
      LDA $00
      STA spriteX
    RTS ; bounding would go here ========================================================================================
    .ENDPROC

  .ENDSCOPE

  .SCOPE Sprite

    .PROC update
      ;JSR update_motion_state
      ;JSR update_animation_frame
      ;JSR update_heading
      ;JSR update_sprite_tiles
      JSR update_sprite_position
      RTS
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