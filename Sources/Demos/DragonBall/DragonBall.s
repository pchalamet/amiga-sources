
	OPT O+,NOCHKBIT

*		Dragon Ball !!	By Sync/DRD
*		----------------------------------------------------->

	incdir "asm:"
	incdir "asm:sources/"
	incdir "asm:datas/"
	incdir "asm:.s/Demos/DragonBall/"
	incdir "ram:"
	include "registers.i"

******************************* yo qq constantes
ZOOM=517
NB_STARS=6
SCREEN_WIDTH=224
SCREEN_HEIGHT=245
NB_BPL=3

Width=28
Heigth=245
Depth=3
MINTERM=$4a
WORD=1

************************** ch'tite structure
	rsreset
Scr	rs.l 1
ClrScr	rs.l 1
Mod	rs.w 1
Blit	rs.w 1

********************************** Boum, le programme de la DragonBall !!!
	section euh,code

	KILL_SYSTEM Main
	moveq #0,d0
	rts

Main	
	lea $dff000,a6

	move.l #coplist,cop1lc(a6)
	clr.w copjmp1(a6)

	move.l #vbl,$6c.w

	bsr mt_init

	move.w #$c020,intena(a6)
	move.w #$87c0,dmacon(a6)

mickey
	btst #6,ciaapra
	bne.s mickey
	bsr mt_end
	RESTORE_SYSTEM

****************************** une vbl de rien du tout
vbl
	bsr mt_music
	lea data_base(pc),a5
	lea $dff000,a6

	bsr.s SwapScreen			a0 pointe sur la structure
	bsr.s ClearScreen			du log_screen

	bsr.s ComputePos
	bsr Compute_Matrix
	bsr Compute_Dots
	bsr Display_Stars
	bsr DrawBubble
	bsr FillScreen

	moveq #2*2,d0				Marrant, avec ces valeurs
	moveq #4*2,d1				et ben ya pas d'erreur de
	moveq #-6*2,d2				remplissage...
	bsr Incrize_Angles

	btst #10,potinp(a6)
	bne.s no_right
	move.w #$f00,color00(a6)
no_right
	move.w #$0020,intreq(a6)
	rte

**************** routine qui flip les ecrans log et phy et init les ptrs videos
SwapScreen
	movem.l log_struct(pc),a0-a1
	exg a0,a1
	movem.l a0-a1,log_struct-data_base(a5)
	move.l Scr(a1),a1
	move.l a1,bpl1ptH(a6)			installe un ptr video
	lea (SCREEN_WIDTH/8)*NB_BPL*2+SCREEN_WIDTH/8(a1),a1
	move.l a1,bpl3ptH(a6)
	lea (SCREEN_WIDTH/8)(a1),a1
	move.l a1,bpl4ptH(a6)
	lea (SCREEN_WIDTH/8)*NB_BPL-(SCREEN_WIDTH/8)*2(a1),a1
	move.l a1,bpl2ptH(a6)
	rts

********************** routine qui efface la DragonBall
ClearScreen
	move.l ClrScr(a0),bltdpt(a6)		va pecher l'adr où effacer
	move.l #$01000002,bltcon0(a6)		mode descending
	move.w Mod(a0),bltdmod(a6)
	move.w Blit(a0),bltsize(a6)		balance la taille du blit
	rts

********************** routine d'init pour la DragonBall
ComputePos
	move.l Mvt_Ptr(pc),a1
	move.l (a1)+,Rayon_A-data_base(a5)
	move.w (a1)+,Centre_Y-data_base(a5)
	cmp.l #End_Table,a1
	bne.s not_end
	lea Dragon_Mvt(pc),a1
not_end
	move.l a1,Mvt_Ptr-data_base(a5)

	move.w Rayon_A(pc),d0			calculs des rapports
	addq.w #3,d0
	mulu #$3fff,d0
	divu #65,d0
	move.w d0,Rapport_X-data_base(a5)

	move.w Rayon_B(pc),d0
	addq.w #1,d0
	mulu #$3fff,d0
	divu #65,d0
	move.w d0,Rapport_Y-data_base(a5)

	move.l stars_Ptr(pc),a0			fait tourner l'etoile
	lea 3*2*11*3(a0),a0
	cmp.l #end_dots_3d,a0
	bne.s not_end_stars	
	lea dots_3d(pc),a0
