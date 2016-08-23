
*				PurgeMem
*				~~~~~~~~


Main
	moveq #-1,d0
	moveq #0,d1
	move.l 4.w,a6
	jsr -198(a6)
	rts


