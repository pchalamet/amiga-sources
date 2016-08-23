
*			  Amiga Loader Unit (ALU)
*			  ~~~~~~~~~~~~~~~~~~~~~~~
*			 (c)1994 Sync/DreamDealers
*
*			 	Debugger



********************************************
* Routine pour attraper toutes les erreurs *
********************************************
	even
Guru_Catcher
	move.l a6,-(sp)
	lea ALU_DataBase(pc),a6
	movem.l d0-d7/a0-a5,Data_Regs-ALU_DataBase(a6)	sauve les regs
	move.l (sp)+,a5
	movem.l a5/a7,Adr_Regs+6*4-ALU_DataBase(a6)
	move.l usp,a0					\ sauve usp
	move.l a0,USP_Adr-ALU_DataBase(a6)		/
	move.w (sp),CCR_Content-ALU_DataBase(a6)	sauve ccr
	move.l 2(sp),PC_Adr-ALU_DataBase(a6)		sauve pc
	move.b ALU_Micropro(a6),Micropro_Number-ALU_DataBase(a6)
	move.b ALU_Math81(a6),Math_81-ALU_DataBase(a6)
	move.b ALU_Math82(a6),Math_82-ALU_DataBase(a6)

	lea Chipset_OCS(pc),a0
	move.l a0,Chipset_Kind-ALU_DataBase(a6)


* Déterminer ici la cause de l'erreur
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

* Initialisations des regs qd ya erreurs
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	bsr Init_Debugger
	bsr View_Registers
	bsr.s Debugger_From_Guru

	move.l USP_Adr(pc),a0			récupreration des registres
	move.l a0,usp
	movem.l Data_Regs(pc),d0-d7/a0-a7
	move.l CCR_Content(pc),(sp)
	move.l PC_Adr(pc),2(sp)
	rte




* Ici on donne la main au debugger en passant en superviseur avant
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Debugger
	move.l a0,-(sp)
	lea Debugger_From_Guru(pc),a0
	move.l a0,$80.w
	move.l (sp)+,a0
	trap #0
	rts

* Le debugger lui meme
* ~~~~~~~~~~~~~~~~~~~~
Debugger_From_Guru
	lea _Custom,a5
	move.w dmaconr(a6),old_dmacon-ALU_DataBase(a6)
	move.w intena(a6),old_intena-ALU_DataBase(a6)
	move.w #$4000,intena(a6)		vire les IT

	move.l ALU_Coplist(a6),cop1lc(a5)	installe la coplist du
	clr.w copjmp1(a5)			debugger
	move.w #$8380,dmacon(a5)		met copper et bitplan

	bsr Display_Help

.main_loop
	pea .main_loop(pc)

	btst #6,_CiaABase+pra
	beq Display_Help
	btst #2,potinp(a5)
	beq View_Registers
	rts





* Toutes les fonctions du debugger
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	CNOP 0,4
Display_Help
	lea Help_Text(pc),a0
	CALLRTS Print

Continue
	move.w #$7fff,dmacon(a5)		restaure le hardware
	move.w #$7fff,intena(a5)
	move.w old_dmacon(pc),dmacon(a5)
	move.w old_intena(pc),intena(a5)
	movem.l Regs(pc),d0-d7/a0-a7
	rts

Reset_Machine
	lea 2.w,a0
	reset
	jmp (a0)

View_Registers
	lea Registers_Text(pc),a0		affiche la bannière
	lea Regs(pc),a1				et l'état de tous les registres
	CALLRTS Print





