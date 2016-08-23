
********************************************************************************
*************                                                       ************
*************      6 BIG BALLS   (C)1993 SYNC OF DREAMDEALERS       ************
*************                                                       ************
********************************************************************************

* utilise 16 triangles de 256 pixels de base. chaque triangle est décalé
* de 1 pixel à droite par rapport au précédent.
* => 32 octets pour le triangle
* => 02 octets pour le shift à droite
* => 44 octets pour le début ou la fin de l'image
* => 44 octets supplémentaire avant le triangle pour pouvoir afficher à droite
*                  ________________             ________________
*                    /\  | |      |                 /\| |      |
*                   /  \ | |      |    ....        /  \ |      |
*                  /    \| |      |               /   |\|      |
*                  ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯             ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*       octets:      32   2   44                  32   2   44
*
*
* structure de la table des precalculation des cercles (distances axe Z/cercle):
* dc.w nb_dist-1
* dc.l offset premiere ligne
* dc.l offset par rapport à la ligne d'avant
* dc.l offset par rapport à la ligne d'avant
* ....



*-----------------------> les includes
	opt O+,C+,NOCHKBIT

	incdir "asm:"
	incdir "asm:datas/"
	incdir "asm:sources/"
	incdir "asm:.s/demos/BigBalls/"
	incdir "asm:songs/big"
	include "registers.i"

*-----------------------> constantes pour les balls
MIN_RADIUS=16
MAX_RADIUS=127

*-----------------------> constantes pour les coplists
COPLIST_SIZE=(9+16+(1+12)*256+1)*4
ball_colors=11*4+2
bpl_ptrs=26*4+2

*-----------------------> structure d'une ball
	rsreset
ball_struct	rs.b 0
bs_Dot		rs.w 1
bs_Color	rs.w 1
bs_SIZEOF	rs.b 0

*-----------------------> zoupla... viva mes bolla !!!
	section neant,code_c

	KILL_SYSTEM BigBalls
	moveq #0,d0
	rts

*-----------------------> le programme principal
BigBalls
	lea data_base(pc),a5
	lea custom_base,a6

*--------------------------> init small_ptr
	lea small_ptr,a0
	move.l #triangle_area,d1
	move.l d1,d2				d2=bplptL
	swap d1					d1=bplptH
loop_clear_balls
	move.w d1,(a0)				bpl1pt
	move.w d2,4(a0)				
	move.w d1,8(a0)				bpl2pt
	move.w d2,12(a0)
	move.w d1,16(a0)			bpl3pt
	move.w d2,20(a0)
	move.w d1,24(a0)			bpl4pt
	move.w d2,28(a0)
	move.w d1,32(a0)			bpl5pt
	move.w d2,36(a0)
	move.w d1,40(a0)			bpl6pt
	move.w d2,44(a0)

*--------------------------> init le reste
	jsr mt_init

	move.l #vbl,$6c.w
	move.l a0,cop1lc(a6)
	clr.w copjmp1(a6)
	move.w #0,fmode(a6)
	move.w #$0c00,bplcon3(a6)

	move.w #$8240,dmacon(a6)		dma blitter
	bsr Make_Triangles			fabrication des triangles
	bsr Clear_Balls				prepare la log_coplist
	bsr Make_Coplists			fabrication des coplists

	move.w #$87c0,dmacon(a6)
	move.w #$c020,intena(a6)

********* LE PRISME
vazytoto
	move.w #420,PosX-data_base(a5)
	move.w #128,PosY-data_base(a5)
	move.w #11000,Zoom-data_base(a5)
	clr.w Alpha-data_base(a5)
	clr.w Teta-data_base(a5)
	clr.w Phi-data_base(a5)
	move.w #12,IncAlpha-data_base(a5)
	move.w #-8,IncTeta-data_base(a5)
	move.w #10,IncPhi-data_base(a5)

	lea dots_3D(pc),a0
	move.w #2500,(a0)+			Dot0
	clr.l (a0)+
	clr.w (a0)+				Dot1
	move.w #2500,(a0)+
	clr.w (a0)+
	move.w #-2500,(a0)+			Dot2
	clr.l (a0)+
	clr.w (a0)+				Dot3
	move.w #-2500,(a0)+
	clr.w (a0)+
	clr.l (a0)+				Dot4
	move.w #2500,(a0)+
	clr.l (a0)+				Dot5
	move.w #-2500,(a0)+

	moveq #123-1,d0
