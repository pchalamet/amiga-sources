

	incdir "include:"
	
	include "exec/exec_lib.i"
	include "dos/dos_lib.i"
	include "dos/dos.i"
	include "misc/macros.i"

	OPT DEBUG


* init les regs
	lea _DataBase(pc),a5
	move.l 4.w,a6
	move.l a6,_ExecBase(a5)

* ouverture de la dos.library
	lea DosName(pc),a1
	moveq #0,d0
	CALL OpenLibrary
	move.l d0,_DosBase(a5)
	beq.s dos_error

* ouverture du fichier pour sauver toute la mémoire chip
	move.l #FileName,d1
	move.l #MODE_NEWFILE,d2
	CALL d0,Open
	move.l d0,FileHandle(a5)
	beq.s file_error

* écriture de toute la mémoire
	move.l d0,d1
	moveq #0,d2
	move.l #2*1024*1024,d3
	CALL Write

* fermeture du fichier
	move.l FileHandle(a5),d1
	CALL Close

file_error
	move.l a6,a1
	CALL _ExecBase(a5),CloseLibrary

dos_error
	moveq #0,d0
	rts






DosName
	dc.b "dos.library",0
FileName
	dc.b "Memory",0




	rsreset
DataBase_Struct	rs.b 0
_ExecBase	rs.l 1
_DosBase	rs.l 1
FileHandle	rs.l 1
DataBase_SizeOf	rs.l 0

	even
_DataBase
	dcb.b DataBase_SizeOf
