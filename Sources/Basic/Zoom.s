 


*			Labyrinthe en 3D avec des textures mappées
*			~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*				(c)1994 Sync/DreamDealers



*********************************************************************************
*                                   Les EQUs                                    *
*********************************************************************************
DATA_OFFSET=$7ffe

NB_COLONNES=106
NB_LIGNES=85

NB_ZOOM=NB_LIGNES+200
SRC_REG=0
DEST_REG=1
TEMP_REG=0


*********************************************************************************
*                        Construction de la table de ZOOM                       *
*   -->	a5=_DataBase                                                            *
*********************************************************************************
Build_Zoom_Table
	lea Table_Zoom_Offset(a5),a0
	lea Table_Zoom(a5),a1

	moveq #1,d0
.For_H
	move.w #NB_LIGNES,d1
	sub.w d0,d1
	asr.w #1,d1

	moveq #0,d2
	tst.w d1
	bge.s .ok_abs
	move.w d1,d2
	neg.w d2
.ok_abs
	mulu.w #TEXTURE_Y,d2
	divu d0,d2

	moveq #0,d3

	move.l a1,d4
	sub.l a0,d4
	subq.l #2,d4
	move.w #$60ff,(a0)+			bra.l ???
	move.l d4,(a0)+				bra.l patator
	addq.l #2,a0				multiple de 8 !!!

	moveq #0,d4
.For_A
	tst.w d1
	blt.s .out_of_screen
	cmp.w #NB_LIGNES,d1
	bge.s .out_of_screen

	move.w d2,d5
	move.w #TEXTURE_Y,d2
	mulu.w d4,d2
	divu d0,d2

	cmp.w d2,d5
	bne.s .not_equal
.equal
	addq.w #1,d3
	bra.s .out_of_screen
.not_equal
	bsr.s Generate_Code
	moveq #1,d3
.out_of_screen
	addq.w #1,d1
	addq.w #1,d4
	cmp.w d0,d4
	ble.s .For_A

	cmp.w d2,d5
	bne.s .no_more_generate
	move.w #NB_LIGNES-1,d1
	bsr.s Generate_Code
.no_more_generate
	move.w #$4e75,(a1)+
	addq.w #1,d0
	cmp.w #NB_ZOOM,d0
	ble.s .For_H
	rts

Generate_Code
	cmp.w #1,d3
	bne.s generate_several
generate_single
	move.w #$3000|SRC_REG|(DEST_REG<<9)|$28|$140,d6
	tst.w d5
	bne.s .no_opt1
	and.w #~$28,d6
	or.w #$10,d6
.no_opt1
	cmp.w #1+(NB_LIGNES/2),d1
	bne.s .no_opt2
	and.w #~$140,d6
	or.w #$80,d6
.no_opt2
	move.w d6,(a1)+

	tst.w d5
	beq.s .opt1
	move.w d5,d6
	mulu.w #TEXTURE_X*2,d6
	move.w d6,(a1)+
.opt1
	cmp.w #1+(NB_LIGNES/2),d1
	beq.s .opt2
	move.w d1,d6
	sub.w #1+(NB_LIGNES/2),d6
	muls.w #COP_SIZE_X,d6
	move.w d6,(a1)+
.opt2
	rts

generate_several
	move.w #$3000|SRC_REG|(TEMP_REG<<9)|$28,d6
	tst.w d5
	bne.s .no_opt1
	and.w #~$28,d6
	or.w #$10,d6
.no_opt1
	move.w d6,(a1)+

	tst.w d5
	beq.s .opt1
	move.w d5,d6
	mulu.w #TEXTURE_X*2,d6
	move.w d6,(a1)+
.opt1
	addq.w #1,d1
	sub.w d3,d1

	moveq #1,d7
.For_T
	move.w #$3000|TEMP_REG|(DEST_REG<<9)|$140,d6
	cmp.w #1+NB_LIGNES/2,d1
	bne.s .no_opt2
	and.w #~$140,d6
	or.w #$80,d6
.no_opt2
	move.w d6,(a1)+

	cmp.w #1+(NB_LIGNES/2),d1
	beq.s .opt2
	move.w d1,d6
	sub.w #1+(NB_LIGNES/2),d6
	muls.w #COP_SIZE_X,d6
	move.w d6,(a1)+
.opt2
.Next_T
	addq.w #1,d1
	addq.w #1,d7
	cmp.w d3,d7
	ble.s .For_T
	subq.w #1,d1
	rts



*********************************************************************************
*                         Toutes les datas du programme                         *
*********************************************************************************
	section mes_daaaatas,bss
	rsset -DATA_OFFSET
DataBase		rs.b 0
Table_Zoom_Offset	rs.l NB_ZOOM*2			bra.l + nop
Table_Zoom		rs.b 10				euh..
DataBase_SIZEOF=__RS-DataBase

_DataBase=*+DATA_OFFSET
	ds.b DataBase_SIZEOF

