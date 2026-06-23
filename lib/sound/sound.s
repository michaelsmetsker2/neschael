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
.IMPORTZP AUDIO_DATA
.IMPORTZP audioStreamTempo
.IMPORTZP audioStreamTicker
.IMPORTZP audioStreamSoundId
.IMPORTZP audioStreamStatus
.IMPORTZP audioStreamChannel
.IMPORTZP audioStreamVolume
.IMPORTZP audioStreamAddrHigh
.IMPORTZP audioStreamAddrLow
.IMPORTZP audioStreamNoteLow
.IMPORTZP audioStreamNoteHigh
.IMPORTZP audioStreamNoteTimer
.IMPORTZP audioStreamNoteDuration

.IMPORTZP shadowApuPorts

  ; period table
.IMPORT periodTableLo
.IMPORT periodTableHi

  ; sound index lookup tables
.IMPORT sound_index_high
.IMPORT sound_index_low

.EXPORT audio_init
.EXPORT stop_sound
.EXPORT load_sound
.EXPORT play_sound_frame

  ; initializes the sound engine
.PROC audio_init

  LDA #%01000000
  STA _FR_COUNTER       ; Disable APU frame IRQ
  STA _DMC_FREQ         ; Disable digital sound IRQs

    ; enable sound channels
  EnableAudioOutput
  
    ; initialize shadowAPU
  LDA #$30 ; all zero exept for length counter halt
  STA shadowApuPorts     ; square 1 volume to 0
  STA shadowApuPorts+4   ; square 2 volume
  STA shadowApuPorts+12  ; Noise volume
  LDA #%10000000
  STA shadowApuPorts+8   ; triangle volume

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

  ; pauses all sound ; TODO update?
.PROC stop_sound
    ; disable all channels
  DisableAudioOutput
    ; clear audioFlag
  LDA gameFlags
  AND #%11011111
  STA gameFlags
  RTS
.ENDPROC

  ; load a sound (song or sfx) into the sound engine by parsing the header
    ; input:
    ;   acc: ID of the sound in the sound index
.PROC load_sound

  ; TODO add to seperate audio scratch? (or do stuff on the stack)
  soundPointer   = SCRATCH   ; pointer to sound to parse
  channelCounter = SCRATCH+2 ; loop index for parsing channels  
  soundId        = SCRATCH+3 ; id of the sound being loaded

  STA soundId ; store fore later
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

  ; read stream headers byte by byte
@stream_loop:

    ; find the stream id, used to place header data at the correct offset
  INY
  LDA (soundPointer), Y
  TAX

    ; set note duration to 1 so notes will play on the first tick
  LDA #$01
  STA audioStreamNoteTimer, X
  STA audioStreamNoteDuration, X

    ; set ticker so a tick will happen next frame
  LDA #$FF
  STA audioStreamTicker, X

  INY
  LDA (soundPointer), Y ; status byte 
  STA audioStreamStatus, X

  INY
  LDA (soundPointer), Y ; channel byte
  STA audioStreamChannel, X

  INY
  LDA (soundPointer), Y ; byte containing volume and duty
  STA audioStreamVolume, X

  INY
  LDA (soundPointer), Y ; initial tempo
  STA audioStreamTempo, X

  INY
  LDA (soundPointer), Y ; location of the stream's data
  STA audioStreamAddrLow, X

  INY
  LDA (soundPointer), Y
  STA audioStreamAddrHigh, X

  LDA soundId ; store song id as well
  STA audioStreamSoundId

    ; decrement counter and conditionaly loop
  DEC channelCounter
  BNE @stream_loop

  RTS
.ENDPROC

.PROC play_sound_frame
    ; don'y play a frame if audio is disabled
  LDA gameFlags
  AND #%00100000
  BEQ @done

  ; TODO silence all channles? (turns off inactive ones?)

  LDX #$00       ; loop index
@loop:           ; update all audio streams

    ; skip stream if it's disabled flag is set
  LDA audioStreamStatus
  AND #$01       ; mask enabled flag ; TODO formalize
  BEQ @next

    ; add tempo to ticker
  LDA audioStreamTicker, X
  CLC
  ADC audioStreamTempo, X  
  STA audioStreamTicker, X
  BCC @next      ; skip if ticker didnt overflow

    ; check if the current note has finished playing
  DEC audioStreamNoteTimer, X
  BNE @buffer

@note_finished:
    ; reset the note's timer
  LDA audioStreamNoteDuration, X
  STA audioStreamNoteTimer, X

  JSR read_stream ; proccess next byte(s) from the stream

@buffer:
  JSR buffer_stream_data

@next:
  INX
  CPX #NUM_STREAMS
  BNE @loop

  JMP set_apu_ports ; sends buffered data to apu ports

@done:
  RTS
.ENDPROC

  ; read and proccess data from an audio stream
    ; input:
    ;     X: stream number
.PROC read_stream

  streamPtr = SCRATCH
  tmpStorage = SCRATCH+2 ; used to keep registers from being clobbered

    ; set stream pointer to the correct address
  LDA audioStreamAddrLow, X
  STA streamPtr
  LDA audioStreamAddrHigh, X
  STA streamPtr+1
  
    ; read byte from the stream
  LDY #$00
@read:
  LDA (streamPtr), Y


  BPL @note ; byte is a note if <#$80

  CMP #OPCODE_THRESHOLD ; test if the byte is an opcode or a note length 
  BCC @length

@opcode:
  ; TODO
  JMP @increment_pointer

@length: ; the byte denotes how long to hold the next note(s)
  
    ; mask bit 7 to get raw note duration
  AND #%01111111
  STA audioStreamNoteDuration, Y  
    
    ; read the next byte as well
  INY
  JMP @read

@note:

  STY tmpStorage ; preserve advancement amount

  TAY

  LDA periodTableLo, Y
  STA audioStreamNoteLow, X
  LDA periodTableHi, Y
  STA audioStreamNoteHigh, X

  LDY tmpStorage ; restore Y


  ; TODO check if note is a rest?


  ; fallthrough to update_pointers

@increment_pointer:
    ; add the ammount of bytes we read to the pointer
  INY
  TYA
  CLC
  ADC audioStreamAddrLow, X
  STA audioStreamAddrLow, X
  BCC :+
  INC audioStreamAddrHigh, X
:

  RTS
.ENDPROC

  ; buffers stream data in shadowApuPorts
    ; INPUT: X: stream number 
.PROC buffer_stream_data
  
    ; find the offset of the correct channels data in the shadowApuPorts,
  LDA audioStreamChannel, X
  ASL
  ASL         ; *4 as 4 bytes per channel
  TAY

    ; volume and duty
  LDA audioStreamVolume, X
  STA shadowApuPorts, Y

    ; sweep
  LDA #$08 ; FIXME temp sweep
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