*                      ________________________   __________________
*           °         /                       /\ /                  \       +
*     +        .     /                       /  Y                    \  .
*                   /_____________          /  /      __________      \    °
*                   \             \        /  /      /\         \      \     .
*          +         \____________/       /  /      /  \_________\      \
*    .                           /       /  /      /   /          \      \  +
*                               /       /  /      /   /   +        \      \
*        °              +      /       /  /      /   /             /      /\   .
*             ________________/       /  /      /   /        +    /      /  \ °
*            /                       /  /      /   /             /      /   /
*           /                       /  /      /   /    .   °    /      /   /  +
*          /_____________          /  /      /___/_____________/______/___/___
*     +    \             \        /  /      //                               /\
*           \____________/       /  /      //                               / /
*                       /       /  /      //__          ______          ___/ / -
*         .   °      . /       /  /      / \_/         /\____/         /\__\/
* +             +     /       /  /      /   /         / /./ /         / /
*    ________________/       /  /      /___/         / /_/ /         / /  --  -
*   /                       /  /          /         / /   /         / /     .
*  /                       /  /          /         / /   /         / /	--- -  -
* /_______________________/  /__________/         / /___/         / /     +
* \                       \  \         /         / /   /         / /    °
*  \_______________________\/ \_______/         / /___/         / /  --- --  -  -
*                            .       /         / /   /         / /    .       +
*               +                /¯¯¯          ¯¯¯¯¯¯          ¯¯/\         °
*                               /                               / /  -- -- - -  -
*   (c) Sync Of DreamDealers   /_______________________________/ /         .
*   ~~~~~~~~~~~~~~~~~~~~~~~~   \_______________________________\/   -  --  --- -
 




	incdir "asm:"
	incdir "asm:sources/"
	incdir "asm:.S/3d_ComplexII/"

	include "registers.i"



********************************************************************************
******************                                           *******************
******************  DESCRIPTIONS DES DIFFERENTES STRUCTURES  *******************
******************                                           *******************
********************************************************************************

*--------------------------> Constantes
SCREEN_X=320
SCREEN_Y=256
SCREEN_MOD=0
SCREEN_DEPTH=3
NB_COLORS=1<<SCREEN_DEPTH
VISIBLE_DISTANCE=300
SCENE_DIST=100
MAX_OBJECTS=200
MAX_DOTS=200

*--------------------------> Flags pour les objets
FLGB_INITIALIZED=0
FLGF_INITIALIZED=1<<0

	IFNE 0
*--------------------------> STRUCT Scene
Scene			rs.b 0
scn_BlankLimit		rs.w 1		BlankLimit de la scène
scn_PosX		rs.w 1		\
scn_PosY		rs.w 1		 | on regarde à partir d'ici
scn_PosZ		rs.w 1		/
scn_Alpha		rs.w 1		\
scn_Teta		rs.w 1		 | et dans cette direction
scn_Phi			rs.w 1		/
scn_ListObjects		rs.l 1		*Object : premier object de la scene ou 0
scn_ColorMap		rs.w NB_COLORS	couleurs de la scène
scn_SIZEOF		rs.b 0
	ENDC

*--------------------------> STRUCT Object
	rsreset
Object			rs.b 0
obj_Depth		rs.w 1		profondeur de l'objet pour le Z-Buffer
obj_Visible		rs.b 1		visibilité de l'object -boolean-
obj_Flags		rs.b 1		flags pour l'objet
obj_PosX		rs.w 1		position X dans la scène
obj_PosY		rs.w 1		position Y dans la scène
obj_PosZ		rs.w 1		position Z dans la scène
obj_Alpha		rs.w 1		angle Alpha de l'objet
obj_Teta		rs.w 1		angle Teta de l'objet
obj_Phi			rs.w 1		angle Phi de l'objet
obj_ExtraInit		rs.l 1		routine d'initialisation
obj_ExtraAnim		rs.l 1		routine d'animation
obj_OriginalElements	rs.l 1		*ListElements
obj_ListElements	rs.l 1		*ListElements mais triés
obj_Buffer2dDots	rs.l 1		*Buffer pour stocker les points 2d
obj_Previous		rs.l 1		*Object précédent ou 0 pour la fin
obj_Next		rs.l 1		*Object suivant ou 0 pour la fin
obj_ListDots		rs.b 0		UNION ListDots

*--------------------------> STRUCT List
	rsreset
List			rs.b 0
l_Quantity		rs.w 1		nb de valeurs dans la structure
l_List			rs.b 0		les valeurs à la suite

*--------------------------> STRUCT Element commune à tous les Elements
	rsreset
Element			rs.b 0
elmt_Depth		rs.w 1		profondeur de la structure
elmt_Type		rs.w 1		type de la structure
elmt_SIZEOF		rs.b 0

*--------------------------> STRUCT Face
TYPE_FACE=0
TYPE_GLENZ_FACE=1
	rsreset
Face			rs.b elmt_SIZEOF
face_FrontColor1	rs.w 1		couleur du front en tramée
face_FrontColor2	rs.w 1
face_BackColor1		rs.w 1		couleur du back en tramée
face_BackColor2		rs.w 1
face_Dot1		rs.w 1		4 points pour faire une Face
face_Dot2		rs.w 1
face_Dot3		rs.w 1
face_Dot4		rs.w 1
face_SIZEOF	rs.b 0

*--------------------------> Macros
ALLOC_DOTS	macro
	IFEQ NARG=1
	fail Missing parameters : ALLOC_DOTS
	ENDC
	dcb.l \1
	endm

