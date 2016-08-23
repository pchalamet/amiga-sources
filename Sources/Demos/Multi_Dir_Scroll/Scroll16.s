
*
*	Scrolling multidirectionnel
*	~~~~~~~~~~~~~~~~~~~~~~~~~~~
*

*
* l'IT pour la synchro ecran est assurée par le copper juste au début
* du panel( en $eb01 ) => evite une 2ème coplist lourde a gérer.
*


* Selection du type de mergeage de coplists
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
FULL_MERGE=0				SMALL_MERGE si FULL_MERGE=0

	
;;	OPT C+


	incdir "asm:"
	incdir "asm:.s/Multi_Dir_Scroll/"
	incdir "ram:"

	include "sources/registers.i"

* EQU pour le heros
* ~~~~~~~~~~~~~~~~~
HERO_X=16
HERO_Y=16

* EQU pour les blocks du scrolling
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
BLOCK_X=16
BLOCK_Y=16
BLOCK_DEPTH=5
BLOCK_WIDTH=BLOCK_X/8
BLOCK_SIZE=BLOCK_WIDTH*BLOCK_Y*BLOCK_DEPTH+17*2
HORIZ_BLOCK=20+1
VERT_BLOCK=12+1

* EQU pour la map
* ~~~~~~~~~~~~~~~
MAP_X=80
MAP_Y=80
MAP_WIDTH=MAP_X*2

* EQU pour le heros
* ~~~~~~~~~~~~~~~~~
MIN_X=$f
MIN_Y=0
MAX_X=MAP_X*BLOCK_X-HERO_X-1
MAX_Y=MAP_Y*BLOCK_Y-HERO_Y

* EQU pour les ecrans du scrolling
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
BPL_X=320
BPL_Y=192
BPL_DEPTH=5
BPL_MODULO=2
BPL_WIDTH=BPL_X/8+BPL_MODULO
MIN_SCROLL_X=$f
MIN_SCROLL_Y=0
MAX_SCROLL_X=(MAP_X-HORIZ_BLOCK+1)*16-1
MAX_SCROLL_Y=(MAP_Y-VERT_BLOCK+1)*16
MAX_SCROLL_SPEED=3<<16
MIN_BOX_X=100-15
MAX_BOX_X=BPL_X-100-HERO_X
MIN_BOX_Y=60-16
MAX_BOX_Y=BPL_Y-60-HERO_Y

* STRUCTURE pour les logiques/physiques
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	rsreset
screen	rs.l 1


* Le programme principal
* ~~~~~~~~~~~~~~~~~~~~~~
MAIN
	bsr save_all

	lea data_base(pc),a5
	lea $dff000,a6


	move.w #$7fff,intena(a6)
	move.w #$7fff,intreq(a6)
	move.w #$7fff,dmacon(a6)

	move.l #HeroPic0,d0			installe le sprite 0
	move.w d0,install_sprites+4+8*0
	swap d0
	move.w d0,install_sprites+8*0

	lea install_sprites+8*4,a0		installe les sprites 1-7
	move.l #blk_spr,d0
	moveq #7-1,d1
.install_spr
	move.w d0,4(a0)
	swap d0
	move.w d0,(a0)
	swap d0
	addq.l #8,a0
	dbf d1,.install_spr

	bsr init_vars				va initialiser les variables
	bsr build_first_screen			contruit les 1er ecrans

	bsr mt_init
	move.l #my_vbl,$6c.w
	move.l #coplist,cop1lc(a6)
	clr.w copjmp1(a6)

	move.w #$83e0,dmacon(a6)
	move.w #$c010,intena(a6)

mickey
	btst #6,ciaapra				bouton 1 du joystick
	bne.s mickey
	bsr mt_end
	bsr restore_all
	moveq #0,d0
	rts

	include "sources/save_all.s"

my_vbl
	movem.l d0-d7/a0-a6,-(sp)

	bsr mt_music

	lea data_base(pc),a5			\ NE JAMAIS CHANGER
	lea $dff000,a6				/ CES REGISTRES !!!

	move.w #$888,color00(a6)
	bsr rebuild_coplist
	bsr display_hero

	bsr swap_struct
	bsr gestion_joy
	bsr scrolling

	move.w #$000,color00(a6)
	move.w #$0010,intreq(a6)		sort de l'IT copper
	movem.l (sp)+,d0-d7/a0-a6
	rte



********************************************************************************
*                     INITIALISE TOUTES LES VARIABLES DU JEU                   *
* EN ENTREE : A5=data_base                                                     *
* EN SORTIE : rien du tout                                                     *
********************************************************************************
init_vars
	move.w HeroX(pc),d0			centre le personnage au
	sub.w #BPL_X/2-HERO_X/2,d0		beau milieu de l'écran
	cmp.w #MIN_SCROLL_X,d0			sur les X
	bge.s set_scroll_X
	move.w #MIN_SCROLL_X,d0
