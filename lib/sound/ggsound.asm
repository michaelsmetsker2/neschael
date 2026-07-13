.linecont +
.include "ggsound.inc"
.include "tracks.inc"

.segment "ZEROPAGE"

sound_disable_update: .res 1

sound_local_byte_0: .res 1

sound_local_word_0: .res 2
sound_local_word_1: .res 2

sound_param_byte_0: .res 1
sound_param_byte_1: .res 1

sound_param_word_0: .res 2

apu_data_ready: .res 1
apu_square_1_old: .res 1
apu_square_2_old: .res 1

sfx_list_address: .res 2
song_address: .res 2
apu_register_sets: .res 20

.segment "BSS"

stream_flags:                  .res MAX_STREAMS
stream_note:                   .res MAX_STREAMS
stream_note_length_lo:         .res MAX_STREAMS
stream_note_length_hi:         .res MAX_STREAMS
stream_note_length_counter_lo: .res MAX_STREAMS
stream_note_length_counter_hi: .res MAX_STREAMS

stream_instrument_index:       .res MAX_STREAMS
stream_volume_offset:          .res MAX_STREAMS
stream_arpeggio_offset:        .res MAX_STREAMS
stream_pitch_offset:           .res MAX_STREAMS
stream_duty_offset:            .res MAX_STREAMS

stream_channel:                .res MAX_STREAMS

stream_channel_register_1:     .res MAX_STREAMS
stream_channel_register_2:     .res MAX_STREAMS
stream_channel_register_3:     .res MAX_STREAMS
stream_channel_register_4:     .res MAX_STREAMS

stream_read_address_lo:        .res MAX_STREAMS
stream_read_address_hi:        .res MAX_STREAMS
stream_return_address_lo:      .res MAX_STREAMS
stream_return_address_hi:      .res MAX_STREAMS

stream_tempo_counter_lo:       .res MAX_STREAMS
stream_tempo_counter_hi:       .res MAX_STREAMS
stream_tempo_lo:               .res MAX_STREAMS
stream_tempo_hi:               .res MAX_STREAMS

.segment "CODE"

.proc sound_initialize

    lda #1
    sta sound_disable_update

    ;Enable square 1, square 2, triangle and noise.
    lda #$0F
    sta $4015

    ;Ensure no apu data is uploaded yet.
    lda #0
    sta apu_data_ready

    jsr sound_initialize_apu_buffer

    ;Make sure all streams are killed.
    jsr sound_stop

    dec sound_disable_update

    rts

.endproc

;Kill all active streams and halt sound.
.proc sound_stop

    ;Save x.
    txa
    pha

    inc sound_disable_update

    ;Kill all streams.
    ldx #(MAX_STREAMS-1)
loop:

    lda #0
    sta stream_flags,x

    dex
    bpl loop

    jsr sound_initialize_apu_buffer

    dec sound_disable_update

    ;Restore x.
    pla
    tax

    rts
.endproc

;Updates all playing streams, if actve. Streams 0 through MAX_MUSIC_STREAMS-1
;are assumed to be music streams. The last two streams, are assumed to be sound
;effect streams. When these are playing, their channel control registers are
;copied overtop what the corresponding music streams had written, so the sound
;effect streams essentially take over while they are playing. When the sound
;effect streams are finished, they signify their corresponding music stream
;(via the TRM callback) to silence themselves until the next note to avoid
;ugly volume envelope transitions.
.proc sound_update

    ;Save regs.
    txa
    pha

    ;Signal apu data not ready.
    lda #0
    sta apu_data_ready

    ;First copy all music streams.
    ldx #0
