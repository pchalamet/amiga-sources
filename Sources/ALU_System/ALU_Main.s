
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
	OPT O+,OW+

* Les includes pour le hardware et ALU
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	incdir "ALU:"
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
	lea DataBase(pc),a5
	lea _Custom,a6
	move.w #$7fff,dmacon(a6)		vire tout !
	move.w #$7fff,intena(a6)
	move.w #$7fff,intreq(a6)
	clr.l (_SysBase).w

* Recherche le type du micropro et de ses sbires
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.w EXEC_AttnFlags(a0),Micropro(a5)

* Recherche des cartes mémoires disponibles à l'aide des MemoryLists d'EXEC
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.l EXEC_MemList(a0),a0
	lea Template_Memory_Space(a5),a1	zone provisoire de stockage
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
	and.l #EXEC_Chip|EXEC_Fast,d1		garde que flags CHIP & FAST
	move.l d1,(a1)+				sauve le type
	addq.w #1,d0				une région en plus
	move.l (a0),a0				MemList suivante
	tst.l (a0)				pointe EXEC_LH_TAIL ?
	bne.s explore_MemList

* Création des MemLists d'ALU
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.w d0,Nb_Template(a5)
	subq.w #1,d0				à cause du dbf...
	lea Template_Memory_Space(a5),a0
Create_MemList
	lea Chip_Memory(a5),a3
	cmp.l #EXEC_Chip,tm_Kind(a0)		c'est de la chip cette mémoire ?
	beq.s .insert
	lea Fast_Memory(a5),a3			nan.. c de la fast
.insert
	move.l tm_Lower(a0),a1
	move.l tm_Upper(a0),d1
	move.l d1,d2				recherche la taille du
	sub.l a1,d1				Memory Chunk

	lea mh_SIZEOF(a1),a2			init le Memory Header
	move.l a1,(a1)+				mh_Lower
	move.l d2,(a1)+				mh_Upper
	move.l a2,(a1)+				mh_First

	sub.l #mh_SIZEOF,d1			init le Memory Chunk
	move.l d1,(a2)+				mc_Size
	clr.l (a2)				mc_Next

	move.l (a3),mh_Next(a1)			insere le Memory Header au début
	move.l a1,(a3)

	lea tm_SIZEOF(a0),a0			on passe à la suite
	dbf d0,Create_MemList






*************************************************************************************************

* les fonctions publiques d'ALU
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*	l'appel des fonctions se fait comme suit:
*	jsr Function(a6)


* Allocation de mémoire
* ~~~~~~~~~~~~~~~~~~~~~
*   -->	d0.l=Taille à reserver
*	d1.l=type à reserver ( ALU_Any / ALU_Fast / ALU_Chip )
* <--	d0=Memory ou NULL
AllocMem
	lea DataBase(pc),a5

	addq.l #7,d0				on reserve des multiples de 8
	and.l #~7,d0

;	tst.b d1
;	bmi.s .alloc_any

	move.l Chip_Memory(a5,d1.w*4),d1	pointe le type de mémoire qu'on veut
	beq.s .exit_alloc
.loop_alloc
	move.l d1,a0	

	moveq #0,d1
	move.l mh_First(a0),d2			Premier Memory Chunk
	beq.s .quick_exit			il existe ?
.loop_alloc_chunk
	move.l d2,a1
	cmp.l mc_Size(a1),d0			la taille du Memory Chunk est bonne ?
	ble.s .found

	move.l a1,d1				passe au Memory Chunk suivant
	move.l mc_Next(a1),d2
.start_alloc
	bne.s .loop_alloc_chunk

.quick_exit
	move.l mh_Next(a0),d1
.alloc_memory
	bne.s .loop_alloc
.exit_alloc
	rts

* d0=Alloc Size
* d1=Memory Chunk précédent
* a0=Memory Header actuel
* a1=Memory Chunk actuel
* CCR set
.found
	beq.s .remove_chunk
.cut_chunk
	move.l mc_Size(a1),d2			calcul la taille restante
	sub.l d0,d2
	move.l mc_Next(a1),d3
	exg d0,a1
	add.l d0,a1				Memory Chunk à creer
	move.l d2,mc_Size(a1)
	move.l a1,mc_Next(a1)
.remove_chunk
	tst.l d1				yavait un Memory Chunk avant ?
	beq.s .remove_all

	move.l d1,a0				oui ! => insertion dans la liste
	move.l a1,mc_Next(a0)
	rts

.remove_all
	clr.l mh_First(a0)			nan! => vire tout !!
	rts



;;.alloc_any




*************************************************************************************************

* Les datas de ALU
* ~~~~~~~~~~~~~~~~
	rsset -DATABASE_OFFSET
Struct_DataBase		rs.b 0
Chip_Memory		rs.l 1
Fast_Memory		rs.l 1
Micropro		rs.w 1
Nb_Template		rs.w 1
Template_Memory_Space	rs.b 10*tm_SIZEOF	10 cartes max !!
DataBase_SIZEOF=__RS-Struct_DataBase

	CNOP 0,4
DataBase=*+DATABASE_OFFSET
	ds.b DataBase_SIZEOF

* end of file *