set_scroll_X
	move.w d0,ScrollX-data_base(a5)
	move.w d0,Old_ScrollX-data_base(a5)
	move.w d0,Very_Old_ScrollX-data_base(a5)

	move.w HeroY(pc),d0			idem mais sur les Y
	sub.w #BPL_Y/2-HERO_Y/2,d0
	bge.s set_scroll_Y
	move.w #MIN_SCROLL_Y,d0
set_scroll_Y
	move.w d0,ScrollY-data_base(a5)
	move.w d0,Old_ScrollY-data_base(a5)
	move.w d0,Very_Old_ScrollY-data_base(a5)

	move.l #$8000,VIT_X-data_base(a5)	init les vitesses
	move.l #$8000,VIT_Y-data_base(a5)

	rts



********************************************************************************
*                  ECHANGE DES STRUCTURES LOGIQUES ET PHYSIQUES                *
* EN ENTREE : A5=data_base                                                     *
* EN SORTIE : rien du tout                                                     *
********************************************************************************
swap_struct
	move.l log_struct(pc),a0
	move.l phy_struct(pc),log_struct-data_base(a5)
	move.l a0,phy_struct-data_base(a5)
	rts



********************************************************************************
*                             GESTION DU JOYSTICK                              *
* EN ENTREE : A5=data_base  A6=$dff000                                         *
* EN SORTIE : rien du tout                                                     *
********************************************************************************
gestion_joy
	move.l HeroX(pc),Old_HeroX-data_base(a5)	pour avoir le Delta X/Y

	move.l VIT_X(pc),d0
	move.l VIT_Y(pc),d1

	move.w joy1dat(a6),d2
	ror.b #2,d2
	lsr.w #4,d2
	and.w #%111100,d2
	jmp JoyRout(pc,d2.w)
JoyRout
	bra.w move_none
	bra.w move_down
	bra.w move_down_right
	bra.w move_right
	bra.w move_up
	bra.w move_none
	bra.w move_none
	bra.w move_up_right
	bra.w move_up_left
	bra.w move_none
	bra.w move_none
	bra.w move_none
	bra.w move_left
	bra.w move_down_left
	bra.w move_none
	bra.w move_none

check_none_X
	cmp.l #$8000,d0				regarde le signe de VIT_X
	beq.s .check_exit			ben on bouge pas
	tst.l d0
	slt d2					sauve le signe de VIT_X
	bpl.s .X_positif
	neg.l d0				prend sa valeur absolue
.X_positif
	sub.l ACC_X(pc),d0			fait tendre vers $8000+
	cmp.l #$8000,d0
	bpl.s .X_ok				on passe pas de l'autre coté !!
	move.l #$8000,d0			on bouge plus !!!
	rts
.X_ok
	tst.b d2				remet le signe de VIT_X
	bpl.s .check_exit
	neg.l d0
.check_exit
	rts

check_none_Y
	cmp.l #$8000,d1				regarde le signe de VIT_Y
	beq.s .check_exit			ben on bouge pas
	tst.l d1
	slt d2					sauve le signe de VIT_Y
	bpl.s .Y_positif
	neg.l d1				prend sa valeur absolue
.Y_positif
	sub.l ACC_Y(pc),d1			fait tendre vers $8000+
	bpl.s .Y_ok
	move.l #$8000,d1			on bouge plus !!!
	rts
.Y_ok
	tst.b d2				remet le signe de VIT_Y
	bpl.s .check_exit
	neg.l d1
.check_exit
	rts


move_none
	bsr.s check_none_X
	bsr.s check_none_Y
	bra.s move_speed

move_left
	sub.l ACC_X(pc),d0
	bsr.s check_none_Y
	bra.s move_speed

move_right
	add.l ACC_X(pc),d0
	bsr.s check_none_Y
	bra.s move_speed

move_up
	bsr.s check_none_X
	sub.l ACC_Y(pc),d1
	bra.s move_speed
move_down
	bsr.s check_none_X
	add.l ACC_Y(pc),d1
	bra.s move_speed

move_up_right
	add.l ACC_X(pc),d0
	sub.l ACC_Y(pc),d1
	bra.s move_speed

move_up_left
	sub.l ACC_X(pc),d0
	sub.l ACC_Y(pc),d1
	bra.s move_speed

move_down_right
	add.l ACC_X(pc),d0
	add.l ACC_Y(pc),d1
	bra.s move_speed

move_down_left
	sub.l ACC_X(pc),d0
	add.l ACC_Y(pc),d1

