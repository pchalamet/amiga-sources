
*			Blenk Cube 3d en 2 bpl
*			----------------------

* structure d'une face d'un cube
	rsreset
point1	rs.w 1				offset point 1
point2	rs.w 1				offset point 2
point3	rs.w 1				offset point 3
point4	rs.w 1				offset point 4
bpl	rs.w 1				ds quel bpl se trouve la face
Red	rs.w 1				composantes RGB de la face
Green	rs.w 1
Blue	rs.w 1
face_SIZEOF	rs.w 0

ZOOM=1100
MAX=$2643

	opt NOCHKBIT

	section toto,code

	incdir "asm:"
	incdir "asm:sources/"
	incdir "asm:datas/"
	incdir "asm:Convex_Vektors"
	incdir "ram:"
	include "registers.i"

	bsr save_all

	lea $dff000,a6
	move.w #$7fff,d0
	move.w d0,intena(a6)
	move.w d0,dmacon(a6)

	move.l #vbl,$6c.w
	move.l #coplist1,cop1lc(a6)
	clr.w copjmp1(a6)
	bsr mt_init

	move.w #$87c0,dmacon(a6)
	move.w #$c020,intena(a6)

mickey
	btst #6,ciaapra
	bne.s mickey

	neg.w Fade_inc-data_base(a5)
	subq.w #1,Fade-data_base(a5)

wait_fade
	cmp.w #1,Fade-data_base(a5)
	bne.s wait_fade

exit_wait
	btst #14,dmaconr(a6)
	bne.s exit_wait

	bsr mt_end
	bsr restore_all
	moveq #0,d0
	rts

	include "save_all.s"

vbl
	bsr mt_music
	lea data_base(pc),a5
	lea $dff000,a6

	cmp.w #$f,Fade-data_base(a5)
	beq.s no_add
	subq.w #1,Slower-data_base(a5)
	bne.s no_add
	move.w #6,Slower-data_base(a5)
	move.w Fade_inc(pc),d0
	add.w d0,Fade-data_base(a5)
no_add
	bsr Setup_Screen
	moveq #-12,d0
	moveq #10,d1
	moveq #4,d2
	bsr Incrize_Angles
	bsr Compute_Matrix			calcul la matrice de rotation
	bsr Compute_Dots			points 3d -> 2d
	bsr Display_Cube			afficher le cube
	bsr Fill_Screen				rempli le cube

	btst #10,potinp(a6)
	bne.s no_RMB
	move.w #$f0f,color00(a6)
no_RMB
	move.w #$0020,intreq(a6)
	rte



********************************************************************************
************************  EFFACAGE DE L'ECRAN DE TRAVAIL  **********************
************************                                  **********************
************************      ET ECHANGE DES COPLISTS     **********************
********************************************************************************
Setup_Screen
	movem.l log_screen(pc),d0-d3		echange les ptr videos
	exg d0,d1
	exg d2,d3
	movem.l d0-d3,log_screen-data_base(a5)

	move.l d1,bpl1ptH(a6)
	add.l #40,d1
	move.l d1,bpl2ptH(a6)
	move.l d3,cop1lc(a6)
	clr.w copjmp1(a6)

	move.l d0,bltdpt(a6)			efface le log_screen
	move.l #$1000000,bltcon0(a6)
	clr.w bltdmod(a6)
	move.w #(160*2<<6)!(20),bltsize(a6)
	rts
data_base
Fade
	dc.w 0
Fade_inc
	dc.w 1
Slower
	dc.w 1
log_screen
	dc.l screen1
phy_screen
	dc.l screen2
log_coplist
	dc.l coplist1
phy_coplist
	dc.l coplist2


********************************************************************************
*************                                                       ************
*************  AUGMENTATION DES ANGLES POUR LA MATRICE DE ROTATION  ************
*************                                                       ************
********************************************************************************
Incrize_Angles
	lea Alpha(pc),a0
do_Alpha
	add.w d0,(a0)+				ajoute l'angle
	bgt.s Alpha_test			signe du résultat
	beq.s do_Teta
	add.w #1440,-2(a0)
	bra.s do_Teta
Alpha_test
	cmp.w #1440,-2(a0)
	blt.s do_Teta
	sub.w #1440,-2(a0)
