
*		       ________________________   __________________
*		      /  __                   /\ /  __              \
*	             /  /                    /  Y  /                 \
*	            /_____________	    /  /      __________      \
*	            \		  \	   /  /      /\         \      \
*	             \____________/	  /  /      /  \_________\	\
*			         /	 /  /      /   /	  \      \
*			        /       /  /      /   /            \      \
*			       /       /  /	 /   /	           /      /\
*	      ________________/	      /  /	/   /		  /      /  \ 
*	     /  __		     /  /      /   /	         /	/   /
*	    /  /		    /  /      /   /		/      /   /
*	   /_____________	   /  /      /   /	       /      /   /
*	   \		 \        /  /      /	/	      /      /   /
*	    \____________/       /  /      /   /	     /      /   /
*			/       /  /	  /   /		    /      /   /
*		       /       /  /	 /   /	           /      /   /
*		      /       /  /	/   /		  /	 /   /
*    ________________/       /  /      /___/_____________/	/   /
*   /  __                   /  /                               /   /
*  /  /                    /  /                               /   /
* /_______________________/  /_______________________________/   /
* \                       \  \                               \  /
*  \_______________________\/ \_______________________________\/
*
*
*

*		3d avec des objects complexes	YEAHHHHHHHHH!!!
*		-----------------------------
*		=====> Trie des surfaces avec le Z-buffer + produit vectoriel


* NOTE:	Dans la matrice de rotation,
*	lorsqu'il y a un MULS -> SWAP	--> perte du bit faible
*	Sinon on fait un ASR.W		--> perte du bit faible également
*
*	Dans la partie 2d -> 3d, on fait un SWAP sur le résultat
*	-> perte de 1 bit
*
*	Résultat des courses : on perd 2 bits sur le résultat final
*	-> parfaitement négligeable  coord/4
*
* FIN DE NOTE




********************************************************************************
******************                                           *******************
******************  DESCRIPTIONS DES DIFFERENTES STRUCTURES  *******************
******************                                           *******************
********************************************************************************
	rsreset
object		rs.b 0
zoom		rs.w 1			zoom de l'objet
ExtraInit	rs.l 1			routine d'initialisation
ExtraJump	rs.l 1			routine d'animation
ObjectColor	rs.l 1			table de couleur
list_dots	rs.l 1			ptr sur la table de points
list_elements	rs.l 1			ptr sur la table d'elements
PosX		rs.w 1			position X sur l'écran
PosY		rs.w 1			position Y sur l'écran
Alpha		rs.w 1			angle alpha
Teta		rs.w 1			angle teta
Phi		rs.w 1			angle phi
BlankLimit	rs.w 1			affichage toutes les n vbl

*--------------------------> structure dots
	rsreset
dots		rs.b 0			structure de la table de points
nb_dots		rs.w 1			nb de point dans la structure
dots_coord	rs.w 0			liste des coord X,Y,Z des points

*--------------------------> les differents types d'éléments disponibles
TYPE_FACE=0
TYPE_LINE=1
TYPE_DOT=2
TYPE_SPHERE=3

*--------------------------> structure élément
	rsreset
elements	rs.b 0			structure de la table des éléments
nb_elements	rs.w 1			nb d'élements dans la structure
elements_ptr	rs.w 0			liste des ptr sur les éléments

	rsreset
element		rs.b 0			structure commune à tous les éléments
type		rs.w 1			type de la structure
depth		rs.w 1			profondeur de la structure
element_SIZEOF	rs.b 0

*--------------------------> structure d'une face
	rsreset
face			rs.b element_SIZEOF
face_front_color	rs.w 1		couleur du front
face_back_color		rs.w 1		couleur du back
face_nb_line		rs.w 1		nb de droites pour une face
face_line		rs.b 0		2 points pour une droite * face_nb_line

*--------------------------> structure d'une droite
	rsreset
line		rs.b element_SIZEOF
line_color	rs.w 1			couleur de la droite
line_line	rs.w 2			2 points pour la droite

*--------------------------> structure d'un point
	rsreset
dot		rs.b element_SIZEOF
dot_color	rs.w 1			couleur du point
dot_pos		rs.w 1			numéro du point

*--------------------------> structure d'une sphere
	rsreset
sphere		rs.b element_SIZEOF
sphere_color	rs.w 1			couleur de la sphere
sphere_radius	rs.w 1			rayon de la sphere
sphere_pos	rs.w 1			numero du point

*--------------------------> structure d'une table de transformation
	rsreset
tab_transf	rs.b 0
transf_total	rs.w 1
transf_dots	rs.b 0

*--------------------------> quelques constantes et macros
SCREEN_WIDTH=320
SCREEN_HEIGHT=256
SCREEN_DEPTH=3
NB_COLOR set 1
	rept SCREEN_DEPTH		calcule le nb de couleurs
NB_COLOR set NB_COLOR*2
	endr

	incdir "asm:"
	incdir "asm:sources/"
	incdir "asm:3d_Complex"
	incdir "asm:songs/small/"
	include "Registers.i"

	SET_OPTS


********************************************************************************
*****************************                   ********************************
*****************************  INITIALISATIONS  ********************************
*****************************                   ********************************
********************************************************************************
	section cacolac,code

	KILL_SYSTEM Entry_Point
	moveq #0,d0
	rts

Entry_Point
	lea data_base(pc),a5		\ Ces registres ne DOIVENT jamais
	lea $dff000,a6			/ être ré-assignés !!

	bsr mt_init

	move.l #screen1,d0		init ptr vidéos dans les coplists
	move.l #screen2,d1
	move.l #screen3,d2
	move.l #(SCREEN_WIDTH/8)*SCREEN_HEIGHT,d3
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

	move.l #vbl,$6c.w

	move.l #coplist1,cop1lc(a6)	installe une coplist
	clr.w copjmp1(a6)

	move.w #$87c0,dmacon(a6)	Pri ! Master ! Bpl ! Copper ! Blitter
	move.w #$c020,intena(a6)	it vbl | it copper



