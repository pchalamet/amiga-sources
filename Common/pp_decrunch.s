
;	lea yo_end,a0
;	lea yo_buffer,a1
;	lea yo_start,a2
;	jsr Decrunch_pp
;	rts
;
;yo_start
;	incbin "ram:toto.pp"
;yo_end
;yo_buffer
;	ds.b 5000


**************************************************************

;
; PowerPacker Decrunch assembler subroutine V2.6
; New version by Sync/Dreamdealers
; Made case dependent & relative PC
;
; This optimized version depack 3-5 times faster than the original
; version by Nico francois but is 1890 bytes long instead of 500.
;
; a0  : just after last byte of crunched file
; a1  : to memory block to decrunch in
; a2  : start of crunched file
; sp  : must have enough space for 256 bytes
;
; NOTE:
;    Decrunch a few bytes higher (safety margin) than the crunched file
;    to decrunch in the same memory space. (64 bytes suffice)
;

Decrunch_pp
	lea $00040206,a3		;construction de Table3
	lea $01050307,a4		;pointée par sp
	moveq #32-1,d0
build_Table3
	movem.l a3-a4,-(sp)
	dbf d0,build_Table3

	move.l	4(a2),d0		;efficiency
	moveq	#0,d6
	moveq	#1,d4
	moveq	#23,d3
	lea	3.w,a3
	lea	MyBitsTable1(pc),a2
	move.l	d0,(a2)
	subq.b	#1,(a2)
	subq.b	#1,1(a2)
	subq.b	#1,2(a2)
	subq.b	#1,3(a2)
	move.l	(a2),MyBitsTable2-MyBitsTable1(a2)
	lea	Table1(pc),a4
	lea	Table2(pc),a5	
	move.l	a1,a2
	move.l	-(a0),d5
	moveq	#0,d1
	move.b	d5,d1
	lsr.l	#8,d5			;taille du fichier decompacte
	add.l	d5,a1
	move.l	-(a0),d5
	lsr.l	d1,d5
	moveq	#31,d7
	sub.w	d1,d7

Loop	lsr.l	#1,d5			;boucle principale
	bcs	Crunb2
	dbf	d7,N32
	moveq	#31,d7
	move.l	-(a0),d5

N32	subq.w	#2,d7
	bmi.s	infeq3
	move.w	d5,d2
	and.w	d4,d2
	lsr.l	#2,d5
	addx.w	d2,d2
	cmp.w	a3,d2
	bne.s	Rnb_h3

	subq.w	#2,d7
	bmi	infeq5
	move.b	d5,d6
	and.w	d4,d6
	lsr.l	#2,d5
	addx.w	d6,d6
	add.w	d6,d2
	subq.b	#3,d6
	beq	R2BR

Rnb_h4	subq.w	#7,d7			;4
	bmi	dblsym_h2		;8,10
	move.b	d5,d6			;4
	move.b	(a4,d6.w),-(a1)		;18
	lsr.l	#8,d5			;24
	dbf	d7,niet			;10,14
	moveq	#31,d7			;4
	move.l	-(a0),d5		;12
	dbf	d2,Rnb
	cmp.l	a1,a2
	bcs	CrunchedBytes
	lea	256(sp),sp
	rts

Tbl4	dc.b	0,2,1,3
infeq3	addq.w	#1,d7
	beq.s	eql11
	move.w	d5,d2
	move.l	-(a0),d5
	lsr.l	#1,d5
	addx.w	d2,d2
	moveq	#30,d7
	cmp.w	a3,d2
	bne.s	Rnb_h2
	
	subq.w	#2,d7
	bmi	infeq5
	move.b	d5,d6
	and.w	d4,d6
	lsr.l	#2,d5
	addx.w	d6,d6
	add.w	d6,d2
	subq.b	#3,d6
	beq.s	R2BR

Rnb_h3	subq.w	#7,d7			;4
	bmi.s	dblsym_h2		;8,10
	move.b	d5,d6			;4
	move.b	(a4,d6.w),-(a1)		;18
	lsr.l	#8,d5			;24
	dbf	d7,niet			;10,14
	moveq	#31,d7			;4
	move.l	-(a0),d5		;12
	dbf	d2,Rnb
	cmp.l	a1,a2
	bcs	CrunchedBytes
	lea	256(sp),sp
	rts

