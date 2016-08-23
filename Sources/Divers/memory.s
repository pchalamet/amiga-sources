
	incdir "hd1:include/"
	include "exec/exec_lib.i"
	include "exec/execbase.i"
	include "exec/memory.i"
	include "exec/lists.i"
	include "exec/nodes.i"

_ExecBase=4

	move.l (_ExecBase).w,a6

	move.w AttnFlags(a6),d0		c'est quoi le micropro ?
	and.b #$3,d0
	add.b #"0",d0
	move.b d0,micropro

	move.l MemList(a6),a0		list de node des regions
	lea memory_avaible(pc),a1
explore
	move.l MH_LOWER(a0),d0		\ bornes de la région
	move.l MH_UPPER(a0),d1		/
	and.l #$fff80000,d0		offset de 512 octets obligatoire
	add.l #$7ffff,d1		carte de 512 Ko minimum
	and.l #$fff80000,d1		offset de 512 octets obligatoire
	move.l d0,(a1)+			adresse de base de la mémoire
	sub.l d0,d1			calcul la taille de la mémoire
	move.l d1,(a1)+			sauve la taille de la mémoire
	move.w MH_ATTRIBUTES(a0),(a1)+	sauve le type de mémoire
	move.l (a0),a0
	tst.l (a0)
	bne.s explore
end	move.l #-1,(a1)			signal la fin de la liste
	rts

		dc.b "c'est un 680"
micropro	dc.b "x0 !!"
memory_avaible	dcb.l 50,0

