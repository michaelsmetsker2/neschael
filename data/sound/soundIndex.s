;
; neschael
; data/sounds.soundIndex.s
; 
; lookup table for soounds

.EXPORT sound_index_low
.EXPORT sound_index_high

.IMPORT test_song ; 0

sound_index_low:
    .BYTE <test_song
sound_index_high:
    .BYTE >test_song