* Initialisation du debugger
* ~~~~~~~~~~~~~~~~~~~~~~~~~~
*   -->	a6=ALU_DataBase
Init_Debugger
	tst.l ALU_Screen(a6)
	bne.s .already_there

	movem.l d0-d1/a0-a1,-(sp)

	lea Guru_Catcher(pc),a0			place le debugger dans le
	move.l a0,$80.w				trap #0

	move.l #SCREEN_WIDTH*SCREEN_Y+Coplist_Size,d0
	moveq #ALU_Mem_Chip|ALU_Mem_Clear,d1
	CALL AllocMem
	move.l d0,ALU_Screen(a6)
	beq.s .error_debugger

	lea scr_ptr+2(pc),a0			installe les ptrs videos
	move.w d0,4(a0)
	swap d0
	move.w d0,(a0)

	swap d0					recopie la coplist en Chip
	add.l #SCREEN_WIDTH*SCREEN_Y,d0
	move.l d0,ALU_Coplist(a6)
	lea Coplist(pc),a0
	move.l d0,a1
	moveq #Coplist_Size/4-1,d0
.dup	move.l (a0)+,(a1)+
	dbf d0,.dup

	movem.l (sp)+,d0-d1/a0-a1
.already_there
	rts

.error_debugger
	move.w #$0f0,_Custom+color00
	bra.s .error_debugger


* Datas du debugger
* ~~~~~~~~~~~~~~~~~
Coplist
	dc.w fmode,$0
	dc.w bplcon0,$1200|$8000
	dc.w bplcon1,0
	dc.w bplcon2,0
	dc.w ddfstrt,$3c
	dc.w ddfstop,$d4
	dc.w diwstrt,$2b81
	dc.w diwstop,$2bc1
	dc.w bpl1mod,0
	dc.w bpl2mod,0
	dc.w color00,$43b
	dc.w color01,$fff
scr_ptr	dc.w bpl1ptH,0
	dc.w bpl1ptL,0
	dc.l $fffffffe
Coplist_Size=*-Coplist

Regs
Trap_Number	dc.w 0
Micropro_Number	dc.b 0
Math_81		dc.b 0
Math_82		dc.b 0
		dc.b 0
Chipset_Kind	dc.l 0
Data_Regs	ds.l 8
Adr_Regs	ds.l 7
MSP_Adr		dc.l 0
ISP_Adr		dc.l 0
USP_Adr		dc.l 0
PC_Adr		dc.l 0
CCR_Content	dc.w 0
CACR_Content	dc.w 0
old_dmacon	dc.w 0
old_intena	dc.w 0

Chipset_OCS
	dc.b "OCS",0
Chipset_ECS
	dc.b "ECS",0
Chipset_AGA
	dc.b "AGA",0
Registers_Text
	dc.b "Trap Error Number %wd",10
	dc.b "MC680%bd0 Processor %c+ 68881 %c%c+ 68882%c%p+ %s Chipset",10
	dc.b "Data Regs",9,"D0=%lh",9,"D1=%lh",9,"D2=%lh",9,"D3=%lh",10
	dc.b 9,9,"D4=%lh",9,"D5=%lh",9,"D6=%lh",9,"D7=%lh",10
	dc.b "Address Regs",9,"A0=%lh",9,"A1=%lh",9,"A2=%lh",9,"A3=%lh",10
	dc.b 9,9,"A4=%lh",9,"A5=%lh",9,"A6=%lh",10
	dc.b "Stacks",9,9,"MSP=%lh",9,"ISP=%lh",9,"USP=%lh",10
	dc.b "Prg State",9,"PC=%lh",9,"CCR=%wh",10
	dc.b "Caches",9,9,"CACR=%wh",10
	dc.b 10,0

Help_Text
	dc.b "AmIgA LoAdeR UnIt (ALU) v1.0  (c)1994 SyNc Of DrEaMdEaLeRs",10
	dc.b "¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯",10
	dc.b "HELP..................This page",10
	dc.b "VIEW <Reg>............View on or all registers",10
	dc.b "CONT..................Continue",10
	dc.b "DUMP Adr<,Length>.....Memory dump",10
	dc.b "EDIT Adr..............Memory edition",10
	dc.b "RESET.................Reset machine",10
	dc.b "EVAL <Expr>...........Evaluate the expression",10
	dc.b 10,0


