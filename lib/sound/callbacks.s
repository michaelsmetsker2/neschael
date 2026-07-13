; 
; neschael
; lib/sound/callbacks.s
;
; contains jump tables and proccesses for all callbacks in the sound engine, these are for processing opcodes, playing notes, and arpeggios
;
.IF 0 ; FIXME
.INCLUDE "lib/sound/sound.inc"

.EXPORT channel_table_low
.EXPORT channel_table_high
.EXPORT opcode_table_low
.EXPORT opcode_table_high
.EXPORT arpeggio_table_low
.EXPORT arpeggio_table_high

  ; callback table for channel subproccesses
channel_table_low:
  .BYTE <square_play_note
  .BYTE <square_play_note
  .BYTE <triangle_play_note
  .BYTE <noise_play_note
channel_table_high:
  .BYTE >square_play_note
  .BYTE >square_play_note
  .BYTE >triangle_play_note
  .BYTE >noise_play_note

  ; callback table for arpeggio subproccesses
arpeggio_table_low:
	.byte <(arpeggio_absolute-1)
	.byte <(arpeggio_fixed-1)
	.byte <(arpeggio_relative-1)
arpeggio_table_high:
	.byte >(arpeggio_absolute-1)
	.byte >(arpeggio_fixed-1)
	.byte >(arpeggio_relative-1)

  ; callback table for opcode subproccesses
opcode_table_low:
.REPEAT 16
  .BYTE <set_length
.ENDREPEAT
  .BYTE <set_length_low
  .BYTE <set_length_high
  .BYTE <set_instrument
  .BYTE <stream_goto
  .BYTE <stream_call
  .BYTE <stream_return
  .BYTE <stream_terminate
opcode_table_high:
.REPEAT 16
  .BYTE >set_length
.ENDREPEAT
  .BYTE >set_length_low
  .BYTE >set_length_high
  .BYTE >set_instrument
  .BYTE >stream_goto
  .BYTE >stream_call
  .BYTE >stream_return
  .BYTE >stream_terminate

;****************************************************************
;These callbacks are all note playback and only execute once per
;frame.
;****************************************************************

.proc square_play_note

	;Load instrument index.
	ldy stream_instrument_index,x
	;Load instrument address.
	lda instrument_list,y
	sta sound_local_word_0
	iny
	lda instrument_list,y
	sta sound_local_word_0+1

	;Set negate flag for sweep unit.
	lda #$08
	sta stream_channel_register_2,x

	.ifdef FEATURE_ARPEGGIOS

	;Get arpeggio type.
	ldy #instrument_header_arpeggio_type
	lda (sound_local_word_0),y
	tay

	;Get the address.
	lda #>(return_from_arpeggio_callback-1)
	pha
	lda #<(return_from_arpeggio_callback-1)
	pha
	lda arpeggio_callback_table_hi,y
	pha
	lda arpeggio_callback_table_lo,y
	pha
	rts
return_from_arpeggio_callback:

	.else

	ldy stream_note,x

	.endif

	;Skip loading note pitch if already loaded, to allow envelopes
	;to modify the pitch.
	lda stream_flags,x
	and #STREAM_PITCH_LOADED_TEST
	bne pitch_already_loaded
	lda stream_flags,x
	ora #STREAM_PITCH_LOADED_SET
	sta stream_flags,x
	;Load low byte of note.
	lda ntsc_note_table_lo,y
	;Store in low 8 bits of pitch.
	sta stream_channel_register_3,x
	;Load high byte of note.
	lda ntsc_note_table_hi,y
	sta stream_channel_register_4,x
pitch_already_loaded:

	.scope
	lda stream_flags,x
	and #STREAM_SILENCE_TEST
	bne silence_until_note
note_not_silenced:

	;Load volume offset.
	ldy stream_volume_offset,x

	;Load volume value for this frame, branch if opcode.
	lda (sound_local_word_0),y
	cmp #ENV_STOP
	beq volume_stop
	cmp #ENV_LOOP
	bne skip_volume_loop

	;We hit a loop opcode, advance envelope index and load loop point.
	iny
	lda (sound_local_word_0),y
	sta stream_volume_offset,x
	tay

skip_volume_loop:

	;Initialize channel control register with envelope decay and
	;length counter disabled but preserving current duty cycle.
	lda stream_channel_register_1,x
	and #%11000000
	ora #%00110000

	;Load current volume value.
	ora (sound_local_word_0),y
	sta stream_channel_register_1,x

	inc stream_volume_offset,x

volume_stop:

	jmp done