wayne
	stop #$2200
	sub.w #71,Zoom-data_base(a5)
	subq.w #2,PosX-data_base(a5)
	dbf d0,wayne

	move.w #2220,Zoom-data_base(a5)
	move.w #150-1,d0
world
	stop #$2200
	dbf d0,world
	moveq #123-1,d0
megateuf
	stop #$2200
	add.w #71,Zoom-data_base(a5)
	subq.w #2,PosX-data_base(a5)
	dbf d0,megateuf

********* LE CERCLE
	move.w #176,PosX-data_base(a5)
	move.w #128,PosY-data_base(a5)
	move.w #1000,Zoom-data_base(a5)
	clr.w Alpha-data_base(a5)
	clr.w Teta-data_base(a5)
	clr.w Phi-data_base(a5)
	clr.w IncAlpha-data_base(a5)
	clr.w IncTeta-data_base(a5)
	move.w #10,IncPhi-data_base(a5)

	lea dots_3D(pc),a0
	move.w #3300,(a0)+			Dot0
	clr.l (a0)+
	move.l #(1650<<16)!(2857),(a0)+		Dot1
	clr.w (a0)+
	move.l #(-1650<<16)!(2857),(a0)+	Dot2
	clr.w (a0)+
	move.w #-3300,(a0)+			Dot3
	clr.l (a0)+
	move.w #-1650,(a0)+			Dot4
	move.w #-2857,(a0)+
	clr.w (a0)+
	move.w #1650,(a0)+			Dot5
	move.w #-2857,(a0)+
	clr.w (a0)+

	move.w #140-1,d0
	move.w #150,d1
partytime
	stop #$2200
	add.w d1,Zoom-data_base(a5)
	subq.w #2,d1
	dbf d0,partytime

	move.w #10,IncAlpha-data_base(a5)
	move.w #-6,IncTeta-data_base(a5)
	move.w #4,IncPhi-data_base(a5)
	move.w #2420,Zoom-data_base(a5)

	move.w #200,d0
ratounette
	stop #$2200
	dbf d0,ratounette

	moveq #123-1,d0
liverulez
	stop #$2200
	add.w #71,Zoom-data_base(a5)
	addq.w #1,PosX-data_base(a5)
	addq.w #2,PosY-data_base(a5)
	dbf d0,liverulez

********* LA DROITE
	move.w #-140,PosX-data_base(a5)
	move.w #128,PosY-data_base(a5)
	move.w #9000,Zoom-data_base(a5)
	clr.w Alpha-data_base(a5)
	clr.w Teta-data_base(a5)
	clr.w Phi-data_base(a5)
	clr.w IncAlpha-data_base(a5)
	clr.w IncTeta-data_base(a5)
	clr.w IncPhi-data_base(a5)

	lea dots_3D(pc),a0
	move.w #-8000,(a0)+			Dot0
	clr.l (a0)+
	move.w #-4800,(a0)+			Dot1
	clr.l (a0)+
	move.w #-1600,(a0)+			Dot2
	clr.l (a0)+
	move.w #1600,(a0)+			Dot3
	clr.l (a0)+
	move.w #4800,(a0)+			Dot4
	clr.l (a0)+
	move.w #8000,(a0)+			Dot5
	clr.l (a0)+

	move.w #170-1,d0
donald
	stop #$2200
	addq.w #4,PosX-data_base(a5)
	dbf d0,donald

	move.w #8,IncPhi-data_base(a5)
	move.w #190-1,d0
	move.w #-150,d1
gontran
	stop #$2200
	subq.w #4,PosX-data_base(a5)
	add.w d1,Zoom-data_base(a5)
	cmp.w #1650,Zoom-data_base(a5)
	bgt.s .yo1
	neg.w d1
.yo1
	cmp.w #9000,Zoom-data_base(a5)
	blt.s .yo2
	neg.w d1
.yo2
	dbf d0,gontran

	move.w #-1000,PosX-data_base(a5)
	move.w #128,PosY-data_base(a5)
	move.w #1600,Zoom-data_base(a5)
	clr.w Alpha-data_base(a5)
	clr.w Teta-data_base(a5)
	clr.w Phi-data_base(a5)
	clr.w IncAlpha-data_base(a5)
	clr.w IncTeta-data_base(a5)
	clr.w IncPhi-data_base(a5)

	move.w #160-1,d0
