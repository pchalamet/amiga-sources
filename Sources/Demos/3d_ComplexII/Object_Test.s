
*	Objet test pour la 3d_Complex II
*	--------------------------------

* La scene
* ~~~~~~~~
my_scene
	dc.w 0				scn_BlankLimit
	dc.w 0,0,100			scn_PosX,scn_PosY,scn_PosZ
	dc.w 0*8,0*8,0*8		scn_Alpha,scn_Teta,scn_Phy
	dc.l my_object1			scn_ObjectList
my_colors
	dc.w $000,$00f,$0f0,$f00,$0ff,$f0f,$ff0,$fff

* le premier object
* ~~~~~~~~~~~~~~~~~
my_object1
	dc.w 0				obj_Depth
	dc.b 0				obj_Visible
	dc.b 0				obj_Flags
	dc.w 0,0,0			obj_PosX,obj_PosY,obj_PosZ
	dc.w 0,0,0			obj_Alpha,obj_Teta,obj_Phi
	dc.l 0				obj_ExtraInit
	dc.l 0				obj_ExtraAnim
	dc.l my_object1_elements	obj_OriginalElements
	dc.l my_object1_buffer_elements	obj_ListElements
	dc.l my_object1_buffer_dots	obj_Buffer2dDots
	dc.l 0				obj_previous
	dc.l my_object2			obj_Next
my_object1_dots
	dc.w 4-1
	dc.w -100,-100,0
	dc.w -100,100,0
	dc.w 100,100,0
	dc.w 100,-100,0

my_object1_buffer_elements
	dc.w 0
	dc.l 1

my_object1_buffer_dots
	dc.w 0
	dcb.l 4,0

my_object1_elements
	dc.w 1-1
	dc.l my_object1_face

my_object1_face
	dc.w 0
	dc.w TYPE_FACE
	dc.w 3,3
	dc.w 7,7
	dc.w 0,1,2,3

* Le dernier object
* ~~~~~~~~~~~~~~~~~
my_object2
	dc.w 0				obj_Depth
	dc.b 0				obj_Visible
	dc.b 0				obj_Flags
	dc.w 800,800,800		obj_PosX,obj_PosY,obj_PosZ
	dc.w 0,0,0			obj_Alpha,obj_Teta,obj_Phi
	dc.l 0				obj_ExtraInit
	dc.l 0				obj_ExtraAnim
	dc.l my_object2_elements	obj_OriginalElements
	dc.l my_object2_buffer_elements	obj_ListElements
	dc.l my_object2_buffer_dots	obj_Buffer2dDots
	dc.l my_object1			obj_previous
	dc.l 0				obj_Next
my_object2_dots
	dc.w 4-1
	dc.w -300,-600,100
	dc.w -300,600,100
	dc.w 300,600,100
	dc.w 300,-600,100

my_object2_buffer_elements
	dc.w 0
	dc.l 1

my_object2_buffer_dots
	dc.w 0
	dcb.l 4,0

my_object2_elements
	dc.w 1-1
	dc.l my_object2_face

my_object2_face
	dc.w 0
	dc.w TYPE_FACE
	dc.w 2,2
	dc.w 5,5
	dc.w 0,1,2,3