not_end_stars
	move.l a0,stars_Ptr-data_base(a5)
	rts

*********************** Routine qui dessine une sphere
DrawBubble
	moveq #0,d6
	moveq #0,d7
	movem.w Rayon_A(pc),d6-d7
	move.l d6,d4
	lsl.l #8,d4
	divu d7,d4
	mulu d4,d4
	move.l d4,a0
	neg.l d4
	add.l a0,a0
	move.l d6,d0
	move.l d0,d1
	add.w d1,d1
	swap d1
	move.l log_struct(pc),a1
	move.l Scr(a1),a1			adr du log_screen
	move.w Centre_Y(pc),d2
	move.w d2,d5
	move.w d2,d3
	subq.w #1,d3
	mulu #(SCREEN_WIDTH/8)*NB_BPL,d5
	add.l d5,a1
	move.l a1,a2
	lea -(SCREEN_WIDTH/8)*NB_BPL(a1),a1
	subq.w #1,d7
	move.w #(SCREEN_WIDTH/2),a3
wait_line
	btst #14,dmaconr(a6)
	bne.s wait_line
loop_ellipse2
	add.l a0,d4
	sub.l d4,d1
	bpl.s delta_pos2
	swap d1
delta_neg2
	subq.w #1,d0
	bmi.s out_ellipse_before2
	add.w d0,d1
	add.w d0,d1
	subq.w #1,d1
	bmi.s delta_neg2
	swap d1
delta_pos2
	move.w a3,d5
	sub.w d0,d5
	move.w d5,d6
	lsr.w #3,d6
	not.b d5
	bset d5,0(a1,d6.w)
	bset d5,0(a2,d6.w)
	move.w a3,d5
	add.w d0,d5
	move.w d5,d6
	lsr.w #3,d6
	not.b d5
	bset d5,0(a1,d6.w)
	bset d5,0(a2,d6.w)
	lea -(SCREEN_WIDTH/8)*NB_BPL(a1),a1
	lea (SCREEN_WIDTH/8)*NB_BPL(a2),a2
	dbf d7,loop_ellipse2
out_ellipse_before2
	rts

************************ Routine qui rempli la DragonBall en l'encadrant
FillScreen
	move.l log_struct(pc),a0

	move.w Centre_Y(pc),d0			calcul la ligne de départ
	add.w Rayon_B(pc),d0
	subq.w #1,d0
	mulu #(SCREEN_WIDTH/8)*NB_BPL,d0

	moveq #0,d1				calcul l'adresse de depart
	move.w Rayon_A(pc),d1
	add.w #(SCREEN_WIDTH/2),d1
	lsr.w #3,d1				adr en octet
	add.l d1,d0
	add.l Scr(a0),d0			ptr source/destination
	move.l d0,ClrScr(a0)

	move.w Rayon_A(pc),d2			calcul le modulo de l'image
	lsr.w #3-1,d2
	addq.w #4,d2
	and.b #$fe,d2
	move.w d2,d1
	neg.w d1
	add.w #(SCREEN_WIDTH/8),d1
	move.w d1,Mod(a0)

	move.w Rayon_B(pc),d3			calcul de bltsize
	mulu #NB_BPL*2*64,d3
	lsr.w #1,d2
	or.w d3,d2

wait_bidule
	btst #14,dmaconr(a6)
	bne.s wait_bidule

	move.l #-1,bltafwm(a6)
	move.l d0,bltapt(a6)			init le blitter
	move.l d0,bltdpt(a6)
	move.w d1,bltamod(a6)
	move.w d1,bltdmod(a6)
	move.l #$09f0000a,bltcon0(a6)
	move.w d2,bltsize(a6)
	move.w d2,Blit(a0)
wait_fill
	btst #14,dmaconr(a6)			hahaha.. c juste pour
	bne.s wait_fill				voir le temps ke ca prend
	rts					dans la vbl!


*************************** routine pour augmenter les angles de rotations
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

************************ calcul de la matrice de rotation
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


************************ projection des points + symetrie des points
Compute_Dots
	moveq #11*(NB_STARS/2)-1,d0		11*3 points pour 3 etoiles
	move.w #ZOOM,d6
	moveq #9,d7				valeur du shift de D
