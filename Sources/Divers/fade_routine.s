fade
	move.w (a0)+,d0			a1 adresse des modifications
	subq.w #1,d0			d0 nb de changements-1
	move.w (a0)+,d5			offset
	move.w (a0)+,d6			prochaine couleur
	ext.l d6
	move.w (a0)+,d1			a0 adresse couleurs a atteindre
	move.w (a0),d2			met compteur dans d2
	cmp.w d1,d2			cmp
	beq.s DoFade			on a assez attendu => fading
	addq.w #1,(a0)			sinon on attend encore
	move.w #$0,d0			signale qu'il n'y a pas eu de chgmt
	rts
	
* B=valeur Bleu  G=valeur vert  R=valeur rouge
	
DoFade
	move.w #0,(a0)+			remet a 0 le compteur
	
* differents tests sont effectués pour atteindre la bonne valeur de R,G ou B

LoopFadeB
	move.w (a0)+,d1
	move.w d1,d2
	and.w #$f,d2			valeur a atteindre B
	
	move.w 0(a1,d5.w),d3
	move.w d3,d4
	and.w #$f,d4			valeur actuelle B
	
	cmp.w d2,d4
	beq.s LoopFadeG
	bgt.s DoFadeOutB
	addq.w #1,d3			inferieur => on augmente
	bra.s LoopFadeG
DoFadeOutB
	subq.w #1,d3			superieur => on diminue

LoopFadeG
	move.w d1,d2
	and.w #$f0,d2			valeur a atteindre G
	
	move.w d3,d4
	and.w #$f0,d4			valeur actuelle G
	
	cmp.w d2,d4
	beq.s LoopFadeR
	bgt.s DoFadeOutG
	add.w #$10,d3			inferieur => on augmente
	bra.s LoopFadeR
DofadeOutG
	sub.w #$10,d3			superieur => on diminue
	
LoopFadeR
	move.w d1,d2
	and.w #$f00,d2			valeur a atteindre R
	
	move.w d3,d4
	and.w #$f00,d4			valeur actuelle R
	
	cmp.w d2,d4
	beq.s FadeAgain
	bgt.s DoFadeOutR
	add.w #$100,d3
	bra.s FadeAgain
DoFadeOutR
	sub.w #$100,d3
FadeAgain
	move.w d3,0(a1,d5.w)
	add.l d6,a1
	dbra d0,LoopFadeB
	move.w #$ffff,d0
	rts

* structure des tables de couleurs a atteindre
* nb de couleur.W
* offset.W
* prochaine couleur offset.W
* wait.W
* temps.W
* couleurs.W
