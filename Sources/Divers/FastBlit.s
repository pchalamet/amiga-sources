
*		FastBlit ON/S,OFF/S: choix de la priorité blitter
*		~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


* Les includes
* ~~~~~~~~~~~~
	incdir "hd1:include/"
	include "exec/exec_lib.i"
	include "dos/dos_lib.i"
	include "dos/dos.i"
	include "misc/macros.i"


* Le point d'entrée
* ~~~~~~~~~~~~~~~~~
	moveq #RETURN_ERROR,d7

	lea DosName(pc),a1			ouverture de la dos.library
	moveq #39,d0
	CALL (_SysBase).w,OpenLibrary
	tst.l d0
	beq.s no_dos

	lea SBP_Template(pc),a0			parsing de la ligne du CLI
	move.l a0,d1
	lea SBP_ArgsArray(pc),a0
	move.l a0,d2
	moveq #0,d3
	CALL d0,ReadArgs
	move.l d0,d1				libère le RDArgs
	beq.s no_rdargs
	CALL FreeArgs

	tst.l Blit_On(pc)
	beq.s do_blit_off
do_blit_on
	move.w #$8400,$dff096			priorité blitter
	bra.s no_error
do_blit_off
	tst.l Blit_Off(pc)
	beq.s no_rdargs
	move.w #$0400,$dff096			priorité micropro
no_error
	moveq #RETURN_OK,d7
no_rdargs
	move.l a6,a1
	CALL (_SysBase).w,CloseLibrary
no_dos
	move.l d7,d0
	rts

SBP_ArgsArray
Blit_On
	dc.l 0
Blit_Off
	dc.l 0

SBP_Template
	dc.b "ON/S,OFF/S",0
DosName
	dc.b "dos.library",0