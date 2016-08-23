;-------------- noisetracker replay routine v2.0 ------------------

;нннннннннннннннннннннннннннннннннннннннн
;н     NoisetrackerV2.0 FASTreplay      н
;н  Uses lev6irq - takes 8 rasterlines  н
;н Do not disable Master irq in $dff09a н
;н Used registers: d0-d3/a0-a7|	=INTENA н
;н  Mahoney & Kaktus - (C) E.A.S. 1990  н
;нннннннннннннннннннннннннннннннннннннннн

mt_init:
	lea	mt_data,a0
	lea	mt_mulu(pc),a1
	move.l	#mt_data+$c,d0
	moveq	#$1f,d1
	moveq	#$1e,d3
mt_lop4:
	move.l	d0,(a1)+
	add.l	d3,d0
	dbf	d1,mt_lop4

	lea	$3b8(a0),a1
	moveq	#$7f,d0
	moveq	#0,d1
	moveq	#0,d2
mt_lop2:
	move.b	(a1)+,d1
	cmp.b	d2,d1
	ble.s	mt_lop
	move.l	d1,d2
mt_lop:	
	dbf	d0,mt_lop2
	addq.w	#1,d2

	asl.l	#8,d2
	asl.l	#2,d2
	lea	4(a1,d2.l),a2
	lea	mt_samplestarts(pc),a1
	add.w	#$2a,a0
	moveq	#$1e,d0
mt_lop3:clr.l	(a2)
	move.l	a2,(a1)+
	moveq	#0,d1
	move.b	d1,2(a0)
	move.w	(a0),d1
	asl.l	#1,d1
	add.l	d1,a2
	add.l	d3,a0
	dbf	d0,mt_lop3

	move.l	$78.w,mt_oldirq-mt_samplestarts-$7c(a1)
	or.b	#2,$bfe001
	move.b	#6,mt_speed-mt_samplestarts-$7c(a1)
	moveq	#0,d0
	lea	$dff000,a0
	move.w	d0,$a8(a0)
	move.w	d0,$b8(a0)
	move.w	d0,$c8(a0)
	move.w	d0,$d8(a0)
	move.b	d0,mt_songpos-mt_samplestarts-$7c(a1)
	move.b	d0,mt_counter-mt_samplestarts-$7c(a1)
	move.w	d0,mt_pattpos-mt_samplestarts-$7c(a1)
	rts


mt_end:	moveq	#0,d0
	lea	$dff000,a0
	move.w	d0,$a8(a0)
	move.w	d0,$b8(a0)
	move.w	d0,$c8(a0)
	move.w	d0,$d8(a0)
	move.w	#$f,$dff096
	rts


mt_music:
	lea	mt_data,a0
	lea	mt_voice1(pc),a4
	addq.b	#1,mt_counter-mt_voice1(a4)
	move.b	mt_counter(pc),d0
	cmp.b	mt_speed(pc),d0
	blt	mt_nonew
	moveq	#0,d0
	move.b	d0,mt_counter-mt_voice1(a4)
	move.w	d0,mt_dmacon-mt_voice1(a4)
	lea	mt_data,a0
	lea	$3b8(a0),a2
	lea	$43c(a0),a0

	moveq	#0,d1
	move.b	mt_songpos(pc),d0
	move.b	(a2,d0.w),d1
	lsl.w	#8,d1
	lsl.w	#2,d1
	add.w	mt_pattpos(pc),d1

	lea	$dff0a0,a5
	lea	mt_samplestarts-4(pc),a1
	lea	mt_playvoice(pc),a6
	jsr	(a6)
	addq.l	#4,d1
	lea	$dff0b0,a5
	lea	mt_voice2(pc),a4
	jsr	(a6)
	addq.l	#4,d1
	lea	$dff0c0,a5
	lea	mt_voice3(pc),a4
	jsr	(a6)
	addq.l	#4,d1
	lea	$dff0d0,a5
	lea	mt_voice4(pc),a4
	jsr	(a6)

	move.w	mt_dmacon(pc),d0

	beq.s	mt_nodma

	lea	$bfd000,a3
	move.b	#$7f,$d00(a3)
	move.w	#$2000,$dff09c
	move.w	#$a000,$dff09a
	move.l	#mt_irq1,$78.w
	moveq	#0,d0
	move.b	d0,$e00(a3)

	move.b	#$a0,$400(a3)

	move.b	d0,$500(a3)
	or.w	#$8000,mt_dmacon-mt_voice4(a4)
	move.b	#$11,$e00(a3)
	move.b	#$81,$d00(a3)

