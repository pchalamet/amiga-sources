
*			Zoom et Rotation d'une image / 68020 et +
*			~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*				(c)1993 Sync/DreamDealers



* Options de compilation
* ~~~~~~~~~~~~~~~~~~~~~~
	OPT P=68020
	OPT O+,OW-,C+
	OPT NODEBUG,NOLINE

* EQU en vrac
* ~~~~~~~~~~~
PIC_X=320
PIC_Y=256
PIC_DEPTH=7
PIC_WIDTH=PIC_X/8
PIC_HEIGHT=PIC_Y

COP_MOVEX=48
COP_MOVEY1=24
COP_MOVEY2=31
COP_MOVEY3=13
COP_MOVEY=COP_MOVEY1+1+COP_MOVEY2+1+COP_MOVEY3
COP_LINE=4
COP_WIDTH=1+1+1+COP_MOVEX+1+1
COP_SIZE=4*(1+1+1+COP_WIDTH*(COP_MOVEY-2)+(1+COP_MOVEX)*COP_LINE*2+1+1)

	IFNE COP_MOVEX>COP_MOVEY
MAX_MOVE=COP_MOVEX
	ELSEIF
MAX_MOVE=COP_MOVEY
	ENDC

PIC_MARGIN=120
MAX_ANGLE=720
MARGIN_X=100
MARGIN_Y=100
INC_ZOOM1=2
INC_ZOOM2=5
ANGLE_COUNTER=500


* Les includes
* ~~~~~~~~~~~~
	incdir "asm:"
	incdir "asm:sources/"
	incdir "asm:.s/demos/RotoZoom/"
	incdir "asm:songs/small"
	include "registers.i"

* Options de compilation
* ~~~~~~~~~~~~~~~~~~~~~~
	OPT P=68020
	OPT O+,OW-
	OPT NODEBUG,NOLINE

* Le programme principal en FAST
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	section rotation,code_c
	KILL_SYSTEM do_Rotate
	moveq #0,d0
	rts

do_Rotate
	lea (data_base,pc),a5
	lea custom_base,a6

	moveq #0,d0
	movec d0,vbr
	move.l #$2001,d0
	movec d0,cacr

	bsr Build_Coplists
	jsr mt_init

	move.l #Rotate_VBL,$6c.w
	move.l phy_coplist(pc),cop1lc(a6)

	move.w #$8280,dmacon(a6)		COPPER
	move.w #$c020,intena(a6)		et pis la VBL!

	bsr Expand_Picture

	WAIT_LMB_DOWN				y va cliquer le Mr ???
	jsr mt_end

	RESTORE_SYSTEM


* La nouvelle VBL
* ~~~~~~~~~~~~~~~
Rotate_VBL
	SAVE_REGS
	jsr mt_music				hop! la zizik!!

	lea data_base(pc),a5
	lea custom_base,a6

	bsr.s Flip_Coplist			echange les coplists
	bsr.s Move_Rotate			deplacement du zoom-rotatif
	bsr Build_Rotate			calcule d'une ligne de zoom
	bsr Rotate				construit le zoom

	VBL_SIZE color00,$fff

	move.w #$0020,intreq(a6)		vire la request
	RESTORE_REGS
	rte

* Echange des coplists
* ~~~~~~~~~~~~~~~~~~~~
Flip_Coplist
	move.l log_coplist(pc),d0
	move.l phy_coplist(pc),log_coplist-data_base(a5)
	move.l d0,phy_coplist-data_base(a5)
	move.l d0,cop1lc(a6)
	clr.w copjmp1(a6)
	rts



* Gestion du déplacement du zoom rotaté
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Move_Rotate
	move.w Inc_Angle(pc),d0
	add.w d0,Angle-data_base(a5)
	bge.s .ang
	add.w #MAX_ANGLE,Angle-data_base(a5)
	bra.s .zozo
.ang
	cmp.w #MAX_ANGLE,Angle-data_base(a5)
	blt.s .zozo
	sub.w #MAX_ANGLE,Angle-data_base(a5)
