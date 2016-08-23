	incdir "asm:sources/"

	opt O+

	include "registers.i"
	
	bsr save_all
	
	lea $dff000,a6
	move.w #$7fff,d0
	move.w d0,intena(a6)
	move.w d0,dmacon(a6)

	move.l #$298129c1,diwstrt(a6)
	move.l #$003800d0,ddfstrt(a6)
	move.w #$1200,bplcon0(a6)
	clr.l bplcon1(a6)
	
	move.l #coplist,cop1lc(a6)
	clr.w copjmp1(a6)

	move.l #vbl,$6c.w
	
	move.w #$83c0,dmacon(a6)
	move.w #$c020,intena(a6)

mickey	btst #6,$bfe001
	bne.s mickey
	
	bsr restore_all
	moveq #0,d0
	rts

	include sources/save_all.s

vbl
	lea $dff000,a6
	lea data_base(pc),a5

	movem.l log_screen(pc),a0/a1
	exg a0,a1
	movem.l a0/a1,log_screen-data_base(a5)
	move.l a1,bpl1ptH(a6)

	bsr gestion_mouse

	move.l log_screen(pc),bltdpt(a6)
	clr.l bltamod(a6)
	move.l #$1000000,bltcon0(a6)
	move.w #256<<6+20,bltsize(a6)

.wait
	btst #14,dmaconr(a6)
	bne.s .wait

size
	move.w #126,d1		rayon
	move.l log_screen(pc),a0	bitplan adr
	move.w MouseX(pc),a1	centreX
	sub.w #150,a1
	move.w MouseY(pc),a2	centreY
	sub.w #150,a2
	bsr draw_circle		trace le cercle

	move.l log_screen(pc),a0
	lea 10240-2(a0),a0
	move.l a0,bltapt(a6)
	move.l a0,bltdpt(a6)
	moveq #-1,d0
	move.l d0,bltafwm(a6)
	move.l #$9f0000a,bltcon0(a6)
	move.w #256<<6+20,bltsize(a6)

	btst #10,potgor(a6)
	bne.s no_red
	move.w #$f00,color00(a6)
	addq.w #1,(size+2).l
no_red
	move.w #$20,intreq(a6)
	rte

gestion_mouse
	move.w joy0dat(a6),d1
	moveq #-1,d3				d3=255
	
	move.b last_X(pc),d0			etat précédent
	move.b d1,last_X-data_base(a5)		etat actuel
	sub.b d1,d0				différence=précédent-actuel
	bvc.s test_Y				Overflow clear ?
	bge.s pas_depassementX_right
	addq.b #1,d0				-255+différence
	bra.s test_Y
pas_depassementX_right
	add.b d3,d0				255+différence
test_Y
	lsr.w #8,d1				récupère les Y
	move.b last_Y(pc),d2
	move.b d1,last_Y-data_base(a5)
	sub.b d1,d2				idem

	bvc.s fin_testY
	bge.s pas_depassementY_down
	addq.b #1,d2
	bra.s fin_testY
pas_depassementY_down
	add.b d3,d2
fin_testY

	ext.w d0
	sub.w d0,mouseX-data_base(a5)		regarde si la souris
	bge.s X_mouse_ok1			est encore dans l'ecran
	move.w #0,mouseX-data_base(a5)
	bra.s X_mouse_ok2

X_mouse_ok1
	cmp.w #320+160*2,mouseX-data_base(a5)
	ble.s X_mouse_ok2
	move.w #320+160*2,mouseX-data_base(a5)

X_mouse_ok2
	ext.w d2
	sub.w d2,mouseY-data_base(a5)
	bge.s Y_mouse_ok1
	move.w #0,mouseY-data_base(a5)
	bra.s ok_mouse

Y_mouse_ok1
	cmp.w #256+160*2,mouseY-data_base(a5)
	ble.s ok_mouse
	move.w #256+160*2,mouseY-data_base(a5)
ok_mouse
	rts

data_base
Last_X	dc.b 0
Last_Y	dc.b 0
MouseX	dc.w 0
MouseY	dc.w 0

log_screen
	dc.l screen1
