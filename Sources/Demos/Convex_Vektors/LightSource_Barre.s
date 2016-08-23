
*			Barre Rotative En Light Source
*			~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


	incdir "asm:"
	incdir "asm:sources/"
	incdir "asm:datas/"
	incdir "asm:.s/convex_vektors/"
	include "registers.i"

	OPT C+,O-


SCREEN_X=352
SCREEN_Y=256
SCREEN_DEPTH=2
SCREEN_WIDTH=SCREEN_X/8
SCREEN_HEIGHT=SCREEN_Y*SCREEN_DEPTH

NB_DOT=8
NB_LINE=12
NB_FACE=6

INC_X=2
INC_Y=3
INC_Z=4

	section fea,code

	KILL_SYSTEM do_Barre
	moveq #0,d0
	rts

do_Barre
	lea data_base,a5
	lea custom_base,a6

	move.l #coplist,cop1lc(a6)
	clr.w copjmp1(a6)
	move.l #vbl,$6c.w

	move.w #$87c0,dmacon(a6)
	move.w #$c020,intena(a6)

main_loop
	WAIT_VHSPOS $12000
	lea data_base(pc),a5
	lea custom_base,a6

	bsr Clear_Screen
	bsr Compute_Matrix
	bsr Compute_Dots
	bsr Compute_Lines
	bsr Display_Lines
	bsr Draw_RightLines
	bsr.s Fill_Screen

	moveq #INC_X*2,d0
	moveq #INC_Y*2,d1
	moveq #INC_Z*2,d2
	bsr Incrize_Angles

	VBL_SIZE color00,$fff

	btst #6,ciaapra
	bne.s main_loop
	RESTORE_SYSTEM


vbl
	move.l a1,-(sp)

	move.l phy_screen(pc),a1
	move.l a1,bpl1ptH+custom_base
	lea SCREEN_WIDTH*SCREEN_Y(a1),a1
	move.l a1,bpl2ptH+custom_base

	move.l (sp)+,a1
	move.w #$0020,intreq+custom_base
	rte


*********************************************************************************
*                              ECHANGE DES ECRANS                               *
*********************************************************************************
Clear_Screen
	movem.l log_screen(pc),a0-a1
	exg a0,a1
	movem.l a0-a1,log_screen-data_base(a5)

	WAIT_BLITTER
	move.l a0,bltdpt(a6)
	clr.w bltdmod(a6)
	move.l #$01000000,bltcon0(a6)
	move.l #(SCREEN_HEIGHT<<16)|(SCREEN_X/16),bltsizV(a6)
	rts



*********************************************************************************
*                              REMPLISSAGE DE L'ECRAN                           *
*********************************************************************************
Fill_Screen
	WAIT_BLITTER

	move.l log_screen(pc),a0
	lea SCREEN_WIDTH*SCREEN_HEIGHT-2(a0),a0
	move.l a0,bltapt(a6)
	move.l a0,bltdpt(a6)
	clr.l bltamod(a6)
	move.l #$09f00012,bltcon0(a6)
	move.l #(SCREEN_HEIGHT<<16)|(SCREEN_X/16),bltsizV(a6)
	rts



*********************************************************************************
*                      INCREMENTATION DES ANGLES DE ROTATION                    *
*********************************************************************************
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



*********************************************************************************
*                        CALCUL DE LA MATRICE DE ROTATION                       *
*********************************************************************************
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



*********************************************************************************
*                        PROJECTION DES POINTS DE L'OBJECT                      *
*********************************************************************************
Compute_Dots
	lea Dots_3d(pc),a0			pointe les points 3d originaux
	lea table_dots(pc),a1			pointe les points 2d
	lea (SCREEN_X/2).w,a2
	lea (SCREEN_Y/2).w,a3
	moveq #NB_DOT-1,d0			8 points sur un cube
	move.w Zoom(pc),d6			le zoom
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
	add.w a2,d1				recentre à l'écran
	add.w a3,d2
	move.w d1,(a1)+				sauve Xe,Ye
	move.w d2,(a1)+

	dbf d0,loop_compute_dots	
	rts	



*********************************************************************************
*                         RECHERCHE LES DROITES AFFICHABLES                     *
*********************************************************************************
Compute_Lines
	lea table_lines(pc),a0			aucune droite a tracer pour
	moveq #0,d0				l'instant
	moveq #NB_LINE-1,d1
clear_lines_colors
	move.w d0,(a0)
	addq.l #3*2,a0
	dbf d1,clear_lines_colors

	lea table_faces(pc),a0
	lea table_dots(pc),a1
	lea table_lines(pc),a2
	moveq #NB_FACE-1,d7
