
*	Cube En Gels Vectors 3d   (c) 1992 Sync/The Special Brothers
*	-------------------------------------------------------------->

OFFSET=200
NB_POINT=9					nb de point par spline
ZOOM=1200

	opt O+,NOCHKBIT,C+

	incdir "asm:sources/"
	incdir "asm/.s/Demos/Gels_Vectors/"
	incdir "asm:songs/small"
	include "registers.i"


	
	section main,code

	KILL_SYSTEM do_gels
	moveq #0,d0
	rts

do_gels
	lea data_base(pc),a5
	lea _CustomBase,a6

	move.l #vbl,$6c.w
	move.l #coplist,cop1lc(a6)
	clr.w copjmp1(a6)

	jsr mt_init

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

	WAIT_LMB_DOWN
	jsr mt_end
	RESTORE_SYSTEM

*----------------------------> la vbl
vbl
	SAVE_REGS
	jsr mt_music
	lea data_base(pc),a5
	lea $dff000,a6

	bsr do_sprites_mvt			bouge les sprites

	bsr.s flip_screen			échange des écrans
	bsr do_gels_mvt				mvt en gels du cube
	bsr compute_spline			calcule les splines
	bsr rotate_point			3d -> 2d
	bsr display_line			affiche le cube
	bsr fill_screen				rempli le cube

	VBL_SIZE color00,$fff

	move.w #$0020,intreq(a6)
	RESTORE_REGS
	rte

*----------------------------> double buffering et éffaçage
flip_screen
	movem.l log_screen(pc),d0-d1
	exg d0,d1
	movem.l d0-d1,log_screen-data_base(a5)

	WAIT_BLITTER
	move.l d0,bltdpt(a6)			efface le log_screen
	moveq #0,d0				au passage
	move.w d0,bltdmod(a6)
	move.w #$0100,bltcon0(a6)
	move.w d0,bltcon1(a6)
	move.w #160*4<<6+10,bltsize(a6)		efface le cube uniquement

	moveq #20,d0

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
	WAIT_BLITTER

	lea 20*160*4-2(a2),a2			pointe l'avant derniere ligne de
	move.l a2,bltapt(a6)			l'écran
	move.l a2,bltdpt(a6)
	moveq #0,d0
	move.l d0,bltamod(a6)
	move.l #$09f00012,bltcon0(a6)
	move.w #160*4<<6+10,bltsize(a6)
	rts	

*----------------------------> routine qui donne au cube un air de gels
do_gels_mvt
	move.w gels_mvt_ptr(pc),d0
	lea table_gels_mvt(pc),a0
	move.w 0(a0,d0.w),d1

	addq.w #2,d0
	and.w #$7f<<1,d0
	move.w d0,gels_mvt_ptr-data_base(a5)

	move.w d1,d2					modifie le haut du
	add.w #OFFSET,d1				cube
	move.w d1,table_spline1+2-data_base(a5)
	move.w d1,table_spline2+8-data_base(a5)
	move.w d1,table_spline3+2-data_base(a5)
	move.w d1,table_spline4+8-data_base(a5)

	move.w d2,d1					modifie les splines
	asr.w #1,d1
	move.w d1,d2
	add.w #200,d2
	move.w d2,table_spline1+12-data_base(a5)
	move.w d2,table_spline1+16-data_base(a5)
	move.w d2,table_spline2+16-data_base(a5)
	move.w d2,table_spline4+12-data_base(a5)

	neg.w d2
	move.w d2,table_spline2+12-data_base(a5)
	move.w d2,table_spline3+12-data_base(a5)
	move.w d2,table_spline3+16-data_base(a5)
	move.w d2,table_spline4+16-data_base(a5)

	add.w #200+OFFSET,d1

	move.w d1,table_spline1+14-data_base(a5)	modifie les milieu
	move.w d1,table_spline2+14-data_base(a5)	moyenne
	move.w d1,table_spline3+14-data_base(a5)
	move.w d1,table_spline4+14-data_base(a5)

	lea table_gels_little_mvt(pc),a0
	lea little_ptr(pc),a1
	lea point_coord(pc),a2
	lea table_spline1(pc),a3
	move.w #$7f<<1,d7

