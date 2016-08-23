
*
*			Tunnel de points
*			---------------------->
*			(c) 1993 Sync/Dreamdealers

	OPT NOCHKBIT


	incdir "ram:"
	incdir "asm:"
	incdir "asm:sources/"
	incdir "asm:.s/Tunnel/"
	incdir "asm:songs/medium"
	include "registers.i"
	OUTPUT asm:bin/Tunnel3


	KILL_SYSTEM Entry_Point
	moveq #0,d0
	rts

Entry_Point
	lea data_base(pc),a5
	lea _CustomBase,a6

	move.l #coplist,cop1lc(a6)
	move.l #vbl,$6c.w

	jsr mt_init

	move.w #$83c0,dmacon(a6)
	move.w #$c020,intena(a6)

mickey
	btst #6,ciaapra
	bne.s mickey
	move.w #-1,SkipFlag-data_base(a5)

loop_wait_skip
	cmp.w #40,SkipCircles-data_base(a5)
	ble.s loop_wait_skip

	jsr mt_end
	rte

vbl
	movem.l d0-d7/a0-a6,-(sp)

	jsr mt_music

	lea data_base(pc),a5
	lea _CustomBase,a6

	bsr flip_screens
	bsr clear_tunnel
	bsr tunnel

	btst #10,potinp(a6)
	bne.s no_right
	move.w #$f0f,color00(a6)
no_right
	move.w #$0020,intreq(a6)
	movem.l (sp)+,d0-d7/a0-a6
	rte

flip_screens
	movem.l log_screen(pc),d0-d2
	exg d0,d1
	exg d1,d2
	movem.l d0-d2,log_screen-data_base(a5)
	move.l d2,bpl1ptH(a6)
	rts


********************************************************************************
********************                                        ********************
********************  EFFACAGE DE L'ECRAN AVEC LE BLITTER   ********************
********************                                        ********************
********************************************************************************
clear_tunnel
	btst #14,dmaconr(a6)
	bne.s clear_tunnel

	move.l blt_screen(pc),bltdpt(a6)
	move.l #$01000000,bltcon0(a6)
	move.w #40,bltdmod(a6)
	move.w #(256<<6)|(20),bltsize(a6)
	rts

tunnel
	lea Centre(pc),a3
	lea Circles(pc),a4
	move.w Depth(pc),d7
	lea (a4,d7.w),a4

	move.w SkipCircles(pc),d7
	bra.s start_skip

loop_skip_circles
	addq.l #4,a3
	lea 5*216(a4),a4			saute quelques cercles pour
	cmp.l #FinCircles,a4			le final
	bge.s end_tunnel
start_skip
	dbf d7,loop_skip_circles

	move.w NbCircles(pc),d7			affiche que ce nombre de
	bra start_tunnel			cercles

loop_put_tunnel
	move.l a4,a0
	move.l log_screen(pc),a1

	moveq #36-1,d0				36 points sur un cercle
	move.w (a3)+,d1				CentreX
	add.w #160,d1
	ext.l d1
	move.w (a3)+,d2
	add.w #128,d2
	muls #80,d2
	add.l d2,a1				CentreY
loop_put_circle
	move.l d1,d2
	add.w (a0)+,d2				X+centreX
	move.w d2,d3
	asr.w #3,d2
	not.w d3
	ext.l d2
	add.l (a0)+,d2
	bset d3,(a1,d2.l)
	dbf d0,loop_put_circle

	lea 5*216(a4),a4			fin de la table ?
start_tunnel
	cmp.l #FinCircles,a4
	bge.s end_tunnel
	dbf d7,loop_put_tunnel

end_tunnel
	moveq #0,d0				on a fait le tour ?
	move.w Depth(pc),d0
	add.w #216,d0
	cmp.w #10*216,d0
	blt ok_depth
	sub.w #5*216,d0
	move.w d0,Depth-data_base(a5)

	addq.w #1,NbCircles-data_base(a5)
	tst.w SkipFlag-data_base(a5)
	beq.s no_skip
	addq.w #1,SkipCircles-data_base(a5)

no_skip
	lea Centre+59*4(pc),a0
	moveq #59-1,d0
decal_centre
	move.l -(a0),4(a0)
	dbf d0,decal_centre

	lea Table_Cosinus(pc),a0
	lea Table_Sinus(pc),a1
	movem.w Cos(pc),d0-d1
	move.w (a0,d0.w),Centre-data_base(a5)
	move.w (a1,d1.w),Centre+2-data_base(a5)
	add.w IncX(pc),d0
	bpl.s .ok1
	add.w #1440,d0
	bra.s .ok2
.ok1
	cmp.w #1440,d0
	blt.s .ok2
	sub.w #1440,d0
.ok2
	add.w IncY(pc),d1
	bpl.s .ok3
	add.w #1440,d1
	bra.s .ok4
.ok3
	cmp.w #1440,d1
	blt.s .ok4
	sub.w #1440,d1
.ok4
	movem.w d0-d1,Cos-data_base(a5)
	rts

ok_depth
	move.w d0,Depth-data_base(a5)
	rts

data_base
log_screen	dc.l screen1
blt_screen	dc.l screen2
phy_screen	dc.l screen3

Depth		dc.w 0
Cos		dc.w 0
Sin		dc.w 0
IncX		dc.w 30
IncY		dc.w -20
SkipCircles	dc.w 0
SkipFlag	dc.w 0
NbCircles	dc.w 0
Centre		dcb.l 60,0

Table_Cosinus	incbin "Table_cosinus.DAT"
Table_Sinus=Table_Cosinus+90*4

Circles		incbin "Tunnel.DAT"
FinCircles

	include "TMC_Replay.s"
	include "Song.s"

********************************************************************************
********************                                        ********************
********************        LA ET BEN YA LES ECRANS         ********************
********************                                        ********************
********************************************************************************
	section girafe,bss_c
	ds.b 256*80
screen1	ds.b 256*80
	ds.b 256*80
screen2	ds.b 256*80
	ds.b 256*80
screen3	ds.b 256*80
	ds.b 256*80


********************************************************************************
********************                                        ********************
********************               THE COPLIST              ********************
********************                                        ********************
********************************************************************************
	section gologolo,data_c
coplist
	dc.w bplcon0,$1200
	dc.w bplcon1,0
	dc.w bplcon2,0
	dc.w diwstrt,$2b81
	dc.w diwstop,$2bc1
	dc.w ddfstrt,$38
	dc.w ddfstop,$d0
	dc.w bpl1mod,40
	dc.w bpl2mod,40
	dc.w color00,$312
	dc.w color01,$ddd
	dc.l $ffffffffe

	include "samples.s"
