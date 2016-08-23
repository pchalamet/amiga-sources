
*			Sinus scroll
*			~~~~~~~~~~~~


	OPT NOCHKBIT

	incdir "asm:"
	incdir "asm:sources/"
	incdir "asm:songs/small"


 	include sources/Registers.i
	
	KILL_SYSTEM do_sinus_scroll
	moveq #0,d0
	rts


do_sinus_scroll
	lea $dff000,a6

	move.w #$7fff,d0		ecran
	move.w d0,dmacon(a6)		et vbl
	move.w d0,intena(a6)

	jsr mt_init

	move.l #vbl,$6c.w
	move.l #coplist,cop1lc(a6)
	clr.w copjmp1(a6)
	move.w #$ffff,bltalwm(a6)

	move.w #$87c0,dmacon(a6)
	move.w #$c020,intena(a6)

mickey
	btst #6,ciaapra
	bne.s mickey
	jsr mt_end
	RESTORE_SYSTEM


* La nouvelle vbl
* ~~~~~~~~~~~~~~~
vbl
	SAVE_REGS
	lea $dff000,a6
	bsr.s flip_screen			permute les ecrans
	bsr.s clear_hidden_screen
	bsr.s do_scroll			deplace le scroll caché
	bsr put_scroll			copie scroll caché dans ecran caché
	jsr mt_music
	lea $dff000,a6

	VBL_SIZE color00,$fff
	move.w #$20,intreq(a6)
	RESTORE_REGS
	rte

* Echange des ecrans
* ~~~~~~~~~~~~~~~~~~
flip_screen
	move.l next_screen(pc),d0
	move.l current_screen(pc),next_screen
	move.l d0,current_screen
	move.l d0,bpl1ptH(a6)
	add.l #40,d0
	move.l d0,bpl2ptH(a6)
	rts

* Effacage de l'écran
* ~~~~~~~~~~~~~~~~~~~
clear_hidden_screen
	WAIT_BLITTER
	clr.w bltadat(a6)
	clr.w bltdmod(a6)
	move.w #$ffff,bltafwm(a6)
	move.w #$01f0,bltcon0(a6)
	move.l next_screen(pc),bltdpt(a6)
	move.w #234*64+20,bltsize(a6)
	rts

* Fait scroller l'écran caché
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~
do_scroll
	tst.b momento
	beq.s no_wait
	subq.b #1,momento
	rts
no_wait
	move.l pointeur_text(pc),a0	fait entrer les letttres
	tst.b letter_count		dans l'écran caché
	beq.s new_letter
	subq.b #1,letter_count
	bra.s scroll
new_letter
	move.b #7,letter_count
	clr.l d0
	move.b (a0)+,d0
	bne.s continue1
	lea text,a0
	move.b (a0)+,d0
continue1
	bpl.s continue2
	move.b #100,momento
	move.l a0,pointeur_text
	rts
continue2
	cmp.b #32,d0
	bne.s continue3
	move.l a0,pointeur_text
	bra.s scroll
	
continue3
	sub.b #"A",d0			A est la base de la table
	lsl.w d0			table composée de mot => *2
	lea table_pos(pc),a1
	sub.l a2,a2			/ calcul adresse lettre
	move.w 0(a1,d0.l),a2		/ dans image
	adda.l #lettres,a2		/
	WAIT_BLITTER
	move.l a2,bltapt(a6)
	move.l #$24002c,bltamod(a6)
	move.l #hidden_screen+42,bltdpt(a6)
	move.w #$09f0,bltcon0(a6)
	move.w #32*64+2,bltsize(a6)
	
scroll
	WAIT_BLITTER				scroll tout le texte
	move.l #hidden_screen+2,bltapt(a6)	caché
	move.l #$20002,bltamod(a6)
	move.l #hidden_screen,bltdpt(a6)
	move.w #$c9f0,bltcon0(a6)
	move.w #32*64+23,bltsize(a6)
	move.l a0,pointeur_text
	rts

* Affichage du sinus scroll
* ~~~~~~~~~~~~~~~~~~~~~~~~~
put_scroll
	move.w #159,d0				met scroll dans
	move.l pointeur_onde(pc),a1		écran caché
	lea hidden_screen+2,a2
	move.l next_screen(pc),a0
	move.w #$c000,d1

	move.l a0,a3
	adda.w (a1)+,a3

	cmp.l a3,a0
	bne.s attend_blitter
	lea table_sinus+2(pc),a1
	adda.w (a1),a3

