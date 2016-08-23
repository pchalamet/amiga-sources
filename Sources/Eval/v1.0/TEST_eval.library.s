
*			Test de la eval.library
*			~~~~~~~~~~~~~~~~~~~~~~~


* Les includes
* ~~~~~~~~~~~~
	incdir "hd1:include/"
	incdir "asm:.s/Eval/v1.0/include/"

	include "exec/exec_lib.i"
	include "libraries/eval_lib.i"
	include "misc/macros.i"


* Point d'entrée de la commande CLI
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Main
	lea db(pc),a5
	move.l (_SysBase).w,_ExecBase-db(a5)	c'est plus rapide en FAST !!

	lea EvalName(pc),a1			ouverture de la eval.library
	moveq #0,d0
	CALL _ExecBase(pc),OpenLibrary
	move.l d0,_EvalBase-db(a5)
	beq.s no_eval				erreur d'ouverture ?

	CALL d0,AllocToken			allocation d'un token
	move.l d0,my_token-db(a5)
	beq.s no_token

	lea my_expression(pc),a0		met l'expression en upcase
	move.l a0,a1
	CALL TokenUpCase

	lea my_expression(pc),a0		tokenize l'expression
	move.l my_token(pc),a1
	CALL Tokenize
	tst.l d0
	bne.s no_evaluate

	move.l my_token(pc),a0			evalue l'expression si ya
	CALL Evaluate				pas eut d'erreur

no_evaluate
	move.l my_token(pc),a1			libère le token
	CALL FreeToken

no_token
	move.l _EvalBase(pc),a1			ferme la library
	CALL _ExecBase(pc),CloseLibrary
no_eval
	moveq #0,d0				on sort
	rts

db
_ExecBase	dc.l 0
_EvalBase	dc.l 0
my_token	dc.l 0
EvalName	EVALNAME
my_expression	dc.b "2+2+2*(6+2)/4",0