ALLOC_ELEMENTS	macro
	IFEQ NARG=1
	fail Missing parameters : ALLOC_ELEMENTS
	ENDC
	dc.w 0
	dcb.l \1
	endm

*--------------------------> Options de compilations
	OPT P=68030


********************************************************************************
*****************************                   ********************************
*****************************  INITIALISATIONS  ********************************
*****************************                   ********************************
********************************************************************************
	section cacolac,code

	KILL_SYSTEM Do_3d
	moveq #0,d0
	rts

Do_3d
	lea db(pc),a5
	lea custom_base,a6

	movem.l log_screen(pc),d0/d1		les écrans DOIVENT être sur
	addq.l #7,d0				des multiples de 8 car
	and.l #-8,d0				le mode 4x est utilisé
	addq.l #7,d1
	and.l #-8,d1
	movem.l d0/d1,log_screen-db(a5)

	move.l #(SCREEN_X/8)*SCREEN_Y,d3	init les pointeurs videos dans
	moveq #SCREEN_DEPTH-1,d4		les coplists
	movem.l log_coplist(pc),a0/a1
	lea bpl_ptr1-coplist1(a0),a0
	lea bpl_ptr2-coplist2(a1),a1
	bra.s put_bpl_start
loop_put_bpl_ptr
	swap d0
	swap d1
	add.l d3,d0				next screen
	add.l d3,d1
	addq.l #8,a0				next ptr
	addq.l #8,a1
put_bpl_start
	move.w d0,4(a0)				bplL
	move.w d1,4(a1)
	swap d0
	swap d1
	move.w d0,(a0)				bplH
	move.w d1,(a1)
	dbf d4,loop_put_bpl_ptr

	lea trame_screen,a0			construit l'écran de trame
	move.l #$55555555,d0
	lea SCREEN_X/8(a0),a1
	move.l #$AAAAAAAA,d1
	move.w #SCREEN_Y/2-1,d2
build_trame_screen
	move.w #SCREEN_X/32-1,d3
build_trame_line
	move.l d0,(a0)+
	move.l d1,(a1)+
	dbf d3,build_trame_line
	move.l a1,a0
	lea SCREEN_X/8(a1),a1
	dbf d2,build_trame_screen

	move.l #Vbl,$6c.w
	move.l #coplist1,cop1lc(a6)		installe une coplist
	clr.w copjmp1(a6)

	move.w #$87c0,dmacon(a6)		Pri ! Bpl ! Copper ! Blitter
	move.w #$c020,intena(a6)		it vbl | it copper

	bsr.s Main_Prg
	RESTORE_SYSTEM



********************************************************************************
****************************                       *****************************
****************************  PROGRAMME PRINCIPAL  *****************************
****************************                       *****************************
********************************************************************************
Main_Prg
	bsr Initialize_Scene

Next_Frame
	btst #6,ciaapra				bouton gauche de la souris
	beq.s user_exit

	bsr Flip_Screen
	bsr Compute_Scene_Matrix
	bsr Find_Visible_Objects
	bsr Objects_Sorting
	bsr Display_Scene
	bra.s Next_Frame

user_exit
	rts



********************************************************************************
*****************                                               ****************
*****************  ECHANGE DES COPLISTS ET EFFACAGE DE L'ECRAN  ****************
*****************                                               ****************
********************************************************************************
Flip_Screen
	tst.w BlankLeft				attend la fin du BlankLimit
	bpl.s Flip_Screen

	move.l log_coplist(pc),cop1lc(a6)	installe la coplist physique
	movem.l log_coplist(pc),a1-a2/a3-a4
	exg a1,a2				échange les coplist  A B => B A
	exg a3,a4				échange les écrans   A B => A B
	movem.l a1-a2/a3-a4,log_coplist-db(a5)

	move.w scn_BlankLimit(pc),BlankLeft-db(a5)
	lea coplist2_colors-coplist2(a1),a1	installe les couleurs de
	lea scn_ColorMap(pc),a2			la scène
	moveq #NB_COLORS-1,d0
.put_color
	move.w (a2)+,(a1)
	addq.l #4,a1
	dbf d0,.put_color
	
	WAIT_BLITTER
	move.l a3,bltdpt(a6)			éfface le log_screen
	move.l #$01000000,bltcon0(a6)		bltcon0 & bltcon1
	move.w #SCREEN_MOD,bltdmod(a6)		modulo de l'écran
	move.l #(SCREEN_Y*SCREEN_DEPTH)<<16!(SCREEN_X/16),bltsizV(a6)
	rts



********************************************************************************
****************                                               *****************
****************        CALCUL DE LA MATRICE DE ROTATION       *****************
****************                 POUR LA SCENE                 *****************
****************                                               *****************
********************************************************************************
Compute_Scene_Matrix
	movem.w scn_Alpha(pc),d0/d1/d2		scn_Alpha,scn_Teta,scn_Phi
	neg.w d0				\  c'est tout le décor qui
	neg.w d1				 > bouge !!!!!!!
	neg.w d2				/
	lea Scene_Matrix(pc),a0
	bra Compute_Matrix



