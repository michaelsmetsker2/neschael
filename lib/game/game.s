;
; neschael
; lib/game/game.s
;
; main game loop subroutines
;

.INCLUDE "data/system/cpu.inc"
.INCLUDE "data/system/ppu.inc"
.INCLUDE "lib/game/gameData.inc"

.INCLUDE "data/palettes/palettes.inc" ; TODO temp until i find a better place for this

.IMPORT decompress_nametable

.IMPORT level_index
.IMPORT draw_first_screen
.IMPORT player_init

.EXPORT game_init
.EXPORT read_joypad_1
.EXPORT level_init

.PROC game_init

  LoadPaletteData

  ; levelID is already 0 so no need to set it

  RTS
.ENDPROC

.PROC level_init
  ; disable output since we are drawing to the ppu
    ; should already be disabled on entry
  DisableVideoOutput 

  ClearOamMemory ; remove all current sprites

  ; set the level pointer to the id of levelID
  LDA levelId
  ASL A         ; *2 as 2 bytes for each address
  LDA level_index,Y
  STA levelPtr
  LDA level_index+1,Y
  STA levelPtr+1

    ; TODO set up palletes for current level?
    ; TODO set music for current level and clear audio streams

    ; decompress starting nambetables

  ; decompress second nametable normally
  JSR decompress_nametable
  ; change primary nametable and scroll pos to decompress first nametable
  LDA #$01
  STA nametable
  LDA #$FF
  STA screenPosX+1
  JSR decompress_nametable
  ; reset values
  LDA #$00
  STA nametable
  STA screenPosX+1

  JSR draw_first_screen
  JSR player_init
  

  LDA #$1E
  STA $0200
  LDA #$01
  STA $0201
  STA $0202
  STA $0203

  LDA #%00001000
  STA _PPUCTRL
  LDX #$20
  STX _PPUADDR
  LDA #$40
  STA _PPUADDR

  LDY #$00
@left_loop: ; loop through the whole column
  LDA #$01
  STA _PPUDATA
  INY

  CPY #$40
  BNE @left_loop


  EnableVideoOutput
  RTS

.ENDPROC

.PROC read_joypad_1
    ; read button presses from joypad 1 and find what are new presses
  LDA btnDown
  TAY              ; store previousely held inputs in Y
  LDA #1
  STA _JOYPAD_1    ; latch buttons states
  STA btnDown      ; Clear pressed buttons
  LSR              ; A = 0
  STA _JOYPAD_1    ; release button latch
@loop:             ; Fill BTN_DOWN with all buttons down
  LDA _JOYPAD_1
  LSR
  ROL btnDown
  BCC @loop
  TYA
  EOR btnDown
  and btnDown
  STA btnPressed  ; Fill BTN_PRESSED with only new presses
  RTS
.ENDPROC