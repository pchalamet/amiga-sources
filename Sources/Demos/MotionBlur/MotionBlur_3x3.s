 


*				  BLUR
*				  ~~~~
*			(c)1995 Sync/DreamDealers




*********************************************************************************
*                                Les includes                                   *
*********************************************************************************
	incdir "asm:sources/"
	incdir "asm:songs/medium"
	incdir "ram:"
	include "Registers.i"




*********************************************************************************
*                         Les options de compilation                            *
*********************************************************************************
	SET_OPTS

;;	OPT DEBUG,HCLN

*********************************************************************************
*                                   Les EQUs                                    *
*********************************************************************************
DATA_OFFSET=$7ffe

NB_COLONNES=106
NB_LIGNES=12*7
COP_SKIP=29*4
COP_SIZE_X=(NB_COLONNES+4+1+1)*4
COP_SIZE=COP_SKIP+COP_SIZE_X*NB_LIGNES+4
NB_COPLISTS=2

PIXEL_SIZE_X=3
PIXEL_SIZE_Y=3
SCREEN_X=NB_COLONNES*PIXEL_SIZE_X
SCREEN_Y=NB_LIGNES*PIXEL_SIZE_Y
SCREEN_DEPTH=7
SCREEN_WIDTH=(SCREEN_X+7)/8

PICTURE_X=56
PICTURE_Y=56
PICTURE_DEPTH=5
PICTURE_COLORS=1<<PICTURE_DEPTH

NEW_PERCENT=10
OLD_PERCENT=90
HOW_PERCENT=100

*********************************************************************************
*                          Point d'entrée de la demo !                          *
*********************************************************************************
	section zoom,code

	bsr Init_DataBase
	bsr Build_Screen
	bsr Build_Coplists
	bsr Build_Blur_Table
	bsr Modify_Chunky_Picture
	bsr Build_Table_Screen_Offset

	KILL_SYSTEM do_Blur
	moveq #0,d0
	rts

do_Blur
	jsr mt_init

	lea _DataBase,a5
	lea _CustomBase,a6

	movec cacr,d0
	move.l d0,Old_Cache(a5)
	move.l #$3111,d0			Write Allocate + Burst + Caches On
	movec d0,cacr

	move.l #Blur_VBL,$6c.w

	move.w #$8380,dmacon(a6)		set | pri | master | bpl | copper | blitter
	move.w #$c020,intena(a6)

Main_Loop
	bsr Flip_Coplists
	bsr.s Motion_Blur

	btst #6,ciaapra
	bne.s Main_Loop

	move.w #$7fff,d0
	move.w d0,intena(a6)
	move.w d0,dmacon(a6)

	jsr mt_end

	move.l Old_Cache(a5),d0
	movec d0,cacr
	RESTORE_SYSTEM




*********************************************************************************
*			   Routine de Motion Blur				*
*   --> a5=_DataBase								*
*********************************************************************************
Motion_Blur
	move.l a5,-(sp)

	movem.l Log_Table_Screen_Offset(a5),a0/a1
	move.l Blur_Table(a5),a2
	move.l Chunky_Picture(a5),a3
	movem.w MouseX(a5),d0-d1
	divs.w #PICTURE_X,d0			essait de rester dans
	swap d0					l'image...
	tst.w d0
	bpl.s .ok
	add.w #PICTURE_X,d0
.ok	move.w d0,MouseX(a5)
	mulu.w #PICTURE_Y,d0
	divs.w #PICTURE_Y,d1
	swap d1
	tst.w d1
	bpl.s .ok2
	add.w #PICTURE_Y,d1
.ok2	ext.l d1
	move.w d1,MouseY(a5)
	add.l d1,d0
	lea (a3,d0.l*2),a3

	moveq #NB_COLONNES-1,d0
.loop_X
	move.l (a0)+,a4				destination
	moveq #(NB_LIGNES/12)-1,d1
	move.l (a1)+,a5				source
.loop_Y