do_Teta
	add.w d1,(a0)+				ajoute l'angle
	bgt.s Teta_test				signe du résultat
	beq.s do_Phi
	add.w #1440,-2(a0)
	bra.s do_Phi
Teta_test
	cmp.w #1440,-2(a0)
	blt.s do_Phi
	sub.w #1440,-2(a0)
do_Phi
	add.w d2,(a0)				ajoute l'angle
	bgt.s Phi_test				signe du résultat
	beq.s end_Angles
	add.w #1440,(a0)
	rts
Phi_test
	cmp.w #1440,(a0)
	blt.s end_Angles
	sub.w #1440,(a0)
end_Angles
	rts



********************************************************************************
*********************                                    ***********************
*********************  CALCUL DE LA MATRICE DE ROTATION  ***********************
*********************                                    ***********************
********************************************************************************
cosalpha equr d0				qq equr pour se simplifier
sinalpha equr d1				la lecture
costeta  equr d2
sinteta  equr d3
cosphi   equr d4
sinphi   equr d5

Compute_Matrix
	lea Table_Cosinus(pc),a0
	lea Table_Sinus(pc),a1

	movem.w Alpha(pc),d0-d2			va chercher les angles

	move.w 0(a1,d2.w),sinphi		sinus phi
	move.w 0(a0,d2.w),cosphi		cosinus phi

	move.w 0(a1,d1.w),sinteta		sinus teta
	move.w 0(a0,d1.w),costeta		cosinus teta

	move.w 0(a1,d0.w),sinalpha		sinus alpha
	move.w 0(a0,d0.w),cosalpha		cosinus alpha

	lea matrix(pc),a0

	move.w costeta,d6
	muls cosphi,d6				cos(teta) * cos(phi)
	swap d6
	move.w d6,(a0)

	move.w costeta,d6
	muls sinphi,d6				cos(teta) * sin(phi)
	swap d6
	move.w d6,2(a0)

	move.w sinteta,d6
	neg.w d6
	asr.w #1,d6				on perd un bit à cause du swap
	move.w d6,4(a0)				-sin(teta)

	move.w costeta,d6
	muls sinalpha,d6			cos(teta) * sin(alpha)
	swap d6
	move.w d6,10(a0)

	move.w costeta,d6
	muls cosalpha,d6			cos(teta) * cos(alpha)
	swap d6
	move.w d6,16(a0)
	
	move.w sinalpha,d6
	muls sinteta,d6				sin(alpha) * sin(teta)
	swap d6
	rol.l #1,d6
	move.w d6,a1

	muls cosphi,d6				sin(alpha)*sin(teta)*cos(phi)
	move.w cosalpha,d7
	muls sinphi,d7				cos(alpha) * sin(phi)
	sub.l d7,d6
	swap d6
	move.w d6,6(a0)

	move.w a1,d6
	muls sinphi,d6				sin(alpha)*sin(teta)*sin(phi)
	move.w cosalpha,d7
	muls cosphi,d7				cos(alpha) * cos(phi)
	add.l d7,d6
	swap d6
	move.w d6,8(a0)

	move.w cosalpha,d6
	muls sinteta,d6				cos(alpha) * sin(teta)
	swap d6
	rol.l #1,d6
	move.w d6,a1

	muls cosphi,d6				cos(alpha)*sin(teta)*cos(phi)
	move.w sinalpha,d7
	muls sinphi,d7				sin(alpha) * sin(phi)
	add.l d7,d6
	swap d6
	move.w d6,12(a0)

	move.w a1,d6
	muls sinphi,d6				cos(alpha)*sin(teta)*sin(phi)
	move.w sinalpha,d7
	muls cosphi,d7				sin(alpha) * cos(phi)
	sub.l d7,d6
	swap d6
	move.w d6,14(a0)		

	rts

matrix	dcb.w 3*3,0				la matrice de rotation
Alpha	dc.w 0
Teta	dc.w 0
Phi	dc.w 0
Table_Cosinus
	incbin "table_cosinus_720.dat"
Table_Sinus=Table_Cosinus+90*4



