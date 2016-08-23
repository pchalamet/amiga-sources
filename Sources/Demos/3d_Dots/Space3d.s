*********************************************************
*							*
* dessine et fait tourner des étoiles en 3d plots	*
*							*
*********************************************************

	OPT O+


*--------> nb d'étoiles
nb_points=130

*--------> main init
	section nouilles,code_f

	incdir "asm:"
	incdir "asm:sources/"
	incdir "asm:datas/"
	incdir "asm:.s/Demos/3d_Dots/"
	incdir "ram:"
	include "registers.i"

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
	move.l d0,table_mulu+2-data_base(a5)	installation du ptr

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

	KILL_SYSTEM do_3d
	move.l (sp)+,a1				libère la table_mulu
	move.l #256*512,d0
	move.l (ExecBase).w,a6
	jsr FreeMem(a6)
	moveq #0,d0
	rts

do_3d
	lea $dff000,a6

	move.l #$2b812bc1,diwstrt(a6)		init écran
	move.l #$003800d0,ddfstrt(a6)		320*200
	move.w #$3200,bplcon0(a6)
	moveq #0,d0
	move.l d0,bplcon1(a6)			bplcon1 & bplcon2
	move.l d0,bpl1mod(a6)			bpl1mod & bpl2mod
	
	move.l #$00000fef,color00(a6)		init les couleurs
	move.l #$07570fef,color02(a6)
	move.l #$04240fef,color04(a6)
	move.l #$07570fef,color06(a6)
	move.w #0,fmode(a6)

	move.l #vbl,$6c.w			la vbl

	jsr mt_init

	move.w #$8300,dmacon(a6)
	move.w #$c020,intena(a6)

	WAIT_LMB_DOWN
	jsr mt_end
	RESTORE_SYSTEM


*-----------> la vbl
vbl
	SAVE_REGS
	jsr mt_music

	lea data_base(pc),a5
	lea $dff000,a6
	move.w #0,color00(a6)

	bsr gestion_deplacement
	
	movem.l log_screen(pc),a0-a1
	exg a0,a1
	movem.l a0-a1,log_screen-data_base(a5)

	move.l 4(a1),a2
	move.l a2,bpl1ptH(a6)
	add.l #10240,a2
	move.l a2,bpl2ptH(a6)
	add.l #10240,a2
	move.l a2,bpl3ptH(a6)

	movem.l (a0),a0-a1			adr clear_buff
	moveq #0,d0
	jsr (a0)				éfface les étoiles

	bsr do_angle
	bsr compute_matrix
	bsr draw_space

	VBL_SIZE color00,$fff
	move.w #$0020,intreq(a6)

	RESTORE_REGS
	rte

data_base

log_screen	dc.l struct1
phy_screen	dc.l struct2

struct1		dc.l clear_buff1
		dc.l ecran1			structure pour les écrans

struct2		dc.l clear_buff2
		dc.l ecran2

clear_buff1
	dcb.l nb_points,$1340<<16		move.b d0,d(a1) *nb_points
	rts

clear_buff2
	dcb.l nb_points,$1340<<16		move.b d0,d(a1) *nb_points
	rts

*------------> routine qui gere les <> déplacements
gestion_deplacement
	subq.w #1,mvt_timer-data_base(a5)
	bne.s no_different_mvt

	move.l mvt_ptr(pc),a0
	cmp.w #-1,(a0)				test le wait en vbl
	bne.s no_end_table_mvt

	lea table_mvt(pc),a0
	
no_end_table_mvt
	move.w (a0)+,inc_alpha+2-data_base(a5)
	move.w (a0)+,inc_teta+2-data_base(a5)
	move.w (a0)+,inc_phi+2-data_base(a5)
	move.w (a0)+,inc_X+2-data_base(a5)
	move.w (a0)+,inc_Y+2-data_base(a5)
	move.w (a0)+,inc_Z+2-data_base(a5)
	move.w (a0)+,mvt_timer-data_base(a5)
	move.l a0,mvt_ptr-data_base(a5)
	
