NB_POINT=22
my_object
	dc.w 1500
	dc.l 0
	dc.l my_ExtraJump
	dc.l my_color
	dc.l my_dots
	dc.l my_elements
	dc.w 160,128
	dc.w 0,0,0
	dc.w 0

my_dots
	dc.w NB_POINT
p	macro
	dc.w \1*10,\2*10,\3*10
	endm

	p 0,0,130
	p 0,30,0
	p 40,0,10
	p -40,0,10
	p -20,0,-100
	p 0,20,-100
	p 20,0,-100
	p 30,0,-30
	p 80,0,-70
	p 80,0,-100
	p -30,0,-30
	p -80,0,-70
	p -80,0,-100
	p 0,20,-70
	p 0,50,-90
	p 0,50,-110
	p -30,50,-120
	p 30,50,-120
	p 80,30,-90
	p 80,30,-110
	p -80,30,-90
	p -80,30,-110

my_elements
	dc.w 13
	dc.l nez1
	dc.l nez2
	dc.l nez3

	dc.l centre1
	dc.l centre2
	dc.l centre3
	dc.l centre4
	dc.l centre5
	dc.l centre6
	dc.l centre7
	dc.l centre8
	dc.l centre9
	dc.l centre10
	
nez1
	dc.w TYPE_FACE
	dc.w 0
	dc.w 1,-1
	dc.w 3
	dc.w 2,1,1,0,0,2
nez2
	dc.w TYPE_FACE
	dc.w 0
	dc.w 2,-1
	dc.w 3
	dc.w 1,3,3,0,0,1
nez3
	dc.w TYPE_FACE
	dc.w 0
	dc.w 3,-1
	dc.w 3
	dc.w 3,2,2,0,0,3
centre1
	dc.w TYPE_FACE
	dc.w 0
	dc.w 4,-1
	dc.w 4
	dc.w 2,6,6,5,5,1,1,2
centre2
	dc.w TYPE_FACE
	dc.w 0
	dc.w 5,-1
	dc.w 4
	dc.w 5,4,4,3,3,1,1,5
centre3
	dc.w TYPE_FACE
	dc.w 0
	dc.w 6,-1
	dc.w 3
	dc.w 5,6,6,4,4,5
centre4
	dc.w TYPE_FACE
	dc.w 0
	dc.w 7,-1
	dc.w 4
	dc.w 4,6,6,2,2,3,3,4
centre5
	dc.w TYPE_FACE
	dc.w 0
	dc.w 1,2
	dc.w 4
	dc.w 8,7,7,6,6,9,9,8
centre6
	dc.w TYPE_FACE
	dc.w 0
	dc.w 2,3
	dc.w 4
	dc.w 10,11,11,12,12,4,4,10
centre7
	dc.w TYPE_FACE
	dc.w 0
	dc.w 3,4
	dc.w 4
	dc.w 13,14,14,15,15,5,5,13
centre8
	dc.w TYPE_FACE
	dc.w 0
	dc.w 4,5
	dc.w 4
	dc.w 14,16,16,15,15,17,17,14
centre9
	dc.w TYPE_FACE
	dc.w 0
	dc.w 5,6
	dc.w 4
	dc.w 8,18,18,19,19,9,9,8
centre10
	dc.w TYPE_FACE
	dc.w 0
	dc.w 6,7
	dc.w 4
	dc.w 11,20,20,21,21,12,12,11

my_color
	incbin Palette1

my_ExtraJump
	moveq #-2,d0
	moveq #4,d1
	moveq #4,d2
	lea my_object(pc),a0
	bra Incrize_Angles
	
