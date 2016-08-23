
	OPT DEBUG
	OPT O+

main
	moveq #-1,d0
	moveq #-1,d1
	bsr add
	rts






* d0.w=A d1.w=B d2.w=Res d3=Carry
add
	moveq #16-1,d4
	moveq #0,d3			retenu=0
	moveq #0,d2			resultat
loop
	lsr.w #1,d0
	bcs.s first_set
first_clear
	lsr.w #1,d1			0 + ?
	bcs.s second_set1
second_clear
	add.w d3,d2
	ror.w #1,d2			0 + 0 + retenue
	moveq #0,d3
	dbf d4,loop
	rts

second_set1
	tst.b d3			0 + 1  => test de la retenue
	beq.s retenue_clear
retenue_set
	ror.w #1,d2			1 + 1 = 0 + retenue
	moveq #1,d3
	dbf d4,loop
	rts	

retenue_clear
	addq.w #1,d2			1 + 0 = 1
	ror.w #1,d2
	dbf d4,loop
	rts

first_set
	lsr.w #1,d1			1 + ?
	bcc.s second_set1			1 + 0 = 0 + 1

second_set2
	add.b d3,d2			1 + 1 = 0   + retenue
	ror.w #1,d2
	moveq #1,d3			retenue = 1
	dbf d4,loop
	rts
