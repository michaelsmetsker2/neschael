;
; neschael
; data/levels/testLevel.s
;
; simple sandbox for testing
;

.EXPORT test_level2 

test_level2:
  .WORD background_index, attribute_index, spawn_stream
  .BYTE $30, $8F ; high byte of starting player x and y
  .BYTE $02      ; length of the level in backgrounds, zero based

background_index:
  .WORD background_00, background_01, background_02
attribute_index:
  .WORD attrib_00, attrib_01, attrib_02
spawn_stream:
  .WORD spawn_stream

background_00:
  .BYTE $FD, $00, $01, $00, $07, $01, $FE, $02, $02, $09, $0B, $04, $01, $05, $0D, $FD 
  .BYTE $02, $02, $03, $0A, $0D, $FE, $00, $00, $04, $0D, $FF, $03, $08, $27, $05, $0D 
  .BYTE $0D, $1A, $26, $0D, $0D, $4E, $FE, $00, $03, $0C, $75, $0B, $0D, $FF, $01, $0E 
  .BYTE $0D, $FF, $01, $09, $0D, $04, $09, $15, $0D, $FF, $01, $05, $01, $00, $00

attrib_00:
  .WORD a_column00_1,a_column00_2,a_column00_3,a_column00_4,a_column00_5,a_column00_6,a_column00_7,a_column00_8

a_column00_1:
  .BYTE $00, $00, $00, $00, $00, $00, $00
a_column00_2:
  .BYTE $00, $00, $00, $00, $00, $00, $00
a_column00_3:
  .BYTE $00, $00, $00, $00, $00, $00, $00
a_column00_4:
  .BYTE $00, $00, $00, $00, $00, $00, $00
a_column00_5:
  .BYTE $00, $00, $00, $00, $00, $00, $00
a_column00_6:
  .BYTE $00, $00, $00, $00, $00, $00, $00
a_column00_7:
  .BYTE $00, $00, $00, $00, $00, $00, $00
a_column00_8:
  .BYTE $00, $00, $00, $00, $00, $00, $00

background_01:
  .BYTE $FD, $00, $01, $00, $07, $01, $FE, $02, $02, $09, $0B, $04, $01, $05, $0D, $FD 
  .BYTE $02, $02, $03, $0A, $0D, $FE, $00, $00, $04, $0D, $FF, $03, $08, $27, $05, $0D 
  .BYTE $0D, $1A, $26, $0D, $0D, $4E, $FE, $00, $03, $0C, $75, $0B, $0D, $FF, $01, $0E 
  .BYTE $0D, $FF, $01, $09, $0D, $04, $09, $15, $0D, $FF, $01, $05, $01, $00, $00

attrib_01:
  .WORD a_column01_1,a_column01_2,a_column01_3,a_column01_4,a_column01_5,a_column01_6,a_column01_7,a_column01_8

a_column01_1:
  .BYTE $00, $00, $00, $00, $00, $00, $00
a_column01_2:
  .BYTE $00, $00, $00, $00, $00, $00, $00
a_column01_3:
  .BYTE $00, $00, $00, $00, $00, $00, $00
a_column01_4:
  .BYTE $00, $00, $00, $00, $00, $00, $00
a_column01_5:
  .BYTE $00, $00, $00, $00, $00, $00, $00
a_column01_6:
  .BYTE $00, $00, $00, $00, $00, $00, $00
a_column01_7:
  .BYTE $00, $00, $00, $00, $00, $00, $00
a_column01_8:
  .BYTE $00, $00, $00, $00, $00, $00, $00

background_02:
  .BYTE $FD, $00, $01, $00, $07, $01, $FE, $02, $02, $09, $0B, $04, $01, $05, $0D, $FD 
  .BYTE $02, $02, $03, $0A, $0D, $FE, $00, $00, $04, $0D, $FF, $03, $08, $27, $05, $0D 
  .BYTE $0D, $1A, $26, $0D, $0D, $4E, $FE, $00, $03, $0C, $75, $0B, $0D, $FF, $01, $0E 
  .BYTE $0D, $FF, $01, $09, $0D, $04, $09, $15, $0D, $FF, $01, $05, $01, $00, $00
attrib_02:

  .WORD a_column02_1,a_column02_2,a_column02_3,a_column02_4,a_column02_5,a_column02_6,a_column02_7,a_column02_8

a_column02_1:
  .BYTE $11, $11, $11, $11, $11, $11, $11
a_column02_2:
  .BYTE $11, $11, $11, $11, $11, $11, $11
a_column02_3:
  .BYTE $11, $11, $00, $00, $00, $00, $00
a_column02_4:
  .BYTE $00, $00, $00, $00, $00, $00, $00
a_column02_5:
  .BYTE $00, $00, $00, $00, $00, $00, $00
a_column02_6:
  .BYTE $00, $00, $00, $00, $00, $00, $00
a_column02_7:
  .BYTE $00, $00, $00, $00, $00, $00, $00
a_column02_8:
  .BYTE $00, $00, $00, $00, $00, $00, $00
