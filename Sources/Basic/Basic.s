
*			Interpreteur Basic
*			~~~~~~~~~~~~~~~~~~




* Structure d'une commande (instruction ou fonction)
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Cmd_Struct	rs.b 0
Cmd_Next	rs.l 1
Cmd_Name	rs.l 1
Cmd_Proto	rs.l 1
Cmd_Offset	rs.w 1
Cmd_Size	rs.w 1
Cmd_Proto	rs.b 0


* Structure d'une variable
* ~~~~~~~~~~~~~~~~~~~~~~~~
	rsreset
Var_Struct	rs.b 0
Var_Next	rs.l 1
Var_Name	rs.l 1
Var_Data	rs.l 1
Var_SIZEOF	rs.l 1


* Structure d'un tableau
* ~~~~~~~~~~~~~~~~~~~~~~
	rsreset
Array_Struct	rs.b 0
Array_Next	rs.l 1
Array_Name	rs.l 1
Array_Dim	rs.w 1
Array_Size	rs.b 0
Array_Data	rs.b 0



BASIC_Interpretor
	move.l a0,Source(a5)
	move.l sp,Save_SP(a5)
	lea DataBase(pc),a5


* Interpreteur BASIC
* ~~~~~~~~~~~~~~~~~~
*   -->	A0=* source (chaine C)
*	a5=_DataBase
*
* <--	a5=_DataBase
*
Interpretor

* Saute les tabulations et autres espaces ennuyeux
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.Skip_Space
	move.b (a0)+,d0
	beq Interpretor_Exit	
	cmp.b #9,d0			tabulation
	beq.s .Skip_Space
	cmp.b #" ",d0			espace
	beq.s .Skip_Space

* Stocke le bidule dans un buffer
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	lea Identify_Buffer(a5),a1
	move.l a1,a2
	moveq #31-1,d1			pas plus de 31 chars pour toutes VAR !
.Store
	cmp.b #9,d0			tabulation -> instruction
	beq.s Search_Instr
	cmp.b #10,d0			retour ligne -> instruction
	beq.s Search_Instr
	cmp.b #" ",d0			espace -> instruction
	beq.s Search_Instr
	cmp.b #"$",d0			$ -> affectation de string/tab string
	beq.s Search_String
	cmp.b #"=",d0			= -> affectation d'integer
	beq.s Search_Integer
	cmp.b #"(",d0			( -> tableau d'integer
	beq.s Search_IntTab
	cmp.b #"A",d0			A-Z
	blt Interpretor_Error
	cmp.b #"Z",d0
	bgt Interpretor_Error

	move.b d0,(a2)+			stocke la lettre
	move.b (a0)+,d0			lit le char suivant
	dbeq d1,.Store
	subq.l #1,a0			CCR pas modifié
	bne Interpretor_Error		trop long ?

* Affectation à une string
* ~~~~~~~~~~~~~~~~~~~~~~~
Search_String
	move.b (a0)+,d0
	cmp.b #"=",d0
	

Search_Integer
	move.l Integer_List


* A partir d'ici on a isolé le machin
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


Interpretor_Exit
	subq.l #1,a0
	rts

Interpretor_Error
	move.l Save_SP(a5),sp
	rts


* Effacement de toutes les variables
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*   -->	a5=_DataBase
Erase_Variable
	rts





* Toutes les datas utiles pour le BASIC
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
DATABASE_OFFSET=0
	rsset -DATABASE_OFFSET
DataBase_Struct		rs.b 0
Procedure_List		rs.l 1
Function_List		rs.l 1
Integer_List		rs.l 1
String_List		rs.l 1
IntergerArray_List	rs.l 1
StringArray_List	rs.l 1
Current_Line		rs.l 1
ForNext_Count		rs.l 1
Source			rs.l 1
Identify_Buffer		rs.b 32
Save_SP			rs.l 1
DataBase_SIZEOF=__RS-DATABASE_OFFSET

_DataBase		ds.b DataBase_SIZEOF

