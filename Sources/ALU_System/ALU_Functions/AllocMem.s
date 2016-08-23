
*			  Amiga Loader Unit (ALU)
*			  ~~~~~~~~~~~~~~~~~~~~~~~
*			 (c)1994 Sync/DreamDealers
*
*			   Allocation de mémoire



*********************************
* Allocation de mémoire		*
*				*
* en entrée: d0=Taille		*
*            d1=Flags		*
*				*
* en sortie: d0=Adresse ou NULL *
*********************************
	even
AllocMem
	addq.l #mc_SIZEOF-1,d0			multiple des memory chunks
	and.l #~(mc_SIZEOF-1),d0

	movem.l d0/d2/a0,-(sp)

.try_fast
	btst #ALU_Mem_Fast_B,d1			Allocation en Fast ?
	beq.s .try_chip
	move.l ALU_Fast_Memory(a6),d2
	bsr.s Real_AllocMem
	tst.l d0
	bne.s .done

.try_chip
	btst #ALU_Mem_Chip_B,d1			Allocation en Chip ?
	beq.s .no_mem
	move.l (sp),d0
	move.l ALU_Chip_Memory(a6),d2
	bsr.s Real_AllocMem
	tst.l d0
	beq.s .no_mem

.done
.check_clear
	btst #ALU_Mem_Clear_B,d1		on efface le block ?
	beq.s .no_clear

	move.l d0,a0
	move.l (sp),d2
	lsr.l #3,d2
.clear	clr.l (a0)+
	clr.l (a0)+
	subq.l #1,d2
	bne.s .clear
.no_clear
.no_mem
	addq.l #4,sp				bouffe d0
	movem.l (sp)+,d2/a0
	rts





Real_AllocMem
	movem.l a1-a3,-(sp)
	bra.s .start_allocmem

.search_allocmem
	move.l d2,a0

	lea mh_First(a0),a1			commence avec le premier
	move.l mh_First(a0),d2			chunk
	bra.s .start_mem_chunk

.search_mem_chunk
	move.l d2,a2
	cmp.l mc_Size(a2),d0			le chunk est assez grand ?
	bgt.s .next_mem_chunk
	beq.s .remove_chunk			c'est carrement egal ?

.truncate_chunk
	btst #ALU_Mem_Reverse_B,d1		Allocation en sens inverse ?
	bne.s .alloc_reverse
.alloc_normal
	lea (a2,d0.l),a3
	move.l a3,mc_Next-mc_Next(a1)		vire déja le morceau de
	move.l mc_Size(a2),d2			mémoire
	sub.l d0,d2				fabrique le nouveau memory
	move.l d2,mc_Size(a3)			chunk
	move.l mc_Next(a2),mc_Next(a3)		link le nouveau mem_chunk
	move.l a2,d0
	movem.l (sp)+,a1-a3
	rts	
.alloc_reverse
	sub.l d0,mc_Size(a3)			allocation en sens inverse
	lea (a2,d0.l),a2
	move.l a2,d0
	movem.l (sp)+,a1-a3
	rts

.remove_chunk
	move.l mc_Next(a2),mc_Next-mc_Next(a1)	vire le mem_chunk
	move.l a2,d0
	movem.l (sp)+,a1-a3
	rts

.next_mem_chunk
	lea mc_Next(a2),a1			sauve l'adr du chunk précédent
	move.l mc_Next(a2),d2			chunk suivant si yen a d'autres
.start_mem_chunk
	bne.s .search_mem_chunk

.next_mem_header
	move.l mh_Next(a0),d2			header suivant si yen a d'autres
.start_allocmem
	bne.s .search_allocmem
	moveq #0,d0
	movem.l (sp)+,a1-a3
	rts

