
*			CloseLib <LibName>
*			~~~~~~~~~~~~~~~~~~


Main
	moveq #20,d7			code de retour

	clr.b -1(a0,d0.w)		met un zero en fin de LibName

* Recherche la library
* ~~~~~~~~~~~~~~~~~~~~
	move.l a0,a1
	moveq #0,d0
	move.l 4.w,a6
	jsr -552(a6)			OpenLibrary()
	tst.l d0
	beq.s .no_openlib

* Fermeture de la library
* ~~~~~~~~~~~~~~~~~~~~~~~
	move.l d0,d7
	move.l d0,a1
	jsr -414(a6)			ferme pour cette fois-ci
	move.l d7,a1
	jsr -414(a6)			ferme pour la fois d'avant

.no_error
	moveq #0,d7
.no_openlib
	move.l d7,d0
	rts
	
