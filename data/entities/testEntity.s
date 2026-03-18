;
; neschael
; data/entities/testEntity.s
;  
; temp test entity definition and implementation for building the entity system
;


.EXPORT test_entity

test_entity:
  .BYTE #$00 ; how sprites to allocate in oam for this
  .WORD init_func, update_func, remove_func

  ; these functions need to be passed the memory location of their ram or index of a certain pool
.PROC init_func

  RTS
.ENDPROC

.PROC update_func
  
  RTS
.ENDPROC

.PROC remove_func

  RTS
.ENDPROC

