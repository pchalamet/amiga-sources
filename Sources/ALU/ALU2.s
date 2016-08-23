
*			Amiga Loader Unit (ALU) v1.0
*			~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*			 (c)1993 Sync/DreamDealers



* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ *
* Tout le system est en relative PC donc ALU peut etre placé *
* n'importe oû en mémoire et déplacé s'il le faut            *
* => utilisation d'un pointeur : ALU_Base pour appeller les  *
*    fonctions d'ALU                                         *
*                                                            *
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ *


* Structures d'Exec
* ~~~~~~~~~~~~~~~~~
EXEC_AttnFlags=$128
EXEC_MemList=$142
EXEC_MH_Attributes=$E
EXEC_MH_Lower=$14
EXEC_MH_Upper=$18

EXEC_Chip=1<<1
EXEC_Fast=1<<2
_SysBase=4

* Structure du Template_Memory
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	rsreset
Struct_Template_Memory	rs.b 0
tm_Lower		rs.l 1
tm_Upper		rs.l 1
tm_Kind			rs.l 1
tm_SIZEOF		rs.b 0


* Options de compilation
* ~~~~~~~~~~~~~~~~~~~~~~
	OPT C+,O+
	OPT NODEBUG,NOLINE
	OPT P=68020

* Les includes pour le hardware et ALU
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	incdir "asm:.s/ALU/"
	include "ALU_registers.i"
	include "ALU_Def.i"


* Le point d'entrée d'ALU juste après le boot
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*  ->	a1=IoRequest du Trackdisk
*	a6=_SysBase

ALU_Init
	lea ALU_Supervisor(pc),a0		passe en superviseur histoire
	move.l a0,$80.w				d'avoir TOUTES les instructions 680x0
	trap #0
ALU_Supervisor
	move.l a6,a0
	lea ALU_Base(pc),a5
	lea _Custom,a6
	move.w #$7fff,dmacon(a6)		vire tout !
	move.w #$7fff,intena(a6)
	move.w #$7fff,intreq(a6)
	clr.l (_SysBase).w

* Recherche le type du micropro et de ses sbires
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.w EXEC_AttnFlags(a0),Micropro-ALU_Base(a5)

* Recherche des cartes mémoires disponibles à l'aide des MemoryLists d'EXEC
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.l EXEC_MemList(a0),a0
	lea Template_Memory_Space(pc),a1	zone provisoire de stockage
	moveq #0,d0				compteur de région
explore_MemList
	movem.l EXEC_MH_Lower(a0),d1-d2		bornes de la région
	and.l #$fff80000,d1			offset de 512 octets obligatoire
cont_Low_Memory
	add.l #$7ffff,d2			carte de 512 Ko minimum
	and.l #$fff80000,d2			offset de 512 octets obligatoire
	move.l d1,(a1)+				borne basse de la région
	move.l d2,(a1)+				borne haute de la région
	move.l EXEC_MH_Attributes(a0),d1	type de la carte
	and.l #%11,d1				garde que flags CHIP & FAST
	move.l d1,(a1)+				sauve le type
	addq.w #1,d0				une région en plus
	move.l (a0),a0				MemList suivante
	tst.l (a0)				pointe EXEC_LH_TAIL ?
	bne.s explore_MemList

* Création des MemLists d'ALU
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~
	subq.w #1,d0				à cause du dbf...
	lea Template_Memory_Space(pc),a0
Create_MemList
	move.l tm_Lower(a0),a1			création d'une MemList
	clr.l mh_Next(a1)			init mh_Next
	lea mh_SIZEOF(a1),a2			adresse de la région
	move.l a2,mh_First(a1)			init l'adresse du premier chunk
	move.l a2,mh_Lower(a1)			init la borne basse de la région
	move.l tm_Upper(a0),d1
	move.l d1,mh_Upper(a1)			init la borne haute de la région
	sub.l a2,d1
	move.l d1,mh_Free(a1)			init la taille de la région
	clr.l mc_Next(a2)			init la région : pas de Next
	move.l d1,mc_Bytes(a2)			taille du memory chunk

	moveq #ALU_Chip,d1
	lea Chip_Memory(pc),a2
	cmp.w #EXEC_Chip,tm_Kind(a0)
	beq.s Kind_Chip
	moveq #ALU_Fast,d1
	addq.l #4,a2				pointe ALU_Fast_Memory
Kind_Chip
	move.w d1,mh_Kind(a1)			init le type de la région

* Insertion de la MemList dans les listes d'ALU
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*   ->	a0=Template_Memory_Space
*   	a1=MemList
*	a2=ALU_xxx_Memory
*	d0=Compteur MemList

	move.l mh_Next(a2),d1			ya ty au moins une MemList ?
	beq.s Insert_MemList			nan => insère direct
Search_End_MemLists
	move.l d1,a2
	move.l mh_Next(a2),d1			récupère MemList suivante
	bne.s Search_End_MemLists
Insert_MemList
	move.l a1,mh_Next(a2)			insère la liste et basta !
	lea tm_SIZEOF(a0),a0
	dbf d0,Create_MemList


* Relocation d'ALU
* ~~~~~~~~~~~~~~~~
	move.l #(ALU_End-ALU_Start),d0
	moveq #ALU_Any,d1
	bsr AllocMem
	lea ALU_Start(pc),a0
	move.l d0,a1
	move.l #(ALU_End-ALU_Start+3)/4-1,d0
relocate_ALU
	move.l (a0)+,(a1)+
	dbf d0,relocate_ALU





ALU_Start

AllocMem
	



* Les datas de ALU
* ~~~~~~~~~~~~~~~~
	CNOP 0,4
ALU_Base:
Chip_Memory		dc.l 0
			dc.l 0
Fast_Memory		dc.l 0
			dc.l 0
Micropro		dc.w 0
ALU_End

Template_Memory_Space	dcb.b 10*tm_SIZEOF	10 cartes max !!
