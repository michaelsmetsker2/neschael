;
; neschael
; lib/sound/sound.inc
;
; enums and definitions relating to the sound engine
;

.ENUM Audio_channels
  SQUARE_1 = 0
  SQUARE_2 = 1
  TRIANGLE = 2
  NOISE    = 3
  DCPM     = 4 ; unused
.ENDENUM

.ENUM Audio_streams
  MUSIC_SQ1   = 0
  MUSIC_SQ2   = 1
  MUSIC_TRI   = 2
  MUSIC_NOISE = 3
  SFX_1       = 4
  SFX_2       = 5
.ENDENUM

  NUM_STREAMS = $06 ; number of audio streams

  OPCODE_THRESHOLD = $A0 ; threshold in witch a byte read from an audio stream is determined to be an opcode

    ; sound header
  SOUND_STREAM_OFFSET = $00 ; offset to byte holding the ammount of streams in the sound