; little_mvt spline1
	movem.w (a1)+,d1-d4			récupère les ptr
	addq.b #6,d1				augmente les ptr
	addq.b #8,d2
	addq.b #2,d3
	addq.b #8,d4
	and.b d7,d1				fait gâfe que ça sorte pas
	and.b d7,d2
	and.b d7,d3
	and.b d7,d4
	movem.w d1-d4,-4*2(a1)			sauve les ptr

	move.w 0(a0,d1.w),d1			récupère l'offset
	add.w (a2)+,d1				ajoute coord du point
	move.w 0(a0,d2.w),d2
	add.w (a2),d2
	move.w 0(a0,d3.w),d3
	add.w -2(a2),d3
	move.w 0(a0,d4.w),d4
	add.w (a2)+,d4

	move.w d1,(a3)				sauve les coord des points
	move.w d2,4(a3)
	move.w d3,6(a3)
	move.w d4,10(a3)

; little_mvt spline2
	lea spline_SIZEOF(a3),a3
	movem.w (a1)+,d1-d4			récupère les ptr
	addq.b #2,d1				augmente les ptr
	addq.b #8,d2
	addq.b #4,d3
	addq.b #6,d4
	and.b d7,d1				fait gâfe que ça sorte pas
	and.b d7,d2
	and.b d7,d3
	and.b d7,d4
	movem.w d1-d4,-4*2(a1)			sauve les ptr

	move.w 0(a0,d1.w),d1			récupère l'offset
	add.w (a2)+,d1				ajoute coord du point
	move.w 0(a0,d2.w),d2
	add.w (a2),d2
	move.w 0(a0,d3.w),d3
	add.w -2(a2),d3
	move.w 0(a0,d4.w),d4
	add.w (a2)+,d4

	move.w d1,(a3)				sauve les coord des points
	move.w d2,4(a3)
	move.w d3,6(a3)
	move.w d4,10(a3)

; little_mvt spline3
	lea spline_SIZEOF(a3),a3
	movem.w (a1)+,d1-d4			récupère les ptr
	addq.b #4,d1				augmente les ptr
	addq.b #2,d2
	addq.b #6,d3
	addq.b #8,d4
	and.b d7,d1				fait gâfe que ça sorte pas
	and.b d7,d2
	and.b d7,d3
	and.b d7,d4
	movem.w d1-d4,-4*2(a1)			sauve les ptr

	move.w 0(a0,d1.w),d1			récupère l'offset
	add.w (a2)+,d1				ajoute coord du point
	move.w 0(a0,d2.w),d2
	add.w (a2),d2
	move.w 0(a0,d3.w),d3
	add.w -2(a2),d3
	move.w 0(a0,d4.w),d4
	add.w (a2)+,d4

	move.w d1,(a3)				sauve les coord des points
	move.w d2,4(a3)
	move.w d3,6(a3)
	move.w d4,10(a3)

; little_mvt spline4
	lea spline_SIZEOF(a3),a3
	movem.w (a1)+,d1-d4			récupère les ptr
	addq.b #4,d1				augmente les ptr
	addq.b #6,d2
	addq.b #8,d3
	addq.b #2,d4
	and.b d7,d1				fait gâfe que ça sorte pas
	and.b d7,d2
	and.b d7,d3
	and.b d7,d4
	movem.w d1-d4,-4*2(a1)			sauve les ptr

	move.w 0(a0,d1.w),d1			récupère l'offset
	add.w (a2)+,d1				ajoute coord du point
	move.w 0(a0,d2.w),d2
	add.w (a2),d2
	move.w 0(a0,d3.w),d3
	add.w -2(a2),d3
	move.w 0(a0,d4.w),d4
	add.w (a2)+,d4

	move.w d1,(a3)				sauve les coord des points
	move.w d2,4(a3)
	move.w d3,6(a3)
	move.w d4,10(a3)

	rts

