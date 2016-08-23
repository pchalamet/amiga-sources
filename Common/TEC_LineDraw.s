;		  LINEDRAW ROUTINE FOR USE WITH FILLING:
; Preload:  d0=X1  d1=Y1  d2=X2  d3=Y2  d5=Screenwidth  a0=address  a6=$dff000
; $dff060=Screenwidth (word)  $dff072=-$8000   (longword)  $dff044=-1 (longword)
; d0-d5 trashed

line	cmp.w d1,d3
	bgt.s line1
	beq.s out
	exg d0,d2
	exg d1,d3
line1	move.w d1,d4
	muls d5,d4
	move.w d0,d5
	add.l a0,d4
	asr.w #3,d5
	add.w d5,d4
	moveq #0,d5
	sub.w d1,d3
	sub.w d0,d2
	bpl.s line2
	moveq #1,d5
	neg.w d2
line2	move.w d3,d1
	add.w d1,d1
	cmp.w d2,d1
	dbhi d3,line3
line3	move.w d3,d1
	sub.w d2,d1
	bpl.s line4
	exg d2,d3
line4	addx.w d5,d5
	add.w d2,d2
	move.w d2,d1
	sub.w d3,d2
	addx.w d5,d5
	and.w #15,d0
	ror.w #4,d0
	or.w #$a4a,d0
line5	btst #6,2(a6)
	bne.s line5
	move.w d2,$52(a6)
	sub.w d3,d2
	lsl.w #6,d3
	addq.w #2,d3
	move.w d0,$40(a6)
	move.b oct(PC,d5.w),$43(a6)
	move.l d4,$48(a6)
	move.l d4,$54(a6)
	movem.w d1/d2,$62(a6)
	move.w d3,$58(a6)
out	rts
oct	dc.b 3,3+64,19,19+64,11,11+64,23,23+64
