;
; neschael
; lib/player/abilities/abilities
;
; contains the proccesses executed when activating an up or down ability
;

.INCLUDE "lib/player/player.inc"

.EXPORT vertical_boost

  ; uses stored velocity to propell the player upward
.PROC vertical_boost

BASE_VERT_BOOST_VELOCITY = $FCC0

@check_chargestate:
	LDA playerFlags
	AND #CHARGE_STATE_MASK
  BEQ @done
	
    ; set motionState to airborne
  LDA #MotionState::Airborne
  STA motionState
    ; set slowfall flag to false for consistant jump height
  LDA playerFlags
  AND #%01111111
  STA playerFlags

@boost_y:
    ; set the base boost velocity
  LDA #<BASE_VERT_BOOST_VELOCITY
  STA velocityY
  LDA #>BASE_VERT_BOOST_VELOCITY
  STA velocityY+1
    ; add the stored charge to the base
  SEC
  LDA velocityY
  SBC storedCharge
  STA velocityY
  LDA velocityY+1
  SBC storedCharge+1
  STA velocityY+1

@boost_x:
    ; storedCharge / 4 is the horizontal boost velocity
  LSR storedCharge+1
  ROR storedCharge
  LSR storedCharge+1
  ROR storedCharge
    ; branch to apply the horizontal velocity in the correct direction
  LDA playerFlags
  AND #HEADING_MASK
  BEQ @right

@left:
  SEC
  LDA velocityX
  SBC storedCharge
  STA velocityX
  LDA velocityX+1
  SBC storedCharge+1
  STA velocityX+1
  JMP @reset_charge

@right:
  CLC
  LDA velocityX
  ADC storedCharge
  STA velocityX
  LDA velocityX+1
  ADC storedCharge+1
  STA velocityX+1

@reset_charge:
	LDA #$00
	STA storedCharge
	STA storedCharge+1
@reset_chargestate:
	LDA playerFlags
	AND #%11011111
	STA playerFlags

@done:
  RTS
.ENDPROC