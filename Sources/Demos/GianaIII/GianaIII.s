	incdir "asm:" "ram:"

	opt O+,OW-		Optimisation On, Messages Off

		************************************************
		* description : jeu de plateforme 	       *
		* nom du machin : THE GREAT GIANA SISTER 3 ??? *
		************************************************

		****************************************
		* structure de la table des animations *
		****************************************
	rsreset
screen_adr	rs.l 1		- adresse de l'ecran

giana_adr	rs.w 1		- adresse oû remettre le background de Giana
giana_back	rs.l 1		- adresse du background de Giana

obj_on		rs.b 1		- objet utilisé à l'écran ?
obj_anim_num	rs.b 1		- numéro de l'animation
obj_posX	rs.w 1		- position X de l'objet
obj_posY	rs.w 1		- position Y de l'objet
obj_back_adr	rs.l 1		- adresse oû remetre le background
obj_back	rs.l 1		- adresse du background de l'objet

		*************************
		* structure d'un niveau *
		*************************
	rsreset
giana_init_X	rs.b 1
giana_init_Y	rs.b 1
colonne_number	rs.b 1
level_time	rs.b 1
level_describ	rs.b 1

wait_blitter macro
.wait_blitter
	btst #14,dmaconr(a6)
	bne.s .wait_blitter
	endm

		**********************
		* debut du programme *
		**********************

	include sources/registers.i
	
	bsr save_all

	lea $dff000,a6
		**********************************************
		* construction de la premiere image du level *
		**********************************************
	bsr build_level

		***************************
		* initialisations du hard *
		***************************
	move.w #$7fff,d0
	move.w d0,dmacon(a6)
	move.w d0,intena(a6)
	
	move.l #$3000d0,ddfstrt(a6)		datafetch start & stop
	move.l #$298129c1,diwstrt(a6)		position de l'ecran
	move.w #$4200,bplcon0(a6)		4 bitplans
	clr.l bplcon1(a6)			pas de decalage et sprite
	move.l #$7e007e,bpl1mod(a6)		126 de modulo
	
	move.l #coplist,cop1lc(a6)		met en place la coplist
	clr.w copjmp1(a6)			et lance la coplist
	
	move.l #vbl,$6c.w			installe nouvelle vbl
	jsr mt_init

	move.w #$87c0,dmacon(a6)		nasty blitter bpl cop blit
	move.w #$c020,intena(a6)		vbl uniquement

		***********************************************
		* attent que le bouton fire se fasse tripoter *
		***********************************************
mickey
	btst #7,ciaapra
	bne.s mickey
	jsr mt_end
	bsr.s restore_all
	moveq.w #0,d0
	rts
	
	include sources/save_all.s

		************************
		* nouvelle routine vbl *
		************************
vbl
		*************************
		* joue la jolie musique *
		*************************
	jsr mt_music
	lea level(pc),a3

		**************************
		* permutation des ecrans *
		**************************
	movem.l ecran_struct1(pc),a4-a5
	exg a4,a5
	movem.l a4-a5,ecran_struct1-level(a3)

	move.l (a4),d0
	move.l d0,bpl1ptH(a6)		on affiche (a4) on travaille sur (a5)
	add.l #42,d0
	move.l d0,bpl2ptH(a6)
	add.l #42,d0
	move.l d0,bpl3ptH(a6)
	add.l #42,d0
	move.l d0,bpl4ptH(a6)
	
	move.b decalage(pc),d0
	move.b d0,d1
	lsl.b #4,d1
	or.b d1,d0

	move.b d0,bplcon1(a6)

		***********************
		* lecture du joystick *
		***********************
joy
	move.w $dff00c,d0
	ror.b #2,d0
	lsr.w #5,d0
	andi.w #%11110,d0
	lea joytab(pc),a1
	move.w 0(a1,d0.w),d0
	beq.s no_joy_mvt
	move.b #$ff,0(a3,d0.w)		signal le mouvement
no_joy_mvt
		*****************************
		* test ici les deplacements *
		*****************************
	tst.b left
	bne go_left
	tst.b right
	bne go_right
	tst.b up
	bne go_up
	tst.b down
	bne go_down
	tst.b left_up
	bne go_left_up
	tst.b left_down
	bne go_left_down
	tst.b right_up
	bne go_right_up
	tst.b right_down
	bne go_right_down
	tst.b fire
	bne go_fire
fin_joy
	clr.l left-level(a3)		efface les mouvements
	clr.l left_up-level(a3)
	clr.b fire-level(a3)

		***************************
		* affiche Giana à l'écran *
		***************************
*	bsr display_Giana

		**************************
		* fin de la routine vbl  *
		**************************
	btst #6,ciaapra
	bne.s no_left
	move.w #$f,color00(a6)
no_left
	btst #10,potgor(a6)
	bne.s no_right
	move.w #$f00,color00(a6)
no_right
	move.w #$20,intreq(a6)		vbl traitée
	rte

