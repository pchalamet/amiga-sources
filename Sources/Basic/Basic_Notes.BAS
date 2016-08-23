
*
* "0" -> Integer
* "1" -> String
* "T" -> TO
*


A=INTEGRATE(X*X,1 to 2)

TK
	dc.w Print_Rout-TK,Print_SIZE
	dc.b "PRINT",0
	dc.b "1",0
	even





Print_Rout
	rts
Print_SIZE=*-Print_Rout