********************************************************************************
****************                                               *****************
****************         RECHERCHE DES OBJECTS VISIBLES        *****************
**************** en sortie : les objects visibles sont trouvés *****************
****************                                               *****************
********************************************************************************
Find_Visible_Objects
	move.l #ListObjects+l_List,ListObjects_Ptr-db(a5)
	clr.w ListObjects+l_Quantity-db(a5)

	move.l scn_ListObjects(pc),d7
	beq.s no_find
	movem.w scn_PosX(pc),d0/d1		coordonnées de l'observateur
	move.w d0,d2				fabrication d'une boite
	add.w #VISIBLE_DISTANCE,d2		de visibilité
	move.w d1,d3
	add.w #VISIBLE_DISTANCE,d3
	sub.w #VISIBLE_DISTANCE,d0
	sub.w #VISIBLE_DISTANCE,d1
loop_find_visible
	move.l d7,a0
	sf obj_Visible(a0)			object non visible pour l'instant

	cmp.w obj_PosX(a0),d0			borne gauche de la boite
	bgt.s not_visible
	cmp.w obj_PosX(a0),d2			borne droite de la boite
	blt.s not_visible
	cmp.w obj_PosY(a0),d1			borne basse de la boite
	bgt.s not_visible
	cmp.w obj_PosY(a0),d3			borne haute de la boite
	blt.s not_visible

	st obj_Visible(a0)			l'object est visible
	bsr Rotate_Object			rotate l'object
	bsr Sort_Elements			trie ses Elements
	bsr Elements_Sorting
not_visible
	move.l obj_Next(a0),d7			object suivant
	bne.s loop_find_visible
no_find
	rts



********************************************************************************
******************                                            ******************
******************     ROTATION D'UN OBJECT PAR RAPPORT A     ******************
******************    LA SCENE +  PROJECTION DE SES POINTS    ******************
****************** en entrée : a0=*Object                     ******************
****************** en sortie : a0=*Object                     ******************
******************                                            ******************
********************************************************************************
Rotate_Object
	move.l a0,-(sp)

	movem.w obj_Alpha(a0),d0/d1/d2		calcule la matrice de rotation
	lea Object_Matrix(pc),a0		pour l'object
	bsr Compute_Matrix

	move.l (sp),a2
	lea obj_ListDots(a2),a0			ptr sur la liste de points
	move.l obj_Buffer2dDots(a2),a1		on stocke les points 2D (X&Y) ici
	movem.w obj_PosX(a2),a3/a4/a5		position dans la scène
	sub.w scn_PosX(pc),a3
	sub.w scn_PosY(pc),a4
	sub.w scn_PosZ(pc),a5
	lea Z_Buffer(pc),a2			on stocke les coords Z ici
	lea 0.w,a6				profondeur de l'object
	move.w (a0)+,d0				ld_Quantity : nombre de points-1
	moveq #9,d7				D pour projection=$200 ( SHIFT )

**** OPTIMISER CETTE ROUTINE EN ENTRELACANT LES MOVE REGS AVEC LES MOVE MEMS
loop_compute_dots
	movem.w (a0)+,d1/d2/d3			coord 3d du point

	move.w d1,d4				=> d1=X   d2=Y   d3=Z
	move.w d2,d5				\
	move.w d3,d6				/ => d4=X   d5=Y   d6=Z

	muls.w Object_Matrix(pc),d1		ROTATION DE L'OBJECT SUR
	muls.w Object_Matrix+2(pc),d2		LUI MEME
	muls.w Object_Matrix+4(pc),d3
	add.l d3,d2
	add.l d2,d1
	swap d1					X

	move.w d4,d2
	move.w d5,d3
	muls.w Object_Matrix+6(pc),d2
	muls.w Object_Matrix+8(pc),d3
	add.l d3,d2
	move.w d6,d3
	muls.w Object_Matrix+10(pc),d3
	add.l d3,d2
	swap d2					Y

	muls.w Object_Matrix+12(pc),d4
	muls.w Object_Matrix+14(pc),d5
	muls.w Object_Matrix+16(pc),d6
	add.l d6,d5
	add.l d5,d4
	swap d4					Z

	add.w a3,d1				repositionne l'object dans
	add.w a4,d2				la scène
	add.w a5,d4

	move.w d4,d3				=> d1=X   d2=Y   d3=Z
	move.w d1,d5				\
	move.w d2,d6				/ => d4=Z   d5=X   d6=Y

	muls.w Scene_Matrix(pc),d1		ROTATION DE L'OBJECT PAR
	muls.w Scene_Matrix+2(pc),d2		RAPPORT A LA SCENE
	muls.w Scene_Matrix+4(pc),d3
	add.l d3,d2
	add.l d2,d1
	swap d1					X
	ext.l d1
	lsl.l d7,d1				normalement ASL mais bon...

	move.w d5,d2
	move.w d6,d3
	muls.w Scene_Matrix+12(pc),d2
	muls.w Scene_Matrix+14(pc),d3
	add.l d3,d2
	move.w d4,d3
	muls.w Scene_Matrix+16(pc),d3
	add.l d3,d2
	swap d2					Z
	ext.l d2
	lsl.l d7,d2				idem...

	muls.w Object_Matrix+6(pc),d5
	muls.w Object_Matrix+8(pc),d6
	muls.w Object_Matrix+10(pc),d4
	add.l d4,d6
	add.l d6,d5
	swap d5					Y
	add.w #SCENE_DIST,d5

	beq.s no_divs
	divs d5,d1				Xe=X*D/Z
	divs d5,d2				Ye=Y*D/Z
