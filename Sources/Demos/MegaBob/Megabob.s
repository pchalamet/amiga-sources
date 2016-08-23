************************************************
* Prg : Déplacement de bobs suivant une courbe *
************************************************

NB_BOB=26

	incdir "asm:"
	incdir "asm:sources/"
	incdir "ram:"

	include "registers.i"

	section taillo,code

	KILL_SYSTEM MegaBobeux
	moveq #0,d0
	rts

*******************
* initialisations *
*******************
MegaBobeux
	bsr make_masque
	bsr make_ball
	bsr fill_clear
	
	lea $dff000,a6
	move.w #$7fff,d0
	move.w d0,dmacon(a6)
	move.w d0,intena(a6)
	
	move.l #$003800d0,ddfstrt(a6)
	move.l #$2c812cc1,diwstrt(a6)
	move.l #$500050,bpl1mod(a6)
	move.w #$3200,bplcon0(a6)
	clr.l bplcon1(a6)
	move.l #$220000,bltcmod(a6)
	move.l #$000022,bltamod(a6)	
	move.w #$ffff,bltafwm(a6)
	move.w #0,fmode(a6)

	move.l #coplist,cop1lc(a6)
	clr.w copjmp1(a6)
	move.l #vbl,$6c.w
	
	jsr mt_init

	move.w #$87c0,dmacon(a6)
	move.w #$c020,intena(a6)
	
mickey
	btst #6,ciaapra
	bne.s mickey
	jsr mt_end
	RESTORE_SYSTEM
	
************************
* nouvelle routine vbl *
************************

vbl
	bsr.s flip_screen
	bsr.s clear_bob
	bsr next_bob
	bsr draw_bob
	jsr mt_music
	
	lea $dff000,a6
	btst #2,potinp(a6)
	bne.s pas_rouge
	move.w #$f00,color00(a6)
pas_rouge
	move.w #$20,intreq(a6)
	rte

**************************
* permutation des ecrans *
**************************
	
flip_screen
	movem.l next_screen(pc),a0-a1
	exg a0,a1
	movem.l a0-a1,next_screen
	
	move.l a1,bpl1ptH(a6)
	lea 40(a1),a1
	move.l a1,bpl2ptH(a6)
	lea 40(a1),a1
	move.l a1,bpl3ptH(a6)	

	movem.l clear_bob_pos(pc),a0-a1
	exg a0,a1
	movem.l a0-a1,clear_bob_pos

	rts

*********************
* effacage des bobs *
*********************

clear_bob
	WAIT_BLITTER
	move.w #$100,bltcon0(a6)
	moveq #NB_BOB-1,d3
	move.l clear_bob_pos(pc),a0
loop_clear
	WAIT_BLITTER
	move.l (a0)+,bltdpt(a6)
	move.w #96<<6+3,bltsize(a6)
	dbf d3,loop_clear
	rts

**********************
* affichage des bobs *
**********************
	
draw_bob
	move.w #NB_BOB-1,d3
	move.l pointeur_table(pc),a0		a0 pointeur sur table
	move.l clear_bob_pos,a1
loop_bob
	movem.w (a0),d0-d1
	tst.w d0
	bne.s not_end
	lea table_deplacement(pc),a0
	movem.w (a0),d0-d1
not_end
	move.w d0,d2
	lsr.l #3,d0				x/8
	and.l #$fffe,d0
	add.l d1,d0
	add.l next_screen(pc),d0		d0=destination
	move.l d0,(a1)+
	and.w #$f,d2
	ror.w #4,d2
	WAIT_BLITTER
	move.w d2,bltcon1(a6)
	or.w #$fca,d2
	move.w d2,bltcon0(a6)
	
	move.l d0,bltdpt(a6)			D destination
	move.l d0,bltcpt(a6)			C background
	move.l #ball,bltbpt(a6)			B image
	move.l #masque,bltapt(a6)		A masque image
	
	move.w #96*64+3,bltsize(a6)
	add.l #16,a0
	cmp.l #fin_table,a0
	blt.s nothing_done
	suba.l #fin_table-table_deplacement,a0
nothing_done
	dbf d3,loop_bob
	rts
	
next_bob
	move.l pointeur_table(pc),a0
	move.l (a0)+,d0
	bne.s pas_fin_table
	move.l #table_deplacement+4,pointeur_table
	rts
pas_fin_table
	move.l a0,pointeur_table
	rts

***************************************
* remplissage des adresses d'effacage *
***************************************

fill_clear
	lea pos_ecran1,a0
	lea pos_ecran2,a1
	move.l #ecran1,d0
	move.l #ecran2,d1
	move.w #NB_BOB-1,d2
loop_fill
	move.l d0,(a0)+
	move.l d1,(a1)+
	dbf d2,loop_fill
	rts

********************************************
* fabrication masque et image en entrelace *
********************************************

make_masque
	lea bille,a0
	lea masque,a1
	move.w #31,d1
loop_masque
	move.w #2,d0
loop_ligne_masque
	move.w (a0),d2
	or.w 192(a0),d2
	or.w 384(a0),d2
	move.w d2,(a1)
	move.w d2,6(a1)
	move.w d2,12(a1)
	addq.l #2,a0
	addq.l #2,a1
	dbf d0,loop_ligne_masque
	add.l #12,a1
	dbf d1,loop_masque
	rts

make_ball
	lea bille,a0
	lea ball,a1
	move.w #31,d1
loop_ball
	move.w #2,d0
loop_ligne_ball
	move.w (a0),(a1)
	move.w 192(a0),6(a1)
	move.w 384(a0),12(a1)
	addq.l #2,a0
	addq.l #2,a1
	dbf d0,loop_ligne_ball
	add.l #12,a1
	dbf d1,loop_ball
	rts

	include "TMC_Replay.s"
	include "Song.s"

next_screen
	dc.l ecran1
current_screen
	dc.l ecran2
pointeur_table
	dc.l table_deplacement
table_deplacement
	include deplacement.s
fin_table
	dc.l 0
clear_bob_pos
	dc.l pos_ecran1
	dc.l pos_ecran2
pos_ecran1
	dcb.l NB_BOB,0
pos_ecran2
	dcb.l NB_BOB,0

	section picture,data_c
ecran1	dcb.b 30720,0
ecran2	dcb.b 30720,0
bille	incbin ball
masque	dcb.b 576,0
ball	dcb.b 576,0
coplist
	include ball.color
	dc.l $fffffffe
	
	include "Samples.s"
