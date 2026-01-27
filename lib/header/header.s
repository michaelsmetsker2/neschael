;
; neschael
; data/header/header.inc
;
; INES compatible header for emulators
;

.SEGMENT "HEADER"

.BYTE   "NES", $1a    ; NES followed by MS-DOS end of file
.BYTE   $01           ; 2x 16KB ROM (PRG) ; TODO increase
.BYTE   $01           ; 1x 8KB VROM (CHR)
.BYTE   %00000001     ; Mapper nibble 0000 == No mapping (a simple 16KB PRG + 8KB CHR game)
                      ; Mirroring nibble 0001 == Vertical mirroring only

; the remainder of the header is zero padded to 16 bytes via linker