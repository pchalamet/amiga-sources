
*
* Division 32 bits / Mise en oeuvre du 68000
*
* en entrée: d0=nombre 16 bits
*            d1=nombre 32 bits
* en sortie: d0=d1/d0 nombre 32 bits
* d0-d3 trashed
*

div_32_bits
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
.result	move.l d1,d0
	swap d1
	move.w d3,d1
	swap d1
	move.l d1,d0
	rts

