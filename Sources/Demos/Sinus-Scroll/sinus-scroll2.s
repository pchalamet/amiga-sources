
*
*		Sinus-Scroll  Very   Faaaassssstttt !	
*

	OPT NOCHKBIT

wait_blitter	macro
wait_blit\@
	btst #14,dmaconr(a6)
	bne.s wait_blit\@
	endm

	incdir "asm:" "asm:Sinus-Scroll" "ram:"
	
	include "sources/registers.i"
	
	section sin,code_c

	KILL_SYSTEM toto
	moveq #0,d0
	rts

toto	
	lea d(pc),a5
	lea $dff000,a6
	move.w #$7fff,d0
	move.w d0,intena(a6)
	move.w d0,dmacon(a6)
	
	move.w #$2200,bplcon0(a6)
	moveq #0,d0
	move.w #1,bplcon1(a6)
	move.w d0,bplcon2(a6)
	move.l d0,bpl1mod(a6)
	move.l #$003800d0,ddfstrt(a6)
	move.l #$298129c1,diwstrt(a6)

	move.w d0,bltcon1(a6)			quelques inits du
	move.w #$ffff,bltalwm(a6)		blitter
	move.w #$0026,bltbmod(a6)

	move.l #coplist,cop1lc(a6)
	move.w d0,copjmp1(a6)
	
	move.l #vbl,$6c.w

	move.w #$87c0,dmacon(a6)
	move.w #$c020,intena(a6)

mickey
	btst #6,ciaapra
	bne.s mickey

	RESTORE_SYSTEM

coplist
	dc.w fmode,0
	dc.w color00,$000
	dc.w color01,$777
	dc.w color02,$aaa
	dc.w color03,$fff
	dc.l $fffffffe

text_ptr	dc.l text
text		dc.b "NICE  SCROLL       YEAHHH  ",-1,"    "
count		dc.b 1
pause		dc.b 0
	even

vbl
	lea d(pc),a5
	lea $dff000,a6
	bsr SinusScroll

	move.w #$20,intreq(a6)
	rte

SinusScroll
	movem.l log_screen(pc),a0-a1		flip les écrans
	exg a0,a1
	movem.l a0-a1,log_screen-d(a5)
	move.l a1,bpl1ptH(a6)			on travaille sur a0
	add.l #40,a1
	move.l a1,bpl2ptH(a6)

	move.l a0,d0
	add.l #100*40,d0
	move.l d0,bltdpt(a6)			efface le log_screen
	moveq #0,d0
	move.w d0,bltdmod(a6)
	move.w #$0100,bltcon0(a6)
	move.w #156<<6+20,bltsize(a6)

	tst.b pause-d(a5)
	beq.s scroll_hidden
	subq.b #1,pause-d(a5)
	bra DispScroll
scroll_hidden
	wait_blitter
	move.l #hidden_screen+2,bltapt(a6)	bouge le hidden_screen
	move.l #hidden_screen,bltdpt(a6)
	move.l #$00020002,bltamod(a6)
	move.w #$ffff,bltafwm(a6)
	move.w #$c9f0,bltcon0(a6)	
	move.w #32<<6+23,bltsize(a6)

	subq.b #1,count-d(a5)
	bne.s DispScroll
new_lettre
	move.l text_ptr(pc),a1
	move.b (a1)+,d0				récupère la lettre
	bne.s not_end_text
	lea text(pc),a1
	move.b (a1)+,d0
not_end_text
	bgt.s no_pause
	move.b #100,pause-d(a5)
	move.b #1,count-d(a5)
	move.l a1,text_ptr-d(a5)
	bra.s DispScroll
no_pause
	move.b #8,count-d(a5)
	cmp.b #32,d0
	bne.s no_space
	move.b #"Z"+1,d0
no_space
	sub.b #"A",d0				A est la base de la table
	move.l a1,text_ptr-d(a5)
	lea table_lettre(pc),a1
	lsl.w #2,d0				table de long mot

	move.l 0(a1,d0.w),bltapt(a6)		adresse de la lettre
	move.l #hidden_screen+42,bltdpt(a6)
	move.l #$0024002c,bltamod(a6)
	move.w #$09f0,bltcon0(a6)
	move.w #32<<6+2,bltsize(a6)		lettre de 32*32

DispScroll
	lea hidden_screen+2(pc),a1
	move.l sinus_ptr(pc),a2

	move.w #160-1,d0			nb de colonne
	move.w #$c000,d1			masque du transfer sur A
	move.w #32<<6+1,d2			bltsize

	wait_blitter
	move.l #$002e0026,bltamod(a6)
	move.w #$0dfc,bltcon0(a6)
LoopDisp
	moveq #0,d3
	move.w (a2)+,d3
	bne.s Ok
	sub.l #360*2+2,a2
	move.w (a2)+,d3
Ok
	add.l a0,d3

	move.l d3,bltdpt(a6)			A or B -> D
	move.l d3,bltbpt(a6)
	move.l a1,bltapt(a6)
	move.w d1,bltafwm(a6)
	move.w d2,bltsize(a6)
	ror.w #2,d1
	blt.s new_colonne
	dbf d0,LoopDisp
	addq.l #2,sinus_ptr-d(a5)
	rts
new_colonne
	addq.l #2,a0
	addq.l #2,a1
	dbf d0,LoopDisp
	move.l sinus_ptr(pc),a0
	add.l #16,a0
	tst.w (a0)
	beq.s fin
	move.l a0,sinus_ptr-d(a5)
	rts
fin
	move.l #table_sinus,sinus_ptr-d(a5)
	rts

d
log_screen	dc.l ecran1
phy_screen	dc.l ecran2
ecran1		dcb.b 40*256,0
ecran2		dcb.b 41*256,0
hidden_screen	dcb.b (2+40+4+2)*32

a	macro
	dc.l lettre_pic+\1+\2*40
	endm

table_lettre
val set 0
	rept 10
	a val,0
val set val+4
	endr

val set 0
	rept 10
	a val,32
val set val+4
	endr

val set 0
	rept 7
	a val,64
val set val+4
	endr

lettre_pic	incbin font.nice2

sinus_ptr	dc.l table_sinus		ptr sur table_sinus
		
table_sinus	incbin sinus2.dat
		dc.l 0,0,0,0

