
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

	moveq #0,d2



** a1=adr buffer droites cote gauche
** d3=point de depart des droites cote gauche
** d4=nb de lignes cote gauche

** a2=adr buffer droites cote droit
** d4=point de depart des droites cote droit
** d5=nb de lignes cote droit

;; recherche ici une droite non horizontale
;; pour determiner de quel cote onse trouve
	movem.l (a0)+,d0/d1
Determine_Cote
	cmp.w d0,d1
	bgt Cote_Gauche
	blt Cote_Droit
	move.l d1,d0
	addq.w #Dot_SizeOF,d2
	dbf d7,Determine_Cote
;; on devrait jamais arriver ici normalement !!!


;; on a trouve le cote gauche
Cote_Gauche
	lea -Dot_SizeOF*2(a0),a1	sauve le ptr sur ces points
	move.l d2,d3			sauve le point de depart gauche
	moveq #1,d4			nb de droites
;; tant qu'on est a gauche , on y reste,  sinon on passe a droite
Cote_Gauche_Loop
	move.l d1,d0
	move.l (a0)+,d1
	cmp.w d0,d1
	blt.s Cote_Gauche_Droit
	beq.s Cote_Gauche_Bottom

	addq.w #1,d4
	addq.w #Dot_SizeOF,d2
	dbf d7,Cote_Gauche_Loop
;; on devrait jamais arriver ici normalement !!!

Cote_Gauche_Bottom
	addq.w #Dot_SizeOF,d2

	move.l d1,d0
	move.l (a0)+,d1
	cmp.w d0,d1
	blt.s Cote_Gauche_Droit
	dbf d7,Cote_Gauche_Bottom

;; on devrait jamais arriver ici normalement !!!

Cote_Gauche_Droit
	moveq #1,d6			nb de lignes cote droit
Cote_Gauche_Droit_Loop
	move.l (a0)+,d0
	cmp.w d0,d1
	beq Cote_Gauche_Top
	bgt Dup_Cote_Gauche


Cote_Gauche_Top



Cote_Droit


*****************************************************************************
********************************* DATAS *************************************
*****************************************************************************



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