bananajo
	stop #$2200
	add.w #20,PosX-data_base(a5)
	dbf d0,bananajo

********* UN CERCLE QUI ROULE
	move.w #-200,PosX-data_base(a5)
	move.w #80,PosY-data_base(a5)
	move.w #3200,Zoom-data_base(a5)
	clr.w Alpha-data_base(a5)
	clr.w Teta-data_base(a5)
	clr.w Phi-data_base(a5)
	clr.w IncAlpha-data_base(a5)
	clr.w IncTeta-data_base(a5)
	move.w #8,IncPhi-data_base(a5)

	lea dots_3D(pc),a0
	move.w #3300,(a0)+			Dot0
	clr.l (a0)+
	move.l #(1650<<16)!(2857),(a0)+		Dot1
	clr.w (a0)+
	move.l #(-1650<<16)!(2857),(a0)+	Dot2
	clr.w (a0)+
	move.w #-3300,(a0)+			Dot3
	clr.l (a0)+
	move.w #-1650,(a0)+			Dot4
	move.w #-2857,(a0)+
	clr.w (a0)+
	move.w #1650,(a0)+			Dot5
	move.w #-2857,(a0)+
	clr.w (a0)+

	move.w #150-1,d0
dingo
	stop #$2200
	addq.w #4,PosX-data_base(a5)
	dbf d0,dingo

	move.w #-10,IncPhi-data_base(a5)
	move.w #100-1,d0
pluto
	stop #$2200
	subq.w #6,PosX-data_base(a5)
	dbf d0,pluto

********* LE PRISME
	move.w #176,PosX-data_base(a5)
	move.w #-116,PosY-data_base(a5)
	move.w #11000,Zoom-data_base(a5)
	clr.w Alpha-data_base(a5)
	clr.w Teta-data_base(a5)
	clr.w Phi-data_base(a5)
	clr.w IncAlpha-data_base(a5)
	clr.w IncTeta-data_base(a5)
	clr.w IncPhi-data_base(a5)

	lea dots_3D(pc),a0
	move.w #2500,(a0)+			Dot0
	clr.l (a0)+
	clr.w (a0)+				Dot1
	move.w #2500,(a0)+
	clr.w (a0)+
	move.w #-2500,(a0)+			Dot2
	clr.l (a0)+
	clr.w (a0)+				Dot3
	move.w #-2500,(a0)+
	clr.w (a0)+
	clr.l (a0)+				Dot4
	move.w #2500,(a0)+
	clr.l (a0)+				Dot5
	move.w #-2500,(a0)+

	moveq #123-1,d0
terminator
	stop #$2200
	sub.w #71,Zoom-data_base(a5)
	addq.w #2,PosY-data_base(a5)
	dbf d0,terminator

	move.w #6,IncAlpha-data_base(a5)
	move.w #10,IncTeta-data_base(a5)
	move.w #-4,IncPhi-data_base(a5)
	move.w #200-1,d0
asterohache
	stop #$2200
	dbf d0,asterohache

	moveq #123-1,d0
disneyparade
	stop #$2200
	add.w #71,Zoom-data_base(a5)
	subq.w #2,PosX-data_base(a5)
	subq.w #2,PosY-data_base(a5)
	dbf d0,disneyparade

	btst #6,ciaapra
	bne vazytoto

	jsr mt_end

	RESTORE_SYSTEM


********************************************************************************
*************                                                       ************
*************             FABRICATION DES 16 TRIANGLES              ************
*************                                                       ************
********************************************************************************
Make_Triangles
	btst #14,dmaconr(a6)
	bne.s Make_Triangles

	lea triangle_area,a4
loop_make_triangle
	move.l a4,bltdpt(a6)			efface d'abord la 1ere image
	clr.w bltdmod(a6)
	move.l #$01000000,bltcon0(a6)
	move.w #(129<<6)!(39),bltsize(a6)

wait_clear_triangle
	btst #14,dmaconr(a6)
	bne.s wait_clear_triangle

