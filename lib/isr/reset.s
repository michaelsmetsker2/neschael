;
; neschael
; lib/isr/reset.s
;
; This Interrupt Service Routine is called when the NES is reset, including when it is turned on.
;
.SEGMENT "CODE"

.INCLUDE "data/palettes/palettes.inc"

.INCLUDE "data/system/ppu.inc"
.INCLUDE "data/system/apu.inc"
.INCLUDE "data/system/cpu.inc"

.IMPORT main

.EXPORT isr_reset

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
  ClearNametables
  JSR wait_for_vblank

  LoadPaletteData

  JMP main
  RTS         ; This should never be called
.ENDPROC 

; waits for the vblank flag, this is slightly inconsist and
  ; NMI should be used instead
.PROC wait_for_vblank
  @vblank_wait_loop:
  BIT _PPUSTATUS
  BPL @vblank_wait_loop
  RTS
.ENDPROC