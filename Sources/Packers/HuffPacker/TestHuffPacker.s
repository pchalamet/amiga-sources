
*		Routine de test pour HuffPacker v1.2
*		------------------------------------

	include "asm:sources/registers.i"

	section warf,code_f

	lea Source(pc),a0
	lea Destination,a1
	lea Buffer,a2
	bsr HP_Decrunch
	rts

	include "asm:.s/HuffPacker/HuffDecrunch1.2.s"

Source
	incbin "ram:toto"
Destination
	dcb.b 54400,0
Buffer
	dcb.b 3688,0

