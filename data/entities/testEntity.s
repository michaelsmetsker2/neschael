;
; neschael
; data/entities/testEntity.s
;  
; temp test entity definition and implementation for building the entity system
;

.EXPORT test_entity

test_entity:
  .WORD update_func, init_func, remove_func
  .BYTE $04 ; how sprites to allocate in oam for this

  ; these functions need to be passed the memory location of their ram or index of a certain pool
.PROC update_func
  INC $E1 ; FIXME
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  RTS
.ENDPROC

.PROC init_func
  INC $E0 ; FIXME

  RTS
.ENDPROC

.PROC remove_func

  RTS
.ENDPROC

