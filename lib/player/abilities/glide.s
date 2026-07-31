;
; neschael
; lib/player/abilities/verticalBoost.s
;
; contains the proccesses for the glide up ability

.INCLUDE "lib/player/player.inc"

.EXPORT glide_ability

.PROC glide_ability
    ; TODO implement

    ; see if we are already gliding

    ; see if we initiate a glide (grounded, or currently charging)


    ; make sure we have enough charge to glide

    ; drain charge
    LDA storedCharge
    LDA storedCharge+1


    ; fuck with vertical velocity?

    ; fuck with vertical acceleration


    RTS
.ENDPROC