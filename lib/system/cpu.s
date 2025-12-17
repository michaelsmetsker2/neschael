;
; neschael
; lib/system/cpu.inc
;
; CPU-Related assembler directives and macros for nes
;

;
; The NES's 6502 does not contain support for decimal mode. Both the
; CLD and SED opcodes function normally, but the 'd' bit of P is unused
; in both ADC and SBC. It is common practice for games to CLD prior to
; code execution, as the status of 'd' is unknown on power-on and on
; reset.
; 
; Audio registers are mapped internal to the CPU; all waveform gener-
; ation is done internal to the CPU as well.
;


;
; CPU MEMORY MAP
;
; --------------------------------------- $10000
; Upper Bank of Cartridge ROM
; --------------------------------------- $C000
; Lower Bank of Cartridge ROM
; --------------------------------------- $8000
; Cartridge RAM (may be battery-backed)
; --------------------------------------- $6000
; Expansion Modules
; --------------------------------------- $5000
; Input/Output
; --------------------------------------- $2000
; 2kB Internal RAM, mirrored 4 times
; --------------------------------------- $0000
;


_RAM_CLEAR_PATTERN_1	= $00
_RAM_CLEAR_PATTERN_2	= $FE

; Write #$01 and #$00 to latch controllers, then read from them one by one reference https://www.nesdev.org/wiki/Controller_reading
_JOYPAD_1               = $4016
_JOYPAD_2               = $4017

; Button mask bits
_BUTTON_RIGHT = %00000001
_BUTTON_LEFT  = %00000010
_BUTTON_DOWN  = %00000100
_BUTTON_UP    = %00001000
_BUTTON_START = %00010000
_BUTTON_SELECT= %00100000
_BUTTON_B     = %01000000
_BUTTON_A     = %10000000

; CPU flags (i dont trust these because the button masks misbehaved with this syntax)
_FLAG_C = %00000001  ; Carry
_FLAG_Z = %00000010  ; Zero
_FLAG_I = %00000100  ; IRQ Disable
_FLAG_D = %00001000  ; Decimal (unused on NES)
_FLAG_B = %00010000  ; Break
_FLAG_U = %00100000  ; Unused / always set
_FLAG_V = %01000000  ; Overflow
_FLAG_N = %10000000  ; Negative

.MACRO EndlessLoop
:
  JMP :-
.ENDMACRO

.MACRO ClearCpuMemory
  LDX #$00
:
  LDA #_RAM_CLEAR_PATTERN_1
  STA $0000, X
  STA $0100, X
  STA $0300, X
  STA $0400, X
  STA $0500, X
  STA $0600, X
  STA $0700, X
  LDA #_RAM_CLEAR_PATTERN_2
  STA $0200, X                ; move all sprites off-screen
  INX
  BNE :-       ; breaks on overflow
.ENDMACRO

; End of lib/system/cpu.inc