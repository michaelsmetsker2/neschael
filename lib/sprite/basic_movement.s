;
; first_nes
; lib/sprite/basic_movement.s
;

; ==========================================
; Subroutine to move the Luigi sprites right
; ==========================================

.PROC     MoveLuigiRight

    lda     $0203                   ; 
    clc                             ;
    adc     #$01                    ; 
    sta     $0203                   ; Increment the Sprite0 X position

    lda     $0207                   ; 
    clc                             ;
    adc     #$01                    ; 
    sta     $0207                   ; Increment the Sprite1 X position

    lda     $020b                   ; 
    clc                             ;
    adc     #$01                    ; 
    sta     $020b                   ; Increment the Sprite2 X position
    
    lda     $020f                   ; 
    clc                             ;
    adc     #$01                    ; 
    sta     $020f                   ; Increment the Sprite3 X position

    rts

.ENDPROC


; =========================================
; Subroutine to move the Luigi sprites left
; =========================================

.PROC     MoveLuigiLeft

    lda     $0203                   ; 
    sec                             ; 
    sbc     #$01                    ; 
    sta     $0203                   ; Decrement Sprite0 X position

    lda     $0207                   ; 
    sec                             ; 
    sbc     #$01                    ; 
    sta     $0207                   ; Decrement Sprite1 X position

    lda     $020b                   ; 
    sec                             ; 
    sbc     #$01                    ; 
    sta     $020b                   ; Decrement Sprite2 X position

    lda     $020f                   ; 
    sec                             ; 
    sbc     #$01                    ; 
    sta     $020f                   ; Decrement Sprite3 X position

    rts
    
.ENDPROC


; End of lib/sprite/basic_movement.s
