
	opt O+,OW-
	OUTPUT ram:X


* Les includes
* ~~~~~~~~~~~~
	incdir "include:"
	include "exec/execbase.i"
	include "exec/exec_lib.i"
	include	"exec/exec.i"
	include "exec/nodes.i"
	include "exec/memory.i"
	include "exec/tasks.i"
	include "dos/dos_lib.i"
	include "dos/dosextens.i"
	include "devices/trackdisk.i"
	include "misc/Macros.i"


* le point d'entrée
* ~~~~~~~~~~~~~~~~~
Main
	lea DataBase,a5
	move.l (_SysBase).w,a6
	move.l a6,_ExecBase(a5)

	lea Reply_Port(pc),a1
	move.l ThisTask(a6),a0			plus rapide que Findtask(0)
	move.l a0,MP_SIGTASK(a1)
	CALL AddPort				déclare notre port
	
	moveq #0,d0				lecteur DF0:
	moveq #0,d1				pas de flags
	lea TD_DeviceName(pc),a0		le nom du device
	lea TD_Struct(pc),a1			la structure pour le device
	CALL OpenDevice				ouvre le device
	tst.l d0
	bne error_opendevice

	lea DosName(pc),a1			ouvre la dos.library
	moveq #0,d0
	CALL OpenLibrary
	move.l d0,_DosBase(a5)
	beq no_dos

	CALL d0,Output				recherche la sortie standard
	move.l d0,StdOut(a5)

	CALL Input				recherche l'entrée standard
	move.l d0,StdIn(a5)

	bsr Recover_QB


	move.l _DosBase(a5),a1			ferme la dos.library
	CALL _ExecBase(a5),CloseLibrary
no_dos
	lea TD_Struct(pc),a1			ferme le trackdisk.device
	CALL CloseDevice

	lea Reply_Port(pc),a1			enlève le port
	CALL RemPort
error_opendevice
	moveq #0,d0				bye bye !
	rts


* Restauration des fichiers QB d'une serie de disk naz dans un meme dir
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Recover_QB
	lea TD_Struct(pc),a1			met en route le moteur
	move.w #TD_MOTOR,IO_COMMAND(a1)
	move.l #-1,IO_LENGTH(a1)
	CALL _ExecBase(a5),DoIO

	move.l #1760*2*512,d7
	lea Buffer+512,a3
	move.l a3,a2
Main_Loop
	cmp.l a2,a3
	bne.s .Search
	bsr Read_Sector
.Search
	cmp.l a2,a3				recherche la marque du début de fichier
	beq.s Main_Loop
	cmp.l #"FMRK",(a2)+
	bne.s .Search

fmrk_found
	move.l StdOut(a5),d1			écrit le nom du fichier
	move.l a2,d2
	move.l a2,a0
	moveq #-1,d3
.strlen
	tst.b (a0)+
	dbeq d3,.strlen
	not.l d3
	CALL _DosBase(a5),Write

	move.l StdOut(a5),d1			char return plizzz
	move.l #Msg_Return,d2
	moveq #2,d3
	CALL Write

	move.l a2,d1
	move.l #MODE_NEWFILE,d2
	CALL Open
	move.l d0,CurrFile(a5)
	beq.s not_opened

	lea 32(a2),a2				ouvre le fichier
	cmp.l a2,a3
	bgt.s .write
	move.l a2,d6				attention: c'est TOUJOURS 32 octets...
	sub.l a3,d6
	bsr Read_Sector
	lea (a2,d6.l),a2
.write
	move.l (a2)+,d6				taille du fichier
loop_write_file
	move.l a3,d0
	sub.l a2,d0				calcule la taille restante dans le buffer

	cmp.l d0,d6
	bge.s .ok
	move.l d6,d0
.ok
	sub.l d0,d6

	move.l CurrFile(a5),d1			ecrit ce kia dans le buffer
	move.l a2,d2
	move.l d0,d3
	CALL _DosBase(a5),Write
	cmp.l d0,d3
	bne exit_recover

	lea (a2,d0.l),a2			on est ici maintenant

	tst.l d6
	beq .end_of_file

	bsr Read_Sector
	bra loop_write_file

.end_of_file
	move.l CurrFile(a5),d1
	CALL _DosBase(a5),Close
	clr.l CurrFile(a5)

not_opened
	cmp.l a2,a3
	bne.s .not_end
	bsr Read_Sector
.not_end
	addq.l #4,a2				saute la taille du fichier juste écrit

	move.l a2,d0				pointe des LONG
	addq.l #3,d0
	and.l #~3,d0
	move.l d0,a2
	bra Main_Loop


