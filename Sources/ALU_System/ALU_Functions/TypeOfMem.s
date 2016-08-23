
*			  Amiga Loader Unit (ALU)
*			  ~~~~~~~~~~~~~~~~~~~~~~~
*			 (c)1994 Sync/DreamDealers
*
*			 	Type Of Mem



*********************************
* renseigne sur le type de	*
* mémoire			*
*				*
* en entrée: a0=adr		*
*				*
* en sortie: d0=ALU_Mem_Chip	*
*		ou		*
*		ALU_Mem_Fast	*
*		ou		*
*		ALU_Mem_Unknown *
*********************************
	even
TypeOfMem
	move.l d1,-(sp)

	moveq #ALU_Mem_Chip,d0
	move.l ALU_Mem_Chip(a6),d1
	bsr.s .search

	moveq #ALU_Mem_Fast,d0
	move.l ALU_Mem_Fast(a6),d1
	bsr.s .search

	moveq #ALU_Mem_Unknown,d0
	move.l (sp)+,d1
	rts

.search
	move.l a1,-(sp)
	bra.s .start_search
.loop_search
	move.l d1,a1			est-ce que l'adr est dans ce block ?
	cmp.l mh_Lower(a1),a0
	blt.s .skip
	cmp.l mh_Upper(a1),a0
	bge.s .skip

* on l'a trouve : on sort en dépilant ce qu'il y a sur la pile
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.l (sp)+,a1
	addq.l #4,sp			bouffe le 'bsr.s .search'
	move.l (sp)+,d1
	rts

* c'est pas ici donc on passe à la suite
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.skip
	move.l mh_Next(a1),d1
.start_search
	bne.s .loop_search
	move.l (sp)+,a1
	rts

	
