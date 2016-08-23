
	move.l #$1234,d0
	move.l #$789a,d1
	bsr MuluLong

	move.l #$1234,d1
	mulu.l #$789a,d1
	rts

MuluLong
	move.w d1,d2				D
	mulu.w d0,d2				B*D

	move.w d1,d3				D
	move.w d0,d4				sauve B
	swap d0					BA
	mulu.w d0,d3				A*D
	swap d3					A*D*2^16

	swap d1					C
	mulu.w d1,d4				B*C
	swap d4					B*C*2^16

	mulu.w d1,d0				A*C*2^32

	add.l d4,d3
	add.l d3,d2
	add.l d2,d0
	rts
