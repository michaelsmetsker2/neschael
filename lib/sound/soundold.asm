;
; neshael
; lib/sound/sound.s
;
; main sound engine, and subproccesses to interface with it

.INCLUDE "data/system/apu.inc"
.INCLUDE "lib/game/gameData.inc"

.INCLUDE "lib/sound/sound.inc"

.IMPORTZP SCRATCH

  ; period table
.IMPORT periodTableLo
.IMPORT periodTableHi

  ; sound index lookup tables
.IMPORT song_index_high
.IMPORT song_index_low

.IMPORT opcode_table_low
.IMPORT opcode_table_high

.EXPORT audio_init
.EXPORT load_song
.EXPORT play_sound_frame

  ; initializes the sound engine, used when loading the game and levels,
.PROC audio_init

  LDA #%01000000
  STA _FR_COUNTER       ; Disable APU frame IRQ
  STA _DMC_FREQ         ; Disable digital sound IRQs

	; enable sound channels
  EnableAudioOutput

; TODO should add zeroes for level loading
@initialize_shadow_apu:
  LDA #$30               ; all zero exept for length counter halt
  STA shadowApuPorts     ; square 1 volume to 0
  STA shadowApuPorts+4   ; square 2 volume
  STA shadowApuPorts+12  ; Noise volume
  LDA #%10000000
  STA shadowApuPorts+8   ; triangle volume
  LDA #$08
  STA shadowApuPorts+5   ; negate square 2 sweep unit

	; makes sure that the square sounds will be written two on the first frame
  LDA #$FF
  STA sound_sq1_old
  STA sound_sq2_old

	; set audioFlag
  LDA gameFlags
  ORA #%00100000
  STA gameFlags
  RTS
.ENDPROC

.PROC play_sound_frame
; don't play a frame if audio is disabled
  LDA gameFlags
  AND #%00100000
  BEQ @done

  LDX #$00       ; loop index
@loop:           ; update all audio streams

	; skip if stream is disabled
  LDA streamFlags, X
  AND #STREAM_ENABLED_MASK
  BEQ @next

  JSR update_stream
  JSR buffer_stream_data

@next:
  INX
  CPX #NUM_STREAMS_MUSIC
  BNE @loop

  JMP set_apu_ports ; sends buffered data to apu ports

  ; TODO add sfx handling

@done:
  RTS
.ENDPROC

  ; updates an audio stream
	; input: X contains the stream number
.PROC update_stream

  ; pointer to the next byte in the stream
  streamPtr = SCRATCH
  ; pointer to the proccess the stream executes
  callbackAddress = SCRATCH+2

@read:
  ; load the stream's read address
  LDA streamReadAddrLo, X
  STA streamPtr
  LDA streamReadAddrHi, X
  STA streamPtr+1
  
  ; read next byte in the stream
  LDY #$00
  LDA (streamPtr), Y

  ; byte is a note if <#$80
  BPL @note
  ; test if the byte is an opcode or a note length
  CMP #OPCODE_THRESHOLD
  BCC @length

@opcode:
  ; get raw opcode offset 
  SEC
  SBC #OPCODE_THRESHOLD
  TAY

  LDA opcode_table_low, Y
  STA callbackAddress
  LDA opcode_table_high, Y
  STA callbackAddress+1
  ; sets a return address and jumps to the opcodes proccess
  JSR indirect_jsr_helper

  IncrementStreamReadAddr
  JMP @read

@length: ; the byte denotes how long to hold the next note(s)

  ; mask bit 7 to get raw note duration
  AND #%01111111
  STA streamNoteLength, X

  ; read the next byte as well
  IncrementStreamReadAddr
  JMP @read

@note:

  TAY

	; add tempo to ticker
  LDA audioStreamTicker, X
  CLC
  ADC audioStreamTempo, X
  STA audioStreamTicker, X
  BCC @done

  ; check if the current note has finished playing
  DEC audioStreamNoteCounter, X
  BNE @done
@note_finished:
  ; reset the note's timer
  LDA audioStreamNoteLength, X
  STA audioStreamNoteCounter, X

  ; set the note to the corosponding period
  LDA periodTableLo, Y
  STA audioStreamNoteLow, X
  LDA periodTableHi, Y
  STA audioStreamNoteHigh, X

  IncrementStreamReadAddr

@done:
  RTS

  .PROC indirect_jsr_helper
	JMP (callbackAddress)
  .ENDPROC
.ENDPROC

  ; buffers stream data in shadowApuPorts
	; INPUT: X: stream number
