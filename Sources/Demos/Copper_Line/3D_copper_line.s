*********************************************************
*							*
* 3D Copper  lines					*
*							*
* C vraimment trop nul ce petit programme...		*
* on regarde et on oublie !				*
*						  	*
*********************************************************

*--------> nb d'étoiles
nb_points=8
nb_lines=12
NB_MOVE=40
NB_LIGNE=194
LINE_SIZE=NB_MOVE*4+4+4

	OPT NOCHKBIT,OW+

	incdir "asm:"
	incdir "asm:Copper_Line"
	include "sources/registers.i"

*--------> main init

	section boum,code_f

*----------------------> construction de la table des mulus
	move.l #256*512,d0			alloue de la memoire
	moveq #4,d1				pour la table de mulus (fast)
	move.l (ExecBase).w,a6
	jsr AllocMem(a6)
	move.l d0,-(sp)				sauve le ptr
	bne.s Mem_ok
	addq.l #4,sp				corrige sp
	rts					zut ...  ça a pas marché !
	
Mem_ok
	move.l d0,a0				sauve ptr
	add.l #128*512+256,d0			pointe 0*0 ds table_mulu
	lea data_base(pc),a5
	move.l d0,mulu_ptr+2-data_base(a5)	installation du ptr

build_mulu
	move.w #-128,d0				constuit la table de mulu
	move.w #-128,d1
build_line_mulu
	move.w d1,d2
	mulu d0,d2
	move.w d2,(a0)+
	addq.w #1,d1
	cmp.w #128,d1
	bne.s build_line_mulu
	move.w #-128,d1
	addq.w #1,d0
	cmp.w #128,d0
	bne.s build_line_mulu

*----------------------> initialisation de la bête
	KILL_SYSTEM yo_3d

	move.l (sp)+,a1				libère la table_mulu
	move.l #256*512,d0
	move.l (ExecBase).w,a6
	jsr FreeMem(a6)
	moveq #0,d0
	rts

yo_3d
	lea data_base(pc),a5
	lea $dff000,a6

	move.l #vbl,$6c.w			la vbl
	move.l #coplist1,cop1lc(a6)		installe une coplist
	clr.w copjmp1(a6)

	move.w #$86c0,dmacon(a6)
	move.w #$c020,intena(a6)

mickey	btst #6,ciaapra
	bne.s mickey

	RESTORE_SYSTEM

*-----------> la vbl
vbl
	bsr.s clear_coplist
	bsr.s do_angle
	bsr compute_matrix
	bsr compute_all_dots

	lea data_base(pc),a5
	lea $dff000,a6
	bsr draw_object

	movem.l log_coplist(pc),d0-d1
	exg d0,d1
	movem.l d0-d1,log_coplist-data_base(a5)
	
	move.l d1,cop1lc(a6)

	btst #10,potinp(a6)
	bne.s no_red
	move.w #$f00,color00(a6)

no_red
	move.w #$0020,intreq(a6)
	rte

log_coplist	dc.l coplist1
phy_coplist	dc.l coplist2

*------------> routine qui éfface une coplist
clear_coplist
	move.w #NB_LIGNE-1,d0
	move.l log_coplist(pc),a0
	lea 16(a0),a0
	move.l #color00<<16,d2
next_ligne
	addq.l #4,a0
	moveq #NB_MOVE-1,d1
loop_ligne
	move.l d2,(a0)+
	dbf d1,loop_ligne
	addq.l #4,a0
	dbf d0,next_ligne
	rts

*------------> routine qui incrémente les angles
do_angle
	movem.w alpha(pc),d0-d2

inc_alpha
	addq.w #6,d0
	bge.s inc_alpha_2
	add.w #720,d0
	bra.s inc_teta
inc_alpha_2
	cmp.w #720,d0
	blt.s inc_teta
	sub.w #720,d0

inc_teta
	addq.w #6,d1
	bge.s inc_teta_2
	add.w #720,d1
	bra.s inc_phi
inc_teta_2
	cmp.w #720,d1
	blt.s inc_phi
	sub.w #720,d1

inc_phi
	addq.w #6,d2
	bge.s inc_phi_2
	add.w #720,d2
	bra.s angle_ok