song_stream_register_copy_loop:

    ;Load whether this stream is active.
    lda stream_flags,x
    and #STREAM_ACTIVE_TEST
    beq song_stream_not_active

    ;Update the stream.
    jsr stream_update

    ;Load channel number.
    lda stream_channel,x
    ;Multiply by four to get location within apu_register_sets.
    asl
    asl
    tay
    ;Copy the registers over.
    lda stream_channel_register_1,x
    sta apu_register_sets,y
    lda stream_channel_register_2,x
    sta apu_register_sets+1,y
    lda stream_channel_register_3,x
    sta apu_register_sets+2,y
    lda stream_channel_register_4,x
    sta apu_register_sets+3,y
song_stream_not_active:

    inx
    cpx #MAX_MUSIC_STREAMS
    bne song_stream_register_copy_loop
do_not_update_music:

    ldx #soundeffect_one
sfx_stream_register_copy_loop:

    ;Load whether this stream is active.
    lda stream_flags,x
    and #STREAM_ACTIVE_TEST
    beq sfx_stream_not_active

    ;Update the stream.
    jsr stream_update

    ;Load channel number
    lda stream_channel,x
    ;Multiply by four to get location within apu_register_sets.
    asl
    asl
    tay
    ;Copy the registers over.
    lda stream_channel_register_1,x
    sta apu_register_sets,y
    lda stream_channel_register_2,x
    sta apu_register_sets+1,y
    lda stream_channel_register_3,x
    sta apu_register_sets+2,y
    lda stream_channel_register_4,x
    sta apu_register_sets+3,y
sfx_stream_not_active:

    inx
    cpx #MAX_STREAMS
    bne sfx_stream_register_copy_loop

    ;Signial apu data ready.
    lda #1
    sta apu_data_ready

    ;Restore regs.
    pla
    tax

    rts
.endproc

;Note table borrowed from periods.s provided by FamiTracker's NSF driver.
ntsc_note_table_lo:
    .byte <$0D5B, <$0C9C, <$0BE6, <$0B3B, <$0A9A, <$0A01, <$0972, <$08EA, <$086A, <$07F1, <$077F, <$0713
    .byte <$06AD, <$064D, <$05F3, <$059D, <$054C, <$0500, <$04B8, <$0474, <$0434, <$03F8, <$03BF, <$0389
    .byte <$0356, <$0326, <$02F9, <$02CE, <$02A6, <$0280, <$025C, <$023A, <$021A, <$01FB, <$01DF, <$01C4
    .byte <$01AB, <$0193, <$017C, <$0167, <$0152, <$013F, <$012D, <$011C, <$010C, <$00FD, <$00EF, <$00E1
    .byte <$00D5, <$00C9, <$00BD, <$00B3, <$00A9, <$009F, <$0096, <$008E, <$0086, <$007E, <$0077, <$0070
    .byte <$006A, <$0064, <$005E, <$0059, <$0054, <$004F, <$004B, <$0046, <$0042, <$003F, <$003B, <$0038
    .byte <$0034, <$0031, <$002F, <$002C, <$0029, <$0027, <$0025, <$0023, <$0021, <$001F, <$001D, <$001B
    .byte <$001A, <$0018, <$0017, <$0015, <$0014, <$0013, <$0012, <$0011, <$0010, <$000F, <$000E, <$000D

ntsc_note_table_hi:
    .byte >$0D5B, >$0C9C, >$0BE6, >$0B3B, >$0A9A, >$0A01, >$0972, >$08EA, >$086A, >$07F1, >$077F, >$0713
    .byte >$06AD, >$064D, >$05F3, >$059D, >$054C, >$0500, >$04B8, >$0474, >$0434, >$03F8, >$03BF, >$0389
    .byte >$0356, >$0326, >$02F9, >$02CE, >$02A6, >$0280, >$025C, >$023A, >$021A, >$01FB, >$01DF, >$01C4
    .byte >$01AB, >$0193, >$017C, >$0167, >$0152, >$013F, >$012D, >$011C, >$010C, >$00FD, >$00EF, >$00E1
    .byte >$00D5, >$00C9, >$00BD, >$00B3, >$00A9, >$009F, >$0096, >$008E, >$0086, >$007E, >$0077, >$0070
    .byte >$006A, >$0064, >$005E, >$0059, >$0054, >$004F, >$004B, >$0046, >$0042, >$003F, >$003B, >$0038
    .byte >$0034, >$0031, >$002F, >$002C, >$0029, >$0027, >$0025, >$0023, >$0021, >$001F, >$001D, >$001B
    .byte >$001A, >$0018, >$0017, >$0015, >$0014, >$0013, >$0012, >$0011, >$0010, >$000F, >$000E, >$000D

