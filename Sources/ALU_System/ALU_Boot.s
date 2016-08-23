
*			  Amiga Loader Unit (ALU)
*			  ~~~~~~~~~~~~~~~~~~~~~~~
*			 (c)1994 Sync/DreamDealers
*
*				Bootblock



* Option de compilation
* ~~~~~~~~~~~~~~~~~~~~~
	OPT O+,OW-,OW6+
	OPT C+

* Adresse de chargement temporaire d'ALU
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
ALU_LOAD_ADR=$32000


* EQU du system
* ~~~~~~~~~~~~~

CALL	macro
	ifne NARG=2
	move.l \1,a6
	jsr _LVO\2(a6)
	elseif
	jsr _LVO\1(a6)
	endc
	endm

* Exec
_LVOAllocMem=-198
_LVODoIO=-456
_LVOOpenLibrary=-552

* Intuition
_LVODisplayAlert=-90
DEADEND_ALERT=$80000000

* trackdisk
CMD_READ=2
TD_MOTOR=9
IO_LENGTH=36
IO_DATA=40
IO_OFFSET=44



	section ALU_Boot,code

* Le boot commence ici
* ~~~~~~~~~~~~~~~~~~~~
*   ->	A1=TD_STRUCT
*	A6=_SysBase
*
	dc.b "DOS",0
	dc.l 0
	dc.l 0

* Allocation de mémoire pour charger ALU
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.l #ALU_LOAD_ADR,IO_DATA(a1)	IO_DATA
	move.w #CMD_READ,28(a1)			IO_COMMAND ( CMD_READ )
	move.l #1*512,IO_OFFSET(a1)		IO_OFFSET
	move.l #10*512,IO_LENGTH(a1)		IO_LENGTH
	CALL DoIO				chargement d'alu

	move.w #TD_MOTOR,28(a1)			IO_COMMAND ( TD_MOTOR )
	clr.l IO_LENGTH(a1)			IO_LENGTH ( MOTOR_OFF )
	CALL DoIO				arrete le moteur

	jmp ALU_LOAD_ADR

Copyright
	dc.b "-- AmIgA LoAdeR UnIt (ALU) v1.0  (c)1994 SyNc Of DrEaMdEaLeRs --",10
	dc.b "        -- CaLl DrEaMlAnDs At:   +33  32 39 79 23 --",10
	dc.b "               -- 1.2 GiGaByTeS OnLine !!! --",0

