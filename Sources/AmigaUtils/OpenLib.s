
*			OpenLib <LibName>
*			~~~~~~~~~~~~~~~~~


Main
	moveq #20,d7

	clr.b -1(a0,d0.w)		met un zero en fin de LibName

* Ouverture de la library
* ~~~~~~~~~~~~~~~~~~~~~~~
	move.l a0,a1
	moveq #0,d0
	move.l 4.w,a6
	jsr -552(a6)			OpenLibrary()

	tst.l d0			code de retour
	beq.s .error
	moveq #0,d7
.error
	move.l d7,d0
	rts
	
