; 
; neschael
; lib/sound/callbacks.s
;
; contains jump tables and proccesses for all callbacks in the sound engine, these are for processing opcodes, playing notes, and arpeggios
;

.INCLUDE "lib/sound/sound.inc"

.IMPORT instrument_list_low
.IMPORT instrument_list_high

.IMPORTZP SCRATCH

.IMPORT period_table_low
.IMPORT period_table_high

.IMPORT instrument_list_low
.IMPORT instrument_list_high

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

	; note callbacks

	; x contains stream offset
.PROC square_play_note
	instPtr = SCRATCH

	;Load instrument index.
	LDY streamInstrumentIndex, X
	;Load instrument address.
	LDA instrument_list_low, Y
	STA instPtr 
	LDA instrument_list_high, Y
	STA instPtr+1

	;Set negate flag for sweep unit.
	LDA #$08
	STA streamRegister_2, X

	; get arpeggio type.
	LDY #INSTRUMENT_HEADER_ARP_TYPE_OFFSET
	LDA (instPtr), Y
	TAY

	; push return address for arpeggio rts trick
	LDA #>(@return_from_arpeggio_callback-1)
	PHA
	LDA #<(@return_from_arpeggio_callback-1)
	PHA
	LDA arpeggio_table_high, Y
	PHA
	LDA arpeggio_table_low, Y
	PHA
	RTS
@return_from_arpeggio_callback:

	; load pitch if it isn't already
	LDA streamFlags, X
	AND #STREAM_PITCH_LOADED_MASK
	BNE @pitch_loaded
	
	LDA streamFlags, X
	ORA #STREAM_PITCH_LOADED_MASK
	STA streamFlags, X

	;Load low byte of note.
	LDA period_table_low, Y
	;Store in low 8 bits of pitch.
	STA streamRegister_3, X
	;Load high byte of note.
	LDA period_table_high, Y
	STA streamRegister_4, X

@pitch_loaded:

	; check and branch if stream is silenced
	LDA streamFlags, X
	AND #STREAM_SILENCE_MASK
	BNE @silence_until_note

	; Load volume offset.
	LDY streamVolumeOffset, X
	; Load volume value for this frame, branch if loop or stop.
	LDA (instPtr), Y
	CMP #ENV_STOP
	BEQ @volume_stop
	CMP #ENV_LOOP
	BNE @volume_value

@vol_loop_opcode:
	; advance envelope index and load loop point as offset.
	INY
	LDA (instPtr), Y
	STA streamVolumeOffset, X
	TAY

@volume_value:

	; set vol
	LDA streamRegister_1, X
	; keeps old duty cycle bits
	AND #%11000000
	; length counter disable
	ORA #%00110000

	;Load current volume value.
	ORA (instPtr), Y
	STA streamRegister_1, X

	; increment offset
	INC streamVolumeOffset, X
@volume_stop:

	JMP @pitch
@silence_until_note:
	LDA streamRegister_1, X
	; keep old duty cycle bits
	AND #%11000000
	; length counter disable
	ORA #%00110000
	; volume is zero
	STA streamRegister_1, X

@pitch:
	;Load pitch offset.
	LDY streamPitchOffset, X

	;Load pitch value.
	LDA (instPtr), Y
	CMP #ENV_STOP
	BEQ @duty
	CMP #ENV_LOOP
	BNE @pitch_value

@pitch_loop_opcode: 
	; advance envelope index and load loop point.
	INY
	LDA (instPtr), Y
	STA streamPitchOffset, X
	TAY

@pitch_value:
	; Test sign
	LDA (instPtr), Y
	BMI @pitch_neg

@pitch_pos:
	CLC
	LDA streamRegister_3, X
	ADC (instPtr), Y
	STA streamRegister_3, X
	BCC :+
	INC streamRegister_4, X
	:
	
	JMP @inc_pitch_offset

