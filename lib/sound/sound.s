;
; neshael
; lib/sound/sound.s
;
; modified version of ggsound by ; TODO
; main sound engine, and subproccesses to interface with it

.INCLUDE "data/system/apu.inc"
.INCLUDE "lib/game/gameData.inc"

.INCLUDE "lib/sound/sound.inc"

.IMPORTZP SCRATCH

.IMPORT song_list_low
.IMPORT song_list_high
.IMPORT sfx_list_low
.IMPORT sfx_list_high
.IMPORT instrument_list_low
.IMPORT instrument_list_high

.IMPORT channel_table_low
.IMPORT channel_table_high
.IMPORT opcode_table_low
.IMPORT opcode_table_high
.IMPORT arpeggio_table_low
.IMPORT arpeggio_table_high

.EXPORT audio_init
.EXPORT load_song
.EXPORT play_sound_frame

	; initializes sound on startup
.PROC audio_init

	LDA #%01000000
	STA _FR_COUNTER       ; Disable APU frame IRQ
	STA _DMC_FREQ         ; Disable digital sound IRQs

	; enable sound channels
	EnableAudioOutput

@initialize_shadow_apu:
	; set Saw Envelope Disable and Length Counter Disable for square channels
	LDA #%00110000
	STA shadowApuPorts
	STA shadowApuPorts+4
	; and zero noise volume
	STA shadowApuPorts+12

	; zero triangle vol
	LDA #$80
	STA shadowApuPorts+8

	; set Negate flag on sweep units.
	LDA #$08
	STA shadowApuPorts+1
	STA shadowApuPorts+5

	; arbitrary in bounds period (C#)
	LDA #$C9
	STA shadowApuPorts+2
	STA shadowApuPorts+6
	STA shadowApuPorts+10

	; ensure "old" value starts out different from the first default value.
	STA sound_sq1_old
	STA sound_sq2_old

	; zero remaining
	LDA #$00
	STA shadowApuPorts+3
	STA shadowApuPorts+7
	STA shadowApuPorts+11
	STA shadowApuPorts+13
	STA shadowApuPorts+14
	STA shadowApuPorts+15
	
	RTS
.ENDPROC

; Updates sound if the flag is enabled every frame.
; first 4 streams are music, last 2 are sfx
; sfx have priority over music 
; When the sound effect streams are finished, they signify their corresponding
; music stream (via the TRM callback) to silence themselves until the next
; note to avoid ugly volume envelope transitions.
.PROC play_sound_frame
	; if audioflag is disabled, dont play sound
	LDA gameFlags
	AND #%00100000
	BEQ @done

	; loop through all music stream
		; incrementing, while slower, ensures music is proccessed before sfx
	LDX #$00
@stream_loop:

	; skip stream if disabled
	LDA streamFlags, X
	AND #STREAM_ENABLED_MASK
	BEQ @next_stream

	JSR update_stream
	
	; buffer completed stream data into shadowApuRegister
	LDA streamChannel, X
	; Multiply channel by four to get location within shadow apu
	ASL
	ASL
	TAY
	;Copy the registers over.
	LDA streamRegister_1, X
	STA shadowApuPorts, Y
	LDA streamRegister_2, X
	STA shadowApuPorts, Y
	LDA streamRegister_3, X
	STA shadowApuPorts, Y
	LDA streamRegister_4, X
	STA shadowApuPorts, Y

@next_stream:
	INX
	CPX #NUM_STREAMS
	BNE @stream_loop

	; upload to the apu
	JSR set_apu_ports
@done:
	RTS
.ENDPROC

 ; load song into the song engine, expects 4 channels
 	; expects ACC to contain index of a song in song_list
.PROC load_song

	; pointer to song to parse
	songPtr = audio_scratch
	streamPtr = audio_scratch+2

	; set songPtr to the correct song
	TAY
	LDA song_list_low, Y
	STA songPtr
	LDA song_list_high, Y
	STA songPtr+1
	
	; clear flags on all four music streams to ensure outdated playback stops
	LDX #$03
	LDA #$00
:
	STA streamFlags, X
	DEX
	BPL :-

	; load square 1 stream.
	LDY #Track_header::SQUARE_1_ADDR
	LDA (songPtr), Y

	STA streamPtr
	INY
	LDA (songPtr), Y
	BEQ no_square_1
	STA streamPtr+1
	
	LDX #$00
	LDY	#$00
	JSR stream_initialize

	LDY #Track_header::TEMPO_LOW
	LDA (songPtr), Y
	STA streamTempoLow, X
	STA streamTickerLow, X

	INY
	LDA (songPtr), Y
	STA streamTempoHigh, X
	STA streamTickerHigh, X
no_square_1:

	; load square 2 stream.
	LDY #Track_header::SQUARE_2_ADDR
	LDA (songPtr), Y

	STA streamPtr
	INY
	LDA (songPtr), Y
	BEQ no_square_2
	STA streamPtr+1
	
	LDX #$01
	LDY	#$01
	JSR stream_initialize

	LDY #Track_header::TEMPO_LOW
	LDA (songPtr), Y
	STA streamTempoLow, X
	STA streamTickerLow, X

	INY
	LDA (songPtr), Y
	STA streamTempoHigh, X
	STA streamTickerHigh, X
no_square_2:

	;Load triangle stream.
	LDY #Track_header::TRIANGLE_ADDR
	LDA (songPtr), Y

	STA streamPtr
	INY
	LDA (songPtr), Y
	BEQ no_triangle
	STA streamPtr+1
	
	LDX #$02
	LDY	#$02
	JSR stream_initialize

	LDY #Track_header::TEMPO_LOW
	LDA (songPtr), Y
	STA streamTempoLow, X
	STA streamTickerLow, X

	INY
	LDA (songPtr), Y
	STA streamTempoHigh, X
	STA streamTickerHigh, X
no_triangle:

	;Load noise stream.
	LDY #Track_header::NOISE_ADDR
	LDA (songPtr), Y

	STA streamPtr
	INY
	LDA (songPtr), Y
	BEQ no_noise
	STA streamPtr+1
	
	LDX #$03
	LDY	#$03
	JSR stream_initialize

	LDY #Track_header::TEMPO_LOW
	LDA (songPtr), Y
	STA streamTempoLow, X
	STA streamTickerLow, X

	INY
	LDA (songPtr), Y
	STA streamTempoHigh, X
	STA streamTickerHigh, X
no_noise:
	RTS
.ENDPROC


	; load sfx track into the song engine, expects 1 channel
 	; expects ACC to contain index of an effect in sfx_list
	; Expects X to contain the stream, either Audio_streams::SFX_1 or SFX_2
.PROC load_sfx

	; pointer to sound effect to parse
	sfxPtr = audio_scratch
	streamPtr = audio_scratch+2
	stream = audio_scratch+4
	
	LDA Audio_streams::SFX_1
	STA stream

	; set songPtr to the correct song
	TAY
	LDA sfx_list_low, Y
	STA sfxPtr
	LDA sfx_list_high, Y
	STA sfxPtr+1

	;Load square 1 stream.
	LDY #Sfx_header::SQUARE_1_ADDR
	LDA (sfxPtr), Y
	STA streamPtr
	INY
	LDA (sfxPtr), Y
	BEQ no_square_1
	STA streamPtr+1
	
	LDX #stream
	LDY #$00

	JSR stream_initialize

    LDA #$00
    STA streamTempoLow, X
    STA streamTickerLow, X
    LDA #$01
    STA streamTempoHigh, X
    STA streamTickerHigh, X

	INC stream
no_square_1:

	LDA #stream
	CMP #(Audio_streams::SFX_2 + 1)
	BNE skip0
	JMP no_more_sfx_streams_available
skip0:

	;Load square 2 stream.
	LDY #Sfx_header::SQUARE_2_ADDR
	LDA (sfxPtr), Y
	STA streamPtr
	INY
	LDA (sfxPtr), Y
	BEQ no_square_2
	STA streamPtr+1
	
	LDX #stream
	LDY #$01

	JSR stream_initialize

    LDA #$00
    STA streamTempoLow, X
    STA streamTickerLow, X
    LDA #$01
    STA streamTempoHigh, X
    STA streamTickerHigh, X

	INC stream
no_square_2:

	LDA #stream
	CMP #(Audio_streams::SFX_2 + 1)
	BNE skip1
	JMP no_more_sfx_streams_available
skip1:

	;Load triangle stream.
	LDY #Sfx_header::TRIANGLE_ADDR
	LDA (sfxPtr), Y
	STA streamPtr
	INY
	LDA (sfxPtr), Y
	BEQ no_triangle
	STA streamPtr+1
	
	LDX #stream
	LDY #$02

	JSR stream_initialize

    LDA #$00
    STA streamTempoLow, X
    STA streamTickerLow, X
    LDA #$01
    STA streamTempoHigh, X
    STA streamTickerHigh, X

	INC stream
no_triangle:

	LDA #stream
	CMP #(Audio_streams::SFX_2 + 1)
	BEQ no_more_sfx_streams_available

	;Load noise stream.
	LDY #Sfx_header::NOISE_ADDR
	LDA (sfxPtr), Y
	STA streamPtr
	INY
	LDA (sfxPtr), Y
	BEQ no_noise
	STA streamPtr+1
	
	LDX #stream
	LDY #$03

	JSR stream_initialize

    LDA #$00
    STA streamTempoLow, X
    STA streamTickerLow, X
    LDA #$01
    STA streamTempoHigh, X
    STA streamTickerHigh, X

	INC stream
no_noise:
no_more_sfx_streams_available:
	
	RTS
.ENDPROC

	; initializes a stream for a newly playing track
	; Expects x to contain the offset of the stream instance to initialize.
	; Expects y to contain the channel on which to play the stream.
	; inherits the start of stream read address from load song/sfx
.PROC stream_initialize

	streamPtr = audio_scratch+2

	; set not length and counter
	LDA #DEFAULT_NOTE_LENGTH
	STA streamNoteLength, X
	STA streamNoteCounter, X
	
	; set instrument values to 0
	LDA #0
	STA streamInstrumentIndex, X
	STA streamVolumeOffset, X
	STA streamPitchOffset, X
	STA streamDutyOffset, X
	STA streamArpeggioOffset, X

	;Set channel.
	TYA
	STA streamChannel, X

	;Set initial read address.
	LDA streamPtr
	STA streamReadAddrLow, X
	LDA streamPtr+1
	STA streamReadAddrHigh, X

	; note, tempo and ticker are set after this in either load_song or load_sfx	

	;Set stream to be active.
	LDA streamFlags, X
	ORA #STREAM_ENABLED_MASK
	STA streamFlags, X

	RTS
.ENDPROC

;Updates a single stream.
;Expects x to be pointing to a stream instance as an offset from streams.
.PROC update_stream

	streamPtr = audio_scratch
	callbackAddr = audio_scratch+2
	instPtr = audio_scratch+4
	
	;Load current read address of stream.
	LDA streamReadAddrLow, X
	STA streamPtr
	LDA streamReadAddrHigh, X
	STA streamPtr+1
	
	;Load next byte from stream data.
	LDA streamFlags, x
	AND #STREAM_PITCH_LOADED_MASK
	BNE :+
	LDY #$00
	LDA (streamPtr), Y
	STA streamNote, X
:
	; BUG wierd fallthrough behaviorm it compares the flag with opcode base

	; check if value is an opcode or a note
	CMP #OPCODE_THRESHOLD
	BCC @note
@opcode:

	; get the opcodes offset in the callbacktable
	SEC
	SBC #OPCODE_THRESHOLD
	TAY
	; Get the address of the corrospoding opcode function
	LDA opcode_table_low, Y
	STA callbackAddr
	LDA opcode_table_high, Y
	STA callbackAddr+1

	JSR indirect_jsr_helper

	;Advance the stream's read address.
	IncrementStreamReadAddr

	; process the next opcode or note.
	JMP update_stream
@note:

	; Determine which channel callback to use.
	LDA streamChannel, X
	TAY

	LDA channel_table_low, Y
	STA callbackAddr
	LDA channel_table_high, Y
	STA callbackAddr+1

	; Call the channel callback!
	JSR indirect_jsr_helper

	; see if a tick has occured.
	LDA streamTickerHigh, X
	SEC
	SBC #$01
	STA streamTickerHigh, X
	BCS @done

	; add tempo to counter when we wrap
	CLC
	LDA streamTickerLow, X
	ADC streamTempoLow, X
	STA streamTickerLow, X
	LDA streamTickerHigh, X
	ADC streamTempoHigh, X
	STA streamTickerHigh, X

	; decrement the note length counter, advance on zero
	DEC streamNoteCounter
	BNE @done

	; reset the note's duration
	LDA streamNoteLength, X
	STA streamNoteCounter, X

	; reset instrument
	LDY streamInstrumentIndex, X
	LDA instrument_list_low, Y
	STA instPtr
	LDA instrument_list_high, Y
	STA instPtr+1

	LDY #$00
	LDA (instPtr), Y
	STA streamVolumeOffset, X
	INY
	LDA (instPtr), Y
	STA streamPitchOffset, X
	INY
	LDA (instPtr), Y
	STA streamDutyOffset, X
	INY
	LDA (instPtr), Y
	STA streamArpeggioOffset, X

	; Reset silence until note and pitch loaded flags.
	LDA streamFlags, X
	and #STREAM_SILENCE_CLEAR
	and #STREAM_PITCH_LOADED_CLEAR
	STA streamFlags, X

	; advance stream's read address.
	IncrementStreamReadAddr

@done:

	RTS

.PROC indirect_jsr_helper
	JMP (callbackAddr)
	RTS
.ENDPROC

.ENDPROC

.proc set_apu_ports
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
	;Our notes go from 0 to 15 (low to high)
	;but noise channel's low to high is 15 to 0.
	EOR #$0F
	STA _NOISE_LO
	LDA shadowApuPorts+15
	STA _NOISE_HI

	; TODO? Clear out all volume values from this frame in case a sound effect is killed suddenly.
	
	RTS
.endproc
