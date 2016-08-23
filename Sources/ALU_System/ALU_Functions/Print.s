
*			  Amiga Loader Unit (ALU)
*			  ~~~~~~~~~~~~~~~~~~~~~~~
*			 (c)1994 Sync/DreamDealers
*
*			 	  Print



******************************************
* Affichage d'une string avec parametres *
* dans l'écran du debugger		 *
*					 *
* en entrée: a0=*string			 *
*	     a1=*data			 *
******************************************

* 			%s : affichage d'une string
*
* affichage de nombre:	%d pour du decimal
*			%h pour du hexadecimal
*			%b pour du binaire
*	suivi de	s pour un nombre signé
*			u pour un nombre non signé
*	suivi de	b pour un byte
*			w pour un word
*			l pour un long
*
*			%% pour afficher un %
*
*			chr(10) pour un retour à la ligne
*
*			chr(0) pour la fin d'un print
	even
Print
	movem.l d0-d3/d7/a2-a5,-(sp)

	tst.l ALU_Screen(a6)			regarde si le debugger
	bne.s .ok				est présent
	lea Print_Error_Debugger(pc),a0
	CALL Debugger

.ok	move.l ALU_Screen(a6),a2
	lea SCREEN_WIDTH*(SCREEN_Y-FONT_Y)(a2),a2
	lea Font(pc),a3
	move.w ALU_PrintPos(a6),d7		# de colonne dans l'écran
Print_Loop
	moveq #0,d0
	move.b (a0)+,d0
	beq Print_Exit				c'est la fin ?

	cmp.b #10,d0				une nouvelle ligne ?
	beq.s Print_NewLine

	cmp.b #"%",d0				une option ?
	beq.s Print_Param

	cmp.b #7,d0				on fait flasher l'écran ?
	beq Print_Beep

	cmp.b #9,d0				tabulation ?
	beq Print_Tabulation


* Affichage d'un char
* ~~~~~~~~~~~~~~~~~~~
Print_Char
	lsl.w #3,d0				mulu.w #3,d0
	lea (a3,d0.w),a4
	bsr Check_New_Line
	move.b (a4)+,(a2)+			balance le char dans l'écran
	move.b (a4)+,(SCREEN_WIDTH-1)(a2)
	move.b (a4)+,SCREEN_WIDTH*2-1(a2)
	move.b (a4)+,SCREEN_WIDTH*3-1(a2)
	move.b (a4)+,SCREEN_WIDTH*4-1(a2)
	move.b (a4)+,SCREEN_WIDTH*5-1(a2)
	move.b (a4)+,SCREEN_WIDTH*6-1(a2)
	move.b (a4),SCREEN_WIDTH*7-1(a2)
	bra.s Print_Loop


* Scrolling de l'écran d'une ligne vers le haut
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Print_NewLine
	bsr Print_New_Line
	bra.s Print_Loop


* Affichage d'un parametre
* ~~~~~~~~~~~~~~~~~~~~~~~~
Print_Param
	move.b (a0)+,d0

	cmp.b #"c",d0				on affiche un conditionnel ?
	beq Print_Conditionnal

	cmp.b #"p",d0				padding ?
	beq Print_Pad

	cmp.b #"s",d0				on affiche une string ?
	beq Print_String

	cmp.b #"%",d0				on affiche un pourcent ?
	beq Print_Percent

* Affichage d'un nombre
* ~~~~~~~~~~~~~~~~~~~~~
Print_Number
	cmp.b #"b",d0				un byte ?
	bne.s .no_hex_byte
	move.b (a1)+,d0
	ror.l #8,d0				met ca dans l'octet fort
	moveq #2,d1				2 quartets à afficher
	bra.s .display_number

.no_hex_byte
	cmp.b #"w",d0				un word ?
	bne.s .no_hex_word
	move.w (a1)+,d0
	swap d0					met ca dans le mot fort
	moveq #4,d1				4 quartets à afficher
	bra.s .display_number

.no_hex_word
	cmp.b #"l",d0				un long ?
	bne.s .no_hex_long
	move.l (a1)+,d0				un long
	moveq #8,d1				8 quartets à afficher
	bra.s .display_number
.no_hex_long
	lea Print_Error_Param(pc),a0		appelle le debugger.. na!
	CALL Debugger