no_divs
	add.w #SCREEN_X/2,d1			recentre à l'écran
	add.w #SCREEN_Y/2,d2

	move.w d1,(a1)+				sauve les coords X et Y
	move.w d2,(a1)+
	move.w d5,(a2)+				sauve Z
	
	add.w d5,a6				pour calculer la profondeur
	dbf d0,loop_compute_dots		moyenne

	move.l a6,d0				calcule la profondeur moyenne
	move.l (sp)+,a0				de l'object
	ext.l d0
	divs obj_ListDots(a0),d0
	move.w d0,obj_Depth(a0)

	lea db(pc),a5
	lea custom_base,a6

	move.l ListObjects_Ptr(pc),a1		sauve le ptr de l'object
	move.l a0,(a1)+
	addq.w #1,ListObjects+l_Quantity-db(a5)
	addq.l #4,ListObjects_Ptr-db(a5)
	rts	



********************************************************************************
************                                                         ***********
************  CALCULE LE MILIEU DES ELEMENTS POUR POUVOIR LES TRIER  ***********
************ en entrée : a0=*Object                                  ***********
************ en sortie : les profondeurs sont calculées              ***********
************                                                         ***********
********************************************************************************
Sort_Elements
	move.l obj_ListElements(a0),a1		ptr sur la liste des elements
	lea Z_Buffer(pc),a2			ptr sur les Z des points
	move.w (a1)+,d0				nb d'élément-1 : l_Quantity
loop_compute_middle
	move.l (a1)+,a3				ptr sur un Element
	move.w elmt_Type(a3),d1			recherche le type de l'élément
	beq.s middle_face			TYPE_FACE ?
	dbf d0,loop_compute_middle		Element inconnu...
	rts

middle_face
	movem.w face_Dot1(a3),d2/d3/d4/d5
	move.w (a2,d2.w*2),d1
	add.w (a2,d3.w*2),d1
	add.w (a2,d4.w*2),d1
	add.w (a2,d5.w*2),d1
	asr.w #2,d1				divise par 4
	move.w d1,elmt_Depth(a3)
	dbf d0,loop_compute_middle
	rts


********************************************************************************
**************                                                     *************
**************  TRIE LES ELEMENTS POUR AVOIR UN AFFICHAGE CORRECT  *************
************** en entrée : a0=*Object                              *************
************** en sortie : les éléments sont triés                 *************
**************                                                     *************
********************************************************************************
Elements_Sorting
	move.l obj_ListElements(a0),a1
	move.w (a1)+,d0				nb d'éléments-1 : le_Quantity

big_loop_sort_element
	subq.w #1,d0				on trie tjs sur N+1
	blt.s end_sort_elements
	move.w d0,d1				nb d'élément à trier
	move.l a1,a2				*element
	moveq #0,d2				la marque
loop_sort_element
	move.l (a2)+,a3				*element1
	move.w elmt_Depth(a3),d3		profondeur élément 1
loop_sort_element_second
	move.l (a2),a4				*element2
	cmp.w elmt_Depth(a4),d3			element2<element1
	bge.s element_ok
	move.l a4,-4(a2)			échange les ptrs
	move.l a3,(a2)+
	addq.w #1,d2				signale le changement
	dbf d1,loop_sort_element_second
	bra.s big_loop_sort_element
element_ok
	dbf d1,loop_sort_element
	tst.w d2
	bne.s big_loop_sort_element
end_sort_elements
	rts	



********************************************************************************
**************                                                     *************
**************  TRIE LES OBJECTS POUR AVOIR UN AFFICHAGE CORRECT   *************
************** en sortie : les éléments sont triés                 *************
**************                                                     *************
********************************************************************************
Objects_Sorting
	lea ListObjects(pc),a0
	move.w (a0)+,d0				nb d'objects : l_Quantity

big_loop_sort_objects
	subq.w #1,d0				on trie tjs sur N+1
	blt.s end_sort_objects
	move.w d0,d1				nb d'objects à trier
	move.l a0,a1				*Object
	moveq #0,d2				la marque
loop_sort_objects
	move.l (a1)+,a2				*Object1
	move.w obj_Depth(a2),d3			profondeur Object 1
loop_sort_objects_second
	move.l (a1),a3				*Object2
	cmp.w obj_Depth(a3),d3			Object2<Object1
	bge.s objects_ok
	move.l a3,-4(a1)			échange les ptrs
	move.l a3,(a1)+
	addq.w #1,d2				signale le changement
	dbf d1,loop_sort_objects_second
	bra.s big_loop_sort_element
objects_ok
	dbf d1,loop_sort_objects
	tst.w d2
	bne.s big_loop_sort_objects
end_sort_objects
	rts	



********************************************************************************
**************                                                     *************
**************  AFFICHAGE DE LA SCENE SUIVANT LA LISTE D'OBJECTS   *************
************** en sortie : la scène est affichée                   *************
**************                                                     *************
********************************************************************************
Display_Scene
	pea ListObjects+l_List(pc)
	move.l ListObjects-2(pc),-(sp)		ListObject_Nb dans mot faible
	bra.s start_display_objects
loop_display_objects
	move.l (a4)+,a3				*Object
	movem.l d7/a4,-(sp)
	move.l obj_ListElements(a3),a0		pointeur sur liste d'éléments
	move.l obj_Buffer2dDots(a3),a1		pointeur sur points 2D
	move.w (a0)+,d7				Nb d'éléments-1
loop_display_elements
	move.l (a0)+,a2				pointeur sur élément
	move.w elmt_Type(a2),d6			type d'élément
	beq draw_face				TYPE_FACE ?
	dbf d7,loop_display_elements
start_display_objects
	movem.l (sp)+,d7/a4
	dbf d7,loop_display_objects
	rts




