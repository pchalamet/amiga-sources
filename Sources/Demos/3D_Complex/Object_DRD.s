NB_POINT=92+13*2

my_object
	dc.w 1500			zoom
	dc.l my_ExtraInit		ExtraInit
	dc.l my_ExtraJump		ExtraJump
	dc.l my_colors			Couleurs de l'obj
	dc.l my_dots
	dc.l my_elements
	dc.w SCREEN_WIDTH/2
	dc.w SCREEN_HEIGHT/2+25
	dc.w 180*2-14,0,0
	dc.w 1

my_ExtraInit
	move.w #SCREEN_HEIGHT*2,PosY(a0)
	rts

my_ExtraJump
	subq.w #4,PosY(a0)			init la nouvelle position
	cmp.w #SCREEN_HEIGHT/2+25,PosY(a0)	de l'objet
	bge.s .offset_ok
	move.w #SCREEN_HEIGHT/2+25,PosY(a0)
.offset_ok
	IFNE 0
	move.w Teta(a0),d0			init les nouvelles couleurs
	cmp.w #90*2,d0
	ble.s .angle_ok
	cmp.w #180*2,d0
	bge.s .check_4_octant
	add.w #180*2,d0
	bra.s .angle_ok
.check_4_octant
	cmp.w #270*2,d0
	bge.s .angle_ok
	sub.w #180*2,d0
.angle_ok
	lea Table_Cosinus(pc),a1
	move.w 0(a1,d0.w),d0

	move.w d0,d1
	mulu #$B*2-2,d1
	swap d1
	addq.w #2,d1
	move.w d0,d2
	mulu #$8*2-1,d2
	swap d2
	addq.w #1,d2
	lsl.w #4,d2
	or.w d2,d1
	move.w d0,d2
	mulu #$5*2-3,d2
	swap d2
	addq.w #3,d2
	lsl.w #8,d2
	or.w d2,d1

	move.w d0,d2
	mulu #$A*2-2,d2
	swap d2
	addq.w #2,d2
	move.w d0,d3
	mulu #$7*2-1,d3
	swap d3
	addq.w #1,d3
	lsl.w #4,d3
	or.w d3,d2
	move.w d0,d3
	mulu #$4*2-3,d3
	swap d3
	addq.w #3,d3
	lsl.w #8,d3
	or.w d3,d2

	move.w d0,d3
	mulu #$9*2-2,d3
	swap d3
	addq.w #2,d3
	move.w d0,d4
	mulu #$6*2-1,d4
	swap d4
	addq.w #1,d4
	lsl.w #4,d4
	or.w d4,d3
	move.w d0,d4
	mulu #$3*2-3,d4
	swap d4
	addq.w #3,d4
	lsl.w #8,d4
	or.w d4,d3

	lea my_colors(pc),a1
	move.w d1,4*2(a1)
	move.w d2,5*2(a1)
	move.w d3,6*2(a1)
	ENDC

	moveq #0,d0				change les angles de rotations
	moveq #12,d1
	moveq #0,d2
	bsr Incrize_Angles
	rts

my_colors
*	dc.w $312,$B9A,$A89,$978,$58B,$47A,$369,$A68
*            Fond,-----Roses----,----Bleus-----,Rose vif
*	       0    1    2    3    4    5    6    7
*	dc.w $312,$489,$59A,$6AB,$267,$268,$269,$378
	dc.w $312,$6AB,$59A,$489,$267,$268,$269,$378


A=200
B=23

DOT1	macro
	dc.w \1*A-9*A,\2*A+200,\3*A
	endm

DOT2	macro
	dc.w \1*A,\2*A+200-A,\3*A
	endm

DOT3	macro
	dc.w \1*A+8*A,\2*A+200,\3*A
	endm

