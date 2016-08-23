
*			Vire le curseur d'un CLI
*			~~~~~~~~~~~~~~~~~~~~~~~~


Main
	moveq #20,d7			code d'erreur

* Ouverture de la dos.library
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~
	lea DosName(pc),a1
	moveq #0,d0
	move.l 4.w,a6
	jsr -552(a6)			OpenLibrary()
	move.l d0,d1
	beq.s .no_dos

* Recherche la sortie standard
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.l d0,a6
	jsr -60(a6)			Output()

	move.l d0,d1
	beq.s .no_output

* Envoie la chaine pour virer le curseur
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	lea CursOff(pc),a0
	move.l a0,d2
	moveq #4,d3
	jsr -48(a6)			Write()
	cmp.l d0,d3
	bne.s .no_write

	moveq #0,d7

* Sortie du programme
* ~~~~~~~~~~~~~~~~~~~
.no_write
.no_output
	move.l a6,a1
	move.l 4.w,a6
	jsr -414(a6)			CloseLibrary()
.no_dos
	move.l d7,d0
	rts


* Datas
* ~~~~~
CursOff
	dc.b $9b,$30,$20,$70

DosName
	dc.b "dos.library",0