silence_until_note:
	lda stream_channel_register_1,x
	and #%11000000
	ora #%00110000
	sta stream_channel_register_1,x

done:
	.endscope

	;Load pitch offset.
	ldy stream_pitch_offset,x

	;Load pitch value.
	lda (sound_local_word_0),y
	cmp #ENV_STOP
	beq pitch_stop
	cmp #ENV_LOOP
	bne skip_pitch_loop

	;We hit a loop opcode, advance envelope index and load loop point.
	iny
	lda (sound_local_word_0),y
	sta stream_pitch_offset,x
	tay

skip_pitch_loop:

	;Test sign.
	lda (sound_local_word_0),y
	bmi pitch_delta_negative
pitch_delta_positive:

	clc
	lda stream_channel_register_3,x
	adc (sound_local_word_0),y
	sta stream_channel_register_3,x
	lda stream_channel_register_4,x
	adc #0
	sta stream_channel_register_4,x

	jmp pitch_delta_test_done

pitch_delta_negative:

	clc
	lda stream_channel_register_3,x
	adc (sound_local_word_0),y
	sta stream_channel_register_3,x
	lda stream_channel_register_4,x
	adc #$ff
	sta stream_channel_register_4,x

pitch_delta_test_done:

	;Move pitch offset along.
	inc stream_pitch_offset,x

pitch_stop:

duty_code:

	ldy stream_duty_offset,x

	;Load duty value for this frame, but hard code flags and duty for now.
	lda (sound_local_word_0),y
	cmp #DUTY_ENV_STOP
	beq duty_stop
	cmp #DUTY_ENV_LOOP
	bne skip_duty_loop

	;We hit a loop opcode, advance envelope index and load loop point.
	iny
	lda (sound_local_word_0),y
	sta stream_duty_offset,x
	tay

skip_duty_loop:

	;Or the duty value into the register.
	lda stream_channel_register_1,x
	and #%00111111
	ora (sound_local_word_0),y
	sta stream_channel_register_1,x

	;Move duty offset along.
	inc stream_duty_offset,x

duty_stop:

	rts

.endproc

.proc triangle_play_note

	;Load instrument index.
	ldy stream_instrument_index,x
	;Load instrument address.
	lda instrument_list,y
	sta sound_local_word_0
	iny
	lda instrument_list,y
	sta sound_local_word_0+1

	.ifdef FEATURE_ARPEGGIOS
	;Get arpeggio type.
	ldy #instrument_header_arpeggio_type
	lda (sound_local_word_0),y
	tay

	;Get the address.
	lda #>(return_from_arpeggio_callback-1)
	pha
	lda #<(return_from_arpeggio_callback-1)
	pha
	lda arpeggio_callback_table_hi,y
	pha
	lda arpeggio_callback_table_lo,y
	pha
	rts
return_from_arpeggio_callback:

	.else

	ldy stream_note,x

	.endif

	;Skip loading note pitch if already loaded, to allow envelopes
	;to modify the pitch.
	lda stream_flags,x
	and #STREAM_PITCH_LOADED_TEST
	bne pitch_already_loaded
	lda stream_flags,x
	ora #STREAM_PITCH_LOADED_SET
	sta stream_flags,x
	;Load low byte of note.
	lda ntsc_note_table_lo,y
	;Store in low 8 bits of pitch.
	sta stream_channel_register_3,x
	;Load high byte of note.
	lda ntsc_note_table_hi,y
	sta stream_channel_register_4,x
pitch_already_loaded:

	;Load volume offset.
	ldy stream_volume_offset,x

	;Load volume value for this frame, but hard code flags and duty for now.
	lda (sound_local_word_0),y
	cmp #ENV_STOP
	beq volume_stop
	cmp #ENV_LOOP
	bne skip_volume_loop

	;We hit a loop opcode, advance envelope index and load loop point.
	iny
	lda (sound_local_word_0),y
	sta stream_volume_offset,x
	tay

skip_volume_loop:

	lda #%10000000
	ora (sound_local_word_0),y
	sta stream_channel_register_1,x

	inc stream_volume_offset,x

volume_stop:

	;Load pitch offset.
	ldy stream_pitch_offset,x

	;Load pitch value.
	lda (sound_local_word_0),y
	cmp #ENV_STOP
	beq pitch_stop
	cmp #ENV_LOOP
	bne skip_pitch_loop

	;We hit a loop opcode, advance envelope index and load loop point.
	iny
	lda (sound_local_word_0),y
	sta stream_pitch_offset,x
	tay

skip_pitch_loop:

	;Test sign.
	lda (sound_local_word_0),y
	bmi pitch_delta_negative
