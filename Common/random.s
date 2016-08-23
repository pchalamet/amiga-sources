
*
* routine de nombres aléatoires
*
* en entrée:
* en sortie: d0=nombre aléatoire 24 bits
*
* d0-d3 trashed
*

RND_A=$41a7
RND_M=$7ffffff
RND_Q=$f31d
RND_R=$8b14

random
	move.l #RND_Q,d0
	move.l RND_Z(pc),d1
	moveq #0,d3
	divu d0,d1
	bvc.s .result
	move.l d1,d2
	clr.w d1
	swap d1
	divu d0,d1
	move.w d1,d3
	move.w d2,d1
	divu d0,d1
.result
	move.l d1,d0
	swap d0
	mulu #RND_A,d0
	move.w d1,d3
	swap d3
	mulu #RND_R,d3
	swap d3
	clr.w d3
	mulu #RND_R,d1
	add.l d1,d3
	sub.l d3,d0
	move.l d0,RND_Z
	rts

*
* routine d'initialistion de la semence pour les nombres aléatoires
*
* en entrée: a6=custom_base
* en sortie:
*
* d0 trashed
*

init_random
	move.l vposr(a6),d0
	and.l #RND_M,d0
	cmp.l #RND_M-1,d0
	blt.s .semence_ok
	subq.l #2,d0
.semence_ok
	addq.l #1,d0
	move.l d0,RND_Z
	rts
RND_Z	dc.l 0