*----------------------------> routine qui fait bouger les sprites
do_sprites_mvt
	lea table_sprite_mvt(pc),a0
	move.w sprite_mvt_ptr(pc),d0
	move.l 0(a0,d0.w),d1

	move.l d1,sprite0			met position du sprite
	move.l d1,sprite1
	move.l d1,sprite2
	move.l d1,sprite3
	move.l d1,sprite4
	move.l d1,sprite5
	move.l d1,sprite6
	move.l d1,sprite7
	addq.b #8,sprite1+1			et décale de 16 pixels
	add.b #16,sprite2+1
	add.b #24,sprite3+1
	add.b #32,sprite4+1
	add.b #40,sprite5+1
	add.b #48,sprite6+1
	add.b #56,sprite7+1

	addq.w #4,d0
	and.w #$7f<<2,d0
	move.w d0,sprite_mvt_ptr-data_base(a5)
	rts

*----------------------------> routine qui calcule les splines

	rsreset
A_X	rs.w 1				structure de la table des points
A_Y	rs.w 1				d'une spline
A_Z	rs.w 1

B_X	rs.w 1
B_Y	rs.w 1
B_Z	rs.w 1

Q_X	rs.w 0
P_X	rs.w 1				il y en a 4 en tout
Q_Y	rs.w 0
P_Y	rs.w 1
Q_Z	rs.w 0
P_Z	rs.w 1
spline_SIZEOF	rs.w 0

compute_spline
	lea table_spline1(pc),a1		table des points A,B,P,Q
	lea table_3D_point(pc),a2		table de stockage Z,X,Y
	bsr.s do_spline

	lea spline_SIZEOF(a1),a1		répète 4 fois car il y a
	bsr.s do_spline				4 splines

	lea spline_SIZEOF(a1),a1
	bsr.s do_spline
	
	lea spline_SIZEOF(a1),a1

do_spline
	lea T_Power(pc),a0			table des T précalculés
	moveq #NB_POINT-1-2,d0

	movem.w (a1),d6-d7			A_X
	move.w A_Z(a1),(a2)
	movem.w d6-d7,2(a2)
	addq.l #6,a2

loop_spline
	movem.w (a0)+,d1-d4			les facteurs des points

	move.w (a1),d5				calcule de M(T)_X   A_X
	muls d1,d5
	move.w P_X(a1),d6
	muls d2,d6
	add.l d6,d5
	move.w Q_X(a1),d6
	muls d3,d6
	add.l d6,d5
	move.w B_X(a1),d6
	muls d4,d6
	add.l d6,d5
	swap d5
	rol.l #1,d5

	move.w A_Y(a1),d6			calcule de M(T)_Y
	muls d1,d6
	move.w P_Y(a1),d7
	muls d2,d7
	add.l d7,d6
	move.w Q_Y(a1),d7
	muls d3,d7
	add.l d7,d6
	move.w B_Y(a1),d7
	muls d4,d7
	add.l d7,d6
	swap d6
	rol.l #1,d6

	muls A_Z(a1),d1				calcule de M(T)_Z
	muls P_Z(a1),d2
	muls Q_Z(a1),d3
	muls B_Z(a1),d4
	add.l d2,d1
	add.l d3,d1
	add.l d4,d1
	swap d1
	rol.l #1,d1

	movem.w d1/d5/d6,(a2)			sauve les coord du point
	addq.l #6,a2				Z,X,Y

	dbf d0,loop_spline			boucle pour tous les points

	movem.w B_X(a1),d6-d7			met le point B
	move.w B_Z(a1),(a2)
	movem.w d6-d7,2(a2)
	addq.l #6,a2
	rts

*----------------------------> routine qui rotate les points 3d et les met en 2D

rotate_point
	move.w #$6a1d,d1			$7fff * COS 34
	move.w #$b86d,d2			$7fff * SIN 34

	lea table_3D_point(pc),a0		points 3d ( entrée )
	lea table_2D_point(pc),a1		points 2d ( sortie )
	moveq #NB_POINT*4-1,d0