pitch_delta_positive:

	clc
	lda stream_channel_register_3,x
	adc (sound_local_word_0),y
	sta stream_channel_register_3,x
	lda stream_channel_register_4,x
	adc #0
	sta stream_channel_register_4,x

	jmp pitch_delta_test_done

pitch_delta_negative:

	clc
	lda stream_channel_register_3,x
	adc (sound_local_word_0),y
	sta stream_channel_register_3,x
	lda stream_channel_register_4,x
	adc #$ff
	sta stream_channel_register_4,x

pitch_delta_test_done:

	;Move pitch offset along.
	inc stream_pitch_offset,x

pitch_stop:

	rts

.endproc

.proc noise_play_note

	;Load instrument index.
	ldy stream_instrument_index,x
	;Load instrument address.
	lda instrument_list,y
	sta sound_local_word_0
	iny
	lda instrument_list,y
	sta sound_local_word_0+1

	.ifdef FEATURE_ARPEGGIOS
	;Get arpeggio type.
	ldy #instrument_header_arpeggio_type
	lda (sound_local_word_0),y
	tay

	;Get the address.
	lda #>(return_from_arpeggio_callback-1)
	pha
	lda #<(return_from_arpeggio_callback-1)
	pha
	lda arpeggio_callback_table_hi,y
	pha
	lda arpeggio_callback_table_lo,y
	pha
	rts
return_from_arpeggio_callback:

	.else

	ldy stream_note,x

	.endif

	tya
	and #%01111111
	sta sound_local_byte_0

	;Skip loading note pitch if already loaded, to allow envelopes
	;to modify the pitch.
	lda stream_flags,x
	and #STREAM_PITCH_LOADED_TEST
	bne pitch_already_loaded
	lda stream_flags,x
	ora #STREAM_PITCH_LOADED_SET
	sta stream_flags,x
	lda stream_channel_register_3,x
	and #%10000000
	ora sound_local_byte_0
	sta stream_channel_register_3,x
pitch_already_loaded:

	;Load volume offset.
	ldy stream_volume_offset,x

	;Load volume value for this frame, hard code disable flags.
	lda (sound_local_word_0),y
	cmp #ENV_STOP
	beq volume_stop
	cmp #ENV_LOOP
	bne skip_volume_loop

	;We hit a loop opcode, advance envelope index and load loop point.
	iny
	lda (sound_local_word_0),y
	sta stream_volume_offset,x
	tay

skip_volume_loop:

	lda #%00110000
	ora (sound_local_word_0),y
	sta stream_channel_register_1,x

	;Move volume offset along.
	inc stream_volume_offset,x
volume_stop:

	;Load pitch offset.
	ldy stream_pitch_offset,x

	;Load pitch value.
	lda (sound_local_word_0),y
	cmp #ENV_STOP
	beq pitch_stop
	cmp #ENV_LOOP
	bne skip_pitch_loop

	;We hit a loop opcode, advance envelope index and load loop point.
	iny
	lda (sound_local_word_0),y
	sta stream_pitch_offset,x
	tay

skip_pitch_loop:

	;Save off current duty bit.
	lda stream_channel_register_3,x
	and #%10000000
	sta sound_local_byte_0

	;Advance pitch regardless of duty bit.
	clc
	lda stream_channel_register_3,x
	adc (sound_local_word_0),y
	and #%00001111
	;Get duty bit back in.
	ora sound_local_byte_0
	sta stream_channel_register_3,x

	;Move pitch offset along.
	inc stream_pitch_offset,x

pitch_stop:

duty_code:
	;Load duty offset.
	ldy stream_duty_offset,x

	;Load duty value for this frame, but hard code flags and duty for now.
	lda (sound_local_word_0),y
	cmp #DUTY_ENV_STOP
	beq duty_stop
	cmp #DUTY_ENV_LOOP
	bne skip_duty_loop

	;We hit a loop opcode, advance envelope index and load loop point.
	iny
	lda (sound_local_word_0),y
	sta stream_duty_offset,x
	tay

skip_duty_loop:

	;We only care about bit 6 for noise, and we want it in bit 7 position.
	lda (sound_local_word_0),y
	asl
	sta sound_local_byte_0

	lda stream_channel_register_3,x
	and #%01111111
	ora sound_local_byte_0
	sta stream_channel_register_3,x

	;Move duty offset along.
	inc stream_duty_offset,x

duty_stop:

	rts

.endproc

