;
; neschael
; data/entities/entityIndex.s
;  
; lookup table of entities
;

.IMPORT test_entity
.IMPORT glide_flames

.EXPORT entity_index_low
.EXPORT entity_index_high

entity_index_low:
  .BYTE <test_entity, <glide_flames

entity_index_high:
  .BYTE >test_entity, >glide_flames