
*			Commande CLI : CLS
*			~~~~~~~~~~~~~~~~~~


Main
	moveq #20,d7			Code de retour

* Ouverture de la dos.library
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~
	lea DosName(pc),a1
	moveq #0,d0
	move.l 4.w,a6
	jsr -552(a6)			OpenLibrary()
	move.l d0,d1			ca a marché ?
	beq.s .no_dos
	move.l d0,a6

* Recherche la sortie standard
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	jsr -60(a6)			Output()
	move.l d0,d1
	beq.s .no_output

* Envoie la commande d'éffacement de l'écran
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	lea Cls_Command(pc),a0
	move.l a0,d2
	moveq #1,d3
	jsr -48(a6)			Write()

* L'éffacement a eu lieu ?
* ~~~~~~~~~~~~~~~~~~~~~~~~
	cmp.l d0,d3
	bne.s .no_write
	moveq #0,d7

* Fermeture de la dos.library
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~
.no_write
.no_output
	move.l a6,a1
	move.l 4.w,a6
	jsr -414(a6)			CloseLibrary()

* Retour au CLI
* ~~~~~~~~~~~~~
.no_dos
	move.l d7,d0			retour le code d'erreur au Shell
	rts

* Datas
* ~~~~~
DosName
	dc.b "dos.library",0
Cls_Command
	dc.b $c

