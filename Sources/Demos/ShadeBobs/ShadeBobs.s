
	OPT NOCHKBIT

*			Shade Bobs
*			----------

*20/24
*22/24
*10/18
*10/14
*10/12

*  8/6
*  6/4

INC_X=8
INC_Y=6

	rsreset
Shade_Struct	rs.b 0
Offset_X	rs.w 1
Offset_Y	rs.w 1
Table_Cos	rs.b 1024
Table_Sin	rs.b 1024

	incdir "asm:" "asm:.s/ShadeBobs/" "ram:"
	include "sources/registers.i"

	section toto,code_c

	KILL_SYSTEM do_Shade
	moveq #0,d0
	rts

do_Shade
	lea $dff000,a6

	move.l #coplist,cop1lc(a6)
	clr.w copjmp1(a6)
	move.l #vbl,$6c.w

	move.l #Bpl,d0
	lea ptr(pc),a0
	moveq #5-1,d1
loop_init_ptr
	move.w d0,4(a0)
	swap d0
	move.w d0,(a0)
	swap d0
	add.l #40*256,d0
	addq.l #8,a0
	dbf d1,loop_init_ptr

	move.w #$83c0,dmacon(a6)
	move.w #$c020,intena(a6)

	WAIT_LMB_DOWN
	RESTORE_SYSTEM

vbl
	lea data_base(pc),a5
	lea $dff000,a6

	btst #10,potinp(a6)
	beq.s clear_screen

	lea Shade1(pc),a0
	bsr.s Shade_Bobs

	lea Shade2(pc),a0
	bsr.s Shade_Bobs

	lea Shade3(pc),a0
	bsr.s Shade_Bobs

	lea Shade4(pc),a0
	bsr.s Shade_Bobs

	lea Shade5(pc),a0
	bsr.s Shade_Bobs

	move.w #$0020,intreq(a6)
	rte

clear_screen
	move.l #Bpl,bltdpt(a6)
	move.w #0,bltdmod(a6)
	move.w #$0100,bltcon0(a6)
	move.w #0,bltcon1(a6)
	move.w #25,bltsize(a6)
wait_Clear
	btst #14,dmaconr(a6)
	bne.s wait_Clear
	move.w #$0020,intreq(a6)
	rte

Shade_Bobs
	add.w #INC_X,Offset_X(a0)
	and.w #$3fe,Offset_X(a0)
	add.w #INC_Y,Offset_Y(a0)
	and.w #$3fe,Offset_Y(a0)

	move.w Offset_X(a0),d0			récupère les positions X,Y
	move.w Table_Cos(a0,d0.w),d0

	move.w Offset_Y(a0),d1
	lea Table_Sin(a0),a0
	move.w 0(a0,d1.w),d1

	lea Bpl(pc),a0				recherche l'adresse où poser
	move.w d0,d2				le Shade Bob dans l'écran
	lsr.w #3,d2
	lea 0(a0,d2.w),a0
	lea 0(a0,d1.w),a0
	and.w #$f,d0
	ror.w #4,d0				shift B pour le blitter

	lea Shade_Pic(pc),a1
	lea 4*16(a1),a2

	move.l #Restore_Shade,bltapt(a6)	restore l'image du ShadeBob
	move.l a1,bltdpt(a6)
	move.l #0,bltamod(a6)
	or.w #$9f0,d0
	move.w d0,bltcon0(a6)
	move.w #0,bltcon1(a6)
	moveq #-1,d0
	move.l d0,bltafwm(a6)
	move.w #(16*4)<<6+2,bltsize(a6)
wait_Restore
	btst #14,dmaconr(a6)
	bne.s wait_Restore

	move.l #40-4,bltbmod(a6)		init le blitter
	move.w #0,bltcon1(a6)

	moveq #4-1,d7
put_ShadeBob
	move.l a0,bltapt(a6)			prépare le Buffer
	move.l a1,bltbpt(a6)
	move.l a2,bltdpt(a6)
	move.w #$dc0,bltcon0(a6)		fonction AND
	move.w #0,bltdmod(a6)
	move.w #16<<6+2,bltsize(a6)
wait_AND
	btst #14,dmaconr(a6)
	bne.s wait_AND

	move.l a0,bltapt(a6)			copie dans le bitplan
	move.l a1,bltbpt(a6)
	move.l a0,bltdpt(a6)
	move.w #$d3c,bltcon0(a6)		fonction XOR
	move.w #40-4,bltdmod(a6)
	move.w #16<<6+2,bltsize(a6)