********************************************************************************
****************************                       *****************************
****************************  PROGRAMME PRINCIPAL  *****************************
****************************                       *****************************
********************************************************************************
	lea my_object(pc),a0
	move.l a0,current_object-data_base(a5)

	move.l ExtraInit(a0),d0		regarde s'il y a une ExtraInit
	beq.s no_ExtraInit
	move.l d0,a1
	jsr (a1)
no_ExtraInit
Next_Frame
	btst #2,potinp(a6)
	beq.s Next_Frame

	btst #6,ciaapra			test de la souris
	beq.s user_exit

	bsr.s flip_screen

	move.l current_object(pc),a0
	move.w BlankLimit(a0),vbl_left-data_base(a5)

	move.l ExtraJump(a0),d0		regarde s'il y a une ExtraJump
	beq.s no_ExtraJump
	move.l d0,a1
	jsr (a1)
no_ExtraJump
	move.l current_object(pc),a0
	move.l ObjectColor(a0),d0	regarde s'il y a une table des couleurs
	beq.s no_ObjectColor
	move.l d0,a1
	bsr Change_Color
no_ObjectColor
	bsr compute_matrix		calcule la matice de rotation
	bsr compute_dots		rotation + 3d -> 2d
	bsr compute_middle		calcule le milieu des éléments
	bsr sort_element		trie les éléments
	bsr display_element		affiche les éléments

	bra.s Next_Frame

user_exit
	bsr mt_end
	rte



********************************************************************************
****************                                                ****************
****************  LA NOUVELLE INTERRUPTION DE NIVEAU 3 ( VBL )  ****************
****************                                                ****************
********************************************************************************
vbl
	movem.l d0-d7/a0-a6,-(sp)		joue la musique
	bsr mt_music

	lea data_base(pc),a5
	lea $dff000,a6

	subq.w #1,vbl_left-data_base(a5)
	move.w #$0020,intreq(a6)
	movem.l (sp)+,d0-d7/a0-a6
	rte



********************************************************************************
*****************                                               ****************
*****************  ECHANGE DES COPLISTS ET EFFACAGE DE L'ECRAN  ****************
*****************                                               ****************
********************************************************************************
flip_screen
	tst.w vbl_left-data_base(a5)	attend la fin du BlankLimit
	bgt.s flip_screen

	WAIT_BLITTER
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
	move.w #((SCREEN_HEIGHT*SCREEN_DEPTH)&$3ff)<<6+(SCREEN_WIDTH>>4),bltsize(a6)
	rts

data_base:
log_coplist	dc.l coplist1
temp_coplist	dc.l coplist2
phy_coplist	dc.l coplist3
log_screen	dc.l screen1
temp_screen	dc.l screen2
phy_screen	dc.l screen3
vbl_left	dc.w 0



********************************************************************************
*********************                                    ***********************
*********************  CALCUL DE LA MATRICE DE ROTATION  ***********************
*********************                                    ***********************
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

	move.l current_object(pc),a2
	movem.w Alpha(a2),d0-d2			va chercher les angles

	move.w 0(a1,d2.w),sinphi		sinus phi
	neg.w sinphi
	move.w 0(a0,d2.w),cosphi		cosinus phi

	move.w 0(a1,d1.w),sinteta		sinus teta
	neg.w sinteta
	move.w 0(a0,d1.w),costeta		cosinus teta

	move.w 0(a1,d0.w),sinalpha		sinus alpha
	neg.w sinalpha
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



********************************************************************************
*************                                                        ***********
*************  TRANSFORMATIONS DES COORDONNEES 3D EN COORDONNEES 2D  ***********
*************                                                        ***********
********************************************************************************
compute_dots
	move.l current_object(pc),a0
	move.w zoom(a0),a3			le zoom sur l'objet
	lea PosX(a0),a4
	move.l list_dots(a0),a0			ptr sur liste des points
	move.w (a0)+,d0				nb de points
	subq.w #1,d0				à cause du dbf
	lea dots_2d(pc),a1			pointe les Xe et Ye
	lea dots_2d_Z(pc),a2			pointe les Z
	moveq #9,d7				D

loop_compute_dots
	movem.w (a0)+,d1/d2/d3			coord 3d du point

	move.w d1,d4				=> d1=X   d2=Y   d3=Z
	move.w d2,d5				\
	move.w d3,d6				/ => d4=X   d5=Y   d6=Z

	muls.w matrix(pc),d1		ROTATION DE L'OBJECT SUR
	muls.w matrix+2(pc),d2		LUI MEME
	muls.w matrix+4(pc),d3
	add.l d3,d2
	add.l d2,d1
	swap d1					X
	ext.l d1
	lsl.l d7,d1

	move.w d4,d2
	move.w d5,d3
	muls.w matrix+6(pc),d2
	muls.w matrix+8(pc),d3
	add.l d3,d2
	move.w d6,d3
	muls.w matrix+10(pc),d3
	add.l d3,d2
	swap d2					Y
	ext.l d2
	lsl.l d7,d2

	muls.w matrix+12(pc),d4
	muls.w matrix+14(pc),d5
	muls.w matrix+16(pc),d6
	add.l d6,d5
	add.l d5,d4
	swap d4					Z
	add.w a3,d4

	beq.s no_divs
	divs d4,d1				Xe=X*D/Z
	divs d4,d2				Ye=Y*D/Z
no_divs
	add.w PosX-PosX(a4),d1			recentre à l'écran
	add.w PosY-PosX(a4),d2
	move.w d1,(a1)+				sauve Xe,Ye
	move.w d2,(a1)+
	move.w d4,(a2)+				sauve Z

	dbf d0,loop_compute_dots	
	rts	



