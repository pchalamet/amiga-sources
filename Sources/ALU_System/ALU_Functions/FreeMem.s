
*			  Amiga Loader Unit (ALU)
*			  ~~~~~~~~~~~~~~~~~~~~~~~
*			 (c)1994 Sync/DreamDealers
*
*			   Libération de mémoire



*********************************
* Libération de mémoire		*
*				*
* en entrée: a0=Adr block mem	*
*            d0=Taille du block *
*********************************
	even
FreeMem
	move.l d1,-(sp)

	addq.l #mc_SIZEOF-1,d0			multiple des memory chunks
	and.l #~(mc_SIZEOF-1),d0

	move.l ALU_Chip_Memory(a6),d1
	bsr.s Real_FreeMem

	tst.l d0				le block a été libéré ?
	beq.s .skip
	move.l ALU_Fast_Memory(a6),d1
	bsr.s Real_FreeMem
.skip
	move.l (sp)+,d1
	rts

Real_FreeMem
	movem.l a1-a2,-(sp)
	bra.s .start_freemem
.search_freemem
	move.l d1,a1				la memoire est dans cette
	cmp.l mh_Lower(a1),a0			région ?
	blt.s .not_there
	cmp.l mh_Upper(a1),a0
	bgt.s .not_there
.there
	lea mh_Head(a1),a1			la mémoire est dans le coin !
	move.l mh_First-mh_Head(a1),d2
	bra.s .start_search_chunk
.search_chunk
	move.l d2,a2				la mémoire est dans ce
	cmp.l a0,d2				chunk ?
	bge.s .found
	move.l a2,a1
	move.l mc_Next(a2),d2
.start_search_chunk
	bne.s .search_chunk
.last
	move.l d0,(a0)				fabrique un chunk en fin
	clr.l mc_Next(a0)			de liste
	move.l a0,mc_Next(a1)
	bra.s .chk_previous

.found
	move.l d0,(a0)				fabrique un chunk en plein
	move.l a2,mc_Next(a0)			milieu
	move.l a0,mc_Next(a1)
.chk_next
	move.l a0,d1				on a 2 chunks qui se suivent
	add.l d0,d1				à droite ?
	cmp.l a2,d1
	bne.s .chk_previous
**** memory list corrupt:  bgt
	add.l mc_Size(a2),d0
	move.l d0,mc_Size(a0)
	move.l mc_Next(a2),mc_Next(a0)
.chk_previous
	move.l mc_Size(a1),d1			on a 2 chunks qui se suivent
	beq.s .exit_freemem			à gauche ?
	add.l a1,d1
	cmp.l a0,d1
	bne.s .exit_freemem
**** memory list corrupt : bgt
	move.l mc_Next(a0),mc_Next(a1)
	add.l d0,mc_Size(a1)

.exit_freemem
	moveq #0,d0
	movem.l (sp)+,a1-a2
	rts

.not_there
	move.l mh_Next(a1),d1
.start_freemem
	bne.s .search_freemem
**** freeing unknown memory
	movem.l (sp)+,a1-a2
	rts


