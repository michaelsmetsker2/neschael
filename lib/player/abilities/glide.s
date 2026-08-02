;
; neschael
; lib/player/abilities/verticalBoost.s
;
; contains the proccesses for the glide up ability

.INCLUDE "lib/player/player.inc"
.INCLUDE "lib/game/gameData.inc"
.INCLUDE "data/system/cpu.inc"

.IMPORT update_jump_standard

.EXPORT glide_init
.EXPORT update_jump_glide

.PROC glide_init

    ; can't glide if currently on the ground
    LDA motionState
    CMP #MotionState::Grounded
    BCS @done

    ; TODO maybe check if we are currently charging?

    ; TODO init a visual effect of some kind?

    ; set state to gliding
    LDA #MotionState::Gliding
    STA motionState

@done:
    RTS
.ENDPROC

.PROC update_jump_glide

    ; check if we are still holding glide button
	LDA btnDown
	AND #_BUTTON_UP
	BEQ @end_glide
    
    ; end if there is no active charge
    LDA playerFlags
	AND #CHARGE_STATE_MASK
	BEQ @end_glide
    
    ; drain charge
    SEC
	LDA storedCharge
	SBC #$03
	STA storedCharge
	BCS @drain_done
	DEC storedCharge+1
	BPL @drain_done
	
		;stored charge is now negative, end the current charge
	LDA #$00
	STA storedCharge
	STA storedCharge+1
@reset_chargestate:
	LDA playerFlags
	AND #%11011111
	STA playerFlags
@drain_done:

    ; conditionally fuck with vertical velocity?

    ; conditionally fuck with vertical acc
    
    RTS

@end_glide:

    ; destroy visuals

    ; return to airborne motionstate    
    LDA #MotionState::Airborne
    STA motionState

    ; return to the standard update routine
    JMP update_jump_standard
.ENDPROC