*                      ________________________   __________________
*                     /                       /\ /                  \
*                    /                       /  Y                    \
*                   /_____________          /  /      __________      \
*                   \             \        /  /      /\         \      \
*                    \____________/       /  /      /  \_________\      \
*                                /       /  /      /   /          \      \
*                               /       /  /      /   /            \      \
*                              /       /  /      /   /             /      /\
*             ________________/       /  /      /   /             /      /  \ 
*            /                       /  /      /   /             /      /   /
*           /                       /  /      /   /             /      /   /
*          /_____________          /  /      /___/_____________/______/___/___
*          \             \        /  /      //                               /\
*           \____________/       /  /      //                               / /
*                       /       /  /      //__          ______          ___/ /
*                      /       /  /      / \_/         /\____/         /\__\/
*                     /       /  /      /   /         / / / /         / /
*    ________________/       /  /      /___/         / /_/ /         / /
*   /                       /  /          /         / /   /         / /
*  /                       /  /          /         / /   /         / /
* /_______________________/  /__________/         / /___/         / /
* \                       \  \         /         / /   /         / /
*  \_______________________\/ \_______/         / /___/         / /
*                                    /         / /   /         / /
*                                /¯¯¯          ¯¯¯¯¯¯          ¯¯/\
*     Sync of Dreamdealers      /                               / /
*     ====================     /_______________________________/ /
*                              \_______________________________\/
 




	incdir "asm:"
	incdir "asm:datas/"
	incdir "asm:sources/"
	incdir "asm:.S/3d_ComplexII/"

	include "registers.i"



********************************************************************************
******************                                           *******************
******************  DESCRIPTIONS DES DIFFERENTES STRUCTURES  *******************
******************                                           *******************
********************************************************************************
*--------------------------> Les differents types d'éléments disponibles
TYPE_FACE=0
TYPE_LINE=1
TYPE_DOT=2
TYPE_SPHERE=3

*--------------------------> Constantes
SCREEN_X=320
SCREEN_Y=256
SCREEN_DEPTH=3
NB_COLOR=1<<SCREEN_DEPTH
MAX_DOTS=200
VISIBLE_DISTANCE=1000*1000

*--------------------------> Macros
	IFNE 0
WAIT_BLITTER	macro
.wait_blitter\@
	btst #6,dmaconr(a6)
	bne.s .wait_blitter\@
	endm
	ENDC

*--------------------------> Flags pour les objets
FLGB_PRECALCULED=0
FLGF_PRECALCULED=1<<0
FLGB_VISIBLE=1
FLGF_VISIBLE=1<<1

*--------------------------> STRUCT Scene
	IFNE 0
Scene		rs.b 0
s_GlobalColors	rs.l 1			couleurs de la scene
s_BlankLimit	rs.w 1			BlankLimit de la scène
s_PosX		rs.w 1			\
s_PosY		rs.w 1			 | on regarde à partir d'ici
s_PosZ		rs.w 1			/
s_Alpha		rs.w 1			\
s_Teta		rs.w 1			 | et dans cette direction
s_Phy		rs.w 1			/
s_Quantity	rs.w 1			nombre d'objet dans la scène
s_List		rs.l 1			liste *Object
	ENDC

*--------------------------> STRUCT Object
	rsreset
Object		rs.b 0
o_Visible	rs.b 1			l'objet est visible -boolean-
o_Flags		rs.b 1			flags pour l'objet
o_Depth		rs.w 1			profondeur de l'objet
o_PosX		rs.w 1			position X dans la scène
o_PosY		rs.w 1			position Y dans la scène
o_PosZ		rs.w 1			position Z dans la scène
o_Alpha		rs.w 1			angle Alpha de l'objet
o_Teta		rs.w 1			angle Teta de l'objet
o_Phi		rs.w 1			angle Phi de l'objet
o_ExtraInit	rs.l 1			routine d'initialisation
o_ExtraAnim	rs.l 1			routine d'animation
o_ListDots	rs.l 1			*ListDots
o_ListElements	rs.l 1			*ListElements
o_BufferDots	rs.l 1			c là kon stocke les points 2D + Z

*--------------------------> STRUCT ListDots
	rsreset
ListDots	rs.b 0
ld_Quantity	rs.w 1			nb de point dans la structure
ld_List		rs.w 0			liste des coord X,Y,Z des points

ld_X=0
ld_Y=2
ld_Z=4

*--------------------------> STRUCT ListElements
	rsreset
ListElements	rs.b 0
le_Quantity	rs.w 1			nb d'élements dans la structure
le_List		rs.w 0			liste *Element

*--------------------------> STRUCT Element commune à tous les Elements
	rsreset
Element		rs.b 0
e_Depth		rs.w 1			profondeur de la structure
e_Type		rs.w 1			type de la structure
e_SIZEOF	rs.b 0

*--------------------------> STRUCT Face
	rsreset
