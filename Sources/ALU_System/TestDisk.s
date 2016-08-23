* Initialisation du hardware
* ~~~~~~~~~~~~~~~~~~~~~~~~~~


* On commence par reperer les drives 3.5
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	lea _CiaABase+pra,a0
	lea _CiaBBase+prb,a1
	moveq #4-1,d0
get_drive
	move.b d0,d1
	addq.b #3,d1				joue avec ce lecteur
	bclr #7,(a1)				DSKMOTOR low
	bclr d1,(a1)				DSKSELx low
	bset d1,(a1)				DSKSELx high
	bset #7,(a1)				DSKMOTOR high
	bclr d1,(a1)				DSKSELx low
	moveq #0,d2				ID que l'on va chercher
	moveq #16-1,d3
.loop	add.w d2,d2
	bset d1,(a1)				DSKSELx high
	bclr d1,(a1)				DSKSELx low
	btst #5,(a0)				regarde DSKRDY
	beq.s .skip
	bset #0,d2
.skip	bset d1,(a1)				DSKSELx high
	dbf d3,.loop
	tst.w d2				c'est un disk 3.5 ?
	bne.s .not_drive35
	bset d0,ALU_Drives(a6)
.not_drive35
	dbf d0,get_drive