joytab	dc.w 0,val1,val2,val3,val4,0
	dc.w 0,val5,val6,0,0,0,val7,val8

go_right
	move.w giana_max(pc),d0
	cmp.w giana_positionX(pc),d0
	ble.s do_scroll_right
	moveq #0,d0
	addq.w #1,giana_positionX-level(a3)	ajoute la vitesse
	bra fin_joy
do_scroll_right
	tst.b colonne_number(a3)	est-ce que l'on peut scroller?
	beq fin_joy			non alors on se tire
	subq.b #1,decalage-level(a3)	le decor va de droite à gauche(speed)
	and.b #$f,decalage-level(a3)	fait un and sur decalage 1&2

	cmp.b #$f,decalage-level(a3)	non
	bne fin_joy
	subq.b #1,colonne_number(a3)
	bra display_colonne
return_from_display
	addq.l #2,screen_adr(a4)	on ajoute 2 aux pointeurs
	addq.l #2,screen_adr(a5)	videos
	bra fin_joy

go_left
	tst.w giana_positionX-level(a3)
	beq fin_joy
	subq.w #1,giana_positionX-level(a3)
	bra fin_joy
go_up
	subq.w #1,giana_positionY-level(a3)
	bra fin_joy
go_down
	addq.w #1,giana_positionY-level(a3)
	bra fin_joy
go_right_up
	subq.w #1,giana_positionY-level(a3)
	bra go_right
go_right_down
	addq.w #1,giana_positionY-level(a3)
	bra go_right
go_left_up
	tst.w giana_positionX-level(a3)
	beq.s no_X_move_left_up
	subq.w #1,giana_positionX-level(a3)
no_X_move_left_up
	subq.w #1,giana_positionY-level(a3)
	bra fin_joy
go_left_down
	tst.w giana_positionX-level(a3)
	beq.s no_X_move_left_down
	subq.w #1,giana_positionX-level(a3)
no_X_move_left_down
	addq.w #1,giana_positionY-level(a3)
	bra fin_joy
go_fire
	bra fin_joy
			
		********************************************
		* table qui indique les mouvement de Giana *
		********************************************
mvt_direction
left		dc.b 0
right		dc.b 0
up		dc.b 0
down		dc.b 0
left_up		dc.b 0
left_down	dc.b 0
right_up	dc.b 0
right_down	dc.b 0
fire		dc.b 0
		dc.b 0			adresse paire

display_colonne
	move.l #$ffffffff,bltafwm(a6)
	move.l level_pointeur(pc),a0		pointe la colonne
	lea block_data(pc),a1			pointe la table des offsets
	lea block_picture,a2			pointe l'image des blocs
	move.l (a5),d2				cherche l'ecran de travail
	add.l #42,d2
	move.w #15,d0				1§ blocs par colonnes
	
	wait_blitter
	move.w #$9f0,bltcon0(a6)		copie A=D
	clr.w bltcon1(a6)
	move.l #$260028,bltamod(a6)		modulo A et D

loop_display_colonne
	clr.w d1
	move.b (a0)+,d1				d1=numero du bloc
	lsl.b #1,d1				d1=d1*2 car table de mot
	move.w 0(a1,d1.w),d1			charge offset
	lea 0(a2,d1.w),a3			charge adresse du bloc

	wait_blitter				attend le blitter
	move.l a3,bltapt(a6)			adresse source
	move.l d2,bltdpt(a6)			destination
	move.w #16*4*64+1,bltsize(a6)		taille du bloc ( 4 bitplans)
	add.l #2688,d2
	dbf d0,loop_display_colonne

dup_colonne
	move.l (a5),d0				adr ecran de travail
	add.l #42,d0
	move.l (a4),d1				adr ecran affiché
	add.l #42,d1
	wait_blitter
	move.w #$28,bltamod(a6)
	move.l d0,bltapt(a6)
	move.l d1,bltdpt(a6)
	move.w #1,bltsize(a6)			colonne de 1024*2

	lea level(pc),a3
	move.l a0,level_pointeur-level(a3)	sauvegarde le pointeur

tst_end_level
	tst.b colonne_number(a3)
	bne return_from_display
end_level
	move.w #320,giana_max-level(a3)
	clr.b decalage-level(a3)
	subq.l #2,screen_adr(a4)
	subq.l #2,screen_adr(a5)
	bra return_from_display

display_Giana
	tst.l Giana_back(a5)
	beq.s no_background
	move.l Giana_Back(a5),bltapt(a6)	recopie du background
	move.l Giana_adr(a5),bltdpt(a6)		de Giana
	move.w #$09f0,bltcon0(a6)		
	move.w #32*4+2,bltsize(a6)
	