********************************************************************************
************                                                         ***********
************  CALCULE LE MILIEU DES ELEMENTS POUR POUVOIR LES TRIER  ***********
************                                                         ***********
********************************************************************************
compute_middle
	move.l current_object(pc),a0
	move.l list_elements(a0),a0		ptr sur la liste des elements
	move.l a0,a4				sauve le ptr sur les elements
	lea dots_2d_Z(pc),a3

	move.w (a0)+,d0				nb d'éléments
	subq.w #1,d0				à cause du dbf
loop_compute_middle
	move.l (a0)+,a1				pointe un élément
	move.w (a1),d1				recherche le type de l'élément
	cmp.w #TYPE_FACE,d1
	beq.s middle_face
	cmp.w #TYPE_LINE,d1
	beq.s middle_line
	cmp.w #TYPE_DOT,d1
	beq.s middle_dot

middle_sphere
	move.w sphere_pos(a1),d1		met la profondeur
	add.w d1,d1
	move.w 0(a3,d1.w),depth(a1)
	dbf d0,loop_compute_middle
	rts

middle_dot
	move.w dot_pos(a1),d1
	add.w d1,d1
	move.w 0(a3,d1.w),depth(a1)		met la profondeur
	dbf d0,loop_compute_middle
	rts

middle_line
	movem.w line_line(a1),d1-d2
	add.w d1,d1
	add.w d2,d2
	move.w 0(a3,d1.w),d1			Z1
	add.w 0(a3,d2.w),d1			Z1+Z2
	lsr.w #1,d1				(Z1+Z2)/2
	move.w d1,depth(a1)
	dbf d0,loop_compute_middle
	rts

middle_face
	move.w face_nb_line(a1),d1
	move.w d1,d4				sauve le nb de droite
	subq.w #1,d1				à cause de dbf
	moveq #0,d2				profondeur
	lea face_line(a1),a2			pointe descriptions droites
loop_middle_face
	move.w (a2)+,d3
	add.w d3,d3
	add.w 0(a3,d3.w),d2			ajoute Z
	dbf d1,loop_middle_face
	ext.l d2
	divs d4,d2				divise par le nb de face
	move.w d2,depth(a1)
	dbf d0,loop_compute_middle
	rts



********************************************************************************
**************                                                     *************
**************  TRIE LES ELEMENTS POUR AVOIR UN AFFICHAGE CORRECT  *************
**************                                                     *************
********************************************************************************
sort_element
	move.l a4,a0				ptr sur éléments
	move.w (a0)+,d0				nb d'éléments
	subq.w #1,d0				à cause du dbf

big_loop_sort_element
	subq.w #1,d0				on trie tjs sur N+1
	blt.s end_sort
	move.w d0,d1				nb d'élément à trier
	move.l a0,a1				*element
	moveq #0,d2				la marque
loop_sort_element
	move.l (a1)+,a2				*element1
	move.w depth(a2),d3			profondeur élément 1
loop_sort_element_second
	move.l (a1),a3				*element2
	cmp.w depth(a3),d3			element2<element1
	bge.s element_ok
	move.l a3,-4(a1)			échange les ptrs
	move.l a2,(a1)+
	addq.w #1,d2				signale le changement
	dbf d1,loop_sort_element_second
	bra.s big_loop_sort_element
element_ok
	dbf d1,loop_sort_element
	tst.w d2
	bne.s big_loop_sort_element
end_sort
	rts	



********************************************************************************
***************                                                    *************
***************  AFFICHAGE DES ELEMENTS DU PLUS LOIN AU PLUS PRES  *************
***************                                                    *************
********************************************************************************
display_element
	move.l a4,a0				pointeur sur élément
	move.w (a0)+,d7				nb d'élément à afficher
	subq.w #1,d7				à cause du dbf
	lea dots_2d(pc),a1			pointe la table des points 2d
loop_display_element
	move.l (a0)+,a2				pointeur sur élément
	move.w type(a2),d6			type d'élément
	cmp.w #TYPE_FACE,d6
	beq draw_face
	cmp.w #TYPE_LINE,d6
	beq draw_line
	cmp.w #TYPE_DOT,d6
	beq draw_dot


********************************************************************************
*******************  AFFICHAGE D'UN ELEMENT DE TYPE SPHERE  ********************
********************************************************************************
draw_sphere
	movem.l d7/a0-a1,-(sp)

	move.w sphere_color(a2),actual_face_color-data_base(a5)
	moveq #0,d1
	move.w sphere_radius(a2),d1		rayon de la sphere
	lsl.l #7,d1
	move.w depth(a2),d2
	beq.s .no_divs
	divs d2,d1
.no_divs
	cmp.w #2,d1				regarde si le rayon
	ble.s .no_circle_on_screen		n'est pas trop petit !!
	move.w sphere_pos(a2),d0
	add.w d0,d0				table de WORD
	add.w d0,d0				table de LONG
	movem.w 0(a1,d0.w),a1-a2		coord de la sphere

	move.w a1,d2				encadre le cercle pour le
	add.w d1,d2				remplissage
	blt.s .no_circle_on_screen		regarde si le cercle
	move.w a2,d3				est visible en plus
	add.w d1,d3
	blt.s .no_circle_on_screen
	cmp.w #SCREEN_WIDTH,d2
	blt.s .low1
	move.w #SCREEN_WIDTH-1,d2
.low1
	move.w d2,max_X-data_base(a5)
	cmp.w #SCREEN_HEIGHT,d3
	blt.s .low2
	move.w #SCREEN_HEIGHT-1,d3
.low2
	move.w d3,max_Y-data_base(a5)

	move.w a1,d2
	sub.w d1,d2
	blt.s .low3
	cmp.w #SCREEN_WIDTH,d2
	blt.s .good1
.no_circle_on_screen
	movem.l (sp)+,d7/a0-a1			routine éxécutée quand il
	dbf d7,loop_display_element		n'y a pas de cercle à l'écran
	rts
.low3
	moveq #0,d2
