**************************************************
*						 *
* dessine et fait tourner une sphère en 3d plots *
*						 *
**************************************************

	opt O+

*--------> nb d'étoiles
nb_points=270

*--------> main init
	section sphere,code_f

	incdir "asm:"

	include "sources/registers.i"

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

	bsr.s save_all

	lea $dff000,a6
	lea data_base(pc),a5

	move.w #$7fff,d0			vire tout !
	move.w d0,intena(a6)
	move.w d0,dmacon(a6)
	
	move.l #$298129c1,diwstrt(a6)		init écran
	move.l #$003800d0,ddfstrt(a6)		320*200*4
	moveq #0,d0
	move.l d0,bplcon1(a6)			bplcon1 & bplcon2
	move.l d0,bpl1mod(a6)			bpl1mod & bpl2mod
	
	move.l #coplist,cop1lc(a6)
	move.w d0,copjmp1(a6)

	move.l #vbl,$6c.w			la vbl

	bsr mt_init

	move.w #$8380,dmacon(a6)
	move.w #$c020,intena(a6)

mickey	btst #6,ciaapra
	bne.s mickey
	bsr mt_end
	bsr.s restore_all

	move.l (sp)+,a1				libère la memoire allouée
	move.l #256*512,d0
	move.l (ExecBase).w,a6
	jsr FreeMem(a6)
	moveq #0,d0
	rts

	include "sources/save_all.s"
	include "sources/FastPlay.s"
	incdir "asm:3d_Dots"

current_fade
	dc.b 7
fade_counter
	dc.b 15
nb_dots_flags
	dc.b 12
	even
*-----------> la vbl
vbl
	move.b current_fade(pc),d0
	beq no_fade_at_all

test_7
	cmp.b #7,d0
	bne.s test_6
	lea Table1(pc),a0				SYNC devient blanc
	lea label_1,a1
	bsr Fade
	bra test_end_fade

test_6
	cmp.b #6,d0
	bne.s test_5
	lea Table2(pc),a0				SYNC devient gris
	lea label_1,a1
	bsr Fade
	lea Table1(pc),a0				PROUDLY devient blanc
	lea label_2,a1
	bsr Fade
	bra test_end_fade	

test_5
	cmp.b #5,d0
	bne.s test_4
	lea Table2(pc),a0				PROUDLY devient gris
	lea label_2,a1
	bsr Fade
	lea Table1(pc),a0				PRESENTS devient blanc
	lea label_3,a1
	bsr Fade
	bra test_end_fade

test_4
	cmp.b #4,d0
	bne.s test_3
	lea Table3(pc),a0				PROUDLY devient noir
	lea label_2,a1
	bsr Fade
	lea Table2(pc),a0				PRESENTS devient gris
	lea label_3,a1
	bsr Fade
	lea Table1(pc),a0				A NEW DEMO devient blanc
	lea label_4,a1
	bsr Fade
	bra test_end_fade

test_3
	cmp.b #3,d0
	bne.s test_2
	lea Table3(pc),a0				PRESENTS devient noir
	lea label_3,a1
	bsr Fade
	lea Table2(pc),a0				A NEW DEMO devient gris
	lea label_4,a1
	bsr Fade
	lea Table1(pc),a0				CALLED devient blanc
	lea label_5,a1
	bsr Fade
	bra.s test_end_fade

test_2
	cmp.b #2,d0
	bne.s test_1
	lea Table3(pc),a0				A NEW DEMO devient noir
	lea label_4,a1
	bsr Fade
	lea Table2(pc),a0				CALLED devient gris
	lea label_5,a1
	bsr Fade
	lea Table1(pc),a0				BALL deient blanc
	lea label_6,a1
	bsr Fade
	bra.s test_end_fade

test_1
	lea table3(pc),a0				CALLED devient noir
	lea label_5,a1
	bsr Fade
	lea Table4(pc),a0				BALL devient multicolor
	lea label_6,a1
	bsr Fade
	lea Table5(pc),a0				met le sol bleu
	lea label_7,a1
	bsr Fade

