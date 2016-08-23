
*			Amiga Loader Unit (ALU) v1.0
*			~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*			 (c)1994 Sync/DreamDealers



* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ *
* Tout le system est en relative PC donc ALU peut etre placé *
* n'importe oû en mémoire et déplacé s'il le faut            *
* => utilisation d'un pointeur : ALU_Base pour appeller les  *
*    fonctions d'ALU                                         *
*    ALU_Base est stocké dans l'offset 4 de la table des     *
*    vecteur ( faire gaffe au VBR )                          *
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
	include "ALU_registers.i"
	include "ALU_Def.i"





************************
test
	lea DataBase(pc),a5
	move.l #my_memory,Chip_Memory(a5)

	moveq #10,d0
	moveq #0,d1
	bsr AllocMem
	move.l d0,d2

	moveq #10,d0
	moveq #0,d1
	bsr AllocMem
	move.l d0,d3

	move.l d2,d0
	moveq #10,d1
	bsr FreeMem

	move.l d3,d0
	moveq #10,d1
	bsr FreeMem

	rts
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
	lea DataBase(pc),a5
	lea _Custom,a6
	move.w #$7fff,dmacon(a6)		vire tout !
	move.w #$7fff,intena(a6)
	move.w #$7fff,intreq(a6)
	clr.l (_SysBase).w

* Recherche le type du micropro et de ses sbires
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.w EXEC_AttnFlags(a0),Micropro(a5)

* Fabrication des memory headers & chunks d'ALU
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.l EXEC_MemList(a0),a0
Explore_MemList
	movem.l EXEC_MH_Lower(a0),d0/d1		bornes de la région
	and.l #$fff80000,d0			offset de 512 octets obligatoire
	add.l #$7ffff,d1			carte de 512 Ko minimum
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
	move.l Fast_Memory(a5),mh_Next(a1)
	move.l d0,Fast_Memory(a5)
	bra.s Test_Explore_Next

Insert_Chip
	move.l Chip_Memory(a5),mh_Next(a1)
	move.l d0,Chip_Memory(a5)

Test_Explore_Next
	tst.l d2				pointe EXEC_LH_TAIL ?
	bne.s Explore_MemList







********************************************************************************

*********************************
* Allocation de mémoire		*
*				*
* en entrée: d0=Taille		*
*            d1=Any/Chip/Fast	*
*				*
* en sortie: d0=Adresse ou NULL *
*********************************
AllocMem
	move.l a5,-(sp)
	lea DataBase(pc),a5

	addq.l #mc_SIZEOF-1,d0			multiple des memory chunks
	and.l #~(mc_SIZEOF-1),d0

	tst.b d1
	beq.s AllocMem_Chip
	bpl.s AllocMem_Fast
AllocMem_Any
	move.l Fast_Memory(a5),d1		essaye en Chip d'abord
	bsr.s Real_AllocMem
	tst.l d0
	bne.s .ok

	move.l Chip_Memory(a5),d1		en Chip si ca a foiré
	bsr.s Real_AllocMem
.ok	move.l (sp)+,a5
	rts

AllocMem_Chip
	move.l Chip_Memory(a5),d1
	bsr.s Real_AllocMem
	move.l (sp)+,a5
	rts

AllocMem_Fast
	move.l Fast_Memory(a5),d1
	bsr.s Real_AllocMem
	move.l (sp)+,a5
	rts


Real_AllocMem
	movem.l a0-a3,-(sp)
	bra.s .start_allocmem

.search_allocmem
	move.l d1,a0

	lea mh_First(a0),a1			commence avec le premier
	move.l mh_First(a0),d1			chunk
	bra.s .start_mem_chunk

.search_mem_chunk
	move.l d1,a2
	cmp.l mc_Size(a2),d0			le chunk est assez grand ?
	bgt.s .next_mem_chunk
	beq.s .remove_chunk			c'est carrement egal ?

.truncate_chunk
	lea (a2,d0.l),a3
	move.l a3,mc_Next-mc_Next(a1)		vire déja le morceau de
	move.l mc_Size(a2),d1			mémoire
	sub.l d0,d1				fabrique le nouveau memory
	move.l d1,mc_Size(a3)			chunk
	move.l mc_Next(a2),mc_Next(a3)		link le nouveau mem_chunk
	move.l a2,d0
	movem.l (sp)+,a0-a3
	rts	