.good1
	move.w d2,min_X-data_base(a5)

	move.w a2,d2
	sub.w d1,d2
	blt.s .low4
	cmp.w #SCREEN_HEIGHT,d2
	blt.s .good2
	movem.l (sp)+,d7/a0-a1			pareil que
	dbf d7,loop_display_element		.no_circle_on_screen
	rts
.low4
	moveq #0,d2
.good2
	move.w d2,min_Y-data_base(a5)

*-----------------> on trace le cercle puisqu'il est visible
	lea scratch_screen,a0			bpl ou l'on va mettre la sphere

*-----------------> macro utilisée par la routine de tracé de cercle
put_pixel	macro			put_pixel X,Y,DeltaY
	move.w a1,d4			regarde si P1 est visible
	add.w \1,d4
	blt .no_dots			test à gauche pour P1
	move.w a2,d5
	add.w \2,d5
	blt .no_dots

	cmp.w #SCREEN_WIDTH*4,d4		test à droite pour P1
	bge.s .draw_left
	cmp.w #SCREEN_HEIGHT*4,d5
	bge .draw_top

.draw_right
	movem.w 0(a3,d4.w),d4/d6	P1 est visible
	add.w 2(a4,d5.w),d6
	bset d4,0(a0,d6.w)		point P1
	sub.w \3,d6			symetrie suivant Y  --  DeltaY
	blt.s .draw_right_left
	bset d4,0(a0,d6.w)		point P2

.draw_all
	move.w a1,d4
	sub.w \1,d4
	blt .no_dots
	movem.w 0(a3,d4.w),d4/d6
	add.w 2(a4,d5.w),d6
	bset d4,0(a0,d6.w)		point P4
	sub.w \3,d6			symetrie suivant Y  --  Delta Y
	bset d4,0(a0,d6.w)		point P3
	bra .no_dots

.draw_right_left
	move.w a1,d4
	sub.w \1,d4
	blt .no_dots
	movem.w 0(a3,d4.w),d4/d6
	add.w 2(a4,d5.w),d6
	bset d4,0(a0,d6.w)		point P4
	bra .no_dots

.draw_left
	move.w a1,d4
	sub.w \1,d4
	blt.s .draw_left_right
	cmp.w #SCREEN_WIDTH*4,d4
	bge .no_dots
	tst.w d5
	blt .no_dots
	cmp.w #SCREEN_HEIGHT*4,d5
	bge.s .draw_left_top
	movem.w 0(a3,d4.w),d4/d6
	move.w 2(a4,d5.w),d5
	add.w d5,d6
	bset d4,0(a0,d6.w)		point P4
	bset #0,(SCREEN_WIDTH/8)-1(a0,d5.w)	point à droite
	sub.w \3,d6
	sub.w \3,d5
	blt .no_dots
	bset d4,0(a0,d6.w)		point P3
	bset #0,(SCREEN_WIDTH/8)-1(a0,d5.w)	point à droite
	bra .no_dots

.draw_left_right
	tst.w d5
	blt .no_dots
	cmp.w #SCREEN_HEIGHT*4,d5
	bge.s .draw_left_right2
	move.w 2(a4,d5.w),d6
	bset #0,(SCREEN_WIDTH/8)-1(a0,d6.w)	point à droite
	sub.w \3,d6
	blt.s .no_dots
	bset #0,(SCREEN_WIDTH/8)-1(a0,d6.w)	point à droite
	bra.s .no_dots
.draw_left_right2
	move.w a2,d5
	sub.w \2,d5
	blt.s .no_dots
	cmp.w #SCREEN_HEIGHT*4,d5
	bge.s .no_dots
	move.w 2(a4,d5.w),d6
	bset #0,(SCREEN_WIDTH/8)-1(a0,d6.w)
	bra.s .no_dots

.draw_left_top
	move.w a2,d5
	sub.w \2,d5
	blt.s .no_dots
	cmp.w #SCREEN_HEIGHT*4,d5
	bge.s .no_dots
	movem.w 0(a3,d4.w),d4/d6
	move.w 2(a4,d5.w),d5
	add.w d5,d6
	bset d4,0(a0,d6.w)		point P3
	bset #0,(SCREEN_WIDTH/8)-1(a0,d5.w)	point à droite
	bra.s .no_dots

.draw_top
	move.w a2,d5
	sub.w \2,d5
	blt.s .no_dots
	cmp.w #SCREEN_HEIGHT*4,d5
	bge.s .no_dots
	movem.w 0(a3,d4.w),d4/d6
	add.w 2(a4,d5.w),d6
	bset d4,0(a0,d6.w)		point P2
	move.w a1,d4
	sub.w \1,d4
	blt.s .no_dots
	movem.w 0(a3,d4.w),d4/d6
	add.w 2(a4,d5.w),d6
	bset d4,0(a0,d6.w)		point P3
.no_dots
	endm				fin de la macro put_pixel

*------------------> la routine de tracé de cercle
draw_circle
	add.w a1,a1			4*Centre_X
	add.w a1,a1
	add.w a2,a2			4*Centre_Y
	add.w a2,a2

	lea tabX(pc),a3			ptr sur des tables
	lea tabY(pc),a4

	moveq #0,d7
	move.w d1,d7			sauve le rayon
	add.w d1,d1			2*R
	move.w d1,d0
	neg.w d0
	addq.w #3,d0			d0 => C:=3-2*R
	add.w d1,d1			d1 => X:=X*4
	moveq #0,d2			d2 => Y:=0
	move.w d1,d3			pour ne pas tracer 2 points sur 1 ligne
	mulu #(SCREEN_WIDTH/8)*2,d7	d7 => Delta Y coté YX
	sub.w a5,a5			a5 => Delta Y coté XY

	WAIT_BLITTER

loop_compute_circle
	cmp.w d1,d2			while X>Y do
	bgt fin_draw_circle
	cmp.w d1,d2			while X>Y do
	bgt fin_draw_circle
	put_pixel d1,d2,a5		pixel X,Y + symétries
