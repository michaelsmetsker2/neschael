;
; neschael
; lib/game/entities/entityData.inc
;
; constants and macros relating to the entity management system
;

; entity level map 
; Byte 1:
  ; bits 0-3 metaColumn index relative to the screen
  ; bits 4-7 metatile y position 
  ; Byte 2   entity id
  ; Byte 3   params

; Entity Slot Map
; Byte 1:
  ; bit 7 - 0 if inactive 1 if active
  ; bits 1-6 1-128 id in entityIndex of the entities definition
; Byte 2-3 X position in world space
; Byte 4 - Y position in pixels
; Byte 5 params
; Byte 6+ scratch

  SPRITE_CAP         = $3C           ; 60 maximum allowed unreserved sprites before they will stop spawning

    ; lengths for the entity pool, a section of ram that stores values for active entities
  ENTITY_POOL_SIZE   = $0F            ; amount of entity slots in the pool
  ENTITY_LENGTH      = $07            ; how many bytes of ram per entity
    ; length of the pool in its entirety
  POOL_LENGTH = ENTITY_LENGTH * ENTITY_POOL_SIZE 

  INIT_FUNC_OFFSET   = $02           ; offset to the initialization function from an entities definition
  NUM_SPRITES_OFFSET = $06           ; offset to the sprite ammount

.SCOPE Slot
  X_POS_OFFSET = $01
  Y_POS_OFFSET = $03
  PARAM_OFFSET = $04 ; offset for the param byte in the entity slot

.ENDSCOPE

.SCOPE UpdateParams
  slotPtr             = $00          ; 16 bit, points to the first byte of the slot owned by the current entity
  SAFE_SCRATCH        = $05
.ENDSCOPE


.SCOPE InitParams
  metatileIndex       = $01  ; read only, index of the metacolumn index of the entity relative to the background
  entityData          = $04  ; ready only, 16 bit, pointer to the start of the entities rom params

  slotPtr             = $06  ; 16 bit, points to the memory chunk in the entity pool alocated for the entity
  entityId            = $0A  ; ID of the entity

  SAFE_SCRATCH        = $0B  ; scratch memory that is sure not to collide with in use values
.ENDSCOPE