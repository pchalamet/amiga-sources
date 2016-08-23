
*			Fonctions de la eval.library
*			~~~~~~~~~~~~~~~~~~~~~~~~~~~~

_LVOAllocToken	EQU -30
_LVOFreeToken	EQU -36
_LVOTokenUpCase	EQU -42
_LVOTokenize	EQU -48
_LVOEvaluate	EQU -54

EVALNAME	macro
	dc.b "eval.library",0
	endm