my_dots
	dc.w NB_POINT
	DOT1 1,7,1			0
	DOT1 1,6,1
	DOT1 2,6,1
	DOT1 2,4,1
	DOT1 -2,4,1
	DOT1 -3,3,1
	DOT1 -4,1,1
	DOT1 -4,-1,1
	DOT1 -3,-3,1
	DOT1 -1,-5,1
	DOT1 1,-5,1
	DOT1 2,-5,1
	DOT1 4,-3,1
	DOT1 4,6,1
	DOT1 5,6,1
	DOT1 5,7,1
	DOT1 -1,2,1
	DOT1 -2,1,1
	DOT1 -2,0,1
	DOT1 -1,-1,1
	DOT1 1,-1,1
	DOT1 2,0,1
	DOT1 2,2,1
	DOT1 1,7,-1			23
	DOT1 1,6,-1
	DOT1 2,6,-1
	DOT1 2,4,-1
	DOT1 -2,4,-1
	DOT1 -3,3,-1
	DOT1 -4,1,-1
	DOT1 -4,-1,-1
	DOT1 -3,-3,-1
	DOT1 -1,-5,-1
	DOT1 1,-5,-1
	DOT1 2,-5,-1
	DOT1 4,-3,-1
	DOT1 4,6,-1
	DOT1 5,6,-1
	DOT1 5,7,-1
	DOT1 -1,2,-1
	DOT1 -2,1,-1
	DOT1 -2,0,-1
	DOT1 -1,-1,-1
	DOT1 1,-1,-1
	DOT1 2,0,-1
	DOT1 2,2,-1

	DOT3 1,7,1			46
	DOT3 1,6,1
	DOT3 2,6,1
	DOT3 2,4,1
	DOT3 -2,4,1
	DOT3 -3,3,1
	DOT3 -4,1,1
	DOT3 -4,-1,1
	DOT3 -3,-3,1
	DOT3 -1,-5,1
	DOT3 1,-5,1
	DOT3 2,-5,1
	DOT3 4,-3,1
	DOT3 4,6,1
	DOT3 5,6,1
	DOT3 5,7,1
	DOT3 -1,2,1
	DOT3 -2,1,1
	DOT3 -2,0,1
	DOT3 -1,-1,1
	DOT3 1,-1,1
	DOT3 2,0,1
	DOT3 2,2,1
	DOT3 1,7,-1			69
	DOT3 1,6,-1
	DOT3 2,6,-1
	DOT3 2,4,-1
	DOT3 -2,4,-1
	DOT3 -3,3,-1
	DOT3 -4,1,-1
	DOT3 -4,-1,-1
	DOT3 -3,-3,-1
	DOT3 -1,-5,-1
	DOT3 1,-5,-1
	DOT3 2,-5,-1
	DOT3 4,-3,-1
	DOT3 4,6,-1
	DOT3 5,6,-1
	DOT3 5,7,-1
	DOT3 -1,2,-1
	DOT3 -2,1,-1
	DOT3 -2,0,-1
	DOT3 -1,-1,-1
	DOT3 1,-1,-1
	DOT3 2,0,-1
	DOT3 2,2,-1			91

	DOT2 -4,5,1			92
	DOT2 -4,-4,1
	DOT2 -2,-4,1
	DOT2 -2,2,1
	DOT2 -1,3,1
	DOT2 1,3,1
	DOT2 1,1,1
	DOT2 3,1,1
	DOT2 3,4,1
	DOT2 1,5,1
	DOT2 -1,5,1
	DOT2 -2,4,1
	DOT2 -2,5,1			104

	DOT2 -4,5,-1			105
	DOT2 -4,-4,-1
	DOT2 -2,-4,-1
	DOT2 -2,2,-1
	DOT2 -1,3,-1
	DOT2 1,3,-1
	DOT2 1,1,-1
	DOT2 3,1,-1
	DOT2 3,4,-1
	DOT2 1,5,-1
	DOT2 -1,5,-1
	DOT2 -2,4,-1
	DOT2 -2,5,-1			117

my_elements
	dc.w 52+4+4+13-4-4-3
	dc.l face_D1_up1
	dc.l face_D1_up2
	dc.l face_D1_down1
	dc.l face_D1_down2
	dc.l face_D1_1
	dc.l face_D1_2
	dc.l face_D1_3