mt_nodma:
	add.w	#$10,mt_pattpos-mt_voice4(a4)
	cmp.w	#$400,mt_pattpos-mt_voice4(a4)
	bne.s	mt_exit
mt_next:clr.w	mt_pattpos-mt_voice4(a4)
	clr.b	mt_break-mt_voice4(a4)
	addq.b	#1,mt_songpos-mt_voice4(a4)
	and.b	#$7f,mt_songpos-mt_voice4(a4)
	move.b	-2(a2),d0
	cmp.b	mt_songpos(pc),d0
	bne.s	mt_exit
	move.b	-1(a2),mt_songpos-mt_voice4(a4)
mt_exit:tst.b	mt_break-mt_voice4(a4)
	bne.s	mt_next
	rts

mt_nonew:
	lea	$dff0a0,a5
	lea	mt_com(pc),a6
	jsr	(a6)
	lea	mt_voice2(pc),a4
	lea	$dff0b0,a5
	jsr	(a6)
	lea	mt_voice3(pc),a4
	lea	$dff0c0,a5
	jsr	(a6)
	lea	mt_voice4(pc),a4
	lea	$dff0d0,a5
	jsr	(a6)
	tst.b	mt_break-mt_voice4(a4)
	bne.s	mt_next
	rts

mt_irq1:tst.b	$bfdd00
	move.w	mt_dmacon(pc),$dff096
	move.l	#mt_irq2,$78.w
	move.w	#$2000,$dff09c
	rte

mt_irq2:tst.b	$bfdd00
	movem.l	a3/a4,-(a7)
	lea	mt_voice1(pc),a4
	lea	$dff000,a3
	move.l	$a(a4),$a0(a3)
	move.w	$e(a4),$a4(a3)
	move.l	$a+$1c(a4),$b0(a3)
	move.w	$e+$1c(a4),$b4(a3)
	move.l	$a+$38(a4),$c0(a3)
	move.w	$e+$38(a4),$c4(a3)
	move.l	$a+$54(a4),$d0(a3)
	move.w	$e+$54(a4),$d4(a3)
	movem.l	(a7)+,a3/a4
	move.b	#0,$bfde00
	move.b	#$7f,$bfdd00
	move.l	mt_oldirq(pc),$78.w
	move.w	#$2000,$dff09c
	move.w	#$2000,$dff09a
	rte

mt_playvoice:
	move.l	(a0,d1.l),(a4)
	moveq	#0,d2
	move.b	2(a4),d2
	lsr.b	#4,d2
	move.b	(a4),d0
	and.b	#$f0,d0
	or.b	d0,d2
	beq	mt_oldinstr

	asl.w	#2,d2
	move.l	(a1,d2.l),4(a4)
	move.l	mt_mulu(pc,d2.w),a3
	move.w	(a3)+,8(a4)
	move.w	(a3)+,$12(a4)
	move.l	4(a4),d0
	moveq	#0,d3
	move.w	(a3)+,d3
	beq	mt_noloop
	asl.w	#1,d3
	add.l	d3,d0
	move.l	d0,$a(a4)
	move.w	-2(a3),d0
	add.w	(a3),d0
	move.w	d0,8(a4)
	bra	mt_hejaSverige

mt_mulu:dcb.l	$20,0

mt_noloop:
	add.l	d3,d0
	move.l	d0,$a(a4)
mt_hejaSverige:
	move.w	(a3),$e(a4)
	move.w	$12(a4),8(a5)

mt_oldinstr:
	move.w	(a4),d3
	and.w	#$fff,d3
	beq	mt_com2
	tst.w	8(a4)
	beq.s	mt_stopsound
	move.b	2(a4),d0
	and.b	#$f,d0
	cmp.b	#5,d0
	beq.s	mt_setport
	cmp.b	#3,d0
	beq.s	mt_setport

	move.w	d3,$10(a4)
	move.w	$1a(a4),$dff096
	clr.b	$19(a4)

	move.l	4(a4),(a5)
	move.w	8(a4),4(a5)
	move.w	$10(a4),6(a5)

	move.w	$1a(a4),d0
	or.w	d0,mt_dmacon-mt_playvoice(a6)
	bra	mt_com2

