;
; neschael
; lib/game/entities/entities.s
;
; main subroutines for handling the entity system
;

.INCLUDE "lib/game/entities/entityData.inc"

.IMPORT entityPool
.IMPORT shadowOam

.EXPORT update_entities

  tmpEntityPointer     = $00 ; 16 bit, points to the first byte of the current entities ram

.PROC entities_init
  ; this should just set them all to disabled right?
  ; TODO
  RTS
.ENDPROC

.PROC update_entities
    ; if the update pointer reaches this address, all entities have been looped through 
  poolEndAddress = entityPool + ENTITY_LENGTH * ENTITY_POOL_SIZE

    ; clear non reserved OAM memory
  LDX #$10 ; start at 16, skip reserved OAM ; TODO make a constant
  CLC
  LDY #$FE
:
  TYA
  STA shadowOam, X
  TXA
  ADC #$04
  TAX
  BCC :-

  RTS  

    ; loop through entity pool
  LDX #$00
@entity_loop:

    ; skip if entity is inactive
  LDA entityPool, X
  BPL @increment

  LDY #$00
  LDA (tmpEntityPointer), Y
  BMI @increment_entity

  LDA #>(@increment_entity - 1)
  ;PHA
  LDA #<(@increment_entity - 1)
  ;PHA
;  JMP (tmpFuncPointer) ; this memory block is page aligned so this should never cause issue

    ; increment pointer to the next entity
@increment_entity:
  CLC
  TXA
  ADC #ENTITY_LENGTH
  STA tmpEntityPointer
    ; bbreak if end of the pool
    ; FIXME once the pool size is finalized change this to a BCS
  CMP #ENTITY_POOL_SIZE
  BNE @update_loop

@done:
  RTS
.ENDPROC