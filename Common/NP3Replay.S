* * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* NoisePacker V3.0 PlayRoutine ©1991 Twins of Phenomena *
* Used registers are d0-d7/a0-a6     It use lev6irq     *
* How to use it? 1. bsr np_init                         *
*                2. bsr np_music (every vert.)          *
*                3. bsr np_end                          *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * *

np_init:moveq	#1,d0
	moveq	#0,d1
	lea	np_data,a4
	lea	$dff000,a5
	lea	np_oldirq(pc),a6

	move.l	$78.w,(a6)+
	move	d0,(a6)+
	move.l	a4,a3
	add	(a4)+,a3
	move.l	a3,(a6)+
	move	d1,(a6)+
np_ini1:add	(a4)+,a3
	move.l	a3,(a6)+
	dbf	d0,np_ini1
	move	(a4)+,d0
	add.l	d0,a3

	move.l	#$82000006,(a6)+
	move	#$0100,(a6)+
	move.l	#np_portup,(a6)+
	move.l	#np_portdown,(a6)+
	move.l	#np_port,(a6)+
	move.l	#np_vib,(a6)+
	move.l	#np_port2,(a6)+
	move.l	#np_vib2,(a6)+
	move.l	#np_volslide,(a6)+
	move.l	#np_arp,(a6)+
	move.l	#np_songjmp,(a6)+
	move.l	#np_setvol,(a6)+
	move.l	#np_pattbreak,(a6)+
	move.l	#np_filter,(a6)+
	move.l	#np_setspeed,(a6)+

	moveq	#0,d0
	move.l	a4,a6
	add	-8(a4),a6
	sub	#12,a6
np_ini2:move.l	a3,2(a4)
	move.l	a3,a2
	move	14(a4),d0
	add	d0,d0
	add.l	d0,a2
	move.l	a2,8(a4)
	move	6(a4),d0
	add	d0,d0
	add.l	d0,a3
	add	#16,a4
	cmp.l	a4,a6
	bne.s	np_ini2

	bset	#1,$bfe001
	move	d1,$a8(a5)
	move	d1,$b8(a5)
	move	d1,$c8(a5)
	move	d1,$d8(a5)
	move	#$f,$96(a5)

	move	#$2000,$9a(a5)
	lea	$bfd000,a0
	move.b	#$7f,$d00(a0)
	move.b	#$08,$e00(a0)
	move.b	#$80,$400(a0)
	move.b	#$01,$500(a0)
np_ini3:btst	#0,$d00(a0)
	beq.s	np_ini3
	move.b	#$81,$d00(a0)
	move	#$e000,$9a(a5)
	rts

np_end:	moveq	#0,d0
	lea	$dff000,a5
	move	d0,$a8(a5)
	move	d0,$b8(a5)
	move	d0,$c8(a5)
	move	d0,$d8(a5)
	bclr	#1,$bfe001
	move	#$f,$96(a5)
	move	#$2000,$9a(a5)
	move.l	np_oldirq(pc),$78.w
	rts

np_music:
	moveq	#0,d6
	lea	$dff0d0,a4
	lea	np_block(pc),a6
	subq	#1,(a6)+
	bhi	np_nonew

	move.l	(a6)+,a1
	add	(a6)+,a1
	move.l	(a6)+,a0
	add	(a1),a0
	move.l	(a6)+,d2
	lea	np_data-8,a1
	lea	np_voidat1(pc),a2

	moveq	#8,d0
	moveq	#0,d1
	moveq	#0,d4
	moveq	#0,d5
np_loop1:
	move	(a0)+,d1

	tst	(a2)+
	bpl.s	np_lop3
	addq	#1,-(a2)
	add	#32,a2
	addq	#8,a4
	bra	np_lop7
np_lop3:
	move.l	d2,a3
	add.l	d1,a3
	add	(a2),a3

	move.b	(a3)+,d1
	bpl.s	np_lop4
	ext	d1
	addq	#1,d1
	addq	#1,(a2)
	move	d1,-(a2)
	move	d6,8(a2)
	add	#32,a2
	addq	#8,a4
	bra	np_lop7
np_lop4:
	move.b	(a3)+,d3
	move.b	(a3)+,d4
	addq	#3,(a2)+

	move.l	a1,a3
	move.b	d1,d7
	lsl	#8,d7
	or.b	d3,d7
	and	#$1f0,d7
	bne.s	np_loop3

	add	(a2)+,a3
	addq	#2,a2
	addq	#2,a3
	bra.s	np_loop4
