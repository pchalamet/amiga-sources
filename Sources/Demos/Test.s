	
*			Fractale triangle
*			~~~~~~~~~~~~~~~~~
*			(c)1995 Sync/DreamDealers




	incdir "asm:sources/"
	include "registers.i"
	SET_OPTS
	OPT DEBUG,HCLN

SCREEN_X=640
SCREEN_Y=512
SCREEN_DEPTH=1
FILL=0

	KILL_SYSTEM do_triangle
	moveq #0,d0
	rts


do_triangle
	lea _DataBase,a5
	lea _CustomBase,a6

	move.l sp,Save_SP(a5)
	lea New_SP,sp

	bsr.s Init_Screen
	bsr Hardware_Init

	IFNE 1
	move.w #SCREEN_X-1,d0		\ (x1,y1)
	moveq #0,d1			/
	move.w #SCREEN_X/3,d2		\ (x2,y2)
	move.w #SCREEN_Y/2,d3		/
	move.w #SCREEN_X-1,d4		\ (x3,y3)
	move.w #SCREEN_Y-1,d5		/
	moveq #6,d6			niveau de récursion
	ELSE
	move.w #SCREEN_X/2,d0		\ (x1,y1)
	moveq #0,d1			/
	moveq #0,d2			\ (x2,y2)
	move.w #SCREEN_Y-1,d3		/
	move.w #SCREEN_X-1,d4		\ (x3,y3)
	move.w #SCREEN_Y-1,d5		/
	moveq #7,d6			niveau de récursion
	ENDC
	bsr Triangle

	IFNE FILL
	bsr.s Fill_Screen
	ENDC

	WAIT_LMB_DOWN

	move.l Save_SP(a5),sp

	move.w #$7fff,d0
	move.w d0,intena(a6)
	move.w d0,dmacon(a6)
	RESTORE_SYSTEM


* Remplissage de l'écran
* ~~~~~~~~~~~~~~~~~~~~~~
Fill_Screen
	move.l Screen(a5),a0
	add.l #(SCREEN_X/8)*SCREEN_Y*SCREEN_DEPTH-2,a0
	move.l a0,bltapt(a6)
	move.l a0,bltdpt(a6)
	clr.l bltamod(a6)
	move.l #$09f00012,bltcon0(a6)
	move.l #(SCREEN_Y<<16)|(SCREEN_X/16),bltsizV(a6)
	rts




* init les bitplans dans les coplists
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Init_Screen
	move.l #Screen1,d0
	move.l d0,Screen(a5)
	lea Cop1_Bpl,a0
	lea Cop2_Bpl,a1
	moveq #SCREEN_DEPTH-1,d1
.put
	move.w d0,4(a0)			lignes paires
	swap d0
	move.w d0,(a0)
	swap d0
	add.l #(SCREEN_X/8),d0
	addq.l #8,a0

	move.w d0,4(a1)			lignes impaires
	swap d0
	move.w d0,(a1)
	swap d0
	add.l #(SCREEN_X/8),d0
	addq.l #8,a1

	dbf d1,.put
	rts	


Hardware_Init
	move.l #Cop1,cop1lc(a6)
	move.l #Cop2,cop2lc(a6)

	move.l #Triangle_VBL,$6c.w
	move.w #$87c0,dmacon(a6)
	move.w #$c020,intena(a6)
	rts


Triangle_VBL
	SAVE_REGS

	lea _DataBase,a5
	lea _CustomBase,a6

	move.w vposr(a6),d0
	bmi.s .lof
	clr.w copjmp2(a6)		lignes impaires
	bra.s .shf
.lof	clr.w copjmp1(a6)		lignes paires
.shf

	move.w #$0020,intreq(a6)
	RESTORE_REGS
	rte
	


Triangle
	bsr DrawLine_Init
	moveq #%111,d7


X1 EQUR d0
Y1 EQUR d1
X2 EQUR d2
Y2 EQUR d3
X3 EQUR d4
Y3 EQUR d5
REC EQUR d6
MASK EQUR d7
Rec_Triangle
	tst.w REC
	ble End_Rec_Triangle

	movem.w d0-d6,-(sp)
* Etat de la pile
* ~~~~~~~~~~~~~~~
	CARGS #0,x1.w,y1.w,x2.w,y2.w,x3.w,y3.w,rec.w

	btst #0,MASK
	beq.s .no_cote1
	move.l Screen(a5),a0
	bsr DrawLine
.no_cote1
	btst #1,MASK
	beq.s .no_cote2
	movem.w x2(sp),d0-d1/d2-d3
	move.l Screen(a5),a0
	bsr DrawLine
.no_cote2
	btst #2,MASK
	beq.s .no_cote3
	movem.w x1(sp),d0-d1
	movem.w x3(sp),d2-d3
	move.l Screen(a5),a0
	bsr DrawLine
.no_cote3
	