stars_Ptr=*+2
	lea dots_3d,a0				pointe les points 3d originaux
	lea dots_2d(pc),a1			pointe les points 2d finaux
	lea 11*4*(NB_STARS)(a1),a2
	move.w #(SCREEN_WIDTH/2)-1,a3
	move.w Centre_Y(pc),a4
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

	move.l d1,d4
	move.l d2,d5
	neg.l d4
	neg.l d5

	add.w d6,d3				calcul du point normal
	beq.s no_divs
	divs d3,d1
	divs d3,d2

	sub.w d6,d3				calcul du symetrique
	sub.w d6,d3
	neg.w d3
	divs d3,d4
	divs d3,d5
no_divs
	muls Rapport_X(pc),d1			calcul des rapports & recentrage
	swap d1
	add.w a3,d1
	muls Rapport_Y(pc),d2
	swap d2
	add.w a4,d2
	muls Rapport_X(pc),d4
	swap d4
	add.w a3,d4
	muls Rapport_Y(pc),d5
	swap d5
	add.w a4,d5

	move.w d1,(a1)+				sauve tout ca
	move.w d2,(a1)+
	movem.w d4-d5,-(a2)

	dbf d0,loop_compute_dots	
	rts	

***************************** Affichage des etoiles
Display_Stars
	move.l log_struct(pc),a0
	move.l Scr(a0),a0
	lea (SCREEN_WIDTH/8)(a0),a2

	bsr LineInit

	lea dots_2d(pc),a1
	moveq #NB_STARS-1,d7
draw_all_stars
	moveq #10-1,d6
	move.l a2,a0

	movem.w (a1),d0-d5			un petit produit vectoriel
	sub.w d0,d2				(x2-x1)
	sub.w d1,d5				(y3-y1)
	muls d5,d2				(x2-x1)*(y3-y1)
	sub.w d0,d4				(x3-x1)
	sub.w d1,d3				(y2-y1)
	muls d4,d3				(x3-x1)*(y2-y1)
	sub.l d3,d2				(x2-x1)*(y3-y1)<(x3-x1)*(y2-y1)?
	bgt front				face devant si >0
back
draw_back_star
	lea (SCREEN_WIDTH/8)(a2),a0
	movem.w (a1),d0-d3
	addq.w #3,d0
	addq.w #3,d2

.Line	cmp.w d1,d3
	bgt.s .Line1
	beq .LineOut
	exg d0,d2
	exg d1,d3
.Line1	sub.w d0,d2
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
	add.w Table_Mulu_Line1(pc,d1.w),d4
	lea 0(a0,d4.w),a0
	move.w d0,d4
	or.w #$0b<<8|MINTERM,d4
	moveq #0,d1
	tst.w d2
	bpl.s .Line2
	neg.w d2
	moveq #4,d1
.Line2	cmp.w d2,d3
	bpl.s .Line3
	or.b #16,d1
	bra.s .Line4
.Line3	exg d2,d3
	add.b d1,d1
.Line4	addq.b #3,d1
	or.w d0,d1
	add.w d3,d3
	add.w d3,d3
	add.w d2,d2
.Line5	btst #14,dmaconr(a6)
	bne.s .Line5
	move.w d3,bltbmod(a6)
	sub.w d2,d3
	bge.s .Line6
	or.w #$40,d1
.Line6	move.w d1,bltcon1(a6)
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
.LineOut
	addq.l #4,a1
	dbf d6,draw_back_star
	addq.l #4,a1
	dbf d7,draw_all_stars
	rts

Table_Mulu_Line1
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

front
draw_front_star
	move.l a2,a0
	movem.w (a1),d0-d3
	subq.w #1,d0
	subq.w #1,d2

.Line	cmp.w d1,d3
	bgt.s .Line1
	beq .LineOut
	exg d0,d2
	exg d1,d3
.Line1	sub.w d0,d2
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
	add.w Table_Mulu_Line2(pc,d1.w),d4
	lea 0(a0,d4.w),a0
	move.w d0,d4
	or.w #$0b<<8|MINTERM,d4
	moveq #0,d1
	tst.w d2
	bpl.s .Line2
	neg.w d2
	moveq #4,d1