wait_XOR
	btst #14,dmaconr(a6)
	bne.s wait_XOR

	lea 40*256(a0),a0
	move.l a2,a1
	lea 4*16(a1),a2
	dbf d7,put_ShadeBob

	move.l a0,bltapt(a6)
	move.l a1,bltbpt(a6)
	move.l a0,bltdpt(a6)
	move.w #16<<6+2,bltsize(a6)
wait_XOR2
	btst #14,dmaconr(a6)
	bne.s wait_XOR2
	rts	

data_base
Shade1
	dc.w -INC_X*18
	dc.w -INC_Y*18
	incbin "Table1.dat"

Shade2	dc.w -INC_X*12
	dc.w -INC_Y*12
	incbin "Table2.dat"

Shade3	dc.w -INC_X*7
	dc.w -INC_Y*7
	incbin "Table3.dat"

Shade4	dc.w -INC_X*3
	dc.w -INC_Y*3
	incbin "Table4.dat"

Shade5	dc.w 0
	dc.w 0
	incbin "Table5.dat"

Restore_Shade
	incbin "Shade_Pic.RAW"
	dcb.b 4*16*4
Shade_Pic
	dcb.b 4*16*5

coplist
	dc.w bplcon0,$5200
	dc.w bplcon1,$0
	dc.w bplcon2,$0
	dc.w diwstrt,$2b81
	dc.w diwstop,$2bc1
	dc.w ddfstrt,$38
	dc.w ddfstop,$d0
	dc.w bpl1mod,$0
	dc.w bpl2mod,$0
ptr=*+2
	dc.w bpl1ptH,0
	dc.w bpl1ptL,0
	dc.w bpl2ptH,0
	dc.w bpl2ptL,0
	dc.w bpl3ptH,0
	dc.w bpl3ptL,0
	dc.w bpl4ptH,0
	dc.w bpl4ptL,0
	dc.w bpl5ptH,0
	dc.w bpl5ptL,0

	IFNE 0
	dc.w $180,$002
	dc.w $182,$112
	dc.w $184,$223
	dc.w $186,$334
	dc.w $188,$345
	dc.w $18A,$456
	dc.w $18C,$568
	dc.w $18E,$679
	dc.w $190,$78A
	dc.w $192,$89A
	dc.w $194,$9AB
	dc.w $196,$ABC
	dc.w $198,$BCD
	dc.w $19A,$CDD
	dc.w $19C,$EEE
	dc.w $19E,$FFF
	dc.w $1A0,$DEE
	dc.w $1A2,$ADD
	dc.w $1A4,$8DC
	dc.w $1A6,$7CB
	dc.w $1A8,$5BA
	dc.w $1AA,$3A9
	dc.w $1AC,$2A8
	dc.w $1AE,$197
	dc.w $1B0,$187
	dc.w $1B2,$176
	dc.w $1B4,$076
	dc.w $1B6,$065
	dc.w $1B8,$055
	dc.w $1BA,$054
	dc.w $1BC,$044
	dc.w $1BE,$033
	ENDC

	dc.w	$0180,$0312
	dc.w	$0182,$0413
	dc.w	$0184,$0523
	dc.w	$0186,$0524
	dc.w	$0188,$0624
	dc.w	$018A,$0725
	dc.w	$018C,$0835
	dc.w	$018E,$0936
	dc.w	$0190,$0936
	dc.w	$0192,$0A37
	dc.w	$0194,$0B47
	dc.w	$0196,$0C48
	dc.w	$0198,$0D49
	dc.w	$019A,$0D59
	dc.w	$019C,$0E5A
	dc.w	$019E,$0F5A
	dc.w	$01A0,$0DEE
	dc.w	$01A2,$0BDD
	dc.w	$01A4,$0ACC
	dc.w	$01A6,$09CC
	dc.w	$01A8,$07BB
	dc.w	$01AA,$06AA
	dc.w	$01AC,$05A9
	dc.w	$01AE,$0499
	dc.w	$01B0,$0488
	dc.w	$01B2,$0377
	dc.w	$01B4,$0277
	dc.w	$01B6,$0166
	dc.w	$01B8,$0155
	dc.w	$01BA,$0144
	dc.w	$01BC,$0044
	dc.w	$01BE,$0033

	dc.l $fffffffe

Bpl
	dcb.b 40*256*5,0