*-------------------> trace le bord gauche du triangle
make_line1
	lea (32+2+44)*128+44(a4),a0
	move.w #$8000,d0
	moveq #128-1,d1
build_line1
	or.w d0,(a0)
	lea -(32+2+44)(a0),a0
	ror.w #1,d0
	bcs.s change1
	dbf d1,build_line1
	bra.s make_line2
change1
	addq.l #2,a0
	dbf d1,build_line1

*-------------------> trace le bord droit du triangle
make_line2
	lea (32+2+44)*128+44+32-2(a4),a0
	moveq #1,d0
	moveq #128-1,d1
build_line2
	or.w d0,(a0)
	lea -(32+2+44)(a0),a0
	add.w d0,d0
	beq.s change2
	dbf d1,build_line2
	bra.s build_others
change2
	moveq #1,D0
	subq.l #2,a0
	dbf d1,build_line2

build_others
	lea (32+2+44)*129-2(a4),a0
	move.l a0,bltapt(a6)			remplissage du triangle
	move.l a0,bltdpt(a6)
	clr.l bltamod(a6)
	move.l #$09f0000a,bltcon0(a6)
	move.w #(129<<6)!(39),bltsize(a6)

	move.w #$19f0,d0			recopie du triangle avec
	moveq #15,d1				un decalage de 1 pixel à
	bra.s wait_dup_triangle			chaque fois

loop_all_triangle
	lea (32+2+44)*129(a4),a4
	move.l #triangle_area,bltapt(a6)
	move.l a4,bltdpt(a6)
	clr.l bltamod(a6)
	move.w d0,bltcon0(a6)
	clr.w bltcon1(a6)
	move.w #(129<<6)!(39),bltsize(a6)

	add.w #$1000,d0

wait_dup_triangle
	btst #14,dmaconr(a6)
	bne.s wait_dup_triangle

	dbf d1,loop_all_triangle
	rts



********************************************************************************
*************                                                       ************
*************               FABRICATION DES COPLISTS                ************
*************                                                       ************
********************************************************************************
Make_Coplists
	lea coplist1,a0
	move.l a0,a1
	move.l #(bplcon0<<16)!$6600,(a1)+
	move.l #(bplcon1<<16),(a1)+
	move.l #(bplcon2<<16)!$40,(a1)+
	move.l #(diwstrt<<16)!$2b71,(a1)+
	move.l #(diwstop<<16)!$2bd1,(a1)+
	move.l #(ddfstrt<<16)!$30,(a1)+
	move.l #(ddfstop<<16)!$d8,(a1)+
	move.l #(bpl1mod<<16)!(32+2),(a1)+
	move.l #(bpl2mod<<16)!(32+2),(a1)+
	move.l #(color00<<16)!$789,(a1)+
	move.l #(color08<<16)!$312,(a1)+
	move.l #(color01<<16)!$312,(a1)+
	move.l #(color02<<16)!$312,(a1)+
	move.l #(color03<<16)!$312,(a1)+
	move.l #(color04<<16)!$312,(a1)+
	move.l #(color05<<16)!$312,(a1)+
	move.l #(color06<<16)!$312,(a1)+
	move.l #(color07<<16)!$312,(a1)+
	move.l #(color09<<16)!$312,(a1)+
	move.l #(color10<<16)!$312,(a1)+
	move.l #(color11<<16)!$312,(a1)+
	move.l #(color12<<16)!$312,(a1)+
	move.l #(color13<<16)!$312,(a1)+
	move.l #(color14<<16)!$312,(a1)+
	move.l #(color15<<16)!$312,(a1)+

	move.w #$2adf,d0
	move.w #256-1,d1
loop_make_ptr
	moveq #6*2-1,d2
	move.w d0,(a1)+
	move.w #$fffe,(a1)+
	move.l #(bpl1ptH<<16),d3
loop_make_line
	move.l d3,(a1)+
	add.l #(2<<16),d3
	dbf d2,loop_make_line
	add.w #$0100,d0
	dbf d1,loop_make_ptr
	move.l #$fffffffe,(a1)+

	move.w #COPLIST_SIZE/4-1,d0
loop_dup_coplist
	move.l (a0)+,(a1)+
	dbf d0,loop_dup_coplist
	rts	



