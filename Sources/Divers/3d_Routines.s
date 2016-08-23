********************************************************************************
*****************************                     ******************************
*****************************  PRODUIT VECTORIEL  ******************************
*****************************                     ******************************
********************************************************************************
Prod_Vect
			d0=X1   ,   d1=Y1
			d2=X2   ,   d3=Y2
			d4=X3   ,   d5=Y3
	sub.w d0,d2				(x2-x1)
	sub.w d1,d5				(y3-y1)
	muls d5,d2				(x2-x1)*(y3-y1)
	sub.w d0,d4				(x3-x1)
	sub.w d1,d3				(y2-y1)
	muls d4,d3				(x3-x1)*(y2-y1)
	sub.l d3,d2				(x2-x1)*(y3-y1)<(x3-x1)*(y2-y1)?
	bgt.s face_front			face devant si >0



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
	add.w #360*4,-2(a0)
	bra.s do_Teta
Alpha_test
	cmp.w #360*4,-2(a0)
	blt.s do_Teta
	sub.w #360*4,-2(a0)
do_Teta
	add.w d1,(a0)+				ajoute l'angle
	bgt.s Teta_test				signe du résultat
	beq.s do_Phi
	add.w #360*4,-2(a0)
	bra.s do_Phi
Teta_test
	cmp.w #360*4,-2(a0)
	blt.s do_Phi
	sub.w #360*4,-2(a0)
do_Phi
	add.w d2,(a0)				ajoute l'angle
	bgt.s Phi_test				signe du résultat
	beq.s end_Angles
	add.w #360*4,(a0)
	rts
Phi_test
	cmp.w #360*4,(a0)
	blt.s end_Angles
	sub.w #360*4,(a0)
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
	incbin "asm:.s/Convex_Vektors/table_cosinus.dat"
Table_Sinus=Table_Cosinus+90*4



********************************************************************************
*************                                                        ***********
*************  TRANSFORMATIONS DES COORDONNEES 3D EN COORDONNEES 2D  ***********
*************                                                        ***********
********************************************************************************
Compute_Dots
	lea dots_3d(pc),a0			pointe les points 3d originaux
	lea dots_2d(pc),a1			pointe les points 2d
	moveq #8-1,d0				8 points sur un cube
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
no_divs
	add.w #80,d1				recentre à l'écran
	add.w #80,d2
	move.w d1,(a1)+				sauve Xe,Ye
	move.w d2,(a1)+

	dbf d0,loop_compute_dots	
	rts	