mt_stopsound:
	move.w	$1a(a4),$dff096
	bra	mt_com2

mt_setport:
	move.w	(a4),d2
	and.w	#$fff,d2
	move.w	d2,$16(a4)
	move.w	$10(a4),d0
	clr.b	$14(a4)
	cmp.w	d0,d2
	beq.s	mt_clrport
	bge	mt_com2
	move.b	#1,$14(a4)
	bra	mt_com2
mt_clrport:
	clr.w	$16(a4)
	rts

mt_port:moveq	#0,d0
	move.b	3(a4),d2
	beq.s	mt_port2
	move.b	d2,$15(a4)
	move.b	d0,3(a4)
mt_port2:
	tst.w	$16(a4)
	beq.s	mt_rts
	move.b	$15(a4),d0
	tst.b	$14(a4)
	bne.s	mt_sub
	add.w	d0,$10(a4)
	move.w	$16(a4),d0
	cmp.w	$10(a4),d0
	bgt.s	mt_portok
	move.w	$16(a4),$10(a4)
	clr.w	$16(a4)
mt_portok:
	move.w	$10(a4),6(a5)
mt_rts:	rts

mt_sub:	sub.w	d0,$10(a4)
	move.w	$16(a4),d0
	cmp.w	$10(a4),d0
	blt.s	mt_portok
	move.w	$16(a4),$10(a4)
	clr.w	$16(a4)
	move.w	$10(a4),6(a5)
	rts

mt_sin:
	dc.b $00,$18,$31,$4a,$61,$78,$8d,$a1,$b4,$c5,$d4,$e0,$eb,$f4,$fa,$fd
	dc.b $ff,$fd,$fa,$f4,$eb,$e0,$d4,$c5,$b4,$a1,$8d,$78,$61,$4a,$31,$18

mt_vib:	move.b	$3(a4),d0
	beq.s	mt_vib2
	move.b	d0,$18(a4)

mt_vib2:move.b	$19(a4),d0
	lsr.w	#2,d0
	and.w	#$1f,d0
	moveq	#0,d2
	move.b	mt_sin(pc,d0.w),d2
	move.b	$18(a4),d0
	and.w	#$f,d0
	mulu	d0,d2
	lsr.w	#7,d2
	move.w	$10(a4),d0
	tst.b	$19(a4)
	bmi.s	mt_vibsub
	add.w	d2,d0
	bra.s	mt_vib3
mt_vibsub:
	sub.w	d2,d0
mt_vib3:move.w	d0,6(a5)
	move.b	$18(a4),d0
	lsr.w	#2,d0
	and.w	#$3c,d0
	add.b	d0,$19(a4)
	rts


mt_arplist:
	dc.b 0,1,2,0,1,2,0,1,2,0,1,2,0,1,2,0,1,2,0,1,2,0,1,2,0,1,2,0,1,2,0,1

mt_arp:	moveq	#0,d0
	move.b	mt_counter(pc),d0
	move.b	mt_arplist(pc,d0.w),d0
	beq.s	mt_normper
	cmp.b	#2,d0
	beq.s	mt_arp2
mt_arp1:move.b	3(a4),d0
	lsr.w	#4,d0
	bra.s	mt_arpdo
mt_arp2:move.b	3(a4),d0
	and.w	#$f,d0
mt_arpdo:
	asl.w	#1,d0
	move.w	$10(a4),d1
	lea	mt_periods(pc),a0
mt_arp3:cmp.w	(a0)+,d1
	blt.s	mt_arp3
	move.w	-2(a0,d0.w),6(a5)
	rts

mt_normper:
	move.w	$10(a4),6(a5)
	rts

mt_com:	move.w	2(a4),d0
	and.w	#$fff,d0
	beq.s	mt_normper
	move.b	2(a4),d0
	and.b	#$f,d0
	beq.s	mt_arp
	cmp.b	#6,d0
	beq.s	mt_volvib
	cmp.b	#4,d0
	beq	mt_vib
	cmp.b	#5,d0
	beq.s	mt_volport
	cmp.b	#3,d0
	beq	mt_port
	cmp.b	#1,d0
	beq.s	mt_portup
	cmp.b	#2,d0
	beq.s	mt_portdown
	move.w	$10(a4),6(a5)
	cmp.b	#$a,d0
	beq.s	mt_volslide
	rts