********************************************************************************
******************                                       ***********************
******************  AFFICHAGE D'UN ELEMENT DE TYPE FACE  ***********************
******************                                       ***********************
********************************************************************************
draw_face
	movem.l d7/a0-a1,-(sp)			sauve ptr element etc..

*--------------------> calcule le produit vectoriel pour Z
	movem.w face_Dot1(a2),d0/d2/d4		3 points de la face
	movem.w (a1,d0.w*4),d0/d1		d0=X1   ,   d1=Y1
	movem.w (a1,d2.w*4),d2/d3		d2=X2   ,   d3=Y2
	movem.w (a1,d4.w*4),d4/d5		d4=X3   ,   d5=Y3
	sub.w d0,d2				(x2-x1)
	sub.w d1,d5				(y3-y1)
	muls d5,d2				(x2-x1)*(y3-y1)
	sub.w d0,d4				(x3-x1)
	sub.w d1,d3				(y2-y1)
	muls d4,d3				(x3-x1)*(y2-y1)
	moveq #0,d0				offset couleur
	cmp.l d3,d2				(x2-x1)*(y3-y1)<(x3-x1)*(y2-y1)?
	beq no_face_at_all			pas de face si =0
	blt.s .front_color			<0 => couleur front
	moveq #4,d0				>0 => couleur back
.front_color
	move.w face_FrontColor1(a2,d0.w),FaceColor-db(a5)
	blt no_face_at_all			si <0 pas de face

*--------------------> à partir d'ici la face existe et a sa propre couleur
	clr.l max_X-db(a5)		init quelques données
	move.l #$7fff7fff,min_X-db(a5)

	movem.w face_Dot1(a2),d0/d2
	movem.w (a1,d0.w*4),d0-d1		X1,Y1
	movem.w (a1,d2.w*4),d2-d3		X2,Y2
	bsr Draw_Clipped_Line

	movem.w face_Dot2(a2),d0/d2
	movem.w (a1,d0.w*4),d0-d1		X1,Y1
	movem.w (a1,d2.w*4),d2-d3		X2,Y2
	bsr Draw_Clipped_Line

	movem.w face_Dot3(a2),d0/d2
	movem.w (a1,d0.w*4),d0-d1		X1,Y1
	movem.w (a1,d2.w*4),d2-d3		X2,Y2
	bsr Draw_Clipped_Line

	move.w face_Dot4(a2),d0
	move.w face_Dot1(a2),d2
	movem.w (a1,d0.w*4),d0-d1		X1,Y1
	movem.w (a1,d2.w*4),d2-d3		X2,Y2
	bsr Draw_Clipped_Line

	rts
*----------------------> encadre l'objet qui se trouve dans le scratch screen
	tst.w VisibleLines_Quantity(pc)		ya qqchose ??
	beq no_face_at_all

	lea Table_Mulu(pc),a0
	move.w max_Y(pc),d0
	add.w d0,d0
	move.w (a0,d0.w),d0			mulu #SCREEN_X/8,d0
	move.w max_X(pc),d1
	lsr.w #3,d1				adr en octet
	and.w #$fffe,d1				pointe des mots
	add.w d1,d0
	move.l log_screen(pc),a0
	lea (a0,d0.w),a0			ptr sur destination
	lea scratch_screen,a1
	lea (a1,d0.w),a1			ptr source

	move.w min_X(pc),d2
	lsr.w #3,d2				adr en octet
	and.b #$fe,d2				pointe des mots
	sub.w d2,d1				max_X-min_X  ( en octets )
	addq.w #2,d1
	move.w d1,d3				sauve largeur en octets
	sub.w #SCREEN_X/8,d3
	neg.w d3				modulo des ptr blitter

	move.w max_Y(pc),d2
	sub.w min_Y(pc),d2
	addq.w #1,d2
	lsl.w #6,d2
	lsr.w #1,d1				taille en mots
	or.w d2,d1				bltsize
	
*--------------------------> rempli le scratch screen
	WAIT_BLITTER
	moveq #-1,d0
	move.l d0,bltafwm(a6)			masque sur A
	move.l a1,bltapt(a6)			source=scratch
	move.l a1,bltdpt(a6)			destination=scratch
	move.w d3,bltamod(a6)
	move.w d3,bltbmod(a6)
	move.w d3,bltdmod(a6)	
	move.l #$09f0000a,bltcon0(a6)		In-fill et descending, D=A
	move.w d1,bltsize(a6)			lance le blitter

*--------------------------> recopie du scratch dans les bpl
	move.w FaceColor(pc),d2			couleur de la face
	moveq #SCREEN_DEPTH-1,d0
	bra.s put_face_start
loop_put_face
	lea (SCREEN_X/8)*SCREEN_Y(a0),a0
put_face_start
	WAIT_BLITTER
	lsr.w #1,d2				sort un bit
	bcc.s clear_face
	move.l a1,bltapt(a6)			source A=scratch
	move.l a0,bltbpt(a6)			source B=bpl
	move.l a0,bltdpt(a6)			destination=bpl
	move.l #$0dfc0002,bltcon0(a6)		mode descending, D=A or B
	move.w d1,bltsize(a6)
	dbf d0,loop_put_face
	bra.s clear_scratch	
clear_face
	move.l a1,bltapt(a6)
	move.l a0,bltbpt(a6)	
	move.l a0,bltdpt(a6)
	move.l #$0d0c0002,bltcon0(a6)		mode descending, D=(not A) or B
	move.w d1,bltsize(a6)
	dbf d0,loop_put_face

