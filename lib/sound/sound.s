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

  ; period table
.IMPORT periodTableLo
.IMPORT periodTableHi

  ; sound index lookup tables
.IMPORT song_list_low
.IMPORT song_list_high
.IMPORT sfx_list_low
.IMPORT sfx_list_high
.IMPORT instrument_list_low
.IMPORT instrument_list_high

.IMPORT opcode_table_low
.IMPORT opcode_table_high

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
	
	;Load current read address of stream.
	LDA streamReadAddrLow, X
	STA streamPtr
	LDA streamReadAddrHigh, X
	STA streamPtr+1
	
	;Load next byte from stream data.
	LDA streamFlags, x
	and #STREAM_PITCH_LOADED_TEST
	bne skip1
	ldy #0
	lda (read_address),y
	sta stream_note,x
skip1:

	;Is this byte a note or a stream opcode?
	cmp #OPCODES_BASE
	bcc process_note
process_opcode:

	;Look up the opcode in the stream callbacks table.
	sec
	sbc #OPCODES_BASE
	tay
	;Get the address.
	lda stream_callback_table_lo,y
	sta callback_address
	lda stream_callback_table_hi,y
	sta callback_address+1
	;Call the callback!
	jsr indirect_jsr_callback_address

	;Advance the stream's read address.
	IncrementStreamReadAddr

	;Immediately process the next opcode or note. The idea here is that
	;all stream control opcodes will execute during the current frame as "setup"
	;for the next note. All notes will execute once per frame and will always
	;return from this routine. This leaves the problem, how would the stream
	;control opcode "terminate" work? It works by pulling the current return
	;address off the stack and then performing an rts, effectively returning
	;from its caller, this routine.
	jmp stream_update

process_note:

	;Determine which channel callback to use.
	lda stream_channel,x
	tay
	lda channel_callback_table_lo,y
	sta callback_address
	lda channel_callback_table_hi,y
	sta callback_address+1

	;Call the channel callback!
	jsr indirect_jsr_callback_address

	sec
	lda stream_tempo_counter_lo,x
	sbc #<256
	sta stream_tempo_counter_lo,x
	lda stream_tempo_counter_hi,x
	sbc #>256
	sta stream_tempo_counter_hi,x
	bcs do_not_advance_note_length_counter

	;Reset tempo counter when we cross 0 by adding original tempo back on.
	;This way we have a wrap-around value that does not get lost when we count
	;down to the next note.
	clc
	lda stream_tempo_counter_lo,x
	adc stream_tempo_lo,x
	sta stream_tempo_counter_lo,x
	lda stream_tempo_counter_hi,x
	adc stream_tempo_hi,x
	sta stream_tempo_counter_hi,x

	;Decrement the note length counter.. On zero, advance the stream's read address.
	sec
	lda stream_note_length_counter_lo,x
	sbc #<1
	sta stream_note_length_counter_lo,x
	lda stream_note_length_counter_hi,x
	sbc #>1
	sta stream_note_length_counter_hi,x

	lda stream_note_length_counter_lo,x
	ora stream_note_length_counter_hi,x

	bne note_length_counter_not_zero

	;Reset the note length counter.
	lda stream_note_length_lo,x
	sta stream_note_length_counter_lo,x
	lda stream_note_length_hi,x
	sta stream_note_length_counter_hi,x

	ldy stream_instrument_index,x
	lda instrument_list,y
	sta sound_local_word_0
	iny
	lda instrument_list,y
	sta sound_local_word_0+1
	ldy #0
	lda (sound_local_word_0),y
	sta stream_volume_offset,x
	iny
	lda (sound_local_word_0),y
	sta stream_pitch_offset,x
	iny
	lda (sound_local_word_0),y
	sta stream_duty_offset,x
	iny
	lda (sound_local_word_0),y
	sta stream_arpeggio_offset,x

	;Reset silence until note and pitch loaded flags.
	lda stream_flags,x
	and #STREAM_SILENCE_CLEAR
	and #STREAM_PITCH_LOADED_CLEAR
	sta stream_flags,x

	;Advance the stream's read address.
	IncrementStreamReadAddr
do_not_advance_note_length_counter:
note_length_counter_not_zero:

	rts

.proc indirect_jsr_callback_address
	jmp (callback_address)
	rts
.endproc

.endproc

.proc sound_upload

	lda apu_data_ready
	beq apu_data_not_ready

	jsr sound_upload_apu_register_sets

apu_data_not_ready:

	rts
.endproc

.proc sound_upload_apu_register_sets
square1:
	lda apu_register_sets+0
	sta $4000
	lda apu_register_sets+1
	sta $4001
	lda apu_register_sets+2
	sta $4002
	lda apu_register_sets+3
	;Compare to last write.
	cmp apu_square_1_old
	;Don't write this frame if they were equal.
	beq square2
	sta $4003
	;Save the value we just wrote to $4003.
	sta apu_square_1_old
square2:
	lda apu_register_sets+4
	sta $4004
	lda apu_register_sets+5
	sta $4005
	lda apu_register_sets+6
	sta $4006
	lda apu_register_sets+7
	cmp apu_square_2_old
	beq triangle
	sta $4007
	;Save the value we just wrote to $4007.
	sta apu_square_2_old
triangle:
	lda apu_register_sets+8
	sta $4008
	lda apu_register_sets+10
	sta $400A
	lda apu_register_sets+11
	sta $400B
noise:
	lda apu_register_sets+12
	sta $400C
	lda apu_register_sets+14
	;Our notes go from 0 to 15 (low to high)
	;but noise channel's low to high is 15 to 0.
	eor #$0f
	sta $400E
	lda apu_register_sets+15
	sta $400F

	;Clear out all volume values from this frame in case a sound effect is killed suddenly.
	lda #%00110000
	sta apu_register_sets
	sta apu_register_sets+4
	sta apu_register_sets+12
	lda #%10000000
	sta apu_register_sets+8

	rts
.endproc
