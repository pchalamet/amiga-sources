NB_POINT=38
my_object
	dc.w 1000			zoom
	dc.l 0				ExtraInit
	dc.l my_ExtraJump		ExtraJump
	dc.l my_color			ObjectColor
	dc.l my_dots
	dc.l my_elements
	dc.w 160			PosX
	dc.w 128			PosY
	dc.w 0				Alpha
	dc.w 0				Teta
	dc.w 0				Phi
	dc.w 0				BlankLimit

my_dots
	dc.w NB_POINT			nb points
* face du dessus
	dc.w -800,-800,-200
	dc.w -800,-400,-200
	dc.w -800,400,-200
	dc.w -800,800,-200
	dc.w -400,800,-200
	dc.w 400,800,-200
	dc.w 800,800,-200
	dc.w 800,400,-200
	dc.w 800,-400,-200
	dc.w 800,-800,-200
	dc.w 400,-800,-200
	dc.w -400,-800,-200
	dc.w -400,-400,-200
	dc.w -400,400,-200
	dc.w 400,400,-200
	dc.w 400,-400,-200
* face du dessous
	dc.w -800,-800,200
	dc.w -800,-400,200
	dc.w -800,400,200
	dc.w -800,800,200
	dc.w -400,800,200
	dc.w 400,800,200
	dc.w 800,800,200
	dc.w 800,400,200
	dc.w 800,-400,200
	dc.w 800,-800,200
	dc.w 400,-800,200
	dc.w -400,-800,200
	dc.w -400,-400,200
	dc.w -400,400,200
	dc.w 400,400,200
	dc.w 400,-400,200
	dc.w 0,0,-800
	dc.w 0,0,800
	dc.w -400,0,0
	dc.w 400,0,0
	dc.w 0,-400,0
	dc.w 0,400,0

my_elements
	dc.w 35
* haut
	dc.l face0
	dc.l face1
	dc.l face2
	dc.l face3
	dc.l face4
	dc.l face5
	dc.l face6
	dc.l face7
* bas
	dc.l face8
	dc.l face9
	dc.l face10
	dc.l face11
	dc.l face12
	dc.l face13
	dc.l face14
	dc.l face15
* coté gauche
	dc.l face16
	dc.l face17
	dc.l face18
* coté bas
	dc.l face19
	dc.l face20
	dc.l face21
* coté droit
	dc.l face22
	dc.l face23
	dc.l face24
* coté haut
	dc.l face25
	dc.l face26
	dc.l face27
* milieu
	dc.l face28
	dc.l face29
	dc.l face30
	dc.l face31
	dc.l line1
	dc.l line2
	dc.l line3

face0
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,7
	dc.w 4
	dc.w 0,11,11,12,12,1,1,0
face1
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,1
	dc.w 4
	dc.w 1,12,12,13,13,2,2,1
face2
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,1
	dc.w 4
	dc.w 2,13,13,4,4,3,3,2
face3
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,1
	dc.w 4
	dc.w 13,14,14,5,5,4,4,13
face4
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,1
	dc.w 4
	dc.w 14,7,7,6,6,5,5,14
face5
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,1
	dc.w 4
	dc.w 15,8,8,7,7,14,14,15
face6
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,1
	dc.w 4
	dc.w 10,9,9,8,8,15,15,10
face7
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,1
	dc.w 4
	dc.w 11,10,10,15,15,12,12,11

face8
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,7
	dc.w 4
	dc.w 16,17,17,28,28,27,27,16
face9
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,2
	dc.w 4
	dc.w 17,18,18,29,29,28,28,17
face10
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,2
	dc.w 4
	dc.w 18,19,19,20,20,29,29,18
face11
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,2
	dc.w 4
	dc.w 20,21,21,30,30,29,29,20
face12
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,2
	dc.w 4
	dc.w 21,22,22,23,23,30,30,21
face13
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,2
	dc.w 4
	dc.w 23,24,24,31,31,30,30,23
face14
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,2
	dc.w 4
	dc.w 24,25,25,26,26,31,31,24
face15
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,2
	dc.w 4
	dc.w 26,27,27,28,28,31,31,26

face16
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,3
	dc.w 4
	dc.w 0,1,1,17,17,16,16,0
face17
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,3
	dc.w 4
	dc.w 1,2,2,18,18,17,17,1
face18
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,3
	dc.w 4
	dc.w 2,3,3,19,19,18,18,2
face19
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,4
	dc.w 4
	dc.w 3,4,4,20,20,19,19,3

face20
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,4
	dc.w 4
	dc.w 4,5,5,21,21,20,20,4

face21
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,4
	dc.w 4
	dc.w 5,6,6,22,22,21,21,5

face22
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,5
	dc.w 4
	dc.w 6,7,7,23,23,22,22,6

face23
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,5
	dc.w 4
	dc.w 7,8,8,24,24,23,23,7

face24
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,5
	dc.w 4
	dc.w 8,9,9,25,25,24,24,8

face25
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,6
	dc.w 4
	dc.w 9,10,10,26,26,25,25,9

face26
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,6
	dc.w 4
	dc.w 10,11,11,27,27,26,26,10

face27
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,6
	dc.w 4
	dc.w 11,0,0,16,16,27,27,11

face28
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,5
	dc.w 4
	dc.w 13,12,12,28,28,29,29,13

face29
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,6
	dc.w 4
	dc.w 14,13,13,29,29,30,30,14

face30
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,3
	dc.w 4
	dc.w 15,14,14,30,30,31,31,15

face31
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,4
	dc.w 4
	dc.w 12,15,15,31,31,28,28,12

line1
	dc.w TYPE_LINE
	dc.w 0
	dc.w 7
	dc.w 32,33

line2
	dc.w TYPE_LINE
	dc.w 0
	dc.w 7
	dc.w 34,35
line3
	dc.w TYPE_LINE
	dc.w 0
	dc.w 7
	dc.w 36,37

my_color
	dc.w $000,$00f,$00d,$00b,$009,$007,$005,$fff

my_ExtraJump
	moveq #-2,d0
	moveq #4,d1
	moveq #6,d2
	lea my_object(pc),a0
	bsr Incrize_Angles
	rts
