

*
*		Fabrication de la fonte pour le system ALU
*		   à partir de la fonte system courante
*
*			(c) 1994 Sync/DreamDealers
*


* ouverture de l'intuition.library
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	lea IntuitionName(pc),a1
	moveq #0,d0
	move.l 4.w,a6
	jsr -552(a6)			OpenLibrary()
	move.l d0,_IntuitionBase
	beq no_intuition

* ouverture de la graphics.library
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	lea GfxName(pc),a1
	moveq #0,d0
	jsr -552(a6)			OpenLibrary()
	move.l d0,_GfxBase
	beq no_gfx

* ouverture de la dos.library
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~
	lea DosName(pc),a1
	moveq #0,d0
	jsr -552(a6)			OpenLibrary
	move.l d0,_DosBase
	beq no_dos

* ouverture d'un ecran
* ~~~~~~~~~~~~~~~~~~~~
	lea Screen_Attr(pc),a0
	move.l _IntuitionBase(pc),a6
	jsr -198(a6)			OpenScreen()
	move.l d0,Screen
	beq no_screen
	move.l d0,a0
	lea 84(a0),a0
	move.l a0,RastPort		RastPort de l'écran

* Boucle principale qui va chercher les 256 chars
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.l Screen(pc),a0		\
	move.l $c0(a0),a0		 > un trait pour le debug
	move.w #$5555,(a0)		/

	moveq #0,d7
	lea Font_Buffer(pc),a5
	move.l _GfxBase(pc),a6
loop
	moveq #0,d0
	moveq #6,d1
	move.l RastPort(pc),a1
	jsr -240(a6)			Move()

	moveq #1,d0
	lea Text(pc),a0			stocke le char à afficher
	move.b d7,(a0)
	move.l RastPort(pc),a1
	jsr -60(a6)			Text

	move.l Screen(pc),a0		recopie la lettre affichée dans le
	move.l $c0(a0),a0		buffer
	moveq #8-1,d0
.dup	move.b (a0),(a5)+
	lea 40(a0),a0
	dbf d0,.dup

	addq.w #1,d7			yen a encore à afficher ?
	cmp.w #256,d7
	bne loop

* Sauvegarde du fichier de la fonte
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.l #Font_FileName,d1
	move.l #1006,d2			MODE_NEWFILE
	move.l _DosBase(pc),a6
	jsr -30(a6)			Open
	move.l d0,d7
	beq no_file

	move.l d0,d1
	move.l #Font_Buffer,d2
	move.l #256*8,d3
	jsr -48(a6)			Write

	move.l d7,d1
	jsr -36(a6)			Close

* fermeture de l'écran
* ~~~~~~~~~~~~~~~~~~~~
no_file
	move.l Screen(pc),a0
	move.l _IntuitionBase(pc),a6
	jsr -66(a6)			CloseScreen()

* fermeture de la dos.library
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~
no_screen
	move.l _DosBase(pc),a1
	move.l 4.w,a6
	jsr -414(a6)			CloseLibrary()

* fermeture de la graphics.library
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
no_dos
	move.l _GfxBase(pc),a1
	jsr -414(a6)			CloseLibrary()

* fermeture de l'intuition.library
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
no_gfx
	move.l _IntuitionBase(pc),a1
	jsr -414(a6)			CloseLibrary()

* sortie
* ~~~~~~
no_intuition
	moveq #0,d0
	rts


_IntuitionBase		dc.l 0
_GfxBase		dc.l 0
_DosBase		dc.l 0
Screen			dc.l 0
RastPort		dc.l 0

Screen_Attr
	dc.w 0
	dc.w 0
	dc.w 320
	dc.w 16
	dc.w 1
	dc.b 1
	dc.b 0
	dc.w 2
	dc.w 15
	dc.l 0
	dc.l 0
	dc.l 0
	dc.l 0
	
IntuitionName
	dc.b "intuition.library",0
GfxName
	dc.b "graphics.library",0
DosName
	dc.b "dos.library",0
Font_FileName
	dc.b "ALU:ALU_System/Font.RAW",0
Text
	dc.b 0

Font_Buffer
	ds.b 256*8

