;
; neschael
; data/entities/entityIndex.s
;  
; lookup table of entities
;

.IMPORT test_entity

.EXPORT entity_index_low
.EXPORT entity_index_high

entity_index_low:
  .BYTE <test_entity

entity_index_high:
  .BYTE >test_entity