.zozo
	movem.w CentreX(pc),d0/d1
	add.w Inc_X(pc),d0
	add.w Inc_Y(pc),d1

	cmp.w #MARGIN_X,d0
	bgt.s .ok1
	neg.w Inc_X-data_base(a5)
	bra.s .ok2
.ok1
	cmp.w #PIC_X*2-MARGIN_X,d0
	blt.s .ok2
	neg.w Inc_X-data_base(a5)
.ok2
	cmp.w #MARGIN_Y,d1
	bgt.s .ok3
	neg.w Inc_Y-data_base(a5)
	bra.s .ok4
.ok3
	cmp.w #PIC_Y*2-MARGIN_Y,d1
	blt.s .ok4
	neg.w Inc_Y-data_base(a5)
.ok4
	movem.w d0/d1,CentreX-data_base(a5)

	subq.w #1,Angle_Counter-data_base(a5)
	bne.s .ok_boy
	neg.w Inc_Angle-data_base(a5)
	subq.w #2,Inc_Angle-data_base(a5)		9 -> 7  ou  -7 -> -9
	move.w #ANGLE_COUNTER,Angle_Counter-data_base(a5)
.ok_boy
	move.w Offset_Zoom1(pc),d0
	addq.w #INC_ZOOM1,d0
	cmp.w #MAX_ANGLE,d0
	blt.s .ok5
	sub.w #MAX_ANGLE,d0
.ok5	move.w d0,Offset_Zoom1-data_base(a5)

	move.w Offset_Zoom2(pc),d1
	addq.w #INC_ZOOM2,d1
	cmp.w #MAX_ANGLE,d1
	blt.s .ok6
	sub.w #MAX_ANGLE,d1
.ok6	move.w d1,Offset_Zoom2-data_base(a5)

	lea Table_Cosinus(pc),a0
	move.w (a0,d0.w*2),d0
	muls.w #$18*$10,d0
	move.w (a0,d1.w*2),d1
	muls.w #$14*$10,d1
	add.l d1,d0
	swap d0
	asr.w #1,d0
	add.w #$18,d0
	move.w d0,Zoom-data_base(a5)
	rts



