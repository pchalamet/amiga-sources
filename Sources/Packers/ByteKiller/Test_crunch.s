

	move.l #start_data,start
	move.l #end_data,stop
	move.l #toto,write
	move.l #$1000,offset
	bsr crunch

	rts

	include "BKMP_crunch.s"

start_data
	dcb.b 1024,0
end_data
toto
	dcb.b 2000,0

