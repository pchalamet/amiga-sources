
*			      Cube 3d en 3 bpl
*			avec glenz et rubber vektor
*			---------------------------

* hum.. quelques constantes !!
rubber_code=$6000

* structure d'une face d'un cube
	rsreset
point1	rs.w 1				offset point 1
point2	rs.w 1				offset point 2
point3	rs.w 1				offset point 3
point4	rs.w 1				offset point 4
face_SIZEOF	rs.w 0

bpl1=0
bpl2=20
bpl3=40

	OPT NOCASE

	incdir "asm:" "asm:Convex_Vektors"
	include "sources/registers.i"

	move.l #supervisor,$80.w
	trap #0
supervisor
	move.l #stack,sp

	lea $dff000,a6
	
	move.w #$7fff,d0
	move.w d0,intena(a6)
	move.w d0,dmacon(a6)
	move.b #$87,$bfd100
	
	lea main(pc),a0				reloge le code du rubber vektor
	lea rubber_code,a1
	move.w #(end_rubber_code-start_rubber_code)/2,d0
loop_dup_code
	move.w (a0)+,(a1)+
	dbf d0,loop_dup_code
	jmp rubber_code

main
	org rubber_code

start_rubber_code
	lea coplist1,a0				construction de la coplist1
	move.w #160-1,d0
	move.l #$500ffffe,d1			wait pour copper
loop_make_ptr
	move.l d1,(a0)+				met le wait
	move.l #bpl1ptH<<16,(a0)+
	move.l #bpl1ptL<<16,(a0)+		met les init des ptr videos
	move.l #bpl2ptH<<16,(a0)+
	move.l #bpl2ptL<<16,(a0)+
	move.l #bpl3ptH<<16,(a0)+
	move.l #bpl3ptL<<16,(a0)+
	add.l #$01000000,d1			ligne suivante
	dbf d0,loop_make_ptr
	move.l #$fffffffe,(a0)

	lea coplist1,a0				construction de la coplist2
	lea coplist2,a1
	move.w #160*(4+6*4)+4-1,d0
loop_dup_coplist1
	move.b (a0)+,(a1)+
	dbf d0,loop_dup_coplist1
	
	move.w #$3200,bplcon0(a6)		init les ecrans
	clr.l bplcon1(a6)
	move.l #40<<16+40,bpl1mod(a6)
	move.l #$006000a8,ddfstrt(a6)
	move.l #$50d1f0c1,diwstrt(a6)
	clr.l color00(a6)
	clr.l color02(a6)
	clr.l color04(a6)
	clr.l color06(a6)

	move.l #vbl,$6c.w
	move.l #coplist1,cop1lc(a6)
	clr.w copjmp1(a6)

	move.w #$87c0,dmacon(a6)
	move.w #$c020,intena(a6)

mickey
	btst #6,ciaapra
	bne.s mickey
	lea 2.w,a0
	reset
	jmp (a0)

vbl
	lea data_base(pc),a5
	lea $dff000,a6

	bsr Setup_Screen			prépare les écrans

	tst.w color_wait-data_base(a5)
	bne.s dec_wait
	addq.w #1,slower-data_base(a5)
	and.w #%11,slower-data_base(a5)
	bne.s do_rubber
	subq.w #1,nb_color-data_base(a5)
	blt.s next_color
	move.l color_ptr(pc),a0
	move.l (a0)+,color02(a6)
	move.l (a0)+,color06(a6)
	move.l a0,color_ptr-data_base(a5)
	bra.s do_rubber
next_color
	move.l color_ptr(pc),a0
	move.l (a0)+,d0
	bne.s not_end_color
	lea restart_color(pc),a0
	move.l (a0)+,d0
not_end_color
	move.l d0,color_wait-data_base(a5)
	move.l a0,color_ptr-data_base(a5)
	clr.w slower-data_base(a5)
	bra.s do_rubber
dec_wait
	subq.w #1,color_wait-data_base(a5)
do_rubber
	bsr Make_Rubber				fait le rubber

inc_X=*+1
	moveq #4,d0				\
inc_Y=*+1
	moveq #2,d1				 \ fait tourner le cube
inc_Z=*+1
	moveq #4,d2				 /
	bsr Incrize_Angles			/

	bsr Compute_Matrix			calcul la matrice de rotation
	bsr Compute_Dots			points 3d -> 2d
	bsr Display_Cube			afficher le cube
	bsr Fill_Screen				rempli le cube
	bsr Prepare_Next_Frame			incrémente ptr video

	btst #2,potgor(a6)
	bne.s no_right
	move.b #4,inc_X-data_base(a5)
	move.b #2,inc_Y-data_base(a5)
	move.b #-4,inc_Z-data_base(a5)
	move.w #$0020,intreq(a6)
	rte