channel_callback_table_lo:
    .byte <square_1_play_note
    .byte <square_2_play_note
    .byte <triangle_play_note
    .byte <noise_play_note

channel_callback_table_hi:
    .byte >square_1_play_note
    .byte >square_2_play_note
    .byte >triangle_play_note
    .byte >noise_play_note

stream_callback_table_lo:
    .byte <stream_set_length_s
    .byte <stream_set_length_s
    .byte <stream_set_length_s
    .byte <stream_set_length_s
    .byte <stream_set_length_s
    .byte <stream_set_length_s
    .byte <stream_set_length_s
    .byte <stream_set_length_s
    .byte <stream_set_length_s
    .byte <stream_set_length_s
    .byte <stream_set_length_s
    .byte <stream_set_length_s
    .byte <stream_set_length_s
    .byte <stream_set_length_s
    .byte <stream_set_length_s
    .byte <stream_set_length_s
    .byte <stream_set_length_lo
    .byte <stream_set_length_hi
    .byte <stream_set_instrument
    .byte <stream_goto
    .byte <stream_call
    .byte <stream_return
    .byte <stream_terminate

stream_callback_table_hi:
    .byte >stream_set_length_s
    .byte >stream_set_length_s
    .byte >stream_set_length_s
    .byte >stream_set_length_s
    .byte >stream_set_length_s
    .byte >stream_set_length_s
    .byte >stream_set_length_s
    .byte >stream_set_length_s
    .byte >stream_set_length_s
    .byte >stream_set_length_s
    .byte >stream_set_length_s
    .byte >stream_set_length_s
    .byte >stream_set_length_s
    .byte >stream_set_length_s
    .byte >stream_set_length_s
    .byte >stream_set_length_s
    .byte >stream_set_length_lo
    .byte >stream_set_length_hi
    .byte >stream_set_instrument
    .byte >stream_goto
    .byte >stream_call
    .byte >stream_return
    .byte >stream_terminate

arpeggio_callback_table_lo:
    .byte <(arpeggio_absolute-1)
    .byte <(arpeggio_fixed-1)
    .byte <(arpeggio_relative-1)

arpeggio_callback_table_hi:
    .byte >(arpeggio_absolute-1)
    .byte >(arpeggio_fixed-1)
    .byte >(arpeggio_relative-1)

;****************************************************************
;These callbacks are all note playback and only execute once per
;frame.
;****************************************************************

.proc square_1_play_note

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

square_2_play_note = square_1_play_note

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

.proc stream_set_instrument

    advance_stream_read_address
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
.proc stream_set_length_s

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

.proc stream_set_length_lo

    advance_stream_read_address
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

.proc stream_set_length_hi

    advance_stream_read_address
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

    advance_stream_read_address
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

    advance_stream_read_address
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

    advance_stream_read_address

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

;Expects sound_param_byte_0 to contain index of a song in song_list.
;Assumed to be four addresses to initialize streams on, for square1, square2, triangle and noise.
;Any addresses found to be zero will not initialize that channel.
.proc play_song

    ;Save index regs.
    tya
    pha
    txa
    pha

    inc sound_disable_update

    ;Get song address from song list.
    lda sound_param_byte_0
    asl
    tay
    lda song_list,y
    sta song_address
    iny
    lda song_list,y
    sta song_address+1

    ;Load square 1 stream.
    ldx #0
    jsr stream_stop

    ldy #track_header_square1_stream_address
    lda (song_address),y
    sta sound_param_word_0
    iny
    lda (song_address),y
    beq no_square_1
    sta sound_param_word_0+1

    lda #0
    sta sound_param_byte_0

    lda #0
    sta sound_param_byte_1

    jsr stream_initialize

    ldy #track_header_ntsc_tempo_lo
    lda (song_address),y
    sta stream_tempo_lo,x
    sta stream_tempo_counter_lo,x

    iny
    lda (song_address),y
    sta stream_tempo_hi,x
    sta stream_tempo_counter_hi,x
