
*			  Amiga Loader Unit (ALU)
*			  ~~~~~~~~~~~~~~~~~~~~~~~
*			 (c)1994 Sync/DreamDealers
*
*			    Installer de disk


CALL	macro
	ifNE NARG=2
	move.l \1,a6
	jsr _LVO\2(a6)
	elseif
	jsr _LVO\1(a6)
	endc
	endm


* Exec
* ~~~~
_SysBase=4
_LVOOpenLibrary=-512
_LVOCloseLibrary=-414

* Dos
* ~~~



* Structure de données
* ~~~~~~~~~~~~~~~~~~~~
	rsreset
Struct_DataBase	rs.b 0
_ExecBase	rs.l 1
_DosBase	rs.l 1
DataBase_SIZEOF	rs.b 0


	section ALU,code

	lea DataBase(pc),a5
	move.l (_SysBase).w,a6
	move.l a6,_ExecBase(a5)

	lea DosName(pc),a1
	moveq #0,d0
	CALL OpenLibrary
	move.l d0,_DosBase(a5)
	beq no_dos

	move.l d0,a6
	move.l #WindowName,d1
	move.l #
