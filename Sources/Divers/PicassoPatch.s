
*			Corrige le bug de la picasso dans la startup-sequence
*			~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*			la picasso II se met toujours en mode picasso même si
*			c'est un mode amiga qui est affiché...

	OPT O+,OW-
	OPT NODEBUG,NOLINE

	incdir "asm:sources/"
	include "registers.i"

	section cotcot,code
Main
	lea VillageName(pc),a1
	CALL 4.w,OpenLibrary
	tst.l d0
	beq.s .no_village

	move.l d0,a6
	CALL SetAmigaDisplay

	move.l a6,a1
	CALL 4.w,CloseLibrary
	moveq #0,d0
.no_village
	rts

VillageName
	dc.b "village.library",0