.PROC buffer_stream_data

  ; load channel number
  LDA audioStreamChannel, X
  ; *4 to get offset in shadowApuPorts
  ASL
  ASL
  TAY

  ; volume and duty
  LDA audioStreamVolume, X
  STA shadowApuPorts, Y
  ; negate sweep
  LDA #$08
  STA shadowApuPorts+1, Y
  ; period low and high
  LDA audioStreamNoteLow, X
  STA shadowApuPorts+2, Y
  LDA audioStreamNoteHigh, X
  STA shadowApuPorts+3, Y

  RTS
.ENDPROC

  ; copies buffered data in shadowApuPorts to the correct apu port
.PROC set_apu_ports
@square_1:
  LDA shadowApuPorts
  STA _SQ1_VOL
  LDA shadowApuPorts+1
  STA _SQ1_SWEEP
  LDA shadowApuPorts+2
  STA _SQ1_LO
  LDA shadowApuPorts+3
  CMP sound_sq1_old    ; only write to this port if value is updated, prevents static
  BEQ @square_2
  STA _SQ1_HI
  STA sound_sq1_old
@square_2:
  LDA shadowApuPorts+4
  STA _SQ2_VOL
  LDA shadowApuPorts+5
  STA _SQ2_SWEEP
  LDA shadowApuPorts+6
  STA _SQ2_LO
  LDA shadowApuPorts+7
  CMP sound_sq2_old    ; only write to this port if value is updated, prevents static
  BEQ @triangle
  STA _SQ2_HI
  STA sound_sq2_old
@triangle:
  LDA shadowApuPorts+8
  STA _TRI_LINEAR
  LDA shadowApuPorts+10
  STA _TRI_LO
  LDA shadowApuPorts+11
  STA _TRI_HI
@noise:
  LDA shadowApuPorts+12
  STA _NOISE_VOL
  LDA shadowApuPorts+14
  STA _NOISE_LO
  LDA shadowApuPorts+15
  STA _NOISE_HI

  RTS
.ENDPROC

  ; load a song into the sound engine by parsing the header
	  ; input: acc is be the index of the song in the song_index 
.PROC load_song
  soundPtr   = audio_scratch   ; pointer to sound to parse
  streamPtr  = audio_scratch+2 ; pointer to the starting read addr of the stream

  ; set pointer to header of sound to load
  LDA song_index_low, Y
  STA soundPtr
  LDA song_index_high, Y
  STA soundPtr+1

  ; loop to clear flags on all 4 music streams,
    ; this ensures all music streams stop
  LDX #$03
  LDA #$00
:
  STA audioStreamFlags, X
 
  DEX
  BPL :-

  ; initialize all four music streams

  ; set streamPtr to sq1
  LDY #Track_header::SQUARE_1_ADDR
  LDA (soundPtr), Y
  STA streamPtr
  INY
  LDA (soundPtr), Y
  ; null stream
  BEQ no_sq1 
  STA streamPtr+1

  LDX #Audio_streams::MUSIC_SQ1
  LDY #Audio_channels::SQUARE_1
  JSR stream_init
no_sq1:

  RTS
.ENDPROC

.PROC load_sfx
  ; TODO
  RTS
.ENDPROC

  ; resets a stream to it's initial values
	  ; expexts inherites audio scratch from load_song and load_sfx
    ; X: stream index
    ; Y: channel index
.PROC stream_init
    ; inherited from load_song and load_sfx
  soundPtr   = audio_scratch   ; pointer to sound to parse
  streamPtr  = audio_scratch+2 ; pointer to the starting read addr of the stream

  ; flags should already be cleared
  LDA #DEFAULT_NOTE_LENGTH
  STA streamNoteLength, X
  STA streamNoteCounter, X

  ;Set initial instrument index.
  LDA #$00
  STA streamInstrumentIndex, X
  STA streamVolumeOffset, X
  STA streamPitchOffset, X
  STA streamDutyOffset, X
  STA streamArpeggioOffset, X
  
  TYA
  STA streamChannel, X

  ;Set initial read address.
  lda starting_read_address
  sta stream_read_address_lo,x
  lda starting_read_address+1
  sta stream_read_address_hi,x

  ;Set default tempo.
  lda #<DEFAULT_TEMPO
  sta stream_tempo_lo,x
  sta stream_tempo_counter_lo,x
  lda #>DEFAULT_TEMPO
  sta stream_tempo_hi,x
  sta stream_tempo_counter_hi,x

  ;Set stream to be active.
  lda stream_flags,x
  ora #STREAM_ACTIVE_SET
  sta stream_flags,x
null_starting_read_address:

  dec sound_disable_update

  ;Restore x.
  pla
  tax


  RTS
.ENDPROC
