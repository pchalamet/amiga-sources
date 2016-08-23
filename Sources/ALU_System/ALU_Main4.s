
*			Amiga Loader Unit (ALU) v1.0
*			~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*			 (c)1994 Sync/DreamDealers



* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ *
* Tout le system est en relative PC donc ALU peut etre placé *
* n'importe oû en mémoire et déplacé s'il le faut            *
* => utilisation d'un pointeur : ALU_Base pour appeller les  *
*    fonctions d'ALU                                         *
*  ex:  jsr ALU_AllocMem(a6)				     *
*                                                            *
* Seuls le contenus des registres pour le passages de        *
* parametres sont detruits				     *
*                                                            *
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ *


DATABASE_OFFSET=0


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



* Options de compilation
* ~~~~~~~~~~~~~~~~~~~~~~
	OPT O+,OW-,OW6+

* Les includes pour le hardware et ALU
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	incdir "ALU:"
	incdir "ALU:ALU_System/"
	incdir "ALU:ALU_System/ALU_Functions/"
	include "ALU_Registers.i"
	include "ALU_Private.i"
	include "ALU_Include.i"





************************
test
	lea ALU_DataBase(pc),a6
	move.l #my_memory,ALU_Chip_Memory(a6)

	moveq #10,d0
	moveq #0,d1
	CALL AllocMem
	move.l d0,d2

	moveq #10,d0
	moveq #0,d1
	CALL AllocMem
	move.l d0,d3

	move.l d2,d0
	moveq #10,d1
	CALL FreeMem

	move.l d3,d0
	moveq #10,d1
	CALL FreeMem
	rts


my_memory
	dc.l my_memory
	dc.l my_chunk+64
	dc.l 0
	dc.l 0
	dc.l my_chunk
	dc.l 0

my_chunk
	dc.l 64
	dc.l 0
	ds.b 64-4*2

************************




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
	lea ALU_DataBase(pc),a5
	lea _Custom,a6
	move.w #$7fff,dmacon(a6)		vire tout !
	move.w #$7fff,intena(a6)
	move.w #$7fff,intreq(a6)

* Recherche le type du micropro et de ses sbires
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.w EXEC_AttnFlags(a0),ALU_Micropro(a5)

* Fabrication des memory headers & chunks d'ALU
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.l EXEC_MemList(a0),a0
Explore_MemList
	movem.l EXEC_MH_Lower(a0),d0/d1		bornes de la région
	and.l #$fff80000,d0			offset de 512 octets obligatoire
	bne.s .skip
	add.l #1024,d0				table des vecteurs
.skip	add.l #$7ffff,d1			carte de 512 Ko minimum
	and.l #$fff80000,d1			offset de 512 octets obligatoire
	move.l (a0),a0				région suivante
	move.l (a0),d2				flag de fin de la liste

* Fabrication du Memory Header et du premier Memory Chunk
	move.l d0,a1
	move.l d0,(a1)+				borne basse de la région
	move.l d1,(a1)+				borne haute de la région
	sub.l d0,d1				\ taille de la région
	sub.l #mh_SIZEOF,d1			/
	clr.l (a1)+				mh_Flags
	clr.l (a1)+				mh_Head
	addq.l #mh_SIZEOF-mh_First,a1
	clr.l mh_Next-mh_SIZEOF(a1)		Memory Header suivant
	move.l a1,mh_First-mh_SIZEOF(a1)	adresse du premier chunk
	move.l d1,(a1)+				taille du chunk
	clr.l (a1)+				chunk suivant

	move.l d0,a1
	btst.b #1,EXEC_MH_Attributes+3(a0)	c'est de la chip ?
	bne.s Insert_Chip
Insert_Fast
	move.l ALU_Fast_Memory(a5),mh_Next(a1)
	move.l d0,ALU_Fast_Memory(a5)
	bra.s Test_Explore_Next

Insert_Chip
	move.l ALU_Chip_Memory(a5),mh_Next(a1)
	move.l d0,ALU_Chip_Memory(a5)

Test_Explore_Next
	tst.l d2				pointe EXEC_LH_TAIL ?
	bne.s Explore_MemList







********************************************************************************
*                    Toutes les fonctions publiques d'ALU		       *
********************************************************************************
	include "AllocMem.s"
	include "FreeMem.s"


********************************************************************************
*                             Les datas d'ALU				       *
********************************************************************************
	CNOP 0,4
	DEF_FUNCTION FreeMem
	DEF_FUNCTION AllocMem
ALU_DataBase
	ds.b ALU_DataBase_SIZEOF

* end of file *
