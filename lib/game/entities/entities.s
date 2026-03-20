;
; neschael
; lib/game/entities/entities.s
;
; main subroutines for handling the entity system
;

.INCLUDE "lib/game/entities/entityData.inc"
.INCLUDE "data/system/ppu.inc"

.IMPORT   entityPool
.IMPORTZP SCRATCH
.IMPORT   shadowOam

.IMPORT entity_index_low
.IMPORT entity_index_high

.EXPORT update_entities

  tmpEntityMemoryPointer = SCRATCH     ; 16 bit, points to the first byte of the current entities ram

  ; seta all entities to inactive upon level load
.PROC entities_init


  RTS
  ; FIXME unfinished bad broken  
  LDA #$00
  LDX #$00


  CLC
@loop:
  STA entityPool, X

  ADC #ENTITY_LENGTH


.ENDPROC

  ; loops through all entity slts and runs the update function on active entities
.PROC update_entities
    ; if the update pointer reaches this address, all entities have been looped through 

  tmpEntityOffset        = SCRATCH + 2 ; loop index/offset of current entity, stored during updates
  tmpFuncPointer         = SCRATCH + 3 ; 16 bit, points to the update function of curretn entity

    ; clear non reserved OAM memory
  
@clear_oam:
  LDX #$10 ; start at 16, skip reserved OAM ; TODO make a constant
  CLC
  LDY #$FE
:
  TYA
  STA shadowOam, X
  TXA
  ADC #_OAM_SIZE
  TAX
  BCC :-
  
    ; set the high byte of the pointer as it doesn't change
  LDA #<entityPool
  STA tmpEntityMemoryPointer+1

    ; loop through entity pool
  LDX #$00
@entity_loop:

    ; test bit 7 for an active entity
  LDA entityPool, X
  BPL @next_entity  ; bit 7 = 0, skip
@active_entity:
    ; update low byte of memory pointer to the current entity's block
  CLC
  TXA
  ADC #<entityPool
  STA tmpEntityMemoryPointer

    ; find funcion
  TXA
  AND #%01111111
  TAY
  LDA entity_index_low, Y
  STA tmpFuncPointer
  LDA entity_index_high, Y
  STA tmpFuncPointer+1

    ; store x
  STX tmpEntityOffset

    ; run function and set return point
  LDA #>(@ret - 1)
  PHA
  LDA #<(@ret - 1)
  PHA
  JMP (tmpFuncPointer) ; BUG this will misbehave on page boundaries

@ret:
    ; restore index
  LDX tmpEntityOffset
@next_entity: ; FIXME once the size of the pool is finalized, bcs can be used instead of CMP
    ; increment index and loop
  TXA
  ADC #ENTITY_LENGTH
  TAX
  CMP #POOL_LENGTH
  BCC @entity_loop    
@done:
  RTS
.ENDPROC