inc_phi_2
	cmp.w #720,d2
	blt.s angle_ok
	sub.w #720,d2

angle_ok
	movem.w d0-d2,alpha-data_base(a5)
	rts

*------------> routine qui calcul la matrice de rotation dans l'espace
* en entrée :
*		d0=alpha
*		d1=teta
*		d2=phi

compute_matrix
	lea table_cosinus(pc),a0
	lea table_sinus(pc),a1

*-----------------> recherche les cosinus et sinus des angles

cosalpha equr d0				qq equr pour se simplifier
sinalpha equr d1				la lecture
costeta  equr d2
sinteta  equr d3
cosphi   equr d4
sinphi   equr d5

	move.w 0(a1,d2.w),sinphi		sinus phi
	move.w 0(a0,d2.w),cosphi		cosinus phi

	move.w 0(a1,d1.w),sinteta		sinus teta
	move.w 0(a0,d1.w),costeta		cosinus teta

	move.w 0(a1,d0.w),sinalpha		sinus alpha
	move.w 0(a0,d0.w),cosalpha		cosinus alpha

mulu_ptr
	lea $12345678,a1			on pointe 0*0 dans table_mulu

*-----------------> calcul de la matrice de rotation
	lea matrix(pc),a0

	move.w costeta,d6
	muls cosphi,d6				cos(teta) * cos(phi)
	asl.l #2,d6
	and.w #$fe00,d6				multiple de 512 uniquement
	lea 0(a1,d6.l),a2			adr du mulu
	move.l a2,(a0)

	move.w costeta,d6
	muls sinphi,d6				cos(teta) * sin(phi)
	asl.l #2,d6
	and.w #$fe00,d6				multiple de 512 uniquement
	lea 0(a1,d6.l),a2			adr du mulu
	move.l a2,12(a0)

	move.w sinteta,d6
	ext.l d6
	neg.w d6
	asl.l #8,d6
	asl.l #1,d6
	and.w #$fe00,d6
	lea 0(a1,d6.l),a2
	move.l a2,24(a0)			-sin(teta)

	move.w costeta,d6
	muls sinalpha,d6			cos(teta) * sin(alpha)
	asl.l #2,d6
	and.w #$fe00,d6				multiple de 512 uniquement
	lea 0(a1,d6.l),a2			adr du mulu
	move.l a2,28(a0)

	move.w costeta,d6
	muls cosalpha,d6			cos(teta) * cos(alpha)
	asl.l #2,d6
	and.w #$fe00,d6				multiple de 512 uniquement
	lea 0(a1,d6.l),a2			adr du mulu
	move.l a2,32(a0)
	
	move.w sinalpha,d6
	muls sinteta,d6				sin(alpha) * sin(teta)
	move.w d6,a3

	muls cosphi,d6				sin(alpha)*sin(teta)*cos(phi)
	asr.l #5,d6
	move.w cosalpha,d7
	muls sinphi,d7				cos(alpha) * sin(phi)
	asl.l #2,d7
	sub.l d7,d6
	and.w #$fe00,d6
	lea 0(a1,d6.l),a2
	move.l a2,4(a0)

	move.w a3,d6
	muls sinphi,d6				sin(alpha)*sin(teta)*sin(phi)
	asr.l #5,d6
	move.w cosalpha,d7
	muls cosphi,d7				cos(alpha) * cos(phi)
	asl.l #2,d7
	add.l d7,d6
	and.w #$fe00,d6
	lea 0(a1,d6.l),a2
	move.l a2,16(a0)

	move.w cosalpha,d6
	muls sinteta,d6				cos(alpha) * sin(teta)
	move.w d6,a3

	muls cosphi,d6				cos(alpha)*sin(teta)*cos(phi)
	asr.l #5,d6
	move.w sinalpha,d7
	muls sinphi,d7				sin(alpha) * sin(phi)
	asl.l #2,d7
	add.l d7,d6
	and.w #$fe00,d6
	lea 0(a1,d6.l),a2
	move.l a2,8(a0)

	move.w a3,d6
	muls sinphi,d6				cos(alpha)*sin(teta)*sin(phi)
	asr.l #5,d6
	move.w sinalpha,d7
	muls cosphi,d7				sin(alpha) * cos(phi)
	asl.l #2,d7
	sub.l d7,d6
	and.w #$fe00,d6
	lea 0(a1,d6.l),a2
	move.l a2,20(a0)		

	rts