;	dc.l face_D1_4
	dc.l face_D1_5
	dc.l face_D1_6
	dc.l face_D1_7
	dc.l face_D1_8
	dc.l face_D1_9
;	dc.l face_D1_10
	dc.l face_D1_11
	dc.l face_D1_12
	dc.l face_D1_13
	dc.l face_D1_14
;	dc.l face_D1_15
	dc.l face_D1_16
	dc.l face_D1_17
	dc.l face_D1_18
;	dc.l face_D1_19
	dc.l face_D1_20
	dc.l face_D1_21
	dc.l face_D1_22

	dc.l face_D2_up1
	dc.l face_D2_up2
	dc.l face_D2_down1
	dc.l face_D2_down2
	dc.l face_D2_1
	dc.l face_D2_2
	dc.l face_D2_3
;	dc.l face_D2_4
	dc.l face_D2_5
	dc.l face_D2_6
	dc.l face_D2_7
	dc.l face_D2_8
	dc.l face_D2_9
;	dc.l face_D2_10
	dc.l face_D2_11
	dc.l face_D2_12
	dc.l face_D2_13
	dc.l face_D2_14
;	dc.l face_D2_15
	dc.l face_D2_16
	dc.l face_D2_17
	dc.l face_D2_18
;	dc.l face_D2_19
	dc.l face_D2_20
	dc.l face_D2_21
	dc.l face_D2_22
	dc.l face_R_up1
	dc.l face_R_up2
	dc.l face_R_up3
	dc.l face_R_up4
	dc.l face_R_down1
	dc.l face_R_down2
	dc.l face_R_down3
	dc.l face_R_down4
	dc.l face_R_1
;	dc.l face_R_2
	dc.l face_R_3
	dc.l face_R_4
	dc.l face_R_5
	dc.l face_R_6
	dc.l face_R_7
	dc.l face_R_8
	dc.l face_R_9
;	dc.l face_R_10
	dc.l face_R_11
	dc.l face_R_12
;	dc.l face_R_13

face_D1_up1
	dc.w TYPE_FACE
	dc.w 0
	dc.w 4,-1
	dc.w 11
	dc.w 0,1,1,2,2,21,21,20,20,10,10,11,11,12,12,13,13,14,14,15,15,0

face_D1_up2
	dc.w TYPE_FACE
	dc.w 0
	dc.w 4,-1
	dc.w 14
	dc.w 3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,20,20,19,19,18,18,17,17,16,16,22,22,3

face_D1_down1
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,6
	dc.w 11
	dc.w 0+B,1+B,1+B,2+B,2+B,21+B,21+B,20+B,20+B,10+B,10+B,11+B,11+B,12+B,12+B,13+B,13+B,14+B,14+B,15+B,15+B,0+B

face_D1_down2
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,6
	dc.w 14
	dc.w 3+B,4+B,4+B,5+B,5+B,6+B,6+B,7+B,7+B,8+B,8+B,9+B,9+B,10+B,10+B,20+B,20+B,19+B,19+B,18+B,18+B,17+B,17+B,16+B,16+B,22+B,22+B,3+B

face_D1_1
	dc.w TYPE_FACE
	dc.w 0
	dc.w 1,-1
	dc.w 4
	dc.w 0,23,23,24,24,1,1,0

face_D1_2
	dc.w TYPE_FACE
	dc.w 0
	dc.w 7,-1
	dc.w 4
	dc.w 1,24,24,25,25,2,2,1

face_D1_3
	dc.w TYPE_FACE
	dc.w 0
	dc.w 2,-1
	dc.w 4
	dc.w 2,25,25,26,26,3,3,2

face_D1_4
	dc.w TYPE_FACE
	dc.w 0
	dc.w 7,-1
	dc.w 4
	dc.w 3,26,26,27,27,4,4,3

face_D1_5
	dc.w TYPE_FACE
	dc.w 0
	dc.w 3,-1
	dc.w 4
	dc.w 4,27,27,28,28,5,5,4