********************************************************************************
*************                                                       ************
*************              INTERRUPION NIVEAU 3 - VBL               ************
*************                                                       ************
********************************************************************************
vbl
	movem.l d0-d7/a0-a6,-(sp)

	jsr mt_music

	lea data_base(pc),a5
	lea custom_base,a6

	bsr Clear_Balls
	bsr Compute_Matrix
	bsr Compute_Dots
	bsr Sort_Balls
	bsr Display_Balls

	movem.w IncAlpha(pc),d0-d2
	bsr.s Incrize_Angles

	bsr Flip_Coplist

	btst #10,potinp(a6)
	bne.s no_right
	move.w #$fff,color00(a6)
no_right
	move.w #$0020,intreq(a6)

	movem.l (sp)+,d0-d7/a0-a6
	rte



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
	muls.w cosphi,d6			cos(teta) * cos(phi)
	swap d6
	move.w d6,(a0)

	move.w costeta,d6
	muls.w sinphi,d6			cos(teta) * sin(phi)
	swap d6
	move.w d6,2(a0)

	move.w sinteta,d6
	neg.w d6
	asr.w #1,d6				on perd un bit à cause du swap
	move.w d6,4(a0)				-sin(teta)

	move.w costeta,d6
	muls.w sinalpha,d6			cos(teta) * sin(alpha)
	swap d6
	move.w d6,10(a0)

	move.w costeta,d6
	muls.w cosalpha,d6			cos(teta) * cos(alpha)
	swap d6
	move.w d6,16(a0)
	
	move.w sinalpha,d6
	muls.w sinteta,d6			sin(alpha) * sin(teta)
	swap d6
	rol.l #1,d6
	move.w d6,a1

	muls.w cosphi,d6			sin(alpha)*sin(teta)*cos(phi)
	move.w cosalpha,d7
	muls.w sinphi,d7			cos(alpha) * sin(phi)
	sub.l d7,d6
	swap d6
	move.w d6,6(a0)

	move.w a1,d6
	muls.w sinphi,d6			sin(alpha)*sin(teta)*sin(phi)
	move.w cosalpha,d7
	muls.w cosphi,d7			cos(alpha) * cos(phi)
	add.l d7,d6
	swap d6
	move.w d6,8(a0)

	move.w cosalpha,d6
	muls.w sinteta,d6			cos(alpha) * sin(teta)
	swap d6
	rol.l #1,d6
	move.w d6,a1

	muls.w cosphi,d6			cos(alpha)*sin(teta)*cos(phi)
	move.w sinalpha,d7
	muls.w sinphi,d7			sin(alpha) * sin(phi)
	add.l d7,d6
	swap d6
	move.w d6,12(a0)

	move.w a1,d6
	muls.w sinphi,d6			cos(alpha)*sin(teta)*sin(phi)
	move.w sinalpha,d7
	muls.w cosphi,d7			sin(alpha) * cos(phi)
	sub.l d7,d6
	swap d6
	move.w d6,14(a0)		
	rts



********************************************************************************
*************                                                        ***********
*************  TRANSFORMATIONS DES COORDONNEES 3D EN COORDONNEES 2D  ***********
*************                                                        ***********
********************************************************************************
Compute_Dots
	lea dots_3D(pc),a0
	lea dots_2D(pc),a4
	movem.w PosX(pc),a1-a3
	moveq #6-1,d0
	moveq #9,d7				valeur du shift de D

loop_compute_dots
	movem.w (a0),d1-d3			coord 3d du point
	muls.w matrix(pc),d1
	muls.w matrix+2(pc),d2
	muls.w matrix+4(pc),d3
	add.l d3,d2
	add.l d2,d1
	swap d1
	ext.l d1
	lsl.l d7,d1				X=X*D

	movem.w (a0),d2-d4			coord 3d du point
	muls.w matrix+6(pc),d2
	muls.w matrix+8(pc),d3
	muls.w matrix+10(pc),d4
	add.l d4,d3
	add.l d3,d2
	swap d2					Y
	ext.l d2
	lsl.l d7,d2				Y=Y*D

	movem.w (a0)+,d3-d5			coord 3d du point
	muls.w matrix+12(pc),d3
	muls.w matrix+14(pc),d4
	muls.w matrix+16(pc),d5
	add.l d5,d4
	add.l d4,d3
	swap d3					Z
	add.w a3,d3				zjoute le zoom

	beq.s no_divs
	divs d3,d1				Xe=X*D/Z
	divs d3,d2				Ye=Y*D/Z