@pitch_neg:
	CLC
	LDA streamRegister_3, X
	ADC (instPtr), Y
	STA streamRegister_3, X
	BCS :+
	DEC streamRegister_4, X
	:

@inc_pitch_offset:
	INC streamPitchOffset, X

@duty:
	LDY streamDutyOffset, X

	;Load duty value for this frame, but hard code flags and duty for now.
	LDA (instPtr), Y
	CMP #DUTY_ENV_STOP
	BEQ @done
	CMP #DUTY_ENV_LOOP
	BNE @duty_value

	;We hit a loop opcode, advance envelope index and load loop point.
	INY
	LDA (instPtr), Y
	STA streamDutyOffset, X
	TAY

@duty_value:
	;Or the duty value into the register.
	LDA streamRegister_1, X
	AND #%00111111
	ORA (instPtr), Y
	STA streamRegister_1, X

	; increment offset
	INC streamDutyOffset, X

@done:
	RTS
.ENDPROC

.PROC triangle_play_note
	instPtr = SCRATCH

	;Load instrument index.
	LDY streamInstrumentIndex, X
	;Load instrument address.
	LDA instrument_list_low, Y
	STA instPtr 
	LDA instrument_list_high, Y
	STA instPtr+1

	; get arpeggio type.
	LDY #INSTRUMENT_HEADER_ARP_TYPE_OFFSET
	LDA (instPtr), Y
	TAY

	; push return address for arpeggio rts trick
	LDA #>(@return_from_arpeggio_callback-1)
	PHA
	LDA #<(@return_from_arpeggio_callback-1)
	PHA
	LDA arpeggio_table_high, Y
	PHA
	LDA arpeggio_table_low, Y
	PHA
	RTS
@return_from_arpeggio_callback:

	; load pitch if it isn't already
	LDA streamFlags, X
	AND #STREAM_PITCH_LOADED_MASK
	BNE @pitch_loaded
	
	LDA streamFlags, X
	ORA #STREAM_PITCH_LOADED_MASK
	STA streamFlags, X

	;Load low byte of note.
	LDA period_table_low, Y
	;Store in low 8 bits of pitch.
	STA streamRegister_3, X
	;Load high byte of note.
	LDA period_table_high, Y
	STA streamRegister_4, X

@pitch_loaded:

	;Load volume offset.
	LDY streamVolumeOffset, X

	;Load volume value for this frame, but hard code flags and duty for now.
	LDA (instPtr), Y
	CMP #ENV_STOP
	BEQ @pitch
	CMP #ENV_LOOP
	BNE @vol_value

@vol_loop_opcode:
	; advance envelope and load loop point.
	INY
	LDA (instPtr), Y
	STA streamVolumeOffset, X
	TAY

@vol_value:

	LDA #%10000000
	ORA (instPtr), Y
	STA streamRegister_1, X

	INC streamVolumeOffset, X

@pitch:
	;Load pitch offset.
	LDY streamPitchOffset, X

	;Load pitch value.
	LDA (instPtr), Y
	CMP #ENV_STOP
	BEQ @done
	CMP #ENV_LOOP
	BNE @pitch_value

@pitch_loop_opcode:
	; advance envelope index and load loop point.
	INY
	LDA (instPtr), Y
	STA streamPitchOffset, X
	TAY

@pitch_value:
	; Test sign
	LDA (instPtr), Y
	BMI @pitch_neg

@pitch_pos:
	CLC
	LDA streamRegister_3, X
	ADC (instPtr), Y
	STA streamRegister_3, X
	BCC :+
	INC streamRegister_4, X
	:
	
	JMP @inc_pitch_offset

@pitch_neg:
	CLC
	LDA streamRegister_3, X
	ADC (instPtr), Y
	STA streamRegister_3, X
	BCS :+
	DEC streamRegister_4, X
	:

@inc_pitch_offset:
	inc streamPitchOffset, X

@done:
	RTS

.ENDPROC