loop_compute_2D_point
	movem.w (a0)+,d3-d5			coord 3d du point : Z,X,Y

	move.w d3,d6				les Z
	move.w d4,d7				les X

	muls d1,d4				X*cos Ø
	muls d2,d3				Y*sin Ø
	sub.l d3,d4				le nouveau X après rotation
	swap d4
	rol.l #1,d4
	ext.l d4

	muls d2,d7				X*sin Ø
	muls d1,d6				Z*cos Ø
	add.l d6,d7				le nouveau Z après rotation
	swap d7
	rol.l #1,d7

	moveq #8,d3
	asl.l d3,d4				multiplie X° et Y° par D
	asl.l d3,d5

	add.w #ZOOM,d7
	beq.s no_div
	divs d7,d4				Xe=X°/Z°
	divs d7,d5				Ye=Y°/Z°
no_div
	add.w #84,d4				recentre l'objet
	sub.w #11,d5

	movem.w d4/d5,(a1)			sauve les coord du point 2d
	addq.l #4,a1

	dbf d0,loop_compute_2D_point
	rts


*----------------------------> routine qui affiche le cube (splines et droites)

; bpl1=0
; bpl2=20
; bpl3=40
; bpl4=60

display_line
	bsr DrawLine_Init
	
;	move.w #Width*Depth,bltdmod(a6)		largeur de l'image
;	move.w #$8000,bltadat(a6)		Style du point

	lea table_2D_point(pc),a1		table des points 2d
	move.l log_screen(pc),a2		1er écran

*** trace la spline 1
	moveq #NB_POINT-1-1,d7
	lea 20(a2),a3				a3=2ème bpl
	lea 60(a2),a4				a4=4ème bpl
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
	lea 40(a2),a3				a3=3ème bpl
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
	lea 20(a2),a3				a3=2ème bpl
draw_spline4
	movem.w (a1),d0-d3
	move.l a3,a0
	addq.l #4,a1
	bsr DrawLine
	dbf d7,draw_spline4

	lea table_2D_point(pc),a1
*** trace la droite 1
	movem.w (a1),d0-d1
	movem.w NB_POINT*4+(NB_POINT-1)*4(a1),d2-d3
	move.l a2,a0
	bsr DrawLine
	movem.w (a1),d0-d1
	movem.w NB_POINT*4+(NB_POINT-1)*4(a1),d2-d3
	lea 20(a2),a0
	bsr DrawLine
	movem.w (a1),d0-d1
	movem.w NB_POINT*4+(NB_POINT-1)*4(a1),d2-d3
	lea 60(a2),a0
	bsr DrawLine

*** trace la droite 2
	movem.w (NB_POINT-1)*4(a1),d0-d3
	lea 40(a2),a0
	bsr DrawLine

*** trace la droite 3
	movem.w NB_POINT*4+(NB_POINT-1)*4(a1),d0-d3
	move.l a2,a0
	bsr DrawLine
	movem.w NB_POINT*4+(NB_POINT-1)*4(a1),d0-d3
	lea 20(a2),a0
	bsr DrawLine
	movem.w NB_POINT*4+(NB_POINT-1)*4(a1),d0-d3
	lea 40(a2),a0
	bsr DrawLine

*** trace la droite 4
	movem.w NB_POINT*4(a1),d0-d1
	movem.w NB_POINT*4*2+(NB_POINT-1)*4(a1),d2-d3
	lea 60(a2),a0
	bsr.s DrawLine

*** trace la droite 5
	movem.w NB_POINT*4*2(a1),d0-d1
	movem.w NB_POINT*4*3+(NB_POINT-1)*4(a1),d2-d3
	move.l a2,a0
	bsr.s DrawLine
	movem.w NB_POINT*4*2(a1),d0-d1
	movem.w NB_POINT*4*3+(NB_POINT-1)*4(a1),d2-d3
	lea 20(a2),a0
	bsr.s DrawLine

*** trace la droite 6
	movem.w NB_POINT*4*2+(NB_POINT-1)*4(a1),d0-d3
	lea 40(a2),a0
	bsr.s DrawLine
	movem.w NB_POINT*4*2+(NB_POINT-1)*4(a1),d0-d3
	lea 60(a2),a0
	bsr.s DrawLine
		
