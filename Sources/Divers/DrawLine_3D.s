Width=40				largeur en octets
Heigth=256				hauteur en pixel
Depth=1					profondeur en bitplans
MINTERM=$ca				minterm de la droite
WORD=1					table de WORD ou LONG


			*************************************
			* routine de tracé de droites 3D  : *
			*    si Y1=Y2 --> pas de droite	    *
			*    sinon DY=DY-1		    *
			*				    *
			* le clipping doit être fait avant  *
			*   de rentrer dans cette routine   *
			*				    *
			* en entrée :			    *
			*	       d0.w=X1		    *
			*	       d1.w=Y1		    *
			*	       d2.w=X2		    *
			*	       d3.w=Y2		    *
			*	       a0.l=adr bitplan	    *
			*	       a6.l=$dff000	    *
			*				    *
			* en sortie :			    *
			*	       d0-d4/a0 modifiés    *
			*************************************
DrawLine
	cmp.w d1,d3
	bgt.s .Y_OK
	beq .no_line

	exg d0,d2
	exg d1,d3
.Y_OK
	sub.w d0,d2				d2=deltaX
	sub.w d1,d3				d3=deltaY
	subq.w #1,d3

	moveq #0,d4
	ror.w #4,d0				\
	move.b d0,d4				 > d0=décalage
	and.w #$f000,d0				/

	add.b d4,d4				d4=adr en octets sur X
	add.w d1,d1				d1=d1*2 car table de mots
	IFEQ WORD
	add.w d1,d1
	ENDC
	add.w Table_Mulu_Line(pc,d1.w),d4	d4=d1*Width+d4
	lea 0(a0,d4.w),a0			recherche 1er mot de la droite
	move.w d0,d4				sauvegarde du décalage
	or.w #$0b<<8|MINTERM,d4			source + masque
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

.wait
	btst #14,dmaconr(a6)
	bne.s .wait

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
	addq.b #2,d2				(Gdelta+1)<<6+2
	move.w d2,bltsize(a6)			traçage de la droite
.no_line
	rts

Table_Mulu_Line
MuluCount set 0
	rept Heigth
	IFNE WORD
	dc.w MuluCount*Width*Depth
	ELSEIF
	dc.l MuluCount*Width*Depth
	ENDC
MuluCount set MuluCount+1
	endr

			****************************
			* routine d'initialisation *
			* du blitter pour le tracé *
			* de droites		   *
			*			   *
			* en entrée :		   *
			*	       a6=$dff000  *
			*			   *
			* en sortie :		   *
			*	       d0=-1	   *
			****************************						
DrawLine_Init
	btst #14,dmaconr(a6)
	bne.s DrawLine_Init

	moveq #Width*Depth,d0
	move.w d0,bltcmod(a6)			\ largeur de l'image
	move.w d0,bltdmod(a6)			/
	moveq #-1,d0
	move.w d0,bltbdat(a6)			masque de la droite
	move.l d0,bltafwm(a6)			masque sur A
	move.w #$8000,bltadat(a6)		Style du point
	rts	