no_right
	move.b #4,inc_X-data_base(a5)
	move.b #2,inc_Y-data_base(a5)
	move.b #4,inc_Z-data_base(a5)
	move.w #$0020,intreq(a6)
	rte
	


********************************************************************************
************************  EFFACAGE DE L'ECRAN DE TRAVAIL  **********************
************************                                  **********************
************************      ET ECHANGE DES COPLISTS     **********************
********************************************************************************
Setup_Screen
	movem.l log_screen(pc),a0-a2		place une nouvelle coplist
	exg a1,a2
	movem.l a1-a2,log_coplist-data_base(a5)
	move.l a2,cop1lc(a6)
	clr.w copjmp1(a6)

	move.l a0,bltdpt(a6)			efface le log_screen
	move.l #$1000000,bltcon0(a6)
	clr.w bltdmod(a6)
	move.w #160<<6+10*3,bltsize(a6)
	rts
data_base
color_wait
	dc.w 50
nb_color
	dc.w 16
slower
	dc.w 0
color_ptr
	dc.l start_color+2+2
first_screen
	dc.l screen_start
nb_picture
	dc.w max_pic-1
zoom
	dc.w 1420
log_screen
	dc.l screen_start+(max_pic-2)*picture_size
log_coplist
	dc.l coplist1
phy_coplist
	dc.l coplist2
start_color
	dc.w 5*50,16
	dc.w $000,$000,$000,$000
	dc.w $100,$111,$100,$111
	dc.w $200,$222,$200,$222
	dc.w $300,$333,$300,$333
	dc.w $400,$444,$400,$444
	dc.w $500,$555,$500,$555
	dc.w $600,$666,$600,$666
	dc.w $700,$777,$700,$777
	dc.w $800,$888,$800,$888
	dc.w $900,$999,$900,$999
	dc.w $a00,$aaa,$a00,$aaa
	dc.w $b00,$bbb,$b00,$bbb
	dc.w $c00,$ccc,$c00,$ccc
	dc.w $d11,$ddd,$d11,$ddd
	dc.w $e22,$eee,$e22,$eee
	dc.w $f33,$fff,$f33,$fff
restart_color
	dc.w 10*50,5
	dc.w $e22,$eee,$f33,$fff
	dc.w $d22,$ddd,$f33,$fff
	dc.w $c22,$ddd,$f33,$fff
	dc.w $b22,$ddd,$f33,$fff
	dc.w $a22,$ddd,$f33,$fff
	dc.w 10*50,6
	dc.w $a22,$ddd,$f33,$fff
	dc.w $b22,$ddd,$f33,$fff
	dc.w $c22,$ddd,$f33,$fff
	dc.w $d22,$ddd,$f33,$fff
	dc.w $e22,$eee,$f33,$fff
	dc.w $f33,$fff,$f33,$fff
	dc.l 0
	


********************************************************************************
**********************                                   ***********************
**********************  FAIT UN RUBBER VECTOR A L'ECRAN  ***********************
**********************                                   ***********************
********************************************************************************
Make_Rubber
	move.l log_coplist(pc),a0
	lea 4+2(a0),a0				pointe 1er pointeur video
	move.l first_screen(pc),d0		pointe 1ere image du rubber
	move.l #160,d1				\
	divu nb_picture(pc),d1			 | pas d'incrémentation
	swap d1					/
	moveq #0,d2				# de ligne du rubber
	move.w #160-1,d3			160 lignes de rubber vectors
loop_Make_rubber
	move.w d0,4(a0)				bpl1ptL
	swap d0
	move.w d0,(a0)				bpl1ptH

	swap d0
	add.l #20,d0
	move.w d0,12(a0)			bpl2ptL
	swap d0
	move.w d0,8(a0)				bpl2ptH

	swap d0
	add.l #20,d0
	move.w d0,20(a0)			bpl3ptL
	swap d0
	move.w d0,16(a0)			bpl3ptH

	swap d0
	add.l #20,d0				on s'place sur la ligne suivante

	lea 4*6+4(a0),a0			pointeur suivant ds coplist
	add.l #1<<16,d2				incrémente le # de ligne
	cmp.l d1,d2
	blt.s not_next_rubber_line
	sub.l d1,d2				reset le compteur de ligne
	add.l #picture_size,d0			image suivante
	cmp.l #screen_end,d0
	blt.s not_next_rubber_line
	sub.l #restart_offset,d0
not_next_rubber_line
	dbf d3,loop_make_rubber	
	rts



********************************************************************************
*************************                               ************************
*************************  PREPARE L'AFFICHAGE SUIVANT  ************************
*************************                               ************************
********************************************************************************
Prepare_Next_Frame
	move.l log_screen(pc),a0		passe à un autre écran de
	lea picture_size(a0),a0			travail
	cmp.l #screen_end,a0
	blt.s not_end_memory1
	sub.l #restart_offset,a0
