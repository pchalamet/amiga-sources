
*			  Scrolling horizontal 8 couleurs
*			avec des sprites 64 pixels de larges
*			~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*			     (c) 1993 Sync/DreamDealers


* Les includes
* ~~~~~~~~~~~~
	incdir "asm:.s/sources/"
	incdir "asm:.s/Multi_Dir_Scroll/"
	include "registers.i"

* EQU pour les blocks du scrolling
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
BG_BLOCK_X=16
BG_BLOCK_Y=16
BG_BLOCK_DEPTH=4
BG_BLOCK_WIDTH=BLOCK_X/8
BG_BLOCK_SIZE=BG_BLOCK_WIDTH*BG_BLOCK_Y*BG_BLOCK_DEPTH
BG_HORIZ_BLOCK=20+4

* EQU pour la map
* ~~~~~~~~~~~~~~~
MAP_X=80
MAP_Y=80
MAP_WIDTH=MAP_X*2

* EQU pour les ecrans du scrolling
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
BPL_X=320
BPL_Y=192


* Le programme principal
* ~~~~~~~~~~~~~~~~~~~~~~
	section toto,code
	KILL_SYSTEM Do_Scroll
	moveq #0,d0
	rts

Do_Scroll
	lea db(pc),a5
	lea custom_base,a6

	move.l #Vbl,$6c.w
	move.l #coplist,cop1lc(a6)
	clr.w copjmp1(a6)

	move.w #$87c0,dmacon(a6)
	move.w #$c020,intena(a6)

	WAIT_LMB_DOWN
	RESTORE_SYSTEM

Vbl
	SAVE_REGS
	lea db(pc),a5
	lea custom_base,a6

	bsr background_scrolling
	
	move.w #$0020,intreq(a6)
	RESTORE_REGS
	rte

********************************************************************************
*                    GESTION COMPLETE DU SCROLLING DE FOND                     *
* EN ENTREE : A5=db  A6=custom_base                                            *
* EN SORTIE : rien du tout                                                     *
********************************************************************************
BackGround_Scrolling
	move.w BackGround_ScrollX(pc),d0
	