
*			mapping
*			-------
*
*		(c) 1995 SYnc/DramDealers
*






	incdir "asm:Sources/"
	incdir "asm:.s/Mapping/"
	

	include "registers.i"
	include "mapping.i"



Entry_Point
	KILL_SYSTEM Main
	moveq #0,d0
	rts



Main
	lea Dragon_Face,a0
	bsr Draw_Mapped_Face

	rts



*   --> A0=Pointeur sur une face
Draw_Mapped_Face
	lea Left_Buffer,a1
	lea Right_Buffer,a2

	addq.l #4,a0			saute la texture
	move.l (a0)+,d7			nb de droites
	subq.w #2,d7			dbf + derniere droite

	moveq #0,d0			offset Dot dans la Texture

;; saute deja les droites horizontales
	move.l (a0)+,d1			premier point
Skip_Horizontal
	move.l (a0)+,d2			point suivant

	cmp.w d1,d2			on est dans quel cote ?
	bgt Fill_Left_First		d2 plus bas que d1  => cote gauche
	blt Fill_Right_First		d2 plus haut que d1 => cote droit
;; c'est donc eq => pas de droite => essait encore
	move.l d2,d1
	addq.w #Dot_SizeOF,d0
	dbf d7,Skip_Horizontal

;; maintenant , jusqu'a ce que l'on arrive a droite, on remplie a gauche
Fill_Left
	addq.w #Dot_SizeOF,d0
	move.l d2,d1

	move.l (a0)+,d2
	cmp.w d1,d2			on est encore a gauche ?
	blt Fill_Right			nan => cote droit
	beq.s Skip_Bottom_First		presque => saute les Bottoms
Fill_Left_First
	movem.l d0/d1/d2,-(a1)
	dbf d7,Fill_Left
	bra Fill_Last

;; on a rencontre une ligne horizontale en bas => on saute tant que yen a
Skip_Bottom
	addq.w #Dot_SizeOF,d0
	move.l d2,d1

	move.l (a0)+,d2
	cmp.w d1,d2			toujours des Bottoms ?
	blt.s Fill_Right_First		nan => cote droit
Skip_Bottom_First
	dbf d7,Skip_Bottom
	bra Fill_Last



Fill_Right_First
	addq.w #Dot_SizeOF,d0
	exg d1,d2			remet ca dans le bon sens
	bra.s Fill_Right_Start
	
Fill_Right
	addq.w #Dot_SizeOF,d0
	move.l d1,d2

	move.l (a0)+,d1
	cmp.w d1,d2
	blt Fill_Left_First
	beq Skip_Top_First



Fill_Right_Start
	movem.l d0/d1/d2,-(a2)
	dbf d7,Fill_Right
	bra Fill_Last

Skip_Top
	addq.w #Dot_SizeOF,d0
	move.l d1,d2

	move.l (a0)+,d1
	cmp.w d1,d2
	blt Fill_Left_First


Skip_Top_First
	dbf d7,Skip_Top


Fill_Last



*****************************************************************************
********************************* DATAS *************************************
*****************************************************************************



	section mapping_datas,bss

	ds.b 1024
Left_Buffer
	ds.b 1024

	ds.b 1024
Right_Buffer
	ds.b 1024





	section mapping_constant_datas,data

	include "Dragon.Obj"
