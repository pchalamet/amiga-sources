
*			  Amiga Loader Unit (ALU)
*			  ~~~~~~~~~~~~~~~~~~~~~~~
*			 (c)1994 Sync/DreamDealers
*
*			    ALU Public Include



ALU_VERSION=1
ALU_REVISION=0
_AluBase=0


* Fonctions publiques d'ALU
* ~~~~~~~~~~~~~~~~~~~~~~~~~
ALU_LVO_COUNTER set -4			une petite macro pour definir les
DEF_LVO		macro			offset facilement
ALU_\1=ALU_LVO_COUNTER
ALU_LVO_COUNTER set ALU_LVO_COUNTER-4
		endm

	DEF_LVO	AllocMem
	DEF_LVO FreeMem
	DEF_LVO TypeOfMem
	DEF_LVO Init_Debugger
	DEF_LVO Debugger
	DEF_LVO Print


* EQU pour ALU
* ~~~~~~~~~~~~
DEF_EQU	macro
ALU_\1_B=\2
ALU_\1=(1<<\2)
	endm

	DEF_EQU Mem_Fast,6
	DEF_EQU Mem_Chip,5
	DEF_EQU Mem_Reverse,1
	DEF_EQU Mem_Clear,0
ALU_Mem_Any=ALU_Mem_Fast|ALU_Mem_Chip
ALU_Mem_Unknown=0


* Macro d'appel des fonctions d'ALU
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
CALL	macro
	ifne NARG=2
	move.l \1,a6
	jsr ALU_\2(a6)
	elseif
	jsr ALU_\1(a6)
	endc
	endm

CALLRTS	macro
	ifne NARG=2
	move.l \1,a6
	jmp ALU_\2(a6)
	elseif
	jmp ALU_\1(a6)
	endc
	endm

ALU_DEBUGGER	macro
	trap #0
	endm