test_end_fade
	lea data_base(pc),a5
	tst.b d0
	beq.s display_screen
	subq.b #1,fade_counter-data_base(a5)
	bne.s display_screen
	move.b #15,fade_counter-data_base(a5)
	subq.b #1,current_fade-data_base(a5)
	bra.s display_screen

no_fade_at_all
	bsr mt_music

	lea data_base(pc),a5
	lea $dff000,a6

display_screen
	lea logo_screen,a0
	move.l a0,bpl2ptH(a6)
	lea 10240(a0),a0
	move.l a0,bpl3ptH(a6)
	lea 10240(a0),a0
	move.l a0,bpl4ptH(a6)

	bsr vu_metre

	movem.l log_screen(pc),a0-a1
	exg a0,a1
	movem.l a0-a1,log_screen-data_base(a5)

	move.l 4(a1),bpl1ptH(a6)

	tst.b current_fade-data_base(a5)
	bne.s vbl_no_ball

	movem.l (a0),a0-a1			adr clear_buff
	jsr (a0)				éfface les étoiles

	cmp.w #269,nb_dots+2-data_base(a5)
	beq.s all_dots_ok
	subq.b #1,nb_dots_flags-data_base(a5)
	bne.s all_dots_ok
	move.b #12,nb_dots_flags-data_base(a5)
	add.w #30,nb_dots+2-data_base(a5)

all_dots_ok
	bsr do_angle
	bsr compute_matrix

	bsr draw_sphere

vbl_no_ball
	lea $dff000,a6
	btst #10,potgor(a6)
	bne.s no_red
	move.w #$f00,color00(a6)
no_red
	move.w #$0020,intreq(a6)
	rte

data_base

log_screen	dc.l struct1
phy_screen	dc.l struct2

struct1		dc.l clear_buff1
		dc.l ecran1			structure pour les écrans

struct2		dc.l clear_buff2
		dc.l ecran2

clear_buff1
	moveq #0,d0
	dcb.l nb_points,$1340<<16		move.b d0,d(a1) *nb_points
	rts

clear_buff2
	moveq #0,d0
	dcb.l nb_points,$1340<<16		move.b d0,d(a1) *nb_points
	rts

*------------> routine qui fait un petit vu-metre à l'écran
vu_metre
	lea mt_voice1(pc),a0
	lea vu_metre_cop+6,a1
	moveq #4-1,d0
	
do_vu_metre
	move.w (a0),d1				regarde si une note a été
	and.w #$0fff,d1				jouée
	beq.s vu_next
	move.w #$1000,(a1)
	and.w #$f000,(a0)
vu_next
	add.l #28,a0
	add.l #16,a1
	dbf d0,do_vu_metre	

	moveq #4-1,d0				descend la couleur d'un cran si
sub_vu_metre
	sub.l #16,a1				différent de 0
	tst.w (a1)
	beq.s sub_do_nothing
	sub.w #$100,(a1)
sub_do_nothing
	dbf d0,sub_vu_metre		
	rts

*------------> routine qui fait le fading à l'écran
fade
	move.w (a0)+,d0			a1 adresse des modifications
	subq.w #1,d0			d0 nb de changements-1
	move.w (a0)+,d5			offset
	moveq #0,d6
	move.w (a0)+,d6			prochaine couleur
	move.w (a0)+,d1			a0 adresse couleurs a atteindre
	move.w (a0),d2			met compteur dans d2
	cmp.w d1,d2			cmp
	beq.s DoFade			on a assez attendu => fading
	addq.w #1,(a0)			sinon on attend encore
	moveq #0,d0			signale qu'il n'y a pas eu de chgmt
	rts
	
* B=valeur Bleu  G=valeur vert  R=valeur R
	
DoFade
	move.w #0,(a0)+			remet a 0 le compteur
	
