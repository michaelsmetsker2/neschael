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

.IMPORT level_index_low
.IMPORT level_index_high

.IMPORT draw_first_screen
.IMPORT player_init
.IMPORT entities_init
.IMPORT hud_init

.EXPORT game_init
.EXPORT read_joypad_1
.EXPORT level_init

.PROC game_init

  ; maybe here i set the fixed palletes and only set dynamic ones on level load 
 ; TODO still empty.

  RTS
.ENDPROC

.PROC level_init
    ; disable output as we will be drawing to the ppu
  DisableVideoOutput 

@clear_level_flag:
  LDA #%11101111
  AND gameFlags
  STA gameFlags

  ClearOamMemory ; remove all current sprites
  JSR entities_init
  
  ; set the level pointer to the id of levelID
  LDY levelId
  LDA level_index_low,Y
  STA levelPtr
  LDA level_index_high,Y
  STA levelPtr+1

 LoadPaletteData ; TODO set up palletes for current level?
    ; TODO set music for current level and clear audio streams

@decompress_starting_nametables:
    ; reset scroll variables so the correct backgrounds load
  LDA #$00
  STA nametable
  STA screenPosX+1
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
  JSR hud_init
  JSR player_init

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