.PROC noise_play_note
	instPtr = SCRATCH
	tempStorage = SCRATCH+2

	;Load instrument index.
	LDY streamInstrumentIndex, X
	;Load instrument address.
	LDA instrument_list_low, Y
	STA instPtr 
	LDA instrument_list_high, Y
	STA instPtr+1

	; get arpeggio type.
	LDY #INSTRUMENT_HEADER_ARP_TYPE_OFFSET
	LDA (instPtr), Y
	TAY

	; push return address for arpeggio rts trick
	LDA #>(@return_from_arpeggio_callback-1)
	PHA
	LDA #<(@return_from_arpeggio_callback-1)
	PHA
	LDA arpeggio_table_high, Y
	PHA
	LDA arpeggio_table_low, Y
	PHA
	RTS
@return_from_arpeggio_callback:

	TYA
	AND #%01111111
	STA tempStorage

	; load pitch if it isn't already
	LDA streamFlags, X
	AND #STREAM_PITCH_LOADED_MASK
	BNE @pitch_loaded
	
	LDA streamFlags, X
	ORA #STREAM_PITCH_LOADED_MASK
	STA streamFlags, X
	LDA streamRegister_3, X
	AND #%10000000
	ORA tempStorage
	STA streamRegister_3, X
@pitch_loaded:
	; Load volume offset.
	LDY streamVolumeOffset, X

	; Load volume value for this frame, branch if loop or stop.
	LDA (instPtr), Y
	CMP #ENV_STOP
	BEQ @pitch
	CMP #ENV_LOOP
	BNE @volume_value

@vol_loop_opcode:
	; advance envelope index and load loop point as offset.
	INY
	LDA (instPtr), Y
	STA streamVolumeOffset, X
	TAY

@volume_value:

	LDA #%00110000
	ORA (instPtr), Y
	STA streamRegister_1, X

	;Move volume offset along.
	INC streamVolumeOffset, X
@pitch:

	;Load pitch offset.
	LDY streamPitchOffset, X

	;Load pitch value.
	LDA (instPtr), Y
	CMP #ENV_STOP
	BEQ duty
	CMP #ENV_LOOP
	BNE pitch_value

pitch_loop_opcode:
	; advance envelope index and load loop point.
	INY
	LDA (instPtr), Y
	STA streamPitchOffset, X
	TAY

pitch_value:
	; Save off current duty bit.
	LDA streamRegister_3, X
	AND #%10000000
	STA tempStorage

	;Advance pitch regardless of duty bit.
	CLC
	LDA streamRegister_3, X
	ADC (instPtr), Y
	AND #%00001111
	;Get duty bit back in.
	ORA tempStorage
	STA streamRegister_3, X

	;Move pitch offset along.
	INC streamPitchOffset, X

duty:

	;Load duty offset.
	LDY streamDutyOffset, X

	;Load duty value for this frame, but hard code flags and duty for now.
	LDA (instPtr), Y
	CMP #DUTY_ENV_STOP
	BEQ @done
	CMP #DUTY_ENV_LOOP
	BNE @duty_value

@duty_loop_opcode:
	; advance envelope index and load loop point.
	INY
	LDA (instPtr), Y
	STA streamDutyOffset, X
	TAY

@duty_value:

	;We only care about bit 6 for noise, and we want it in bit 7 position.
	LDA (instPtr), Y
	ASL
	STA tempStorage

	LDA streamRegister_3, X
	AND #%01111111
	ORA tempStorage
	STA streamRegister_3, X

	;Move duty offset along.
	INC streamDutyOffset, X

@done:
	RTS
.ENDPROC

.PROC arpeggio_absolute
	instPtr = SCRATCH

	LDY streamArpeggioOffset, X

	LDA (instPtr), Y
	CMP #ENV_STOP
	BEQ arpeggio_stop
	CMP #ENV_LOOP
	BNE arpeggio_play
arpeggio_loop:

	;We hit a loop opcode, advance envelope index and load loop point.
	INY
	LDA (instPtr), Y
	STA streamArpeggioOffset, X
	TAY

