;
; neschael
; lib/game/entities/entities.s
;
; main subroutines for handling the entity system
;

.INCLUDE "lib/game/entities/entityData.inc"
.INCLUDE "lib/game/gamedata.inc"
.INCLUDE "data/system/ppu.inc"

.IMPORTZP SCRATCH
.IMPORT   entityPool
.IMPORT   shadowOam

.IMPORT entity_index_low
.IMPORT entity_index_high

.EXPORT entities_init
.EXPORT update_entities
.EXPORT create_entity


  ; seta all entities to inactive upon level load
.PROC entities_init
 
  LDA #$00
  STA spriteCount

  RTS
  ; FIXME unfinished bad broken  
  LDA #$00
  LDX #$00

  CLC
@loop:
  STA entityPool, X
  CLC
  ADC #ENTITY_LENGTH

  RTS
.ENDPROC

  ; loops through all entity slts and runs the update function on active entities
.PROC update_entities

  tmpEntityMemoryPointer = SCRATCH     ; 16 bit, points to the first byte of the current entities ram

    ; if the update pointer reaches this address, all entities have been looped through 

  UNRESERVED_OAM_OFFSET  = $10 ; offset to skip the reserverd entries in OAM (16, first 4)

  tmpEntityOffset        = SCRATCH + 2 ; loop index/offset of current entity, stored during updates
  tmpFuncPointer         = SCRATCH + 3 ; 16 bit, points to the update function of current entity

    ; clear non reserved OAM memory
  
@clear_oam: ; TODO find a way to only clear the filled stuff
  LDX #UNRESERVED_OAM_OFFSET ; start at unreserved
  LDA #$FE
:
  .REPEAT 2 ; unrolled loop for 92 saved cycles/frame
  STA shadowOam, X
  INX
  INX
  INX
  INX
  .ENDREPEAT
  BNE :-
  
    ; set the high byte of the pointer as it doesn't change
  LDA #>entityPool
  STA tmpEntityMemoryPointer+1

    ; loop through entity pool
  LDX #$00
@entity_loop:

    ; test bit 7 for an active entity
  LDA entityPool, X
  BPL @next_entity  ; bit 7 = 0, skip
@active_entity:
    ; update low byte of memory pointer to the current entity's block
  TXA
  CLC
  ADC #<entityPool
  STA tmpEntityMemoryPointer

    ; find funcion
  TXA
  AND #%01111111 ; mask activity bit to get entity id
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
  JMP (tmpFuncPointer) ; BUG this will misbehave on page boundaries (can always do rts trick)

@ret:
    ; restore index
  LDX tmpEntityOffset
@next_entity: ; FIXME once the size of the pool is finalized, bcs can be used instead of CMP
    ; increment index and loop
  CLC
  TXA
  ADC #ENTITY_LENGTH
  TAX
  CMP #POOL_LENGTH
  BCC @entity_loop
@done:
  RTS
.ENDPROC

  ; this will need to be passed the entity ID and the parameters
.PROC create_entity

  roMetatileIndex       = $01 ; read only, index of the metacolumn index of the entity relative to the background, inhereted from check_entities
  roEntityData          = $04 ; ready only, 16 bit, pointer to the start of the entities rom params, inhereted from check_entities

  tmpSlotPtr            = $06 ; 16 bit, points to the ; TODO
  tmpEntityTypePointer  = $08 ; 16 bit, points to the entity types definition in rom
  tmpInitFuncPtr        = $0A ; 16 bit, points to the init function if the entity to jump to


@find_free_slot:
    ; set the high byte of the pointer as it doesn't change
  LDA #>entityPool
  STA tmpSlotPtr+1

    ; loop through the pool to find an inactive slot
  LDX #$00
@pool_loop:
    ; test bit 7 for a free slot
  LDA entityPool, X
  BPL @slot_found  ; bit 7 = 0, empty, slot free
@next_slot:
  TXA
  CLC
  ADC #ENTITY_LENGTH
  TAX
  CMP #POOL_LENGTH
  BCC @pool_loop   ; FIXME see fixme above

  RTS ; no free slots, return early

@slot_found:
    ; update low byte of slot pointer to the current entity's block
  TXA
  CLC
  ADC #<entityPool
  STA tmpSlotPtr

    ; id of the entity
  LDY #$01
  LDA (roEntityData), y
  TAY
  
    ; create pointer to the entity type
  LDA entity_index_low, Y
  STA tmpEntityTypePointer
  LDA entity_index_high, Y
  STA tmpEntityTypePointer+1

@check_sprites:
    ; add the number of sprites to the current ammount
  LDY #NUM_SPRITES_OFFSET
  LDA (tmpEntityTypePointer), Y
  CLC
  ADC spriteCount
  CMP #SPRITE_CAP+1
    ; TODO if needed i can make an optional not spawn fallback subproccess 
  BCS @done       ; sprite cap exceeded, return early
  
    ; update the count
  STA spriteCount

    ; create tmpInitFuncPtr
  LDY #INIT_FUNC_OFFSET
  LDA (tmpEntityTypePointer), Y
  STA tmpInitFuncPtr
  INY
  LDA (tmpEntityTypePointer), Y
  STA tmpInitFuncPtr+1

    ; push return address and run init function
  LDA #>(@ret - 1)
  PHA
  LDA #<(@ret - 1)
  PHA
  JMP (tmpInitFuncPtr) ; BUG this can misbehave on page boundaries
@ret:
  ; fixme this cah be  hardcoded label if i dont need to spawn one entity from another

@done:
  RTS
.ENDPROC