face_D1_6
	dc.w TYPE_FACE
	dc.w 0
	dc.w 2,-1
	dc.w 4
	dc.w 5,28,28,29,29,6,6,5

face_D1_7
	dc.w TYPE_FACE
	dc.w 0
	dc.w 1,-1
	dc.w 4
	dc.w 6,29,29,30,30,7,7,6

face_D1_8
	dc.w TYPE_FACE
	dc.w 0
	dc.w 2,-1
	dc.w 4
	dc.w 7,30,30,31,31,8,8,7

face_D1_9
	dc.w TYPE_FACE
	dc.w 0
	dc.w 3,-1
	dc.w 4
	dc.w 8,31,31,32,32,9,9,8

face_D1_10
	dc.w TYPE_FACE
	dc.w 0
	dc.w 7,-1
	dc.w 4
	dc.w 9,32,32,34,34,11,11,9

face_D1_11
	dc.w TYPE_FACE
	dc.w 0
	dc.w 2,-1
	dc.w 4
	dc.w 11,34,34,35,35,12,12,11

face_D1_12
	dc.w TYPE_FACE
	dc.w 0
	dc.w 1,-1
	dc.w 4
	dc.w 12,35,35,36,36,13,13,12

face_D1_13
	dc.w TYPE_FACE
	dc.w 0
	dc.w 7,-1
	dc.w 4
	dc.w 13,36,36,37,37,14,14,13

face_D1_14
	dc.w TYPE_FACE
	dc.w 0
	dc.w 2,-1
	dc.w 4
	dc.w 14,37,37,38,38,15,15,14

face_D1_15
	dc.w TYPE_FACE
	dc.w 0
	dc.w 7,-1
	dc.w 4
	dc.w 15,38,38,23,23,0,0,15

face_D1_16
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,1
	dc.w 4
	dc.w 16,39,39,40,40,17,17,16

face_D1_17
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,2
	dc.w 4
	dc.w 17,40,40,41,41,18,18,17

face_D1_18
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,3
	dc.w 4
	dc.w 18,41,41,42,42,19,19,18

face_D1_19
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,7
	dc.w 4
	dc.w 19,42,42,43,43,20,20,19

face_D1_20
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,2
	dc.w 4
	dc.w 20,43,43,44,44,21,21,20

face_D1_21
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,1
	dc.w 4
	dc.w 21,44,44,45,45,22,22,21

face_D1_22
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,7
	dc.w 4
	dc.w 22,45,45,39,39,16,16,22


C set 46
face_D2_up1
	dc.w TYPE_FACE
	dc.w 0
	dc.w 6,-1
	dc.w 11
	dc.w 0+C,1+C,1+C,2+C,2+C,21+C,21+C,20+C,20+C,10+C,10+C,11+C,11+C,12+C,12+C,13+C,13+C,14+C,14+C,15+C,15+C,0+C

face_D2_up2
	dc.w TYPE_FACE
	dc.w 0
	dc.w 6,-1
	dc.w 14
	dc.w 3+C,4+C,4+C,5+C,5+C,6+C,6+C,7+C,7+C,8+C,8+C,9+C,9+C,10+C,10+C,20+C,20+C,19+C,19+C,18+C,18+C,17+C,17+C,16+C,16+C,22+C,22+C,3+C

face_D2_down1
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,4
	dc.w 11
	dc.w 0+B+C,1+B+C,1+B+C,2+B+C,2+B+C,21+B+C,21+B+C,20+B+C,20+B+C,10+B+C,10+B+C,11+B+C,11+B+C,12+B+C,12+B+C,13+B+C,13+B+C,14+B+C,14+B+C,15+B+C,15+B+C,0+B+C

face_D2_down2
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,4
	dc.w 14
	dc.w 3+B+C,4+B+C,4+B+C,5+B+C,5+B+C,6+B+C,6+B+C,7+B+C,7+B+C,8+B+C,8+B+C,9+B+C,9+B+C,10+B+C,10+B+C,20+B+C,20+B+C,19+B+C,19+B+C,18+B+C,18+B+C,17+B+C,17+B+C,16+B+C,16+B+C,22+B+C,22+B+C,3+B+C