symetrie_YX
	cmp.w d1,d3			c'est une autre ligne ?
	beq pas_YX
	put_pixel d2,d1,d7		pixel Y,X + symétries
pas_YX
	move.w d1,d3			sauvegarde le numéro de la ligne
	lea (SCREEN_WIDTH/8)*2(a5),a5	Delta Y coté XY
	tst.w d0			C<0 ?
	blt.s C_inf_0

C_pas_inf_0
	sub.w d1,d0
	add.w d2,d0
	add.w #10,d0			C:=C-4*X+4*Y+10
	sub.w #(SCREEN_WIDTH/8)*2,d7	Delta Y coté YX
	subq.w #4,d1			X:=X-1
	addq.w #4,d2			Y:=Y+1
	bra loop_compute_circle

C_inf_0
	add.w d2,d0
	addq.w #6,d0			C:=C+4*Y+6
	addq.w #4,d2			Y:=Y+1
	bra loop_compute_circle

fin_draw_circle
	lea data_base(pc),a5		on se branche sur la routine de
	bra fill_circle_branch		remplissage d'une face...Yo man !

tabX
mult set 0
	rept SCREEN_WIDTH
	dc.l ($f-mult&$f)<<16+mult/8
mult set mult+1
	endr

tabY
mult set 0
	rept SCREEN_HEIGHT
	dc.l mult*(SCREEN_WIDTH/8)
mult set mult+1
	endr


********************************************************************************
*******************  AFFICHAGE D'UN ELEMENT DE TYPE POINT  *********************
********************************************************************************
draw_dot
	move.w dot_pos(a2),d0			# du point
	add.w d0,d0
	add.w d0,d0
	movem.w 0(a1,d0.w),d0-d1		Xe,Ye

	tst.w d0				regarde si le point est visible
	blt.s dot_out_screen
	tst.w d1
	blt.s dot_out_screen
	cmp.w #SCREEN_WIDTH,d0
	bge.s dot_out_screen
	cmp.w #SCREEN_HEIGHT,d1
	bge.s dot_out_screen

	move.w dot_color(a2),d2			couleur du point
	move.l log_screen(pc),a2		ptr sur écran
	move.w d0,d3
	lsr.w #3,d0
	not.b d3				pout bset ou bclr
	lea Table_Mulu(pc),a4
	add.w d1,d1				table de WORD
	add.w 0(a4,d1.w),d0			X=X+Y*(SCREEN_WIDTH/8)
	lea 0(a2,d0.w),a2			pointe le point dans l'écran

	moveq #SCREEN_DEPTH-1,d1

	WAIT_BLITTER				on ne sait jamais !!
	bra.s display_dot_start
loop_display_dot
	lea (SCREEN_WIDTH/8)*SCREEN_HEIGHT(a2),a2
display_dot_start
	lsr.w #1,d2				fait sortir un bit de la couleur
	bcc.s clear_dot
	bset d3,(a2)
	dbf d1,loop_display_dot
dot_out_screen
	dbf d7,loop_display_element
	rts
clear_dot
	bclr d3,(a2)
	dbf d1,loop_display_dot
	dbf d7,loop_display_element
	rts


********************************************************************************
********************  AFFICHAGE D'UN ELEMENT DE TYPE DROITE  *******************
********************************************************************************
draw_line
	movem.w line_line(a2),d0/d2
	add.w d0,d0
	add.w d0,d0
	add.w d2,d2
	add.w d2,d2
	movem.w 0(a1,d0.w),d0-d1		X1,Y1
	movem.w 0(a1,d2.w),d2-d3		X2,Y2

	cmp.w d2,d0
	ble.s .x1_less_x2
	exg d0,d2
	exg d1,d3
.x1_less_x2
	tst.w d0
	bge.s .no_inter_X_min
	tst.w d2
	blt line_unvisible

*---------------> clip suivant les X avec le bord gauche ( Xmin )
	sub.w d3,d1				(Y1-Y2)
	muls d2,d1				(Y1-Y2)*(X2-0)
	neg.l d1				(Y1-Y2)*(0-X2)
	sub.w d2,d0				(X2-X1)
	divs d0,d1				(Y1-Y2)*(0-X2)/(X2-X1)
	add.w d3,d1				Y1=(Y1-Y2)*(0-X2)/(X2-X1)+Y2
	moveq #0,d0				X1=0

.no_inter_X_min
	cmp.w #SCREEN_WIDTH,d2
	blt.s .no_inter_X_max
	cmp.w #SCREEN_WIDTH,d0
	bge line_unvisible

*---------------> clip suivant les X avec le bord droit ( Xmax )
	move.w #SCREEN_WIDTH-1,d4
	sub.w d2,d4				(D-X2)
	move.w d3,d5				sauve Y2
	sub.w d1,d3				(Y2-Y1)
	muls d4,d3				(Y2-Y1)*(D-X2)
	sub.w d0,d2				(X2-X1)
	divs d2,d3				(Y1-Y2)*(D-X2)/(X1-X2)
	add.w d5,d3				(Y1-Y2)*(D-X2)/(X1-X2)+Y2
	move.w #SCREEN_WIDTH-1,d2		X2=SCREEN_WIDTH-1

.no_inter_X_max
	cmp.w d3,d1
	ble.s .y1_less_y2
	exg d0,d2
	exg d1,d3
.y1_less_y2
	tst.w d1
	bge.s .no_inter_Y_min
	tst.w d3
	blt line_unvisible	

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
	cmp.w #SCREEN_HEIGHT,d3
	blt.s .no_inter_Y_max
	cmp.w #SCREEN_HEIGHT,d1
	bge line_unvisible

*---------------> clip suivant les Y avec le bas ( Ymax )
	move.w #SCREEN_HEIGHT-1,d4
	sub.w d1,d4				(D-Y1)
	sub.w d0,d2				(X2-X1)
	muls d4,d2				(D-Y1)*(X2-X1)
	sub.w d1,d3				(Y2-Y1)
	divs d3,d2				(D-Y1)*(X2-X1)/(Y2-Y1)
	add.w d0,d2				(D-Y1)*(X2-X1)/(Y2-Y1)+X1
	move.w #SCREEN_HEIGHT-1,d3

