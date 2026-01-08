.export Lz
.exportzp zLzPtr

.zeropage
zLzPtr: .addr 0
zLzCount: .byte 0
zLzTemp: .byte 0

.bss
bBuf: .res 256

.if 1
.import _putchar

.zeropage
zLzSave: .word 0

.macro putchar
	sty zLzSave+0
	stx zLzSave+1
	jsr _putchar
	ldy zLzSave+0
	ldx zLzSave+1
.endmacro
.else
.macro putchar
	lda a:$0000
.endmacro
.endif

.code
.proc Lz
	Ptr := zLzPtr
	length := zLzCount
	temp := zLzTemp
	ldy #$00
	ldx #$00
Loop:
	lda (Ptr),y
	sta length
	bmi Lit
	beq Done
Ref:
	iny
	bne :+
	inc Ptr+1
	:
	lda (Ptr),y
	sty temp
	tay
@Loop:
	lda bBuf,y
	sta bBuf,x
	putchar
	iny
	inx
	dec length
	bpl @Loop
	ldy temp
	iny
	bne Loop
	inc Ptr+1
	jmp Loop
Lit:
	iny
	bne :+
	inc Ptr+1
	:
@Loop:
	lda (Ptr),y
	sta bBuf,x
	putchar
	iny
	bne :+
	inc Ptr+1
	:
	inx
	inc length
	bne @Loop
	jmp Loop
Done:
	rts
.endproc