face_D2_1
	dc.w TYPE_FACE
	dc.w 0
	dc.w 1,-1
	dc.w 4
	dc.w 0+C,23+C,23+C,24+C,24+C,1+C,1+C,0+C

face_D2_2
	dc.w TYPE_FACE
	dc.w 0
	dc.w 7,-1
	dc.w 4
	dc.w 1+C,24+C,24+C,25+C,25+C,2+C,2+C,1+C

face_D2_3
	dc.w TYPE_FACE
	dc.w 0
	dc.w 2,-1
	dc.w 4
	dc.w 2+C,25+C,25+C,26+C,26+C,3+C,3+C,2+C

face_D2_4
	dc.w TYPE_FACE
	dc.w 0
	dc.w 7,-1
	dc.w 4
	dc.w 3+C,26+C,26+C,27+C,27+C,4+C,4+C,3+C

face_D2_5
	dc.w TYPE_FACE
	dc.w 0
	dc.w 3,-1
	dc.w 4
	dc.w 4+C,27+C,27+C,28+C,28+C,5+C,5+C,4+C

face_D2_6
	dc.w TYPE_FACE
	dc.w 0
	dc.w 2,-1
	dc.w 4
	dc.w 5+C,28+C,28+C,29+C,29+C,6+C,6+C,5+C

face_D2_7
	dc.w TYPE_FACE
	dc.w 0
	dc.w 1,-1
	dc.w 4
	dc.w 6+C,29+C,29+C,30+C,30+C,7+C,7+C,6+C

face_D2_8
	dc.w TYPE_FACE
	dc.w 0
	dc.w 2,-1
	dc.w 4
	dc.w 7+C,30+C,30+C,31+C,31+C,8+C,8+C,7+C

face_D2_9
	dc.w TYPE_FACE
	dc.w 0
	dc.w 3,-1
	dc.w 4
	dc.w 8+C,31+C,31+C,32+C,32+C,9+C,9+C,8+C

face_D2_10
	dc.w TYPE_FACE
	dc.w 0
	dc.w 7,-1
	dc.w 4
	dc.w 9+C,32+C,32+C,34+C,34+C,11+C,11+C,9+C

face_D2_11
	dc.w TYPE_FACE
	dc.w 0
	dc.w 2,-1
	dc.w 4
	dc.w 11+C,34+C,34+C,35+C,35+C,12+C,12+C,11+C

face_D2_12
	dc.w TYPE_FACE
	dc.w 0
	dc.w 1,-1
	dc.w 4
	dc.w 12+C,35+C,35+C,36+C,36+C,13+C,13+C,12+C

face_D2_13
	dc.w TYPE_FACE
	dc.w 0
	dc.w 7,-1
	dc.w 4
	dc.w 13+C,36+C,36+C,37+C,37+C,14+C,14+C,13+C

face_D2_14
	dc.w TYPE_FACE
	dc.w 0
	dc.w 2,-1
	dc.w 4
	dc.w 14+C,37+C,37+C,38+C,38+C,15+C,15+C,14+C

face_D2_15
	dc.w TYPE_FACE
	dc.w 0
	dc.w 3,-1
	dc.w 4
	dc.w 15+C,38+C,38+C,23+C,23+C,0+C,0+C,15+C

face_D2_16
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,1
	dc.w 4
	dc.w 16+C,39+C,39+C,40+C,40+C,17+C,17+C,16+C

face_D2_17
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,2
	dc.w 4
	dc.w 17+C,40+C,40+C,41+C,41+C,18+C,18+C,17+C

face_D2_18
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,3
	dc.w 4
	dc.w 18+C,41+C,41+C,42+C,42+C,19+C,19+C,18+C

face_D2_19
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,7
	dc.w 4
	dc.w 19+C,42+C,42+C,43+C,43+C,20+C,20+C,19+C