Face		rs.b e_SIZEOF
f_FrontColor1	rs.w 1			couleur du front en tramée
f_FrontColor2	rs.w 1
f_BackColor1	rs.w 1			couleur du back en tramée
f_BackColor2	rs.w 1
f_Dot1		rs.w 1			4 points pour faire une Face
f_Dot2		rs.w 1			si 3 points seulement => f_Dot4=-1
f_Dot3		rs.w 1
f_Dot4		rs.w 1
f_List		rs.b 0			2 points pour une droite * face_nb_line

	IFNE 0
*--------------------------> STRUCT Line
	rsreset
Line		rs.b e_SIZEOF
l_Color		rs.w 1			couleur de la droite en tramée
l_Mask		rs.w 1			masque de la droite
l_Dot1		rs.w 1			1er point de la droite
l_Dot2		rs.w 1			2ème point de la droite

*--------------------------> STRUCT Dot
	rsreset
Dot		rs.b e_SIZEOF
d_Color		rs.w 1			couleur du point
d_Dot		rs.w 1			le point

*--------------------------> STRUCT Sphere
	rsreset
Sphere		rs.b e_SIZEOF
s_Color		rs.w 1			couleur de la sphere en tramée
s_Radius	rs.w 1			rayon de la sphere
s_Dot		rs.w 1			centre de la sphere
	ENDC







********************************************************************************
*****************************                   ********************************
*****************************  INITIALISATIONS  ********************************
*****************************                   ********************************
********************************************************************************
	section cacolac,code

	KILL_SYSTEM Entry_Point

Entry_Point
	lea data_base(pc),a5		\ Ces registres ne DOIVENT jamais
	lea custom_base,a6		/ être ré-assignés !!

	move.w #$7fff,d0		on vire tout
	move.w d0,intena(a6)
	move.w d0,dmacon(a6)
	
	move.l #screen1,d0		init ptr vidéos dans les coplists
	move.l #screen2,d1
	move.l #screen3,d2
	move.l #(SCREEN_X/8)*SCREEN_Y,d3
	moveq #SCREEN_DEPTH-1,d4
	lea bpl_ptr1,a0
	lea bpl_ptr2,a1
	lea bpl_ptr3,a2
	bra.s put_bpl_start
loop_put_bpl_ptr
	swap d0
	swap d1
	swap d2
	add.l d3,d0			next screen
	add.l d3,d1
	add.l d3,d2
	addq.l #8,a0			next ptr
	addq.l #8,a1
	addq.l #8,a2
put_bpl_start
	move.w d0,4(a0)			bplL
	move.w d1,4(a1)
	move.w d2,4(a2)
	swap d0
	swap d1
	swap d2
	move.w d0,(a0)			bplH
	move.w d1,(a1)
	move.w d2,(a2)
	dbf d4,loop_put_bpl_ptr

	lea trame_screen,a0		construit l'écran de trame
	move.l #$55555555,d0
	lea SCREEN_X/8(a0),a1
	move.l #$AAAAAAAA,d1
	move.w #SCREEN_Y/2-1,d2
build_trame_screen
	move.w #SCREEN_X/4-1,d3
build_trame_line
	move.l d0,(a0)+
	move.l d1,(a1)+
	dbf d3,build_trame_line
	move.l a1,a0
	lea (SCREEN_X/8)*2(a1),a1
	dbf d2,build_trame_screen

	move.l #vbl,$6c.w
	move.l #coplist1,cop1lc(a6)	installe une coplist
	clr.w copjmp1(a6)

	move.w #$87c0,dmacon(a6)	Pri ! Master ! Bpl ! Copper ! Blitter
	move.w #$c020,intena(a6)	it vbl | it copper

	bsr Main_Prg
	rte

********************************************************************************
****************************                       *****************************
****************************  PROGRAMME PRINCIPAL  *****************************
****************************                       *****************************
********************************************************************************
Main_Prg
	lea my_scene,a0
	bsr init_scene

Next_Frame
	btst #6,ciaapra			test de la souris
	beq user_exit

	bsr flip_screen
	move.w s_BlankLimit(pc),vbl_left-data_base(a5)
	bsr search_visible_object
	bsr rotate_visible_object

user_exit
	rts





********************************************************************************
*****************                                               ****************
*****************  ECHANGE DES COPLISTS ET EFFACAGE DE L'ECRAN  ****************
*****************                                               ****************
********************************************************************************
flip_screen
	tst.w vbl_left-data_base(a5)	attend la fin du BlankLimit
	bgt.s flip_screen

	WAIT_BLITTER
.wait_blitter
	btst #14,dmaconr(a6)		attend quand meme la fin du blitter...
	bne.s .wait_blitter

	movem.l log_coplist(pc),d0-d5
	exg d0,d1			échange les coplist
	exg d1,d2
	exg d3,d4			échange les écrans
	exg d4,d5
	movem.l d0-d5,log_coplist-data_base(a5)

	move.l d2,cop1lc(a6)		installe la coplist physique
	
	move.l d3,bltdpt(a6)		éfface le log_screen
	move.w #$0100,bltcon0(a6)	bltcon0
	clr.w bltcon1(a6)		mode copie
	clr.w bltdmod(a6)		pas de modulo
	move.w #((SCREEN_Y*SCREEN_DEPTH)&$3ff)<<6+(SCREEN_X/16),bltsize(a6)
	rts