phy_screen
	dc.l screen2

		***************************************
		* affiche un point et ses symétriques *
		*  par rapport à Centre_X et Centre_Y *
		*				      *
		* en entrée : D1.w=X		      *
		* 	      D2.w=Y		      *
		*	      A0.l=Bpl		      *
		*	      A1.w=Centre_X	      *
		*	      A2.w=Centre_Y	      *
		*	      A3.l=tabX		      *
		*	      a4.l=tabY		      *
		*        a5.w/d7.w=DeltaY	      *
		***************************************
put_pixel	macro			put_pixel X,Y,DeltaY
	move.w a1,d4			regarde si P1 est visible
	add.w \1,d4
	blt .no_dots			test à gauche pour P1
	move.w a2,d5
	add.w \2,d5
	blt .no_dots

	cmp.w #PLANE_WIDTH*4,d4		test à droite pour P1
	bge.s .draw_left
	cmp.w #PLANE_HEIGHT*4,d5
	bge .draw_top

.draw_right
	movem.w 0(a3,d4.w),d4/d6	P1 est visible
	add.w 2(a4,d5.w),d6
	bset d4,0(a0,d6.w)		point P1
	sub.w \3,d6			symetrie suivant Y  --  DeltaY
	blt.s .draw_right_left
	bset d4,0(a0,d6.w)		point P2

.draw_all
	move.w a1,d4
	sub.w \1,d4
	blt .no_dots
	movem.w 0(a3,d4.w),d4/d6
	add.w 2(a4,d5.w),d6
	bset d4,0(a0,d6.w)		point P4
	sub.w \3,d6			symetrie suivant Y  --  Delta Y
	bset d4,0(a0,d6.w)		point P3
	bra .no_dots

.draw_right_left
	move.w a1,d4
	sub.w \1,d4
	blt .no_dots
	movem.w 0(a3,d4.w),d4/d6
	add.w 2(a4,d5.w),d6
	bset d4,0(a0,d6.w)		point P4
	bra .no_dots

.draw_left
	move.w a1,d4
	sub.w \1,d4
	blt.s .draw_left_right
	cmp.w #PLANE_WIDTH*4,d4
	bge .no_dots
	tst.w d5
	blt .no_dots
	cmp.w #PLANE_HEIGHT*4,d5
	bge.s .draw_left_top
	movem.w 0(a3,d4.w),d4/d6
	move.w 2(a4,d5.w),d5
	add.w d5,d6
	bset d4,0(a0,d6.w)		point P4
	bchg #0,(PLANE_WIDTH/8)-1(a0,d5.w)		point à droite
	sub.w \3,d6
	sub.w \3,d5
	blt .no_dots
	bset d4,0(a0,d6.w)		point P3
	bchg #0,(PLANE_WIDTH/8)-1(a0,d5.w)		point à droite
	bra .no_dots

.draw_left_right
	tst.w d5
	blt .no_dots
	cmp.w #PLANE_HEIGHT*4,d5
	bge.s .draw_left_right2
	move.w 2(a4,d5.w),d6
	bchg #0,(PLANE_WIDTH/8)-1(a0,d6.w)		point à droite
	sub.w \3,d6
	blt.s .no_dots
	bchg #0,(PLANE_WIDTH/8)-1(a0,d6.w)		point à droite
	bra.s .no_dots

.draw_left_right2
	move.w a2,d5
	sub.w \2,d5
	blt.s .no_dots
	cmp.w #PLANE_HEIGHT*4,d5
	bge.s .no_dots
	move.w 2(a4,d5.w),d6
	bchg #0,(PLANE_WIDTH/8)-1(a0,d6.w)
	bra.s .no_dots

.draw_left_top
	move.w a2,d5
	sub.w \2,d5
	blt.s .no_dots
	cmp.w #PLANE_HEIGHT*4,d5
	bge.s .no_dots
	movem.w 0(a3,d4.w),d4/d6
	move.w 2(a4,d5.w),d5
	add.w d5,d6
	bset d4,0(a0,d6.w)		point P3
	bchg #0,(PLANE_WIDTH/8)-1(a0,d5.w)		point à droite
	bra.s .no_dots