no_square_1:

    ;Load square 2 stream.
    ldx #1
    jsr stream_stop

    ldy #track_header_square2_stream_address
    lda (song_address),y
    sta sound_param_word_0
    iny
    lda (song_address),y
    beq no_square_2
    sta sound_param_word_0+1

    lda #1
    sta sound_param_byte_0

    lda #1
    sta sound_param_byte_1

    jsr stream_initialize

    ldy #track_header_ntsc_tempo_lo
    lda (song_address),y
    sta stream_tempo_lo,x
    sta stream_tempo_counter_lo,x

    iny
    lda (song_address),y
    sta stream_tempo_hi,x
    sta stream_tempo_counter_hi,x
no_square_2:

    ;Load triangle stream.
    ldx #2
    jsr stream_stop

    ldy #track_header_triangle_stream_address
    lda (song_address),y
    sta sound_param_word_0
    iny
    lda (song_address),y
    beq no_triangle
    sta sound_param_word_0+1

    lda #2
    sta sound_param_byte_0

    lda #2
    sta sound_param_byte_1

    jsr stream_initialize

    ldy #track_header_ntsc_tempo_lo
    lda (song_address),y
    sta stream_tempo_lo,x
    sta stream_tempo_counter_lo,x

    iny
    lda (song_address),y
    sta stream_tempo_hi,x
    sta stream_tempo_counter_hi,x
no_triangle:

    ;Load noise stream.
    ldx #3
    jsr stream_stop

    ldy #track_header_noise_stream_address
    lda (song_address),y
    sta sound_param_word_0
    iny
    lda (song_address),y
    beq no_noise
    sta sound_param_word_0+1

    lda #3
    sta sound_param_byte_0

    lda #3
    sta sound_param_byte_1

    jsr stream_initialize

    ldy #track_header_ntsc_tempo_lo
    lda (song_address),y
    sta stream_tempo_lo,x
    sta stream_tempo_counter_lo,x

    iny
    lda (song_address),y
    sta stream_tempo_hi,x
    sta stream_tempo_counter_hi,x
no_noise:

    dec sound_disable_update

    ;Restore index regs.
    pla
    tax
    pla
    tay

    rts

.endproc

;Expects sound_param_byte_0 to contain the index of the sound effect to play.
;Expects sound_param_byte_1 to contain the sound effect priority. This can
;be one of two values: soundeffect_one, and soundeffect_two from ggsound.inc.
;Assumes the parameters are correct; no range checking is performed.
.proc play_sfx

    ;Save index regs.
    tya
    pha
    txa
    pha

    inc sound_disable_update

    ;Get sfx address from sfx list.
    lda sound_param_byte_0
    asl
    tay
    lda sfx_list,y
    sta sound_local_word_0
    iny
    lda sfx_list,y
    sta sound_local_word_0+1

    lda sound_param_byte_1
    sta sound_local_byte_0

    ;Load square 1 stream.
    ldy #track_header_square1_stream_address
    lda (sound_local_word_0),y
    sta sound_param_word_0
    iny
    lda (sound_local_word_0),y
    beq no_square_1
    sta sound_param_word_0+1

    lda #0
    sta sound_param_byte_0

    lda sound_local_byte_0
    sta sound_param_byte_1

    jsr stream_initialize

    ldx sound_local_byte_0
    ldy #track_header_ntsc_tempo_lo
    lda (sound_local_word_0),y
    sta stream_tempo_lo,x
    sta stream_tempo_counter_lo,x
    iny
    lda (sound_local_word_0),y
    sta stream_tempo_hi,x
    sta stream_tempo_counter_hi,x

    inc sound_local_byte_0
