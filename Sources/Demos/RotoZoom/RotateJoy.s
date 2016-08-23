
*			Zoom et Rotation d'une image / 68020 et +
*			~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*				(c)1993 Sync/DreamDealers



* EQU en vrac
* ~~~~~~~~~~~
PIC_X=896
PIC_Y=860
PIC_DEPTH=8
PIC_WIDTH=PIC_X/8
PIC_HEIGHT=PIC_Y

COP_MOVEX=48
COP_MOVEY=56
COP_LINE=5
COP_WAIT=COP_MOVEY*COP_LINE+COP_LINE/2
COP_WIDTH=4*(1+COP_MOVEX)
COP_SIZE=4*(COP_WAIT*(1+COP_MOVEX)+1)

	IFNE COP_MOVEX>COP_MOVEY
MAX_MOVE=COP_MOVEX
	ELSEIF
MAX_MOVE=COP_MOVEY
	ENDC

OFFSET_X1=$2b
OFFSET_X2=$2b+2
MAX_ANGLE=360
MAX_SPEED=100
MAX_ZOOM=$30
MIN_ZOOM=$2
MARGIN=140

* Les includes
* ~~~~~~~~~~~~
	incdir "asm:"
	incdir "asm:sources/"
	incdir "asm:.s/Rotate/"
	incdir "asm:.s/Rotate/MelonBomb/"
	incdir "ram:"
	include "registers.i"

* Options de compilation
* ~~~~~~~~~~~~~~~~~~~~~~
	OPT P=68030
	OPT O+
	OPT OW-

* Le programme principal en FAST
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	section rotation,code
Main
	KILL_SYSTEM do_Rotate
	moveq #0,d0
	rts

do_Rotate
	lea (data_base,pc),a5
	lea custom_base,a6

	bsr build_coplist
	bsr expand_picture
	jsr mt_init

	move.l #Rotate_VBL,$6c.w
	move.l phy_coplist(pc),cop1lc(a6)

	move.w #$8280,dmacon(a6)		COPPER
	move.w #$c020,intena(a6)		et pis la VBL!

	WAIT_LMB_DOWN				y va cliquer le Mr ???
	jsr mt_end
	RESTORE_SYSTEM


* La nouvelle VBL
* ~~~~~~~~~~~~~~~
Rotate_VBL
	SAVE_REGS
	jsr mt_music

	lea data_base(pc),a5
	lea custom_base,a6

	bsr Move_Rotate
	bsr build_Rotate
	bsr.s Rotate
	bsr.s Flip_Coplist

	VBL_SIZE color00,$000

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
	rts



* Rotation du bitmap et stockage dans la coplist
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Rotate
	move.l (log_coplist,pc),a0		pointe data du 1er COP_MOVE
	lea 4+2(a0),a0

	lea chunky_picture(pc),a1		cherche un ptr sur l'image
	move.w (CentreY,pc),d0
	lsr.w #1,d0
	bcs.s posy_ok
	lea (COP_LINE/2)*COP_WIDTH(a0),a0
posy_ok
	mulu #PIC_X*2,d0			table de WORD
	add.l d0,a1

	move.w CentreX(pc),d0			c'est là oû on regarde
	lsr.w #1,d0
	lea (a1,d0.w*2),a1			table de WORD

	lea Table_Rotate(pc),a2			la table de rotation
	lea COP_MOVEX*4(a2),a3			pointe les changements de Centre

	moveq #COP_MOVEY-1,d0			traite toute la coplist
rotate_all
	move.l a2,a4
	moveq #COP_MOVEX-1,d1			on se fait toute la ligne
rotate_line
	move.l (a4)+,d2				va chercher l'offset du point
	move.w (a1,d2.l),d2			va chercher sa couleur
depl set 0
	REPT COP_LINE
	move.w d2,depl(a0)			installe couleur dans la ligne
depl set depl+COP_WIDTH
	ENDR
	addq.l #4,a0
	dbf d1,rotate_line
	lea COP_WIDTH*(COP_LINE-1)+4(a0),a0	ligne suivante
	add.l (a3)+,a1				change la position du Centre
	dbf d0,rotate_all
	rts



