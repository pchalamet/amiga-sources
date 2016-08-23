
*			Autorise les sprites en dehors de l'écran
*			~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

* Les includes
* ~~~~~~~~~~~~
	incdir "hd1:include/"
	include "exec/exec_lib.i"
	include "graphics/gfxbase.i"
	include "intuition/intuition_lib.i"
	include "misc/macros.i"

	OPT O+,OW-
	OPT NODEBUG,NOLINE

* Structure des données
* ~~~~~~~~~~~~~~~~~~~~~
	rsreset
_ExecBase	rs.l 1
_GfxBase	rs.l 1
_IntuitionBase	rs.l 1
db_SIZEOF	rs.b 0

* Le programme principale
* ~~~~~~~~~~~~~~~~~~~~~~~
	section tarte,code
	lea db,a5

	move.l (_SysBase).w,_ExecBase(a5)

	lea GfxName(pc),a1
	moveq #39,d0
	CALL _ExecBase(a5),OpenLibrary
	move.l d0,_GfxBase(a5)
	beq.s no_gfx

	lea IntuitionName(pc),a1
	moveq #39,d0
	CALL OpenLibrary
	move.l d0,_IntuitionBase(a5)
	beq.s no_intuition

	move.l _GfxBase(a5),a0
	and.b #$1d,gb_BP3Bits(a0)
	or.b #$02,gb_BP3Bits(a0)		BRDBLNK & BRDSPR $22

	CALL _IntuitionBase(a5),RemakeDisplay

no_error
	move.l a6,a1
	CALL _ExecBase(a5),CloseLibrary
no_intuition
	move.l _GfxBase(a5),a1
	CALL CloseLibrary
no_gfx
	moveq #0,d0
	rts

GfxName
	dc.b "graphics.library",0
IntuitionName
	dc.b "intuition.library",0

	section yo,bss
db	ds.b db_SIZEOF
