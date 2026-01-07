.include "registers.inc"

.export LzssDec

.code
.proc LzssDec
	Ptr := $0
	length := $2
	temp := $3
	Buf = $300
	ldx #$00
	.export LzssDecContinue
	LzssDecContinue:
	ldy #$00
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
	lda Buf,y
	sta Buf,x
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
	sta Buf,x
	iny
	bne :+
	inc Ptr+1
	:
	inx
	inc length
	bne @Loop
	jmp Loop
Done:
	tya
	sec
	adc Ptr+0
	sta Ptr+0
	bcc :+
	inc Ptr+1
:
	rts
.endproc
