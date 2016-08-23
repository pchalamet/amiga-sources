NB_POINT=8*6
my_object
	dc.w 1800			zoom
	dc.l 0				ExtraInit
	dc.l my_ExtraJump		ExtraJump
	dc.l my_color			ObjectColor
	dc.l my_dots
	dc.l my_elements
	dc.w SCREEN_WIDTH/2		PosX
	dc.w SCREEN_HEIGHT/2		PosY
	dc.w 0				Alpha
	dc.w 0				Teta
	dc.w 0				Phi
	dc.w 0				BlankLimit

etage	macro
	dc.w 500*\2,0,\1
	dc.w 350*\2,-350*\2,\1
	dc.w 0,-500*\2,\1
	dc.w -350*\2,-350*\2,\1
	dc.w -500*\2,0,\1
	dc.w -350*\2,350*\2,\1
	dc.w 0,500*\2,\1
	dc.w 350*\2,350*\2,\1
	endm

face	macro
\@
	dc.w TYPE_FACE				face color,p1,p2,etage
	dc.w 0
	dc.w -1,\1
	dc.w 4
	dc.w \2+8*\4,\3+8*\4
	dc.w \3+8*\4,\3+8*\4+8
	dc.w \3+8*\4+8,\2+8*\4+8
	dc.w \2+8*\4+8,\2+8*\4
	endm

circle	macro
	face \1,0,1,\2				circle color,etage
	face \1+1,1,2,\2
	face \1,2,3,\2
	face \1+1,3,4,\2
	face \1,4,5,\2
	face \1+1,5,6,\2
	face \1,6,7,\2
	face \1+1,7,0,\2
	endm	

my_dots
	dc.w NB_POINT			nb points
	etage -2000,2
	etage -600,1
	etage -200,3
	etage 200,3
	etage 600,1
	etage 2000,2

my_elements
	dc.w 8*5+2
	dc.l _012
	dc.l _013
	dc.l _014
	dc.l _015
	dc.l _016
	dc.l _017
	dc.l _018
	dc.l _019
	dc.l _020
	dc.l _021
	dc.l _022
	dc.l _023
	dc.l _024
	dc.l _025
	dc.l _026
	dc.l _027
	dc.l _028
	dc.l _029
	dc.l _030
	dc.l _031
	dc.l _032
	dc.l _033
	dc.l _034
	dc.l _035
	dc.l _036
	dc.l _037
	dc.l _038
	dc.l _039
	dc.l _040
	dc.l _041
	dc.l _042
	dc.l _043
	dc.l _044
	dc.l _045
	dc.l _046
	dc.l _047
	dc.l _048
	dc.l _049
	dc.l _050
	dc.l _051
	dc.l face_top
	dc.l face_bottom

	circle 1,0			étage 0-1
	circle 3,1			étage 1-2
	circle 5,2			étage 2-3
	circle 3,3			étage 3-4
	circle 1,4			étage 4-5

face_top
	dc.w TYPE_FACE
	dc.w 0
	dc.w 7,-1
	dc.w 8
	dc.w 0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,0
face_bottom
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,7
	dc.w 8
	dc.w 40,41,41,42,42,43,43,44,44,45,45,46,46,47,47,40

my_color
	dc.w $467,$B9A,$58B,$A89,$47A,$978,$369,$A68

my_ExtraJump
;4 -6 -8
	moveq #2,d0
	moveq #-4,d1
	moveq #-2,d2
	lea my_object(pc),a0
	bsr Incrize_Angles

	subq.w #1,waiting-data_base(a5)
	beq.s next_transformation
	lea my_object(pc),a0
	move.l transform_ptr(pc),a1
	move.l (a1),a1
	bsr Transformer
	rts

next_transformation
	move.l transform_ptr(pc),a0
	addq.l #4,a0
	tst.l (a0)
	bne.s .ok
	lea table_transform(pc),a0
.ok
	move.l a0,transform_ptr-data_base(a5)

	move.l (a0),a0					init waiting
	move.w (a0),waiting-data_base(a5)
	add.w #20,waiting-data_base(a5)

	lea my_object(pc),a0
	bsr Transformer_Init
	rts

waiting
	dc.w 1
transform_ptr
	dc.l table_transform
table_transform
	dc.l transform1
	dc.l transform6
	dc.l transform3
	dc.l transform7
	dc.l transform2
	dc.l transform4
	dc.l transform5
	dc.l transform8
	dc.l 0

transform1
	dc.w 40
	etage -2000,2
	etage -600,1
	etage -200,3
	etage 200,3
	etage 600,1
	etage 2000,2

transform2
	dc.w 40
	etage -2000,1
	etage -1700,3
	etage -1400,1
	etage 1400,1
	etage 1700,3
	etage 2000,1

transform3
	dc.w 40
	etage -2500,1
	etage -2000,3
	etage -800,1
	etage 800,1
	etage 2000,3
	etage 2500,1

transform4
	dc.w 40
	etage -1500,1
	etage -1000,2
	etage -500,3
	etage 0,4
	etage 500,3
	etage 1000,2

transform5
	dc.w 40
	etage -1000,2
	etage -500,3
	etage -500,1
	etage 500,1
	etage 500,3
	etage 1000,2

transform6
	dc.w 40
	etage -1000,2
	etage -500,3
	etage -500,4
	etage 500,4
	etage 500,3
	etage 1000,2

transform7
	dc.w 40
	etage -1000,1
	etage -500,4
	etage -500,2
	etage 500,2
	etage 500,4
	etage 1000,1

transform8
	dc.w 40
	etage -3000,2
	etage -2000,2
	etage -1000,2
	etage 1000,2
	etage 2000,2
	etage 3000,2