* Modification de la vitesse du heros
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
move_speed
	cmp.l #MAX_SCROLL_SPEED,d0		sauve VIT_X
	ble.s .X_ok
	move.l #MAX_SCROLL_SPEED,d0
	bra.s move_set_X
.X_ok
	cmp.l #-MAX_SCROLL_SPEED,d0
	bge.s move_set_X
	move.l #-MAX_SCROLL_SPEED,d0
move_set_X
	move.l d0,VIT_X-data_base(a5)
	swap d0
	add.w d0,HeroX-data_base(a5)

	cmp.l #MAX_SCROLL_SPEED,d1		sauve VIT_Y
	ble.s .Y_ok
	move.l #MAX_SCROLL_SPEED,d1
	bra.s move_set_Y
.Y_ok
	cmp.l #-MAX_SCROLL_SPEED,d1
	bge.s move_set_Y
	move.l #-MAX_SCROLL_SPEED,d1
move_set_Y
	move.l d1,VIT_Y-data_base(a5)
	swap d1
	add.w d1,HeroY-data_base(a5)

* Fait gaffe que le heros ne sorte pas de l'ecran
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
move_tstX_min
	cmp.w #MIN_X,HeroX-data_base(a5)
	bge.s move_tstX_max
	move.w #MIN_X,HeroX-data_base(a5)
	clr.l VIT_X-data_base(a5)
	bra.s move_tstY_min
move_tstX_max
	cmp.w #MAX_X,HeroX-data_base(a5)
	ble.s move_tstY_min
	move.w #MAX_X,HeroX-data_base(a5)
	clr.l VIT_X-data_base(a5)

move_tstY_min
	tst.w HeroY-data_base(a5)
	bge.s move_tstY_max
	clr.w HeroY-data_base(a5)
	clr.l VIT_Y-data_base(a5)
	bra.s move_exit
move_tstY_max
	cmp.w #MAX_Y,HeroY-data_base(a5)
	ble.s move_exit
	move.w #MAX_Y,HeroY-data_base(a5)
	clr.l VIT_Y-data_base(a5)

* Modification du scrolling en fonction du heros
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
move_exit
	move.w HeroX(pc),d0
	sub.w Old_HeroX(pc),d0
	beq.s no_moveX
	bpl.s chk_rightX
chk_leftX
	move.w HeroX(pc),d1
	sub.w ScrollX(pc),d1
	cmp.w #MIN_BOX_X,d1
	bge.s no_moveX
	add.w d0,ScrollX-data_base(a5)
	cmp.w #MIN_SCROLL_X,ScrollX-data_base(a5)
	bge.s no_moveX
	move.w #MIN_SCROLL_X,ScrollX-data_base(a5)
	bra.s no_moveX
chk_rightX
	move.w HeroX(pc),d1
	sub.w ScrollX(pc),d1
	cmp.w #MAX_BOX_X,d1
	ble.s no_moveX
	add.w d0,ScrollX-data_base(a5)
	cmp.w #MAX_SCROLL_X,ScrollX-data_base(a5)
	ble.s no_moveX
	move.w #MAX_SCROLL_X,ScrollX-data_base(a5)

no_moveX
	move.w HeroY(pc),d0
	sub.w Old_HeroY(pc),d0
	beq.s no_moveY
	bpl.s chk_downY
chk_upX
	move.w HeroY(pc),d1
	sub.w ScrollY(pc),d1
	cmp.w #MIN_BOX_Y,d1
	bge.s no_moveY
	add.w d0,ScrollY-data_base(a5)
	bge.s no_moveY
	clr.w ScrollY-data_base(a5)
	bra.s no_moveY
chk_downY
	move.w HeroY(pc),d1
	sub.w ScrollY(pc),d1
	cmp.w #MAX_BOX_Y,d1
	ble.s no_moveY
	add.w d0,ScrollY-data_base(a5)
	cmp.w #MAX_SCROLL_Y,ScrollY-data_base(a5)
	ble.s no_moveY
	move.w #MAX_SCROLL_Y,ScrollY-data_base(a5)

no_moveY
	rts



********************************************************************************
*                              AFFICHAGE DU HEROS                              *
* EN ENTREE : A5=data_base  A6=$dff000                                         *
* EN SORTIE : rien du tout                                                     *
********************************************************************************
display_hero
	move.w HeroX(pc),d0
	sub.w ScrollX(pc),d0
	move.w HeroY(pc),d1
	sub.w ScrollY(pc),d1
	move.w #16<<8,d2
	bsr put_sprite
	or.w #$80,d3
	move.l d3,HeroPic0
	rts