loop_compute_lines
	movem.w (a0)+,d0/d2/d4
	movem.w 0(a1,d0.w),d0-d1
	movem.w 0(a1,d2.w),d2-d3
	movem.w 0(a1,d4.w),d4-d5

	sub.w d0,d2				(x2-x1)
	sub.w d1,d5				(y3-y1)
	muls d5,d2				(x2-x1)*(y3-y1)
	sub.w d0,d4				(x3-x1)
	sub.w d1,d3				(y2-y1)
	muls d4,d3				(x3-x1)*(y2-y1)
	sub.l d3,d2				(x2-x1)*(y3-y1)<(x3-x1)*(y2-y1)?
	ble.s face_back				face devant si >0

face_font
	movem.w (a0)+,d0-d4
	eor.w d0,0(a2,d1.w)
	eor.w d0,0(a2,d2.w)
	eor.w d0,0(a2,d3.w)
	eor.w d0,0(a2,d4.w)
	dbf d7,loop_compute_lines
	rts

face_back
	lea (1+4)*2(a0),a0			saute la couleur + les 4 droites
	dbf d7,loop_compute_lines
	rts



*********************************************************************************
*                             AFFICHAGE DES DROITES                             *
*********************************************************************************
Display_Lines
	lea $dff000,a6
	bsr LineInit

	lea table_lines(pc),a1
	lea table_dots(pc),a2
	move.l log_screen(pc),a3
	lea line_bpl1(pc),a4
	lea line_bpl2(pc),a5
	moveq #NB_LINE-1,d7
loop_display_lines
	move.w (a1)+,d6				récupère la couleur
	beq.s no_line

	movem.w (a1)+,d0/d2
	movem.w 0(a2,d0.w),d0-d1
	movem.w 0(a2,d2.w),d2-d3
	move.l a3,a0

	cmp.w #%11,d6				trace la droite ds le bon bpl
	bne.s not_in_all_bpl
	bsr.s Line
	movem.w -4(a1),d0/d2
	movem.w 0(a2,d0.w),d0-d1
	movem.w 0(a2,d2.w),d2-d3
	lea SCREEN_WIDTH*SCREEN_Y(a3),a0
	exg a4,a5
	bsr.s Line
	exg a4,a5
	dbf d7,loop_display_lines
	rts

not_in_all_bpl
	subq.w #1,d6				elle est ds le bpl1 ?
	bne.s not_in_bpl1
	bsr.s Line
	dbf d7,loop_display_lines
	rts
not_in_bpl1
	lea SCREEN_WIDTH*SCREEN_Y(a0),a0	trace ds le bpl2
	exg a4,a5
	bsr.s Line
	exg a4,a5
	dbf d7,loop_display_lines
	rts

no_line
	addq.l #4,a1
	dbf d7,loop_display_lines
	rts



*********************************************************************************
*                  TRACAGE DES DROITES DU BORD DROIT DE L'ECRAN                 *
*********************************************************************************
Draw_RightLines
	lea Table_Mulu_Line(pc),a0
	lea line_bpl1(pc),a2
put_right_in_bpl1
	cmp.l a2,a4
	beq.s next_bpl
	movem.w (a2)+,d0/d1
	bsr LineRight
	bra.s put_right_in_bpl1
next_bpl
	lea line_bpl2(pc),a2
	lea SCREEN_WIDTH*SCREEN_Y(a3),a3
put_right_in_bpl2
	cmp.l a2,a5
	beq.s end_right
	movem.w (a2)+,d0/d1
	bsr LineRight
	bra.s put_right_in_bpl2
end_right
	rts
	

*********************************************************************************
*                      ROUTINE DE TRACE DE DROITE + CLIPPING                    *
*********************************************************************************
; Sync Line Drawing Routine
; d0=X1  d1=Y1  d2=X2  d3=Y3  a0=Bpl

Width=SCREEN_WIDTH
Heigth=SCREEN_Y
Depth=1
MINTERM=$4a
WORD=1

Line
	cmp.w d2,d0
	ble.s .x1_less_x2
	exg d0,d2
	exg d1,d3
.x1_less_x2
	tst.w d0
	bge.s .no_inter_X_min
	tst.w d2
	blt LineOut

*---------------> clip suivant les X avec le bord gauche ( Xmin )
	sub.w d3,d1				(Y1-Y2)
	muls d2,d1				(Y1-Y2)*(X2-0)
	neg.l d1				(Y1-Y2)*(0-X2)
	sub.w d2,d0				(X2-X1)
	divs d0,d1				(Y1-Y2)*(0-X2)/(X2-X1)
	add.w d3,d1				Y1=(Y1-Y2)*(0-X2)/(X2-X1)+Y2
	moveq #0,d0				X1=0