.no_inter_Y_max
	move.l log_screen(pc),a3		* ecran

*-------------------------> routine qui précalcule les registres pour une droite
*-------------------------> line(d0,d1)-(d2,d3),a0
Draw_Normal_Line_Compute
	sub.w d0,d2				d2=deltaX
	sub.w d1,d3				d3=deltaY

	moveq #0,d4
	ror.w #4,d0				\
	move.b d0,d4				 > d0=décalage
	and.w #$f000,d0				/

	add.b d4,d4				d4=adr en octets sur X
	add.w d1,d1				d1=d1*2 car table de mots
	lea Table_Mulu(pc),a4
	add.w 0(a4,d1.w),d4			d4=d1*Width+d4
	lea 0(a3,d4.w),a3			recherche 1er mot de la droite
	move.w d0,d4				sauvegarde du décalage
	or.w #$0b00,d4				source
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

	addq.b #1,d1				commute en mode LINE
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
	sub.w d2,d3				4*Pdelta-4*Gdelta
	move.w d3,bltamod(a6)

	addq.w #1<<1,d2				(Gdelta+1)<<1
	lsl.w #5,d2				(Gdelta)<<6
	addq.w #2,d2				(Gdelta+1)<<6+2

	moveq #SCREEN_WIDTH/8,d0
	move.w d0,bltcmod(a6)			\ largeur de l'image
	move.w d0,bltdmod(a6)			/
	moveq #-1,d0
	move.w d0,bltbdat(a6)			masque de la droite
	move.l d0,bltafwm(a6)			masque sur A
	move.w #$8000,bltadat(a6)		Style du point

*-------> en sortit, a3=ptr 1er mot de la droite

	move.w line_color(a2),d0		couleur de la droite
	moveq #SCREEN_DEPTH-1,d1
	bra.s display_line_start

loop_display_color_line
	lea (SCREEN_WIDTH/8)*SCREEN_HEIGHT(a3),a3
	WAIT_BLITTER
display_line_start
	lsr.w #1,d0				sort un bit
	bcc.s line_clear_line

	move.b #$ca,d4				D=aC + AB
	move.w d3,bltapt+2(a6)
	move.w d4,bltcon0(a6)
	move.l a3,bltcpt(a6)
	move.l a3,bltdpt(a6)
	move.w d2,bltsize(a6)

	dbf d1,loop_display_color_line
line_unvisible
	dbf d7,loop_display_element
	rts
line_clear_line
	move.b #$0a,d4				D=aC
	move.w d3,bltapt+2(a6)
	move.w d4,bltcon0(a6)
	move.l a3,bltcpt(a6)
	move.l a3,bltdpt(a6)
	move.w d2,bltsize(a6)

	dbf d1,loop_display_color_line
	dbf d7,loop_display_element
	rts

Normal_bltapt	dc.w 0
minterm=*+1
Normal_bltcon0	dc.w 0
Normal_bltsize	dc.w 0



********************************************************************************
******************  AFFICHAGE D'UN ELEMENT DE TYPE FACE  ***********************
********************************************************************************
draw_face
	movem.l d7/a0-a1,-(sp)			sauve ptr element etc..

*--------------------> calcule le produit vectoriel pour Z
	lea face_line(a2),a3
	movem.w (a3),d0/d2			\ 3 points de la face
	move.w 6(a3),d4				/
	add.w d0,d0
	add.w d0,d0
	add.w d2,d2
	add.w d2,d2
	add.w d4,d4
	add.w d4,d4
	movem.w 0(a1,d0.w),d0-d1		d0=X1   ,   d1=Y1
	movem.w 0(a1,d2.w),d2-d3		d2=X2   ,   d3=Y2
	movem.w 0(a1,d4.w),d4-d5		d4=X3   ,   d5=Y3
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
	move.w face_front_color(a2,d0.w),actual_face_color-data_base(a5)
	blt no_face_at_all			si <0 pas de face

*--------------------> à partir d'ici la face existe et a sa propre couleur
	clr.w right_point_nb-data_base(a5)
	clr.l max_X-data_base(a5)		init quelques données
	move.l #$7fff7fff,min_X-data_base(a5)

	moveq #0,d6				0 droite pour l'instant
	move.w face_nb_line(a2),d7		nb de droite à clipper	
	subq.w #1,d7				à cause du dbf
	lea face_line(a2),a3			pointe description line
	lea right_point(pc),a4			ptr buffer right point

DrawLine_Init
	WAIT_BLITTER

	moveq #SCREEN_WIDTH/8,d0
	move.w d0,bltcmod(a6)			\ largeur de l'image
	move.w d0,bltdmod(a6)			/
	moveq #-1,d0
	move.w d0,bltbdat(a6)			masque de la droite
	move.l d0,bltafwm(a6)			masque sur A
	move.w #$8000,bltadat(a6)		Style du point

loop_clip_all_line
	movem.w (a3)+,d0/d2			2 points pour une droite
	add.w d0,d0
	add.w d0,d0				table de long
	add.w d2,d2
	add.w d2,d2
	movem.w 0(a1,d0.w),d0-d1		X1,Y1
	movem.w 0(a1,d2.w),d2-d3		X2,Y2

*---------------------> on clippe la droite
	cmp.w d2,d0
	ble.s .x1_less_x2
	exg d0,d2
	exg d1,d3
.x1_less_x2
	cmp.w #SCREEN_WIDTH,d2
	blt.s .no_inter_X_max
	cmp.w #SCREEN_WIDTH,d0
	bge line_face_unvisible

