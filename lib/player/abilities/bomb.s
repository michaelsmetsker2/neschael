;
; neschael
; lib/player/abilities/bomb.s
;
; contains the proccesses for the bomb down ability

.INCLUDE "lib/player/player.inc"

.IMPORT create_entity

.EXPORT bomb_init

.PROC bomb_init

    ; TODO formalize bomb cost

    ; TODO check if we have ENOUGH charge
@check_chargestate:
	LDA playerFlags
	AND #CHARGE_STATE_MASK
    BEQ @done
	
    ; check if there is already a bomb out? (or at a threshold?)
    ; if so, remove the old one?


    ; create entity
.IF 1
    LDA #$02 ; entity ID for bombEntity
    STA $0A
    LDA #$00 ; set to manually spawn entity
    STA $04
    JSR create_entity
.ENDIF


    ; remove charge?

@done:
    RTS
.ENDPROC