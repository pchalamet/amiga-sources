
*		CLI Line Parser  by Sync\ThE SpeCiAl BrOthErS
*		--------------------------------------------------->


*  en entrée :	a0/d0 initialisés par le Dos  ;  a0=&CliLine  ; d0=Size
*		a1=&buffer
*  en sortie :	d0=nb d'arguments-1
*  d0-d2/a0-a2 trashed !!
MAXSIZEARGV=32
MAXARGC=3

line_parsing
	clr.b -1(a0,d0.w)			met un bo zero à la fin

	moveq #0,d0				Argc
	bra.s search_end_space
loop_parse_line
	clr.b (a2)
	addq.w #1,d0				incrémente argc
	lea MAXSIZEARGV(a1),a1			passe au buffer suivant
	cmp.w #MAXARGC,d0
	beq.s end_of_parsing
search_end_space
	cmp.b #" ",(a0)+			saute tous les espaces
	beq.s search_end_space
	move.l a1,a2				pointeur sur le buffer
	move.w #MAXSIZEARGV-2,d2
	tst.b -1(a0)				fin de la ligne ?
	beq.s end_of_parsing
	cmp.b #'"',-1(a0)			argument entre quotes ?
	beq.s quoted_arg	

	subq.l #1,a0				revient un peu en arriere
non_quoted_arg
	move.b (a0)+,d1
	beq.s end_non_quoted			fin de la ligne ?
	cmp.b #" ",d1				espace ?
	beq.s loop_parse_line
	move.b d1,(a2)+
	dbf d2,non_quoted_arg
end_non_quoted
	clr.b (a2)				met une zero en fin d'arguement
	addq.w #1,d0				incrémente argc
end_of_parsing
	rts

quoted_arg
	move.b (a0)+,d1
	beq.s end_of_parsing			fin de la ligne ?
	cmp.b #'"',d1				fin de l'argument ?
	beq.s loop_parse_line
	move.b d1,(a2)+
	dbf d2,quoted_arg
	rts

