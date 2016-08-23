

	incdir "asm:.s/Plasma"
	incdir "asm:sources/"
	incdir "asm:songs/medium"

	opt O+,OW-			optimise les add et lea
	opt NOCHKBIT
	
			*******************
			* datas du plasma *
			*******************
speed_sinusx1	set 5
inc_sinusx1	set 5

speed_sinusx2	set -1
inc_sinusx2	set 6

speed_sinusy1	set 3
inc_sinusy1	set 4

speed_sinusy2	set 4
inc_sinusy2	set 2

			**********************
			* datas du programme *
			**********************
speed_sinusx1	set speed_sinusx1<<1
inc_sinusx1	set inc_sinusx1<<1
speed_sinusx2	set speed_sinusx2<<1
inc_sinusx2	set inc_sinusx2<<1
speed_sinusy1	set speed_sinusy1<<1
inc_sinusy1	set inc_sinusy1<<1
speed_sinusy2	set speed_sinusy2<<1
inc_sinusy2	set inc_sinusy2<<1

speed_sinusx	set speed_sinusx2<<16+speed_sinusx1
inc_sinusx	set inc_sinusx2<<16+inc_sinusx1
speed_sinusy	set speed_sinusy2<<16+speed_sinusy1
inc_sinusy	set inc_sinusy2<<16+inc_sinusy1

NB_MOVEX	= 5
NB_COLONNE	= 52
NB_LIGNE	= NB_COLONNE*NB_MOVEX
NB_BYTES_LIGNE	= (NB_COLONNE+1)*4			WAIT+MOVES
COPLIST_SIZE	= 4+4+NB_BYTES_LIGNE*NB_LIGNE+4+4+4+4+4	BARRE+END_COPLIST
BARRE_COLOR	= $fff

	incdir "asm:"
	include "sources/registers.i"

	section main_prg,code

			****************************
			* initialisations diverses *
			****************************
	KILL_SYSTEM golo_golo
	moveq #0,d0
	rts

golo_golo
	lea $dff000,a6
	jsr mt_init

	move.l #cop2,cop1lc(a6)			installe une coplist
	clr.w copjmp1(a6)
	move.l #vbl,$6c.w			installe la nouvelle vbl

	move.l #$003000d8,ddfstrt(a6)
	move.l #$8471c0d1,diwstrt(a6)

	move.w #$0200,bplcon0(a6)
	move.l #0,bplcon1(a6)
	move.w #$3,fmode(a6)

	move.w #$87c0,dmacon(a6)		blitter|copper
	move.w #$c020,intena(a6)		vbl uniquement
	
	WAIT_LMB_DOWN
	jsr mt_end
	RESTORE_SYSTEM

			************************
			* nouvelle routine vbl *
			************************
vbl
	jsr mt_music				la zizique

	lea plasma_data(pc),a5			base des datas
	lea $dff000,a6

	bsr plasma				LE PLASMA
	
	movem.l coplist1(pc),a3-a4		échange des coplists
	exg a3,a4
	movem.l a3-a4,coplist1-plasma_data(a5)
	move.l a3,cop1lc(a6)			adr coplist dans registre

	VBL_SIZE color00,$fff

	move.w #$20,intreq(a6)
	rte

coplist1	dc.l cop1
coplist2	dc.l cop2


			************************
			* la routine de plasma *
			************************
plasma
	move.l coplist2(pc),a0		cherche la coplist de travail
	lea 4+4+1(a0),a0		a0=pointeur coplist X
	lea 4+1(a0),a1			a1=pointeur coplist Y
	lea table_couleur+256,a2	a2 pointe sur la table des couleurs
	lea table_sinus-plasma_data(a5),a3	a3=pointeur table sinus
	move.l #inc_sinusx,d3		d3=inc_sinusx
	move.l d3,d4			d4=inc_sinusx avec un swap
	swap d4
	move.l #inc_sinusy,d5		d5=inc_sinusy
	move.l d5,d6			d6=inc_sinusy avec un swap
	swap d6
	move.l #$01fe01fe,d7		taille de la table sinus
	
	add.l #speed_sinusx,sinusx_ptr-plasma_data(a5)	sinus sur les X
	add.l #speed_sinusy,sinusy_ptr-plasma_data(a5)	sinus sur les Y
	movem.l sinusx_ptr(pc),d0-d1			pointeurs sinus

			***********************************
			* initialisation du blitter	  *
			* avant de rentrer dans la boucle *
			***********************************
	move.l #$09f00000,bltcon0(a6)		mode A=D
	moveq #-1,d2
	move.l d2,bltafwm(a6)			masque sur A
	move.l #NB_BYTES_LIGNE-2,bltamod(a6)	modulo A et D
;bsize=NB_LIGNE<<6+1
bsize=(NB_LIGNE<<16)+1


			***********************************
			* macro qui fait bouger sur les X *
			***********************************
