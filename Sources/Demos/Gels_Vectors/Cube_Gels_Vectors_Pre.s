
*	Cube En Gels Vectors 3d   (c) 1992 Sync/The Special Brothers
*	-------------------------------------------------------------->

OFFSET=200
NB_POINT=6					nb de point par spline

	opt O+

	incdir "asm:" "asm:Gels_Vectors/"
	include "sources/registers.i"
	
	section main,code_f

	bsr save_all

	lea data_base(pc),a5
	lea $dff000,a6
	
	move.w #$7fff,d0
	move.w d0,intena(a6)
	move.w d0,dmacon(a6)
	
	move.l #vbl,$6c.w
	move.l #coplist,cop1lc(a6)
	move.w #0,copjmp1(a6)

	bsr mt_init

	lea $dff000,a6
	bsr DrawLine_Init

	move.l #fake_bpl,d0
	move.w d0,f_bpl1L
	swap d0
	move.w d0,f_bpl1H

	lea sprite0,a0
	lea spr0H,a1
	moveq #8-1,d0
loop_init_spr
	move.l a0,d1
	move.w d1,4(a1)
	swap d1
	move.w d1,(a1)
	addq.l #8,a1
	lea sprite1-sprite0(a0),a0
	dbf d0,loop_init_spr

	move.w #$87e0,dmacon(a6)		blitter + copper + sprites
	move.w #$c020,intena(a6)		IT vbl autorisée

mickey
	btst #6,ciaapra
	bne.s mickey
	bsr mt_end
	bsr.s restore_all
	moveq #0,d0
	rts

	include "sources/save_all.s"
	include "sources/fastplay.s"

*----------------------------> la vbl
vbl
	bsr mt_music
	lea data_base(pc),a5
	lea $dff000,a6

	bsr.s flip_screen
	bsr display_line			affiche le cube
	bsr fill_screen				rempli le cube

	add.l #NB_POINT*4*4,table_2D_ptr-data_base(a5)
	move.l table_2D_ptr(pc),d0
	cmp.l #table_2D_point_end,d0
	bne.s not_end_table_2D
	move.l #table_2D_point,table_2D_ptr-data_base(a5)
not_end_table_2D

	btst #10,potgor(a6)
	bne.s no_color
	move.w #$f,color00(a6)
no_color

	move.w #$0020,intreq(a6)
	rte

*----------------------------> double buffering et éffaçage
flip_screen
	movem.l log_screen(pc),d0-d1
	exg d0,d1
	movem.l d0-d1,log_screen-data_base(a5)

	move.l d0,bltdpt(a6)			efface le log_screen
	moveq #0,d0				au passage
	move.w d0,bltdmod(a6)
	move.w #$0100,bltcon0(a6)
	move.w d0,bltcon1(a6)
	move.w #85*4<<6+6,bltsize(a6)		efface le cube uniquement

	moveq #12,d0

	move.w d1,bpl1L				installation des pointeurs
	add.w d0,d1
	move.w d1,bpl2L
	add.w d0,d1
	move.w d1,bpl3L
	add.w d0,d1
	move.w d1,bpl4L
	swap d1
	move.w d1,bpl1H
	move.w d1,bpl2H
	move.w d1,bpl3H
	move.w d1,bpl4H

	rts

*----------------------------> routine qui rempli le cube
fill_screen
	btst #14,dmaconr(a6)
	bne.s fill_screen

	lea 12*85*4-2(a2),a2			pointe l'avant derniere ligne de
	move.l a2,bltapt(a6)			l'écran
	move.l a2,bltdpt(a6)
	moveq #0,d0
	move.l d0,bltamod(a6)
	move.l #$09f00012,bltcon0(a6)
	move.w #85*4<<6+6,bltsize(a6)

	btst #10,potgor(a6)
	bne.s fill_screen_wait
	move.w #$ff,color00(a6)

fill_screen_wait
	btst #14,dmaconr(a6)
	bne.s fill_screen_wait

	rts	


*----------------------------> routine qui affiche le cube (splines et droites)

bpl1=0
bpl2=12
bpl3=24
bpl4=36

display_line
	btst #14,dmaconr(a6)
	bne.s display_line

	move.w #Width*Depth,bltdmod(a6)		largeur de l'image
	move.w #$8000,bltadat(a6)		Style du point

	move.l table_2D_ptr(pc),a1		table des points 2d
	move.l log_screen(pc),a2		1er écran

