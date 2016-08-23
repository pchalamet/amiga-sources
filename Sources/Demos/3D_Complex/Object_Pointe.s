********************************************************************************
***************** objet qui représente des plateaux superposés *****************
*****************      entourés d'un cadre en droites	       *****************
********************************************************************************
NB_POINT=14
my_object
	dc.w 1800				zoom
	dc.l 0					ExtraInit
	dc.l my_ExtraJump			ExtraJmp
	dc.l my_color				ObjectColor
	dc.l my_dots
	dc.l my_elements
	dc.w 70					Pos X
	dc.w 180				Pos Y
	dc.w 0					alpha
	dc.w 0					teta
	dc.w 0					phi
	dc.w 1					BlankLimit
	
my_dots
	dc.w NB_POINT				nb de points

	dc.w 200,200,200
	dc.w 200,-200,200
	dc.w -200,-200,200
	dc.w -200,200,200

	dc.w 200,200,-200
	dc.w 200,-200,-200
	dc.w -200,-200,-200
	dc.w -200,200,-200

	dc.w 0,0,1000
	dc.w 0,0,-1000
	dc.w 0,1000,0
	dc.w 0,-1000,0
	dc.w 1000,0,0
	dc.w -1000,0,0

my_elements
	dc.w 4*6
	dc.l face1
	dc.l face2
	dc.l face3
	dc.l face4
	
	dc.l face5
	dc.l face6
	dc.l face7
	dc.l face8

	dc.l face9
	dc.l face10
	dc.l face11
	dc.l face12

	dc.l face13
	dc.l face14
	dc.l face15
	dc.l face16

	dc.l face17
	dc.l face18
	dc.l face19
	dc.l face20

	dc.l face21
	dc.l face22
	dc.l face23
	dc.l face24

face1
	dc.w TYPE_FACE 
	dc.w 0
	dc.w 1,-1
	dc.w 3
	dc.w 1,0,0,8,8,1
face2
	dc.w TYPE_FACE
	dc.w 0
	dc.w 6,-1
	dc.w 3
	dc.w 0,3,3,8,8,0
face3
	dc.w TYPE_FACE
	dc.w 0
	dc.w 3,-1
	dc.w 3
	dc.w 3,2,2,8,8,3
face4
	dc.w TYPE_FACE
	dc.w 0
	dc.w 4,-1
	dc.w 3
	dc.w 2,1,1,8,8,2

face5
	dc.w TYPE_FACE
	dc.w 0
	dc.w 1,-1
	dc.w 3
	dc.w 4,5,5,9,9,4
face6
	dc.w TYPE_FACE
	dc.w 0
	dc.w 2,-1
	dc.w 3
	dc.w 5,6,6,9,9,5
face7
	dc.w TYPE_FACE
	dc.w 0
	dc.w 3,-1
	dc.w 3
	dc.w 6,7,7,9,9,6
face8
	dc.w TYPE_FACE
	dc.w 0
	dc.w 4,-1
	dc.w 3
	dc.w 7,4,4,9,9,7

face9
	dc.w TYPE_FACE
	dc.w 0
	dc.w 5,-1
	dc.w 3
	dc.w 0,1,1,12,12,0
face10
	dc.w TYPE_FACE
	dc.w 0
	dc.w 6,-1
	dc.w 3
	dc.w 1,5,5,12,12,1
face11
	dc.w TYPE_FACE
	dc.w 0
	dc.w 7,-1
	dc.w 3
	dc.w 5,4,4,12,12,5
face12
	dc.w TYPE_FACE
	dc.w 0
	dc.w 1,-1
	dc.w 3
	dc.w 4,0,0,12,12,4

face13
	dc.w TYPE_FACE
	dc.w 0
	dc.w 5,-1
	dc.w 3
	dc.w 2,3,3,13,13,2
face14
	dc.w TYPE_FACE
	dc.w 0
	dc.w 6,-1
	dc.w 3
	dc.w 3,7,7,13,13,3
face15
	dc.w TYPE_FACE
	dc.w 0
	dc.w 7,-1
	dc.w 3
	dc.w 7,6,6,13,13,7
face16
	dc.w TYPE_FACE
	dc.w 0
	dc.w 1,-1
	dc.w 3
	dc.w 6,2,2,13,13,6

face17
	dc.w TYPE_FACE
	dc.w 0
	dc.w 2,-1
	dc.w 3
	dc.w 1,2,2,11,11,1
face18
	dc.w TYPE_FACE
	dc.w 0
	dc.w 4,-1
	dc.w 3
	dc.w 2,6,6,11,11,2
face19
	dc.w TYPE_FACE
	dc.w 0
	dc.w 6,-1
	dc.w 3
	dc.w 6,5,5,11,11,6
face20
	dc.w TYPE_FACE
	dc.w 0
	dc.w 7,-1
	dc.w 3
	dc.w 5,1,1,11,11,5

face21
	dc.w TYPE_FACE
	dc.w 0
	dc.w 2,-1
	dc.w 3
	dc.w 3,0,0,10,10,3
face22
	dc.w TYPE_FACE
	dc.w 0
	dc.w 4,-1
	dc.w 3
	dc.w 0,4,4,10,10,0
face23
	dc.w TYPE_FACE
	dc.w 0
	dc.w 6,-1
	dc.w 3
	dc.w 4,7,7,10,10,4
face24
	dc.w TYPE_FACE
	dc.w 0
	dc.w 7,-1
	dc.w 3
	dc.w 7,3,3,10,10,7

my_color
;;	dc.w $789,$586,$568,$657,$675,$858,$865,$567
	incbin "palette2"

my_ExtraJump
	lea my_object(pc),a0
	moveq #-2,d0
	moveq #6,d1
	moveq #8,d2
	bra Incrize_Angles

