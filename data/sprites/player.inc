;
; neschael
; data/sprites/player.inc
;

    ; Y TILE ATTR X
player_sprite:
.BYTE Player::I_SPRITE_Y, $0, %00000000, Player::I_SPRITE_X

blario_sprite:
; small luigi
.BYTE 28,  $36,  %00000010,  28		; Sprite 0
.BYTE 28,  $37,  %00000010,  36		; Sprite 1
.BYTE 36,  $38,  %00000010,  28		; Sprite 2
.BYTE 36,  $39,  %00000010,  36		; Sprite 3

; End of data/sprites/player.inc