no_divs
	add.w a1,d1				recentre à l'écran
	add.w a2,d2
	move.w d1,(a4)+				sauve Xe,Ye,Depth
	move.w d2,(a4)+
	move.w d3,(a4)+
	dbf d0,loop_compute_dots	
	rts	





********************************************************************************
*************                                                        ***********
*************       EFFACAGE DES BALLS DANS LA COPLIST LOGIQUE       ***********
*************                                                        ***********
********************************************************************************
Clear_Balls
	btst #14,dmaconr(a6)
	bne.s Clear_Balls

	move.l #small_ptr,bltapt(a6)		reinite les ptrs avec
	move.l log_coplist(pc),a0		le blitter...
	lea bpl_ptrs(a0),a0
	move.l a0,bltdpt(a6)
	move.l #$09f00000,bltcon0(a6)
	move.w #-46,bltamod(a6)
	move.w #6,bltdmod(a6)
	moveq #-1,d0
	move.l d0,bltafwm(a6)
	move.w #(256<<6)!(23),bltsize(a6)
	rts



********************************************************************************
*************                                                        ***********
*************     TRIAGE DES BALLS ET MISE EN PLACE DES COULEURS     ***********
*************                                                        ***********
********************************************************************************
Sort_Balls	
	lea ball_ptr(pc),a0
	lea dots_2D(pc),a1
	moveq #6-1,d0

big_loop_sort_element
	subq.w #1,d0				on trie tjs sur N+1
	blt.s end_sort
	move.w d0,d1				nb d'élément à trier
	move.l a0,a2				*element
	moveq #0,d2				la marque
loop_sort_element
	move.l (a2)+,a3				*element1
	move.w bs_Dot(a3),d3
	move.w 4(a1,d3.w),d3			profondeur élément 1
loop_sort_element_second
	move.l (a2),a4				*element2
	move.w bs_Dot(a4),d4
	cmp.w 4(a1,d4.w),d3			element2<element1?
	bge.s element_ok
	move.l a4,-4(a2)			échange les ptrs
	move.l a3,(a2)+
	addq.w #1,d2				signale le changement
	dbf d1,loop_sort_element_second
	bra.s big_loop_sort_element
element_ok
	dbf d1,loop_sort_element
	tst.w d2
	bne.s big_loop_sort_element
end_sort

	move.l log_coplist(pc),a1
	lea ball_colors(a1),a1

	move.l (a0)+,a2				ball1
	move.w bs_Color(a2),(a1)
	move.l (a0)+,a2				ball2
	move.w bs_Color(a2),4(a1)
	move.w bs_Color(a2),8(a1)
	move.l (a0)+,a2				ball3
	move.w bs_Color(a2),12(a1)
	move.w bs_Color(a2),16(a1)
	move.w bs_Color(a2),20(a1)
	move.w bs_Color(a2),24(a1)

	move.l (a0)+,a2				ball4
	move.w bs_Color(a2),28(a1)
	move.l (a0)+,a2				ball5
	move.w bs_Color(a2),32(a1)
	move.w bs_Color(a2),36(a1)
	move.l (a0)+,a2				ball6
	move.w bs_Color(a2),40(a1)
	move.w bs_Color(a2),44(a1)
	move.w bs_Color(a2),48(a1)
	move.w bs_Color(a2),52(a1)
	
	rts



********************************************************************************
*************                                                        ***********
*************             AFFICHAGE DE TOUTES LES BALLS              ***********
*************                                                        ***********
********************************************************************************
Display_Balls
	btst #14,dmaconr(a6)
	bne.s Display_Balls

	move.l log_coplist(pc),a4
	lea bpl_ptrs(a4),a4
	lea ball_ptr(pc),a5
	lea dots_2D(pc),a6

*----------------------> traite les bpl impaires d'abord
	moveq #3-1,d7
loop_display_odd_balls
	move.l (a5)+,a0				va chercher une struct ball

	move.w bs_Dot(a0),d0			# du point
	movem.w (a6,d0.w),d0/d1/d3		Xe,Ye,Depth
	move.l #127*1600,d2
	tst.w d3				Radius/Depth ?
	beq.s .no_divs
	divs d3,d2