.proc arpeggio_absolute

	ldy stream_arpeggio_offset,x

	lda (sound_local_word_0),y
	cmp #ENV_STOP
	beq arpeggio_stop
	cmp #ENV_LOOP
	beq arpeggio_loop
arpeggio_play:

	;We're changing notes.
	lda stream_flags,x
	and #STREAM_PITCH_LOADED_CLEAR
	sta stream_flags,x

	;Load the current arpeggio value and add it to current note.
	clc
	lda (sound_local_word_0),y
	adc stream_note,x
	tay
	;Advance arpeggio offset.
	inc stream_arpeggio_offset,x

	jmp done
arpeggio_stop:

	;Just load the current note.
	ldy stream_note,x

	jmp done
arpeggio_loop:

	;We hit a loop opcode, advance envelope index and load loop point.
	iny
	lda (sound_local_word_0),y
	sta stream_arpeggio_offset,x
	tay

	;We're changing notes.
	lda stream_flags,x
	and #STREAM_PITCH_LOADED_CLEAR
	sta stream_flags,x

	;Load the current arpeggio value and add it to current note.
	clc
	lda (sound_local_word_0),y
	adc stream_note,x
	tay
	;Advance arpeggio offset.
	inc stream_arpeggio_offset,x
done:

	rts

.endproc

.proc arpeggio_fixed

	ldy stream_arpeggio_offset,x

	lda (sound_local_word_0),y
	cmp #ENV_STOP
	beq arpeggio_stop
	cmp #ENV_LOOP
	beq arpeggio_loop
arpeggio_play:

	;We're changing notes.
	lda stream_flags,x
	and #STREAM_PITCH_LOADED_CLEAR
	sta stream_flags,x

	;Load the current arpeggio value and use it as the current note.
	lda (sound_local_word_0),y
	;sta stream_note,x
	tay
	;Advance arpeggio offset.
	inc stream_arpeggio_offset,x

	jmp done
