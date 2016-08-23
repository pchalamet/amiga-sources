
*	tracé de droite dans une coplist composé de MOVEs et de WAITs
*	-------------------------------------------------------------


	incdir "dh0:asm/"
	
NB_MOVE=40
NB_LIGNE=194
LINE_SIZE=NB_MOVE*4+4+4

	incdir "asm:"
	include "sources/registers.i"

	section prout,code_c

	bsr save_all
	
	lea data_base(pc),a5
	lea $dff000,a6

	move.w #$7fff,d0
	move.w d0,intena(a6)
	move.w d0,dmacon(a6)

	move.l #vbl,$6c.w

	move.l #coplist,cop1lc(a6)
	move.w #0,copjmp1(a6)

	move.w #$8680,dmacon(a6)		master ! copper ! blitter ! pri
	move.w #$c020,intena(a6)

mickey
	btst #6,ciaapra
	bne.s mickey
	bsr restore_all
	moveq #0,d0
	rts

	include "sources/save_all.s"

vbl
	move.w X1(pc),d0
	move.w Y(pc),d1
	move.w X2(pc),d2
	move.w d1,d3
	bsr draw_copper_line

	move.w X1(pc),d0
	move.w Y(pc),d1
	moveq #0,d2
	move.w d1,d3
	bsr draw_copper_line

	move.w X2(pc),d0
	move.w Y(pc),d1
	move.w #319,d2
	move.w d1,d3
	bsr draw_copper_line

	tst.w X1-data_base(a5)
	beq.s do_Y
	subq.w #1,X1-data_base(a5)
	addq.w #1,X2-data_base(a5)
do_Y
	tst.w Y-data_base(a5)
	beq.s no_Y
	subq.w #1,Y-data_base(a5)
no_Y

no_inc
	btst #10,potgor(a6)
	bne.s no_red
	move.w #$f00,color00(a6)

no_red
	move.w #$0020,intreq(a6)
	rte

X1	dc.w 159
X2	dc.w 160
Y	dc.w NB_LIGNE-1

*------------------------> tracé de droite façon Bresenham dans la coplist
*------------------------> line(d0,d1)-(d2,d3)
*------------------------> d6-d7/a2-a6 inchangés
X equr d0
Y equr d1
point_ptr equr a0
DX equr d2
DY equr d3
INCX equr d4
INCY equr d5
C equr d0
COUNT equr d1

draw_copper_line
	lea coplist+16(pc),a0
	lea table_color(pc),a1			pointe la table des couleurs

do_DX
	moveq #4,INCX
	sub.w d0,d2				calcule de DX
	bge.s Do_DY				et de INCX
	neg.w DX
	neg.l INCX

do_DY
	lsr.w #3,DX				passe de pixel en octets
	lsr.w #1,X				X pointe des LONGs
	and.b #$fc,X

	move.l #LINE_SIZE,INCY
	sub.w d1,d3				calcule de DY
	bge.s do_C				et de INCY
	neg.w DY
	neg.l INCY

do_C
	add.w Y,Y				table de WORDs
	move.w table_mulu(pc,Y.w),Y		mulu #NB_MOVE*4+4+4,Y
	add.w X,Y				commence au bon offset
	lea 4+2(a0,Y.w),point_ptr		pointe dans la coplist

	cmp.w DX,DY				DX>DY ?
	bge.s DX_lower_DY

	add.w DY,DY
	move.w DY,C				calcule de C
	sub.w DX,C				C:=2*DY-DX

	move.w DX,COUNT				for I:=1 to DX
	add.w DX,DX
.loop
	move.w (a1)+,(point_ptr)		met un point de la droite

	add.l INCX,point_ptr
	tst.w C
	bge.s .C_ge
	add.w DY,C
	dbf COUNT,.loop
	rts
.C_ge
	add.l INCY,point_ptr
	add.w DY,C				C:=C+2*DY-2*DX
	sub.w DX,C
	dbf COUNT,.loop
	rts
	
DX_lower_DY
	add.w DX,DX
	move.w DX,C				calcule de C
	sub.w DY,C				C:=2*DX-DY

	move.w DY,COUNT				for I:=1 to DY
	add.w DY,DY
.loop
	move.w (a1)+,(point_ptr)		met un point de la droite

	add.l INCY,point_ptr
	tst.w C
	bge.s .C_ge
	add.w DX,C				C:=C+2*DX
	dbf COUNT,.loop
	rts
.C_ge
	add.l INCX,point_ptr
	add.w DX,C				C:=C+2*DX-2*DY
	sub.w DY,C
	dbf COUNT,.loop
	rts
	
***********************************************************************
***********************************************************************
************************** BASE DES DATAS *****************************
data_base:
***********************************************************************

table_mulu
mul set 0
	rept NB_LIGNE
	dc.w mul*LINE_SIZE
mul set mul+1
	endr

table_color
	rept 2
;	dc.w 0
	dc.w $100,$200,$300,$400,$500,$600,$700,$800,$900
	dc.w $a00,$b00,$c00,$d00,$e00,$f00,$f10,$f20,$f30,$f40
	dc.w $f50,$f60,$f70,$f80,$f90,$fa0,$fb0,$fc0,$fd0,$fe0
	dc.w $ff0,$ff1,$ff2,$ff3,$ff4,$ff5,$ff6,$ff7,$ff8,$ff9
	dc.w $ffa,$ffb,$ffc,$ffd,$ffe,$fff,$eff,$dff,$cff,$bff
	dc.w $aff,$9ff,$8ff,$7ff,$6ff,$5ff,$4ff,$3ff,$2ff,$1ff
	dc.w $0ff,$0ef,$0df,$0cf,$0bf,$0af,$09f,$08f,$07f,$06f
	dc.w $05f,$04f,$03f,$02f,$01f,$00f,$10f,$20f,$30f,$40f
	dc.w $50f,$60f,$70f,$80f,$90f,$a0f,$b0f,$c0f,$d0f,$e0f
	dc.w $f0f,$e1e,$d2d,$c3c,$b4b,$a5a,$969,$878,$787,$696
	dc.w $5a5,$4b4,$3c3,$2d2,$1e1,$0f0,$0e0,$0d0,$0c0,$0b0
	dc.w $0a0,$090,$080,$070,$060,$050,$040,$030,$020,$010
	endr

coplist
wait set $4500
	dc.w wait|$0f,$fffe
	dc.w color00,$fff
wait set wait+$100
	dc.w wait|$0f,$fffe
	dc.w color00,0
	rept NB_LIGNE
	dc.w (wait|$3f),$fffe
	dcb.l NB_MOVE,color00<<16
wait set (wait+$100)&$ff00
	dc.w color00,0
	endr
	dc.w wait|$0f,$fffe
	dc.w color00,$fff
wait set wait+$100
	dc.w wait|$0f,$fffe
	dc.w color00,0
	dc.l $fffffffe

