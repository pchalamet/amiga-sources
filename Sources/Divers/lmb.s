
	OPT NODEBUG
	OUTPUT C:LMB

main
	btst #6,$bfe001
	beq.s .down
	moveq #0,d0
	rts
.down
	moveq #5,d0
	rts

	