* Routine de sortie
* ~~~~~~~~~~~~~~~~~
exit_recover_read
	addq.l #4,sp
exit_recover
	move.l CurrFile(a5),d1			ferme le fichier si ouvert
	beq.s .no_open
	CALL _DosBase(a5),Close
	clr.l CurrFile(a5)
.no_open
	lea TD_Struct(pc),a1			arrete le moteur
	move.w #TD_MOTOR,IO_COMMAND(a1)
	clr.l IO_LENGTH(a1)
	CALL _ExecBase(a5),DoIO
	rts


Read_Sector
	cmp.l #1760*2*512,d7			fin du disk ?
	bne.s .no_change

	lea TD_Struct(pc),a1			arrete le moteur
	move.w #TD_MOTOR,IO_COMMAND(a1)
	clr.l IO_LENGTH(a1)
	CALL _ExecBase(a5),DoIO

	move.l StdOut(a5),d1			ecrit le message
	move.l #Msg_Ask_Disk,d2
	move.l #Msg_Ask_Disk_Size,d3
	CALL _DosBase(a5),Write

	move.l StdIn(a5),d1			lit un char
	move.l #Buffer,d2
	moveq #1,d3
	CALL Read

	cmp.b #"n",Buffer			on sort ?
	beq exit_recover_read

	lea TD_Struct(pc),a1			arrete le moteur
	move.w #TD_MOTOR,IO_COMMAND(a1)
	move.l #-1,IO_LENGTH(a1)
	CALL _ExecBase(a5),DoIO

	moveq #0,d7
.no_change
	lea TD_Struct(pc),a1
	move.w #CMD_READ,IO_COMMAND(a1)		on fait de la lecture
	move.l #Buffer,IO_DATA(a1)		adr du buffer en chip
	move.l #512,IO_LENGTH(a1)		longueur à lire
	move.l d7,IO_OFFSET(a1)			met l'offset
	CALL _ExecBase(a5),DoIO
	add.l #512,d7
	lea Buffer,a2
	rts



*************************************************************************************************


			*******************************
			* STRUCTURE POUR LE TRACKDISK *
			*******************************
TD_Struct
	dc.l 0				LN_SUCC
	dc.l 0				LN_PRED
	dc.b NT_DEVICE			LN_TYPE
	dc.b 0				LN_PRI
	dc.l 0				LN_NAME
	dc.l Reply_Port			MN_REPLYPORT
	dc.l 0				IO_DEVICE
	dc.l 0				IO_UNIT
	dc.w 0				IO_COMMAND
	dc.b 0				IO_FLAGS
	dc.b 0				IO_ERROR
	dc.w 0				IO_SIZE
	dc.l 0				IO_ACTUAL
	dc.l 0				IO_LENGTH
	dc.l 0				IO_DATA
	dc.l 0				IO_OFFSET
	dc.l 0				IOTD_COUNT
	dc.l 0				IOTD_SECLABEL
Reply_Port
	dc.l 0				LN_SUCC
	dc.l 0				LN_PRED
	dc.b NT_REPLYMSG		LN_TYPE
	dc.b 0				LN_PRI
	dc.l Reply_Port_Name		LN_NAME
	dc.b 0				MP_FLAGS
	dc.b 0				MP_SIGBIT
	dc.l 0				MP_SIGTASK
	dc.l *+4			LH_HEAD
	dc.l 0				LH_TAIL
	dc.l *-8			LH_TAILPRED
	dc.b NT_REPLYMSG		LH_TYPE
	dc.b 0				LH_PAD	

DosName
	dc.b "dos.library",0
TD_DeviceName
	dc.b "trackdisk.device",0
Reply_Port_Name
	dc.b "fuck da qback",0
Msg_Ask_Disk
	dc.b "Disk suivant plizzz",10
Msg_Ask_Disk_Size=*-Msg_Ask_Disk
Msg_Return
	dc.b 13,10
	


* les datas du prog
* ~~~~~~~~~~~~~~~~~
	section bidochon,bss
	rsreset
DataBase_Struct		rs.b 0
_ExecBase		rs.l 1
_DosBase		rs.l 1
StdOut			rs.l 1
StdIn			rs.l 1
CurrFile		rs.l 1
DataBase_SIZEOF=__RS-DataBase_Struct

DataBase
	ds.b DataBase_SIZEOF


* le buffer pour le trackdisk
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~
	section trouduc,bss_c
Buffer
	ds.b 512