.draw_top
	move.w a2,d5
	sub.w \2,d5
	blt.s .no_dots
	cmp.w #PLANE_HEIGHT*4,d5
	bge.s .no_dots
	movem.w 0(a3,d4.w),d4/d6
	add.w 2(a4,d5.w),d6
	bset d4,0(a0,d6.w)		point P2
	move.w a1,d4
	sub.w \1,d4
	blt.s .no_dots
	movem.w 0(a3,d4.w),d4/d6
	add.w 2(a4,d5.w),d6
	bset d4,0(a0,d6.w)		point P3
.no_dots
	endm				fin de la macro put_pixel

		***********************************
		*  dessine un cercle de rayon R	  *
		*				  *
		* en entrée : D1.w=Rayon	  *
		*             A0.l=BPL ADR	  *
		*	      A1.w=Centre_X	  *
		*	      A2.w=Centre_Y	  *
		*				  *
		***********************************

PLANE_WIDTH EQU 320
PLANE_HEIGHT EQU 256

draw_circle
	add.w a1,a1			4*Centre_X
	add.w a1,a1
	add.w a2,a2			4*Centre_Y
	add.w a2,a2

	lea tabX(pc),a3			ptr sur des tables
	lea tabY(pc),a4

	moveq #0,d7
	move.w d1,d7			sauve le rayon
	add.w d1,d1			2*R
	move.w d1,d0
	neg.w d0
	addq.w #3,d0			d0 => C:=3-2*R
	add.w d1,d1			d1 => X:=X*4
	moveq #0,d2			d2 => Y:=0
	move.w d1,d3			pour ne pas tracer 2 points sur 1 ligne
	mulu #(PLANE_WIDTH/8)*2,d7	d7 => Delta Y coté YX
	sub.w a5,a5			a5 => Delta Y coté XY

	move.w a1,d4			regarde s'il y a une intersection
	add.w d1,d4			avec la droite des XX' et des YY'
	cmp.w #PLANE_WIDTH*4,d4
	blt.s loop_compute_circle
	move.w a1,d4
	sub.w d1,d4
	cmp.w #PLANE_WIDTH*4,d4		regarde si l'intersection est
	bge.s loop_compute_circle	visible
	move.w a2,d4
	blt.s loop_compute_circle
	cmp.w #PLANE_HEIGHT*4,d4
	bge.s loop_compute_circle
	move.w 2(a4,d4.w),d4
	bset #0,(PLANE_WIDTH/8)-1(a0,d4.w)

loop_compute_circle
	put_pixel d1,d2,a5		pixel X,Y + symétries
symetrie_YX
	cmp.w d1,d3			c'est une autre ligne ?
	beq pas_YX
	put_pixel d2,d1,d7		pixel Y,X + symétries
pas_YX
	move.w d1,d3			sauvegarde le numéro de la ligne
	lea (PLANE_WIDTH/8)*2(a5),a5	Delta Y coté XY
	tst.w d0			C<0 ?
	blt C_inf_0

C_pas_inf_0
	sub.w d1,d0
	add.w d2,d0
	add.w #10,d0			C:=C-4*X+4*Y+10
	sub.w #(PLANE_WIDTH/8)*2,d7	Delta Y coté YX
	subq.w #4,d1			X:=X-1
	addq.w #4,d2			Y:=Y+1

	cmp.w d1,d2			while X>Y do
	blt loop_compute_circle
	put_pixel d2,d1,d7		pixel Y,X + symétries
	rts

C_inf_0
	add.w d2,d0
	addq.w #6,d0			C:=C+4*Y+6
	addq.w #4,d2			Y:=Y+1

	cmp.w d1,d2			while X>Y do
	blt loop_compute_circle
	put_pixel d2,d1,d7		pixel Y,X + symétries
	rts

tabX
mult set 0
	rept PLANE_WIDTH
	dc.l ($f-mult&$f)<<16+mult/8
mult set mult+1
	endr

tabY
mult set 0
	rept PLANE_HEIGHT
	dc.l mult*(PLANE_WIDTH/8)
mult set mult+1
	endr

	section gfx,data_c
coplist
	dc.w $180,0,$182,$fff
	dc.l $fffffffe

screen1	dcb.b 10240,0
screen2	dcb.b 10240,0