no_background
	clr.l d0
	move.w Giana_PositionX,d0
	move.w d0,d1
	lsr.w #3,d0				d0=d0/8
	and.w #$fffe,d0				adresse paire SVP
	and.w #$f,d1				le décalage
	clr.l d2
	move.w Giana_PositionY,d2
	mulu #160,d2				calcul ordonnée
	add.l screen_adr(a5),d0			ajoute l'adresse de l'écran
	add.l d2,d0				adresse du transfer
	move.w d0,Giana_adr(a5)			sauvegarde l'adr du transfer
	ror.w #4,d1				décalage de B dans bltcon1
	move.w d1,bltcon1(a6)
	or.w #$0fca,bltcon0(a6)			décalage + sources ds bltcon0
	move.w d0,bltbpt(a6)			init B
	move.w d0,bltdpt(a6)			init D
*	move.w 					init C
*	move.w 					init A
	














build_level
	move.l #$ffffffff,bltafwm(a6)
	move.l level_pointeur(pc),a0		pointe le niveau
	lea block_data(pc),a1			pointe la table des offsets
	lea block_picture,a2			pointe l'image des blocs
	lea ecran1+43006+2,a4			pointe l'image ecran
	move.w #19,d0				20 colonnes à mettre

	wait_blitter
	move.w #$9f0,bltcon0(a6)		copie A=D
	clr.w bltcon1(a6)
	move.l #$260028,bltamod(a6)		modulo A et D

loop_next_colonne
	move.w #15,d1				nombre de blocs par colonne
	sub.l #43006,a4				debut colonne suivante
	
loop_make_colonne
	clr.w d2
	move.b (a0)+,d2				d2=numero du bloc
	lsl.b #1,d2				d2=d2*2 car table de mot
	move.w 0(a1,d2.w),d2			charge offset
	lea 0(a2,d2.w),a3			charge adresse du bloc

	wait_blitter				attend le blitter
	move.l a3,bltapt(a6)			adresse source
	move.l a4,bltdpt(a6)			destination
	move.w #16*4*64+1,bltsize(a6)		taille du bloc ( 4 bitplans)

	add.l #2688,a4				passe au bloc suivant
	dbf d1,loop_make_colonne
	dbf d0,loop_next_colonne
	lea level(pc),a3
	move.l a0,level_pointeur-level(a3)	sauvegarde du pointeur

dup_screen
	wait_blitter
	move.l #ecran1,bltapt(a6)
	move.l #ecran2,bltdpt(a6)
	clr.l bltamod(a6)
	move.w #21,bltsize(a6)			ecran de 1024*42
	rts

ecran_struct1
	dc.l struct1
ecran_struct2
	dc.l struct2

		**************************
		* rappel de la structure *
		* .l screen_adr		 *
		* .l giana_pos		 *
		* .l objet1 etc...	 *
		**************************
struct1
	dc.l ecran1
	dc.l 0			adresse à partir d'oû la sauvegarde a eu lieu
	dc.l Giana_Buffer1	adresse de la sauvegarde du background
struct2
	dc.l ecran2
	dc.l 0
	dc.l Giana_Buffer2

decalage
	dc.b 0
	even
giana_positionX
	dc.w 0
giana_positionY
	dc.w 200
giana_max
	dc.w 160
giana_anim_number
	dc.w 0
giana_table_anim
;				mettre ici les adr des images en fonction
;				de la vitesse

level_pointeur
	dc.l level+4			indique la colonne à afficher
level
	incbin level2.dat

		***********************************************
		* valeurs de saut pour la routine du joystick *
		***********************************************
val1=down-level
val2=right_down-level
val3=right-level
val4=up-level
val5=right_up-level
val6=left_up-level
val7=left-level
val8=left_down-level

		*****************************************
		* fabrication des offset pour les blocs *
		*****************************************
make_block_data macro
block_dat set 2560*\1
	rept 20
	dc.w block_dat
block_dat set block_dat+2
	endr
	endm

block_data
	make_block_data 0
	make_block_data 1
	make_block_data 2
	make_block_data 3
	make_block_data 4
	make_block_data 5
	dc.w 2560*6,2560*6+2,2560*6+4,2560*6+6,2560*6+8,2560*6+10
	dc.w 2560*6+12,2560*6+14

	section gfx_snd,data_c

block_picture
	incbin giana_block		blocs en 16 couleurs

ecran1	dcb.b 10752*4,$0		ecrans de 42*256   4 bitplans
ecran2	dcb.b 10752*4,$0		fenetre de 40*256
	dcb.b 840*4,$00			on se reserve 20 lignes pour
;					le scrolling => 20 tableaux max

Giana_Buffer1
	dcb.b 512,0
Giana_Buffer2
	dcb.b 512,0

coplist
	dc.w color00,$0000,color01,$0D79,color02,$0B00,color03,$0950
	dc.w color04,$00A0,color05,$005F,color06,$004B,color07,$0080
	dc.w color08,$0FE0,color09,$0630,color10,$0FB0,color11,$0FFF
	dc.w color12,$0BBB,color13,$0F70,color14,$0800,color15,$0F00
	dc.l $fffffffe

	include "asm:.s/The Module Converter/TMC_Replay.s"
	include "ram:Song.s"

