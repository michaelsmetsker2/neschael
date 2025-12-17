;
; neschael
; lib/player.s
;

.SCOPE Player
  targetVelocityX   = $30   ; Signed Fixed Point 4.4
  velocityX         = $31   ; Signed Fixed Point 4.4
  positionX         = $32   ; Signed Fixed Point 12.4
  spriteX           = $34   ; Unsigned Screen Coordinates
  heading           = $35   ; See `.enum Heading`, below...

  velocityY         = $36   ; Signed Fixed Point 4.4
  positionY         = $37   ; Signed Fixed Point 12.4
  spriteY           = $39   ; Unsigned Screen Coordinates

  motionState       = $3A   ; See `.enum MotionState`, below...
  animationFrame    = $3B
  animationTimer    = $3C
  idleState         = $3D   ; See `.enum IdleState`, below...
  idleTimer         = $3E

  .SCOPE Initial

  .ENDSCOPE

  .PROC init

  .ENDPROC  


  .SCOPE Movement
    .PROC update
      RTS
    .ENDPROC
  .ENDSCOPE

  .SCOPE Sprite
    .PROC update
      RTS
    .ENDPROC
  .ENDSCOPE




.ENDSCOPE

; end of lib/player.s