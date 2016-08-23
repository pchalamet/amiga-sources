
*				Vire l'écran de la picasso si y est
*				~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

	incdir "include:"
	include "exec/exec_lib.i"
	include "misc/macros.i"



	section rem,code
Main
	lea DataBase,a5
	move.l (_SysBase).w,a6

	movem.l d0/a0,CliArgs(a5)

	move.l a6,_ExecBase(a6)

	lea DosName(pc),a1
	moveq #0,d0
	CALL OpenLibrary
	move.l d0,_DosBase(a5)
	beq.s .no_dos

	lea VillageName(pc),a1
	moveq #0,d0
	CALL OpenLibrary
	move.l d0,_VillageBase(a5)
	beq.s .no_village

	move.l d0,a6
	btst #4,$22(a6)
	seq VillageFlag(a5)

	jsr -192(a6)

	




	tst.b VillageFlag(a5)
	beq.s .no_village
	move.l _VillageBase(a5),a6
	jsr -198(a6)

.no_village
	move.l _DosBase(a5),a1
	CALL CloseLibrary
.no_dos
	moveq #0,d0
	rts

VillageName
	dc.b "village.library",0


	section dat,bss
	rsreset
_ExecBase	rs.l 1
_DosBase	rs.l 1
_VillageBase	rs.l 1
CliArgs		rs.l 1
		rs.l 1
VillageFlag	rs.b 1
database_SIZEOF	rs.b 0

DataBase
	ds.b database_SIZEOF