.Line2	cmp.w d2,d3
	bpl.s .Line3
	or.b #16,d1
	bra.s .Line4
.Line3	exg d2,d3
	add.b d1,d1
.Line4	addq.b #3,d1
	or.w d0,d1
	add.w d3,d3
	add.w d3,d3
	add.w d2,d2
.Line5	btst #14,dmaconr(a6)
	bne.s .Line5
	move.w d3,bltbmod(a6)
	sub.w d2,d3
	bge.s .Line6
	or.w #$40,d1
.Line6	move.w d1,bltcon1(a6)
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
.LineOut
	addq.l #4,a1
	dbf d6,draw_front_star
	addq.l #4,a1
	dbf d7,draw_all_stars
	rts

Table_Mulu_Line2
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

LineInit
	btst #14,dmaconr(a6)
	bne.s LineInit
	moveq #Width*Depth,d0
	move.w d0,bltcmod(a6)
	move.w d0,bltdmod(a6)
	moveq #-1,d0
	move.l d0,bltafwm(a6)
	move.l #-$8000,bltbdat(a6)
	rts	

**************************************** datas
data_base
log_struct	dc.l log_struct1
phy_struct	dc.l phy_struct2

log_struct1	dc.l Screen1
		dc.l Screen1+(SCREEN_WIDTH/8)-2
		dc.w 0
		dc.w 1<<6+1
phy_struct2	dc.l Screen2
		dc.l Screen2+(SCREEN_WIDTH/8)-2
		dc.w 0
		dc.w 1<<6+1

Rayon_A		dc.w 0
Rayon_B		dc.w 0
Centre_Y	dc.w 0
Mvt_Ptr		dc.l Dragon_Mvt
Rapport_X	dc.w 0
Rapport_Y	dc.w 0

dots_3d
	incbin "Stars.dat"
end_dots_3d

dots_2d
	dcb.w (11*2)*NB_STARS,0

Dragon_Mvt
	incbin "Dragon_Mvt.dat"
End_Table

	include "TMC_Replay.s"
	include "Song.s"

	section sample,data_c
coplist
	dc.w fmode,$0
	dc.w bplcon0,$4200
	dc.w bplcon1,$0005
	dc.w bplcon2,$0000
	dc.w diwstrt,$28a1
	dc.w diwstop,$38e1
	dc.w ddfstrt,$0050
	dc.w ddfstop,$00b8
	dc.w bpl1mod,(SCREEN_WIDTH/8)*2
	dc.w bpl2mod,(SCREEN_WIDTH/8)*2
	dc.w color00,$70a
	dc.w color01,$286
	dc.w color02,$397
	dc.w color03,$4a8
	dc.w color05,$079
	dc.w color06,$07a
	dc.w color07,$07f
	dc.w color09,$076
	dc.w color10,$077
	dc.w color11,$078
	dc.w color13,$071
	dc.w color14,$072
	dc.w color15,$04c
	dc.w $cd0f,$fffe
	dc.w color00,$405
	dc.w color01,$175
	dc.w color02,$286
	dc.w color03,$397
	dc.w color05,$078
	dc.w color06,$07b
	dc.w color07,$06e
	dc.w color09,$075
	dc.w color10,$076
	dc.w color11,$077
	dc.w color13,$070
	dc.w color14,$071
	dc.w color15,$03b
	dc.w $ffdf,$fffe
	dc.w $180f,$fffe
	dc.w bpl1mod,-((SCREEN_WIDTH/8)*NB_BPL*2+SCREEN_WIDTH/8)
	dc.w bpl2mod,-((SCREEN_WIDTH/8)*NB_BPL*2+SCREEN_WIDTH/8)
	dc.w color01,$064
	dc.w color02,$175
	dc.w color03,$286
	dc.w color05,$067
	dc.w color06,$06a
	dc.w color07,$05d
	dc.w color09,$064
	dc.w color10,$065
	dc.w color11,$066
	dc.w color13,$060
	dc.w color14,$060
	dc.w color15,$02a
	dc.l $fffffffe

	include "Samples.s"

	section prout,bss_c
Screen1	ds.b (SCREEN_WIDTH/8)*SCREEN_HEIGHT*3
Screen2 ds.b (SCREEN_WIDTH/8)*SCREEN_HEIGHT*3