; REC_TRIANGLE[X1,Y1,(X1+X2)/2,(Y1+Y2)/2,(X1+X3)/2,(Y1+Y3)/2,REC-1,%10]
	movem.w x1(sp),X1-Y3
	add.w X1,X2
	asr.w #1,X2
	add.w Y1,Y2
	asr.w #1,Y2
	add.w X1,X3
	asr.w #1,X3
	add.w Y1,Y3
	asr.w #1,Y3
	subq.w #1,REC
	moveq #%10,MASK
	bsr.s Rec_Triangle

; REC_TRIANGLE[(X1+X2)/2,(Y1+Y2)/2,X2,Y2,(X2+X3)/2,(Y2+Y3)/2,REC-1,%100]
	movem.w x1(sp),X1-REC
	add.w X2,X1
	asr.w #1,X1
	add.w Y2,Y1
	asr.w #1,Y1
	add.w X2,X3
	asr.w #1,X3
	add.w Y2,Y3
	asr.w #1,Y3
	subq.w #1,REC
	moveq #%100,MASK
	bsr.s Rec_Triangle

; REC_TRIANGLE[(X1+X3)/2,(Y1+Y3)/2,(X2+X3)/2,(Y2+Y3)/2,X3,Y3,REC-1,%1]
	movem.w x1(sp),X1-REC
	add.w X3,X1
	asr.w #1,X1
	add.w Y3,Y1
	asr.w #1,Y1
	add.w X3,X2
	asr.w #1,X2
	add.w Y3,Y2
	asr.w #1,Y2
	subq.w #1,REC
	moveq #%1,MASK
	bsr Rec_Triangle

; REC_TRIANGLE[(2*X1+X2+X3)/4,(2*Y1+Y2+Y3)/4,(2*X2+X1+X3)/4,(2*Y2+Y1+Y3)/4,(2*X3+X1+X2)/4,(2*Y3+Y1+Y2)/4,REC-1,%0]
	move.w x1(sp),X1
	add.w X1,X1
	add.w x2(sp),X1
	add.w x3(sp),X1
	asr.w #2,X1

	move.w y1(sp),Y1
	add.w Y1,Y1
	add.w y2(sp),Y1
	add.w y3(sp),Y1
	asr.w #2,Y1

	move.w x2(sp),X2
	add.w X2,X2
	add.w x1(sp),X2
	add.w x3(sp),X2
	asr.w #2,X2

	move.w y2(sp),Y2
	add.w Y2,Y2
	add.w y1(sp),Y2
	add.w y3(sp),Y2
	asr.w #2,Y2

	move.w x3(sp),X3
	add.w X3,X3
	add.w x1(sp),X3
	add.w x2(sp),X3
	asr.w #2,X3

	move.w y3(sp),Y3
	add.w Y3,Y3
	add.w y1(sp),Y3
	add.w y2(sp),Y3
	asr.w #2,Y3

	move.w rec(sp),REC
	subq.w #1,REC
	moveq #0,MASK
	bsr Rec_Triangle

	lea 7*2(sp),sp
End_Rec_Triangle
	rts





Width=SCREEN_X/8			taille en octets
Heigth=SCREEN_Y				hauteur en pixels
Depth=SCREEN_DEPTH			profondeur en bpl
	IFNE FILL
MINTERM=$4a				minterm de la droite
DOING_3D=1				on fait de la 3D ou non
ONEDOT=1				1 point par ligne ou plusieurs
	ELSE
MINTERM=$ca
DOING_3D=0
ONEDOT=0
	ENDC
WAIT_BLIT=1				on attend le blitter ou non


			*************************************
			*    routine de tracé de droites    *
			* le clipping doit être fait avant  *
			*   de rentrer dans cette routine   *
			*				    *
			* en entrée :			    *
			*	       d0.w=X1		    *
			*	       d1.w=Y1		    *
			*	       d2.w=X2		    *
			*	       d3.w=Y2		    *
			*	       a0.l=adr bitplan	    *
			*	       a6.l=$dff000	    *
			*				    *
			* en sortie :			    *
			*	       d0-d5/a0 modifiés    *
			*************************************
DrawLine
	cmp.w d1,d3
	bge.s .Y_OK

	exg d0,d2
	exg d1,d3
.Y_OK
	sub.w d0,d2				d2=deltaX
	sub.w d1,d3				d3=deltaY
	IFNE DOING_3D
	subq.w #1,d3
	ble .no_line
	ENDC

	moveq #0,d4
	ror.w #4,d0				\
	move.b d0,d4				 > d0=décalage
	and.w #$f000,d0				/

	add.w d4,d4				d4=adr en octets sur X
	add.w d1,d1				d1=d1*2 car table de mots
	add.w Table_Mulu_Line(pc,d1.w),d4	d4=d1*Width+d4
	lea 0(a0,d4.l),a0			recherche 1er mot de la droite
	move.w d0,d4				sauvegarde du décalage
	or.w #$0b<<8|MINTERM,d4			source + masque
.find_octant	
	moveq #0,d1				on recherche l'octant
	tst.w d3				test de deltaY
	bpl.s .Y1_inf_Y2
	neg.w d3
	moveq #4,d1