********************************************************************************
*************                                                        ***********
*************  TRANSFORMATIONS DES COORDONNEES 3D EN COORDONNEES 2D  ***********
*************                                                        ***********
********************************************************************************
Compute_Dots
	lea dots_3d(pc),a0			pointe les points 3d originaux
	lea dots_2d(pc),a1			pointe les points 2d
	move.w #ZOOM,d6				le zoom
	moveq #8-1,d0				8 points sur le cube
	moveq #9,d7				valeur du shift de D

loop_compute_dots
	movem.w (a0),d1-d3			coord 3d du point
	muls matrix(pc),d1
	muls matrix+2(pc),d2
	muls matrix+4(pc),d3
	add.l d3,d2
	add.l d2,d1
	swap d1
	ext.l d1
	lsl.l d7,d1				X=X*D

	movem.w (a0),d2-d4			coord 3d du point
	muls matrix+6(pc),d2
	muls matrix+8(pc),d3
	muls matrix+10(pc),d4
	add.l d4,d3
	add.l d3,d2
	swap d2					Y
	ext.l d2
	lsl.l d7,d2				Y=Y*D

	movem.w (a0)+,d3-d5			coord 3d du point
	muls matrix+12(pc),d3
	muls matrix+14(pc),d4
	muls matrix+16(pc),d5
	add.l d5,d4
	add.l d4,d3
	swap d3					Z
	add.w d6,d3				zjoute le zoom

	beq.s no_divs
	divs d3,d1				Xe=X*D/Z
	divs d3,d2				Ye=Y*D/Z
	asr.w #1,d2
no_divs
	add.w #160,d1				recentre à l'écran
	add.w #80,d2
	move.w d1,(a1)+				sauve Xe,Ye
	move.w d2,(a1)+

	dbf d0,loop_compute_dots	
	rts	



********************************************************************************
******************************                   *******************************
******************************  AFFICHE LE CUBE  *******************************
******************************                   *******************************
********************************************************************************
Display_Cube
	bsr DrawLine_Init			init le blitter

	move.l log_coplist(pc),a1
	lea color_patch-coplist1(a1),a1
	lea dots_2d(pc),a2			pointe les points 2d
	lea cube_faces(pc),a3			pointe descriptions des faces
	move.l log_screen(pc),a4		pointe l'écran de travail
	moveq #6-1,d7				6 faces pour un cube

draw_next_face
	movem.w (a3),d0/d2/d4			offset de 3 points
	movem.w 0(a2,d0.w),d0-d1		d0=X1   ,   d1=Y1
	movem.w 0(a2,d2.w),d2-d3		d2=X2   ,   d3=Y2
	movem.w 0(a2,d4.w),d4-d5		d4=X3   ,   d5=Y3
	sub.w d0,d2				(x2-x1)
	sub.w d1,d5				(y3-y1)
	muls d5,d2				(x2-x1)*(y3-y1)
	sub.w d0,d4				(x3-x1)
	sub.w d1,d3				(y2-y1)
	muls d4,d3				(x3-x1)*(y2-y1)
	sub.l d3,d2				(x2-x1)*(y3-y1)<(x3-x1)*(y2-y1)?
	bgt.s face_front			face devant si >0

	lea face_SIZEOF(a3),a3			pointe la face suivante
	dbf d7,draw_next_face
	rts					=0 => pas de face

face_front
	moveq #$f,d5
	mulu #$e,d2				calcule composante par
	divu #MAX,d2				rapport à $f
	addq.w #1,d2

	mulu Fade(pc),d2			calcule composante par
	divu d5,d2				rapport au fade

	move.w d2,d3				calcule la composante Rouge
	mulu Red(a3),d3
	divu d5,d3
	lsl.w #8,d3

	move.w d2,d4				calcule la composante Verte
	mulu Green(a3),d4
	divu d5,d4
	lsl.w #4,d4

	mulu Blue(a3),d2			calcule la composante Bleue
	divu d5,d2

	or.w d3,d2				composantes RGB de la face
	or.w d4,d2	

