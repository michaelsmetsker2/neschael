;
; first_nes
; lib/isr/custom.s
;
; This Interrupt Service Routine is called when a BRK instruction is executed. This is a good
; location to place custom code, which will then trigger with every BRK instruction. Note that
; this interrupt is maskable (IRQ).
;

.SEGMENT "CODE"

.EXPORT isr_custom

.PROC isr_custom

    NOP  ; Do nothing

    RTI  ; Return from interrupt
    
.ENDPROC