.no_divs
	move.l a4,a0
	bsr.s Big_Ball
	lea 16(a4),a4				bpl impaire suivant
	dbf d7,loop_display_odd_balls

*----------------------> traite les bpl paires ensuite
	lea -16*3+8(a4),a4
	moveq #3-1,d7
loop_display_even_balls
	move.l (a5)+,a0				va chercher une struct ball

	move.w bs_Dot(a0),d0			# du point
	movem.w (a6,d0.w),d0/d1/d3		Xe,Ye,Depth
	move.l #127*1600,d2
	tst.w d3				Radius/Depth ?
	beq.s .no_divs
	divs d3,d2
.no_divs
	move.l a4,a0
	bsr.s Big_Ball
	lea 16(a4),a4				bpl impaire suivant
	dbf d7,loop_display_even_balls

	lea data_base(pc),a5
	lea custom_base,a6
	rts	
	


********************************************************************************
*************                                                        ***********
*************                  AFFICHAGE D'UNE BALL                  ***********
*************                                                        ***********
********************************************************************************
* a0=ptr coplist bpl
* d0=coord X/ecran
* d1=coord Y/ecran
* d2=rayon
Big_Ball
*---------------------> vire les balls trop grosse ou trop petite
	cmp.w #MIN_RADIUS,d2
	blt no_ball
	cmp.w #MAX_RADIUS,d2
	bgt no_ball

*---------------------> conversion du X de l'ecran en X sur le triangle
	neg.w d0
	add.w #128+352+16,d0
	ble.s no_ball
	cmp.w #352+256,d0
	bge.s no_ball

*---------------------> recherche un ptr sur la table des distances
	move.w d2,d3
	sub.w #16,d3				les cercles commencent
	add.w d3,d3				à partir de 16
	add.w d3,d3
	lea RadiusPtr(pc),a1
	move.l (a1,d3.w),a1

*---------------------> recherche le bon triangle au bon offset
	move.w d0,d3
	not.w d3
	and.w #$f,d3
	mulu.w #(32+2+44)*129,d3
	add.l #triangle_area,d3
	move.l d3,a2
	lsr.w #4,d0				\ cnop 0,2:d0
	add.w d0,d0				/
	lea (a2,d0.w),a2			ca c la bonne colonne

*---------------------> initialisation des ptrs videos dans la coplist
* d1.w=PosY
* a0.l=ptr coplist
* a1.l=ptr cercle
* a2.l=ptr bitmap triangle
	move.w (a1)+,d0
	tst.w d1
	ble top_not_visible
	
	move.w d1,d2
	sub.w #255,d2
	bge bottom_not_visible

	moveq #4+8*6,d6				inc des ptrs coplists
	move.w d1,d2
	mulu.w d6,d2
	lea (a0,d2.l),a0			\ ptrs dans la coplist
	move.l a0,a3				/

	cmp.w d0,d1				ca frotte en haut ?
	blt.s top_cut

	move.w #255,d2				ca frotte en bas ?
	sub.w d1,d2
	cmp.w d0,d2
	blt.s bottom_cut

********************************************************************************

no_cut
	move.l a2,d1
.init_ball
	add.l (a1)+,d1
	move.w d1,4(a0)
	move.w d1,4(a3)
	swap d1
	move.w d1,(a0)
	move.w d1,(a3)
	swap d1
	sub.l d6,a0
	add.l d6,a3
	dbf d0,.init_ball
no_ball
	rts
	
********************************************************************************

bottom_cut
	sub.w d2,d0
	move.l a2,d1
.init_ball_common
	add.l (a1)+,d1
	move.w d1,4(a0)
	move.w d1,4(a3)
	swap d1
	move.w d1,(a0)
	move.w d1,(a3)
	swap d1
	sub.l d6,a0
	add.l d6,a3
	dbf d2,.init_ball_common
	bra.s .start_init_ball
.init_ball_part
	add.l (a1)+,d1
	move.w d1,4(a0)
	swap d1
	move.w d1,(a0)
	swap d1
	sub.l d6,a0
.start_init_ball
	dbf d0,.init_ball_part
	rts

********************************************************************************

top_cut
	sub.w d1,d0
	move.l a2,d2
