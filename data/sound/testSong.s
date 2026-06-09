;
; neschael
; data/sounds.testSong.s
; 
; test of audio streams and an audio data format

.EXPORT test_song

test_song:
        ; song header
    .BYTE $01 ; stream count

        ; stream headers
    .BYTE $00 ; stream
    .BYTE $00 ; status flags
    .BYTE $00 ; channel
    .BYTE $00 ; initial volume and duty
    .WORD test_stream ; stream data pointer

test_stream:
    .BYTE $00