draw_face
	move.w bpl(a3),d6			met la couleur
	move.w d6,d0
	add.w d0,d0
	add.w d0,d0
	move.w d2,2(a1,d0.w)

	lsr.b #1,d6
	bcc.s not_in_bpl1

	movem.w (a3),d0/d2			point 1 & 2
	movem.w 0(a2,d0.w),d0-d1
	movem.w 0(a2,d2.w),d2-d3
	move.l a4,a0
	bsr DrawLine

	movem.w point2(a3),d0/d2		point 2 & 3
	movem.w 0(a2,d0.w),d0-d1
	movem.w 0(a2,d2.w),d2-d3
	move.l a4,a0
	bsr DrawLine

	movem.w point3(a3),d0/d2		point 3 & 4
	movem.w 0(a2,d0.w),d0-d1
	movem.w 0(a2,d2.w),d2-d3
	move.l a4,a0
	bsr DrawLine
		
	move.w point4(a3),d0			point 1 & 4
	move.w (a3),d2
	movem.w 0(a2,d0.w),d0-d1
	movem.w 0(a2,d2.w),d2-d3
	move.l a4,a0
	bsr DrawLine

not_in_bpl1
	tst.b d6
	beq.s not_in_bpl2

	movem.w (a3),d0/d2			point 1 & 2
	movem.w 0(a2,d0.w),d0-d1
	movem.w 0(a2,d2.w),d2-d3
	lea 40(a4),a0
	bsr DrawLine

	movem.w point2(a3),d0/d2		point 2 & 3
	movem.w 0(a2,d0.w),d0-d1
	movem.w 0(a2,d2.w),d2-d3
	lea 40(a4),a0
	bsr DrawLine

	movem.w point3(a3),d0/d2		point 3 & 4
	movem.w 0(a2,d0.w),d0-d1
	movem.w 0(a2,d2.w),d2-d3
	lea 40(a4),a0
	bsr DrawLine
		
	move.w point4(a3),d0			point 1 & 4
	move.w (a3),d2
	movem.w 0(a2,d0.w),d0-d1
	movem.w 0(a2,d2.w),d2-d3
	lea 40(a4),a0
	bsr DrawLine

not_in_bpl2
	lea face_SIZEOF(a3),a3
	dbf d7,draw_next_face
	rts


********************************************************************************
*************************                             **************************
*************************  REMPLI LE CUBE AU BLITTER  **************************
*************************                             **************************
********************************************************************************
Fill_Screen
	lea 40*160*2-2(a4),a4

Fill_Screen_Wait
	btst #14,dmaconr(a6)
	bne.s Fill_Screen_Wait

	move.l a4,bltapt(a6)
	move.l a4,bltdpt(a6)
	clr.l bltamod(a6)
	move.l #$9f00012,bltcon0(a6)
	move.w #(160*2<<6)!(20),bltsize(a6)
	btst #14,dmaconr(a6)
wait_fill
	btst #14,dmaconr(a6)
	bne.s wait_fill
	rts



********************************************************************************
*******************                                            *****************
*******************  ROUTINE DE TRACE DE DROITES FAITE MAISON  *****************
*******************                                            *****************
********************************************************************************
Width=40				largeur en octets
Heigth=160				hauteur en pixel
Depth=2					profondeur en bitplans
MINTERM=$4a				minterm de la droite

DrawLine
	cmp.w d1,d3
	bgt.s .Y_OK
	beq .no_line

	exg d0,d2
	exg d1,d3
.Y_OK
	sub.w d0,d2				d2=deltaX
	sub.w d1,d3				d3=deltaY
	subq.w #1,d3

	moveq #0,d4
	ror.w #4,d0				\
	move.b d0,d4				 > d0=décalage
	and.w #$f000,d0				/

	add.b d4,d4				d4=adr en octets sur X
	add.w d1,d1				d1=d1*2 car table de WORD
	add.w Table_Mulu_Line(pc,d1.w),d4	d4=d1*Width+d4
	lea 0(a0,d4.w),a0			recherche 1er mot de la droite
	move.w d0,d4				sauvegarde du décalage
	or.w #$0b<<8|MINTERM,d4			source + masque
.find_octant	
	moveq #0,d1
	tst.w d2
	bpl.s .X1_inf_X2
	neg.w d2
	moveq #4,d1
.X1_inf_X2
	cmp.w d2,d3
	bpl.s .DY_sup_DX
	or.b #16,d1
	bra.s .octant_found