.no_inter_X_min
	cmp.w #SCREEN_X,d2
	blt.s .no_inter_X_max
	cmp.w #SCREEN_X,d0
	bge LineOut

*---------------> clip suivant les X avec le bord droit ( Xmax )
	move.w #SCREEN_X-1,d4
	sub.w d2,d4				(D-X2)
	move.w d3,d5				sauve Y2
	sub.w d1,d3				(Y2-Y1)
	muls d4,d3				(Y2-Y1)*(D-X2)
	sub.w d0,d2				(X2-X1)
	divs d2,d3				(Y1-Y2)*(D-X2)/(X1-X2)
	add.w d5,d3				(Y1-Y2)*(D-X2)/(X1-X2)+Y2
	move.w #SCREEN_X-1,d2			X2=SCREEN_WIDTH-1

	move.w d3,(a4)+

.no_inter_X_max
	cmp.w d3,d1
	ble.s .y1_less_y2
	exg d0,d2
	exg d1,d3
.y1_less_y2
	tst.w d1
	bge.s .no_inter_Y_min
	tst.w d3
	blt LineOut

*---------------> clip suivant les Y avec le haut ( Ymin )
	move.w d0,d4				sauve X1
	sub.w d2,d0				(X1-X2)
	muls d1,d0				(0-Y1)*(X2-X1)
	sub.w d3,d1				(Y1-Y2)
	neg.w d1				(Y2-Y1)
	divs d1,d0				(0-Y1)*(X2-X1)/(Y2-Y1)
	add.w d4,d0				(0-Y1)*(X2-X1)/(Y2-Y1)+X1
	moveq #0,d1				Y1=0

.no_inter_Y_min
	cmp.w #SCREEN_Y,d3
	blt.s .no_inter_Y_max
	cmp.w #SCREEN_Y,d1
	bge LineOut

*---------------> clip suivant les Y avec le bas ( Ymax )
	move.w #SCREEN_Y-1,d4
	sub.w d1,d4				(D-Y1)
	sub.w d0,d2				(X2-X1)
	muls d4,d2				(D-Y1)*(X2-X1)
	sub.w d1,d3				(Y2-Y1)
	divs d3,d2				(D-Y1)*(X2-X1)/(Y2-Y1)
	add.w d0,d2				(D-Y1)*(X2-X1)/(Y2-Y1)+X1
	move.w #SCREEN_Y-1,d3

.no_inter_Y_max
	cmp.w d1,d3
	beq LineOut
	bgt.s Line1
	exg d0,d2
	exg d1,d3
Line1	sub.w d0,d2
	sub.w d1,d3
	subq.w #1,d3
	moveq #0,d4
	ror.w #4,d0
	move.b d0,d4
	and.w #$f000,d0
	add.b d4,d4
	add.w d1,d1
	IFEQ WORD
	add.w d1,d1
	ENDC
	add.w Table_Mulu_Line(pc,d1.w),d4
	lea 0(a0,d4.w),a0
	move.w d0,d4
	or.w #$0b<<8|MINTERM,d4
	moveq #0,d1
	tst.w d2
	bpl.s Line2
	neg.w d2
	moveq #4,d1
Line2	cmp.w d2,d3
	bpl.s Line3
	or.b #16,d1
	bra.s Line4
Line3	exg d2,d3
	add.b d1,d1
Line4	addq.b #3,d1
	or.w d0,d1
	add.w d3,d3
	add.w d3,d3
	add.w d2,d2
Line5	btst #6,dmaconr(a6)
	bne.s Line5
	move.w d3,bltbmod(a6)
	sub.w d2,d3
	bge.s Line6
	or.w #$40,d1
Line6	move.w d1,bltcon1(a6)
	move.w d3,bltapt+2(a6)
	sub.w d2,d3
	move.w d3,bltamod(a6)
	move.w d4,bltcon0(a6)
	move.l a0,bltcpt(a6)
	move.l a0,bltdpt(a6)
	addq.w #1<<1,d2
	lsl.w #5,d2
	addq.b #2,d2
	move.w d2,bltsize(a6)
LineOut	rts

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


*********************************************************************************
*                  ROUTINE DE TRACE DE DROITE VERTICAL + CLIPPING               *
*********************************************************************************
; d0=Y1  d1=Y2  a0=Table_Mulu_Line  a3=bpl
LineRight
	cmp.w d0,d1				effectue un clipping sur les Y
	beq.s no_right_line
	bgt.s .Y1_min_Y2
	exg d0,d1
.Y1_min_Y2
	tst.w d0
	bge.s .no_inter_Y_min
	tst.w d1
	blt.s no_right_line
	moveq #0,d0
.no_inter_Y_min
	cmp.w #SCREEN_Y-1,d1
	ble.s .no_inter_Y_max
	cmp.w #SCREEN_Y-1,d0
	bgt.s no_right_line
	move.w #SCREEN_Y-1,d1
