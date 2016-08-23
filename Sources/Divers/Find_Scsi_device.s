
*			recherche et sauvegarde du scsi.device
*			~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~





* les includes
* ~~~~~~~~~~~~
	incdir "include:"
	include "exec/exec_lib.i"
	include "exec/resident.i"
	include "dos/dos_lib.i"
	include "dos/dos.i"
	include "misc/macros.i"




* la recherche & la sauvegarde
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~

	section toto,code

	lea DosName(pc),a1		ouvre la dos.library
	CALL (_SysBase).w,OpenLibrary
	move.l d0,d7			d5=_DosBase
	beq.s no_dos

	lea ScsiName(pc),a1		recherche le scsi.device
	CALL FindResident
	move.l d0,d6			d6=start device
	beq.s no_resident

	move.l d0,a0
	move.l RT_ENDSKIP(a0),d5
	sub.l d6,d5			d5=size device

	move.l #FileName,d1		ouvre le fichier de sortie
	move.l #MODE_NEWFILE,d2
	CALL d7,Open
	move.l d0,d4
	beq.s no_open

	move.l d4,d1			ecrit le device entièrement
	move.l d6,d2
	move.l d5,d3
	CALL Write

	move.l d4,d1
	CALL Close
no_open
no_resident
	move.l d7,a1
	CALL (_SysBase).w,CloseLibrary
no_dos
	moveq #0,d0
	rts


DosName
	dc.b "dos.library",0
ScsiName
	dc.b "scsi.device",0
FileName
	dc.b "ram:scsi.device",0
