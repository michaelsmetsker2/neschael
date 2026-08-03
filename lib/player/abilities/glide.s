;
; neschael
; lib/player/abilities/verticalBoost.s
;
; contains the proccesses for the glide up ability

.INCLUDE "lib/player/player.inc"
.INCLUDE "lib/game/gameData.inc"
.INCLUDE "data/system/cpu.inc"

.IMPORT update_jump_standard
.IMPORT reset_charge

.IMPORT create_entity

.EXPORT glide_init
.EXPORT update_jump_glide

.PROC glide_init

    ; can't glide if currently on the ground
    LDA motionState
    CMP #MotionState::Grounded
    BCS @done

    ; TODO make entity of visual effects
    ; TODO formalize
    LDA #$01 ; entity ID for glideFlames
    STA $0A
    LDA #$00
    STA $04
    JSR create_entity

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
    
@lower_charge:
    SEC
	LDA storedCharge
	SBC #GLIDE_CHARGE_DRAIN
	STA storedCharge
	BCS @drain_done
	DEC storedCharge+1
	BPL @drain_done
		; charge is negative, reset
    JSR reset_charge
@drain_done:

    ; check if we are moving down
    LDA velocityY+1
    BMI @return_to_standard

    ; set to velocity to the glide constant
    LDA #<Jump::GLIDE_VELOCITY
    STA velocityY
    LDA #>Jump::GLIDE_VELOCITY
    STA velocityY+1
    
    RTS
@end_glide:

    ; destroy visuals

    ; return to airborne motionstate    
    LDA #MotionState::Airborne
    STA motionState

@return_to_standard:
    ; return to the standard update routine
    JMP update_jump_standard
.ENDPROC