********************************************************************************
********************                                     ***********************
********************     INITIALISATION D'UNE SCENE      ***********************
******************** en entrée : rien du tout            ***********************
******************** en sortie : les objects sont ok     ***********************
********************************************************************************
init_scene
	lea s_Quantity(pc),a0
	move.w (a0)+,d0
	bra.s start_init_objects
init_objects
	move.l (a0)+,a1
	bset #FLGB_PRECALCULED,o_Flags(a1)
	bne.s start_init_objects

	move.l o_ExtraInit(a1),d2		init l'objet s'il y a
	beq.s no_ExtraInit			lieu d'être
	move.l d2,a2
	movem.l d0/a0-a1,-(sp)
	jsr (a2)	
	movem.l (sp)+,d0/a0-a1
no_ExtraInit

	move.l o_ListElements(a1),a1		precalcule des mulu #6 sur
	move.w (a1)+,d1				les listes de points dans
	bra.s start_init_elements		les elements
init_elements
	move.l (a1)+,a2
	move.w e_Type(a2),d2
	cmp.w #TYPE_FACE,d2
	beq init_face
	cmp.w #TYPE_LINE,d2
	beq init_line
	cmp.w #TYPE_DOT,d2
	beq init_dot
	cmp.w #TYPE_SPHERE,d2
	beq init_sphere
start_init_elements
	dbf d1,init_elements
start_init_objects
	dbf d0,init_objects
	rts

init_face
	lea f_Quantity(a2),a2
	move.w (a2),d2				precalcule le dbf tant
	subq.w #1,d2				qu'on y est !!!
	move.w d2,(a2)+
loop_init_face
	movem.w (a2),d3-d4
	mulu #6,d3
	mulu #6,d4
	move.w d3,(a2)+
	move.w d4,(a2)+
	dbf d2,loop_init_face
	dbf d1,init_elements
	dbf d0,init_objects
	rts

init_line
	movem.w l_Dot1(a2),d2-d3
	mulu #6,d2
	mulu #6,d3
	movem.w d2-d3,l_Dot1(a2)
	dbf d1,init_elements
	dbf d0,init_objects
	rts

init_dot
	move.w d_Dot(a2),d2
	mulu #6,d2
	move.w d2,d_Dot(a2)
	dbf d1,init_elements
	dbf d0,init_objects
	rts

init_sphere
	move.w s_Dot(a2),d2
	mulu #6,d2
	move.w d2,s_Dot(a2)
	dbf d1,init_elements
	dbf d0,init_objects
	rts



********************************************************************************
********************                                       *********************
********************  ROUTINE QUI REGARDE SI UN OBJET EST  *********************
******************** DANS UN CERTAIN PERIMETRE PAR RAPPORT *********************
********************           A  L'OBSERVATEUR            *********************
******************** en entrée : rien du tout              *********************
******************** en sortie : le plus gros a été viré   *********************
********************************************************************************
search_visible_objects
	movem.w s_PosX(pc),d0-d2
	lea s_Quantity(pc),a0
	move.w (a0)+,d7			nombre d'object
	bra.s start_search_visible
loop_search_visible_object
	move.l (a0)+,a1			choppe un object
	movem.w o_PosX(a1),d3-d5	coordonnée de l'objet
	sub.w d0,d3			calcul la distance an carré de
	sub.w d1,d4			l'observateur à l'objet
	sub.w d2,d5
	muls d3,d3
	muls d4,d4
	muls d5,d5
	add.l d5,d4
	add.l d4,d3
	cmp.l #VISIBLE_DISTANCE,d3	l'objet est visible ?
	slt o_Visible(a1)
start_search_visible
	dbf d0,loop_search_visible_object
	rts



********************************************************************************
********************                                     ***********************
********************  ROTATION DES OBJETS VISIBLES DANS  ***********************
******************** DANS LEUR REPERE + REPOSITIONEMENT  ***********************
******************** en entrée : rien du tout            ***********************
******************** en sortie : les points sont rotés   ***********************
********************                                     ***********************
********************************************************************************
rotate_visible_objects
	lea s_Quantity(pc),a0
	move.w (a0)+,d0
	bra.s start_rotate_visible
loop_rotate_visible
	move.l (a0)+,a4
	tst.b o_Visible(a4)			on le rotate ??
	beq start_rotate

	movem.l d0/a0/a4,-(sp)
	movem.w o_Alpha(a4),d0-d2		\ fabrication de la matrice
	bsr compute_matrix			/ de rotation dans son repère
	move.l a4,a0
	bsr rotate_dots				fait tourner l'objet
	movem.l (sp)+,d0/a0/a4

start_rotate_visible
	dbf d0,loop_rotate_visible
	rts



