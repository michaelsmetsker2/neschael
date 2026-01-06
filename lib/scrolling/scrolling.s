;   
; nechael
; lib/scrolling.s
;
; subroutines related to SCROLLING_BUFF, when scrolling thresholds are reached, it will uncompress
; and store level data while the PPU is writing. This takes leaves less logic for NMI
;

.SEGMENT "CODE"

.INCLUDE "data/system/ppu.inc"

.INCLUDE "lib/game/gameData.inc"
.INCLUDE "lib/scrolling/scrolling.inc"

.IMPORT fill_scroll_buffer

.EXPORT scroll_screen
.EXPORT draw_first_screen

; === unsafe memory constants ===

  tmpOldScrollPos        = $15 ; 16 bit, previous scroll position

; apply the scrollAmount, swap nametables and fill the scroll buffer if neccessary
.PROC scroll_screen

  LDA scrollAmount
  BEQ @done            ; return early if no scroll is needed 

    ;store the previous scroll position
  LDA screenPosX
  STA tmpOldScrollPos
  LDA screenPosX+1
  STA tmpOldScrollPos+1

@update_scroll_position:
  
  LDA screenPosX
  CLC
  ADC scrollAmount     ; add low byte
  STA screenPosX
  LDA screenPosX+1
  
  BIT scrollAmount     ; check sign of scrollAmount
  BPL @positive
@negative:
  
  ADC #$FF             ; extend sign
  STA screenPosX+1

  JMP @check_nametable_boundary
@positive:

  ADC #$00             ; add carry
  STA screenPosX+1

@check_nametable_boundary:
  CMP tmpOldScrollPos+1
  BEQ @check_metatile_boundary ; branch if we havn't scrolled onto a new nametable

  LDA nametable
  EOR #$01                ; flip nametable
  STA nametable  

@check_metatile_boundary: ; see if we crossed into a new metatile so we must draw more
  LDA tmpOldScrollPos
  EOR screenPosX
  AND #%11110000
  CMP #$00
  BEQ @reset_scroll_amount  ; if we're on the same metatile, don't draw

  JSR fill_scroll_buffer
@reset_scroll_amount:
  LDA #$00
  STA scrollAmount
@done:
  RTS
.ENDPROC

; fully draws the first screen upon loading a level
.PROC draw_first_screen
  LDA #$01          ; flip nametable so we start drawing on first screen
  STA nametable

  LDA #$FF          ; set the screen one background back and scroll right
  STA screenPosX+1
  LDA #$00          
  STA screenPosX
  STA $00           ; loop counter

@draw_loop:
  JSR fill_scroll_buffer ; fill and draw from buffer
  DrawOffscreenTiles
  DrawOffscreenAttributes

  CLC
  LDA #$10
  ADC screenPosX      ; increment screen position by one metatile
  STA screenPosX
  LDA #$00
  ADC screenPosX+1
  STA screenPosX+1

  INC $00
  LDA $00
  CMP #$10            ; 16 columns per screen
  BNE @draw_loop      ; loop through screen

    ; reset nametable
  LDA #$00
  STA nametable
    ; fill the buffer once more so the first col of nametable 1 is filled
  JSR fill_scroll_buffer

  RTS
.ENDPROC