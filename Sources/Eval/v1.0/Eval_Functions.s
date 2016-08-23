
*			Evaluateur d'expressions avec des ENTIERS
*			~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



* Allocation d'une structure 
* ~~~~~~~~~~~~~~~~~~~~~~~~~~
* <--	d0=ptr sur structure Token ou 0 si erreur
AllocToken
	move.l a6,-(sp)
	move.l ev_ExecBase(a6),a6
	move.l #tk_SIZEOF,d0
	move.l #MEMF_PUBLIC,d1
	CALL AllocMem
	move.l (sp)+,a6
	rts



* Libération d'une structure Token
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*  -->	a1=ptr sur la structure Token à liberer
FreeToken
	move.l a6,-(sp)
	move.l ev_ExecBase(a6),a6
	move.l #tk_SIZEOF,d0
	CALL FreeMem
	move.l (sp)+,a6
	rts



* Met en majuscule une expression au format chaine C
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*  -->	a0=expression d'entrée
* <--	a1=expression de sortie
*
TokenUpCase
	move.b (a0)+,d0
	cmp.b #'"',d0			fait gaffe aux chaines de char
	beq.s Search_Next_Quote
	cmp.b #"a",d0
	blt.s Upcase_Write
	cmp.b #"z",d0
	bgt.s Upcase_Write
	sub.b #"a"-"A",d0
Upcase_Write
	move.b d0,(a1)+
	bne.s TokenUpCase
	rts

Quote_loop
	move.b (a0)+,d0			recherche la 2ème quote
	cmp.b #'"',d0
	beq.s Upcase_Write
Search_Next_Quote
	move.b d0,(a1)+
	bne.s Quote_loop
	rts


* Tokenisation d'une expression
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*  -->	a0=expression
*	a1=*Token
* <--	d0=erreur flag ( 0=OK )
*
Tokenize
	movem.l d2-d7/a2-a6,-(sp)
	lea tk_Stack_Tokens(a1),a4
	lea tk_Stack_Priorities(a1),a3
	lea tk_Stack_Operators(a1),a2
	lea tk_Stack_Operands(a1),a1
	moveq #-1,d6				Nb_Parenthesis
	moveq #0,d7				Synt Error Flag
	bsr.s TEvalue
	move.l #Op_End,(a4)			on s'arretera ici !!

	moveq #0,d0				* regarde voir si ya une erreur *
	tst.b d7				erreur de syntaxe ?
	sne d0
	add.w d0,d0
	tst.w d6				autant de parenthèses ouvertes
	sne d0					que de fermées ?
	add.w d0,d0
	tst.b (a0)				on est à la fin de l'expression ?
	sne d0					d0=0 ou <>0
	movem.l (sp)+,d2-d7/a2-a6
	rts



* Tokenisation d'une expression
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*  -->	d6=Niveau de parenthèses
*	d7=Flag d'erreur
*	a1=Stack_Operands
*	a2=Stack_Operators
*	a3=Stack_Priorities
*	a4=Stack_Tokens
*
* <--	d6=Niveau de parenthèse
*	d7=Flag d'erreur
*
TEvalue
	tst.b d7				ya une erreur ?
	bne.s TEvalue_Synt

	addq.w #1,d6				augmente le niveau de parenthèses
	moveq #0,d5				priorité operateur (LOCAL)
TEvalue1
	move.b d5,(a3)+				sauve la priorité
	move.l a5,(a2)+				et l'operateur
TEvalue2
	bsr.s Get_Operand			lit une operande
TEvalue3
	tst.b d7				lecture d'un char
	bne.s .error
	move.b (a0)+,d0
.error
	cmp.b #"+",d0				recherche l'operateur
	bne.s .not_plus				et sa priorité s'il existe
	moveq #1,d5
	lea Op_Plus(pc),a5
	bra.s .found

.not_plus
	cmp.b #"-",d0
	bne.s .not_minus
	moveq #1,d5
	lea Op_Minus(pc),a5
	bra.s .found

.not_minus
	cmp.b #"*",d0
	bne.s .not_muls
	moveq #2,d5
	lea Op_Muls(pc),a5
	bra.s .found

.not_muls
	cmp.b #"/",d0
	bne.s .not_divs
	moveq #2,d5
	lea Op_Divs(pc),a5
	bra.s .found

.not_divs
	cmp.b #"^",d0
	bne.s .not_power
	moveq #3,d5
	lea Op_Power(pc),a5
	bra.s .found

.not_power
	moveq #0,d5

.found
	cmp.b -1(a3),d5				compare les priorités
	bgt.s TEvalue1				sup => on l'empile

	subq.l #1,a0				un coup pour rien !
	move.b -(a3),d5				précédent
	move.l -(a2),a5				Z inchangé
	beq.s TEvalue_End			yen a plus ?
	move.l a5,(a4)+				on le met dans la pile de tokens
	bra.s TEvalue3

TEvalue_End
	cmp.b #")",d0				on sort à cause d'une
	bne.s TEvalue_Synt			parenthèse fermée ?
	addq.l #1,a0
	subq.w #1,d6
TEvalue_Synt
	rts

	
	
