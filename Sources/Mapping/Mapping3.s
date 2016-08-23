
*			mapping
*			-------
*
*		(c) 1995 SYnc/DramDealers
*






	incdir "asm:Sources/"
	incdir "asm:.s/Mapping/"
	

	include "registers.i"
	include "mapping.i"

	OPT DEBUG
	OPT HCLN



Entry_Point
	KILL_SYSTEM Main
	moveq #0,d0
	rts



Main
	lea _DataBase,a5

	lea Dragon_Face,a0
	bsr Draw_Mapped_Face

	rts



*   --> A0=Pointeur sur une face
Draw_Mapped_Face
	addq.l #4,a0

	move.l (a0)+,d7			nombre de lignes dans le contour
	subq.l #1,d7

	lea Left_Buffer(pc),a1
	move.l a1,a2
	lea Right_Buffer(pc),a3
	move.l a3,a4

	moveq #0,d3			point en cours
	moveq #0,d4			nb de lignes dans gauche
	moveq #0,d5			nb de lignes dans droit

	moveq #0,d6

	move.l (a0)+,d0
Loop
	move.l (a0)+,d1
	cmp.w d0,d1
	bgt Left
	blt Right
	dbf d7,Loop
	rts

Left
	addq.w #1,d4
	btst #0,d6			deja venu a gauche ?
	bne.s Left_a2
Left_a1
	move.l d1,-(a1)
	move.l d0,-(a1)
	move.l d3,-(a1)
	dbf d7,Loop
	rts

Left_a2
	move.l d3,(a2)+
	move.l d1,(a2)+
	move.l d0,(a2)+
	dbf d7,Loop





*****************************************************************************
********************************* DATAS *************************************
*****************************************************************************


	dcb.b 1024
Left_Buffer
	dcb.b 1024

	dcb.b 1024
Right_Buffer
	dcb.b 1024




	section mapping_datas,bss

	rsreset
DataBase_Struct	rs.w 0
Fill_Left_Start_Dot	rs.l 1
Fill_Right_Start_Dot	rs.l 1
DataBase_SizeOF		rs.w 0


_DataBase
	ds.b DataBase_SizeOF



	section mapping_constant_datas,data

	include "Dragon.Obj"
