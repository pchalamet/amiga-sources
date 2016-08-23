
*				Fractales !
*				~~~~~~~~~~~



* EQU en vrac
* ~~~~~~~~~~~
SCREEN_X=320
SCREEN_Y=256
SCREEN_DEPTH=8
SCREEN_WIDTH=SCREEN_X/8
SCREEN_HEIGHT=SCREEN_WIDTH*SCREEN_DEPTH
STACK_SIZE=10*1024
DEG_MAX=8
TABLEAU_WIDTH=(1<<DEG_MAX)


* options de compilations
* ~~~~~~~~~~~~~~~~~~~~~~~
	OPT O+,OW+
	OPT P=68030



* les includes
* ~~~~~~~~~~~~
	incdir "asm:sources/"
	incdir "asm:.s/Fractales/"
	include "registers.i"



* le programme principale
* ~~~~~~~~~~~~~~~~~~~~~~~
	section fractales,code_f
	KILL_SYSTEM do_Fractale
	moveq #0,d0
	rts

do_Fractale
	lea (data_base,pc),a5
	lea custom_base,a6
	move.l a7,(Old_Stack-data_base,a5)
	lea New_Stack,a7

	move.l #coplist,(cop1lc,a6)
	clr.w (copjmp1,a6)
	move.l #vbl,$6c.w

	move.w #$8380,(dmacon,a6)
	move.w #$c020,(intena,a6)

main_loop
	lea Tableau,a0
	move.l a0,a1
	move.l #TABLEAU_WIDTH,d0
	move.l #TABLEAU_WIDTH*TABLEAU_WIDTH,d1
	moveq #$7f,d2
	bsr.s Init
	bsr.s Compute_Fractale
	bsr Display_Fractale

.wait
	btst #6,ciaapra
	beq.s .exit
	btst #2,potinp(a6)
	beq.s main_loop
	bra.s .wait

.exit
	move.l Old_Stack(pc),a7
	RESTORE_SYSTEM


* Calcule d'une fractale
* ~~~~~~~~~~~~~~~~~~~~~~
Compute_Fractale
	movem.l d0/d1/a0,-(sp)

	lsr.l #1,d0				descend d'un niveau
	lsr.l #1,d1

* calcule des nouveau niveau
	move.w (a0,d0.l*2),d2
	add.w (a0,d0.l*2),d2			T(2,1)
	add.w (a0,d1.l*2),d2			T(1,2)
	add.l d0,d1
	add.w (a0,d1.l*2),d2			T(2,2)
	sub.l d0,d1
	lsr.w #2,d2
	move.l a0,a1
	bsr.s Init				===> T(1,1)
	lea (a0,d0.l*2),a1
	bsr.s Init				===> T(2,1)
	lea (a0,d1.l*2),a1
	bsr.s Init				===> T(1,2)
	lea (a1,d0.l*2),a1
	bsr.s Init				===> T(1,2)


	IFNE 0
	moveq #0,d2
	move.w (a0,d0.l*2),d2			T(2,1)
	add.w (a0,d1.l*2),d2			T(1,2)
	add.l d0,d1
	add.w (a0,d1.l*2),d2			T(2,2)
	sub.l d0,d1
	divu #3,d2
	move.l a0,a1
	bsr.s Init				===> T(1,1)

	moveq #0,d2
	move.w (a0),d2				T(1,1)
	add.w (a0,d1.l*2),d2			T(1,2)
	add.l d0,d1
	add.w (a0,d1.l*2),d2			T(2,2)
	sub.l d0,d1
	divu #3,d2
	lea (a0,d0.l*2),a1
	bsr.s Init				===> T(2,1)

	moveq #0,d2
	move.w (a0),d2				T(1,1)
	add.w (a0,d0.l*2),d2			T(2,1)
	add.l d0,d1
	add.w (a0,d1.l*2),d2			T(2,2)
	sub.l d0,d1
	divu #3,d2
	lea (a0,d1.l*2),a1
	bsr.s Init				===> T(1,2)

	moveq #0,d2
	move.w (a0),d2				T(1,1)
	add.w (a0,d0.l*2),d2			T(2,1)
	add.w (a0,d1.l*2),d2			T(1,2)
	divu #3,d2
	lea (a1,d0.l*2),a1
	bsr.s Init				===> T(1,2)
	ENDC