********************************************************************************
***************** CALCUL DES 2 MOTS DE CONTROLE D'UN SPRITE ********************
***************** EN ENTREE :  D0=COORD X		    ********************
*****************              D1=COORD Y		    ********************
*****************              D2=HAUTEUR DU SPRITE<<8	    ********************
***************** EN SORTIE :  D3=CONTROL LONG WORD         ********************
********************************************************************************
put_sprite
	moveq #0,d3
	add.w #$2b,d1				recentre sur les Y
	lsl.w #8,d1
	add.w #$80,d0				recentre sur les X
	lsr.w #1,d0				bit 0 dans X
	or.w d1,d0
	move.w d0,d3
	swap d3
	addx.w d3,d3				insère X !!
	add.w d2,d1				calcule de vstop
	or.w d1,d3
	rts



********************************************************************************
*                        GESTION COMPLETE DU SCROLLING                         *
* EN ENTREE : A5=data_base  A6=$dff000                                         *
* EN SORTIE : rien du tout                                                     *
********************************************************************************
scrolling
	move.l log_struct(pc),a0		recherche l'ecran de travail
	move.l screen(a0),a0
	move.w ScrollX(pc),d0
	move.w d0,d1
	lsr.w #4,d1				/----\  lsr.w #4,d1
	add.w d1,d1				\----/  and.w #$fffe,d1
	lea (a0,d1.w),a0
	move.l a0,Screen_Ptr-data_base(a5)

	not.w d0				calcul le delay de l'ecran
	and.w #$f,d0
	move.w d0,Screen_Delay-data_base(a5)

	moveq #0,d0
	move.w ScrollY(pc),d0			recherche le debut et la
	divu #BPL_Y+BLOCK_Y,d0			taille de la premiere
	swap d0					partie du scrolling
	move.w d0,First_Part_Start-data_base(a5)
	neg.w d0
	add.w #BPL_Y+BLOCK_Y,d0
	cmp.w #BPL_Y,d0
	ble.s .not_full_screen_part
	move.w #BPL_Y,d0
.not_full_screen_part
	move.w d0,First_Part_Size-data_base(a5)

	moveq #0,d0				recherche la fin de la
	move.w ScrollY(pc),d0			2ème partie du scrolling
	add.w #BPL_Y,d0
	divu #BPL_Y+BLOCK_Y,d0
	swap d0
	move.w d0,Second_Part_End-data_base(a5)

	lea Map,a0				recherche le pointeur
	move.w ScrollX(pc),d0			sur la map du decor
	lsr.w #4,d0				/----\  lsr.w #3,d0
	add.w d0,d0				\----/  and.w #$fffe,d0
	lea (a0,d0.w),a0
	move.w ScrollY(pc),d0
	lsr.w #4,d0				divise par 16
	mulu #MAP_WIDTH,d0
	lea (a0,d0.l),a0
	move.l a0,Map_Ptr-data_base(a5)

.wait_block_init
	btst #14,dmaconr(a6)
	bne.s .wait_block_init

	move.l #$09f00000,bltcon0(a6)
	move.l #BPL_WIDTH-BLOCK_WIDTH,bltamod(a6)
	moveq #-1,d0
	move.l d0,bltafwm(a6)


	move.l Map_Ptr(pc),a0			-------------------------
	move.l Screen_Ptr(pc),a1
	move.w First_Part_Start(pc),d0		init quelques pointeurs
	and.w #$fff0,d0				pour l'affichage vertical
	mulu #BPL_WIDTH*BPL_DEPTH,d0
	lea (a1,d0.l),a1			-------------------------

	move.w ScrollX(pc),d0			affichage vertical des blocks
	cmp.w Very_Old_ScrollX(pc),d0		du scrolling
	beq.s .no_scroll_horiz			on a bougé sur les X ?
	blt.s .scroll_left
.scroll_right
	lea (HORIZ_BLOCK-1)*2(a0),a0		*2 car c des mots ds la map !!
	lea BPL_WIDTH-BPL_MODULO(a1),a1
.scroll_left
	bsr Display_Colonne


.no_scroll_horiz
	move.l Map_Ptr(pc),a0			init quelques pointeurs
	move.w First_Part_Start(pc),d0		pour le scrolling vertical

	move.w ScrollY(pc),d1
	cmp.w Very_Old_ScrollY(pc),d1
	beq.s .no_scroll_vert			on a bougé sur les Y ?
	blt.s .scroll_up
.scroll_down
	lea (VERT_BLOCK-1)*MAP_WIDTH(a0),a0
	move.w Second_Part_End(pc),d0
.scroll_up
	and.w #$fff0,d0
	mulu #BPL_WIDTH*BPL_DEPTH,d0
	move.l Screen_Ptr(pc),a1
	lea (a1,d0.l),a1
	bsr Display_Line