** première série
	movem.w (a3)+,d2/d3/d4/d5/d6/d7		lit 6 couleurs

	lsl.l #2,d2
	or.w (a5),d2
	move.w (a2,d2.l*2),(a4)

	lsl.l #2,d3
	or.w COP_SIZE_X(a5),d3
	move.w (a2,d3.l*2),COP_SIZE_X(a4)

	lsl.l #2,d4
	or.w COP_SIZE_X*2(a5),d4
	move.w (a2,d4.l*2),COP_SIZE_X*2(a4)

	lsl.l #2,d5
	or.w COP_SIZE_X*3(a5),d5
	move.w (a2,d5.l*2),COP_SIZE_X*3(a4)

	lsl.l #2,d6
	or.w COP_SIZE_X*4(a5),d6
	move.w (a2,d6.l*2),COP_SIZE_X*4(a4)

	lsl.l #2,d7
	or.w COP_SIZE_X*5(a5),d7
	move.w (a2,d7.l*2),COP_SIZE_X*5(a4)


** deuxième série
	movem.w (a3)+,d2/d3/d4/d5/d6/d7		lit 6 couleurs

	lsl.l #2,d2
	or.w COP_SIZE_X*6(a5),d2
	move.w (a2,d2.l*2),COP_SIZE_X*6(a4)

	lsl.l #2,d3
	or.w COP_SIZE_X*7(a5),d3
	move.w (a2,d3.l*2),COP_SIZE_X*7(a4)

	lsl.l #2,d4
	or.w COP_SIZE_X*8(a5),d4
	move.w (a2,d4.l*2),COP_SIZE_X*8(a4)

	lsl.l #2,d5
	or.w COP_SIZE_X*9(a5),d5
	move.w (a2,d5.l*2),COP_SIZE_X*9(a4)

	lsl.l #2,d6
	or.w COP_SIZE_X*10(a5),d6
	move.w (a2,d6.l*2),COP_SIZE_X*10(a4)

	lsl.l #2,d7
	or.w COP_SIZE_X*11(a5),d7
	lea COP_SIZE_X*12(a5),a5
	move.w (a2,d7.l*2),COP_SIZE_X*11(a4)
	lea COP_SIZE_X*12(a4),a4

	dbf d1,.loop_Y

	lea (PICTURE_Y-NB_LIGNES)*2(a3),a3
	dbf d0,.loop_X

	move.l (sp)+,a5
	rts



*********************************************************************************
*			Juste une petite VBL pour la muzik			*
*********************************************************************************
Blur_VBL
	SAVE_REGS
	jsr mt_music

	lea _DataBase,a5
	lea _CustomBase,a6

	bsr.s Update_Mouse

	sf Flip_Flag(a5)
	move.w #$0020,intreq(a6)
	RESTORE_REGS
	rte




*********************************************************************************
*                           Permutation des coplists                            *
*   -->	a5=_DataBase                                                            *
*	a6=_Custom                                                              *
*********************************************************************************
Flip_Coplists
	st Flip_Flag(a5)

	movem.l Log_Coplist(a5),d0-d1/d2-d3
	exg d0,d1
	exg d2,d3
	movem.l d0-d1/d2-d3,Log_Coplist(a5)

	move.l d1,cop1lc(a6)			init la nouvelle coplist

.wait	tst.b Flip_Flag(a5)			attend la syncho
	bne.s .wait
	clr.w copjmp1(a6)
	rts


*********************************************************************************
*				Gestion de la souris				*
*   -->	a5=_DataBase								*
*	a6=_CustomBase								*
*********************************************************************************
Update_Mouse
	move.w joy0dat(a6),d1
	moveq #-1,d3				d3=255
	
	move.b LastX(a5),d0			etat précédent
	move.b d1,LastX(a5)			etat actuel
	sub.b d1,d0				différence=précédent-actuel
	bvc.s test_Y				Overflow clear ?
	bge.s pas_depassementX_right
	addq.b #1,d0				-255+différence
	bra.s test_Y
pas_depassementX_right
	add.b d3,d0				255+différence
test_Y
	lsr.w #8,d1				récupère les Y
	move.b LastY(a5),d2
	move.b d1,LastY(a5)
	sub.b d1,d2				idem
	bvc.s fin_testY
	bge.s pas_depassementY_down
	addq.b #1,d2
	bra.s fin_testY
pas_depassementY_down
	add.b d3,d2
fin_testY
	ext.w d0
	ext.w d2
	sub.w d0,MouseX(a5)
	sub.w d2,MouseY(a5)
	rts