* Gestion du déplacement du zoom rotaté
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Move_Rotate
	bsr gestion_joystick

	move.w Angle(pc),d0			projette la vitesse sur les
	move.w Speed(pc),d1			axe
	lea Table_Cosinus(pc),a0
	move.w (a0,d0.w*2),d2
	muls.w d1,d2
	swap d2					vitesse sur les X
	lea Table_Sinus(pc),a1
	move.w (a1,d0.w*2),d3
	muls.w d1,d3
	swap d3					vitesse sur les Y

	sub.w d3,CentreX-data_base(a5)
	sub.w d2,CentreY-data_base(a5)


	tst.w Angle-data_base(a5)
	bge.s .ok1
	add.w #MAX_ANGLE,Angle-data_base(a5)
	bra.s .ok2
.ok1	cmp.w #MAX_ANGLE,Angle-data_base(a5)
	blt.s .ok2
	sub.w #MAX_ANGLE,Angle-data_base(a5)
.ok2
	cmp.w #MARGIN,CentreX-data_base(a5)
	bge.s .ok3
	move.w #MARGIN,CentreX-data_base(a5)
	bra.s .ok4
.ok3	cmp.w #PIC_X*2-MARGIN,CentreX-data_base(a5)
	ble.s .ok4
	move.w #PIC_X*2-MARGIN,CentreX-data_base(a5)
.ok4
	cmp.w #MARGIN,CentreY-data_base(a5)
	bge.s .ok5
	move.w #MARGIN,CentreY-data_base(a5)
	bra.s .ok6
.ok5	cmp.w #PIC_Y*2-MARGIN,CentreY-data_base(a5)
	ble.s .ok6
	move.w #PIC_Y*2-MARGIN,CentreY-data_base(a5)
.ok6
	rts

* Gestion du joystick
* ~~~~~~~~~~~~~~~~~~~
gestion_joystick
	btst #7,ciaapra
	bne.s .no_up
	cmp.w #MAX_ZOOM,Zoom-data_base(a5)
	beq.s .no_down
	addq.w #1,Zoom-data_base(a5)
	bra.s .no_down
.no_up
	btst #6,potinp(a6)
	bne.s .no_down
	cmp.w #MIN_ZOOM,Zoom-data_base(a5)
	beq.s .no_down
	subq.w #1,Zoom-data_base(a5)
.no_down
	move.w joy1dat(a6),d0
	ror.b #2,d0
	lsr.w #4,d0
	and.w #%111100,d0
	jmp JoyRout(pc,d0.w)
JoyRout
	bra.w move_none
	bra.w move_down
	bra.w move_down_right
	bra.w move_right
	bra.w move_up
	bra.w move_none
	bra.w move_none
	bra.w move_up_right
	bra.w move_up_left
	bra.w move_none
	bra.w move_none
	bra.w move_none
	bra.w move_left
	bra.w move_down_left
	bra.w move_none
	bra.w move_none

move_none
	rts
move_down
	clr.w Speed-data_base(a5)
	rts
move_up
	cmp.w #MAX_SPEED,Speed-data_base(a5)
	beq.s move_none
	addq.w #1,Speed-data_base(a5)
	rts
move_left
	addq.w #1,Angle-data_base(a5)
	rts
move_right
	subq.w #1,Angle-data_base(a5)
	rts
move_down_left
	bsr move_down
	bra move_left
move_down_right
	bsr move_down
	bra move_right
move_up_left
	bsr move_up
	bra move_left
move_up_right
	bsr move_up
	bra move_right



* Transformation de l'image : chaque pixel devient un mot donnant sa couleur
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
expand_picture
	lea end_picture-1,a0			pointe l'image
	lea end_chunky_picture,a1		pointe le bitmap
	lea picture_colors,a2			pointe les couleurs
	move.w #PIC_Y-1,d0			répète pour toutes les lignes
expand_all
	move.w #PIC_X-1,d1			répète pour la ligne
	moveq #0,d2				# du bit à tester
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
build_coplist
	lea coplist1,a0
	move.l a0,log_coplist-data_base(a5)
	move.l a0,a1
	move.w #COP_WAIT-1,d0
	move.l #($1f00fffe)|(OFFSET_X1<<16),d1	1er wait
	move.l #color00<<16,d2			MOVE.W #$000,color00