*** trace la spline 1
	moveq #NB_POINT-1-1,d7
	lea bpl2(a2),a3				a3=2ème bpl
	lea bpl4(a2),a4				a4=4ème bpl
draw_spline1
	movem.w (a1),d0-d3
	move.l a3,a0
	bsr DrawLine
	movem.w (a1),d0-d3
	move.l a4,a0
	bsr DrawLine
	addq.l #4,a1
	dbf d7,draw_spline1
	addq.l #4,a1

*** trace la spline 2
	moveq #NB_POINT-1-1,d7
	lea bpl3(a2),a3				a3=3ème bpl
draw_spline2
	movem.w (a1),d0-d3
	move.l a3,a0
	bsr DrawLine
	movem.w (a1),d0-d3
	move.l a4,a0
	bsr DrawLine
	addq.l #4,a1
	dbf d7,draw_spline2
	addq.l #4,a1

*** trace la spline 3
	moveq #NB_POINT-1-1,d7
draw_spline3
	movem.w (a1),d0-d3
	move.l a3,a0
	bsr DrawLine
	addq.l #4,a1
	dbf d7,draw_spline3
	addq.l #4,a1

*** trace la spline 4
	moveq #NB_POINT-1-1,d7
	lea bpl2(a2),a3				a3=2ème bpl
draw_spline4
	movem.w (a1),d0-d3
	move.l a3,a0
	addq.l #4,a1
	bsr DrawLine
	dbf d7,draw_spline4

	move.l table_2D_ptr(pc),a1
*** trace la droite 1
	movem.w (a1),d0-d1
	movem.w NB_POINT*4+(NB_POINT-1)*4(a1),d2-d3
	move.l a2,a0
	bsr DrawLine
	movem.w (a1),d0-d1
	movem.w NB_POINT*4+(NB_POINT-1)*4(a1),d2-d3
	lea bpl2(a2),a0
	bsr DrawLine
	movem.w (a1),d0-d1
	movem.w NB_POINT*4+(NB_POINT-1)*4(a1),d2-d3
	lea bpl4(a2),a0
	bsr DrawLine

*** trace la droite 2
	movem.w (NB_POINT-1)*4(a1),d0-d3
	lea bpl3(a2),a0
	bsr DrawLine

*** trace la droite 3
	movem.w NB_POINT*4+(NB_POINT-1)*4(a1),d0-d3
	move.l a2,a0
	bsr DrawLine
	movem.w NB_POINT*4+(NB_POINT-1)*4(a1),d0-d3
	lea bpl2(a2),a0
	bsr DrawLine
	movem.w NB_POINT*4+(NB_POINT-1)*4(a1),d0-d3
	lea bpl3(a2),a0
	bsr DrawLine

*** trace la droite 4
	movem.w NB_POINT*4(a1),d0-d1
	movem.w NB_POINT*4*2+(NB_POINT-1)*4(a1),d2-d3
	lea bpl4(a2),a0
	bsr.s DrawLine

*** trace la droite 5
	movem.w NB_POINT*4*2(a1),d0-d1
	movem.w NB_POINT*4*3+(NB_POINT-1)*4(a1),d2-d3
	move.l a2,a0
	bsr.s DrawLine
	movem.w NB_POINT*4*2(a1),d0-d1
	movem.w NB_POINT*4*3+(NB_POINT-1)*4(a1),d2-d3
	lea bpl2(a2),a0
	bsr.s DrawLine

*** trace la droite 6
	movem.w NB_POINT*4*2+(NB_POINT-1)*4(a1),d0-d3
	lea bpl3(a2),a0
	bsr.s DrawLine
	movem.w NB_POINT*4*2+(NB_POINT-1)*4(a1),d0-d3
	lea bpl4(a2),a0
	bsr.s DrawLine
		
*** trace la droite 7
	movem.w NB_POINT*4*3+(NB_POINT-1)*4(a1),d0-d1
	movem.w (a1),d2-d3
	move.l a2,a0
	bsr.s DrawLine
	
*** trace la droite 8
	movem.w NB_POINT*4*3(a1),d0-d1
	movem.w (NB_POINT-1)*4(a1),d2-d3
	lea bpl2(a2),a0
	bsr.s DrawLine
	movem.w NB_POINT*4*3(a1),d0-d1
	movem.w (NB_POINT-1)*4(a1),d2-d3
	lea bpl3(a2),a0
	bsr.s DrawLine
	movem.w NB_POINT*4*3(a1),d0-d1
	movem.w (NB_POINT-1)*4(a1),d2-d3
	lea bpl4(a2),a0