no_square_1:

    lda sound_local_byte_0
    cmp #(soundeffect_two + 1)
    bne skip0
    jmp no_more_sfx_streams_available
skip0:

    ;Load square 2 stream.
    ldy #track_header_square2_stream_address
    lda (sound_local_word_0),y
    sta sound_param_word_0
    iny
    lda (sound_local_word_0),y
    beq no_square_2
    sta sound_param_word_0+1

    lda #1
    sta sound_param_byte_0

    lda sound_local_byte_0
    sta sound_param_byte_1

    jsr stream_initialize

    ldx sound_local_byte_0
    ldy #track_header_ntsc_tempo_lo
    lda (sound_local_word_0),y
    sta stream_tempo_lo,x
    sta stream_tempo_counter_lo,x
    iny
    lda (sound_local_word_0),y
    sta stream_tempo_hi,x
    sta stream_tempo_counter_hi,x

    inc sound_local_byte_0
no_square_2:

    lda sound_local_byte_0
    cmp #(soundeffect_two + 1)
    bne skip1
    jmp no_more_sfx_streams_available
skip1:

    ;Load triangle stream.
    ldy #track_header_triangle_stream_address
    lda (sound_local_word_0),y
    sta sound_param_word_0
    iny
    lda (sound_local_word_0),y
    beq no_triangle
    sta sound_param_word_0+1

    lda #2
    sta sound_param_byte_0

    lda sound_local_byte_0
    sta sound_param_byte_1

    jsr stream_initialize

    ldx sound_local_byte_0
    ldy #track_header_ntsc_tempo_lo
    lda (sound_local_word_0),y
    sta stream_tempo_lo,x
    sta stream_tempo_counter_lo,x
    iny
    lda (sound_local_word_0),y
    sta stream_tempo_hi,x
    sta stream_tempo_counter_hi,x

    inc sound_local_byte_0
no_triangle:

    lda sound_local_byte_0
    cmp #(soundeffect_two + 1)
    beq no_more_sfx_streams_available

    ;Load noise stream.
    ldy #track_header_noise_stream_address
    lda (sound_local_word_0),y
    sta sound_param_word_0
    iny
    lda (sound_local_word_0),y
    beq no_noise
    sta sound_param_word_0+1

    lda #3
    sta sound_param_byte_0

    lda sound_local_byte_0
    sta sound_param_byte_1

    jsr stream_initialize

    ldx sound_local_byte_0
    ldy #track_header_ntsc_tempo_lo
    lda (sound_local_word_0),y
    sta stream_tempo_lo,x
    sta stream_tempo_counter_lo,x
    iny
    lda (sound_local_word_0),y
    sta stream_tempo_hi,x
    sta stream_tempo_counter_hi,x

    inc sound_local_byte_0
no_noise:

no_more_sfx_streams_available:

    dec sound_disable_update

    ;Restore index regs.
    pla
    tax
    pla
    tay

    rts

.endproc

;Pauses all music streams by clearing volume bits from all channel registers
;and setting the pause flag so these streams are not updated.
.proc pause_song

    ldx #(MAX_MUSIC_STREAMS-1)
next_stream:

    lda stream_flags,x
    ora #STREAM_PAUSE_SET
    sta stream_flags,x

    lda stream_channel_register_1,x
    and #%11110000
    sta stream_channel_register_1,x

    dex
    bpl next_stream

    rts

.endproc

;Resumes all music streams.
.proc resume_song

    ldx #(MAX_MUSIC_STREAMS-1)
next_stream:

    lda stream_flags,x
    and #STREAM_PAUSE_CLEAR
    sta stream_flags,x

    dex
    bpl next_stream

    rts

.endproc