.no_inter_Y_max
	sub.w d0,d1				récupère le DeltaY		
	add.w d0,d0
	move.w 0(a0,d0.w),d0			mulu #SCREEN_WIDTH,d0
	lea SCREEN_WIDTH-2(a3,d0.w),a1		adr de départ

	lsl.w #6,d1				calcul de bltsize
	addq.w #1,d1

	WAIT_BLITTER
	move.l a1,bltcpt(a6)
	move.l a1,bltdpt(a6)
	move.w #SCREEN_WIDTH-2,bltcmod(a6)
	move.w #SCREEN_WIDTH-2,bltdmod(a6)
	move.w #$0001,bltadat(a6)
	move.l #$034a0000,bltcon0(a6)
	move.w d1,bltsize(a6)
no_right_line
	rts



*********************************************************************************
*                 INITIALISATION DU BLITTER POUR LE TRACE DE DROITE             *
*********************************************************************************
LineInit
	WAIT_BLITTER
	moveq #Width*Depth,d0
	move.w d0,bltcmod(a6)
	move.w d0,bltdmod(a6)
	moveq #-1,d0
	move.l d0,bltafwm(a6)
	move.l #-$8000,bltbdat(a6)
	rts	



*********************************************************************************
*                          TOUTES LES DATAS DU PROGRAMME                        *
*********************************************************************************
data_base
Zoom
	dc.w 2500
log_screen
	dc.l screen1
phy_screen
	dc.l screen2
line_bpl1
	dcb.w 6,0
line_bpl2
	dcb.w 6,0

DIST=500
Dots_3d
	dc.w DIST,DIST,DIST*7			point 0
	dc.w DIST,-DIST,DIST*7			point 1
	dc.w -DIST,-DIST,DIST*7
	dc.w -DIST,DIST,DIST*7
	dc.w DIST,DIST,-DIST*7
	dc.w DIST,-DIST,-DIST*7
	dc.w -DIST,-DIST,-DIST*7
	dc.w -DIST,DIST,-DIST*7			point 7

table_dots
	dcb.l NB_DOT

*-----------------> LINE(Dot1,Dot2)
LINE	macro
	IFNE NARG-2
	FAIL Pas assez de parametres pour LINE
	ENDC
	dc.w 0,\1*4,\2*4
	endm

table_lines
	LINE 0,1				ligne 0
	LINE 1,2				ligne 1
	LINE 2,3
	LINE 3,0
	LINE 4,5
	LINE 5,6
	LINE 6,7
	LINE 7,4
	LINE 0,4
	LINE 1,5
	LINE 2,6
	LINE 3,7				ligne 11


*-----------------> FACE(Dot1,Dot2,Dot3,Line1,Line2,Line3,Line4)
FACE	macro
	IFNE NARG-8
	FAIL Pas assez de parametres pour FACE
	ENDC
	dc.w \1*4,\2*4,\3*4			3 points pour l'orientation
	dc.w \4					la couleur de la face
	dc.w \5*6,\6*6,\7*6,\8*6		les 4 droites
	endm

table_faces
	FACE 0,1,2,%01,0,1,2,3			face 0
	FACE 3,2,6,%10,2,10,6,11
	FACE 7,6,5,%01,6,5,4,7
	FACE 4,5,1,%10,4,9,0,8
	FACE 6,2,1,%11,10,1,9,5
	FACE 3,7,4,%11,11,7,8,3			face 5



*********************************************************************************
*                                 LA COPPERLIST                                 *
*********************************************************************************
	section mycopper,data_c
coplist
	dc.w fmode,$0
	dc.w bplcon0,$2200
	dc.w bplcon1,$0000
	dc.w bplcon2,$0000
	dc.w ddfstrt,$0030
	dc.w ddfstop,$00d8
	dc.w diwstrt,$3071
	dc.w diwstop,$29d1
	dc.w bpl1mod,0
	dc.w bpl2mod,0

	dc.w $2f0f,$fffe
	dc.w color00,$fff

	dc.w $300f,$fffe
	dc.w color00,$000
	dc.w color01,$00f
	dc.w color02,$00d
	dc.w color03,$00b

	dc.w $ffdf,$fffe
	dc.w $290f,$fffe
	dc.w color00,$fff

	dc.w $2a0f,$fffe
	dc.w color00,$000
	dc.l $fffffffe



*********************************************************************************
*                                  LES ECRANS                                   *
*********************************************************************************
	section ecran,bss_c
screen1
	ds.b SCREEN_WIDTH*SCREEN_HEIGHT
screen2
	ds.b SCREEN_WIDTH*SCREEN_HEIGHT