.display_number
	move.b (a0)+,d2				on affiche comment ?
	cmp.b #"h",d2				on affiche un nombre en hexa ?
	beq Print_Hex

	cmp.b #"d",d2				on affiche un nombre en dec ?
	beq.s Print_Dec

* Affichage d'un nombre en binaire
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Print_Bin
	add.w d1,d1				\ passe en bits
	add.w d1,d1				/

	lea ("%"*FONT_Y)(a3),a4			affiche un % avant le nombre
	bra.s .put_bin
.loop_print_bin
	add.l d0,d0
	bcc.s .bin_0
.bin_1	lea ("1"*FONT_Y)(a3),a4
	bra.s .put_bin
.bin_0	lea ("0"*FONT_Y)(a3),a4
.put_bin
	bsr Check_New_Line
	move.b (a4)+,(a2)+			balance le char dans l'écran
	move.b (a4)+,(SCREEN_WIDTH-1)(a2)
	move.b (a4)+,SCREEN_WIDTH*2-1(a2)
	move.b (a4)+,SCREEN_WIDTH*3-1(a2)
	move.b (a4)+,SCREEN_WIDTH*4-1(a2)
	move.b (a4)+,SCREEN_WIDTH*5-1(a2)
	move.b (a4)+,SCREEN_WIDTH*6-1(a2)
	move.b (a4),SCREEN_WIDTH*7-1(a2)
	dbf d1,.loop_print_bin
	bra Print_Loop

* Affichage d'un nombre en décimal
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Print_Dec
	add.w d1,d1				\
	add.w d1,d1				/ passe en bits
	sub.w #32,d1
	neg.w d1				32-d1
	lsr.l d1,d0				met ca à droite + effacage

	moveq #0,d1				Flags pour 0
	lea .Dec_Table(pc),a5
.loop_print_dec
	moveq #~"0",d2
	move.l (a5)+,d3
	bne.s .sub_loop				fin de la table ?
	tst.b d1				on a affiché que des 0 ?
	bne Print_Loop
	move.w #"0",d0
	bra Print_Char
.sub_loop
	sub.l d3,d0
	dblt d2,.sub_loop
	add.l d3,d0				un en trop
	not.w d2
	tst.b d1				on avait un zero avant ?
	bne.s .dec_ok
	cmp.b #"0",d2				c'est un 0 maintenant ?
	sne d1
	beq.s .loop_print_dec
.dec_ok	lea (a3,d2.w),a4
	bsr Check_New_Line
	move.b (a4)+,(a2)+			balance le char dans l'écran
	move.b (a4)+,(SCREEN_WIDTH-1)(a2)
	move.b (a4)+,SCREEN_WIDTH*2-1(a2)
	move.b (a4)+,SCREEN_WIDTH*3-1(a2)
	move.b (a4)+,SCREEN_WIDTH*4-1(a2)
	move.b (a4)+,SCREEN_WIDTH*5-1(a2)
	move.b (a4)+,SCREEN_WIDTH*6-1(a2)
	move.b (a4),SCREEN_WIDTH*7-1(a2)
	bra.s .loop_print_dec
.Dec_Table
	dc.l 1000000000
	dc.l 100000000
	dc.l 10000000
	dc.l 1000000
	dc.l 100000
	dc.l 10000
	dc.l 1000
	dc.l 100
	dc.l 10
	dc.l 1
	dc.l 0

* Affichage d'un nombre en hexadecimal
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Print_Hex
	lea ("$"*FONT_Y)(a3),a4			affiche en $ avant le nombre
	bra.s .start_hex
.loop_print_hex
	rol.l #4,d0
	move.b d0,d2
	and.w #$f,d2
	move.b .Hex_Table(pc,d2.w),d2
	lsl.w #3,d2				mulu.w #8,d2
	lea (a3,d2.w),a4
.start_hex
	bsr Check_New_Line
	move.b (a4)+,(a2)+			balance le char dans l'écran
	move.b (a4)+,(SCREEN_WIDTH-1)(a2)
	move.b (a4)+,SCREEN_WIDTH*2-1(a2)
	move.b (a4)+,SCREEN_WIDTH*3-1(a2)
	move.b (a4)+,SCREEN_WIDTH*4-1(a2)
	move.b (a4)+,SCREEN_WIDTH*5-1(a2)
	move.b (a4)+,SCREEN_WIDTH*6-1(a2)
	move.b (a4),SCREEN_WIDTH*7-1(a2)
	dbf d1,.loop_print_hex
	bra Print_Loop