* Fabrication de la table de rotation ( transcription directe de l'AMOS...)
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Build_Rotate
	move.w #(-COP_MOVEY/4),d0		B=(-COP_MOVEY/2)*Zoom
	muls.w Zoom(pc),d0

	moveq #0,d1
	move.w #(-COP_MOVEX/4),d1		A=(-COP_MOVEX/2)*Zoom
	muls.w Zoom(pc),d1

	moveq #MAX_MOVE-1,d2			M

	move.w Angle(pc),d7			ANGLE
	lea Table_Cosinus(pc),a1
	move.w (a1,d7.w*2),d3			Cos(ANGLE)
	lea Table_Sinus(pc),a1
	move.w (a1,d7.w*2),d4			Sin(ANGLE)

	lea 0.w,a0
	lea 0.w,a1
	lea Table_Rotate(pc),a2
	lea COP_MOVEX*4(a2),a3			pointe les chgts de centre

for_M
	move.w d1,d5
	muls.w d3,d5				A*Cos(ANGLE)
	move.w d0,d6
	muls.w d4,d6				B*Sin(ANGLE)
	add.l d6,d5
	swap d5					X=A*Cos(ANGLE)+B*Sin(ANGLE)

	move.w d0,d6
	muls.w d3,d6				B*Cos(ANGLE)
	move.w d1,d7
	muls.w d4,d7				A*Sin(ANGLE)
	sub.l d7,d6
	swap d6					Y=B*Cos(ANGLE)-A*Sin(ANGLE)

	cmp.w #MAX_MOVE-1-COP_MOVEX,d2		0<=M<=COP_MOVEX-1 version dbf
	ble.s .no_more

	ext.l d5
	move.w d6,d7
	muls.w #(PIC_X+PIC_MARGIN),d7		Y*PIC_X
	add.l d5,d7
	add.l d7,d7				(X+Y*PIC_X)*2
	move.l d7,(a2)+

.no_more
	cmp.w #MAX_MOVE-1,d2			1<M<=COP_MOVEY version dbf
	beq.s no_change_center
	cmp.w #MAX_MOVE-1-COP_MOVEY,d2
	ble.s no_change_center

	sub.w a0,d5				DX=X-OLD_X
	add.w d5,a0				OLD_X=X
	sub.w a1,d6				DY=Y-OLD_Y
	add.w d6,a1				OLD_Y=Y

	muls.w #(PIC_X+PIC_MARGIN),d5		DX*PIC_X
	ext.l d6
	sub.l d6,d5				-DY+DX*PIC_X
	sub.l d6,d6
	add.l d5,d5				(-DY+DX*PIC_X)*2
	move.l d5,(a3)+

.next_M
	add.w Zoom(pc),d1			Inc A
	dbf d2,for_M
	rts

no_change_center
	move.w d5,a0				UPDATE OLD_X & OLD_Y
	move.w d6,a1
.next_M
	add.w Zoom(pc),d1			Inc A
	dbf d2,for_M
	rts



* Rotation du bitmap et stockage dans la coplist
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Rotate
	move.l (log_coplist,pc),a0		pointe data du 1er COP_MOVE
	lea 6*4+2(a0),a0

	lea bitmap,a1				cherche un ptr sur l'image
	move.w (CentreY,pc),d0
	lsr.w #1,d0
	mulu #(PIC_X+PIC_MARGIN)*2,d0		table de WORD
	add.l d0,a1

	move.w CentreX(pc),d0			c'est là oû on regarde
	lsr.w #1,d0
	lea (a1,d0.w*2),a1			table de WORD

	lea Table_Rotate(pc),a2			la table de rotation
	lea COP_MOVEX*4(a2),a3			pointe les changements de Centre

*********************************************************************************
	moveq #COP_MOVEY1-1,d0			traite la première partie
rotate1
	move.l a2,a4
	moveq #COP_MOVEX-1,d1			on se fait toute la ligne
rotate_line1
	move.l (a4)+,d2				va chercher l'offset du point
	move.w (a1,d2.l),(a0)
	addq.l #4,a0
	dbf d1,rotate_line1
	lea (COP_WIDTH-COP_MOVEX)*4(a0),a0	ligne suivante
	add.l (a3)+,a1				change la position du Centre
	dbf d0,rotate1

*********************************************************************************
	subq.l #8,a0				c pas une ligne normale...
	move.l a2,a4
	moveq #COP_MOVEX-1,d1
rotate_fake1
	move.l (a4)+,d2
	move.w (a1,d2.l),d2
depl set 0
	REPT COP_LINE
	move.w d2,depl(a0)
depl set depl+(1+COP_MOVEX)*4
	ENDR
	addq.l #4,a0
	dbf d1,rotate_fake1
	lea (1+COP_MOVEX)*(COP_LINE-1)*4+3*4(a0),a0
	add.l (a3)+,a1				change la position du Centre

*********************************************************************************
	moveq #COP_MOVEY2-1,d0			traite la deuxième partie
rotate2
	move.l a2,a4
	moveq #COP_MOVEX-1,d1			on se fait toute la ligne
rotate_line2
	move.l (a4)+,d2				va chercher l'offset du point
	move.w (a1,d2.l),(a0)
	addq.l #4,a0
	dbf d1,rotate_line2
	lea (COP_WIDTH-COP_MOVEX)*4(a0),a0	ligne suivante
	add.l (a3)+,a1				change la position du Centre
	dbf d0,rotate2

*********************************************************************************
	subq.l #8,a0				c pas une ligne normale...
	move.l a2,a4
	moveq #COP_MOVEX-1,d1
rotate_fake2
	move.l (a4)+,d2
	move.w (a1,d2.l),d2
depl set 0
	REPT COP_LINE
	move.w d2,depl(a0)
depl set depl+(1+COP_MOVEX)*4
	ENDR
	addq.l #4,a0
	dbf d1,rotate_fake2
	lea (1+COP_MOVEX)*(COP_LINE-1)*4+3*4(a0),a0
	add.l (a3)+,a1				change la position du Centre

*********************************************************************************
	moveq #COP_MOVEY3-1,d0			traite la deuxième partie
rotate3
	move.l a2,a4
	moveq #COP_MOVEX-1,d1			on se fait toute la ligne
rotate_line3
	move.l (a4)+,d2				va chercher l'offset du point
	move.w (a1,d2.l),(a0)
	addq.l #4,a0
	dbf d1,rotate_line3
	lea (COP_WIDTH-COP_MOVEX)*4(a0),a0	ligne suivante
	add.l (a3)+,a1				change la position du Centre
	dbf d0,rotate3
	rts



* Transformation de l'image : chaque pixel devient un mot donnant sa couleur
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Expand_Picture
	lea end_picture-1,a0			pointe l'image
	lea end_bitmap,a1			pointe le bitmap
	lea picture_colors,a2			pointe les couleurs
	move.w #PIC_Y-1,d0			répète pour toutes les lignes
expand_all
	move.w #PIC_X-1,d1			répète pour la ligne
	moveq #0,d2				# du bit à tester
	lea -(PIC_MARGIN*2)(a1),a1		la marge...
expand_line
	moveq #PIC_DEPTH-1,d3			répète pour chaque bpl
	moveq #0,d4				on stocke la couleur ici
	move.l a0,a3				err.. lit à partir d'ici
expand_bit
	btst d2,(a3)
	beq.s .clr
	addq.w #1,d4
.clr
	lea (-PIC_WIDTH,a3),a3
	add.w d4,d4
	dbf d3,expand_bit
	move.w (a2,d4.w),-(a1)			stocke sa couleur
	addq.w #1,d2				test le bit suivant
	and.w #$7,d2				reste dans la limite des 8
	beq.s end_byte				change de limite ?
	dbf d1,expand_line
	lea -PIC_WIDTH*(PIC_DEPTH-1)(a0),a0	saute les bpls entrelacés
	dbf d0,expand_all
	rts
end_byte
	subq.l #1,a0
	dbf d1,expand_line
	lea -PIC_WIDTH*(PIC_DEPTH-1)(a0),a0	saute les bpls entrelacés
	dbf d0,expand_all
	rts



* Fabrication des coplists
* ~~~~~~~~~~~~~~~~~~~~~~~~
Build_Coplists
	lea coplist1,a1
	move.l a1,log_coplist-data_base(a5)
	bsr.s build_one_coplist
	move.l a1,phy_coplist-data_base(a5)

build_one_coplist
	move.l #(fmode<<16)|$3,(a1)+		move.w #$3,fmode
	move.l #(color00<<16),(a1)+
	move.l #$1ee3fffe,(a1)+			wait sur la ligne kon veut...
	move.l a1,d1
	addq.l #2*4,d1				pour relancer la coplist
	move.l #$002b80fe,d7

*********************************************************************************
	moveq #COP_MOVEY1-1,d0
build_all1
	move.w #cop1lc,(a1)+			move.l #coplist_move,cop1lc
	swap d1
	move.w d1,(a1)+
	move.w #cop1lc+2,(a1)+
	swap d1
	move.w d1,(a1)+
	move.l d7,(a1)+				wait sur les X uniquement
	moveq #COP_MOVEX-1,d2
build_line1
	move.l #color00<<16,(a1)+		move.w #$xyz,color00
	dbf d2,build_line1
	move.l #$03018301,(a1)+			on skip toutes les 8 lignes
	move.l #copjmp1<<16,(a1)+		relance la coplist
	add.l #COP_WIDTH*4,d1			coplist suivante
	dbf d0,build_all1

*********************************************************************************
	moveq #COP_LINE-1,d5
	move.l #$7f2bfffe,d6			le wait
build_fake1
	move.l d6,(a1)+				place le wait
	moveq #COP_MOVEX-1,d0
build_fake_line1
	move.l #color00<<16,(a1)+		move.w #$xyz,color00
	dbf d0,build_fake_line1
	add.l #$100<<16,d6			wait suivant
	dbf d5,build_fake1

*********************************************************************************
	moveq #COP_MOVEY2-1,d0
	or.l #$80000000,d7
	move.l a1,d1
	addq.l #2*4,d1
build_all2
	move.w #cop1lc,(a1)+			move.l #coplist_move,cop1lc
	swap d1
	move.w d1,(a1)+
	move.w #cop1lc+2,(a1)+
	swap d1
	move.w d1,(a1)+
	move.l d7,(a1)+				wait sur les X uniquement
	moveq #COP_MOVEX-1,d2
build_line2
	move.l #color00<<16,(a1)+		move.w #$xyz,color00
	dbf d2,build_line2
	move.l #$83018301,(a1)+			on skip toutes les 8 lignes
	move.l #copjmp1<<16,(a1)+		relance la coplist
	add.l #COP_WIDTH*4,d1			coplist suivante
	dbf d0,build_all2

*********************************************************************************
	moveq #COP_LINE-1,d5
	move.l #$ff2bfffe,d6			le wait
build_fake2
	move.l d6,(a1)+				place le wait
	moveq #COP_MOVEX-1,d0
build_fake_line2
	move.l #color00<<16,(a1)+		move.w #$xyz,color00
	dbf d0,build_fake_line2
	add.l #$100<<16,d6			wait suivant
	dbf d5,build_fake2

*********************************************************************************
	moveq #COP_MOVEY3-1,d0
	and.l #$7fffffff,d7
	move.l a1,d1
	addq.l #2*4,d1
build_all3
	move.w #cop1lc,(a1)+			move.l #coplist_move,cop1lc
	swap d1
	move.w d1,(a1)+
	move.w #cop1lc+2,(a1)+
	swap d1
	move.w d1,(a1)+
	move.l d7,(a1)+				wait sur les X uniquement
	moveq #COP_MOVEX-1,d2
build_line3
	move.l #color00<<16,(a1)+		move.w #$xyz,color00
	dbf d2,build_line3
	move.l #$03018301,(a1)+			on skip toutes les 8 lignes
	move.l #copjmp1<<16,(a1)+		relance la coplist
	add.l #COP_WIDTH*4,d1			coplist suivante
	dbf d0,build_all3

*********************************************************************************
	move.l #(color00<<16),(a1)+		houba.. ya plus rien !
	move.l #$fffffffe,(a1)+
	rts



* Toutes les datas de Rotate
* ~~~~~~~~~~~~~~~~~~~~~~~~~~
	CNOP 0,4
data_base

Table_Rotate	ds.l COP_MOVEX
Table_Centre	ds.l COP_MOVEY-1

log_coplist	dc.l 0
phy_coplist	dc.l 0
CentreX		dc.w PIC_X
CentreY		dc.w PIC_Y
Angle		dc.w 0
Angle_Counter	dc.w ANGLE_COUNTER
Inc_X		dc.w 3
Inc_Y		dc.w 2
Inc_Angle	dc.w 7
Zoom		dc.w 0
Offset_Zoom1	dc.w 0
Offset_Zoom2	dc.w 0

picture_colors	incbin "MrDada.PAL"

Table_Cosinus	incbin "Table_Sinus.DAT"
Table_Sinus=Table_Cosinus+90*4

picture		incbin "MrDada.RAW"		=> PIC_WIDTH*PIC_HEIGHT*PIC_DEPTH
end_picture



* La replay et sa zik
* ~~~~~~~~~~~~~~~~~~~
	include "TMC_Replay.s"
	include "Song.s"


	section chunky,bss_c
	ds.w (PIC_X+PIC_MARGIN)*MARGIN_X
bitmap	ds.w (PIC_X+PIC_MARGIN)*PIC_Y
end_bitmap
	ds.w (PIC_X+PIC_MARGIN)*MARGIN_X

* Les samples de la zik en CHIP
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	section feelthebeat,data_c
	include "Samples.s"



* Met les coplists en CHIP
* ~~~~~~~~~~~~~~~~~~~~~~~~
	section habin,bss_c
coplist1	ds.b COP_SIZE
coplist2	ds.b COP_SIZE