arpeggio_play:

	;We're changing notes.
	LDA streamFlags, X
	AND #STREAM_PITCH_LOADED_CLEAR
	STA streamFlags, X

	;Load the current arpeggio value and add it to current note.
	CLC
	LDA (instPtr), Y
	ADC streamNote, X
	TAY
	;Advance arpeggio offset.
	INC streamArpeggioOffset, X

	RTS

arpeggio_stop:
	;Just load the current note.
	LDY streamNote, X
	RTS
.ENDPROC

.PROC arpeggio_fixed
	instPtr = SCRATCH

	LDY streamArpeggioOffset, X
	LDA (instPtr), Y
	CMP #ENV_STOP
	BEQ arpeggio_stop
	CMP #ENV_LOOP
	BNE arpeggio_play

arpeggio_loop:

	; advance envelope index and load loop point.
	INY
	LDA (instPtr), Y
	STA streamArpeggioOffset, X
	TAY

arpeggio_play:

	;We're changing notes.
	LDA streamFlags, X
	AND #STREAM_PITCH_LOADED_CLEAR
	STA streamFlags, X

	;Load the current arpeggio value and use it as the current note.
	LDA (instPtr), Y
	TAY
	;Advance arpeggio offset.
	INC streamArpeggioOffset, X

	RTS
