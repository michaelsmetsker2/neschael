;
; neschael
; lib/isr/reset.s
;
; This Interrupt Service Routine is called when the NES is reset, including when it is turned on.
;

.PROC isr_reset

  ; ---------------------------------------------------------------------------------------------
  ; Initialization sequence for the NES.
  ; ---------------------------------------------------------------------------------------------
  SEI             ; disable IRQs, at least until we are ready to handle them
  CLD             ; disable decimal mode
  LDX #$FF
  TXS             ; Set up stack with value 255
  
  DisableVideoOutput
  DisableAudioOutput

  BIT _PPUSTATUS  ; Clears VBlank flag
  ; ---------------------------------------------------------------------------------------------
  ; When the system is first turned on or reset, the PPU may not be in a usable state right
  ; away. Wait wait for 2 vertical blank intervals.
  ; ---------------------------------------------------------------------------------------------

  JSR wait_for_vblank
  ClearCpuMemory
  JSR wait_for_vblank

  JMP main
  RTS         ; This should never be called
.ENDPROC 

; End of lib/isr/reset.s