no_different_mvt
	rts

mvt_timer	dc.w 1
mvt_ptr		dc.l table_mvt
table_mvt
	dc.w 0,0,0				angle de rot : alpha,teta,phi
	dc.w 14,0,0				déplacement : x,y,z
	dc.w 250				wait en vbl

	dc.w 0,0,0				angles<<1 car table de mots
	dc.w 12,0,-2				dir<<1 car table de mots
	dc.w 5

	dc.w 0,0,0
	dc.w 10,0,-4
	dc.w 5

	dc.w 0,0,0
	dc.w 8,0,-6
	dc.w 5

	dc.w 0,0,0
	dc.w 6,0,-8
	dc.w 5

	dc.w 0,0,0
	dc.w 4,0,-10
	dc.w 5

	dc.w 0,0,0
	dc.w 2,0,-12
	dc.w 5

	dc.w 0,0,0
	dc.w 0,0,-14
	dc.w 350
	
	dc.w 0,0,-2
	dc.w 0,0,-14
	dc.w 5

	dc.w 0,0,-4
	dc.w 0,0,-14
	dc.w 350
	
	dc.w 0,0,-2
	dc.w 0,0,-14
	dc.w 5

	dc.w 0,0,0
	dc.w 0,0,-12
	dc.w 5

	dc.w 0,0,0
	dc.w 0,0,-10
	dc.w 5

	dc.w 0,0,0
	dc.w 0,0,-8
	dc.w 5

	dc.w 0,0,0
	dc.w 0,0,-6
	dc.w 5

	dc.w 0,0,0
	dc.w 0,0,-4
	dc.w 5

	dc.w 0,0,0
	dc.w 0,0,-2
	dc.w 5

	dc.w 0,0,0
	dc.w 0,0,0
	dc.w 5

	dc.w -2,-4,-2
	dc.w 0,2,0
	dc.w 360

	dc.w 0,-4,0
	dc.w 0,4,0
	dc.w 5

	dc.w 0,-4,0
	dc.w 0,6,0
	dc.w 5

	dc.w 0,-4,0
	dc.w 0,8,0
	dc.w 5

	dc.w 0,-4,0
	dc.w 0,10,0
	dc.w 5

	dc.w 0,-4,0
	dc.w 0,12,0
	dc.w 310

	dc.w 0,-4,0
	dc.w 0,10,0
	dc.w 5

	dc.w 0,-4,0
	dc.w 0,8,0
	dc.w 5

	dc.w 0,-4,0
	dc.w 0,6,0
	dc.w 5

	dc.w 0,-4,0
	dc.w 0,4,0
	dc.w 5

	dc.w 0,-4,0
	dc.w 0,2,0
	dc.w 5

	dc.w 0,-4,0
	dc.w 0,0,0
	dc.w 5

	dc.w 0,-4,0
	dc.w 0,-2,0
	dc.w 5

	dc.w 0,-4,0
	dc.w 0,-4,0
	dc.w 5

	dc.w 0,-4,0
	dc.w 0,-6,0
	dc.w 5

	dc.w 0,-4,0
	dc.w 0,-8,0
	dc.w 5

	dc.w 0,-4,0
	dc.w 0,-10,0
	dc.w 5

	dc.w 0,-4,0
	dc.w 0,-12,0
	dc.w 310

	dc.w 0,-4,0
	dc.w 0,-10,0
	dc.w 5

	dc.w 0,-4,0
	dc.w 0,-8,0
	dc.w 5

	dc.w 0,-4,0
	dc.w 0,-6,0
	dc.w 5

	dc.w 0,-4,0
	dc.w 0,-4,0
	dc.w 5

	dc.w 0,-4,0
	dc.w 0,-2,0
	dc.w 5

	dc.w 0,-4,0
	dc.w 0,0,-2
	dc.w 5

	dc.w 0,-4,0
	dc.w 0,0,-4
	dc.w 5

	dc.w 0,-4,0
	dc.w 0,0,-6
	dc.w 5

	dc.w 0,-2,0
	dc.w 0,0,-8
	dc.w 5
	
	dc.w 0,-2,0
	dc.w 0,0,-10
	dc.w 5

	dc.w 0,-2,0
	dc.w 0,0,-12
	dc.w 5

	dc.w 0,-4,0
	dc.w 0,0,-14
	dc.w 300
	
	dc.w 0,-2,0
	dc.w 0,0,-12
	dc.w 5

	dc.w 0,-2,0
	dc.w 0,0,-10
	dc.w 5

	dc.w 0,-2,0
	dc.w 0,0,-8
	dc.w 5
	
	dc.w 0,-2,0
	dc.w 0,0,-6
	dc.w 5	

	dc.w 0,-2,0
	dc.w 0,0,-4
	dc.w 5

	dc.w 0,-2,0
	dc.w 0,0,-2
	dc.w 5

	dc.w -2,-4,-2
	dc.w 0,0,0
	dc.w 400

	dc.w -2,-4,0
	dc.w 0,-2,0
	dc.w 5

	dc.w -2,-4,0
	dc.w 0,-4,0
	dc.w 5

	dc.w -2,-4,0
	dc.w 0,-6,0
	dc.w 5
	
	dc.w -2,-4,0
	dc.w 0,-8,0
	dc.w 10
	
	dc.w -4,-4,0
	dc.w 0,-8,0
	dc.w 5

	dc.w -4,-2,0
	dc.w 0,-8,0
	dc.w 400

	dc.w -2,0,-2
	dc.w 0,-10,0
	dc.w 5

	dc.w 0,0,-4
	dc.w 0,-10,0
	dc.w 5

	dc.w 0,0,-4
	dc.w 0,-8,0
	dc.w 5

	dc.w 0,0,-2
	dc.w 0,-6,0
	dc.w 5

	dc.w 0,0,0
	dc.w 0,-4,0
	dc.w 5

	dc.w 0,0,0
	dc.w 0,-2,0
	dc.w 5
	
	dc.w 0,0,0
	dc.w 0,0,0
	dc.w 5
	
	dc.w 0,0,0
	dc.w 0,0,2
	dc.w 5
	
	dc.w 0,0,0
	dc.w 0,0,4
	dc.w 5
	
	dc.w 0,-2,0
	dc.w 0,0,6
	dc.w 5
	
	dc.w 0,-2,0
	dc.w 0,0,8
	dc.w 5
	
	dc.w 0,-4,0
	dc.w 0,0,10
	dc.w 800
	
	dc.w 0,-4,0
	dc.w 0,0,8
	dc.w 5
	
	dc.w 0,-2,0
	dc.w 0,0,6
	dc.w 5
	
	dc.w 0,-2,-2
	dc.w 0,0,4
	dc.w 5

	dc.w 0,-2,-2
	dc.w 0,-2,2
	dc.w 5

	dc.w -2,-4,-2
	dc.w 0,-4,2
	dc.w 500

	dc.w 0,-2,-2
	dc.w 0,-4,2
	dc.w 5

	dc.w 0,0,0
	dc.w 2,-2,0
	dc.w 5
	
	dc.w 0,0,0
	dc.w 4,0,0
	dc.w 5
	
	dc.w 0,0,0
	dc.w 6,0,0
	dc.w 5
	
	dc.w 0,0,0
	dc.w 8,0,0
	dc.w 5
	
	dc.w 0,0,0
	dc.w 10,0,0
	dc.w 5

	dc.w 0,0,0
	dc.w 12,0,0
	dc.w 5

	dc.w -1	