.DY_sup_DX
	exg d2,d3
	add.b d1,d1
.octant_found

	addq.b #3,d1				LINE + ONEDOT
	or.w d0,d1				rajoute le décalage
	
	add.w d3,d3				4*Pdelta
	add.w d3,d3
	add.w d2,d2				2*Gdelta

.wait
	btst #14,dmaconr(a6)
	bne.s .wait

	move.w d3,bltbmod(a6)
	sub.w d2,d3				4*Pdelta-2*Gdelta
	bge.s .no_SIGNFLAG
	or.w #$40,d1
.no_SIGNFLAG
	move.w d1,bltcon1(a6)
	move.w d3,bltapt+2(a6)
	sub.w d2,d3				4*Pdelta-4*Gdelta
	move.w d3,bltamod(a6)

	move.w d4,bltcon0(a6)

	move.l a0,bltcpt(a6)			\ pointeur sur 1er mot droite
	move.l a0,bltdpt(a6)			/

	addq.w #1<<1,d2				(Gdelta+1)<<1
	lsl.w #5,d2				(Gdelta+1)<<6
	addq.b #2,d2				(Gdelta+1)<<6+2
	move.w d2,bltsize(a6)			traçage de la droite
.no_line
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



********************************************************************************
*****************************                       ****************************
*****************************  DESCRIPTION DU CUBE  ****************************
*****************************                       ****************************
********************************************************************************
dots_3d
BING=500
	dc.w BING,BING,BING
	dc.w BING,-BING,BING
	dc.w -BING,-BING,BING
	dc.w -BING,BING,BING
	dc.w BING,BING,-BING
	dc.w BING,-BING,-BING
	dc.w -BING,-BING,-BING
	dc.w -BING,BING,-BING

dots_2d
	dcb.w 8*2,0

POINT	macro
	dc.w \1*4-4
	endm

cube_faces
* 1ère face
	POINT 2
	POINT 3
	POINT 4
	POINT 1
	dc.w 1
	dc.w $f
	dc.w $8
	dc.w $0

* 2ème face
	POINT 4
	POINT 3
	POINT 7
	POINT 8
	dc.w 2
	dc.w $f
	dc.w $0
	dc.w $8

* 3ème face
	POINT 7
	POINT 6
	POINT 5
	POINT 8
	dc.w 1
	dc.w $8
	dc.w $f
	dc.w $8

* 4ème face
	POINT 5
	POINT 6
	POINT 2
	POINT 1
	dc.w 2
	dc.w $f
	dc.w $0
	dc.w $f

* 5ème face
	POINT 2
	POINT 6
	POINT 7
	POINT 3
	dc.w 3
	dc.w $8
	dc.w $8
	dc.w $f

* 6ème face
	POINT 5
	POINT 1
	POINT 4
	POINT 8
	dc.w 3
	dc.w $f
	dc.w $f
	dc.w $0

	include "sources/TMC_Replay.s"
	include "Song.s"

	section ahkeclamusikkejaimeux,data_c
	include "samples.s"

coplist1
	dc.w fmode,$0
	dc.w ddfstrt,$0064
	dc.w ddfstop,$00ac
	dc.w diwstrt,$50d1
	dc.w diwstop,$f0c1
	dc.w bplcon0,$2200!$8000
	dc.w bplcon1,$0000
	dc.w bplcon2,$0000
	dc.w bpl1mod,40
	dc.w bpl2mod,40
color_patch
	dc.w color00,$000
	dc.w color01,$f00
	dc.w color02,$0f0
	dc.w color03,$00f
	dc.l $fffffffe

coplist2
	dc.w fmode,$0
	dc.w ddfstrt,$0064
	dc.w ddfstop,$00ac
	dc.w diwstrt,$50d1
	dc.w diwstop,$f0c1
	dc.w bplcon0,$2200!$8000
	dc.w bplcon1,$0000
	dc.w bplcon2,$0000
	dc.w bpl1mod,40
	dc.w bpl2mod,40
	dc.w color00,$000
	dc.w color01,$f00
	dc.w color02,$0f0
	dc.w color03,$00f
	dc.l $fffffffe

	section ecran,bss_c
screen1
	ds.b 40*160*2
screen2
	ds.b 40*160*2