arpeggio_stop:

	;When a fixed arpeggio is done, we're changing notes to the
	;currently playing note. (This is FamiTracker's behavior)
	;However, we only do this if we're stopping at any point other
	;than one, which indicates an arpeggio did in fact execute.
	LDA streamArpeggioOffset, X
	CMP #$01
	BEQ skip_clear_pitch_loaded
	LDA streamFlags, X
	AND #STREAM_PITCH_LOADED_CLEAR
	STA streamFlags, X
skip_clear_pitch_loaded:

	;Just load the current note.
	LDY streamNote, X

	RTS

.ENDPROC

.PROC arpeggio_relative

	instPtr = SCRATCH

	LDY streamArpeggioOffset, X

	LDA (instPtr), Y
	CMP #ENV_STOP
	BEQ arpeggio_stop
	CMP #ENV_LOOP
	BNE arpeggio_play

arpeggio_loop:

	;We hit a loop opcode, advance envelope index and load loop point.
	INY
	LDA (instPtr), Y
	STA streamArpeggioOffset, X
	TAY
	
arpeggio_play:

	;We're changing notes.
	LDA streamFlags, X
	AND #STREAM_PITCH_LOADED_CLEAR
	STA streamFlags, X

	;Load the current arpeggio value and add it to current note.
	CLC
	LDA (instPtr), Y
	ADC streamNote, X
	CMP #HIGHEST_NOTE
	BMI @skip
	LDA #HIGHEST_NOTE
@skip:
	STA streamNote, X
	TAY
	;Advance arpeggio offset.
	INC streamArpeggioOffset, X

	RTS

arpeggio_stop:
	;Just load the current note.
	LDY streamNote, X
	RTS
.ENDPROC

	; opcode callbacks

.PROC set_instrument
	streamPtr = audio_scratch
	callbackAddr = audio_scratch+2
	instPtr = audio_scratch+4

	IncrementStreamReadAddr
	; Load next byte in data stream.
	LDA streamReadAddrLow, X
	STA streamPtr
	LDA streamReadAddrHigh, X
	STA streamPtr+1

	LDY #$00
	LDA (streamPtr), Y
	STA streamInstrumentIndex, X
	TAY

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

	RTS
.ENDPROC

; This callback works for a set
;of opcodes which can set the note length for values 1 through 16.
;This helps reduce ROM space required by songs.
.PROC set_length

	;determine note length from opcode
	SEC
	LDA streamNote, X
	SBC #OPCODE_THRESHOLD
	CLC
	ADC #$01
	STA streamNoteLength, X
	STA streamNoteCounter, X
	RTS

.ENDPROC

.PROC set_length_low
	streamPtr = audio_scratch
	callbackAddr = audio_scratch+2
	instPtr = audio_scratch+4

	IncrementStreamReadAddr
	; Load next byte in data stream.
	LDA streamReadAddrLow, X
	STA streamPtr
	LDA streamReadAddrHigh, X
	STA streamPtr+1

	LDY #$00
	LDA (streamPtr), Y
	STA streamNoteLength, X
	STA streamNoteCounter, X
	
	RTS
.ENDPROC

.PROC set_length_high

	; Uh oh, this feature was removed
	RTS
.ENDPROC

;This opcode loops to the beginning of the stream. It expects the two
;following bytes to contain the address to loop to.
.PROC stream_goto
	streamPtr = audio_scratch
	callbackAddr = audio_scratch+2
	instPtr = audio_scratch+4

	IncrementStreamReadAddr
	; Load next byte in data stream.
	LDA streamReadAddrLow, X
	STA streamPtr
	LDA streamReadAddrHigh, X
	STA streamPtr+1
	
	LDY #$00
	LDA (streamPtr), Y
	STA streamReadAddrLow, X
	LDY #$01
	LDA (streamPtr), Y
	STA streamReadAddrHigh, X

	LDA streamReadAddrLow, X
	BNE :+
	DEC streamReadAddrHigh, X
	:
	DEC streamReadAddrLow, X

	RTS

.ENDPROC

;This opcode stores the current stream read address in
;return_stream_read_address (lo and hi) and then reads the
;following two bytes and stores them in the current stream read address.
;It is assumed that a RET opcode will be encountered in the stream which
;is being called, which will restore the return stream read address.
;This is how the engine can allow repeated chunks of a song.
.proc stream_call
	streamPtr = audio_scratch
	callbackAddr = audio_scratch+2
	instPtr = audio_scratch+4

	tempPtr = SCRATCH

	IncrementStreamReadAddr
	; Load next byte in data stream.
	LDA streamReadAddrLow, X
	STA streamPtr
	LDA streamReadAddrHigh, X
	STA streamPtr+1

	;Retrieve lo byte of destination address from first CAL parameter.
	LDY #$00
	LDA (streamPtr), Y
	STA tempPtr
	INY
	;Retrieve hi byte of destination address from second CAL parameter.
	LDA (streamPtr), Y
	STA tempPtr+1

	IncrementStreamReadAddr

	;Now store current stream read address in stream's return address.
	LDA streamReadAddrLow, X
	STA streamReturnAddrLow, X
	LDA streamReadAddrHigh, X
	STA streamReturnAddrHigh, X

	;Finally, transfer address we are calling to current read address.
	SEC
	LDA tempPtr
	SBC #$01
	STA streamReadAddrLow, X
	LDA tempPtr+1
	SBC #$00
	STA streamReadAddrHigh, X
	
	RTS
.ENDPROC

;This opcode restores the stream_return_address to the stream_read_address
;and continues where it left off.
.PROC stream_return

	LDA streamReturnAddrLow, X
	STA streamReadAddrLow, X
	LDA streamReturnAddrHigh, X
	STA streamReadAddrHigh, X

	RTS
.ENDPROC

;This opcode returns from the parent caller by popping two bytes off
;the stack and then doing rts.
.PROC stream_terminate

	;Set the current stream to inactive.
	LDA #$00
	STA streamFlags, X

	CPX #Audio_streams::SFX_1
	BMI not_sound_effect

	;Load channel this sfx writes to.
	LDY streamChannel, X

	;Use this as index into streams to tell corresponding music channel
	;to silence until the next note.
	LDA streamFlags, Y
	ORA #STREAM_SILENCE_MASK
	STA streamFlags, Y

not_sound_effect:
	;Pop current address off the stack.
	PLA
	PLA
	;Return from parent caller.
	RTS
.ENDPROC