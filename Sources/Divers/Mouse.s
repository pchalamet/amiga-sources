********************************************************************************
*************                                                       ************
*************        GESTION DES DEPLACEMENTS DE LA SOURIS          ************
*************                                                       ************
********************************************************************************
Update_Mouse
	move.w joy0dat(a6),d1
	moveq #-1,d3				d3=255
	
	move.b LastX(pc),d0			etat précédent
	move.b d1,LastX-data_base(a5)		etat actuel
	sub.b d1,d0				différence=précédent-actuel
	bvc.s test_Y				Overflow clear ?
	bge.s pas_depassementX_right
	addq.b #1,d0				-255+différence
	bra.s test_Y
pas_depassementX_right
	add.b d3,d0				255+différence
test_Y
	lsr.w #8,d1				récupère les Y
	move.b LastY(pc),d2
	move.b d1,LastY-data_base(a5)
	sub.b d1,d2				idem
	bvc.s fin_testY
	bge.s pas_depassementY_down
	addq.b #1,d2
	bra.s fin_testY
pas_depassementY_down
	add.b d3,d2
fin_testY
	ext.w d0
	ext.w d2
	sub.w d0,MouseX-data_base(a5)
	sub.w d2,MouseY-data_base(a5)
	rts
