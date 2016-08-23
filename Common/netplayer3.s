	*****	1 buffer,interleaved,5bpl's	*****
	*****	VBL normale			*****
	incdir	'dh0:.code/.s/'
	include	'3dkub/offsets.s'
	section	RUNTUDJU,code_c
main:

	move.l	$6c.w,old_lv3+2
	lea	list,a0
	move.w	#12,d0
loop	
	move.l	(a0)+,song
	bsr	play
	dbf	d0,loop
	moveq	#0,d0
	rts	
play
	movem.l	d0-d7/a0-a6,-(a7)
	moveq	#0,d0
	move.l	song,a0
	jsr	00(a0)
	move.l	#lv3,$6c.w
	wraster
Mouse	
	btst	#8,$dff016
	bne.s	Mouse
	wraster
Mouse2	
	btst	#8,$dff016
	beq.s	Mouse2
	wraster
Mouse3	
	btst	#8,$dff016
	bne.s	Mouse3
	wraster

	move.l	old_lv3+2,$6c.w
	move.l	song,a0
	jsr	08(a0)
	movem.l	(a7)+,d0-d7/a0-a6
	rts
	

lv3	movem.l	d0-d7/a0-a6,-(a7)
	move.w	$dff01e,d0
	btst	#5,d0
	beq.s	go
	move.l	song,a0
	jsr	04(a0)
go	movem.l	(a7)+,d0-d7/a0-a6
old_lv3	jmp	00
list	dc.l	s10,s11,s12,s13,s14,s15,s16,s17,s18,s19
	dc.l	s20,s21,s22
song	dc.l	0
s10	incbin	'divers/mus12'
s11	incbin	'divers/mus11'
s12	incbin	'divers/mus10'
s13	incbin	'divers/mus9'
s14	incbin	'divers/mus8'
s15	incbin	'divers/mus7'
s16	incbin	'divers/mus6'
s17	incbin	'divers/mus5'
s18	incbin	'divers/mus4'
s19	incbin	'divers/mus3'
s20	incbin	'divers/mus2'
s21	incbin	'divers/mus1'
s22	incbin	'divers/robocop_title'
