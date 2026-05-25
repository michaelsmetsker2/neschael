;
; neschael
; lib/player/abilities/abilities
;
; contains the proccesses executed when activating an up or down ability
;

.INCLUDE "lib/player/player.inc"

.EXPORT vertical_boost

  ; uses stored velocity to propel the player updwards
.PROC vertical_boost

@check_chargestate:
	LDA playerFlags
	AND #CHARGE_STATE_MASK
  BEQ @done
	
    ; set motionState to airborne
  LDA #MotionState::Airborne
  STA motionState
    ; set slowfall flag to false for consistancy
  LDA playerFlags
  AND #%01111111
  STA playerFlags

  LDA #$B0
  STA velocityY
  LDA #$FC
  STA velocityY+1

  SEC
  LDA velocityY
  SBC storedCharge
  STA velocityY
  LDA velocityY+1
  SBC storedCharge+1
  STA velocityY+1

  LSR storedCharge+1
  ROR storedCharge
  LSR storedCharge+1
  ROR storedCharge

  SEC
  LDA velocityX
  SBC storedCharge
  STA velocityX
  LDA velocityX+1
  SBC storedCharge+1
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