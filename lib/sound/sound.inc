;
; neschael
; lib/sound/sound.inc
;
; enums and definitions relating to the sound engine
;

.IMPORTZP AUDIO_DATA_ZP
.IMPORT   AUDIO_DATA

    ; the last value written to the square channels 4th APU port
      ; only writing when the value changes prevents a scratchy noise
  sound_sq1_old = AUDIO_DATA_ZP
  sound_sq2_old = AUDIO_DATA_ZP + 1

    ; audio engine specific scratch data to avoid clobbering when starting a new song
  audio_scratch = AUDIO_DATA_ZP + 2

  ; status byte
  streamFlags               = AUDIO_DATA + 0
  ; raw byte from data stream
  streamNote                = AUDIO_DATA + 6
  streamNoteLength          = AUDIO_DATA + 12
  streamNoteCounter         = AUDIO_DATA + 18
  
  streamInstrumentIndex     = AUDIO_DATA + 24
  ; offset into each envelope
  streamVolumeOffset        = AUDIO_DATA + 30
  streamArpeggioOffset      = AUDIO_DATA + 36
  streamPitchOffset         = AUDIO_DATA + 42
  streamDutyOffset          = AUDIO_DATA + 48

  ; contains enum Audio_channels
  streamChannel             = AUDIO_DATA + 54

  streamReadAddrLow         = AUDIO_DATA + 60
  streamReadAddrHigh        = AUDIO_DATA + 66
  streamReturnAddrLow       = AUDIO_DATA + 72
  streamReturnAddrHigh      = AUDIO_DATA + 78

  streamTickerLow           = AUDIO_DATA + 84
  streamTickerHigh          = AUDIO_DATA + 90
  streamTempoLow            = AUDIO_DATA + 96
  streamTempoHigh           = AUDIO_DATA + 102

  streamRegister_1          = AUDIO_DATA + 108
  streamRegister_2          = AUDIO_DATA + 114
  streamRegister_3          = AUDIO_DATA + 120
  streamRegister_4          = AUDIO_DATA + 126
  
  shadowApuPorts            = AUDIO_DATA + 132 ; size 16

    ; byte offsets for the track header for parsing
  .SCOPE Track_header
    TEMPO_LOW     = 0
    TEMPO_HIGH    = 1
    SQUARE_1_ADDR = 2
    SQUARE_2_ADDR = 4
    TRIANGLE_ADDR = 6
    NOISE_ADDR    = 8 
  .ENDSCOPE

  .SCOPE Sfx_header
    SQUARE_1_ADDR = 0
    SQUARE_2_ADDR = 2
    TRIANGLE_ADDR = 4
    NOISE_ADDR    = 6
  .ENDSCOPE

  .ENUM Audio_channels
    SQUARE_1 = 0
    SQUARE_2 = 1
    TRIANGLE = 2
    NOISE    = 3
  .ENDENUM

  .ENUM Audio_streams
    MUSIC_SQ1   = 0
    MUSIC_SQ2   = 1
    MUSIC_TRI   = 2
    MUSIC_NOISE = 3
    SFX_1       = 4
    SFX_2       = 5
  .ENDENUM

  NUM_STREAMS_MUSIC = $04 ; number of audio streams not counting sfx
  NUM_STREAMS       = $06 ; number of audio streams including sfx
  ; NUM_STREAM_SFX    = $02 ; number of sfx streams

  DEFAULT_NOTE_LENGTH = $20 ; frames
  DEFAULT_TEMPO       = $0F00

  OPCODE_THRESHOLD = $A0 ; threshold in witch a byte read from an audio stream is determined to be an opcode

  STREAM_ENABLED_MASK = %00000001

  ; simple macro to increment the pointer when reading from an audio stream
.MACRO IncrementStreamReadAddr
  INC audioStreamAddrLow, X
  BNE :+
  INC audioStreamAddrHigh, X
:
.ENDMACRO