.no_scroll_vert
	move.l Old_ScrollX(pc),Very_Old_ScrollX-data_base(a5)
	move.l ScrollX(pc),Old_ScrollX-data_base(a5)
	rts



********************************************************************************
*               REFAIT LA COPLIST POUR BIEN AFFICHER LE SCROLLING              *
* EN ENTREE : A6=$dff000                                                       *
* EN SORTIE : rien du tout                                                     *
********************************************************************************
rebuild_coplist
	move.w Screen_Delay(pc),d0		installe le delay
	move.w d0,d1
	lsl.w #4,d1
	or.w d1,d0
	move.w d0,install_delay

	move.l Screen_Ptr(pc),d0		installe les ptrs videos
	lea install_part2(pc),a0		pour la 2ème partie
	moveq #BPL_DEPTH-1,d1
.install_part2
	move.w d0,4(a0)				met PtrLow
	swap d0
	move.w d0,(a0)				met PtrHigh
	swap d0
	add.l #BPL_WIDTH,d0
	addq.l #8,a0
	dbf d1,.install_part2

	move.w First_Part_Start(pc),d0		installe les ptrs videos
	mulu #BPL_WIDTH*BPL_DEPTH,d0		pour la 1ère partie du
	add.l Screen_Ptr(pc),d0			scrolling
	lea install_part1,a0
	moveq #BPL_DEPTH-1,d1
.install_part1
	move.w d0,4(a0)				met PtrLow
	swap d0
	move.w d0,(a0)				met PtrHigh
	swap d0
	add.l #BPL_WIDTH,d0
	addq.l #8,a0
	dbf d1,.install_part1

	move.w First_Part_Size(pc),d0		installe le wait
	add.b #$2b-1,d0				-1 : il faut avoir le temps de
	move.b d0,install_wait_cut-data_base(a5)	recharger les ptrs bpl


* Maintenant on merge les 2 coplists dans la vraie
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

	IFNE FULL_MERGE
* VERITABLE MERGEAGE DE COPLISTS MAIS TROP LENT...
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	lea Degrad_coplist(pc),a0
	lea Scroll_coplist(pc),a1
	lea install_merged_coplist,a2
	move.w (a0)+,d0				nb d'instructions dans
	move.w (a1)+,d1				chaque coplist
loop_merge_coplist
	tst.w d0				\
	bmi.s merge_only_coplist1		 | regarde si yen a encore
	tst.w d1				 | en reserve
	bmi.s merge_only_coplist0		/

	btst.b #0,1(a0)				c'est un move ?
	beq.s merge_move0

	btst.b #0,1(a1)				c'est un move ?
	beq.s merge_move1

	move.w (a0),d2				on a 2 wait => on les compare
	cmp.w (a1),d2
	bhi.s merge_wait1

merge_wait0
	move.l (a0)+,(a2)+
	dbf d0,loop_merge_coplist
	bra.s merge_only_coplist1
merge_wait1
	move.l (a1)+,(a2)+
	dbf d1,loop_merge_coplist
	bra.s merge_only_coplist0

merge_move0
	move.l (a0)+,(a2)+
	dbf d0,loop_merge_coplist
	bra.s merge_only_coplist1
merge_move1
	move.l (a1)+,(a2)+
	dbf d1,loop_merge_coplist

merge_only_coplist0
	tst.w d0
	bmi.s merge_exit
put_coplist0
	move.l (a0)+,(a2)+
	dbf d0,put_coplist0
merge_exit
	rts

merge_only_coplist1
	tst.w d1
	bmi.s merge_exit
put_coplist1
	move.l (a1)+,(a2)+
	dbf d1,put_coplist1
	rts

	ELSEIF

* MERGEAGE DE COPLISTS BIEN PLUS RAPIDE MAIS MOINS FLEXIBLE	
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	lea Degrad_coplist(pc),a0
	lea Scroll_coplist(pc),a1
	lea install_merged_coplist,a2
	move.w (a0)+,d0				nb de (wait+move)/2-1
	moveq #Scroll_coplist_size-1,d1		nb d'instruction-1
	move.w (a1),d2				wait pour la coplist2
loop_merge_coplist
	cmp.w (a0),d2				compare les 2 waits
	bls.s put_coplist2_content
	move.l (a0)+,(a2)+			copie le wait
	move.l (a0)+,(a2)+			copie le move
	dbf d0,loop_merge_coplist
put_coplist2
	move.l (a1)+,(a2)+			copie toute la coplist2
	dbf d1,put_coplist2			et sort
	rts
put_coplist2_content
	move.l (a1)+,(a2)+			copie toute la coplist2
	dbf d1,put_coplist2_content		puis copie la coplist1