* recursivité sur les carrés suivants
	tst.l d0
	beq.s .end_recurse

	bsr.s Compute_Fractale			T(1,1)
	lea (a0,d0.l*2),a0
	bsr.s Compute_Fractale			T(2,1)
	move.b vhposr(a6),d7
	lea (a0,d1.l*2),a0
	bsr.s Compute_Fractale			T(2,2)
	sub.l d0,a0
	sub.l d0,a0
	bsr.s Compute_Fractale			T(1,2)

.end_recurse
	movem.l (sp)+,d0/d1/a0
	rts


* Initialise tout un carré avec la meme couleur
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*  -->	a1=*buffer
*	d2=couleur
*	d0=hauteur/largeur du carré
*
* <--	a1=*buffer
*	d2=couleur
*	d3-d4/a3 trashed
Init
	move.b vhposr+1(a6),d3
	and.w #$1f,d3
	add.w d2,d3
	sub.w #$f,d3
	bge.s .ok1
	moveq #0,d3
.ok1
	cmp.w #$ff,d3
	ble.s .ok2
	move.w #$ff,d3
.ok2
	move.w d0,d4
	move.l a1,a3
loop_Y
	move.l a3,a4
	move.w d0,d5
loop_X
	move.w d3,(a4)+
	dbf d5,loop_X
	lea TABLEAU_WIDTH*2(a3),a3
	dbf d4,loop_Y
	rts



* Affichage du buffer
* ~~~~~~~~~~~~~~~~~~~
Display_Fractale
	SAVE_REGS
	lea Tableau,a0
	lea Ecran,a1

	move.w #TABLEAU_WIDTH-1,d0
put_Y
	moveq #0,d1				X
put_X
	move.w (a0)+,d2
	moveq #SCREEN_DEPTH-1,d3
	move.l a1,a2
	move.w d1,d4
	move.w d1,d5
	lsr.w #3,d4
	not.w d5
put_pixel
	lsr.w #1,d2
	bcc.s .clear
.set
	bset d5,(a2,d4.w)
	lea SCREEN_WIDTH(a2),a2
	dbf d3,put_pixel
	addq.w #1,d1
	cmp.w #TABLEAU_WIDTH,d1
	bne.s put_X
	lea SCREEN_HEIGHT(a1),a1
	dbf d0,put_Y
	RESTORE_REGS
	rts
.clear
	bclr d5,(a2,d4.w)
	lea SCREEN_WIDTH(a2),a2
	dbf d3,put_pixel
	addq.w #1,d1
	cmp.w #TABLEAU_WIDTH,d1
	bne.s put_X
	lea SCREEN_HEIGHT(a1),a1
	dbf d0,put_Y
	RESTORE_REGS
	rts



* la vbl
* ~~~~~~
vbl
	SAVE_REGS

	lea custom_base,a6

	lea Ecran,a0
	move.l a0,(bpl1ptH,a6)
	lea (SCREEN_WIDTH,a0),a0
	move.l a0,(bpl2ptH,a6)
	lea (SCREEN_WIDTH,a0),a0
	move.l a0,(bpl3ptH,a6)
	lea (SCREEN_WIDTH,a0),a0
	move.l a0,(bpl4ptH,a6)
	lea (SCREEN_WIDTH,a0),a0
	move.l a0,(bpl5ptH,a6)
	lea (SCREEN_WIDTH,a0),a0
	move.l a0,(bpl6ptH,a6)
	lea (SCREEN_WIDTH,a0),a0
	move.l a0,(bpl7ptH,a6)
	lea (SCREEN_WIDTH,a0),a0
	move.l a0,(bpl8ptH,a6)

	move.w #$0020,(intreq,a6)
	RESTORE_REGS
	rte