********************************************************************************
********************                                     ***********************
********************  CALCUL DE LA MATRICE DE ROTATION   ***********************
******************** en entrée : d0=Alpha d1=Teta d2=Phi ***********************
******************** en sortie : la matrice est calculée ***********************
********************                                     ***********************
********************************************************************************
cosalpha equr d0				qq equr pour se simplifier
sinalpha equr d1				la lecture
costeta  equr d2
sinteta  equr d3
cosphi   equr d4
sinphi   equr d5

compute_matrix
	lea Table_Cosinus(pc),a0
	lea Table_Sinus(pc),a1

	move.w 0(a1,d2.w),sinphi		sinus phi
	move.w 0(a0,d2.w),cosphi		cosinus phi

	move.w 0(a1,d1.w),sinteta		sinus teta
	move.w 0(a0,d1.w),costeta		cosinus teta

	move.w 0(a1,d0.w),sinalpha		sinus alpha
	move.w 0(a0,d0.w),cosalpha		cosinus alpha

	lea matrix(pc),a0

	move.w costeta,d6
	muls cosphi,d6				cos(teta) * cos(phi)
	swap d6
	move.w d6,(a0)

	move.w costeta,d6
	muls sinphi,d6				cos(teta) * sin(phi)
	swap d6
	move.w d6,2(a0)

	move.w sinteta,d6
	neg.w d6
	asr.w #1,d6				on perd un bit à cause du swap
	move.w d6,4(a0)				-sin(teta)

	move.w costeta,d6
	muls sinalpha,d6			cos(teta) * sin(alpha)
	swap d6
	move.w d6,10(a0)

	move.w costeta,d6
	muls cosalpha,d6			cos(teta) * cos(alpha)
	swap d6
	move.w d6,16(a0)
	
	move.w sinalpha,d6
	muls sinteta,d6				sin(alpha) * sin(teta)
	swap d6
	rol.l #1,d6
	move.w d6,a3

	muls cosphi,d6				sin(alpha)*sin(teta)*cos(phi)
	move.w cosalpha,d7
	muls sinphi,d7				cos(alpha) * sin(phi)
	sub.l d7,d6
	swap d6
	move.w d6,6(a0)

	move.w a3,d6
	muls sinphi,d6				sin(alpha)*sin(teta)*sin(phi)
	move.w cosalpha,d7
	muls cosphi,d7				cos(alpha) * cos(phi)
	add.l d7,d6
	swap d6
	move.w d6,8(a0)

	move.w cosalpha,d6
	muls sinteta,d6				cos(alpha) * sin(teta)
	swap d6
	rol.l #1,d6
	move.w d6,a3

	muls cosphi,d6				cos(alpha)*sin(teta)*cos(phi)
	move.w sinalpha,d7
	muls sinphi,d7				sin(alpha) * sin(phi)
	add.l d7,d6
	swap d6
	move.w d6,12(a0)

	move.w a3,d6
	muls sinphi,d6				cos(alpha)*sin(teta)*sin(phi)
	move.w sinalpha,d7
	muls cosphi,d7				sin(alpha) * cos(phi)
	sub.l d7,d6
	swap d6
	move.w d6,14(a0)		

	rts

matrix	dcb.w 3*3,0				la matrice de rotation
Table_Cosinus
	incbin "table_cosinus_360.dat"
Table_Sinus=Table_Cosinus+90*2


********************************************************************************
*************                                                        ***********
************* ROTATION DES POINTS A PARTIR DE LA MATRICE DE ROTATION ***********
************* en entrée : a0=*Object                                 ***********
************* en sortie : les points sont rotés                      ***********
*************                                                        ***********
********************************************************************************
rotate_dots
	movem.w o_PosX(a0),a2-a4		coord de l'objet dans la scène
	lea o_BufferDots(a0),a1			c là kon va écrire les points 2D
	move.l o_ListDots(a0),a0		pointe la liste de points
	move.w (a0)+,d0				nombre de points
	moveq #9,d7				D=facteur d'agrandissement
	bra.s .start_compute_dots

.loop_compute_dots
	movem.w (a0),d1-d3			coord 3d du point
	muls matrix(pc),d1
	muls matrix+2(pc),d2
	muls matrix+4(pc),d3
	add.l d3,d2
	add.l d2,d1
	swap d1					X dans (0,0,0)
	add.w a2,d1				X+PosX dans la scène

	movem.w (a0),d2-d4			coord 3d du point
	muls matrix+6(pc),d2
	muls matrix+8(pc),d3
	muls matrix+10(pc),d4
	add.l d4,d3
	add.l d3,d2
	swap d2					Y dans (0,0,0)
	add.w a3,d2				Y=Y+PosY dans la scène

	movem.w (a0)+,d3-d5			coord 3d du point
	muls matrix+12(pc),d3
	muls matrix+14(pc),d4
	muls matrix+16(pc),d5
	add.l d5,d4
	add.l d4,d3
	swap d3					Z dans (0,0,0)
	add.w a4,d3				Z=Z+PosZ+Zoom dans la scène
	move.w d1,(a1)+				sauve Xr,Yr,Zr
	move.w d2,(a1)+
	move.w d3,(a1)+
