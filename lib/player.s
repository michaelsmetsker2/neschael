;
; neschael
; lib/player.s
;

.SCOPE Player
    ; Initialization values
  I_VELOCITY_X = 0
  I_VELOCITY_Y = 0
  I_POSX_LO    = $00
  I_POSX_HI    = $03
  I_POSY_LO    = $F0
  I_POSY_HI    = $08
  I_SPRITE_X   = 143
  I_SPRITE_Y   = 143

  targetVelocityX   = $20   ; Signed Fixed Point 4.4
  velocityX         = $21   ; Signed Fixed Point 4.4
  velocityY         = $22   ; Signed Fixed Point 4.4
  
    ; these will not overflow for about 8 screens in either direction
  positionX         = $23   ; Unsigned Fixed Point 12.4
  positionY         = $25   ; Unsigned Fixed Point 12.4

  spriteX           = $27   ; Unsigned Screen Coordinates
  spriteY           = $28   ; Unsigned Screen Coordinates

    ; these could be combinded if there are less than 8 motion states
  heading           = $29   ; See `.enum Heading`, below...
  motionState       = $2A   ; See `.enum MotionState`, below...

  animationFrame    = $2B
  animationTimer    = $2C


  .ENUM Heading
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

  .SCOPE Jump
    FLOOR_HEIGHT = 143
    INITIAL_VELOCITY = $C8
    MAX_FALL_SPEED = $40
    FALL_SPEED_LO  = $01   ; deceleration while holding A
    FALL_SPEED_HI  = $04   ; deceleration while free falling
    DECELERATION_THRESHOLD = $E0 ; greater than this velocity, slow falling
                                      ; will no longer be possible, 
                                      ; TODO: tweak this to liking
  .ENDSCOPE

  .PROC init
    JSR init_x
    JSR init_y
    JSR init_sprite
  .ENDPROC

  .PROC init_x
      ; Start with no velocity
    LDA #I_VELOCITY_X
    STA targetVelocityX
    STA velocityX 
      ; Sets initial X-position to 110 or $06E0 in 12.4 fixed point
    LDA #I_SPRITE_X
    STA spriteX
    LDA #I_POSX_LO
    STA positionX
    LDA #I_POSX_HI
    STA positionX + 1
    RTS    
  .ENDPROC

  .PROC init_y
      ; start with no velocity
    LDA #I_VELOCITY_Y
    STA velocityY 
      ; Sets initial Y-position to 110 or $06E0 in 12.4 fixed point
    LDA #I_SPRITE_Y
    STA spriteY
    LDA #I_POSY_LO
    STA positionY
    LDA #I_POSY_HI
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
  .BYTE Player::I_SPRITE_Y, $0, %00000000, Player::I_SPRITE_X

  .SCOPE Movement

    .PROC update
      JSR update_vertical_motion
      ;JSR set_target_velocity_x
      ;JSR accelerate_x
      ;JSR apply_velocity_x
      ;JSR bound_position_x
      RTS
    .ENDPROC

    .PROC update_vertical_motion
      LDA motionState  
      CMP #MotionState::Airborne
      BEQ @airborne              ; branch if player is airborne
    @check_jump:
      LDA btnPressed
      AND #_BUTTON_A
      BNE @begin_jump            ; branch if a new jump is detected
      LDA #0
      STA velocityY    ; clear Y velocity in case landing? idk disabled temporarily see if it causes issues
      RTS
    @begin_jump:
      LDA #Jump::INITIAL_VELOCITY
      STA velocityY
      LDA #MotionState::Airborne
      STA motionState
      RTS
    @airborne:
      JSR update_jump_velocity
      JSR apply_velocity_y
      JSR bound_position_y
      RTS
    .endproc

    .PROC update_jump_velocity
      ; Determine if velocity decelerates slow or fest based on button hold
      LDY #Jump::FALL_SPEED_HI
      LDA velocityY
      CMP #Jump::DECELERATION_THRESHOLD
      BPL @decelerate ; fast fall if velocity over threshhold
      LDA btnDown
      AND #_BUTTON_A
      BEQ @decelerate ; fast fall if a is not held down
      LDY #Jump::FALL_SPEED_LO
    @decelerate:
      ; Perform the deceleration
      TYA
      CLC
      ADC velocityY
      ; If I want to cap max fall speed, do it here -----------------------
      STA velocityY ; store velocity
      RTS
    .ENDPROC

    .PROC apply_velocity_y ; 6502 handles negative values automatically apparently?
      LDA velocityY
      BMI @negative
      CLC
      ADC positionY
      STA positionY
      LDA #0
      ADC positionY + 1 ; add the carry to the high byte of positionY
      STA positionY + 1
      RTS
    @negative:
      LDA #0
      SEC
      SBC velocityY
      STA $00
      LDA positionY
      SEC
      SBC $00
      STA positionY
      LDA positionY + 1
      SBC #0
      STA positionY + 1
      RTS

    .ENDPROC

    .PROC bound_position_y
      ; convert from 12.4 fixed point into screen coords
      LDA positionY
      STA $00
      LDA positionY + 1
      STA $01 ; shift over four bytes
      LSR $01
      ROR $00
      LSR $01
      ROR $00      
      LSR $01
      ROR $00
      LSR $01
      ROR $00
      LDA $00
      STA spriteY

    @check_landing: ; This will need to be changed for collision
          CMP #Jump::FLOOR_HEIGHT ; remember y increases downward :)
      BCS @land
      RTS
@land:
    ; clamp position to the landing height
    LDA #00
    STA positionY + 1 ; clear high byte
    LDA #Jump::FLOOR_HEIGHT ; this will eventually be swapped with the
                              ; landing place of collided surface
    ASL A
    ROL positionY + 1
    ASL A
    ROL positionY + 1
    ASL A
    ROL positionY + 1
    ASL A
    ROL positionY + 1 
    STA positionY

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
      ;JSR update_heading
      ;JSR update_sprite_tiles
      JSR update_sprite_position
      RTS
    .ENDPROC


    .PROC update_sprite_position
      LDA spriteX
      ;STA $0200 + _OAM_X
      LDA spriteY
      STA $0200 + _OAM_Y
      RTS
    .ENDPROC

  .ENDSCOPE

.ENDSCOPE

; end of lib/player.s