clear_scratch
	WAIT_BLITTER
	move.l a1,bltdpt(a6)			destination=scratch
	move.l #$01000002,bltcon0(a6)		mode decending, D=0
	move.w d1,bltsize(a6)

no_face_at_all
	movem.l (sp)+,d7/a0-a1			ptr displayer
	dbf d7,loop_display_elements
	movem.l (sp)+,d7/a4
	dbf d7,loop_display_objects
	rts


************************
* TRACAGE D'UNE DROITE *
************************
Draw_Clipped_Line
*---------------------> on clippe la droite
	cmp.w d2,d0
	ble.s .x1_less_x2
	exg d0,d2
	exg d1,d3
.x1_less_x2
	cmp.w #SCREEN_X,d2
	blt.s .no_inter_X_max
	cmp.w #SCREEN_X,d0
	bge line_face_unvisible

*---------------> clip suivant les X avec le bord droit ( Xmax )
	move.w #SCREEN_X-1,d4
	sub.w d2,d4				(D-X2)
	move.w d3,d5				sauve Y2
	sub.w d1,d3				(Y2-Y1)
	muls d4,d3				(Y2-Y1)*(D-X2)
	sub.w d0,d2				(X2-X1)
	divs d2,d3				(Y1-Y2)*(D-X2)/(X1-X2)
	add.w d5,d3				(Y1-Y2)*(D-X2)/(X1-X2)+Y2
	move.w #SCREEN_X-1,d2			X2=SCREEN_X-1

.no_inter_X_max
	tst.w d0
	bge.s .no_inter_X_min
	tst.w d2
	blt line_face_unvisible

*---------------> clip suivant les X avec le bord gauche ( Xmin )
	sub.w d3,d1				(Y1-Y2)
	muls d2,d1				(Y1-Y2)*(X2-0)
	neg.l d1				(Y1-Y2)*(0-Y2)
	sub.w d2,d0				(X2-X1)
	divs d0,d1				(Y1-Y2)*(0-Y2)/(X2-X1)
	add.w d3,d1				Y1=(Y1-Y2)*(0-Y2)/(X2-X1)+Y2
	moveq #0,d0				X1=0

	cmp.w min_X(pc),d0		encadrement à gauche
	bge.s .no_inter_X_min
	move.w d0,min_X-db(a5)

.no_inter_X_min
	cmp.w d3,d1
	ble.s .y1_less_y2
	exg d0,d2
	exg d1,d3
.y1_less_y2
	tst.w d1
	bge.s .no_inter_Y_min
	tst.w d3
	blt line_face_unvisible	

*---------------> clip suivant les Y avec le haut ( Ymin )
	move.w d0,d4				sauve X1
	sub.w d2,d0				(X1-X2)
	muls d1,d0				(0-Y1)*(X2-X1)
	sub.w d3,d1				(Y1-Y2)
	neg.w d1				(Y2-Y1)
	divs d1,d0				(0-Y1)*(X2-X1)/(Y2-Y1)
	add.w d4,d0				(0-Y1)*(X2-X1)/(Y2-Y1)+X1
	moveq #0,d1				Y1=0

.no_inter_Y_min
	cmp.w #SCREEN_Y,d3
	blt.s .no_inter_Y_max
	cmp.w #SCREEN_Y,d1
	bge line_face_unvisible

*---------------> clip suivant les Y avec le bas ( Ymax )
	move.w #SCREEN_Y-1,d4
	sub.w d1,d4				(D-Y1)
	sub.w d0,d2				(X2-X1)
	muls d4,d2				(D-Y1)*(X2-X1)
	sub.w d1,d3				(Y2-Y1)
	divs d3,d2				(D-Y1)*(X2-X1)/(Y2-Y1)
	add.w d0,d2				(D-Y1)*(X2-X1)/(Y2-Y1)+X1
	move.w #SCREEN_Y-1,d3

.no_inter_Y_max
	addq.w #1,VisibleLines_Quantity-db(a5)	droite visible

*--------------------> encadrement de la face
	move.w d0,d4
	move.w d2,d5

	cmp.w d5,d4
	ble.s d4_le_d5
	exg d4,d5
d4_le_d5
	cmp.w min_X(pc),d4
	bgt.s d4_gt
	move.w d4,min_X-db(a5)
d4_gt
	cmp.w max_X(pc),d5
	blt.s d5_lt
	move.w d5,max_X-db(a5)
d5_lt
	cmp.w min_Y(pc),d1
	bgt.s d1_gt
	move.w d1,min_Y-db(a5)
d1_gt
	cmp.w max_Y(pc),d3
	blt.s d3_lt
	move.w d3,max_Y-db(a5)
d3_lt
*--------------------> tracage de la face
;	lea scratch_screen,a0
	move.l log_screen(pc),a0
Draw_3D_Line
	sub.w d0,d2				d2=deltaX
	sub.w d1,d3				d3=deltaY
	beq.s .no_line
	subq.w #1,d3

	moveq #0,d4
	ror.w #4,d0				\
	move.b d0,d4				 > d0=décalage
	and.w #$f000,d0				/

	add.w d4,d4				d4=adr en octets sur X
	add.w d1,d1				d1=d1*2 car table de mots
	add.w Table_Mulu(pc,d1.w),d4		d4=d1*Width+d4
	lea 0(a0,d4.w),a0			recherche 1er mot de la droite
	move.w d0,d4				sauvegarde du décalage
	or.w #$0b4a,d4				minterm=$4a  EOR
