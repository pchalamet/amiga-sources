
*			Rajoute les 2 megas de la PicassoII
*			dans les memory-lists de l'Amiga...
*			~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

	incdir "include:"
	include "exec/execbase.i"
	include "exec/exec_lib.i"
	include "exec/nodes.i"
	include "exec/lists.i"
	include "exec/memory.i"
	include "misc/macros.i"


	section cool,code

* On fabrique d'abord le memory header dans le ram de la picassoII
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	lea $200000,a0
	clr.l (a0)+				LN_SUCC
	clr.l (a0)+				LN_PRED
	move.b #NT_MEMORY,(a0)+			LN_TYPE
	move.b #10,(a0)+			LN_PRI
	clr.l (a0)+				LN_NAME

	move.w #MEMF_FAST,(a0)+			MH_ATTRIBUTES
	move.l #$200000+MH_SIZE,(a0)+		MH_FIRST
	move.l #$200000+MH_SIZE,(a0)+		MH_LOWER
	move.l #$200000+$200000,(a0)+		MH_UPPER
	move.l #$200000-MH_SIZE,(a0)+		MH_FREE

	clr.l (a0)+				MC_NEXT
	move.l #$200000-MH_SIZE,(a0)+		MC_BYTES

	CALL (_SysBase).w,Disable		vire le multitache

	lea MemList(a6),a0			ajoute le memory header
	lea $200000,a1
	ADDHEAD

	CALL Enable				remet le multitache

	moveq #0,d0				c tout bon !
	rts