.remove_chunk
	move.l mc_Next(a2),mc_Next-mc_Next(a1)	vire le mem_chunk
	move.l a2,d0
	movem.l (sp)+,a0-a3
	rts

.next_mem_chunk
	lea mc_Next(a2),a1			sauve l'adr du chunk précédent
	move.l mc_Next(a2),d1			chunk suivant si yen a d'autres
.start_mem_chunk
	bne.s .search_mem_chunk

.next_mem_header
	move.l mh_Next(a0),d1			header suivant si yen a d'autres
.start_allocmem
	bne.s .search_allocmem
	moveq #0,d0
	movem.l (sp)+,a0-a3
	rts



*********************************
* Libération de mémoire		*
*				*
* en entrée: d0=Adr block mem	*
*            d1=Taille du block *
*********************************
FreeMem
	movem.l d2/a5,-(sp)
	lea DataBase(pc),a5

	addq.l #mc_SIZEOF-1,d1			multiple des memory chunks
	and.l #~(mc_SIZEOF-1),d1

	move.l Chip_Memory(a5),d2
	bsr.s Real_FreeMem

	tst.l d0				le block a été libéré ?
	beq.s .skip
	move.l Fast_Memory(a5),d2
	bsr.s Real_FreeMem
.skip
	movem.l (sp)+,d2/a5
	rts

Real_FreeMem
	movem.l a0-a2,-(sp)
	bra.s .start_freemem
.search_freemem
	move.l d2,a0				la memoire est dans cette
	cmp.l mh_Lower(a0),d0			région ?
	blt.s .not_there
	cmp.l mh_Upper(a0),d0
	bgt.s .not_there
.there
	lea mh_First(a0),a1
	move.l mh_First(a0),d2			voui !
	bra.s .start_search_chunk
.search_chunk
	move.l d2,a2				la mémoire est dans ce
	cmp.l d0,d2				chunk ?
	bge.s .found
	lea mc_Next(a2),a1
	move.l mc_Next(a2),d2
.start_search_chunk
	bne.s .search_chunk
.last
	move.l d0,a0				c'est en fait le dernier
	move.l d1,(a0)+				chunk
	clr.l mc_Next-mc_Next(a0)
	move.l d0,mc_Next-mc_Next(a1)		le premier chunk
	bra.s .chk_previous

.found
	move.l d0,a0				création d'un chunk en
	move.l d1,(a0)+				plein milieu
	move.l a2,mc_Next-mc_Next(a0)
	move.l d0,mc_Next-mc_Next(a1)
.chk_next
	move.l d0,d2
	add.l d1,d2				on a réussi a recoller 2
	cmp.l a2,d2				chunks consécutifs ?
	bne.s .chk_previous
**** memory list corrupt:  bgt

	add.l mc_Size(a2),d1
	move.l d1,mc_Size-mc_Next(a0)
	move.l mc_Next(a2),mc_Next-mc_Next(a0)

.chk_previous
	move.l mc_Size-mc_Next(a1),d2		c'est le premier chunk ?
	beq.s .exit_freemem
	add.l a1,d2
	cmp.l d0,d2
	bne.s .exit_freemem
**** memory list corrupt : bgt

	move.l mc_Next-mc_Next(a0),mc_Next-mc_Next(a1)
	add.l d1,mc_Size-mc_Next(a1)

.exit_freemem
	moveq #0,d0
	movem.l (sp)+,a0-a2
	rts

.not_there
	move.l mh_Next(a0),d2
.start_freemem
	bne.s .search_freemem
	movem.l (sp)+,a0-a2
	rts





********************************************************************************

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


* Les datas de ALU
* ~~~~~~~~~~~~~~~~
	rsset -DATABASE_OFFSET
Struct_DataBase		rs.b 0
Chip_Memory		rs.l 1
Fast_Memory		rs.l 1
Micropro		rs.w 1
DataBase_SIZEOF=__RS-Struct_DataBase

	CNOP 0,4
DataBase=*+DATABASE_OFFSET
	ds.b DataBase_SIZEOF

* end of file *