.find_octant	
	moveq #0,d1
	tst.w d2
	bpl.s .X1_inf_X2
	neg.w d2
	moveq #4,d1
.X1_inf_X2
	cmp.w d2,d3
	bpl.s .DY_sup_DX
	or.b #16,d1
	bra.s .octant_found
.DY_sup_DX
	exg d2,d3
	add.b d1,d1
.octant_found

	addq.b #3,d1				LINE + ONEDOT
	or.w d0,d1				rajoute le décalage
	
	add.w d3,d3				4*Pdelta
	add.w d3,d3
	add.w d2,d2				2*Gdelta

	WAIT_BLITTER

	move.w d3,bltbmod(a6)
	sub.w d2,d3				4*Pdelta-2*Gdelta
	bge.s .no_SIGNFLAG
	or.w #$40,d1
.no_SIGNFLAG
	move.w d1,bltcon1(a6)
	move.w d3,bltapt+2(a6)
	sub.w d2,d3				4*Pdelta-4*Gdelta
	move.w d3,bltamod(a6)

	move.w d4,bltcon0(a6)

	move.l a0,bltcpt(a6)			\ pointeur sur 1er mot droite
	move.l a0,bltdpt(a6)			/

	addq.w #1<<1,d2				(Gdelta+1)<<1
	lsl.w #5,d2				(Gdelta+1)<<6
	addq.w #2,d2				(Gdelta+1)<<6+2
	move.w d2,bltsize(a6)			traçage de la droite
.no_line
line_face_unvisible
	rts

Table_Mulu
MuluCount set 0
	rept SCREEN_Y
	dc.w MuluCount*(SCREEN_X/8)
MuluCount set MuluCount+1
	endr



********************************************************************************
********************                                     ***********************
********************     INITIALISATION D'UNE SCENE      ***********************
******************** en sortie : les objects sont ok     ***********************
********************                                     ***********************
********************************************************************************
Initialize_Scene
	move.l scn_ListObjects(pc),d0
	beq.s no_init
init_objects
	move.l d0,a0
	bset #FLGB_INITIALIZED,obj_Flags(a0)
	bne.s no_ExtraInit

	move.l obj_OriginalElements(a0),a1	duplique les éléments de
	move.l obj_ListElements(a0),a2		l'object pour pouvoir
	move.w (a1)+,d0				réutiliser plusieurs fois la
	move.w d0,(a2)+				même ListElements
.dup	move.l (a1)+,(a2)+
	dbf d0,.dup

	move.l obj_ExtraInit(a0),d0		init l'objet s'il y a
	beq.s no_ExtraInit			lieu d'être
	move.l d0,a1
	jsr (a1)				a0=*Object
no_ExtraInit
	move.l obj_Next(a0),d0			object suivant
	bne.s init_objects
no_init
	rts



********************************************************************************
********************                                     ***********************
********************  CALCUL D'UNE MATRICE DE ROTATION   ***********************
******************** en entrée : d0=Alpha d1=Teta d2=Phi ***********************
********************             a0=Matrice              ***********************
******************** en sortie : la matrice est calculée ***********************
********************                                     ***********************
********************************************************************************
cosalpha equr d0				qq equr pour se simplifier
sinalpha equr d1				la lecture
costeta  equr d2
sinteta  equr d3
cosphi   equr d4
sinphi   equr d5

Compute_Matrix
	lea Table_Sinus(pc),a1			table de WORD
	lea Table_Cosinus(pc),a2

	move.w (a1,d2.w*2),sinphi		sinus phi
	move.w (a2,d2.w*2),cosphi		cosinus phi

	move.w (a1,d1.w*2),sinteta		sinus teta
	move.w (a2,d1.w*2),costeta		cosinus teta

	move.w (a1,d0.w*2),sinalpha		sinus alpha
	move.w (a2,d0.w*2),cosalpha		cosinus alpha

	move.w costeta,d6
	muls cosphi,d6				cos(teta) * cos(phi)
	add.l d6,d6
	swap d6
	move.w d6,(a0)

	move.w costeta,d6
	muls sinphi,d6				cos(teta) * sin(phi)
	add.l d6,d6
	swap d6
	move.w d6,2(a0)

	move.w sinteta,d6
	neg.w d6
	move.w d6,4(a0)				-sin(teta)

	move.w costeta,d6
	muls sinalpha,d6			cos(teta) * sin(alpha)
	add.l d6,d6
	swap d6
	move.w d6,10(a0)

	move.w costeta,d6
	muls cosalpha,d6			cos(teta) * cos(alpha)
	add.l d6,d6
	swap d6
	move.w d6,16(a0)
	
	move.w sinalpha,d6
	muls sinteta,d6				sin(alpha) * sin(teta)
	add.l d6,d6
	swap d6
	move.w d6,a3

	muls cosphi,d6				sin(alpha)*sin(teta)*cos(phi)
	move.w cosalpha,d7
	muls sinphi,d7				cos(alpha) * sin(phi)
	sub.l d7,d6
	add.l d6,d6
	swap d6
	move.w d6,6(a0)

	move.w a3,d6
	muls sinphi,d6				sin(alpha)*sin(teta)*sin(phi)
	move.w cosalpha,d7
	muls cosphi,d7				cos(alpha) * cos(phi)
	add.l d7,d6
	add.l d6,d6
	swap d6
	move.w d6,8(a0)

	move.w cosalpha,d6
	muls sinteta,d6				cos(alpha) * sin(teta)
	add.l d6,d6
	swap d6
	move.w d6,a3

	muls cosphi,d6				cos(alpha)*sin(teta)*cos(phi)
	move.w sinalpha,d7
	muls sinphi,d7				sin(alpha) * sin(phi)
	add.l d7,d6
	add.l d6,d6
	swap d6
	move.w d6,12(a0)

	move.w a3,d6
	muls sinphi,d6				cos(alpha)*sin(teta)*sin(phi)
	move.w sinalpha,d7
	muls cosphi,d7				sin(alpha) * cos(phi)
	sub.l d7,d6
	add.l d6,d6
	swap d6
	move.w d6,14(a0)		
	rts