face_D2_20
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,2
	dc.w 4
	dc.w 20+C,43+C,43+C,44+C,44+C,21+C,21+C,20+C

face_D2_21
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,1
	dc.w 4
	dc.w 21+C,44+C,44+C,45+C,45+C,22+C,22+C,21+C

face_D2_22
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,7
	dc.w 4
	dc.w 22+C,45+C,45+C,39+C,39+C,16+C,16+C,22+C


face_R_up1
	dc.w TYPE_FACE
	dc.w 0
	dc.w 5,-1
	dc.w 4
	dc.w 92,93,93,94,94,104,104,92

face_R_up2
	dc.w TYPE_FACE
	dc.w 0
	dc.w 5,-1
	dc.w 4
	dc.w 95,96,96,102,102,103,103,95

face_R_up3
	dc.w TYPE_FACE
	dc.w 0
	dc.w 5,-1
	dc.w 4
	dc.w 96,97,97,101,101,102,102,96

face_R_up4
	dc.w TYPE_FACE
	dc.w 0
	dc.w 5,-1
	dc.w 4
	dc.w 98,99,99,100,100,101,101,98

C set 13
face_R_down1
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,5
	dc.w 4
	dc.w 92+C,93+C,93+C,94+C,94+C,104+C,104+C,92+C

face_R_down2
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,5
	dc.w 4
	dc.w 95+C,96+C,96+C,102+C,102+C,103+C,103+C,95+C

face_R_down3
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,5
	dc.w 4
	dc.w 96+C,97+C,97+C,101+C,101+C,102+C,102+C,96+C

face_R_down4
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,5
	dc.w 4
	dc.w 98+C,99+C,99+C,100+C,100+C,101+C,101+C,98+C

face_R_1
	dc.w TYPE_FACE
	dc.w 0
	dc.w 1,-1
	dc.w 4
	dc.w 92,105,105,106,106,93,93,92

face_R_2
	dc.w TYPE_FACE
	dc.w 0
	dc.w 7,-1
	dc.w 4
	dc.w 93,106,106,107,107,94,94,93

face_R_3
	dc.w TYPE_FACE
	dc.w 0
	dc.w 2,-1
	dc.w 4
	dc.w 94,107,107,108,108,95,95,94

face_R_4
	dc.w TYPE_FACE
	dc.w 0
	dc.w 3,-1
	dc.w 4
	dc.w 95,108,108,109,109,96,96,95

face_R_5
	dc.w TYPE_FACE
	dc.w 0
	dc.w 7,-1
	dc.w 4
	dc.w 96,109,109,110,110,97,97,96

face_R_6
	dc.w TYPE_FACE
	dc.w 0
	dc.w 2,-1
	dc.w 4
	dc.w 97,110,110,111,111,98,98,97

face_R_7
	dc.w TYPE_FACE
	dc.w 0
	dc.w 7,-1
	dc.w 4
	dc.w 98,111,111,112,112,99,99,98

face_R_8
	dc.w TYPE_FACE
	dc.w 0
	dc.w 1,-1
	dc.w 4
	dc.w 99,112,112,113,113,100,100,99

face_R_9
	dc.w TYPE_FACE
	dc.w 0
	dc.w 2,-1
	dc.w 4
	dc.w 100,113,113,114,114,101,101,100

face_R_10
	dc.w TYPE_FACE
	dc.w 0
	dc.w 7,-1
	dc.w 4
	dc.w 101,114,114,115,115,102,102,101

face_R_11
	dc.w TYPE_FACE
	dc.w 0
	dc.w 3,-1
	dc.w 4
	dc.w 102,115,115,116,116,103,103,102

face_R_12
	dc.w TYPE_FACE
	dc.w 0
	dc.w 2,-1
	dc.w 4
	dc.w 103,116,116,117,117,104,104,103

face_R_13
	dc.w TYPE_FACE
	dc.w 0
	dc.w 7,-1
	dc.w 4
	dc.w 104,107,107,105,105,92,92,104