put_coplist1_content
	move.l (a0)+,(a2)+			copie le wait
	move.l (a0)+,(a2)+			copie le move
	dbf d0,put_coplist1_content
	rts
	ENDC



********************************************************************************
*                      AFFICHAGE D'UNE COLONNE DE BLOCKS                       *
* EN ENTREE : A0=ptr sur la map  A1=ptr sur l'ecran  A6=$dff000                *
* EN SORTIE : rien du tout                                                     *
********************************************************************************
Display_Colonne
	moveq #VERT_BLOCK-1,d0
	moveq #0,d1				flag pour l'affichage
	lea Block_Gfx,a2
	move.l Screen_Ptr(pc),a3
	add.l #BPL_WIDTH*(BPL_Y+BLOCK_Y)*BPL_DEPTH,a3
.loop_each_vert_block
	move.w (a0),d2				pointe le bon block
	and.w #$1ff,d2				9 bits = # du block
	mulu #BLOCK_SIZE,d2
	lea (a2,d2.l),a4
.wait_vert_block_paste
	btst #14,dmaconr(a6)
	bne.s .wait_vert_block_paste
	move.l a4,bltapt(a6)					block à copier
	move.l a1,bltdpt(a6)					destination
	move.w #(BLOCK_Y*BPL_DEPTH<<6)|(BLOCK_X/16),bltsize(a6)	paste le block

	lea MAP_WIDTH(a0),a0			blocks suivant
	lea BPL_WIDTH*BLOCK_Y*BPL_DEPTH(a1),a1	ligne suivante

	tst.w d1				on affiche koi ?
	bne.s .not_end_first_part
	cmp.l a3,a1				on arrive à la fin ?
	blt.s .not_end_first_part
	moveq #-1,d1				on affiche la 2ème partie
	sub.l #BPL_WIDTH*(BPL_Y+BLOCK_Y)*BPL_DEPTH,a1	revient en haut de l'ecran
.not_end_first_part
	dbf d0,.loop_each_vert_block
	rts



********************************************************************************
*                       AFFICHAGE D'UNE LIGNE DE BLOCKS                        *
* EN ENTREE : A0=ptr sur la map  A1=ptr sur l'ecran  A6=$dff000                *
* EN SORTIE : rien du tout                                                     *
********************************************************************************
Display_Line
	moveq #HORIZ_BLOCK-1,d0
	lea Block_Gfx,a2
.loop_each_horiz_block
	move.w (a0)+,d1				pointe le bon block
	and.w #$1ff,d1				9 bits = # du block 
	mulu #BLOCK_SIZE,d1
	lea 0(a2,d1.l),a3
.wait_horiz_block_paste
	btst #14,dmaconr(a6)
	bne.s .wait_horiz_block_paste
	move.l a3,bltapt(a6)
	move.l a1,bltdpt(a6)
	move.w #(BLOCK_Y*BPL_DEPTH<<6)|(BLOCK_X/16),bltsize(a6)

	addq.l #BLOCK_WIDTH,a1
	dbf d0,.loop_each_horiz_block
	rts	



********************************************************************************
*                       FABRICATION DES ECRANS DE DEPART                       *
* EN ENTREE : A5=data_base  A6=$dff000                                         *
* EN SORTIE : rien du tout                                                     *
********************************************************************************
build_first_screen
	move.w #$8240,dmacon(a6)		autorise le DMA-blitter

	move.l log_struct(pc),a0		recherche l'ecran de travail
	move.l screen(a0),a0
	move.w ScrollX(pc),d0
	lsr.w #4,d0				/----\  lsr.w #3,d0
	add.w d0,d0				\----/  and.w #$fffe,d0
	lea (a0,d0.w),a0
	move.l a0,Screen_Ptr-data_base(a5)

	moveq #0,d0
	move.w ScrollY(pc),d0			recherche le debut et la
	divu #BPL_Y+BLOCK_Y,d0			taille de la premiere
	swap d0					partie du scrolling
	move.w d0,First_Part_Start-data_base(a5)
	neg.w d0
	add.w #BPL_Y+BLOCK_Y,d0
	cmp.w #BPL_Y,d0
	ble.s .not_full_screen_part
	move.w #BPL_Y,d0
.not_full_screen_part
	move.w d0,First_Part_Size-data_base(a5)

	lea Map,a0				recherche le pointeur
	move.w ScrollX(pc),d0			sur la map du decor
	lsr.w #4,d0
	add.w d0,d0
	lea (a0,d0.w),a0
	move.w ScrollY(pc),d0
	lsr.w #4,d0				divise par 16
	mulu #MAP_WIDTH,d0
	lea (a0,d0.l),a0
	move.l a0,Map_Ptr-data_base(a5)