* Lecture d'une operande
* ~~~~~~~~~~~~~~~~~~~~~~
Get_Operand
	tst.b d7			ya une erreur ?
	bne Get_Operand_Synt

	moveq #0,d0
	moveq #0,d1

	move.b (a0)+,d0			lit un char
	cmp.b #"(",d0			euh.. c une parenthèse ?
	beq TEvalue			=> on se re-execute
	cmp.b #"$",d0			c'est de l'hexadecimal ?
	beq.s Get_Hexadecimal
	cmp.b #"%",d0			c'est du binaire ?
	beq.s Get_Binary
	cmp.b #'"',d0			c'est une chaine de charactères ?
	beq Get_String

* Lecture d'un nombre decimal
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~
Get_Decimal
	sub.b #"0",d0			donc c'est du decimal => fo que ce
	bmi Get_Function		soit un chiffre absolument
	cmp.b #9,d0			sinon ca veut dire que c'est une
	bgt Get_Function		fonction
.get_dec_operand
	move.b (a0)+,d1			list un char
	beq End_Get_Operand		c'est la fin ?
	sub.b #"0",d1
	bmi End_Get_Operand
	cmp.b #9,d1
	bgt.s End_Get_Operand
	mulu.l #10,d0
	add.l d1,d0
	bra.s .get_dec_operand

* Lecture d'un nombre hexadecimal
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Get_Hexadecimal
	move.b (a0)+,d0			c'est de l'hexadecimal => fo que ce
	sub.b #"0",d0			soit une lettre entre 0-9 et A-F
	blt.s Get_Operand_Error
	cmp.b #9,d0
	ble.s .get_hex_operand
	sub.b #"A"-"0",d0
	blt.s Get_Operand_Error
	cmp.b #$f,d0
	bgt.s Get_Operand_Error
.get_hex_operand
	move.b (a0)+,d1
	sub.b #"0",d1
	blt.s End_Get_Operand
	cmp.b #9,d1
	ble.s .do_hex
	sub.b #"A"-"0",d1
	blt.s End_Get_Operand
	cmp.b #$f,d1
	bgt.s End_Get_Operand
.do_hex
	lsl.l #4,d0
	or.b d1,d0
	bra.s .get_hex_operand

* Lecture d'un nombre binaire
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~
Get_Binary
	move.b (a0)+,d0			c'est un nombre binaire => fo que
	sub.b #"0",d0			ce soit une lettre entre 0-1
	blt.s Get_Operand_Error
	subq.b #1,d0
	bgt.s Get_Operand_Error
	addq.b #1,d0
.get_bin_operand
	move.b (a0)+,d1
	sub.b #"0",d1
	blt.s End_Get_Operand
	subq.b #1,d1
	bgt.s End_Get_Operand
	addq.b #1,d1
	add.l d0,d0
	or.b d1,d0
	bra.s .get_bin_operand

* Lecture d'une chaine
* ~~~~~~~~~~~~~~~~~~~~
Get_String
	moveq #0,d0
.get_string_operand
	move.b (a0)+,d1			lit jusqu'à temps de rencontrer
	cmp.b #'"',d1			un "
	beq.s End_Get_Operand_String
	lsl.l #8,d0
	move.b d1,d0
	bra.s .get_string_operand

* Lecture d'une fonction
* ~~~~~~~~~~~~~~~~~~~~~~
Get_Function
***************** Tester ici la presence d'une fonction

Get_Operand_Error
	subq.l #1,a0
	st d7
Get_Operand_Synt
	rts

End_Get_Operand
	subq.l #1,a0			revient en arrière
End_Get_Operand_String
	move.l d0,(a1)+			stocke la valeur de retour
	move.l #Op_Const,(a4)+		et dans la pile de Tokens
	rts



* Evaluation d'une expression tokenisée
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*  -->	a0=EvalStruct
* <--	d0=Return value
*
Evaluate
	movem.l a2/a3,-(sp)
	lea tk_Stack_Eval(a0),a2
	lea tk_Stack_Tokens(a0),a1
	lea tk_Stack_Operands(a0),a0

	move.l (a1)+,a3
	jsr (a3)

	move.l -4(a2),d0
	movem.l (sp)+,a2/a3
	rts


* Les operateurs par defaut
* ~~~~~~~~~~~~~~~~~~~~~~~~~
Op_End
	rts

Op_Const
	move.l (a0)+,(a2)+
	move.l (a1)+,a3
	jmp (a3)

Op_Plus
	move.l -(a2),d0				B
	add.l d0,-4(a2)				A+B
	move.l (a1)+,a3
	jmp (a3)

Op_Minus
	move.l -(a2),d0				B
	sub.l d0,-4(a2)				A-B
	move.l (a1)+,a3
	jmp (a3)

Op_Muls
	move.l -(a2),d0				B
	muls.l -4(a2),d0			A*B
	move.l d0,-4(a2)
	move.l (a1)+,a3
	jmp (a3)

Op_Divs
	move.l -8(a2),d0			A
	divs.l -(a2),d0				A/B
	move.l d0,-4(a2)
	move.l (a1)+,a3
	jmp (a3)

Op_Power
	move.l -(a2),d0				exposant
	move.l -4(a2),d1			le nombre 'exposanté'
	moveq #1,d2				resultat
	tst.l d0				while (exposant>0)
.loop	beq.s .exit
	muls.l d1,d2
	subq.l #1,d0
	bra.s .loop
.exit	move.l d2,-4(a2)
	move.l (a1)+,a3
	jmp (a3)