*------------> routine qui incrémente les angles
do_angle
	movem.w alpha(pc),d0-d2

inc_alpha
	add.w #0,d0
	bge.s inc_alpha_2
	add.w #720,d0
	bra.s inc_teta
inc_alpha_2
	cmp.w #720,d0
	blt.s inc_teta
	sub.w #720,d0

inc_teta
	add.w #0,d1
	bge.s inc_teta_2
	add.w #720,d1
	bra.s inc_phi
inc_teta_2
	cmp.w #720,d1
	blt.s inc_phi
	sub.w #720,d1

inc_phi
	add.w #0,d2
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

table_mulu
	lea (0).l,a1				on pointe 0*0 dans table_mulu

*-----------------> calcul de la matrice de rotation
	lea matrix(pc),a0

	move.w costeta,d6
	muls cosphi,d6				cos(teta) * cos(phi)
	asl.l #2,d6
	and.w #$fe00,d6				multiple de 512 uniquement
	lea 0(a1,d6.l),a2			adr du mulu
	move.l a2,0(a0)

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
	add.l d6,d6
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
	incbin "table_cosinus_360.dat"
table_sinus=table_cosinus+90*2

*-------------> on dessine les etoiles à l'écran
draw_space
	lea sphere_dots_coord(pc),a1

	move.l log_screen(pc),a2
	move.l 4(a2),d7				*log screen
	move.l (a2),a2
	addq.l #2,a2				*clear_buffer

	lea table_mulu40(pc),a3

	move.w #nb_points-1,d0			nb_points à afficher
