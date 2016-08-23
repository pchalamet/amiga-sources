
*			FastBlitter
*			~~~~~~~~~~~


Main
	moveq #0,d7			code d'erreur

* Recherche l'option
* ~~~~~~~~~~~~~~~~~~
	subq.w #2,d0			un char + RC ?
	bne.s Display_info

	cmp.b #"A",(a0)
	beq.s Activate

	cmp.b #"Q",(a0)
	beq.s Quit

* Affichage des informations
* ~~~~~~~~~~~~~~~~~~~~~~~~~~
Display_info
	moveq #20,d7			code d'erreur

	lea DosName(pc),a1
	moveq #0,d0
	move.l 4.w,a6
	jsr -552(a6)			OpenLibrary()
	tst.l d0
	beq.s .no_dos

	move.l d0,a6
	jsr -60(a6)			Output()

	lea Doc(pc),a0
	move.l d0,d1
	move.l a0,d2
	moveq #Doc_Size,d3
	jsr -48(a6)			Write()
	cmp.l d0,d3
	bne.s .no_write

	moveq #0,d7
.no_write
	move.l a6,a1
	move.l 4.w,a6
	jsr -414(a6)			CloseLibrary()
.no_dos
Exit
	move.l d7,d0
	rts

* Activation de BltPri
* ~~~~~~~~~~~~~~~~~~~~
Activate
	move.w #$8400,$dff096
	bra.s Exit

* Effacement de BltPri
* ~~~~~~~~~~~~~~~~~~~~
Quit	move.w #$0400,$dff096
	bra.s Exit

* Datas
* ~~~~~
DosName
	dc.b "dos.library",0

Doc
	dc.b $9b,"1m"
	dc.b "FastBlitter v1.0 (c)1994 Sync/DreamDealers",10
	dc.b $9b,"0m","Usage: FastBlitter [A][Q][?]",10
Doc_Size=*-Doc

* end of file