x_move	macro
	and.l d7,d0				évite de sortir de la table
	move.w 0(a3,d0.w),d2
	swap d0
	add.w 0(a3,d0.w),d2			ajoute les 2 sinus
	
	asr.w #4,d2
	add.b #$1e,d2				recentre le plasma
	or.b #$01,d2				data impaire car WAIT

	move.b d2,NB_BYTES_LIGNE*mult(a0)	met le WAIT ainsi calculé

	add.l \1,d0				ajoute INC_SINUSX

mult set mult+1	
	endm

			***********************************
			* macro qui fait bouger sur les Y *
			***********************************
y_move	macro
	and.l d7,d1				évite de sortir de la table
	move.w 0(a3,d1.w),d2			récupère les 2 sinus
	swap d1
	add.w 0(a3,d1.w),d2			ajoute les 2 sinus

	lea 0(a2,d2.w),a4			recherche début des couleurs

.fea\@
	btst #14,dmaconr(a6)
	bne.s .fea\@

	move.l a4,bltapt(a6)			source : couleurs
	move.l a1,bltdpt(a6)			destination
;	move.w #bsize,bltsize(a6)		let's go !!
	move.l #bsize,bltsizV(a6)
	addq.l #4,a1				MOVE suivant
	add.l \1,d1				ajoute INC_SINUSY

	endm
			*************
			* la boucle *
			*************
mult set 0
info_mult set 15
do_plasma
	rept NB_COLONNE/2			car code déja dupliqué 2 fois

	y_move d5				plasma sur les Y
	x_move d3				plasma sur les X
	x_move d4				on répète NB_MOVEX fois
	x_move d3
	x_move d4
	x_move d3

	y_move d6				idem
	x_move d4
	x_move d3
	x_move d4
	x_move d3
	x_move d4

info_mult set info_mult-1
	IFEQ info_mult
	lea NB_BYTES_LIGNE*mult(a0),a0
mult set 0
info_mult set 15
	ENDC
	endr
	rts	
	
plasma_data

sinusx_ptr	dc.l 0
sinusy_ptr	dc.l 0

table_sinus
	incbin plasma_sinus.dat

a 	macro
	dc.w \1,\1,\2,\2,\3,\3,\4,\4,\5,\5,\6,\6,\7,\7,\8,\8,\9,\9,\a,\a
	endm

	include "TMC_Replay.s"
	include "Song.s"



	section cead,data_c
table_couleur
	rept 2
		a $000,$100,$200,$300,$400,$500,$600,$700,$800,$900
		a $a00,$b00,$c00,$d00,$e00,$f00,$f10,$f20,$f30,$f40
		a $f50,$f60,$f70,$f80,$f90,$fa0,$fb0,$fc0,$fd0,$fe0
		a $ff0,$ff1,$ff2,$ff3,$ff4,$ff5,$ff6,$ff7,$ff8,$ff9
		a $ffa,$ffb,$ffc,$ffd,$ffe,$fff,$eff,$dff,$cff,$bff
		a $aff,$9ff,$8ff,$7ff,$6ff,$5ff,$4ff,$3ff,$2ff,$1ff
		a $0ff,$0ef,$0df,$0cf,$0bf,$0af,$09f,$08f,$07f,$06f
		a $05f,$04f,$03f,$02f,$01f,$00f,$10f,$20f,$30f,$40f
		a $50f,$60f,$70f,$80f,$90f,$a0f,$b0f,$c0f,$d0f,$e0f
		a $f0f,$e1e,$d2d,$c3c,$b4b,$a5a,$969,$878,$787,$696
		a $5a5,$4b4,$3c3,$2d2,$1e1,$0f0,$0e0,$0d0,$0c0,$0b0
		a $0a0,$090,$080,$070,$060,$050,$040,$030,$020,$010
	endr
		a $000,$100,$200,$300,$400,$500,$600,$700,$800,$900
		a $a00,$b00,$c00,$d00,$e00,$f00,$f10,$f20,$f30,$f40

cop1
	dc.w $282d,$fffe
	dc.w color00,BARRE_COLOR
wait set $291e
	rept NB_LIGNE
	dc.w wait,$fffe
	dcb.l NB_COLONNE,color00<<16
wait set (wait+$100)&$ffff
	endr
wait set (wait&$ff00)|$2d
	dc.w wait,$fffe
	dc.w color00,BARRE_COLOR
wait set wait+$100
	dc.w wait,$fffe
	dc.w color00,$000
	dc.l $fffffffe
cop2
	dc.w $282d,$fffe
	dc.w color00,BARRE_COLOR
wait set $291e
	rept NB_LIGNE
	dc.w wait,$fffe
	dcb.l NB_COLONNE,color00<<16
wait set (wait+$100)&$ffff
	endr
wait set (wait&$ff00)|$2d
	dc.w wait,$fffe
	dc.w color00,BARRE_COLOR
wait set wait+$100
	dc.w wait,$fffe
	dc.w color00,$000
	dc.l $fffffffe

	include "Samples.s"