np_loop3:
	move	d7,(a2)+
	add	d7,a3
	move	(a3)+,(a2)+
np_loop4:
	and	#$f,d3
	move	d3,(a2)+
	move	d4,(a2)+

	and	#$fe,d1
	beq.s	np_loop5

	move	np_periods-2(pc,d1.w),d7

	subq	#3,d3
	beq	np_setport
	subq	#2,d3
	beq	np_setport

	or	d0,d5
	move	d7,(a2)+
	move	d1,(a2)+
	move	d6,(a2)+

	move.l	(a3)+,(a4)+
	move	(a3)+,(a4)+
	move.l	(a3)+,(a2)+
	move	(a3)+,(a2)+

	subq	#6,d3
	bmi.s	np_loop6
	add	d3,d3
	add	d3,d3
	move.l	38(a6,d3.w),a3
	jmp	(a3)

np_loop5:
	add	#12,a2
	addq	#6,a4
	sub	#11,d3
	bmi.s	np_loop6
	add	d3,d3
	add	d3,d3
	move.l	38(a6,d3.w),a3
	jmp	(a3)

np_periods:
	dc.w	$0358,$0328,$02fa,$02d0,$02a6,$0280,$025c,$023a,$021a
	dc.w	$01fc,$01e0,$01c5,$01ac,$0194,$017d,$0168,$0153,$0140
	dc.w	$012e,$011d,$010d,$00fe,$00f0,$00e2,$00d6,$00ca,$00be
	dc.w	$00b4,$00aa,$00a0,$0097,$008f,$0087,$007f,$0078,$0071

np_loop6:
	move	-12(a2),(a4)+
np_loop7:
	move	-18(a2),(a4)
	addq	#8,a2
np_lop7:
	sub	#$18,a4
	lsr	#1,d0
	bne	np_loop1

	move	d5,6(a4)
	or	d5,(a6)+
	move	(a6)+,-20(a6)
	move.l	#np_irq1,$78.w
	move.b	#$19,$bfde00

	bset	#0,(a6)+
	beq.s	np_break
	addq.b	#1,(a6)
	cmp.b	#64,(a6)
	bne.s	np_next
np_break:
	move.b	d6,(a6)
	move.l	d6,-32(a2)
	move.l	d6,-64(a2)
	move.l	d6,-96(a2)
	move.l	d6,-128(a2)
	lea	np_block+2(pc),a6
	move.l	(a6)+,a0
	addq	#2,(a6)
	move	(a6),d0
	cmp	-4(a0),d0
	bne.s	np_next
	move	-2(a0),(a6)
np_next:rts

np_setvol:
	move	d4,-18(a2)
	bra.w	np_loop6

np_pattbreak:
	move.b	d6,4(a6)
	bra.w	np_loop6

np_songjmp:
	move.b	#63,5(a6)
	move.b	d4,-9(a6)
	bra.w	np_loop6

np_setspeed:
	move	d4,2(a6)
	bra	np_loop6

np_filter:
	and.b	#$fd,$bfe001
	or.b	d4,$bfe001
	bra	np_loop6

np_setport:
	add	#12,a2
	addq	#8,a4
	cmp	-12(a2),d7
	slt	(a2)
	beq.s	np_clear
	move	d7,2(a2)
	bra	np_loop7
np_clear:
	move	d6,2(a2)
	bra	np_loop7

np_nonew:
	lea	np_voidat1(pc),a0
	moveq	#3,d0
np_lop1:move	8(a0),d1
	beq.w	np_lop2
	subq	#8,d1
	bhi.w	np_lop2
	addq	#7,d1
	add	d1,d1
	add	d1,d1
	move.l	20(a6,d1.w),a3
	jmp	(a3)
np_lop2:add	#32,a0
	sub	#$10,a4
	dbf	d0,np_lop1
	rts

np_portup:
	move	10(a0),d2
	sub	d2,12(a0)
	cmp	#$71,12(a0)
	bpl.s	np_portup2
	move	#$71,12(a0)
np_portup2:
	move	12(a0),6(a4)
	bra.s	np_lop2

np_portdown:
	move	10(a0),d2
	add	d2,12(a0)
	cmp	#$358,12(a0)
	bmi.s	np_portdown2
	move	#$358,12(a0)