matrix
	dcb.l 3*3,0				la matrice de rotation

*-------------> les angles de rotations de la spheres
alpha	dc.w 0
teta	dc.w 0
phi	dc.w 0

*-------------> tables des cosinus & sinus 
table_cosinus
	incbin table_sinus.dat
table_sinus=table_cosinus+90*2

*-------------> 3d -> 2d
compute_all_dots
	lea object_dots_coord(pc),a1

	lea computed_dots(pc),a3
	move.w #nb_points-1,d0			nb_points à afficher
compute_dot
	movem.w (a1)+,d1-d3			coordonnées du point

	lea matrix(pc),a0			début matrice de rotation

	movem.l (a0)+,a4-a6			1ère colonne
	move.w 0(a4,d1.w),d4
	add.w 0(a5,d2.w),d4			calcul de X
	add.w 0(a6,d3.w),d4
	ext.l d4

	movem.l (a0)+,a4-a6			2ème colonne
	move.w 0(a4,d1.w),d5
	add.w 0(a5,d2.w),d5			calcul de Y
	add.w 0(a6,d3.w),d5
	ext.l d5

	movem.l (a0),a4-a6			3ème colonne
	move.w 0(a4,d1.w),d6
	add.w 0(a5,d2.w),d6			calcul de Z
	add.w 0(a6,d3.w),d6
	asr.w #8,d6
	add.w #130,d6				augmente Z

	divs d6,d4				calcul de Xe
	divs d6,d5				calcul de Ye
no_div
	add.w #160,d4				recentre le point
	add.w #97,d5

	movem.w d4-d5,(a3)			sauve coord du point
	addq.l #4,a3

	dbf d0,compute_dot			loop pour tous les points
	rts

draw_object
;	btst #14,dmaconr(a6)			attend le blitter
;	bne.s draw_object

	lea object_line(pc),a2			pointe les droites
	lea computed_dots(pc),a3		pointe les points 2d
	move.l log_coplist(pc),a4		recherche la coplist de travail
	lea 16(a4),a4
	moveq #nb_lines-1,d7
draw_fil
	movem.w (a2)+,d0/d2
	add.w d0,d0				lsl.w #2,d0
	add.w d0,d0
	add.w d2,d2				lsl.w #2,d2
	add.w d2,d2
	movem.w 0(a3,d0.w),d0-d1		X1,Y1
	movem.w 0(a3,d2.w),d2-d3		X2,Y2
	move.l a4,a0				adr coplist
	bsr draw_copper_line			trace la droite
	dbf d7,draw_fil
	rts
	
pt	macro
	dc.w \1*2,\2*2,\3*2
	endm

prout=50

object_dots_coord
	pt prout,prout,prout				0
	pt prout,prout,-prout				1
	pt prout,-prout,-prout				2
	pt prout,-prout,prout				3
	pt -prout,prout,prout				4
	pt -prout,prout,-prout				5
	pt -prout,-prout,-prout				6
	pt -prout,-prout,prout				7

object_line
	dc.w 0,1,1,2,2,3,3,0
	dc.w 4,5,5,6,6,7,7,4
	dc.w 0,4,1,5,2,6,3,7

computed_dots
	dcb.w 2*nb_points,0

*------------------------> tracé de droite façon Bresenham dans la coplist
*------------------------> line(d0,d1)-(d2,d3),a0
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
	lea table_color(pc),a1			pointe la table des couleurs

do_DX
	moveq #4,INCX
	sub.w d0,d2				calcule de DX
	bge.s do_DY				et de INCX
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
	dc.w $000,$100,$200,$300,$400,$500,$600,$700,$800,$900
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

	CNOP 0,4
blank_line
	dcb.l NB_MOVE,color00<<16

	section fae,data_c
coplist1
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

coplist2
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