*----------------------------> routine de tracé de droite (d0,d1)-(d2,d3),a0

Width=12				taille en octets
Heigth=85				hauteur en pixels
Depth=4					profondeur en bitplan
ONEDOT=1				traçage avec un point par ligne
MINTERM=$4a				minterm de la droite

DrawLine
	cmp.w d1,d3
	bgt.s DrawLine_Ok
	beq no_line

	exg d0,d2
	exg d1,d3
DrawLine_Ok
	sub.w d0,d2				d2=deltaX
	sub.w d1,d3				d3=deltaY
	subq.w #1,d3

	moveq #0,d4
	ror.w #4,d0				\
	move.b d0,d4				 > d0=décalage
	and.w #$f000,d0				/

	add.b d4,d4				d4=adr en octets sur X
	add.w d1,d1				d1=d1*2 car table de mots
	add.w Table_Mulu_Line(pc,d1.w),d4	d4=d1*Width*Depth+d4
	lea 0(a0,d4.w),a0			recherche 1er mot de la droite
	move.w d0,d4				sauvegarde du décalage
	or.w #$0b<<8|MINTERM,d4			source + masque
find_octant	
	moveq #0,d1
	tst.w d2
	bpl.s X1_inf_X2
	neg.w d2
	moveq #4,d1
X1_inf_X2
	cmp.w d2,d3
	bpl.s DY_sup_DX
	or.b #16,d1
	bra.s octant_found
DY_sup_DX
	exg d2,d3
	add.w d1,d1
octant_found

	IFEQ ONEDOT
	addq.b #1,d1				commute en mode LINE
	ELSEIF
	addq.b #3,d1				commute en mode LINE + ONEDOT
	ENDC

	or.w d0,d1				rajoute l'octant
	
	add.w d3,d3				4*Pdelta
	add.w d3,d3
	add.w d2,d2				2*Gdelta

Line_Wait_Blitter
	btst #14,dmaconr(a6)
	bne.s Line_Wait_Blitter

	move.w d3,bltbmod(a6)
	sub.w d2,d3				4*Pdelta-2*Gdelta
	bge.s no_SIGNFLAG
	or.w #$40,d1
no_SIGNFLAG
	move.w d1,bltcon1(a6)
	move.w d3,bltapt+2(a6)
	sub.w d2,d3				4*Pdelta-4*Gdelta
	move.w d3,bltamod(a6)

	move.w d4,bltcon0(a6)

	move.l a0,bltcpt(a6)			\ pointeur sur 1er mot droite
	move.l a0,bltdpt(a6)			/

	addq.w #1<<1,d2				(2*Gdelta+1)<<1
	lsl.w #5,d2				(2*Gdelta+1)<<6
	addq.w #2,d2				(2*Gdelta+1)<<6+2
	move.w d2,bltsize(a6)			traçage de la droite
no_line
	rts

Table_Mulu_Line
MuluCount set 0
	rept Heigth
	dc.w MuluCount*Width*Depth
MuluCount set MuluCount+1
	endr

DrawLine_Init
	btst #14,dmaconr(a6)
	bne.s DrawLine_Init

	moveq #Width*Depth,d0
	move.w d0,bltcmod(a6)			\ largeur de l'image
	move.w d0,bltdmod(a6)			/
	moveq #-1,d0
	move.w d0,bltbdat(a6)			masque de la droite
	move.l d0,bltafwm(a6)			masque sur A
	move.w #$8000,bltadat(a6)		Style du point
	rts	

data_base
table_sprite_mvt
	incbin "sprite_mvt.dat"
sprite_mvt_ptr
	dc.w $7f<<2				pointe avant car db-buffering

table_2D_ptr
	dc.l table_2D_point
log_screen
	dc.l bpl_1
phy_screen
	dc.l bpl_2
table_2D_point
	incbin "dh1:gels_precalcul.dat"
table_2D_point_end

	section go_to_chip,data_c

bpl_1		dcb.w 6*85*4,0
bpl_2		dcb.w 6*85*4,0
fake_bpl	dcb.w 6,$0

sprite0
	dc.w $0
	dc.w $0
	include "mainspr0.s"
	dc.l 0