*********************************************************************************
*                         Initialisation des datas				*
* <--	a5=_DataBase                                                            *
*********************************************************************************
Init_DataBase
	lea _DataBase,a5
	rts




*********************************************************************************
*                      Fabrication de l'écran pour le zoom                      *
*   -->	a5=_DataBase                                                            *
*********************************************************************************
Build_Screen
	move.l #Screen_space,a0
	move.l a0,Screen(a5)

* efface déja le buffer
* ~~~~~~~~~~~~~~~~~~~~~
	move.l a0,a1
	moveq #(SCREEN_WIDTH/4)-1,d0
.clear
	clr.l (a1)+
	dbf d0,.clear

* construction de 2 lignes du motif
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Build_Motif
	moveq #1,d0

* Fabrication d'une ligne du motif
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*   -->	d0=Couleur de départ
*	a0=Ecran
* <--	a0=Ecran
Build_Motif_Lines
	moveq #1,d1				PosX
Build_Motif_One_Line
	move.w d1,d2
	lsr.w #3,d2				pointe des octets
	move.w d1,d3
	not.w d3				# du bit à modifier

	moveq #SCREEN_DEPTH-1,d4		on se fait tous les bitplans
	move.w d0,d5
put_pixel
	lsr.w #1,d5				sort un bit de la couleur
	bcc.s .clear				c'est quoi ?
.set	bset d3,(a0,d2.w)			met le bit
.branch
	add.w #SCREEN_WIDTH,d2			ligne suivante
	dbf d4,put_pixel

	moveq #0,d2				incrémente la position
	move.w d1,d2				du point
	addq.w #1,d1
	divu #PIXEL_SIZE_X,d2
	swap d2
	tst.w d2
	bne.s .skip

	addq.w #1,d0				couleur suivante

.skip	cmp.w #NB_COLONNES*PIXEL_SIZE_X+1,d1
	bne.s Build_Motif_One_Line
	rts
.clear	bclr d3,(a0,d2.w)			efface le bit
	bra.s .branch


*********************************************************************************
*                       Contruction des coplists de la demo                     *
*   -->	a5=_DataBase                                                            *
*********************************************************************************
Build_Coplists
	lea Coplist_space,a0
	move.l a0,Log_Coplist(a5)
	bsr.s Build_One_Coplist
	move.l a0,Phy_Coplist(a5)
Build_One_Coplist
	move.l #(fmode<<16)|(%11),(a0)+
	move.l #(bplcon0<<16)|($7200),(a0)+	pas de ECSENA
	move.l #(bplcon1<<16),(a0)+
	move.l #(bplcon2<<16),(a0)+
	move.l #(bplcon4<<16),(a0)+
	move.l #(ddfstrt<<16)|($38),(a0)+
	move.l #(ddfstop<<16)|($a0),(a0)+
	move.l #(diwstrt<<16)|($2e81),(a0)+
	move.l #(diwstop<<16)|($2ac1),(a0)+
	move.l #(bpl1mod<<16)|((-SCREEN_WIDTH)&$ffff),(a0)+
	move.l #(bpl2mod<<16)|((-SCREEN_WIDTH)&$ffff),(a0)+
	move.l #(bplcon3<<16)|($0020),(a0)+
	move.l #(color00<<16)|$000,(a0)+
	move.l #(bplcon3<<16)|($8020),(a0)+
	move.l #(color00<<16)|$000,(a0)+

	moveq #SCREEN_DEPTH-1,d0		met en place les ptrs videos
	move.w #bpl1ptH,d1
	move.l Screen(a5),d2
Build_BplPtr
	move.w d1,(a0)+				bplxptH
	swap d2
	move.w d2,(a0)+
	addq.w #2,d1
	move.w d1,(a0)+				bplxptL
	swap d2
	move.w d2,(a0)+
	addq.w #2,d1
	add.l #SCREEN_WIDTH,d2
	dbf d0,Build_BplPtr

** on arrive à la partie suivante par un COP_SKIP sur un pointeur coplist
	moveq #NB_LIGNES/2-1,d6
	move.l #$2ddffffe,d5