.wait_block_init
	btst #14,dmaconr(a6)
	bne.s .wait_block_init

	move.l #$09f00000,bltcon0(a6)
	move.l #BPL_WIDTH-BLOCK_WIDTH,bltamod(a6)
	moveq #-1,d0
	move.l d0,bltafwm(a6)



	move.l Map_Ptr(pc),a0			---------------------------
	move.l Screen_Ptr(pc),a1
	move.w First_Part_Start(pc),d0		init quelques pointeurs
	and.w #$fff0,d0				pour l'affichage horizontal
	mulu #BPL_WIDTH*BPL_DEPTH,d0
	lea (a1,d0.l),a1			---------------------------

	moveq #HORIZ_BLOCK-1,d7			construit l'ecran logique
.build_log_screen
	movem.l a0-a1,-(sp)
	bsr Display_Colonne
	movem.l (sp)+,a0-a1
	addq.l #2,a0				la map est basée sur des mots
	addq.l #BLOCK_WIDTH,a1
	dbf d7,.build_log_screen


	move.l phy_struct(pc),a0		recherche l'ecran de travail
	move.l screen(a0),a0
	move.w ScrollX(pc),d0
	lsr.w #4,d0				/----\  lsr.w #3,d0
	add.w d0,d0				\----/  and.w #$fffe,d0
	lea (a0,d0.w),a0
	move.l a0,Screen_Ptr-data_base(a5)

	move.l Map_Ptr(pc),a0			---------------------------
	move.l Screen_Ptr(pc),a1
	move.w First_Part_Start(pc),d0		init quelques pointeurs
	and.w #$fff0,d0				pour l'affichage horizontal
	mulu #BPL_WIDTH*BPL_DEPTH,d0
	lea (a1,d0.l),a1			---------------------------

	moveq #HORIZ_BLOCK-1,d7			construit l'ecran logique
.build_phy_screen
	movem.l a0-a1,-(sp)
	bsr Display_Colonne
	movem.l (sp)+,a0-a1
	addq.l #2,a0				la map est basée sur des mots
	addq.l #BLOCK_WIDTH,a1
	dbf d7,.build_phy_screen

.wait_build_up
	btst #14,dmaconr(a6)
	bne.s .wait_build_up

	move.w #$0240,dmacon(a6)		vire le DMA-blitter
	rts



* Les datas du programme
* ~~~~~~~~~~~~~~~~~~~~~~
data_base

* Datas pour le heros
* ~~~~~~~~~~~~~~~~~~~
VIT_X			dc.l $8000
VIT_Y			dc.l $8000
ACC_X			dc.l $3000
ACC_Y			dc.l $3000
HeroX			dc.w MAX_X/2
HeroY			dc.w 3*MAX_Y/4
Old_HeroX		dc.w 0
Old_HeroY		dc.w 0

* Datas du scrolling
* ~~~~~~~~~~~~~~~~~~
ScrollX			dc.w 0
ScrollY			dc.w 0
Old_ScrollX		dc.w 0
Old_ScrollY		dc.w 0
Very_Old_ScrollX	dc.w 0
Very_Old_ScrollY	dc.w 0
First_Part_Start	dc.w 0
First_Part_Size		dc.w 0
Second_Part_End		dc.w 0
Map_Ptr			dc.l 0
Screen_Ptr		dc.l 0
Screen_Delay		dc.w 0

* Datas pour les structures logiques et physiques
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
log_struct		dc.l struct_log
phy_struct		dc.l struct_phy

struct_log		dc.l screen_log
struct_phy		dc.l screen_phy

* La replay
* ~~~~~~~~~
	include "sources/TMC_Replay.s"
* La musique
* ~~~~~~~~~~
	include "Song.s"

* Les coplist à fusionner dans la vraie coplist
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Degrad_coplist
	IFNE FULL_MERGE
	dc.w Degrad_coplist_size-1		et hop... un degradé vite
	ELSEIF					fait bien fait !!!
	dc.w (Degrad_coplist_size/2)-1
	ENDC
color set $f0f
dummy set $2b
	REPT 16
	dc.b dummy,$01
	dc.w $fffe
	dc.w color01,color
	IFEQ (color=$f0f)
	dc.b dummy+1,$01
	dc.w $fffe
	dc.w color01,color+$100-$010
	dc.b dummy+2,$01
	dc.w $fffe
	dc.w color01,color
	ENDC
color set color-$100+$010
dummy set dummy+12
	ENDR
Degrad_coplist_size=(*-(Degrad_coplist+2))/4

Scroll_coplist
	IFNE FULL_MERGE
	dc.w Scroll_coplist_size-1
	ENDC
install_wait_cut
	dc.w $00e1,$fffe			le wait pour changer de partie