.Hex_Table
	dc.b "0123456789ABCDEF"

* Affichage d'un pourcent
* ~~~~~~~~~~~~~~~~~~~~~~~
Print_Percent
	move.w #"%",d0
	bra Print_Char

* padding de la zone de data
* ~~~~~~~~~~~~~~~~~~~~~~~~~~
Print_Pad
	addq.l #1,a1
	bra Print_Loop

* Affichage d'un conditionnel
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~
Print_Conditionnal
	tst.b (a1)+				si <>0 on affiche la string
	bne Print_Loop
.get_end
	move.b (a0)+,d0				recherche le %c de fin
	cmp.b #"%",d0				de conditionnel
	bne.s .get_end
	move.b (a0)+,d0
	cmp.b #"c",d0				il faut un 'c' car sinon..GURU!
	beq Print_Loop
	
	lea Print_Error_Param(pc),a0		appelle le debugger.. na!
	CALL Debugger

* Affichage d'une chaine de caractères
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Print_String
	move.l (a1)+,a4
Print_String_Loop
	moveq #0,d0
	move.b (a4)+,d0
	beq Print_Loop
	cmp.b #10,d0				fait gaffe aux retour de ligne
	beq.s .newline

	lsl.w #3,d0				mulu.w #8,d0
	lea (a3,d0.w),a5
	bsr.s Check_New_Line
	move.b (a5)+,(a2)+			balance le char dans l'écran
	move.b (a5)+,(SCREEN_WIDTH-1)(a2)
	move.b (a5)+,SCREEN_WIDTH*2-1(a2)
	move.b (a5)+,SCREEN_WIDTH*3-1(a2)
	move.b (a5)+,SCREEN_WIDTH*4-1(a2)
	move.b (a5)+,SCREEN_WIDTH*5-1(a2)
	move.b (a5)+,SCREEN_WIDTH*6-1(a2)
	move.b (a5),SCREEN_WIDTH*7-1(a2)
	bra.s Print_String_Loop
.newline
	bsr.s Print_New_Line
	bra.s Print_String_Loop


* display beep
* ~~~~~~~~~~~~
Print_Beep
	move.w #$fff,_Custom+color00
	bra Print_Loop


* routine pour une tabulation
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~
Print_Tabulation
	move.l a2,d0				va au multiple de 8 suivant
	addq.l #8,d0
	and.l #~%111,d0
	move.l d0,a2
	addq.w #8,d7
	and.w #~%111,d7
	bra Print_Loop


* sortie de la routine
* ~~~~~~~~~~~~~~~~~~~~
Print_Exit
	move.w d7,ALU_PrintPos(a6)
	movem.l (sp)+,d0-d3/d7/a2-a5
	rts


* Verification de fin de ligne
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Check_New_Line
	addq.w #1,d7
	cmp.w #SCREEN_WIDTH,d7
	blt.s Check_New_Line_Done
Print_New_Line
	movem.l d0/a4,-(sp)
	move.l ALU_Screen(a6),a2
	lea SCREEN_WIDTH*FONT_Y(a2),a4
	move.w #(SCREEN_WIDTH*(SCREEN_Y-FONT_Y))/8-1,d0
.move	move.l (a4)+,(a2)+
	move.l (a4)+,(a2)+
	dbf d0,.move
	move.l a2,a4
	moveq #(SCREEN_WIDTH*FONT_Y)/8-1,d0
.clear	clr.l (a4)+
	clr.l (a4)+
	dbf d0,.clear
	moveq #0,d7
	movem.l (sp)+,d0/a4
Check_New_Line_Done
	rts


* La fonte
* ~~~~~~~~
Font	incbin "Font.RAW"


* Les messages d'érreur pour ce module
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Print_Error_Debugger
	dc.b "ALU_Print Error: Need The Debugger To Be Installed",0

Print_Error_Param
	dc.b "ALU_Print Error: Unknown Parameter Displayer",0