Build_All
	move.l #(bplcon3<<16)|($0020),d7	commence à la palette 0
	bsr.s Build_Line
	move.l d5,(a0)+				met le wait
	add.l #PIXEL_SIZE_Y<<24,d5
	move.l #(bplcon4<<16)|($0000),(a0)+	utilise les palettes 0-3
	move.l #(bplcon3<<16)|($8020),d7	commence à la palette 8
	bsr.s Build_Line
	move.l d5,(a0)+				met le wait
	add.l #PIXEL_SIZE_Y<<24,d5
	move.l #(bplcon4<<16)|($8000),(a0)+	utilise les palettes 4-7
	dbf d6,Build_All

	move.l #$fffffffe,(a0)+
	rts

Build_Line
	move.l d7,(a0)+				construit la palette 0 / 4
	moveq #31-1,d0				couleurs de 1 à 31
	move.l #color01<<16,d1
Build_Colors0	
	move.l d1,(a0)+
	add.l #2<<16,d1
	dbf d0,Build_Colors0

	add.w #$2000,d7				construit la palette 1 / 5
	move.l d7,(a0)+				couleurs de 0 à 32
	moveq #32-1,d0
	move.l #color00<<16,d1
Build_Colors1
	move.l d1,(a0)+
	add.l #2<<16,d1
	dbf d0,Build_Colors1

	add.w #$2000,d7				construit la palette 2 / 6
	move.l d7,(a0)+				couleurs de 0 à 32
	moveq #32-1,d0
	move.l #color00<<16,d1
Build_Colors2
	move.l d1,(a0)+
	add.l #2<<16,d1
	dbf d0,Build_Colors2

	add.w #$2000,d7				construit la palette 3 / 7
	move.l d7,(a0)+				couleurs de 0 à 10
	moveq #11-1,d0
	move.l #color00<<16,d1
Build_Colors3
	move.l d1,(a0)+
	add.l #2<<16,d1
	dbf d0,Build_Colors3
	rts




*********************************************************************************
* 	                   Précalcul sur l'image chunky				*
*   -->	a5=_DataBase                                                            *
*********************************************************************************
Modify_Chunky_Picture
	lea Picture_CHK,a0
	lea Chunky_Picture_space,a1
	move.l a1,Chunky_Picture(a5)

	move.w #PICTURE_Y-1,d0
.loop_y
	move.l a1,a2
	move.w #PICTURE_X-1,d1
.loop_x
	moveq #0,d2
	move.b (a0)+,d2
	ror.w #PICTURE_DEPTH+1,d2
	move.w d2,(a2)
	lea PICTURE_Y*2(a2),a2

	dbf d1,.loop_x
	addq.l #2,a1
	dbf d0,.loop_y
	rts



*********************************************************************************
*                    Contruction de la table de blur				*
*   -->	a5=_DataBase                                                            *
*********************************************************************************
Build_Blur_Table
	lea Blur_Table_space,a0
	move.l a0,Blur_Table(a5)

* pour chaque nouvelle couleurs, on fait
* correspondre une nouvelle palette

	lea Picture_PAL,a1
	moveq #PICTURE_COLORS-1,d0
.loop_color
	move.w (a1)+,d4			lit la couleur suivante
	moveq #0,d1
.loop_build_red
	moveq #0,d2
.loop_build_green
	moveq #0,d3
.loop_build_blue

	move.w #NEW_PERCENT,Percent_New(a5)
	move.w #OLD_PERCENT,Percent_Old(a5)
	move.w #HOW_PERCENT,Percent_How(a5)

* on fait un mélange des couleurs 3/4 pour l'original et 1/4 pour l'ancienne

.redo_it
* traitement du rouge
	move.w d4,d5			$rgb
	and.w #$f00,d5			$0r00
	lsr.w #8,d5			$000r
	mulu.w Percent_New(a5),d5	pour l'original
	move.w d1,d7
	mulu.w Percent_Old(a5),d7	pour l'ancienne
	add.w d7,d5
	divu Percent_How(a5),d5
	lsl.w #8,d5

* traitement du vert
	move.w d4,d6			$rgb
	and.w #$f0,d6			$00g0
	lsr.w #4,d6			$000g
	mulu.w Percent_New(a5),d6
	move.w d2,d7
	mulu.w Percent_Old(a5),d7
	add.w d7,d6
	divu Percent_How(a5),d6
	lsl.w #4,d6
	or.w d6,d5