eql11	clr.w	d2
	move.b	Tbl4(pc,d5.w),d2
	moveq	#31,d7
	move.l	-(a0),d5
	cmp.w	a3,d2
	bne.s	Rnb_h

R2BR	subq.w	#2,d7
	bmi.s	infeq5
	move.b	d5,d6
	and.w	d4,d6
	lsr.l	#2,d5
	addx.w	d6,d6
	add.w	d6,d2
	subq.b	#3,d6
	beq.s	R2BR

Rnb_h2	subq.w	#7,d7			;4
	bmi.s	dblsym_h2		;8,10
	move.b	d5,d6			;4
	move.b	(a4,d6.w),-(a1)		;18
	lsr.l	#8,d5			;24
	dbf	d7,niet			;10,14
	moveq	#31,d7			;4
	move.l	-(a0),d5		;12
	dbf	d2,Rnb
	cmp.l	a1,a2
	bcs	CrunchedBytes
	lea	256(sp),sp
	rts
dblsym_h2
	move.b	(a4,d5.w),d1		;14
	move.l	-(a0),d5		;12
	move.b	d5,d6			;4
	neg.w	d7			;4
	lsr.l	d7,d5			;8+2p  p<8  p=8-n
	neg.w	d7			;4
	addq	#8,d7			;4
	lsl.b	d7,d6			;6+2n  n<8
	or.b	(a4,d6.w),d1		;14
	add.w	d3,d7			;4
	move.b	d1,-(a1)		;8
	dbf	d2,Rnb
	cmp.l	a1,a2
	bcs	CrunchedBytes
	lea	256(sp),sp
	rts

Tbl6	dc.b	0,2,1,3
infeq5	addq.w	#1,d7
	beq.s	sam
	move.b	d5,d6
	move.l	-(a0),d5
	lsr.l	#1,d5
	addx.w	d6,d6
	moveq	#30,d7
	add.w	d6,d2
	subq.b	#3,d6
	beq.s	R2BR

Rnb_h	subq.w	#7,d7			;4
	bmi.s	dblsym			;8,10
	move.b	d5,d6			;4
	move.b	(a4,d6.w),-(a1)		;18
	lsr.l	#8,d5			;24
	dbf	d7,niet			;10,14
	moveq	#31,d7			;4
	move.l	-(a0),d5		;12
	dbf	d2,Rnb
	cmp.l	a1,a2
	bcs	CrunchedBytes
	lea	256(sp),sp
	rts

sam	move.b	Tbl6(pc,d5.w),d6
	moveq	#31,d7
	move.l	-(a0),d5
	add.w	d6,d2
	subq.b	#3,d6
	beq	R2BR	

Rnb	subq.w	#7,d7			;4
	bmi.s	dblsym			;8,10
	move.b	d5,d6			;4
	move.b	(a4,d6.w),-(a1)		;18
	lsr.l	#8,d5			;24
	dbf	d7,niet			;10,14
	moveq	#31,d7			;4
	move.l	-(a0),d5		;12
niet	dbf	d2,Rnb
	cmp.l	a1,a2
	bcs	CrunchedBytes
	lea	256(sp),sp
	rts
	
dblsym	move.b	(a4,d5.w),d1		;14
	move.l	-(a0),d5		;12
	move.b	d5,d6			;4
	neg.w	d7			;4
	lsr.l	d7,d5			;8+2p  p<8  p=8-n
	neg.w	d7			;4
	addq	#8,d7			;4
	lsl.b	d7,d6			;6+2n  n<8
	or.b	(a4,d6.w),d1		;14
	add.w	d3,d7			;4
	move.b	d1,-(a1)		;8
	dbf	d2,Rnb
	cmp.l	a1,a2
	bcs	CrunchedBytes
	lea	256(sp),sp
	rts

MyBitsTable2
	dc.b	$09,$0a,$0b,$0b

