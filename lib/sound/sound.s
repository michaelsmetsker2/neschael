;
; neshael
; lib/sound/sound.s
;
; main sound engine, and subproccesses to interface with it
; TODO figure out:
;  The sweep units can silence the square channels in certain situations 
;  (Periods >= $400, our lowest notes), even when disabled.  We'll have to take a quick look at the sweep unit ports to solve this problem. 
;

.INCLUDE "data/system/apu.inc"
.INCLUDE "lib/game/gameData.inc"

.INCLUDE "lib/sound/sound.inc"

.IMPORTZP SCRATCH

.IMPORTZP AUDIO_STREAM_SOUND_ID
.IMPORTZP AUDIO_STREAM_STATUS
.IMPORTZP AUDIO_STREAM_CHANNEL
.IMPORTZP AUDIO_STREAM_VOL_DUTY
.IMPORTZP AUDIO_STREAM_NOTE_HI
.IMPORTZP AUDIO_STREAM_NOTE_LOW

  ; sound index lookup tables
.IMPORT sound_index_high
.IMPORT sound_index_low

.EXPORT audio_init
.EXPORT stop_sound
.EXPORT load_sound
.EXPORT play_sound_frame

  NUM_STREAMS = $06 ; number of audio streams

  ; initializes the sound system
.PROC audio_init
    ; enable channels
  EnableAudioOutput
    ; silence all channels
  LDA #$30
  STA _SQ1_VOL
  STA _SQ2_VOL
  STA _NOISE_VOL
  LDA #%10000000
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

  ; should be called with the sound ID in ACC
.PROC load_sound

  soundPointer   = SCRATCH   ; pointer to sound to parse
  channelCounter = SCRATCH+2 ; loop index for parsing channels  
  soundId        = SCRATCH+3 ; id of the sound being loaded

  STA soundID ; store fore later
  TAY
    ; set pointer to header of sound to load
  LDA sound_index_low, Y
  STA soundPointer
  LDA sound_index_high, Y
  STA soundPointer+1

    ; get number of streams
  LDY #SOUND_STREAM_OFFSET
  LDA (soundPointer), Y
  STA channelCounter

@stream_loop:
  INY
  LDA (soundPointer), Y ; stream id, used for offset to place header data at the correct offset
  TAX

  INY
  LDA (soundPointer), Y ; status byte 
  STA AUDIO_STREAM_STATUS, X

  INY
  LDA (soundPointer), Y ; channel byte
  STA AUDIO_STREAM_CHANNEL, X

  INY
  LDA (soundPointer), Y ; byte containing volume and duty
  STA AUDIO_STREAM_VOL_DUTY, X

  INY
  LDA (soundPointer), Y ; low byte of note
  STA AUDIO_STREAM_NOTE_LOW, X

  INY
  LDA (soundPointer), Y ; high byte of note
  STA AUDIO_STREAM_NOTE_HI, X

  LDA soundId ; store song id as well
  STA AUDIO_STREAM_SOUND_ID

    ; decrement counter and conditionaly loop
  DEC channelCounter
  BNE @stream_loop

  RTS
.ENDPROC

.PROC play_sound_frame
    ; check audioFlag
  LDA gameFlags
  AND #%00100000
  BEQ @done      ; return if not set

  LDX #$00
@loop:          ; loop through all audio streams

  ; read from data stream in ROM in necessary?
  ; update stream based on what is read

  LDA AUDIO_STREAM_VOL_DUTY, X
  ; Do stuff with volume

  ; ETC


  INX
  CPX #NUM_STREAMS
  BNE @loop
@done:
  RTS
.ENDPROC