arpeggio_stop:

	;When a fixed arpeggio is done, we're changing notes to the
	;currently playing note. (This is FamiTracker's behavior)
	;However, we only do this if we're stopping at any point other
	;than one, which indicates an arpeggio did in fact execute.
	lda stream_arpeggio_offset,x
	cmp #1
	beq skip_clear_pitch_loaded
	lda stream_flags,x
	and #STREAM_PITCH_LOADED_CLEAR
	sta stream_flags,x
skip_clear_pitch_loaded:

	;Just load the current note.
	ldy stream_note,x

	jmp done
arpeggio_loop:

	;We hit a loop opcode, advance envelope index and load loop point.
	iny
	lda (sound_local_word_0),y
	sta stream_arpeggio_offset,x
	tay

	;We're changing notes.
	lda stream_flags,x
	and #STREAM_PITCH_LOADED_CLEAR
	sta stream_flags,x

	;Load the current arpeggio value and use it as the current note.
	lda (sound_local_word_0),y
	tay
	;Advance arpeggio offset.
	inc stream_arpeggio_offset,x
done:

	rts

.endproc

.proc arpeggio_relative

	ldy stream_arpeggio_offset,x

	lda (sound_local_word_0),y
	cmp #ENV_STOP
	beq arpeggio_stop
	cmp #ENV_LOOP
	beq arpeggio_loop
arpeggio_play:

	;We're changing notes.
	lda stream_flags,x
	and #STREAM_PITCH_LOADED_CLEAR
	sta stream_flags,x

	;Load the current arpeggio value and add it to current note.
	clc
	lda (sound_local_word_0),y
	adc stream_note,x
	cmp #HIGHEST_NOTE
	bmi skip
	lda #HIGHEST_NOTE
skip:
	sta stream_note,x
	tay
	;Advance arpeggio offset.
	inc stream_arpeggio_offset,x

	jmp done
arpeggio_stop:

	;Just load the current note.
	ldy stream_note,x

	jmp done
arpeggio_loop:

	;We hit a loop opcode, advance envelope index and load loop point.
	iny
	lda (sound_local_word_0),y
	sta stream_arpeggio_offset,x
	tay

	;We're changing notes.
	lda stream_flags,x
	and #STREAM_PITCH_LOADED_CLEAR
	sta stream_flags,x

	;Load the current arpeggio value and add it to current note.
	clc
	lda (sound_local_word_0),y
	adc stream_note,x
	tay
	;Advance arpeggio offset.
	inc stream_arpeggio_offset,x
done:

	rts

.endproc

;****************************************************************
;These callbacks are all stream control and execute in sequence
;until exhausted.
;****************************************************************

.proc set_instrument

	IncrementStreamReadAddr
	;Load byte at read address.
	lda stream_read_address_lo,x
	sta sound_local_word_0
	lda stream_read_address_hi,x
	sta sound_local_word_0+1
	ldy #0
	lda (sound_local_word_0),y
	asl
	sta stream_instrument_index,x
	tay

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

	rts
.endproc

;Set a standard note length. This callback works for a set
;of opcodes which can set the note length for values 1 through 16.
;This helps reduce ROM space required by songs.
.proc set_length

	;determine note length from opcode
	sec
	lda stream_note,x
	sbc #OPCODES_BASE
	clc
	adc #1
	sta stream_note_length_lo,x
	sta stream_note_length_counter_lo,x
	lda #0
	sta stream_note_length_hi,x
	sta stream_note_length_counter_hi,x

	rts

.endproc

.proc set_length_low

	IncrementStreamReadAddr
	;Load byte at read address.
	lda stream_read_address_lo,x
	sta sound_local_word_0
	lda stream_read_address_hi,x
	sta sound_local_word_0+1
	ldy #0
	lda (sound_local_word_0),y
	sta stream_note_length_lo,x
	sta stream_note_length_counter_lo,x
	lda #0
	sta stream_note_length_hi,x
	sta stream_note_length_counter_hi,x

	rts
.endproc

.proc set_length_high

	IncrementStreamReadAddr
	;Load byte at read address.
	lda stream_read_address_lo,x
	sta sound_local_word_0
	lda stream_read_address_hi,x
	sta sound_local_word_0+1
	ldy #0
	lda (sound_local_word_0),y
	sta stream_note_length_hi,x
	sta stream_note_length_counter_hi,x

	rts
.endproc

;This opcode loops to the beginning of the stream. It expects the two
;following bytes to contain the address to loop to.
.proc stream_goto

	IncrementStreamReadAddr
	;Load byte at read address.
	lda stream_read_address_lo,x
	sta sound_local_word_0
	lda stream_read_address_hi,x
	sta sound_local_word_0+1
	ldy #0
	lda (sound_local_word_0),y
	sta stream_read_address_lo,x
	ldy #1
	lda (sound_local_word_0),y
	sta stream_read_address_hi,x

	sec
	lda stream_read_address_lo,x
	sbc #1
	sta stream_read_address_lo,x
	lda stream_read_address_hi,x
	sbc #0
	sta stream_read_address_hi,x

	rts

.endproc

;This opcode stores the current stream read address in
;return_stream_read_address (lo and hi) and then reads the
;following two bytes and stores them in the current stream read address.
;It is assumed that a RET opcode will be encountered in the stream which
;is being called, which will restore the return stream read address.
;This is how the engine can allow repeated chunks of a song.
.proc stream_call

	IncrementStreamReadAddr
	lda stream_read_address_lo,x
	sta sound_local_word_0
	lda stream_read_address_hi,x
	sta sound_local_word_0+1

	;Retrieve lo byte of destination address from first CAL parameter.
	ldy #0
	lda (sound_local_word_0),y
	sta sound_local_word_1
	iny
	;Retrieve hi byte of destination address from second CAL parameter.
	lda (sound_local_word_0),y
	sta sound_local_word_1+1

	IncrementStreamReadAddr

	;Now store current stream read address in stream's return address.
	lda stream_read_address_lo,x
	sta stream_return_address_lo,x
	lda stream_read_address_hi,x
	sta stream_return_address_hi,x

	;Finally, transfer address we are calling to current read address.
	sec
	lda sound_local_word_1
	sbc #<1
	sta stream_read_address_lo,x
	lda sound_local_word_1+1
	sbc #>1
	sta stream_read_address_hi,x

	rts

.endproc

;This opcode restores the stream_return_address to the stream_read_address
;and continues where it left off.
.proc stream_return

	lda stream_return_address_lo,x
	sta stream_read_address_lo,x
	lda stream_return_address_hi,x
	sta stream_read_address_hi,x

	rts

.endproc

;This opcode returns from the parent caller by popping two bytes off
;the stack and then doing rts.
.proc stream_terminate

	;Set the current stream to inactive.
	lda #0
	sta stream_flags,x

	cpx #soundeffect_one
	bmi not_sound_effect

	;Load channel this sfx writes to.
	ldy stream_channel,x
	;Use this as index into streams to tell corresponding music channel
	;to silence until the next note.
	lda stream_flags,y
	ora #STREAM_SILENCE_SET
	sta stream_flags,y

not_sound_effect:

	;Pop current address off the stack.
	pla
	pla

	;Return from parent caller.
	rts
.endproc

.ENDIF