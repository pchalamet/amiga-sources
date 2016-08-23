*****************************************************************************
***************** CALCUL DES 2 MOTS DE CONTROLE D'UN SPRITE *****************
***************** EN ENTREE :  D0=COORD X		    *****************
*****************              D1=COORD Y		    *****************
*****************              D2=HAUTEUR DU SPRITE	    *****************
*****************              A0=ADR DU SPRITE		    *****************
*****************************************************************************
put_sprite
	moveq #0,d3
	add.w #$80,d0				recentre sur les X
	lsr.w #1,d0
	bcc.s put_sprite_pas_carryX
	moveq #1,d3
put_sprite_pas_carryX
	add.w #$2b,d1				recentre sur les Y
	move.w d1,d4
	lsl.w #8,d1
	bcc.s put_sprite_pas_carryY1
	or.w #4,d3
put_sprite_pas_carryY1
	or.w d1,d0
	add.w d2,d4
	lsl.w #8,d4
	bcc.s put_sprite_pas_carryY2
	or.w #2,d3
put_sprite_pas_carryY2
	or.w d4,d3
	movem.w d0/d3,(a0)
	rts