* les datas
* ~~~~~~~~~
data_base

Old_Stack
	dc.l 0


* grosses datas...
* ~~~~~~~~~~~~~~~~
	section pile,bss_f
Tableau
	ds.w TABLEAU_WIDTH*TABLEAU_WIDTH

	ds.b STACK_SIZE
New_Stack



* zou.. en CHIP tout ca !
* ~~~~~~~~~~~~~~~~~~~~~~~
	section copper,data_c
coplist
	dc.w fmode,$3
	dc.w bplcon0,$0210
	dc.w bplcon1,$0
	dc.w bplcon2,$0
	dc.w ddfstrt,$0038
	dc.w ddfstop,$00a0
	dc.w diwstrt,$2b81
	dc.w diwstop,$2bc1
	dc.w bpl1mod,SCREEN_WIDTH*(SCREEN_DEPTH-1)
	dc.w bpl2mod,SCREEN_WIDTH*(SCREEN_DEPTH-1)

	IFNE 0
palette set $0000
colorMSB set $000
	REPT 8
	dc.w bplcon3,palette
	dc.w color00,colorMSB
	dc.w color01,colorMSB
	dc.w color02,colorMSB
	dc.w color03,colorMSB
	dc.w color04,colorMSB
	dc.w color05,colorMSB
	dc.w color06,colorMSB
	dc.w color07,colorMSB
	dc.w color08,colorMSB
	dc.w color09,colorMSB
	dc.w color10,colorMSB
	dc.w color11,colorMSB
	dc.w color12,colorMSB
	dc.w color13,colorMSB
	dc.w color14,colorMSB
	dc.w color15,colorMSB
	dc.w color16,colorMSB+$111
	dc.w color17,colorMSB+$111
	dc.w color18,colorMSB+$111
	dc.w color19,colorMSB+$111
	dc.w color20,colorMSB+$111
	dc.w color21,colorMSB+$111
	dc.w color22,colorMSB+$111
	dc.w color23,colorMSB+$111
	dc.w color24,colorMSB+$111
	dc.w color25,colorMSB+$111
	dc.w color26,colorMSB+$111
	dc.w color27,colorMSB+$111
	dc.w color28,colorMSB+$111
	dc.w color29,colorMSB+$111
	dc.w color30,colorMSB+$111
	dc.w color31,colorMSB+$111

colorMSB set colorMSB+$222
palette set palette+$2000
	ENDR

palette set $0200
	REPT 8
	dc.w bplcon3,palette
	dc.w color00,$000
	dc.w color01,$111
	dc.w color02,$222
	dc.w color03,$333
	dc.w color04,$444
	dc.w color05,$555
	dc.w color06,$666
	dc.w color07,$777
	dc.w color08,$888
	dc.w color09,$999
	dc.w color10,$aaa
	dc.w color11,$bbb
	dc.w color12,$ccc
	dc.w color13,$ddd
	dc.w color14,$eee
	dc.w color15,$fff
	dc.w color16,$000
	dc.w color17,$111
	dc.w color18,$222
	dc.w color19,$333
	dc.w color20,$444
	dc.w color21,$555
	dc.w color22,$666
	dc.w color23,$777
	dc.w color24,$888
	dc.w color25,$999
	dc.w color26,$aaa
	dc.w color27,$bbb
	dc.w color28,$ccc
	dc.w color29,$ddd
	dc.w color30,$eee
	dc.w color31,$fff

palette set palette+$2000
	ENDR
	ENDC

	include "Fractales.PAL"

	dc.l $fffffffe


* et un ecran
* ~~~~~~~~~~~
	section ecran,bss_c
Ecran
	ds.b SCREEN_WIDTH*SCREEN_Y*SCREEN_DEPTH