.init_ball_common
	add.l (a1)+,d2
	move.w d2,4(a0)
	move.w d2,4(a3)
	swap d2
	move.w d2,(a0)
	move.w d2,(a3)
	swap d2
	sub.l d6,a0
	add.l d6,a3
	dbf d1,.init_ball_common
	bra.s .start_init_ball
.init_ball_part
	add.l (a1)+,d2
	move.w d2,4(a3)
	swap d2
	move.w d2,(a3)
	swap d2
	add.l d6,a3
.start_init_ball
	dbf d0,.init_ball_part
	rts
	
********************************************************************************

bottom_not_visible
	sub.w d2,d0
	bge.s .start_get
	rts

.get_first_ptr
	add.l (a1)+,a2
.start_get
	dbf d2,.get_first_ptr

	lea (4+8*6)*255(a0),a0
	move.l a2,d1				init les ptrs dans la coplist
.init_ball
	add.l (a1)+,d1
	move.w d1,4(a0)
	swap d1
	move.w d1,(a0)
	swap d1
	lea -(4+8*6)(a0),a0
	dbf d0,.init_ball
	rts

********************************************************************************

top_not_visible
	neg.w d1				on en voit un bout de la
	sub.w d1,d0				moitié d'en bas ??
	bge.s .start_get
	rts

.get_first_ptr
	add.l (a1)+,a2
.start_get
	dbf d1,.get_first_ptr

	move.l a2,d1				init les ptrs dans la coplist
.init_ball
	add.l (a1)+,d1
	move.w d1,4(a0)
	swap d1
	move.w d1,(a0)
	swap d1
	lea 4+8*6(a0),a0
	dbf d0,.init_ball
	rts

********************************************************************************


********************************************************************************
*************                                                        ***********
*************                  ECHANGE DES COPLISTS                  ***********
*************                                                        ***********
********************************************************************************
Flip_Coplist
	move.l log_coplist(pc),d0
	move.l phy_coplist,log_coplist-data_base(a5)
	move.l d0,phy_coplist-data_base(a5)
	move.l d0,cop1lc(a6)
	rts



********************************************************************************
*************                                                        ***********
*************                         DATAS                          ***********
*************                                                        ***********
********************************************************************************
data_base
log_coplist	dc.l coplist1
phy_coplist	dc.l coplist2

matrix		dcb.w 3*3,0			la matrice de rotation
Table_Cosinus
	incbin "table_cosinus_720.dat"
Table_Sinus=Table_Cosinus+90*4

PosX		dc.w 0
PosY		dc.w 0
Zoom		dc.w 0
Alpha		dc.w 0
Teta		dc.w 0
Phi		dc.w 0
IncAlpha	dc.w 0
IncTeta		dc.w 0
IncPhi		dc.w 0
dots_3D
	dcb.w 6*3,0
dots_2D
	dcb.w 6*3,0
ball_ptr
	dc.l ball1_1
	dc.l ball2_1
	dc.l ball3_1
	dc.l ball4_1
	dc.l ball5_1
	dc.l ball6_1

**************** un cercle de balls
ball1_1
	dc.w 6*0
	dc.w $865
ball2_1
	dc.w 6*1
	dc.w $586
ball3_1
	dc.w 6*2
	dc.w $568
ball4_1
	dc.w 6*3
	dc.w $567
ball5_1
	dc.w 6*4
	dc.w $657
ball6_1
	dc.w 6*5
	dc.w $675

RadiusPtr
	include "RadiusPtr.s"
RadiusTable
	incbin "PrecalcRadius.DAT"

small_ptr
	dc.w 0
	dc.w bpl1ptL,0
	dc.w bpl2ptH,0
	dc.w bpl2ptL,0
	dc.w bpl3ptH,0
	dc.w bpl3ptL,0
	dc.w bpl4ptH,0
	dc.w bpl4ptL,0
	dc.w bpl5ptH,0
	dc.w bpl5ptL,0
	dc.w bpl6ptH,0
	dc.w bpl6ptL,0

	include "TMC_Replay.s"
	include "Song.s"
	include "Samples.s"

	section ballon,bss_c
triangle_area
	ds.b (32+2+44)*129*16+4
coplist1
	ds.b COPLIST_SIZE
coplist2
	ds.b COPLIST_SIZE