build_all
	move.l d1,(a1)+				place le wait
	moveq #COP_MOVEX-1,d3
build_line
	move.l d2,(a1)+				met des 'COP_MOVE $000,color00'
	dbf d3,build_line
	add.l #$100<<16,d1			wait suivant
	dbf d0,build_all
	move.l #$fffffffe,(a1)+			fin coplist1

	move.w #COP_SIZE/4-1,d0			duplique la coplist
dup_coplist
	move.l (a0)+,(a1)+
	dbf d0,dup_coplist
	move.l a0,phy_coplist-data_base(a5)
	rts



* Fabrication de la table de rotation ( transcription directe de l'AMOS...)
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
build_Rotate
	move.w #(-COP_MOVEY/2),d0		B=(-COP_MOVEY/2)*Zoom
	muls.w Zoom(pc),d0

	move.w #(-COP_MOVEX/2),d1		A=(-COP_MOVEX/2)*Zoom
	muls.w Zoom(pc),d1

	moveq #MAX_MOVE-1,d2			M

	move.w Angle(pc),d7			ANGLE
	lea Table_Cosinus(pc),a1
	move.w (a1,d7.w*2),d3			Cos(ANGLE)
	lea Table_Sinus(pc),a1
	move.w (a1,d7.w*2),d4			Sin(ANGLE)

	lea Table_Rotate(pc),a2
	lea COP_MOVEX*4(a2),a3

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

	move.w d6,d7
	muls.w #PIC_X,d7			Y*PIC_X
	ext.l d5
	add.l d5,d7				X+Y*PIC_X
	add.l d7,d7				(X+Y*PIC_X)*2

	cmp.w #MAX_MOVE-1-COP_MOVEX,d2		0<=M<=COP_MOVEX-1 version dbf
	ble.s .no_more
	move.l d7,(a2)+

.no_more
	cmp.w #MAX_MOVE-1,d2			1<M<=COP_MOVEY version dbf
	beq.s no_change_center
	cmp.w #MAX_MOVE-1-COP_MOVEY,d2
	blt.s no_change_center

	sub.w a0,d5				DX=X-OLD_X
	add.w d5,a0				OLD_X=X
	sub.w a1,d6				DY=Y-OLD_Y
	add.w d6,a1				OLD_Y=Y

	muls.w #PIC_X,d5			DX*PIC_X
	ext.l d6
	sub.l d6,d5				-DY+DX*PIC_X
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



* Toutes les datas de Rotate
* ~~~~~~~~~~~~~~~~~~~~~~~~~~
	CNOP 0,4
data_base

Table_Rotate	ds.l COP_MOVEX
Table_Centre	ds.l COP_MOVEY-1

log_coplist	dc.l 0
phy_coplist	dc.l 0
CentreX		dc.w PIC_X
CentreY		dc.w PIC_Y-30*2
Angle		dc.w 0
Speed		dc.w 0
Zoom		dc.w MAX_ZOOM

picture_colors	incbin "RotatePic2.PAL"

Table_Sinus	incbin "Table_Cosinus.DAT"
Table_Cosinus=Table_Sinus+90*2

picture		incbin "RotatePic2.RAW"		=> PIC_WIDTH*PIC_HEIGHT*PIC_DEPTH
end_picture	ds.b PIC_X*PIC_Y*2-PIC_WIDTH*(PIC_HEIGHT-1)*PIC_DEPTH
end_chunky_picture
chunky_picture=picture+PIC_WIDTH*PIC_DEPTH



* La replay et sa zik
* ~~~~~~~~~~~~~~~~~~~
	include "TMC_Replay.s"
	include "Song.s"



* Les samples de la zik en CHIP
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	section felation,data_c
	include "Samples.s"



* Met les coplists en CHIP
* ~~~~~~~~~~~~~~~~~~~~~~~~
	section habin,bss_c
coplist1	ds.b COP_SIZE
coplist2	ds.b COP_SIZE