* traitement du bleu
	move.w d4,d6			$rgb
	and.w #$f,d6			$000b
	mulu.w Percent_New(a5),d6
	move.w d3,d7
	mulu.w Percent_Old(a5),d7
	add.w d7,d6
	divu Percent_How(a5),d6
	or.w d6,d5

* regarde si on a obtenu la meme couleur ancienne
* si oui, augmente le pourcentage
	moveq #0,d6
	move.w d1,d6			$00r
	lsl.w #4,d6			$0r0
	or.w d2,d6			$0rg
	lsl.w #4,d6			$rg0
	or.w d3,d6			$rgb

	cmp.w d5,d6
	bne.s .ok

	addq.w #1,Percent_New(a5)
	subq.w #1,Percent_Old(a5)

	move.w Percent_New(a5),d7
	cmp.w Percent_How(a5),d7
	ble.s .redo_it
	move.w d4,d5

* stockage de la couleur blurée
.ok
	move.w d5,(a0)+	

.next_blue
	addq.w #1,d3
	cmp.w #$10,d3
	bne .loop_build_blue
.next_green
	addq.w #1,d2
	cmp.w #$10,d2
	bne .loop_build_green
.next_red
	addq.w #1,d1
	cmp.w #$10,d1
	bne .loop_build_red
.next_color
	dbf d0,.loop_color
	rts




*********************************************************************************
*                     Construction de la Table_Screen_Offset                    *
*   -->	a5=_DataBase                                                            *
*********************************************************************************
Build_Table_Screen_Offset
	lea Table_Screen_Offset_space,a0	pour la Log_Table_Screen_Offset
	lea NB_COLONNES*4(a0),a1		pour la Phy_Table_Screen_Offset
	move.l a0,Log_Table_Screen_Offset(a5)
	move.l a1,Phy_Table_Screen_Offset(a5)

	move.l Log_Coplist(a5),a4
	lea COP_SKIP(a4),a4

	moveq #4+2,d0				bplcon3/move
	moveq #31-1,d1
	bsr.s Loop_Create_Table_Offset
	moveq #32-1,d1
	bsr.s Loop_Create_Table_Offset
	moveq #32-1,d1
	bsr.s Loop_Create_Table_Offset
	moveq #11-1,d1
Loop_Create_Table_Offset
	moveq #0,d2
	move.w d0,d2
	add.l a4,d2
	move.l d2,(a0)+
	add.l #COP_SIZE,d2
	move.l d2,(a1)+

	addq.w #4,d0				move suivant
	dbf d1,Loop_Create_Table_Offset
	addq.w #4,d0				saute bplcon3
	rts





*********************************************************************************
*				Datas constantes				*
*********************************************************************************
Picture_CHK
	incbin "Picture10.CHK"

Picture_PAL
	incbin "Picture10.PAL"



*********************************************************************************
*				La replay et sa zik				*
*********************************************************************************
	even
	include "TMC_Replay.s"
	include "song.s"


	section hippopo,data_c
	include "samples.s"



*********************************************************************************
*                         Toutes les datas du programme                         *
*********************************************************************************
	section mes_daaaatas,bss
	rsset -DATA_OFFSET
DataBase		rs.b 0
Old_Cache		rs.l 1
Log_Coplist		rs.l 1
Phy_Coplist		rs.l 1
Log_Table_Screen_Offset	rs.l 1
Phy_Table_Screen_Offset	rs.l 1
Screen			rs.l 1
Chunky_Picture		rs.l 1
Blur_Table		rs.l 1
MouseX			rs.w 1
MouseY			rs.w 1
Percent_New		rs.w 1
Percent_Old		rs.w 1
Percent_How		rs.w 1
LastX			rs.b 1
LastY			rs.b 1
Flip_Flag		rs.b 1
DataBase_SIZEOF=__RS-DataBase

_DataBase=*+DATA_OFFSET
	ds.b DataBase_SIZEOF

	even
Blur_Table_space
	ds.w PICTURE_COLORS*4096

Chunky_Picture_space
	ds.w PICTURE_X*PICTURE_Y



	section ponpon,bss_c

Screen_space
	ds.b SCREEN_WIDTH*SCREEN_DEPTH

Coplist_space
	ds.b COP_SIZE*NB_COPLISTS

Table_Screen_Offset_space
	ds.l NB_COLONNES*NB_COPLISTS




***************
* end of file *
***************
