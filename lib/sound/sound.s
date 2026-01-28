;
; neshael
; lib/sound/sound.s
;
; main sound engine, and subproccesses to interface with it
;

.INCLUDE "data/system/apu.inc"
.INCLUDE "lib/game/gameData.inc"

.INCLUDE "lib/sound/sound.inc"

.EXPORT audio_init
.EXPORT stop_sound
.EXPORT play_sound_frame

  NUM_STREAMS = $06 ; number of audio streams,

; initializes the sound system
.PROC audio_init
  ; enable channels
  EnableAudioOutput
  ; silence channels
  LDA #$30
  STA _SQ1_VOL
  STA _SQ2_VOL
  LDA #$80
  STA _TRI_LINEAR
  ; set audioFlag
  LDA gameFlags
  ORA #%00100000
  STA gameFlags
  RTS
.ENDPROC

.PROC stop_sound
  ; disable all channels
  DisableAudioOutput
  ; clear audioFlag
  LDA gameFlags
  AND #%11011111
  STA gameFlags
  RTS
.ENDPROC

.PROC play_sound_frame
  ; check audioFlag
  LDA gameFlags
  AND #%00100000
  BEQ @done      ; return if not set

  LDX #$00
@loop:          ; loop through all audio streams

  NOP ; TODO



  INX
  CPX #NUM_STREAMS
  BNE @loop
@done:
  RTS
.ENDPROC