*---------------> clip suivant les X avec le bord droit ( Xmax )
	move.w #SCREEN_WIDTH-1,d4
	sub.w d2,d4				(D-X2)
	move.w d3,d5				sauve Y2
	sub.w d1,d3				(Y2-Y1)
	muls d4,d3				(Y2-Y1)*(D-X2)
	sub.w d0,d2				(X2-X1)
	divs d2,d3				(Y1-Y2)*(D-X2)/(X1-X2)
	add.w d5,d3				(Y1-Y2)*(D-X2)/(X1-X2)+Y2
	move.w #SCREEN_WIDTH-1,d2		X2=SCREEN_WIDTH-1

	move.w d3,(a4)+				sauve le Y clippé
	addq.w #1,right_point_nb-data_base(a5)	inc le nb

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
	cmp.w #SCREEN_HEIGHT,d3
	blt.s .no_inter_Y_max
	cmp.w #SCREEN_HEIGHT,d1
	bge line_face_unvisible

*---------------> clip suivant les Y avec le bas ( Ymax )
	move.w #SCREEN_HEIGHT-1,d4
	sub.w d1,d4				(D-Y1)
	sub.w d0,d2				(X2-X1)
	muls d4,d2				(D-Y1)*(X2-X1)
	sub.w d1,d3				(Y2-Y1)
	divs d3,d2				(D-Y1)*(X2-X1)/(Y2-Y1)
	add.w d0,d2				(D-Y1)*(X2-X1)/(Y2-Y1)+X1
	move.w #SCREEN_HEIGHT-1,d3

.no_inter_Y_max
	addq.w #1,d6				inc le nbr de droite à tracer

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
	lea scratch_screen,a0
*----------------------------> routine qui trace une droite 3d
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
	dbf d7,loop_clip_all_line
	bra sort_right_line

Table_Mulu
MuluCount set 0
	rept SCREEN_HEIGHT
	dc.w MuluCount*(SCREEN_WIDTH/8)
MuluCount set MuluCount+1
	endr

line_face_unvisible
	dbf d7,loop_clip_all_line

*---------------> on trie les right droites s'il le faut
sort_right_line
	move.w d6,-(sp)
	move.w right_point_nb(pc),d0		nb de right_point
	beq no_right_line

	move.w #SCREEN_WIDTH-1,max_X-data_base(a5)	une droite à droite

one_line_at_least
	subq.w #1,d0				à cause du dbf
	lea right_point(pc),a2			pointe début de la table
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

*----------------------> on affiche les right line
	move.w right_point_nb(pc),d7		nb de point right
	lsr.w #1,d7				divise par 2 car paires
	subq.w #1,d7				à cause du dbf
	lea scratch_screen,a1
	lea Table_Mulu(pc),a3
	move.w #SCREEN_WIDTH-1,d6
loop_draw_right_line
	movem.w (a2)+,d1/d3			clip le haut
	tst.w d1
	bge.s .ok1
	tst.w d3
	blt no_right_line_this_time
	moveq #0,d1
.ok1
	cmp.w #SCREEN_HEIGHT,d3			clip le bas
	blt.s .ok2
	cmp.w #SCREEN_HEIGHT,d1
	bge no_right_line
	move.w #SCREEN_HEIGHT-1,d3
.ok2
	addq.w #1,(sp)
	move.w d6,d0
	move.w d6,d2

Draw_3d_right_line
	sub.w d0,d2				d2=deltaX
	sub.w d1,d3				d3=deltaY
	beq.s no_right_line_this_time
	subq.w #1,d3

	moveq #0,d4
	ror.w #4,d0				\
	move.b d0,d4				 > d0=décalage
	and.w #$f000,d0				/

	add.w d4,d4				d4=adr en octets sur X
	add.w d1,d1				d1=d1*2 car table de mots
	add.w 0(a3,d1.w),d4			d4=d1*Width+d4
	lea 0(a1,d4.w),a0			recherche 1er mot de la droite
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
no_right_line_this_time
	dbf d7,loop_draw_right_line

no_right_line
*----------------------> encadre l'objet qui se trouve dans le scratch screen
	move.w (sp)+,d6				regarde si une droite a été
	beq no_face_at_all			tracée ou si une face est là

fill_circle_branch
	lea Table_Mulu(pc),a0
	move.w max_Y(pc),d0
	add.w d0,d0
	move.w 0(a0,d0.w),d0			mulu #SCREEN_WIDTH/8,d0
	move.w max_X(pc),d1
	lsr.w #3,d1				adr en octet
	and.b #$fe,d1				pointe des mots
	add.w d1,d0
	move.l log_screen(pc),a0
	lea 0(a0,d0.w),a0			ptr sur destination
	lea scratch_screen,a1
	lea 0(a1,d0.w),a1			ptr source

	move.w min_X(pc),d2
	lsr.w #3,d2				adr en octet
	and.b #$fe,d2				pointe des mots
	sub.w d2,d1				max_X-min_X  ( en octets )
	addq.w #2,d1
	move.w d1,d3				sauve largeur en octets
	sub.w #SCREEN_WIDTH/8,d3
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
	move.l a1,bltdpt(a6)			destintation=scratch
	move.w d3,bltamod(a6)
	move.w d3,bltbmod(a6)
	move.w d3,bltdmod(a6)	
	move.l #$09f0000a,bltcon0(a6)		In-fill et descending, D=A
	move.w d1,bltsize(a6)			lance le blitter

*--------------------------> recopie du scratch dans les bpl
	move.w actual_face_color(pc),d2		couleur de la face
	moveq #SCREEN_DEPTH-1,d0
	bra.s put_face_start
loop_put_face
	lea (SCREEN_WIDTH/8)*SCREEN_HEIGHT(a0),a0
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

min_X	dc.w 0
min_Y	dc.w 0					espace pour stocker
max_X	dc.w 0					l'encadrement d'une face
max_Y	dc.w 0
actual_face_color
	dc.w 0					couleur de la face