not_end_memory1
	move.l a0,log_screen-data_base(a5)

	move.l first_screen(pc),a0		passe à un autre écran
	lea picture_size(a0),a0			d'affichage
	cmp.l #screen_end,a0
	blt.s not_end_memory2
	sub.l #restart_offset,a0
not_end_memory2
	move.l a0,first_screen-data_base(a5)
	rts



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
	add.w #720,-2(a0)
	bra.s do_Teta
Alpha_test
	cmp.w #720,-2(a0)
	blt.s do_Teta
	sub.w #720,-2(a0)
do_Teta
	add.w d1,(a0)+				ajoute l'angle
	bgt.s Teta_test				signe du résultat
	beq.s do_Phi
	add.w #720,-2(a0)
	bra.s do_Phi
Teta_test
	cmp.w #720,-2(a0)
	blt.s do_Phi
	sub.w #720,-2(a0)
do_Phi
	add.w d2,(a0)				ajoute l'angle
	bgt.s Phi_test				signe du résultat
	beq.s end_Angles
	add.w #720,(a0)
	rts
Phi_test
	cmp.w #720,(a0)
	blt.s end_Angles
	sub.w #720,(a0)
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

compute_matrix
	lea table_cosinus(pc),a0
	lea table_sinus(pc),a1

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
	move.w d6,6(a0)

	move.w sinteta,d6
	neg.w d6
	asr.w #1,d6				on perd un bit à cause du swap
	move.w d6,12(a0)			-sin(teta)

	move.w costeta,d6
	muls sinalpha,d6			cos(teta) * sin(alpha)
	swap d6
	move.w d6,14(a0)

	move.w costeta,d6
	muls cosalpha,d6			cos(teta) * cos(alpha)
	swap d6
	move.w d6,16(a0)
	
	move.w sinalpha,d6
	muls sinteta,d6				sin(alpha) * sin(teta)
	swap d6
	rol.l #1,d6
	move.w d6,a3

	muls cosphi,d6				sin(alpha)*sin(teta)*cos(phi)
	move.w cosalpha,d7
	muls sinphi,d7				cos(alpha) * sin(phi)
	sub.l d7,d6
	swap d6
	move.w d6,2(a0)

	move.w a3,d6
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
	move.w d6,a3

	muls cosphi,d6				cos(alpha)*sin(teta)*cos(phi)
	move.w sinalpha,d7
	muls sinphi,d7				sin(alpha) * sin(phi)
	add.l d7,d6
	swap d6
	move.w d6,4(a0)

	move.w a3,d6
	muls sinphi,d6				cos(alpha)*sin(teta)*sin(phi)
	move.w sinalpha,d7
	muls cosphi,d7				sin(alpha) * cos(phi)
	sub.l d7,d6
	swap d6
	move.w d6,10(a0)		

	rts

matrix	dcb.w 3*3,0				la matrice de rotation
Alpha	dc.w 10*2
Teta	dc.w 75*2
Phi	dc.w 160*2
Table_Cosinus
	incbin "datas/table_cosinus_360.dat"
Table_Sinus=Table_Cosinus+90*2



********************************************************************************
*************                                                        ***********
*************  TRANSFORMATIONS DES COORDONNEES 3D EN COORDONNEES 2D  ***********
*************                                                        ***********
********************************************************************************
Compute_Dots
	lea dots_3d(pc),a0			pointe les points 3d originaux
	lea dots_2d(pc),a1			pointe les points 2d
	moveq #8-1,d0				8 points sur un cube
	move.w ZOOM(pc),d6			le zoom
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
no_divs
	add.w #80,d1				recentre à l'écran
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
	cmp.l d2,d3				(x2-x1)*(y3-y1)<(x3-x1)*(y2-y1)?
	blt.s face_front			face devant si <0
	bgt.s face_back				face derriere si >0

	lea face_SIZEOF(a3),a3			pointe la face suivante
	dbf d7,draw_next_face
	rts					=0 => pas de face

face_front
* on trace sur le bpl1
	movem.w (a3),d0/d2			point 1 & 2
	movem.w 0(a2,d0.w),d0-d1
	movem.w 0(a2,d2.w),d2-d3
	move.l a4,a0
	bsr DrawLine

	move.w point2(a3),d0			point 2 & 4
	move.w point4(a3),d2
	movem.w 0(a2,d0.w),d0-d1
	movem.w 0(a2,d2.w),d2-d3
	move.l a4,a0
	bsr DrawLine

	movem.w point3(a3),d0/d2		point 3 & 4
	movem.w 0(a2,d0.w),d0-d1
	movem.w 0(a2,d2.w),d2-d3
	move.l a4,a0
	bsr DrawLine
		
	move.w (a3),d0				point 1 & 3
	move.w point3(a3),d2
	movem.w 0(a2,d0.w),d0-d1
	movem.w 0(a2,d2.w),d2-d3
	move.l a4,a0
	bsr DrawLine

	lea face_SIZEOF(a3),a3
	dbf d7,draw_next_face
	rts