ReadOffset
	moveq	#0,d0
	move.b	MyBitsTable2(pc,d2.w),d0
	subq.w	#7,d0
	bmi.s	perte
	subq.w	#7,d7			;4
	bmi.s	dblsyR			;8,10
	move.b	d5,d6			;4
	move.b	(a4,d6.w),d1		;18
	lsr.l	#8,d5			;24
	dbf	d7,N32fin		;10,14
	moveq	#31,d7			;4
	move.l	-(a0),d5		;12
	dbf	d0,RdBfin
	move.b	(a1,d1.w),-(a1)
	move.b	(a1,d1.w),-(a1)
	dbf	d2,DecrB
	cmp.l	a1,a2
	bcs	Loop
	lea	256(sp),sp
	rts

dblsyR	move.b	(a4,d5.w),d1		;14
	move.l	-(a0),d5		;12
	move.b	d5,d6			;4
	neg.w	d7			;4
	lsr.l	d7,d5			;8+2p  p<8  p=8-n
	neg.w	d7			;4
	addq.w	#8,d7			;4
	lsl.b	d7,d6			;6+2n  n<8
	or.b	(a4,d6.w),d1		;14
	add.w	d3,d7			;4
	dbf	d0,RdBfin
	move.b	(a1,d1.w),-(a1)
	move.b	(a1,d1.w),-(a1)
	dbf	d2,DecrB
	cmp.l	a1,a2
	bcs	Loop
	lea	256(sp),sp
	rts
perte	addq.w	#7,d0
RdBfin	lsr.l	#1,d5
	addx.w	d1,d1
	dbf	d7,N32fin
	moveq	#31,d7
	move.l	-(a0),d5
N32fin	dbf	d0,RdBfin
	move.b	(a1,d1.w),-(a1)
DecrB	move.b	(a1,d1.w),-(a1)
	dbf	d2,DecrB
	cmp.l	a1,a2
	bcs	Loop
	lea	256(sp),sp
	rts

Crunb2	dbf	d7,CrunchedBytes
	moveq	#31,d7
	move.l	-(a0),d5

CrunchedBytes
	moveq	#0,d1
	subq.w	#2,d7		 	;4
	bmi.s	infeq4		 	;8,10
	move.w	d5,d2		 	;4
	and.w	d4,d2		 	;4
	lsr.l	#2,d5		 	;12
	addx.w	d2,d2		 	;4
	cmp.w	a3,d2
	bne	ReadOffset
	lsr.l	#1,d5
	bcs	LongBlockOffset
	dbf	d7,Bk2
	moveq	#31,d7
	move.l	-(a0),d5
	bra.s	Bk2

Tbl5	dc.b	0,2,1,3
infeq4	addq.w	#1,d7		 	;4
	beq.s	eql12		 	;8,10
	move.w	d5,d2		 	;4
	move.l	-(a0),d5	 	;12
	lsr.l	#1,d5		 	;10
	addx.w	d2,d2		 	;4
	moveq	#30,d7		 	;4
	cmp.w	a3,d2
	bne	ReadOffset
	lsr.l	#1,d5
	bcs	LongBlockOffset
	dbf	d7,Bk2
	moveq	#31,d7
	move.l	-(a0),d5

	subq.w	#6,d7			;4
	bmi.s	dblsym2			;8,10
	move.b	d5,d6			;4
	move.b	(a5,d6.w),d1		;14
	lsr.l	#7,d5			;22
	dbf	d7,niet6
	moveq	#31,d7
	move.l	-(a0),d5
	bra.s	niet6

eql12	clr.w	d2		 	;4
	move.b	Tbl5(pc,d5.w),d2 	;14
	moveq	#31,d7		 	;4
	move.l	-(a0),d5	 	;12
	cmp.w	a3,d2
	bne	ReadOffset
	lsr.l	#1,d5
	bcs	LongBlockOffset
	dbf	d7,Bk2
	moveq	#31,d7
	move.l	-(a0),d5

Bk2	subq.w	#6,d7			;4
	bmi.s	dblsym2			;8,10
sym2	move.b	d5,d6			;4
	move.b	(a5,d6.w),d1		;14
	lsr.l	#7,d5			;22
	dbf	d7,niet6
	moveq	#31,d7
	move.l	-(a0),d5