********************************************************************************
************  ROUTINE QUI INSTALLE LES COULEURS PROPRES DE L'OBJET  ************
************                                                        ************
************  a1=ptr table de couleurs                              ************
********************************************************************************
Change_Color
	move.l log_coplist(pc),a2
	lea coplist1_color-coplist1(a2),a2
	moveq #NB_COLOR-1,d0
loop_change_color
	move.w (a1)+,(a2)
	addq.l #4,a2
	dbf d0,loop_change_color
	rts



********************************************************************************
**************  ROUTINE QUI INCREMENTE LES ANGLES D'UN OBJET  ******************
**************                                                ******************
**************  a0=ptr sur objet   d0=Alpha  d1=Teta  d2=Phi  ******************
********************************************************************************
Incrize_Angles
	lea Alpha(a0),a0
do_Alpha
	add.w d0,(a0)+				ajoute l'angle
	bgt.s Alpha_test			signe du résultat
	beq.s do_Teta
	add.w #720,-2(a0)
	bra.s do_Teta
Alpha_test
	cmp.w #720,-2(a0)
	blt.s do_Teta
	sub.w #720,-2(a0)
do_Teta
	add.w d1,(a0)+				ajoute l'angle
	bgt.s Teta_test				signe du résultat
	beq.s do_Phi
	add.w #720,-2(a0)
	bra.s do_Phi
Teta_test
	cmp.w #720,-2(a0)
	blt.s do_Phi
	sub.w #720,-2(a0)
do_Phi
	add.w d2,(a0)				ajoute l'angle
	bgt.s Phi_test				signe du résultat
	beq.s end_Angles
	add.w #720,(a0)
	rts
Phi_test
	cmp.w #720,(a0)
	blt.s end_Angles
	sub.w #720,(a0)
end_Angles
	rts
	


********************************************************************************
***************  ROUTINE QUI INIT LA TRANSFORMATION D'UN OBJET  ****************
***************                                                 ****************
***************  a0=ptr objet                                   ****************
********************************************************************************
Transformer_Init
	lea transformer_start(pc),a1
	move.l list_dots(a0),a0
	move.w (a0)+,d0
	move.w d0,d1				sauve nb_dots
	subq.w #1,d1				à cause du dbf
	add.w d0,d0				\ nb_dots*3-1
	add.w d1,d0				/
	move.w #1,(a1)+				transf_actual
	move.w d0,(a1)+				nb_dots*3-1

loop_fill
	move.l (a0)+,(a1)+			recopie coord point 3d
 	move.w (a0)+,(a1)+
	dbf d1,loop_fill
	rts

********************************************************************************
*****************  ROUTINE QUI TRANSFORME UN OBJET EN UN AUTRE  ****************
*****************                                               ****************
*****************  a0=ptr objet  a1=table de transformation     ****************
********************************************************************************
Transformer
	move.w (a1)+,d1				transf_total
	lea transformer_start(pc),a2
	move.w (a2),d2				transf_actual
	cmp.w d1,d2
	bgt.s Transformer_End
	addq.w #1,(a2)+				augmente transf_actual
	move.w (a2)+,d0				nb_dots*3-1
	move.l list_dots(a0),a0
	addq.l #dots_coord,a0			ptr sur la liste des points
loop_transform
	move.w (a1)+,d3				X2
	sub.w (a2),d3				X2-X1
	muls d2,d3				(X2-X1)*transf_actual
	divs d1,d3				obtient le nouveau delta
	add.w (a2)+,d3				ajoute coord point au delta
	move.w d3,(a0)+				sauve le nouveau point
	dbf d0,loop_transform
Transformer_End
	rts



********************************************************************************
******************************                   *******************************
******************************  DONNES DIVERSES  *******************************
******************************                   *******************************
********************************************************************************
	include "TMC_Replay.s"
	include "Song.s"

Table_Cosinus
	incbin "datas/table_cosinus_360.dat"
Table_Sinus=Table_Cosinus+90*2

current_object
	dc.l 0

	include "Object_Pointe.s"

dots_2d
	dcb.w 2*NB_POINT,0			espace pour stocker Xe,Ye
right_point_nb
	dc.w 0
dots_2d_Z
right_point
	dcb.w NB_POINT,0			espace pour stocker Z et right
transformer_start
	dcb.w 1+1+3*NB_POINT,0

	section écran,data_c

coplist1
	dc.w fmode,%11
	dc.w diwstrt,$2b81
	dc.w diwstop,$2bc1
	dc.w ddfstrt,$0038
	dc.w ddfstop,$00a0
	dc.w bplcon0,(SCREEN_DEPTH<<12)|$200
	dc.w bplcon1,$0000
	dc.w bplcon2,$0000
	dc.w bplcon3,$0000
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
	dc.w fmode,%11
	dc.w diwstrt,$2b81
	dc.w diwstop,$2bc1
	dc.w ddfstrt,$0038
	dc.w ddfstop,$00a0
	dc.w bplcon0,(SCREEN_DEPTH<<12)|$200
	dc.w bplcon1,$0000
	dc.w bplcon2,$0000
	dc.w bplcon3,$0000
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
	dc.w fmode,%11
	dc.w diwstrt,$2b81
	dc.w diwstop,$2bc1
	dc.w ddfstrt,$0038
	dc.w ddfstop,$00a0
	dc.w bplcon0,(SCREEN_DEPTH<<12)|$200
	dc.w bplcon1,$0000
	dc.w bplcon2,$0000
	dc.w bplcon3,$0000
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

	include "Samples.s"

	section screen,bss_c
screen1
	ds.b (SCREEN_WIDTH/8)*SCREEN_HEIGHT*SCREEN_DEPTH
screen2
	ds.b (SCREEN_WIDTH/8)*SCREEN_HEIGHT*SCREEN_DEPTH
screen3
	ds.b (SCREEN_WIDTH/8)*SCREEN_HEIGHT*SCREEN_DEPTH
scratch_screen
	ds.b (SCREEN_WIDTH/8)*SCREEN_HEIGHT

