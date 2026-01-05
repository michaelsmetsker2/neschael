;
; nechael
; lib/player/sprite.s
; 
; updates the player's sprites based on its motion state and heading
;

.SEGMENT "CODE"

.INCLUDE "data/system/ppu.inc"
.INCLUDE "lib/player/player.inc"

.EXPORT update_player_sprite

.PROC update_player_sprite
    ;JSR update_motion_state
    ;JSR update_animation_frame
    JSR update_heading
    ;JSR update_sprite_tiles
    JSR update_sprite_position
    RTS
.ENDPROC

.PROC update_heading
    ; heading is already set during x movement
    LDA playerFlags
    AND #%01000000
    STA $0B
    LDA $0200 + _OAM_ATTR
    AND #%10111111
    ORA $0B
    STA $0200 + _OAM_ATTR
.ENDPROC

.PROC update_sprite_position
    ; copies the sprite x and y variables to the players data
    LDA positionX+1
    STA $0200 + _OAM_X
    LDA positionY+1
    STA $0200 + _OAM_Y
    RTS
.ENDPROC