.start_compute_dots
	dbf d0,.loop_compute_dots	
	rts	



********************************************************************************
*************                                                        ***********
*************  TRANSFORMATIONS DES COORDONNEES 3D EN COORDONNEES 2D  ***********
************* en entrée : a0=*Object                                 ***********
************* en sortie : les points sont rotés et projetés + Z      ***********
*************                                                        ***********
********************************************************************************
project_dots
	movem.w o_PosX(a0),a2-a4		coord de l'objet dans la scène
	add.w o_Zoom(a0),a4			zoom de l'objet
	lea o_BufferDots(a0),a1			c là kon va écrire les points 2D
	move.l o_ListDots(a0),a0		pointe la liste de points
	move.w (a0)+,d0				nombre de points
	moveq #9,d7				D=facteur d'agrandissement
	bra.s .start_compute_dots

.loop_compute_dots
	movem.w (a0),d1-d3			coord 3d du point
	muls matrix(pc),d1
	muls matrix+2(pc),d2
	muls matrix+4(pc),d3
	add.l d3,d2
	add.l d2,d1
	swap d1					X dans (0,0,0)
	add.w a2,d1				X+PosX dans la scène
	ext.l d1
	lsl.l d7,d1				X=X*D

	movem.w (a0),d2-d4			coord 3d du point
	muls matrix+6(pc),d2
	muls matrix+8(pc),d3
	muls matrix+10(pc),d4
	add.l d4,d3
	add.l d3,d2
	swap d2					Y dans (0,0,0)
	add.w a3,d1				Y=Y+PosY dans la scène
	ext.l d2
	lsl.l d7,d2				Y=Y*D

	movem.w (a0)+,d3-d5			coord 3d du point
	muls matrix+12(pc),d3
	muls matrix+14(pc),d4
	muls matrix+16(pc),d5
	add.l d5,d4
	add.l d4,d3
	swap d3					Z dans (0,0,0)
	add.w a4,d3				Z=Z+PosZ+Zoom dans la scène
	beq.s .no_divs
	divs d3,d1				Xe=X*D/Z
	divs d3,d2				Ye=Y*D/Z
.no_divs
	add.w #SCREEN_X/2,d1			recentre à l'écran
	add.w #SCREEN_Y/2,d2
	move.w d1,(a1)+				sauve Xe,Ye
	move.w d2,(a1)+
	move.w d3,(a1)+				sauve Z
.start_compute_dots
	dbf d0,.loop_compute_dots	
	rts	



********************************************************************************
************                                                         ***********
************  CALCULE LE MILIEU DES ELEMENTS POUR POUVOIR LES TRIER  ***********
************  en entrée : a0=*Object                                 ***********
************  en sortie : Toutes les profondeurs sont calculées      ***********
************                                                         ***********
********************************************************************************
compute_middle
	lea o_BufferDots(a0),a1			ptr sur la liste de points
	move.l o_ListElements(a0),a0		ptr sur la liste des elements

	move.w (a0)+,d0				nb d'éléments
	bra.s .start_compute_middle
	subq.w #1,d0				à cause du dbf
.loop_compute_middle
	move.l (a0)+,a2				pointe un élément
	move.w e_Type(a2),d1			recherche le type de l'élément
	cmp.w #TYPE_FACE,d1
	beq.s .middle_face
	cmp.w #TYPE_LINE,d1
	beq.s .middle_line
	cmp.w #TYPE_DOT,d1
	beq.s .middle_dot
	cmp.w #TYPE_SPHERE,d1
	beq.s .middle_sphere
.start_compute_middle
	dbf d0,.loop_compute_middle
	rts

.middle_face
	lea f_Quantity(a2),a3
	move.w (a3)+,d1				d1=f_Quantity  a3=f_List
	move.w d1,d2				sauve le nb de droite
	moveq #0,d3				profondeur
	addq.w #1,d2				à cause du dbf precalculé
.loop_middle_face
	move.w (a3)+,d4
	add.w ld_Z(a1,d4.w),d3			ajoute Z
	dbf d1,.loop_middle_face
	ext.l d3
	divs d2,d3				divise par le nb de face
	move.w d3,e_Depth(a2)
	dbf d0,.loop_compute_middle
	rts

.middle_line
	movem.w l_Dot1(a2),d1-d2
	move.w ld_Z(a1,d1.w),d1			Z1
	add.w ld_Z(a1,d2.w),d1			Z1+Z2
	lsr.w #1,d1				(Z1+Z2)/2
	move.w d1,e_Depth(a2)
	dbf d0,.loop_compute_middle
	rts

.middle_dot
	move.w d_Dot(a2),d1			met la profondeur du point
	move.w ld_Z(a1,d1.w),e_Depth(a2)
	dbf d0,.loop_compute_middle
	rts