* differents tests sont effectués pour atteindre la bonne valeur de R,G ou B

LoopFadeB
	move.w (a0)+,d1
	move.w d1,d2
	and.w #$f,d2			valeur a atteindre B
	
	move.w 0(a1,d5.w),d3
	move.w d3,d4
	and.w #$f,d4			valeur actuelle B
	
	cmp.w d2,d4
	beq.s LoopFadeG
	bgt.s DoFadeOutB
	addq.w #1,d3			inferieur => on augmente
	bra.s LoopFadeG
DoFadeOutB
	subq.w #1,d3			superieur => on diminue

LoopFadeG
	move.w d1,d2
	and.w #$f0,d2			valeur a atteindre G
	
	move.w d3,d4
	and.w #$f0,d4			valeur actuelle G
	
	cmp.w d2,d4
	beq.s LoopFadeR
	bgt.s DoFadeOutG
	add.w #$10,d3			inferieur => on augmente
	bra.s LoopFadeR
DofadeOutG
	sub.w #$10,d3			superieur => on diminue
	
LoopFadeR
	move.w d1,d2
	and.w #$f00,d2			valeur a atteindre R
	
	move.w d3,d4
	and.w #$f00,d4			valeur actuelle R
	
	cmp.w d2,d4
	beq.s FadeAgain
	bgt.s DoFadeOutR
	add.w #$100,d3
	bra.s FadeAgain
DoFadeOutR
	sub.w #$100,d3
FadeAgain
	move.w d3,0(a1,d5.w)
	add.l d6,a1
	dbf d0,LoopFadeB
	moveq #-1,d0			signal les modifications
	rts

* structure des tables de couleurs a atteindre
* nb de couleur.W
* offset.W
* prochaine couleur offset.W
* wait.W
* temps.W
* couleurs.W

Table1
	dc.w 16
	dc.w 2
	dc.w 4
	dc.w 3
	dc.w 0
	dc.w 0
	dcb.w 15,$fff

Table2
	dc.w 16
	dc.w 2
	dc.w 4
	dc.w 3
	dc.w 0
	dc.w $000,$fff,$fff,$fff,$ddd,$ddd,$bbb,$bbb,$999,$999,$888,$888
	dc.w $666,$666,$444,$444

Table3
	dc.w 16
	dc.w 2
	dc.w 4
	dc.w 3
	dc.w 0
	dc.w $000,$fff,$000,$fff,$000,$fff,$000,$fff,$000,$fff,$000,$fff
	dc.w $000,$fff,$000,$fff

Table4
	dc.w 16
	dc.w 2
	dc.w 4
	dc.w 3
	dc.w 0
	dc.w $000,$fff,$c0a,$c0a,$d0c,$d0c,$f0f,$f0f,$580,$580,$6a0,$6a0
	dc.w $7c0,$7c0,$00f,$00f

Table5
	dc.w 9
	dc.w 6
	dc.w 8
	dc.w 3
	dc.w 0
	dc.w $001,$002,$003,$004,$005,$006,$007,$008,$009

*------------> routine qui incrémente les angles
do_angle
	move.w X+2(pc),d0
	add.w X_inc(pc),d0
	move.w d0,X+2-data_base(a5)

tst_X
	cmp.w #240,d0				deplacement de la sphere
	bmi.s tst_X2				sur X,Y,Z
	neg.w X_inc-data_base(a5)
	bra.s tst_Y
tst_X2
	cmp.w #80,d0
	bpl.s tst_Y
	neg.w X_inc-data_base(a5)

tst_Y
	move.w Y+2(pc),d0
	move.w Y_inc(pc),d1
	and.w #$fffe,d1
	add.w d1,d0
	move.w d0,Y+2-data_base(a5)

tst_Y2
	cmp.w #table_mulu40-Y+170<<1,d0
	bmi.s tst_Z
	neg.w Y_inc-data_base(a5)