niet6	
	lea	1(a1,d1.w),a6
	subq.w	#3,d7
	bmi.s	cas2_h
	move.b	d5,d6
	move.b	(sp,d6.w),d6
	lsr.l	#3,d5
	add.w	d6,d2
	subq.b	#7,d6
	beq.s	Bk_h	
	move.b	-(a6),-(a1)
	move.b	-(a6),-(a1)
	dbf	d2,Dcb_h
	cmp.l	a1,a2
	bcs	Loop
	bra	gainplace2
dblsym2
	move.b	(a5,d5.w),d1		;14
	move.l	-(a0),d5		;12
	move.b	d5,d6			;4
	neg.w	d7			;4
	lsr.l	d7,d5			;8+2p  p<7  p=7-n
	neg.w	d7			;4
	addq.w	#7,d7			;4
	lsl.b	d7,d6			;6+2n  n<7
	or.b	(a5,d6.w),d1		;14
	addi.w	#24,d7			;8
	
Bki_h	lea	1(a1,d1.w),a6
Bk_h	subq.w	#3,d7
	bmi.s	cas2_h
	move.b	d5,d6
	move.b	(sp,d6.w),d6
	lsr.l	#3,d5
	add.w	d6,d2
	subq.b	#7,d6
	beq.s	Bk_h	
	move.b	-(a6),-(a1)
Dcb_h	move.b	-(a6),-(a1)
	dbf	d2,Dcb_h
	cmp.l	a1,a2
	bcs	Loop
	bra.s	gainplace2

Tblu	dc.b	0,2,1,3
cas2_h	addq.w	#2,d7
	bmi.s	cas0_h
	bgt.s	caseq_h
	move.b	Tblu(pc,d5.w),d6
	move.l	-(a0),d5
	moveq	#30,d7
	lsr.l	#1,d5
	addx.w	d6,d6
	add.w	d6,d2
	subq.b	#7,d6
	beq.s	Bk_h
	move.b	-(a6),-(a1)
	move.b	-(a6),-(a1)
	dbf	d2,Dcb_h
	cmp.l	a1,a2
	bcs	Loop
	bra.s	gainplace2
cas0_h	move.b	d5,d6
	move.l	-(a0),d5
	lsr.l	#1,d5
	addx.w	d6,d6
	lsr.l	#1,d5
	addx.w	d6,d6
	moveq	#29,d7
	add.w	d6,d2
	subq.b	#7,d6
	beq.s	Bk_h
	move.b	-(a6),-(a1)
	move.b	-(a6),-(a1)
	dbf	d2,Dcb_h
	cmp.l	a1,a2
	bcs	Loop
	bra.s	gainplace2
caseq_h	move.b	(sp,d5.w),d6
	move.l	-(a0),d5
	moveq	#31,d7
	add.w	d6,d2
	subq.b	#7,d6
	beq.s	Bk_h
	move.b	-(a6),-(a1)
	move.b	-(a6),-(a1)
	dbf	d2,Dcb_h
	cmp.l	a1,a2
	bcs	Loop
gainplace2
	lea	256(sp),sp
	rts
perte2	addq	#7,d0
	bra	Rrr3

MyBitsTable1
	dc.b	$09,$0a,$0b,$0b

LongBlockOffset
	moveq	#0,d0
	move.b	MyBitsTable1(pc,d2.w),d0
	dbf	d7,NGH
	moveq	#31,d7
	move.l	-(a0),d5

NGH	subq.w	#7,d0
	bmi.s	perte2
	subq.w	#7,d7			;4
	bmi.s	dblsyZ			;8,10
	move.b	d5,d6			;4
	move.b	(a4,d6.w),d1		;18
	lsr.l	#8,d5			;24
	dbf	d7,Nk7			;10,14
	moveq	#31,d7			;4
	move.l	-(a0),d5		;12

	dbf	d0,Rrr3
	lea	1(a1,d1.w),a6
	subq.w	#3,d7
	bmi	cas2
	move.b	d5,d6
	move.b	(sp,d6.w),d6
	lsr.l	#3,d5
	add.w	d6,d2
	subq.b	#7,d6
	beq.s	Bk	
	move.b	-(a6),-(a1)
	move.b	-(a6),-(a1)
	dbf	d2,Dcb
	cmp.l	a1,a2
	bcs	Loop
	bra	gainplace

