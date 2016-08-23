
*			Amiga Loader Unit (ALU) v1.0
*			~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*			 (c)1994 Sync/DreamDealers
*
*				Code d'Init



* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ *
* Tout le system est en relative PC donc ALU peut etre placé *
* n'importe oû en mémoire et déplacé s'il le faut            *
* => utilisation d'un pointeur : _AluBase pour appeller les  *
*    fonctions d'ALU                                         *
*  ex:  jsr ALU_AllocMem(a6)				     *
*                                                            *
* Seuls le contenus des registres pour le passage de         *
* parametres sont detruits				     *
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



********************************************************************************
*               Le point d'entrée d'ALU juste après le boot		       *
********************************************************************************
ALU_Init
	lea ALU_Supervisor(pc),a0		passe en superviseur histoire
	move.l a0,$80.w				d'avoir TOUTES les instructions
	trap #0

ALU_Supervisor
	lea _Custom,a5
	move.w #$7fff,d0
	move.w d0,dmacon(a5)			vire tout !
	move.w d0,intena(a5)
	move.w d0,intreq(a5)

	lea ALU_DataBase(pc),a6

* Recherche le type du micropro et de ses sbires
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.l (_SysBase).w,a0
	clr.l (_SysBase).w
	move.w EXEC_AttnFlags(a0),ALU_Micropro(a6)

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
	move.w EXEC_MH_Attributes(a0),d2
	move.l (a0),a0				région suivante
	move.l (a0),d3				flag de fin de la liste

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
	and.w #EXEC_Chip,d2			c'est de la Chip memory ?
	bne.s Insert_Chip
Insert_Fast
	move.l ALU_Fast_Memory(a6),mh_Next(a1)
	move.l d0,ALU_Fast_Memory(a6)
	bra.s Test_Explore_Next

Insert_Chip
	move.l ALU_Chip_Memory(a6),mh_Next(a1)
	move.l d0,ALU_Chip_Memory(a6)

Test_Explore_Next
	tst.l d3				pointe EXEC_LH_TAIL ?
	bne.s Explore_MemList


* Allocation d'une pile d'1 Ko
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.l #1024,d0				alloue de la mémoire pour
	moveq #ALU_Mem_Any,d1			la pile supervisor
	CALL AllocMem
	tst.l d0
	beq.s Error_Init
	add.l #1024,d0
	move.l d0,sp

* Relocation d'ALU
* ~~~~~~~~~~~~~~~~
	move.l #End_ALU_System-ALU_System,d0	alloue de la mémoire pour
	moveq #ALU_Mem_Any,d1			le système lui-meme
	CALL AllocMem
	move.l d0,d2
	beq.s Error_Init

	lea ALU_System(pc),a0			oui => reloge le système
	move.l d0,a1
	move.w #(End_ALU_System-ALU_System+3)/4-1,d1
.relocate
	move.l (a0)+,(a1)+
	dbf d1,.relocate

	add.l #ALU_DataBase-ALU_System,d2	recherche la nouvelle adr
	move.l d2,(_AluBase).w			du  system
	move.l d2,a6

* Alloue de la mémoire en Chip pour l'écran de Debug et sa coplist
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.l #40*256+Coplist_Size,d0		alloue de la mémoire pour
	moveq #ALU_Mem_Chip,d1			l'écran + la coplist
	CALL AllocMem
	move.l d0,ALU_Screen(a6)
	beq.s Error_Init

	lea scr_ptr+2(pc),a0			installe les ptrs videos
	move.w d0,4(a0)
	swap d0
	move.w d0,(a0)

	swap d0					recopie la coplist en Chip
	add.l #40*256,d0
	move.l d0,ALU_Coplist(a6)
	lea Coplist(pc),a0
	move.l d0,a1
	moveq #Coplist_Size/4-1,d0
.dup	move.l (a0)+,(a1)+
	dbf d0,.dup


* On saute finalement au startup-code d'ALU
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	jmp ALU_System-ALU_DataBase(a6)

* En cas d'erreur pendant l'init
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Error_Init
	move.w #$f00,_Custom+color00
	bra Error_Init


Coplist
	dc.w fmode,$0
	dc.w bplcon0,$1200
	dc.w bplcon1,0
	dc.w bplcon2,0
	dc.w ddfstrt,$38
	dc.w ddfstop,$d0
	dc.w diwstrt,$2b81
	dc.w diwstop,$2bc1
	dc.w bpl1mod,0
	dc.w bpl2mod,0
	dc.w color00,$53b
	dc.w color01,$fff
scr_ptr	dc.w bpl1ptH,0
	dc.w bpl1ptL,0
	dc.l $fffffffe
Coplist_Size=*-Coplist








********************************************************************************
*                    Le system se trouve réellement ici			       *
* en entrée: a6=_AluBase						       *
********************************************************************************
ALU_System
	sub.l a0,a0
	CALL Debugger





********************************************************************************
*                    Toutes les fonctions publiques d'ALU		       *
********************************************************************************
	include "AllocMem.s"
	include "FreeMem.s"
	include "Debugger.s"

********************************************************************************
*                             Les datas d'ALU				       *
********************************************************************************
	CNOP 0,4
	DEF_FUNCTION Debugger
	DEF_FUNCTION FreeMem
	DEF_FUNCTION AllocMem
ALU_DataBase
	ds.b ALU_DataBase_SIZEOF

End_ALU_System

