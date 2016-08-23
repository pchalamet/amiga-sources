
* Structures d'Exec
* ~~~~~~~~~~~~~~~~~
EXEC_AttnFlags=$128
EXEC_MemList=$142
EXEC_MH_Attributes=$E
EXEC_MH_Lower=$14
EXEC_MH_Upper=$18

EXEC_Chip=1<<1
EXEC_Fast=1<<2
exec_base=4

* Structure du Template_Memory
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	rsreset
Struct_Template_Memory	rs.b 0
tm_Lower		rs.l 1
tm_Upper		rs.l 1
tm_Kind			rs.w 1
tm_SIZEOF		rs.b 0

* Les includes pour le hardware et ALU
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	incdir "asm:.s/ALU/"
	include "ALU_registers.i"
	include "ALU_Def.i"


* Meurtre d'Exec!
* ~~~~~~~~~~~~~~~
	lea Supervisor(pc),a0
	move.l a0,$80.w
	trap #0
Supervisor
	move.l a6,a0				a0=exec_base
	lea data_base(pc),a5
	lea custom_base,a6
	move.w #$7fff,intena(a6)		vire les IT
	move.w #$7fff,intreq(a6)
	move.w #$7fff,dmacon(a6)		vire les DMAs
	move.w #$000,color00(a6)		couleur $000 pour le fond
	clr.l (exec_base).w			vire exec

* Recherche du microprocesseur et de ses sbires
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.w EXEC_AttnFlags(a0),(ALU_Micropro).w

* Recherche de toute la mémoire disponible
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.l EXEC_MemList(a0),a0
	lea Template_Memory_Space(pc),a1	zone provisoire de stockage
	moveq #0,d0				compteur de région
explore_MemList
	movem.l EXEC_MH_Lower(a0),d1-d2		bornes de la région
	and.l #$fff80000,d1			offset de 512 octets obligatoire
	beq do_Low_Memory			c'est la carte $0 ?
cont_Low_Memory
	add.l #$7ffff,d2			carte de 512 Ko minimum
	and.l #$fff80000,d2			offset de 512 octets obligatoire
	move.l d1,(a1)+				borne basse de la région
	move.l d2,(a2)+				borne haute de la région
	move.l EXEC_MH_Attributes(a0),d1	type de la carte
	and.w #%11,d1				garde que flags CHIP & FAST
	move.w d1,(a1)+				sauve le type
	addq.w #1,d0				une région en plus
	move.l (a0),a0				MemList suivante
	tst.l (a0)				pointe EXEC_LH_TAIL ?
	bne.s explore_MemList

* Création des MemLists de ALU
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	subq.w #1,d0				ya au moins une carte donc ok..
	lea Template_Memory_Space(pc),a0
	clr.l (ALU_Chip_Memory).w		\ rien pour l'instant
	clr.l (ALU_Fast_Memory).w		/
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
	clr.l (a2)				init la région : pas de Next
	move.l d1,4(a2)				taille du memory chunk

	moveq #ALU_Chip,d1
	lea (ALU_Chip_Memory).w,a2
	cmp.w #EXEC_Chip,tm_Kind(a0)
	beq.s Kind_Chip
	moveq #ALU_Fast,d1
	addq.l #4,a2				pointe ALU_Fast_Memory
Kind_Chip
	move.w d1,mh_Kind(a1)			init le type de la région

* Insertion de la MemList dans les listes de ALU
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*   ->	a0=Template_Memory_Space
*   	a1=MemList
*	a2=ALU_xxx_Memory
*	d0=Compteur MemList

	tst.l (a2)				c'est la première MemList ?
	beq.s First_MemList
Insert_MemList
	move.l (a2),a2				première entrée
	bra.s Search_Start
Search_End_MemList
	move.l mh_Next(a2),a2
Search_Start
	tst.l mh_Next(a2)			yen a encore ?
	bne.s Search_End_MemList

	move.l a1,mh_Next(a2)			et hop... c'est inséré !!
	lea tm_SIZEOF(a0),a0
	dbf d0,Create_MemList
	bra.s Relocate_ALU
	
First_MemList
	move.l a1,(a2)				stocke le ptr dans ALU_xxx_Memory
	lea tm_SIZEOF(a0),a0
	dbf d0,Create_MemList


* Relogement de ALU en $400 et initialisation de
* ~~~~~~~~~~~~~~~~~~~~~~~~~
Relocate_ALU
	lea $50000,a0
	lea $400.w,a1
	move.l #(10*512)/4-1,d0
Relocate
	move.l (a0)+,(a1)+
	dbf d0,Relocate

	lea LoadFile(pc),a0			nom du fichier à charger
	jmp $400


* Routine appellée quand on rencontre la carte $0
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
do_Low_Memory
	add.l #1024+10*512,d2			saute la table des vecteurs
	bra cont_Low_Memory			et ALU

data_base
Template_Memory_Space
	ds.b 20*tm_SIZEOF			pas plus de 40 cartes...

* Le copyright
* ~~~~~~~~~~~~
	dc.b "Amiga Loader Unit (ALU) v1.0  (c)1993 Sync of DreamDealers  "