.middle_sphere
	move.w s_Dot(a2),d1			met la profondeur de la sphere
	move.w ld_Z(a1,d1.w),e_Depth(a2)
	dbf d0,.loop_compute_middle
	rts



********************************************************************************
**************                                                    **************
**************  TRIE LES ELEMENTS D'UN OBJET SUIVANT UN Z BUFFER  **************
**************  en entrée : a0=*Object                            **************
**************  en sortie : les éléments sont triés               **************                                                  **************
********************************************************************************
sort_element
	move.l o_ListElements(a0),a0		a0=*ListElement
	move.w (a0)+,d0				d0=le_Quantity  a0=le_List
	subq.w #1,d0				à cause du dbf

.big_loop_sort_element
	subq.w #1,d0				on trie tjs sur N+1
	blt.s .end_sort
	move.w d0,d1				nb d'élément à trier
	move.l a0,a1				*element
	moveq #0,d2				la marque
.loop_sort_element
	move.l (a1)+,a2				*element1
	move.w e_Depth(a2),d3			profondeur élément 1
.loop_sort_element_second
	move.l (a1),a3				*element2
	cmp.w e_Depth(a3),d3			element2<element1
	bge.s .element_ok
	move.l a3,-4(a1)			échange les ptrs
	move.l a2,(a1)+
	addq.w #1,d2				signale le changement
	dbf d1,.loop_sort_element_second
	bra.s .big_loop_sort_element
.element_ok
	dbf d1,.loop_sort_element
	tst.w d2
	bne.s .big_loop_sort_element
.end_sort
	rts	



********************************************************************************
***************                                                    *************
***************  AFFICHAGE DES ELEMENTS DU PLUS LOIN AU PLUS PRES  *************
***************  en entrée : a0=*Object                            *************
***************  en sortie : koi ya rien à l'écran ???!! gasp..    *************                                                  *************
********************************************************************************
display_element
	lea o_BufferDots(a0),a1			pointe les points 2D
	move.l o_ListElements(a0),a0
	move.w (a0)+,d7				nb d'élément à afficher
	subq.w #1,d7				à cause du dbf
loop_display_element
	move.l (a0)+,a2				pointeur sur élément
	move.w e_Type(a2),d6			type d'élément
	cmp.w #TYPE_FACE,d6
	beq draw_face
;	cmp.w #TYPE_LINE,d6
;	beq draw_line
;	cmp.w #TYPE_DOT,d6
;	beq draw_dot
;	cmp.w #TYPE_SPHERE,d6
;	beq draw_sphere
start_display_element
	dbf d7,loop_display_element
	rts




********************************************************************************
******************  AFFICHAGE D'UN ELEMENT DE TYPE FACE  ***********************
********************************************************************************
draw_face
	movem.l d7/a0-a1,-(sp)			sauve ptr element etc..

*--------------------> calcule le produit vectoriel pour Z
	lea f_List(a2),a3
	movem.w (a3),d0/d2			\ 3 points de la face
	move.w 6(a3),d4				/
	movem.w ld_X(a1,d0.w),d0-d1		d0=X1   ,   d1=Y1
	movem.w ld_X(a1,d2.w),d2-d3		d2=X2   ,   d3=Y2
	movem.w ld_X(a1,d4.w),d4-d5		d4=X3   ,   d5=Y3
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
	moveq #2,d0				>0 => couleur back
.front_color
	move.w f_FrontColor(a2,d0.w),FaceColor-data_base(a5)
	blt no_face_at_all			si <0 pas de face

*--------------------> à partir d'ici la face existe et a sa propre couleur
	clr.l max_X-data_base(a5)		init quelques données
	move.l #$7fff7fff,min_X-data_base(a5)
	clr.w VisibleLines_Quantity-data_base(a5)	rien pour l'instant
	clr.w RightDots_Quantity-data_base(a5)

	lea f_Quantity(a2),a3
	move.w (a3)+,d7				nb de droite à clipper-1
	lea RightDots(pc),a4			ptr buffer right point

loop_clip_all_line
	movem.w (a3)+,d0/d2			2 points pour une droite
	movem.w ld_X(a1,d0.w),d0-d1		X1,Y1
	movem.w ld_X(a1,d2.w),d2-d3		X2,Y2

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

	move.w d3,(a4)+					sauve le Y clippé
	addq.w #1,RightDots_Quantity-data_base(a5)	on a clippé !!

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

	cmp.w min_X-data_base(a5),d0		encadrement à gauche
	bge.s .no_inter_X_min
	move.w d0,min_X-data_base(a5)

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
	addq.w #1,VisibleLines_Quantity-data_base(a5)	droite visible

*--------------------> encadrement de la face
	move.w d0,d4
	move.w d2,d5

	cmp.w d5,d4
	ble.s d4_le_d5
	exg d4,d5
d4_le_d5
	cmp.w min_X(pc),d4
	bgt.s d4_gt
	move.w d4,min_X-data_base(a5)
