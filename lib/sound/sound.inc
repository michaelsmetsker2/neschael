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

  INSTRUMENT_HEADER_ARP_TYPE_OFFSET = $04
  
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

  DEFAULT_NOTE_LENGTH = $20 ; frames
  DEFAULT_TEMPO       = $0F00

  OPCODE_THRESHOLD = $60 ; threshold in witch a byte read from an audio stream is determined to be an opcode

  ; streamFlags masks
  STREAM_ENABLED_MASK       = %00000001
  STREAM_ENABLED_CLEAR      = %11111110
  STREAM_PITCH_LOADED_MASK  = %00001000
  STREAM_PITCH_LOADED_CLEAR = %11110111
  STREAM_SILENCE_MASK       = %00000010
  STREAM_SILENCE_CLEAR      = %11111101
  
  ; simple macro to increment the pointer when reading from an audio stream
.MACRO IncrementStreamReadAddr
  INC streamReadAddrLow, X
  BNE :+
  INC streamReadAddrHigh, X
:
.ENDMACRO


    ; note aliases
  C0  = 0
  CS0 = 1
  D0  = 2
  DS0 = 3
  E0  = 4
  F0  = 5
  FS0 = 6
  G0  = 7
  GS0 = 8
  A0  = 9
  AS0 = 10
  B0  = 11
  C1  = 12
  CS1 = 13
  D1  = 14
  DS1 = 15
  E1  = 16
  F1  = 17
  FS1 = 18
  G1  = 19
  GS1 = 20
  A1  = 21
  AS1 = 22
  B1  = 23
  C2  = 24
  CS2 = 25
  D2  = 26
  DS2 = 27
  E2  = 28
  F2  = 29
  FS2 = 30
  G2  = 31
  GS2 = 32
  A2  = 33
  AS2 = 34
  B2  = 35
  C3  = 36
  CS3 = 37
  D3  = 38
  DS3 = 39
  E3  = 40
  F3  = 41
  FS3 = 42
  G3  = 43
  GS3 = 44
  A3  = 45
  AS3 = 46
  B3  = 47
  C4  = 48
  CS4 = 49
  D4  = 50
  DS4 = 51
  E4  = 52
  F4  = 53
  FS4 = 54
  G4  = 55
  GS4 = 56
  A4  = 57
  AS4 = 58
  B4  = 59
  C5  = 60
  CS5 = 61
  D5  = 62
  DS5 = 63
  E5  = 64
  F5  = 65
  FS5 = 66
  G5  = 67
  GS5 = 68
  A5  = 69
  AS5 = 70
  B5  = 71
  C6  = 72
  CS6 = 73
  D6  = 74
  DS6 = 75
  E6  = 76
  F6  = 77
  FS6 = 78
  G6  = 79
  GS6 = 80
  A6  = 81
  AS6 = 82
  B6  = 83
  C7  = 84
  CS7 = 85
  D7  = 86
  DS7 = 87
  E7  = 88
  F7  = 89
  FS7 = 90
  G7  = 91
  GS7 = 92
  A7  = 93
  AS7 = 94
  B7  = 95

  HIGHEST_NOTE = B7


  ; opcode aliases

  ;stream control opcodes

  ;set length opcodes for standard note lengths
  SL1 = 0  + OPCODE_THRESHOLD
  SL2 = 1  + OPCODE_THRESHOLD
  SL3 = 2  + OPCODE_THRESHOLD
  SL4 = 3  + OPCODE_THRESHOLD
  SL5 = 4  + OPCODE_THRESHOLD
  SL6 = 5  + OPCODE_THRESHOLD
  SL7 = 6  + OPCODE_THRESHOLD
  SL8 = 7  + OPCODE_THRESHOLD
  SL9 = 8  + OPCODE_THRESHOLD
  SLA = 9  + OPCODE_THRESHOLD
  SLB = 10 + OPCODE_THRESHOLD
  SLC = 11 + OPCODE_THRESHOLD
  SLD = 12 + OPCODE_THRESHOLD
  SLE = 13 + OPCODE_THRESHOLD
  SLF = 14 + OPCODE_THRESHOLD
  SL0 = 15 + OPCODE_THRESHOLD

  ;set length lo byte
  SLL = 16+OPCODE_THRESHOLD

  ;set length hi byte
  SLH = 17+OPCODE_THRESHOLD

  ;set instrument
  STI = 18+OPCODE_THRESHOLD

  ;goto
  GOT = 19+OPCODE_THRESHOLD

  ;call
  CAL = 20+OPCODE_THRESHOLD

  ;return
  RET = 21+OPCODE_THRESHOLD

  ;terminate
  TRM = 22+OPCODE_THRESHOLD

  ;opcodes read from volume and pitch envelopes. These values are also
  ;reserved by Famitracker, so they are safe to use.
  ENV_STOP = %10000000 ;-128
  ENV_LOOP = %01111111 ; 127

  ;a different set of opcodes for stop and loop for duty cycle envelopes.
  ;This is necessary since ENV_STOP can be intepreted as duty cycle = 2,
  ;preventing users from using that setting.
  DUTY_ENV_STOP = %00111111
  DUTY_ENV_LOOP = %00101010

  ;these opcodes exist at the start of any arpeggio envelope to indicate
  ;how the arpeggio is to be executed.
  ARP_TYPE_ABSOLUTE = 0
  ARP_TYPE_FIXED    = 1
  ARP_TYPE_RELATIVE = 2