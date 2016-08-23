
*			Recherche de la picasso II
*			~~~~~~~~~~~~~~~~~~~~~~~~~~

	incdir "include:"
	include "exec/exec_lib.i"
	include "libraries/expansion_lib.i"
	include "misc/macros.i"


	section toto,code

	move.l (_SysBase).w,a6

	lea ExpansionName(pc),a1		ouvre l'expansion.library
	moveq #37,d0
	CALL OpenLibrary
	tst.l d0
	beq.s no_expansion

	move.l d0,a6
	move.l #2167,d0
	moveq #$B,d1				$B pour mem video
	sub.l a0,a0				$C pour controleur
	CALL FindConfigDev

	move.l d0,a0
	move.l $20(a0),a0

no_error
	move.l a6,a1				ferme tout
	CALL (_SysBase).w,CloseLibrary
no_expansion
	moveq #0,d0
	rts

ExpansionName	dc.b "expansion.library",0