d4_gt
	cmp.w max_X(pc),d5
	blt.s d5_lt
	move.w d5,max_X-data_base(a5)
d5_lt
	cmp.w min_Y(pc),d1
	bgt.s d1_gt
	move.w d1,min_Y-data_base(a5)
d1_gt
	cmp.w max_Y(pc),d3
	blt.s d3_lt
	move.w d3,max_Y-data_base(a5)
d3_lt
*--------------------> tracage de la face
	bsr Draw3dLine
line_face_unvisible
	dbf d7,loop_clip_all_line

*---------------> on trie les right droites s'il le faut
sort_right_line
	move.w RightDots_Quantity(pc),d0	nb de RightDots
	beq no_right_line

one_line_at_least
	subq.w #1,d0				à cause du dbf
	lea RightDots(pc),a2			pointe début de la table
big_loop_sort_right_coord
	subq.w #1,d0				on trie sur N+1
	blt.s sort_right_coord_end
	move.w d0,d1				nb d'élément à trier
	move.l a2,a3				*element
	moveq #0,d2				la marque
loop_sort_right_coord
	move.w (a3)+,d3				coord1
loop_sort_right_coord_second
	cmp.w (a3),d3				coord1<=coord2 ?
	ble.s right_ok
	move.w (a3),-2(a3)			échange les coord
	move.w d3,(a3)+
	addq.w #1,d2				signale le changement
	dbf d1,loop_sort_right_coord_second
	bra.s big_loop_sort_right_coord
right_ok
	dbf d1,loop_sort_right_coord
	tst.w d2
	bne.s big_loop_sort_right_coord
sort_right_coord_end

*----------------------> on affiche les right lines
	move.w RightDots_Quantity(pc),d7	nb de RightDots
	lsr.w #1,d7				divise par 2 car paires
	subq.w #1,d7				à cause du dbf

	move.w #SCREEN_X-1,d6
loop_draw_right_line
	movem.w (a2)+,d1/d3			clip le haut
	tst.w d1
	bge.s .ok1
	tst.w d3
	blt no_right_line_this_time
	moveq #0,d1
.ok1
	cmp.w #SCREEN_Y,d3			clip le bas
	blt.s .ok2
	cmp.w #SCREEN_Y,d1
	bge no_right_line
	move.w #SCREEN_Y-1,d3
.ok2
	addq.w #1,VisibleLines_Quantity-data_base(a5)
	move.w #SCREEN_X-1,max_X-data_base(a5)	une droite à droite !!
	move.w d6,d0
	move.w d6,d2
	bsr Draw3dLine
no_right_line_this_time
	dbf d7,loop_draw_right_line

no_right_line
*----------------------> encadre l'objet qui se trouve dans le scratch screen
	tst.w VisibleLines_Quantity-data_base(a5)	ya qqchose ??
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
.fill_init
	btst #14,dmaconr(a6)
	bne.s .fill_init

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
	dbf d7,loop_display_element
	rts




********************************************************************************
*************                                                        ***********
************* ROUTINE DE TRACE DE DROITE POUR LA 3D ( TEC LINEDRAW ) ***********
*************  MODIFIEE POUR TRACER DIRECTEMENT DANS SCRATCH_SCREEN  ***********
*************                                                        ***********
********************************************************************************
;		  LINEDRAW ROUTINE FOR USE WITH FILLING:
; Preload:  d0=X1  d1=Y1  d2=X2  d3=Y2  a6=$dff000
; $dff060=Screenwidth (word)  $dff072=-$8000   (longword)  $dff044=-1 (longword)
; d0-d5 trashed

Draw3dLine
	cmp.w d1,d3
	bgt.s .line1
	beq .out
	exg d0,d2
	exg d1,d3
.line1	move.w d1,d4
	muls #(SCREEN_X/8)*SCREEN_DEPTH,d4
	move.w d0,d5
	add.l #scratch_screen,d4
	asr.w #3,d5
	add.w d5,d4
	moveq #0,d5
	sub.w d1,d3
	sub.w d0,d2
	bpl.s .line2
	moveq #1,d5
	neg.w d2
.line2	move.w d3,d1
	add.w d1,d1
	cmp.w d2,d1
	dbhi d3,.line3
.line3	move.w d3,d1
	sub.w d2,d1
	bpl.s .line4
	exg d2,d3
.line4	addx.w d5,d5
	add.w d2,d2
	move.w d2,d1
	sub.w d3,d2
	addx.w d5,d5
	and.w #15,d0
	ror.w #4,d0
	or.w #$a4a,d0
.line5	btst #14,dmaconr(a6)
	bne.s .line5
	move.w d2,bltapt(a6)
	sub.w d3,d2
	lsl.w #6,d3
	addq.w #2,d3
	move.w d0,bltcon0(a6)
	move.b .oct(pc,d5.w),bltcon1+1(a6)
	move.l d4,bltcpt(a6)
	move.l d4,bltdpt(a6)
	movem.w d1/d2,bltbmod(a6)