dblsyZ	move.b	(a4,d5.w),d1		;14
	move.l	-(a0),d5		;12
	move.b	d5,d6			;4
	neg.w	d7			;4
	lsr.l	d7,d5			;8+2p  p<8  p=8-n
	neg.w	d7			;4
	addq.w	#8,d7			;4
	lsl.b	d7,d6			;6+2n  n<8
	or.b	(a4,d6.w),d1		;14
	add.w	d3,d7			;4

	dbf	d0,Rrr3
	lea	1(a1,d1.w),a6
	subq.w	#3,d7
	bmi.s	cas2
	move.b	d5,d6
	move.b	(sp,d6.w),d6
	lsr.l	#3,d5
	add.w	d6,d2
	subq.b	#7,d6
	beq.s	Bk	
	move.b	-(a6),-(a1)
	move.b	-(a6),-(a1)
	dbf	d2,Dcb
	cmp.l	a1,a2
	bcs	Loop
	bra	gainplace

Rrr3	lsr.l	#1,d5
	addx.w	d1,d1
	dbf	d7,Nk7
	moveq	#31,d7
	move.l	-(a0),d5
Nk7	dbf	d0,Rrr3

Bki	lea	1(a1,d1.w),a6
Bk	subq.w	#3,d7
	bmi.s	cas2
	move.b	d5,d6
	move.b	(sp,d6.w),d6
	lsr.l	#3,d5
	add.w	d6,d2
	subq.b	#7,d6
	beq.s	Bk	
	move.b	-(a6),-(a1)
Dcb	move.b	-(a6),-(a1)
	dbf	d2,Dcb
	cmp.l	a1,a2
	bcs	Loop
	bra.s	gainplace

Tbl2	dc.b	0,2,1,3
cas2	addq.w	#2,d7
	bmi.s	cas0
	bgt.s	caseq
	move.b	Tbl2(pc,d5.w),d6
	move.l	-(a0),d5
	moveq	#30,d7
	lsr.l	#1,d5
	addx.w	d6,d6
	add.w	d6,d2
	subq.b	#7,d6
	beq.s	Bk
	move.b	-(a6),-(a1)
	move.b	-(a6),-(a1)
	dbf	d2,Dcb
	cmp.l	a1,a2
	bcs	Loop
	bra.s	gainplace
cas0	move.b	d5,d6
	move.l	-(a0),d5
	lsr.l	#1,d5
	addx.w	d6,d6
	lsr.l	#1,d5
	addx.w	d6,d6
	moveq	#29,d7
	add.w	d6,d2
	subq.b	#7,d6
	beq.s	Bk
	move.b	-(a6),-(a1)
	move.b	-(a6),-(a1)
	dbf	d2,Dcb
	cmp.l	a1,a2
	bcs	Loop
	bra.s	gainplace
caseq	move.b	(sp,d5.w),d6
	move.l	-(a0),d5
	moveq	#31,d7
	add.w	d6,d2
	subq.b	#7,d6
	beq.s	Bk
	move.b	-(a6),-(a1)
	move.b	-(a6),-(a1)
	dbf	d2,Dcb
	cmp.l	a1,a2
	bcs	Loop
gainplace
	lea	256(sp),sp
	rts