tst_Z
	move.w Z+2(pc),d0
	add.w Z_inc(pc),d0
	move.w d0,Z+2-data_base(a5)
	cmp.w #200,d0
	bpl.s tst_Z2
	neg.w Z_inc-data_base(a5)
	bra.s not_bottom

tst_Z2
	cmp.w #370,d0
	bmi.s not_bottom
	neg.w Z_inc-data_base(a5)

not_bottom
	addq.w #1,Y_inc-data_base(a5)

	movem.w alpha(pc),d0-d2

inc_alpha
	addq.w #4,d0
	cmp.w #720,d0
	blt.s inc_teta
	sub.w #720,d0

inc_teta
	addq.w #6,d1
	cmp.w #720,d1
	blt.s inc_phi
	sub.w #720,d1

inc_phi
	addq.w #2,d2
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

cosalpha equr d0
sinalpha equr d1
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
	lea (0).l,a1

*-----------------> calcul de la matrice de rotation
	lea matrix(pc),a0

	move.w costeta,d6
	muls cosphi,d6				cos(teta) * cos(phi)
	asl.l #2,d6
	and.w #$fe00,d6				multiple de 512 uniquement
	lea 0(a1,d6.l),a2			adr du mulu
	move.l a2,12(a0)

	move.w costeta,d6
	muls sinphi,d6				cos(teta) * sin(phi)
	asl.l #2,d6
	and.w #$fe00,d6				multiple de 512 uniquement
	lea 0(a1,d6.l),a2			adr du mulu
	move.l a2,24(a0)

	move.w sinteta,d6
	ext.l d6
	neg.w d6
	asl.l #8,d6
	add.l d6,d6				asl.l #1,d6
	and.w #$fe00,d6
	lea 0(a1,d6.l),a2
	move.l a2,(a0)				-sin(teta)

	move.w costeta,d6
	muls sinalpha,d6			cos(teta) * sin(alpha)
	asl.l #2,d6
	and.w #$fe00,d6				multiple de 512 uniquement
	lea 0(a1,d6.l),a2			adr du mulu
	move.l a2,4(a0)

	move.w costeta,d6
	muls cosalpha,d6			cos(teta) * cos(alpha)
	asl.l #2,d6
	and.w #$fe00,d6				multiple de 512 uniquement
	lea 0(a1,d6.l),a2			adr du mulu
	move.l a2,8(a0)
	
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
	move.l a2,16(a0)

	move.w a3,d6
	muls sinphi,d6				sin(alpha)*sin(teta)*sin(phi)
	asr.l #5,d6
	move.w cosalpha,d7
	muls cosphi,d7				cos(alpha) * cos(phi)
	asl.l #2,d7
	add.l d7,d6
	and.w #$fe00,d6
	lea 0(a1,d6.l),a2
	move.l a2,28(a0)

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
	move.l a2,20(a0)

	move.w a3,d6
	muls sinphi,d6				cos(alpha)*sin(teta)*sin(phi)
	asr.l #5,d6
	move.w sinalpha,d7
	muls cosphi,d7				sin(alpha) * cos(phi)
	asl.l #2,d7
	sub.l d7,d6
	and.w #$fe00,d6
	lea 0(a1,d6.l),a2
	move.l a2,32(a0)		

	rts
matrix
	dcb.l 3*3,0

*-------------> les angles de rotations de la spheres
alpha	dc.w 0
teta	dc.w 0
phi	dc.w 0
X_inc	dc.w 3
Y_inc	dc.w 0
Z_inc	dc.w 2

*-------------> tables des cosinus & sinus 
table_cosinus
	incbin table_sinus.dat
table_sinus=table_cosinus+90*2

*-------------> on dessine la sphère à l'écran
draw_sphere
	lea sphere_dots_coord(pc),a1

	move.l log_screen(pc),a2
	move.l 4(a2),d7				*log screen
	move.l (a2),a2
	addq.l #4,a2				*clear_buffer

