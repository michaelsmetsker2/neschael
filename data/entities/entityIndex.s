;
; neschael
; data/entities/entityIndex.s
;  
; lookup table of entities
;

.IMPORT test_entity
.IMPORT glide_flames
.IMPORT bomb_entity

.EXPORT entity_index_low
.EXPORT entity_index_high

entity_index_low:
  .BYTE <test_entity, <glide_flames, <bomb_entity

entity_index_high:
  .BYTE >test_entity, >glide_flames, >bomb_entity