Table1
	dc.b	0,$80,$40,$c0,$20,$a0,$60,$e0
	dc.b	$10,$90,$50,$d0,$30,$b0,$70,$f0
	dc.b	8,$88,$48,$c8,$28,$a8,$68,$e8
	dc.b	$18,$98,$58,$d8,$38,$b8,$78,$f8
	dc.b	4,$84,$44,$c4,$24,$a4,$64,$e4
	dc.b	$14,$94,$54,$d4,$34,$b4,$74,$f4
	dc.b	$c,$8c,$4c,$cc,$2c,$ac,$6c,$ec
	dc.b	$1c,$9c,$5c,$dc,$3c,$bc,$7c,$fc
	dc.b	2,$82,$42,$c2,$22,$a2,$62,$e2
	dc.b	$12,$92,$52,$d2,$32,$b2,$72,$f2
	dc.b	$a,$8a,$4a,$ca,$2a,$aa,$6a,$ea
	dc.b	$1a,$9a,$5a,$da,$3a,$ba,$7a,$fa
	dc.b	6,$86,$46,$c6,$26,$a6,$66,$e6
	dc.b	$16,$96,$56,$d6,$36,$b6,$76,$f6
	dc.b	$e,$8e,$4e,$ce,$2e,$ae,$6e,$ee
	dc.b	$1e,$9e,$5e,$de,$3e,$be,$7e,$fe
	dc.b	1,$81,$41,$c1,$21,$a1,$61,$e1
	dc.b	$11,$91,$51,$d1,$31,$b1,$71,$f1
	dc.b	9,$89,$49,$c9,$29,$a9,$69,$e9
	dc.b	$19,$99,$59,$d9,$39,$b9,$79,$f9
	dc.b	5,$85,$45,$c5,$25,$a5,$65,$e5
	dc.b	$15,$95,$55,$d5,$35,$b5,$75,$f5
	dc.b	$d,$8d,$4d,$cd,$2d,$ad,$6d,$ed
	dc.b	$1d,$9d,$5d,$dd,$3d,$bd,$7d,$fd
	dc.b	3,$83,$43,$c3,$23,$a3,$63,$e3
	dc.b	$13,$93,$53,$d3,$33,$b3,$73,$f3
	dc.b	$b,$8b,$4b,$cb,$2b,$ab,$6b,$eb
	dc.b	$1b,$9b,$5b,$db,$3b,$bb,$7b,$fb
	dc.b	7,$87,$47,$c7,$27,$a7,$67,$e7
	dc.b	$17,$97,$57,$d7,$37,$b7,$77,$f7
	dc.b	$f,$8f,$4f,$cf,$2f,$af,$6f,$ef
	dc.b	$1f,$9f,$5f,$df,$3f,$bf,$7f,$ff

Table2
	dc.b	0,$40,$20,$60,$10,$50,$30,$70
	dc.b	8,$48,$28,$68,$18,$58,$38,$78
	dc.b	4,$44,$24,$64,$14,$54,$34,$74
	dc.b	$c,$4c,$2c,$6c,$1c,$5c,$3c,$7c
	dc.b	2,$42,$22,$62,$12,$52,$32,$72
	dc.b	$a,$4a,$2a,$6a,$1a,$5a,$3a,$7a
	dc.b	6,$46,$26,$66,$16,$56,$36,$76
	dc.b	$e,$4e,$2e,$6e,$1e,$5e,$3e,$7e
	dc.b	1,$41,$21,$61,$11,$51,$31,$71
	dc.b	9,$49,$29,$69,$19,$59,$39,$79
	dc.b	5,$45,$25,$65,$15,$55,$35,$75
	dc.b	$d,$4d,$2d,$6d,$1d,$5d,$3d,$7d
	dc.b	3,$43,$23,$63,$13,$53,$33,$73
	dc.b	$b,$4b,$2b,$6b,$1b,$5b,$3b,$7b
	dc.b	7,$47,$27,$67,$17,$57,$37,$77
	dc.b	$f,$4f,$2f,$6f,$1f,$5f,$3f,$7f
	dc.b	0,$40,$20,$60,$10,$50,$30,$70
	dc.b	8,$48,$28,$68,$18,$58,$38,$78
	dc.b	4,$44,$24,$64,$14,$54,$34,$74
	dc.b	$c,$4c,$2c,$6c,$1c,$5c,$3c,$7c
	dc.b	2,$42,$22,$62,$12,$52,$32,$72
	dc.b	$a,$4a,$2a,$6a,$1a,$5a,$3a,$7a
	dc.b	6,$46,$26,$66,$16,$56,$36,$76
	dc.b	$e,$4e,$2e,$6e,$1e,$5e,$3e,$7e
	dc.b	1,$41,$21,$61,$11,$51,$31,$71
	dc.b	9,$49,$29,$69,$19,$59,$39,$79
	dc.b	5,$45,$25,$65,$15,$55,$35,$75
	dc.b	$d,$4d,$2d,$6d,$1d,$5d,$3d,$7d
	dc.b	3,$43,$23,$63,$13,$53,$33,$73
	dc.b	$b,$4b,$2b,$6b,$1b,$5b,$3b,$7b
	dc.b	7,$47,$27,$67,$17,$57,$37,$77
	dc.b	$f,$4f,$2f,$6f,$1f,$5f,$3f,$7f

**************************************************************

