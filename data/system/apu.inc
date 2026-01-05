;
; neschael
; data/system/apu.inc
;
; APU-Related assembler directives and macros for nes
;

; The APU (Audio Processing Unit) is the sound hardware the NES console which generates sound.
; It is implemented in the RP2A03 (NTSC) and RP2A07 (PAL) chips.
; Its registers are mapped in the range $4000-$4013, $4015 and $4017.


; ------+-----+---------------------------------------------------------------
; $4015 | W   | Sound Channel Switch
;       |   0 | Channel 1, 1 = enable sound.
;       |   1 | Channel 2, 1 = enable sound.
;       |   2 | Channel 3, 1 = enable sound.
;       |   3 | Channel 4, 1 = enable sound.
;       |   4 | Channel 5, 1 = enable sound.
;       | 5-7 | Unused (???)
; ------+-----+---------------------------------------------------------------
_SND_CHN    = $4015        ; Reference: https://wiki.nesdev.com/w/index.php/APU#Status_.28.244015.29

; APU Square wave channels 1 and 2
; Reference: https://wiki.nesdev.com/w/index.php/APU_Pulse
_SQ1_VOL    = $4000
_SQ1_SWEEP  = $4001
_SQ1_LO     = $4002
_SQ1_HI     = $4003
_SQ2_VOL    = $4004
_SQ2_SWEEP  = $4005
_SQ2_LO     = $4006
_SQ2_HI     = $4007

; APU Triangle wave channel
; Reference: https://wiki.nesdev.com/w/index.php/APU_Triangle
_TRI_LINEAR = $4008
_TRI_LO     = $400a
_TRI_HI     = $400b

; APU Noise generator
; Reference: https://wiki.nesdev.com/w/index.php/APU_Noise
_NOISE_VOL  = $400c
_NOISE_LO   = $400e
_NOISE_HI   = $400f

; APU Delta Modulation Channel
; Reference: https://wiki.nesdev.com/w/index.php/APU_DMC
_DMC_FREQ   = $4010
_DMC_RAW    = $4011
_DMC_START  = $4012
_DMC_LEN    = $4013

; APU Frame counter
_FR_COUNTER	= $4017               ; Reference: https://wiki.nesdev.com/w/index.php/APU_Frame_Counter

.MACRO DisableAudioOutput
    LDA #%01000000
    STA _FR_COUNTER             ; Disable APU frame IRQ
    STA _DMC_FREQ               ; Disable digital sound IRQs
.ENDMACRO