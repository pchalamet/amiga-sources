
	section dae,code

	lea source,a0
	lea dest,a1
	bsr decrunch
	rts

	include "BKMP_Decrunch.s"

source
	incbin "dh1:battle.pak"

	section fea,bss
dest
	ds.b $55c40
fin