mt_portup:
	moveq	#0,d0
	move.b	3(a4),d0
	sub.w	d0,$10(a4)
	move.w	$10(a4),d0
	cmp.w	#$71,d0
	bpl.s	mt_portup2
	move.w	#$71,$10(a4)
mt_portup2:
	move.w	$10(a4),6(a5)
	rts

mt_portdown:
	moveq	#0,d0
	move.b	3(a4),d0
	add.w	d0,$10(a4)
	move.w	$10(a4),d0
	cmp.w	#$358,d0
	bmi.s	mt_portdown2
	move.w	#$358,$10(a4)
mt_portdown2:
	move.w	$10(a4),6(a5)
	rts

mt_volvib:
	 bsr	mt_vib2
	 bra.s	mt_volslide
mt_volport:
	 bsr	mt_port2

mt_volslide:
	moveq	#0,d0
	move.b	3(a4),d0
	lsr.b	#4,d0
	beq.s	mt_vol3
	add.b	d0,$13(a4)
	cmp.b	#$40,$13(a4)
	bmi.s	mt_vol2
	move.b	#$40,$13(a4)
mt_vol2:move.w	$12(a4),8(a5)
	rts

mt_vol3:move.b	3(a4),d0
	and.b	#$f,d0
	sub.b	d0,$13(a4)
	bpl.s	mt_vol4
	clr.b	$13(a4)
mt_vol4:move.w	$12(a4),8(a5)
	rts

mt_com2:move.b	2(a4),d0
	and.b	#$f,d0
	beq	mt_rts
	cmp.b	#$e,d0
	beq.s	mt_filter
	cmp.b	#$d,d0
	beq.s	mt_pattbreak
	cmp.b	#$b,d0
	beq.s	mt_songjmp
	cmp.b	#$c,d0
	beq.s	mt_setvol
	cmp.b	#$f,d0
	beq.s	mt_setspeed
	rts

mt_filter:
	move.b	3(a4),d0
	and.b	#1,d0
	asl.b	#1,d0
	and.b	#$fd,$bfe001
	or.b	d0,$bfe001
	rts

mt_pattbreak:
	move.b	#1,mt_break-mt_playvoice(a6)
	rts

mt_songjmp:
	move.b	#1,mt_break-mt_playvoice(a6)
	move.b	3(a4),d0
	subq.b	#1,d0
	move.b	d0,mt_songpos-mt_playvoice(a6)
	rts

mt_setvol:
	cmp.b	#$40,3(a4)
	bls.s	mt_sv2
	move.b	#$40,3(a4)
mt_sv2:	moveq	#0,d0
	move.b	3(a4),d0
	move.b	d0,$13(a4)
	move.w	d0,8(a5)
	rts

mt_setspeed:
	moveq	#0,d0
	move.b	3(a4),d0
	cmp.b	#$1f,d0
	bls.s	mt_sp2
	moveq	#$1f,d0
mt_sp2:	tst.w	d0
	bne.s	mt_sp3
	moveq	#1,d0
mt_sp3:	move.b	d0,mt_speed-mt_playvoice(a6)
	rts

mt_periods:
	dc.w $0358,$0328,$02fa,$02d0,$02a6,$0280,$025c,$023a,$021a,$01fc,$01e0
	dc.w $01c5,$01ac,$0194,$017d,$0168,$0153,$0140,$012e,$011d,$010d,$00fe
	dc.w $00f0,$00e2,$00d6,$00ca,$00be,$00b4,$00aa,$00a0,$0097,$008f,$0087
	dc.w $007f,$0078,$0071,$0000

mt_speed:	dc.b	6
mt_counter:	dc.b	0
mt_pattpos:	dc.w	0
mt_songpos:	dc.b	0
mt_break:	dc.b	0
mt_dmacon:	dc.w	0
mt_samplestarts:dcb.l	$1f,0
mt_voice1:	dcb.w	13,0
		dc.w	1
mt_voice2:	dcb.w	13,0
		dc.w	2
mt_voice3:	dcb.w	13,0
		dc.w	4
mt_voice4:	dcb.w	13,0
		dc.w	8
mt_oldirq:	dc.l	0