compute_dot
	movem.w (a1),d1-d3			coordonnées du point

inc_X
	add.w #0,d1
	cmp.w #127*2,d1
	ble.s inc_X_2
	sub.w #512,d1
	bra.s inc_Y
inc_X_2
	cmp.w #-256,d1
	bge.s inc_Y
	add.w #512,d1

inc_Y
	add.w #0,d2
	cmp.w #127*2,d2
	ble.s inc_Y_2
	sub.w #512,d2
	bra.s inc_Z
inc_Y_2
	cmp.w #-256,d2
	bge.s inc_Z
	add.w #512,d2

inc_Z
	add.w #0,d3
	cmp.w #127*2,d3
	ble.s inc_Z_2
	sub.w #512,d3
	bra.s inc_pt_ok
inc_Z_2
	cmp.w #-256,d3
	bge.s inc_pt_ok
	add.w #512,d3

inc_pt_ok
	movem.w d1-d3,(a1)
	addq.l #6,a1

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
	add.w #130,d6				;130

	divs d6,d4				calcul de Xe
	divs d6,d5				calcul de Ye
no_div
	add.w #160,d4				recentre le point
	blt.s no_dot
	cmp.w #319,d4
	bgt.s no_dot

	add.w #128,d5
	blt.s no_dot
	cmp.w #255,d5
	bgt.s no_dot

	cmp.w #120,d6				;120
	blt.s in_bpl1
	add.w #256,d5
	cmp.w #160,d6				;160
	blt.s in_bpl1
	add.w #256,d5
in_bpl1

	add.w d5,d5
	move.w 0(a3,d5.w),d5			add #128,d5 & mulu #40,d5 
	move.b d4,d6
	lsr.w #3,d4
	add.w d4,d5
	move.w d5,(a2)
	addq.l #4,a2
	not.b d6
	move.l d7,a4
	bset d6,0(a4,d5.w)

no_dot
	dbf d0,compute_dot			loop pour tous les points
	rts

sphere_dots_coord
	incbin space.dat

table_mulu40
val set 0
	rept 256*3
	dc.w val*40
val set val+1
	endr


	include "TMC_Replay.s"
	include "Song.s"


	section mon_chien_est_noir_et_blanc,bss_c

ecran1	ds.b 10240*3
ecran2	ds.b 10240*3


	section zik,data_c
	include "Samples.s"