attend_blitter
	WAIT_BLITTER
	move.w #$26,bltdmod(a6)
	move.l #$26002e,bltbmod(a6)
	move.w #$0dfc,bltcon0(a6)
	bra.s real_first_move

loop_cut
	move.l a0,a3
	tst.w (a1)
	beq.s fin_table_mvt
	adda.w (a1)+,a3
	bra.s continue_loop
fin_table_mvt	
	lea table_sinus+2(pc),a1
	adda.w (a1)+,a3

continue_loop
	WAIT_BLITTER
real_first_move
	move.l a2,bltapt(a6)
	move.l a3,bltbpt(a6)
	move.l a3,bltdpt(a6)
	move.w d1,bltafwm(a6)
	move.w #32*64+1,bltsize(a6)	transfer !
	
	ror.w #2,d1
	bcs.s change_bloc
	dbf d0,loop_cut
	bra.s fin_put_scroll
change_bloc
	move.w #$c000,d1
	addq.w #2,a0
	addq.w #2,a2
	dbf d0,loop_cut

fin_put_scroll
	move.l pointeur_onde(pc),a0
	add.w #20,a0
	tst.w (a0)
	bne.s fin_sinus
	lea table_sinus(pc),a0
fin_sinus
	move.w a0,pointeur_onde+2
	rts


next_screen	dc.l ecran1		adresse de l'ecran caché
current_screen	dc.l ecran2

pointeur_text	dc.l text
letter_count	dc.b 0
momento		dc.b 0

table_pos	dc.w 0,4,8,12,16,20,24,28,32,36
		dc.w 1280,1284,1288,1292,1296,1300,1304,1308,1312,1316
		dc.w 2560,2564,2568,2572,2576,2580,2584
pointeur_onde	dc.l table_sinus

table_sinus
	include onde.s
	dcb.l 4,0
	even
text
	dc.b "  CHARSET ",-1,"   ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	dc.b "   ",0

	even
	include "TMC_Replay.s"
	include "Song.s"



* Les datas qui doivent aller en chip
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	section ecran,data_c
ecran1
	dcb.b 234*40,$0			ecran de 40*234
	dcb.b 40,$ff
ecran2
	dcb.b 234*40,$0			ecran de 40*234
	dcb.b 40,$ff
hidden_screen
	dcb.b 1536,0			hidden_screen de 48*32
	even
lettres
	incbin font.nice2
	even
	
coplist
	dc.w fmode,$3
	dc.w bplcon0,$2200
	dc.w bplcon1,$0
	dc.w bplcon2,$0
	dc.w diwstrt,$2b81
	dc.w diwstop,$2bc1
	dc.w ddfstrt,$0038
	dc.w ddfstop,$00a0
	dc.w bpl1mod,0
	dc.w bpl2mod,0
	dc.w color00,0
	dc.w color01,$888
	dc.w color02,$ccc
	dc.w color03,$fff
	dc.w $640f,$fffe
	dc.w color00,$3
	dc.w $650f,$fffe
	dc.w color00,$2
	dc.w $660f,$fffe
	dc.w color00,$3
	dc.w $8c0f,$fffe
	dc.w color00,$5
	dc.w $8d0f,$fffe
	dc.w color00,$4
	dc.w $8e0f,$fffe
	dc.w color00,$5
	dc.w $b40f,$fffe
	dc.w color00,$9
	dc.w $b50f,$fffe
	dc.w color00,$8
	dc.w $b60f,$fffe
	dc.w color00,$9
	dc.w $dc0f,$fffe
	dc.w color00,$d
	dc.w $dd0f,$fffe
	dc.w color00,$b
	dc.w $de0f,$fffe
	dc.w color00,$d
	dc.w $ff0f,$fffe
	dc.w color00,$f
	dc.w $ffdf,$fffe
	dc.w $000f,$fffe
	dc.w color00,$e
	dc.w $010f,$fffe
	dc.w color00,$f
	dc.w $110f,$fffe
	dc.w color01,$666
	dc.w color02,$aaa
	dc.w color03,$ddd
	dc.w bpl1mod,-80
	dc.w bpl2mod,-80
	dc.l $fffffffe

	include "Samples.s"
