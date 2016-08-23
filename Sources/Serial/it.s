

	incdir "asm:sources/"
	include "registers.i"
	
	

toto
	KILL_SYSTEM main
	moveq #0,d0
	rts


main
	lea _Custom,a6

	move.l #vbl,$6c.w
	move.l #trap,$14.w
	move.w #$c020,intena(a6)

	WAIT_LMB_DOWN
	RESTORE_SYSTEM



vbl
	move.w #$7fff,intena(a6)
	move.w #$7fff,intreq(a6)

	move.w #$f00,color00(a6)
	WAIT_LMB_DOWN

	moveq #0,d0
	divu d0,d1
	move.w #$00f,color00(a6)

	rte


trap
	move.w #$0f0,color00(a6)
	WAIT_LMB_UP
	rte