.Y1_inf_Y2
	moveq #0,d5
	tst.w d2
	bpl.s .X1_inf_X2
	neg.w d2
	moveq #4,d5
.X1_inf_X2
	cmp.w d2,d3
	bpl.s .DY_sup_DX
	add.b d1,d1
	or.b #16,d5
	bra.s .octant_found
.DY_sup_DX
	exg d3,d2
	add.w d5,d5
.octant_found
	or.w d1,d5

	IFEQ ONEDOT
	addq.b #1,d5				commute en mode LINE
	ELSEIF
	addq.b #3,d5				ou LINE + ONEDOT
	ENDC

	or.w d0,d5				rajoute l'octant
	
	add.w d3,d3				4*Pdelta
	add.w d3,d3
	add.w d2,d2				2*Gdelta

.DrawLine_Wait
	IFNE WAIT_BLIT
	btst #6,dmaconr(a6)
	bne.s .DrawLine_Wait
	ENDC

	move.w d3,bltbmod(a6)
	sub.w d2,d3				4*Pdelta-2*Gdelta
	bge.s .no_SIGNFLAG
	or.w #$40,d5
.no_SIGNFLAG
	move.w d5,bltcon1(a6)
	move.w d3,bltapt+2(a6)
	sub.w d2,d3				4*Pdelta-4*Gdelta
	move.w d3,bltamod(a6)

	move.w d4,bltcon0(a6)

	move.l a0,bltcpt(a6)			\ pointeur sur 1er mot droite
	move.l a0,bltdpt(a6)			/

	addq.w #1<<1,d2				2*Gdelta+1<<1
	lsl.w #5,d2				(Gdelta+1)<<6
	addq.b #2,d2				(Gdelta+1)<<6+2
	move.w d2,bltsize(a6)			traçage de la droite
.no_line
	rts

Table_Mulu_Line
MuluCount set 0
	rept Heigth
	dc.w MuluCount*Width*Depth
MuluCount set MuluCount+1
	endr

			****************************
			* routine d'initialisation *
			* du blitter pour le tracé *
			* de droites		   *
			*			   *
			* en entrée :		   *
			*	       a6=$dff000  *
			*			   *
			****************************						
DrawLine_Init
	IFNE WAIT_BLIT
	btst #6,dmaconr(a6)
	bne.s DrawLine_Init
	ENDC

	move.w #Width*Depth,bltcmod(a6)		\ largeur de l'image
	move.w #Width*Depth,bltdmod(a6)		/
	move.w #-1,bltbdat(a6)			masque de la droite
	move.l #-1,bltafwm(a6)			masque sur A
	move.w #$8000,bltadat(a6)		Style du point
	rts	






	section dat,bss

	rsreset
DataBase_Struct		rs.b 0
Screen			rs.l 1
Save_SP			rs.l 1
DataBase_SizeOF		rs.b 0

_DataBase
	ds.b DataBase_SizeOF

	ds.b 4*1024
New_SP


	section cop,data_c
Cop1
	dc.w fmode,%11
	dc.w bplcon0,$8204|(SCREEN_DEPTH<<12)
	dc.w bplcon1,$0
	dc.w bplcon2,$0
	dc.w bplcon4,$0
	dc.w ddfstrt,$38
	dc.w ddfstop,$c8
	dc.w diwstrt,$2b81
	dc.w diwstop,$2bc1
	dc.w bpl1mod,SCREEN_X/8
	dc.w bpl1mod,SCREEN_X/8

Cop1_Colors
	dc.w bplcon3,$0000
	dc.w color00,$155
	dc.w color01,$888
	dc.w bplcon3,$0200
	dc.w color00,$000
	dc.w color01,$000

Cop1_Bpl=*+2
bpl set bpl1ptH
	REPT SCREEN_DEPTH
	dc.w bpl,0
	dc.w bpl+2,0
bpl set bpl+4
	ENDR

	dc.l $fffffffe


Cop2
	dc.w fmode,%11
	dc.w bplcon0,$8204|(SCREEN_DEPTH<<12)
	dc.w bplcon1,$0
	dc.w bplcon2,$0
	dc.w bplcon4,$0
	dc.w ddfstrt,$38
	dc.w ddfstop,$c8
	dc.w diwstrt,$2b81
	dc.w diwstop,$2bc1
	dc.w bpl1mod,SCREEN_X/8
	dc.w bpl1mod,SCREEN_X/8

Cop2_Colors
	dc.w bplcon3,$0000
	dc.w color00,$155
	dc.w color01,$888
	dc.w bplcon3,$0200
	dc.w color00,$000
	dc.w color01,$000

Cop2_Bpl=*+2
bpl set bpl1ptH
	REPT SCREEN_DEPTH
	dc.w bpl,0
	dc.w bpl+2,0
bpl set bpl+4
	ENDR

	dc.l $fffffffe


	section scr,bss_c

Screen1
	ds.b (SCREEN_X/8)*SCREEN_Y*SCREEN_DEPTH