np_portdown2:
	move	12(a0),6(a4)
	bra.s	np_lop2

np_arp:	move	-2(a6),d2
	sub	16(a6),d2
	neg	d2
	move.b	np_arplist(pc,d2.w),d2
	beq.s	np_arp0
	subq	#2,d2
	beq.s	np_arp2
np_arp1:move	10(a0),d2
	lsr	#3,d2
	and	#$e,d2
	bra.s	np_arp3
np_arp2:move	10(a0),d2
	and	#$f,d2
	add	d2,d2
np_arp3:add	14(a0),d2
	cmp	#$48,d2
	bls.s	np_arp4
	moveq	#$48,d2
np_arp4:lea	np_periods-2(pc),a3
	move	(a3,d2.w),6(a4)
	bra	np_lop2
np_arp0:move	12(a0),6(a4)
	bra	np_lop2

np_arplist:
	dc.b 0,1,2,0,1,2,0,1,2,0,1,2,0,1,2,0,1,2,0,1,2,0,1,2,0,1,2,0,1,2,0,1

np_sin:
	dc.b $00,$18,$31,$4a,$61,$78,$8d,$a1,$b4,$c5,$d4,$e0,$eb,$f4,$fa,$fd
	dc.b $ff,$fd,$fa,$f4,$eb,$e0,$d4,$c5,$b4,$a1,$8d,$78,$61,$4a,$31,$18

np_vib:	move	10(a0),d3
	beq.s	np_vib2
	move	d3,30(a0)
np_vib2:	
	move	16(a0),d3
	lsr	#2,d3
	and	#$1f,d3
	moveq	#0,d2
	move.b	np_sin(pc,d3.w),d2
	move	30(a0),d3
	and	#$f,d3
	mulu	d3,d2
	lsr	#7,d2
	move	12(a0),d3
	tst.b	17(a0)
	bmi.s	np_vibsub
	add	d2,d3
	bra.s	np_vib3
np_vibsub:
	sub	d2,d3
np_vib3:move	d3,6(a4)
	move	30(a0),d3
	lsr	#2,d3
	and	#$3c,d3
	add.b	d3,17(a0)
	cmp.b	#20,d1
	bne	np_lop2

np_volslide:
	move	10(a0),d2
	add.b	d2,7(a0)
	bmi.s	np_vol3
	cmp	#$40,6(a0)
	bmi.s	np_vol2
	move	#$40,6(a0)
np_vol2:move	6(a0),8(a4)
	bra	np_lop2

np_vol3:move	d6,6(a0)
	move	d6,8(a4)
	bra	np_lop2

np_port:move	10(a0),d2
	beq.s	np_port2
	move	d2,28(a0)

np_port2:
	move	26(a0),d2
	beq.s	np_rts
	move	28(a0),d3
	tst	24(a0)
	bne.s	np_sub
	add	d3,12(a0)
	cmp	12(a0),d2
	bgt.s	np_portok
	move	d2,12(a0)
	move	d6,26(a0)
np_portok:
	move	12(a0),6(a4)
np_rts:	cmp.b	#16,d1
	beq.s	np_volslide
	bra	np_lop2

np_sub:	sub	d3,12(a0)
	cmp	12(a0),d2
	blt.s	np_portok
	move	d2,12(a0)
	move	d6,26(a0)
	move	12(a0),6(a4)
	cmp.b	#16,d1
	beq	np_volslide
	bra	np_lop2

np_irq1:
	tst.b	$bfdd00
	move.b	#$19,$bfde00
	move.l	#np_irq2,$78.w
	move	np_block+16(pc),$dff096
	move	#$2000,$dff09c
	rte

np_irq2:
	tst.b	$bfdd00
	move.l	np_voidat1+18(pc),$dff0d0
	move	np_voidat1+22(pc),$dff0d4
	move.l	np_voidat1+50(pc),$dff0c0
	move	np_voidat1+54(pc),$dff0c4
	move.l	np_voidat1+82(pc),$dff0b0
	move	np_voidat1+86(pc),$dff0b4
	move.l	np_voidat1+114(pc),$dff0a0
	move	np_voidat1+118(pc),$dff0a4
	move.l	np_oldirq(pc),$78.w
	move	#$2000,$dff09c
	rte

np_oldirq:	dc.l	0
np_block:	dcb.l	19,0
np_voidat1:	dcb.l	32,0