;Expects sound_param_byte_0 to contain the channel on which to play the stream.
;Expects sound_param_byte_1 to contain the offset of the stream instance to initialize.
;Expects sound_param_word_0 to contain the starting read address of the stream to
;initialize.
.proc stream_initialize
channel = sound_param_byte_0
stream = sound_param_byte_1
starting_read_address = sound_param_word_0

    ;Save x.
    txa
    pha

    ldx stream

    inc sound_disable_update

    lda starting_read_address
    ora starting_read_address+1
    beq null_starting_read_address

    ;Set stream to be inactive while initializing.
    lda #0
    sta stream_flags,x

    ;Set a default note length (20 frames).
    lda #20
    sta stream_note_length_lo,x
    ;Set initial note length counter.
    sta stream_note_length_counter_lo,x
    lda #0
    sta stream_note_length_hi,x
    sta stream_note_length_counter_hi,x

    ;Set initial instrument index.
    lda #0
    sta stream_instrument_index,x
    sta stream_volume_offset,x
    sta stream_pitch_offset,x
    sta stream_duty_offset,x
    sta stream_arpeggio_offset,x

    ;Set channel.
    lda channel
    sta stream_channel,x

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

    rts
.endproc

;Stops a stream from playing.
;Assumes x contains the index of the stream to kill.
.proc stream_stop

    inc sound_disable_update

    lda #0
    sta stream_flags,x

    dec sound_disable_update

    rts

.endproc

;Updates a single stream.
;Expects x to be pointing to a stream instance as an offset from streams.
.proc stream_update
callback_address = sound_local_word_0
read_address = sound_local_word_1

    lda stream_flags,x
    and #STREAM_PAUSE_TEST
    beq skip0
    rts
skip0:

    ;Load current read address of stream.
    lda stream_read_address_lo,x
    sta read_address
    lda stream_read_address_hi,x
    sta read_address+1

    ;Load next byte from stream data.
    lda stream_flags,x
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
    advance_stream_read_address

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
    advance_stream_read_address
do_not_advance_note_length_counter:
note_length_counter_not_zero:

    rts

.proc indirect_jsr_callback_address
    jmp (callback_address)
    rts
.endproc

.endproc

.proc sound_initialize_apu_buffer

    ;****************************************************************
    ;Initialize Square 1
    ;****************************************************************

    ;Set Saw Envelope Disable and Length Counter Disable to 1 for square 1.
    lda #%00110000
    sta apu_register_sets

    ;Set Negate flag on the sweep unit.
    lda #$08
    sta apu_register_sets+1

    ;Set period to C9, which is a C#...just in case nobody writes to it.
    lda #$C9
    sta apu_register_sets+2

    ;Make sure the old value starts out different from the first default value.
    sta apu_square_1_old

    lda #$00
    sta apu_register_sets+3

    ;****************************************************************
    ;Initialize Square 2
    ;****************************************************************

    ;Set Saw Envelope Disable and Length Counter Disable to 1 for square 2.
    lda #%00110000
    sta apu_register_sets+4

    ;Set Negate flag on the sweep unit.
    lda #$08
    sta apu_register_sets+5

    ;Set period to C9, which is a C#...just in case nobody writes to it.
    lda #$C9
    sta apu_register_sets+6

    ;Make sure the old value starts out different from the first default value.
    sta apu_square_2_old

    lda #$00
    sta apu_register_sets+7

    ;****************************************************************
    ;Initialize Triangle
    ;****************************************************************
    lda #%10000000
    sta apu_register_sets+8

    lda #$C9
    sta apu_register_sets+10

    lda #$00
    sta apu_register_sets+11

    ;****************************************************************
    ;Initialize Noise
    ;****************************************************************
    lda #%00110000
    sta apu_register_sets+12

    lda #%00000000
    sta apu_register_sets+13

    lda #%00000000
    sta apu_register_sets+14

    lda #%00000000
    sta apu_register_sets+15

    rts
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