sprite1
	dc.w $0
	dc.w $0
	include "mainspr1.s"
	dc.l 0
sprite2
	dc.w $0
	dc.w $0
	include "mainspr2.s"
	dc.l 0
sprite3
	dc.w $0
	dc.w $0
	include "mainspr3.s"
	dc.l 0
sprite4
	dc.w $0
	dc.w $0
	include "mainspr4.s"
	dc.l 0
sprite5
	dc.w $0
	dc.w $0
	include "mainspr5.s"
	dc.l 0
sprite6
	dc.w $0
	dc.w $0
	include "mainspr6.s"
	dc.l 0
sprite7
	dc.w $0
	dc.w $0
	include "mainspr7.s"
	dc.l 0

coplist
	dc.w diwstrt,$20f1			affiche un faux bpl pour
	dc.w diwstop,$8ba1			les sprites
	dc.w ddfstrt,$70
	dc.w ddfstop,$98
	dc.w bplcon0,$1200
	dc.w bplcon1,$0
	dc.w bplcon2,$3f
	dc.w bpl1mod,-12
	dc.w bpl1ptH
f_bpl1H	dc.w 0,bpl1ptL
f_bpl1L	dc.w 0
	dc.w spr0ptH				les sprites
spr0H	dc.w 0,spr0ptL
spr0L	dc.w 0
	dc.w spr1ptH
spr1H	dc.w 0,spr1ptL
spr1L	dc.w 0
	dc.w spr2ptH
spr2H	dc.w 0,spr2ptL
spr2L	dc.w 0
	dc.w spr3ptH
spr3H	dc.w 0,spr3ptL
spr3L	dc.w 0
	dc.w spr4ptH
spr4H	dc.w 0,spr4ptL
spr4L	dc.w 0
	dc.w spr5ptH
spr5H	dc.w 0,spr5ptL
spr5L	dc.w 0
	dc.w spr6ptH
spr6H	dc.w 0,spr6ptL
spr6L	dc.w 0
	dc.w spr7ptH
spr7H	dc.w 0,spr7ptL
spr7L	dc.w 0

	dc.w color00,$ca8			couleur du fond
	dc.w color17,$ba9			couleur pour le sprite (la main)
	dc.w color18,$987
	dc.w color19,$765
	dc.w color21,$ba9
	dc.w color22,$987
	dc.w color23,$765
	dc.w color25,$ba9
	dc.w color26,$987
	dc.w color27,$765
	dc.w color29,$ba9
	dc.w color30,$987
	dc.w color31,$765

	dc.w $8b0f,$fffe
	dc.w diwstrt,$8bf1			écran de 160*160
	dc.w diwstop,$e0a1
	dc.w ddfstrt,$0070
	dc.w ddfstop,$0098
	dc.w bplcon0,$4200			4 bitplans couleurs
	dc.w bpl1mod,12*3			les plans sont entrelacés
	dc.w bpl2mod,12*3
	dc.w bplcon0,$4200
	dc.w bpl1ptH				les pointeurs vidéos sur
bpl1H	dc.w 0,bpl1ptL				l'écran
bpl1L	dc.w 0
	dc.w bpl2ptH
bpl2H	dc.w 0,bpl2ptL
bpl2L	dc.w 0
	dc.w bpl3ptH
bpl3H	dc.w 0,bpl3ptL
bpl3L	dc.w 0
	dc.w bpl4ptH
bpl4H	dc.w 0,bpl4ptL
bpl4L	dc.w 0

	dc.w color04,$90
	dc.w color07,$a0
	dc.w color08,$b0
	dc.w color10,$c0
	dc.w color11,$d0
	dc.w color12,$e0
	dc.w color14,$f0

	dc.w $c80f,$fffe
	dc.w color00,$b97
	dc.w color04,$80
	dc.w color07,$90
	dc.w color08,$a0
	dc.w color10,$b0
	dc.w color11,$c0
	dc.w color12,$c0
	dc.w color14,$e0

	dc.w $c90f,$fffe
	dc.w color00,$a86
	dc.w color04,$70
	dc.w color07,$80
	dc.w color08,$90
	dc.w color10,$a0
	dc.w color11,$b0
	dc.w color12,$c0
	dc.w color14,$d0

	dc.l $fffffffe

mt_data
	incbin "dh0:music/RollMops/baramine/mod.mother-nature"