install_part2=*+2
dummy set bpl1ptH
	REPT BPL_DEPTH				pointeurs pour la 2ème partie
	dc.w dummy,$0000
	dc.w dummy+2,$0000
dummy set dummy+4
	ENDR
Scroll_coplist_size=(*-Scroll_coplist)/4



	section map,data
* La map du jeu
* ~~~~~~~~~~~~~
Map
	incbin "dh1:Map.DAT"
;	REPT MAP_Y/2-2
;	dcb.l MAP_X/2,$00010000
;	dcb.l MAP_X/2,$00000001
;	ENDR
;	REPT MAP_X/4
;	dc.l $00030004
;	dc.l $00050004
;	ENDR
;	dcb.w MAP_X*3,$0002
	


* La coplist
* ~~~~~~~~~~
	section pirouette,data_c
coplist
	dc.w bplcon0,(BPL_DEPTH<<12)|$0200
install_delay=*+2
	dc.w bplcon1,$0000
	dc.w bplcon2,%100100
	dc.w ddfstrt,$0030
	dc.w ddfstop,$00d0
	dc.w diwstrt,$2b81
	dc.w diwstop,$ebc1
	dc.w bpl1mod,BPL_WIDTH*(BPL_DEPTH-1)
	dc.w bpl2mod,BPL_WIDTH*(BPL_DEPTH-1)

	dc.w color00,$000
	dc.w color01,$58f
	dc.w color02,$B00
	dc.w color03,$950
	dc.w color04,$0A0
	dc.w color05,$05F
	dc.w color06,$04B
	dc.w color07,$080
	dc.w color08,$FE0
	dc.w color09,$630
	dc.w color10,$FB0
	dc.w color11,$FFF
	dc.w color12,$BBB
	dc.w color13,$F70
	dc.w color14,$800
	dc.w color15,$F00
	dc.w color16,$000
	dc.w color17,$ECA
	dc.w color18,$C00
	dc.w color19,$F60
	dc.w color20,$F80
	dc.w color21,$3F1
	dc.w color22,$00F
	dc.w color23,$2CD
	dc.w color24,$F0C
	dc.w color25,$630
	dc.w color26,$950
	dc.w color27,$FCA
	dc.w color28,$FE0
	dc.w color29,$CCC
	dc.w color30,$888
	dc.w color31,$444

install_sprites=*+2
dummy set spr0ptH
	REPT 8					pointeurs pour les sprites
	dc.w dummy,$0000
	dc.w dummy+2,$0000
dummy set dummy+4
	ENDR

install_part1=*+2
dummy set bpl1ptH
	REPT BPL_DEPTH				pointeurs pour la 1ère partie
	dc.w dummy,$0000
	dc.w dummy+2,$0000
dummy set dummy+4
	ENDR

install_merged_coplist
	dcb.l Degrad_coplist_size+Scroll_coplist_size,color00<<16

	dc.w $eb01,$fffe			\ lance une IT copper
	dc.w intreq,$8010			/
	dc.w color00,$fff

	dc.l $fffffffe

* Les blocks du jeu
* ~~~~~~~~~~~~~~~~~
Block_Gfx
	REPT BLOCK_Y				block 0
	dc.w $FFFF,$0000,$0000,$0000,$0000
	ENDR
	dcb.w 17,0

	REPT BLOCK_Y/2
	dc.w $FFFF,$AAAA,$0000,$0000,$0000
	dc.w $FFFF,$5555,$0000,$0000,$0000
	ENDR
	dcb.w 17,0

	REPT BLOCK_Y/2
	dc.w $FFFF,$5555,$0000,$0000,$0000
	dc.w $FFFF,$AAAA,$0000,$0000,$0000
	ENDR
	dcb.w 17,0

	incbin "Block1.RAW"			block 1
	dcb.w 17,0

	incbin "Block5.RAW"			block 2
	dcb.w 17,0

	incbin "Block3.RAW"			block 3
	dcb.w 17,0

	incbin "Block4.RAW"			block 4
	dcb.w 17,0

	incbin "BlocK2.RAW"			block 5
	dcb.w 17,0

* Image du heros
* ~~~~~~~~~~~~~~
HeroPic0
	dc.l 0
	dcb.l 16,$ffffffff
blk_spr
	dc.l 0



* Les samples de la musique
* ~~~~~~~~~~~~~~~~~~~~~~~~~
	include "Samples.s"


* Les ecrans
* ~~~~~~~~~~
	section Screens,bss_c
screen_log		dcb.b BPL_WIDTH*(BPL_Y+80)*BPL_DEPTH,$00
screen_phy		dcb.b BPL_WIDTH*(BPL_Y+80)*BPL_DEPTH,$00