Y
	lea table_mulu40+80*2(pc),a3

nb_dots
	move.w #30-1,d0			nb_points à afficher
compute_dot
	movem.w (a1)+,d1-d3			coordonnées du point
	lea matrix(pc),a0			début matrice de rotation

	movem.l (a0)+,a4-a6			3ème colonne
	move.w 0(a4,d1.w),d6
	add.w 0(a5,d2.w),d6			calcul de Z
	add.w 0(a6,d3.w),d6
	asr.w #8,d6
	bge.s no_dot
Z
	add.w #200,d6
	
	movem.l (a0)+,a4-a6			1ère colonne
	move.w 0(a4,d1.w),d4
	add.w 0(a5,d2.w),d4			calcul de X
	add.w 0(a6,d3.w),d4
	ext.l d4

	movem.l (a0),a4-a6			2ème colonne
	move.w 0(a4,d1.w),d5
	add.w 0(a5,d2.w),d5			calcul de Y
	add.w 0(a6,d3.w),d5
	ext.l d5

	divs d6,d4				calcul de Xe
	divs d6,d5				calcul de Ye
no_div
X
	add.w #160,d4				recentre le point

	add.w d5,d5				asl.w #1,d5
	move.w 0(a3,d5.w),d5			add.w #Y,d5 & mulu #40,d5 
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
	incbin sphere.dat

table_mulu40
val set 0
	rept 256
	dc.w val*40
val set val+1
	endr

	section go_to_chip,bss_c

ecran1	dcb.b 10240,0
ecran2	dcb.b 10240,0

	section prout,data_c
logo_screen
	incbin ball_logo.RAW

color_palette macro
	dc.w color00,$000
	dc.w color01,$000
	dc.w color02,$000
	dc.w color03,$000
	dc.w color04,$000
	dc.w color05,$000
	dc.w color06,$000
	dc.w color07,$000
	dc.w color08,$000
	dc.w color09,$000
	dc.w color10,$000
	dc.w color11,$000
	dc.w color12,$000
	dc.w color13,$000
	dc.w color14,$000
	dc.w color15,$000
	endm

coplist
	dc.w bplcon0,$4200
label_1
	color_palette

vu_metre_cop
	dc.w $2c0f,$fffe
	dc.w color00,$000
	dc.w $2d0f,$fffe
	dc.w color00,$000

	dc.w $320f,$fffe
	dc.w color00,$000
	dc.w $330f,$fffe
	dc.w color00,$000

	dc.w $380f,$fffe
	dc.w color00,$000
	dc.w $390f,$fffe
	dc.w color00,$000

	dc.w $3e0f,$fffe
	dc.w color00,$000
	dc.w $3f0f,$fffe
	dc.w color00,$000

	dc.w $4f0f,$fffe				PROUDLY
label_2
	color_palette
	
	dc.w $750f,$fffe				PRESENTS
label_3
	color_palette
	
	dc.w $9b0f,$fffe				A NEW DEMO
label_4
	color_palette
	
	dc.w $c10f,$fffe				CALLED
label_5
	color_palette
	
	dc.w $e30f,$fffe				BALL
label_6
	color_palette

	dc.w $ffdf,$fffe
label_7
	dc.w $010f,$fffe
	dc.w color00,$000
	dc.w $020f,$fffe
	dc.w color00,$000
	dc.w $030f,$fffe
	dc.w color00,$000
	dc.w $050f,$fffe
	dc.w color00,$000
	dc.w $070f,$fffe
	dc.w color00,$000
	dc.w $0b0f,$fffe
	dc.w color00,$000
	dc.w $110f,$fffe
	dc.w color00,$000
	dc.w $190f,$fffe
	dc.w color00,$000
	dc.w $260f,$fffe
	dc.w color00,$000

	dc.l $fffffffe

mt_data
	incbin "dh0:music/modules/mod.lovecraft"