********************************************************************************
****************                                                ****************
****************  LA NOUVELLE INTERRUPTION DE NIVEAU 3 ( VBL )  ****************
****************                                                ****************
********************************************************************************
Vbl
	SAVE_REGS
	lea db(pc),a5
	lea custom_base,a6

	subq.w #1,BlankLeft-db(a5)		décrémente le BlankLimit

	move.w #$0020,intreq(a6)
	RESTORE_REGS
	rte



********************************************************************************
*************                                                        ***********
*************      TOUTES LES DATAS UTILES POUR LA 3D COMPLEXE       ***********
*************                                                        ***********
********************************************************************************
	CNOP 0,4
db:

log_coplist		dc.l coplist1
phy_coplist		dc.l coplist2
log_screen		dc.l screen1
phy_screen		dc.l screen2

BlankLeft		dc.w 0

ListObjects		dc.w 0
			dcb.l MAX_OBJECTS
ListObjects_Ptr		dc.l 0

Z_Buffer		dcb.w MAX_DOTS		profondeur des points projetés

Table_Sinus		incbin "Table_Sinus.DAT"
Table_Cosinus=Table_Sinus+90*8

Scene_Matrix		dcb.w 3*3,0
Object_Matrix		dcb.w 3*3,0

FaceColor		dc.w 0
min_X			dc.w 0
min_Y			dc.w 0
max_X			dc.w 0
max_Y			dc.w 0

VisibleLines_Quantity	dc.w 0


********************************************************************************
*************                                                        ***********
*************                   UNE SIMPLE SCENE                     ***********
*************                                                        ***********
********************************************************************************
scn_ListObjects		dc.l my_object1
scn_BlankLimit		dc.w 0
scn_PosX		dc.w 0
scn_PosY		dc.w 0
scn_PosZ		dc.w 200
scn_Alpha		dc.w 0
scn_Teta		dc.w 0
scn_Phi			dc.w 0
scn_ColorMap		dc.w $000,$00f,$0f0,$f00,$0ff,$f0f,$ff0,$fff

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
	ALLOC_ELEMENTS 1

my_object1_buffer_dots
	ALLOC_DOTS 4

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
	ALLOC_ELEMENTS 1

my_object2_buffer_dots
	ALLOC_DOTS 4

my_object2_elements
	dc.w 1-1
	dc.l my_object2_face

my_object2_face
	dc.w 0
	dc.w TYPE_FACE
	dc.w 2,2
	dc.w 5,5
	dc.w 0,1,2,3




********************************************************************************
*************                                                        ***********
*************         LES ECRANS ET LES COPLISTS QUI DOIVENT         ***********
*************                  ETRE EN CHIP_MEMORY                   ***********
*************                                                        ***********
********************************************************************************
	section bulle,data_c
coplist1
	dc.w fmode,$3
	dc.w diwstrt,$2b81
	dc.w diwstop,$2bc1
	dc.w ddfstrt,$0038
	dc.w ddfstop,$00a0
	dc.w bplcon0,(SCREEN_DEPTH<<12)|$200
	dc.w bplcon1,$0000
	dc.w bplcon2,$0000
	dc.w bpl1mod,$0000
	dc.w bpl2mod,$0000
coplist1_colors=*+2
color_start set color00
	rept NB_COLORS
	dc.w color_start,0
color_start set color_start+2
	endr
bpl_ptr1=*+2
bpl set bpl1ptH
	rept SCREEN_DEPTH
	dc.w bpl,0				bplH
	dc.w bpl+2,0				bplL
bpl set bpl+4
	endr
	dc.l $fffffffe

coplist2
	dc.w fmode,$3
	dc.w diwstrt,$2b81
	dc.w diwstop,$2bc1
	dc.w ddfstrt,$0038
	dc.w ddfstop,$00a0
	dc.w bplcon0,(SCREEN_DEPTH<<12)|$200
	dc.w bplcon1,$0000
	dc.w bplcon2,$0000
	dc.w bpl1mod,$0000
	dc.w bpl2mod,$0000
coplist2_colors=*+2
color_start set color00
	rept NB_COLORS
	dc.w color_start,0
color_start set color_start+2
	endr
bpl_ptr2=*+2
bpl set bpl1ptH
	rept SCREEN_DEPTH
	dc.w bpl,0				bplH
	dc.w bpl+2,0				bplL
bpl set bpl+4
	endr
	dc.l $fffffffe



	section screen,bss_c
screen1
	ds.b (SCREEN_X/8)*SCREEN_Y*SCREEN_DEPTH+8
screen2
	ds.b (SCREEN_X/8)*SCREEN_Y*SCREEN_DEPTH+8
scratch_screen
	ds.b (SCREEN_X/8)*SCREEN_Y
trame_screen
	ds.b (SCREEN_X/8)*SCREEN_Y
