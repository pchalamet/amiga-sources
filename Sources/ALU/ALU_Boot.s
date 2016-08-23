

*			Amiga Loader Unit (ALU) v1.0
*			~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*				    Boot
*				    ~~~~

* Les includes systemes pour le boot uniquement...
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	incdir "hd1:include/"
	include "exec/execbase.i"
	include "exec/exec_lib.i"
	include "exec/io.i"
	include "intuition/intuition_lib.i"
	include "intuition/intuition.i"
	include "devices/trackdisk.i"
	include "misc/macros.i"

* Options de compilation
* ~~~~~~~~~~~~~~~~~~~~~~
	OPT C+,O+,OW+

	section ALU_Boot,code

* Le boot commence ici
* ~~~~~~~~~~~~~~~~~~~~
*   ->	A1=TD_STRUCT
*	A6=exec_base
*
	dc.b "DOS",0
	dc.l 0
	dc.l 0

* Regarde d'abord le type du microprocesseur
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	lea AlertAbsolete(pc),a0
	move.w AttnFlags(a6),d0
	btst #AFB_68020,d0			hey.. c koi le micropro ?
	beq.s Do_Alert


* Allocation de mémoire pour charger ALU ( de facon temporaire )
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.l a1,-(sp)

	move.l #10*512,d0			alloue 10*512 octets
	moveq #0,d1
	CALL AllocMem

	lea AlertMemory(pc),a0			on prevoit...
	move.l (sp)+,a1
	move.l d0,IO_DATA(a1)			IO_DATA
	beq.s Do_Alert				au fait.. on l'a eut cette
	move.l d0,-(sp)				mémoire ???
	move.w #CMD_READ,28(a1)			IO_COMMAND ( CMD_READ )
	move.l #1*512,IO_OFFSET(a1)		IO_OFFSET
	move.l #10*512,IO_LENGTH(a1)		IO_LENGTH
	CALL DoIO				DoIO ( charge ALU )

	move.w #TD_MOTOR,28(a1)			IO_COMMAND ( TD_MOTOR )
	clr.l IO_LENGTH(a1)			IO_LENGTH ( MOTOR_OFF )
	CALL DoIO				DoIO ( arrete le moteur )

	move.l (sp)+,a0				adresse d'init d'ALU
	jmp (a0)				et hop , c parti !!!


* Ya une erreur => on affiche une alerte
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Do_Alert
	move.l a0,-(sp)				sauve l'alerte

	lea IntuitionName(pc),a1		ouvre l'intuition.library
	moveq #0,d0				pour faire un DisplayAlert()
	move.l 4.w,a6
	CALL OpenLibrary
	tst.l d0				euh.. ca a marché ??
	beq.s oulala

	move.l d0,a6				affiche l'alert
	move.l #DEADEND_ALERT,d0
	moveq #35,d1
	move.l (sp)+,a0
	jmp _LVODisplayAlert(a6)		on n'est pas censé revenir...

* Ya pa memoire
* Ya pa intuition
* Ya pa ALU
* Mais ya de la merde => nettoyage de printemps avec un beau GURU !!!!
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
oulala
	illegal

IntuitionName
	INTNAME

AlertMemory
	dc.b 0,180,15,"AmIgA LoAdEr UnIt (ALU) v1.0 ReQuEsT",0,1
	dc.b 0,180,25,"Ooops ! NoT EnOuGh MeMoRy... HaHaHa!",0,0

AlertAbsolete
	dc.b 0,180,15,"AmIgA LoAdEr UnIt (ALU) v1.0 ReQuEsT",0,1
	dc.b 0,180,25,"Ooops ! NoT A 68020 Or MoRe... HiHi!",0,0

Copyright
	dc.b "$VER:"
	dc.b "-- AmIgA LoAdeR UnIt (ALU) v1.0  (c)1994 SyNc Of DrEaMdEaLeRs --",10
	dc.b "        -- CaLl DrEaMlAnDs At:   +33  32 39 79 23 --",10
	dc.b "               -- 1.2 GiGaByTeS OnLine !!! --",0
