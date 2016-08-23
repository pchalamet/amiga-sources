
*			Test du blitter en LowRes
*			~~~~~~~~~~~~~~~~~~~~~~~~~

* Bob 64*64 de la même profondeur que l'écran
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

* Resultats en Low-res
* ~~~~~~~~~~~~~~~~~~~~
*  Nb Bitplans      BURST   0      1      2      3
* -------------------------------------------------
*      1                   58     60     60     61
*      2                   27     30     30     31
*      3                   17     19     19     20
*      4                   11     14     14     15
*      5                    8     10     10     12
*      6                    6      8      8      9
*      7                    4      7      7      8
*      8                    3      5      5      7

PRI=1
BPL_DEPTH=1
BURST=3
NB_BOB=60

	incdir "asm:sources/"
	include "registers.i"

	section testos,code_c

	KILL_SYSTEM test
	moveq #0,d0
	rts

test
	lea custom_base,a6

	move.l #screen,d0
	addq.l #7,d0
	and.l #-8,d0
	move.l d0,bpl_ptr
	lea screen_ptr(pc),a0
	moveq #BPL_DEPTH-1,d1
put
	move.w d0,4(a0)
	swap d0
	move.w d0,(a0)
	swap d0
	add.l #40,d0
	addq.l #8,a0
	dbf d1,put

	move.l #coplist,cop1lc(a6)
	clr.w copjmp1(a6)
	move.l #Vbl,$6c.w

	IFNE PRI
	move.w #$87c0,dmacon(a6)
	ELSEIF
	move.w #$83c0,dmacon(a6)	
	ENDC
	move.w #$c020,intena(a6)

	WAIT_LMB_DOWN
	RESTORE_SYSTEM

Vbl
	moveq #NB_BOB-1,d0
loop
	move.l #bob,bltapt(a6)
	move.l #bob,bltbpt(a6)
	move.l #bob,bltcpt(a6)
	move.l bpl_ptr(pc),bltdpt(a6)
	move.l #$ffffffff,bltafwm(a6)
	move.l #$0fff0000,bltcon0(a6)
	clr.w bltamod(a6)
	clr.w bltbmod(a6)
	clr.w bltcmod(a6)
	move.w #40-(64/8),bltdmod(a6)
	move.l #(64*BPL_DEPTH<<16)|(64/16),bltsizV(a6)
	WAIT_BLITTER
	dbf d0,loop
	move.w #$f00,color00(a6)

	move.w #$0020,intreq(a6)
	rte

bpl_ptr
	dc.l 0

coplist
	IFNE (BPL_DEPTH=8)
	dc.w bplcon0,$0210
	ELSEIF
	dc.w bplcon0,(BPL_DEPTH<<12)|$0200
	ENDC

	dc.w diwstrt,$2b81
	dc.w diwstop,$2bc1
	dc.w ddfstrt,$0038
	IFNE (BURST=0)
	dc.w ddfstop,$00d0
	dc.w fmode,%00
	ENDC
	IFNE (BURST=1)
	dc.w ddfstop,$00c8
	dc.w fmode,%01
	ENDC
	IFNE (BURST=2)
	dc.w ddfstop,$00c8
	dc.w fmode,%10
	ENDC
	IFNE (BURST=3)
	dc.w ddfstop,$00a8
	dc.w fmode,%11
	ENDC
	dc.w bpl1mod,40*(BPL_DEPTH-1)
	dc.w bpl2mod,40*(BPL_DEPTH-1)
	dc.w color00,$000
	dc.w color01,$fff

dummy set bpl1ptH
screen_ptr=*+2
	REPT BPL_DEPTH
	dc.w dummy,0
	dc.w dummy+2,0
dummy set dummy+4
	ENDR

	dc.l $fffffffe

bob
	dcb.b (64/8)*64*BPL_DEPTH,$ff

screen
	ds.b 40*256*BPL_DEPTH
	ds.b 4
