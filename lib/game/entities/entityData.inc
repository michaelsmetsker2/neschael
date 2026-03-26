;
; neschael
; lib/game/entities/entityData.inc
;
; constants and macros relating to the entity management system
;

    ; lengths for the entity pool, a section of ram that stores values for active entities
  ENTITY_POOL_SIZE   = $0F            ; amount of entity slots in the pool
  ENTITY_LENGTH      = $07            ; how many bytes of ram per entity
    ; length of the pool in its entirety
  POOL_LENGTH = ENTITY_LENGTH * ENTITY_POOL_SIZE 

  INIT_FUNC_OFFSET   = $02           ; offset to the initialization function from an entities definition
  NUM_SPRITES_OFFSET = $06           ; offset to the sprite ammount

  SPRITE_CAP         = $3C           ; 60 maximum allowed unreserved sprites before they will stop spawning