*** trace la droite 7
	movem.w NB_POINT*4*3+(NB_POINT-1)*4(a1),d0-d1
	movem.w (a1),d2-d3
	move.l a2,a0
	bsr.s DrawLine
	
*** trace la droite 8
	movem.w NB_POINT*4*3(a1),d0-d1
	movem.w (NB_POINT-1)*4(a1),d2-d3
	lea 20(a2),a0
	bsr.s DrawLine
	movem.w NB_POINT*4*3(a1),d0-d1
	movem.w (NB_POINT-1)*4(a1),d2-d3
	lea 40(a2),a0
	bsr.s DrawLine
	movem.w NB_POINT*4*3(a1),d0-d1
	movem.w (NB_POINT-1)*4(a1),d2-d3
	lea 60(a2),a0

*----------------------------> routine de tracé de droite (d0,d1)-(d2,d3),a0

Width=20				taille en octets
Heigth=160				hauteur en pixels
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

	WAIT_BLITTER
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
	WAIT_BLITTER

	moveq #Width*Depth,d0
	move.w d0,bltcmod(a6)			\ largeur de l'image
	move.w d0,bltdmod(a6)			/
	moveq #-1,d0
	move.w d0,bltbdat(a6)			masque de la droite
	move.l d0,bltafwm(a6)			masque sur A
	move.w #$8000,bltadat(a6)		Style du point
	rts	

data_base
T_Power
	incbin "T_Power.dat"

table_gels_mvt
	incbin "gels_mvt.dat"
gels_mvt_ptr
	dc.w 0
table_sprite_mvt
	incbin "sprite_mvt.dat"
sprite_mvt_ptr
	dc.w $7f<<2				pointe avant car db-buffering

table_gels_little_mvt
	incbin "gels_little_mvt.dat"
little_ptr
	dcb.w 8*2,0
point_coord
	dc.w 200,200				X et Z
	dc.w -200,200
	dc.w -200,-200
	dc.w 200,-200

pt	macro
	dc.w \1,\2,\3
	endm

table_spline1
	pt 200,0+OFFSET,200			A
	pt 200,400+OFFSET,200			B
	pt 0,0,0				P et Q
table_spline2
	pt -200,400+OFFSET,200			B
	pt -200,0+OFFSET,200			A
	pt 0,0,0				P et Q
table_spline3
	pt -200,0+OFFSET,-200			A
	pt -200,400+OFFSET,-200			B
	pt 0,0,0				P et Q
table_spline4
	pt 200,400+OFFSET,-200			B
	pt 200,0+OFFSET,-200			A
	pt 0,0,0				P et Q

table_3D_point
	dcb.b NB_POINT*6*4
table_2D_point
	dcb.b NB_POINT*4*4,0

log_screen
	dc.l bpl1
phy_screen
	dc.l bpl2

	include "TMC_Replay.s"
	include "Song.s"


	section go_to_chip,data_c

bpl1		dcb.w 10*160*4,0
bpl2		dcb.w 10*160*4,0
fake_bpl	dcb.b 12,$0

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
	dc.w fmode,0
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

	dc.w $8b0f,$fffe
	dc.w diwstrt,$8bd1			écran de 160*160
	dc.w diwstop,$2bc1
	dc.w ddfstrt,$0060
	dc.w ddfstop,$00a8
	dc.w bplcon0,$4200			4 bitplans couleurs
	dc.w bpl1mod,20*4-20			les plans sont entrelacés
	dc.w bpl2mod,20*4-20
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

	dc.w color04,$909
	dc.w color07,$a0a
	dc.w color08,$b0b
	dc.w color10,$c0c
	dc.w color11,$d0d
	dc.w color12,$e0e
	dc.w color14,$f0f

	dc.w $c80f,$fffe
	dc.w color00,$a86
	dc.w color04,$707
	dc.w color07,$808
	dc.w color08,$909
	dc.w color10,$a0a
	dc.w color11,$b0b
	dc.w color12,$c0c
	dc.w color14,$d0d

	dc.l $fffffffe

	include "Samples.s"