****
	move.w #(SCREEN_X/8)*SCREEN_DEPTH,bltcmod(a6)
	move.l #-$8000,bltbdat(a6)
	move.l #-1,bltafwm(a6)
****
	move.w d3,bltsize(a6)
.out	rts
.oct	dc.l $3431353,$b4b1757



********************************************************************************
****************                                                ****************
****************  LA NOUVELLE INTERRUPTION DE NIVEAU 3 ( VBL )  ****************
****************                                                ****************
********************************************************************************
vbl
	movem.l d0-d7/a0-a6,-(sp)		joue la musique

	lea data_base(pc),a5
	lea custom_base,a6

	subq.w #1,vbl_left-data_base(a5)
	move.w #$0020,intreq(a6)
	movem.l (sp)+,d0-d7/a0-a6
	rte



********************************************************************************
*************                                                        ***********
*************      TOUTES LES DATAS UTILES POUR LA 3D COMPLEXE       ***********
*************                                                        ***********
********************************************************************************
data_base:
Scene
s_GlobalColors	dc.l 0			couleurs de la scene
s_BlankLimit	dc.w 0			BlankLimit de la scène
s_PosX		dc.w 0			\
s_PosY		dc.w 0			 | on regarde à partir d'ici
s_PosZ		dc.w 0			/
s_Alpha		dc.w 0			\
s_Teta		dc.w 0			 | et dans cette direction
s_Phy		dc.w 0			/
s_Quantity	dc.w 0			nombre d'objet dans la scène
s_List		dc.l 0			liste *Object

current_scene		dc.l 0
log_coplist		dc.l coplist1
temp_coplist		dc.l coplist2
phy_coplist		dc.l coplist3
log_screen		dc.l screen1
temp_screen		dc.l screen2
phy_screen		dc.l screen3
vbl_left		dc.w 0

FaceColor		dc.w 0
VisibleLines_Quantity	dc.w 0
RightDots_Quantity	dc.w 0
RightDots		dcb.w MAX_DOTS,0
min_X			dc.w 0
min_Y			dc.w 0
max_X			dc.w 0
max_Y			dc.w 0

Table_Mulu
dummy set 0
	rept SCREEN_Y
	dc.w dummy*(SCREEN_Y/8)*SCREEN_DEPTH
dummy set dummy+1
	endr



********************************************************************************
*************                                                        ***********
*************                     UN OBJET 3D                        ***********
*************                                                        ***********
********************************************************************************
	include "Object_Test.s"



********************************************************************************
*************                                                        ***********
*************         LES ECRANS ET LES COPLISTS QUI DOIVENT         ***********
*************                  ETRE EN CHIP_MEMORY                   ***********
*************                                                        ***********
********************************************************************************
	section bulle,data_c
coplist1
	dc.w diwstrt,$2b81
	dc.w diwstop,$2bc1
	dc.w ddfstrt,$0038
	dc.w ddfstop,$00d0
	dc.w bplcon0,(SCREEN_DEPTH<<12)|$200
	dc.w bplcon1,$0000
	dc.w bplcon2,$0000
	dc.w bpl1mod,$0000
	dc.w bpl2mod,$0000
coplist1_color=*+2
color_start set color00
	rept NB_COLOR
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
	dc.w diwstrt,$2b81
	dc.w diwstop,$2bc1
	dc.w ddfstrt,$0038
	dc.w ddfstop,$00d0
	dc.w bplcon0,(SCREEN_DEPTH<<12)|$200
	dc.w bplcon1,$0000
	dc.w bplcon2,$0000
	dc.w bpl1mod,$0000
	dc.w bpl2mod,$0000
coplist2_color=*+2
color_start set color00
	rept NB_COLOR
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

coplist3
	dc.w diwstrt,$2b81
	dc.w diwstop,$2bc1
	dc.w ddfstrt,$0038
	dc.w ddfstop,$00d0
	dc.w bplcon0,(SCREEN_DEPTH<<12)|$200
	dc.w bplcon1,$0000
	dc.w bplcon2,$0000
	dc.w bpl1mod,$0000
	dc.w bpl2mod,$0000
coplist3_color=*+2
color_start set color00
	rept NB_COLOR
	dc.w color_start,0
color_start set color_start+2
	endr
bpl_ptr3=*+2
bpl set bpl1ptH
	rept SCREEN_DEPTH
	dc.w bpl,0				bplH
	dc.w bpl+2,0				bplL
bpl set bpl+4
	endr
	dc.l $fffffffe

	section screen,bss_c
screen1
	ds.b (SCREEN_X/8)*SCREEN_Y*SCREEN_DEPTH
screen2
	ds.b (SCREEN_X/8)*SCREEN_Y*SCREEN_DEPTH
screen3
	ds.b (SCREEN_X/8)*SCREEN_Y*SCREEN_DEPTH
scratch_screen
	ds.b (SCREEN_X/8)*SCREEN_Y
trame_screen
	ds.b (SCREEN_X/8)*SCREEN_Y