face_back
* on trace sur le bpl 2
	movem.w (a3),d0/d2			point 1 & 2
	movem.w 0(a2,d0.w),d0-d1
	movem.w 0(a2,d2.w),d2-d3
	lea bpl2(a4),a0
	bsr DrawLine

	movem.w point2(a3),d0/d2		point 2 & 3
	movem.w 0(a2,d0.w),d0-d1
	movem.w 0(a2,d2.w),d2-d3
	lea bpl2(a4),a0
	bsr DrawLine

	movem.w point3(a3),d0/d2		point 3 & 4
	movem.w 0(a2,d0.w),d0-d1
	movem.w 0(a2,d2.w),d2-d3
	lea bpl2(a4),a0
	bsr DrawLine

	move.w (a3),d0				point 1 & 4
	move.w point4(a3),d2
	movem.w 0(a2,d0.w),d0-d1
	movem.w 0(a2,d2.w),d2-d3
	lea bpl2(a4),a0
	bsr DrawLine
	
* on trace sur le bpl 3
	movem.w (a3),d0/d2			point 1 & 2
	movem.w 0(a2,d0.w),d0-d1
	movem.w 0(a2,d2.w),d2-d3
	lea bpl3(a4),a0
	bsr DrawLine

	move.w point2(a3),d0			point 2 & 4
	move.w point4(a3),d2
	movem.w 0(a2,d0.w),d0-d1
	movem.w 0(a2,d2.w),d2-d3
	lea bpl3(a4),a0
	bsr DrawLine

	movem.w point3(a3),d0/d2		point 3 & 4
	movem.w 0(a2,d0.w),d0-d1
	movem.w 0(a2,d2.w),d2-d3
	lea bpl3(a4),a0
	bsr DrawLine
		
	move.w (a3),d0				point 1 & 3
	move.w point3(a3),d2
	movem.w 0(a2,d0.w),d0-d1
	movem.w 0(a2,d2.w),d2-d3
	lea bpl3(a4),a0
	bsr DrawLine

	lea face_SIZEOF(a3),a3
	dbf d7,draw_next_face
	rts


********************************************************************************
*************************                             **************************
*************************  REMPLI LE CUBE AU BLITTER  **************************
*************************                             **************************
********************************************************************************
Fill_Screen
	lea 20*160*3-2(a4),a4

Fill_Screen_Wait
	btst #6,dmaconr(a6)
	bne.s Fill_Screen_Wait

	move.l a4,bltapt(a6)
	move.l a4,bltdpt(a6)
	clr.l bltamod(a6)
	move.l #$9f0000a,bltcon0(a6)
	move.w #160<<6+10*3,bltsize(a6)
	rts



********************************************************************************
*******************                                            *****************
*******************  ROUTINE DE TRACE DE DROITES FAITE MAISON  *****************
*******************                                            *****************
********************************************************************************
Width=20				largeur en octets
Heigth=160				hauteur en pixel
Depth=3					profondeur en bitplans
MINTERM=$4a				minterm de la droite
WORD=1					table de WORD ou LONG

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
	IFEQ WORD
	add.w d1,d1				d1=d1*4 si table de LONG
	ENDC
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
	btst #6,dmaconr(a6)
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
	IFNE WORD
	rept Heigth
	dc.w MuluCount*Width*Depth
MuluCount set MuluCount+1
	endr
	ELSEIF
	rept Heigth
	dc.l MuluCount*Width*Depth
MuluCount set MuluCount+1
	endr
	ENDC

DrawLine_Init
	btst #6,dmaconr(a6)
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

* 2ème face
	POINT 4
	POINT 3
	POINT 7
	POINT 8

* 3ème face
	POINT 7
	POINT 6
	POINT 5
	POINT 8

* 4ème face
	POINT 5
	POINT 6
	POINT 2
	POINT 1

* 5ème face
	POINT 2
	POINT 6
	POINT 7
	POINT 3

* 6ème face
	POINT 5
	POINT 1
	POINT 4
	POINT 8

end_rubber_code

max_pic=27
coplist1=rubber_code+end_rubber_code-start_rubber_code
coplist2=coplist1+160*(4+6*4)+4
screen_start=$40000
screen_end=screen_start+max_pic*20*160*3
picture_size=20*160*3
restart_offset=max_pic*20*160*3
stack=$5000

