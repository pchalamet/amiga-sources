
***********************************************
* Coplist Desassembler ( CopDes ) by Sync/TSB *
*                                             *
* Usage : CopDes [>output_file]               *
***********************************************

	incdir "hd1:include"
	include "exec/exec_lib.i"
	include "libraries/dos_lib.i"
	include "graphics/gfxbase.i"
	include "misc/macros.i"
	OUTPUT ram:X

*--------------------------------> ouvre la DOS
main
	bra.s skip_version
	dc.b "$VER: CopDes V2.0 (c)1993 Sync/DreamDealers",0
	even
skip_version
	lea data_base(pc),a5

	move.l (_SysBase).w,_ExecBase-data_base(a5)

	lea DosName(pc),a1
	moveq #0,d0
	CALL (_SysBase).w,OpenLibrary
	move.l d0,_DosBase-data_base(a5)
	beq.s Error_Dos 

*-------------------------------> ouvre la Gfx
	lea GfxName(pc),a1
	moveq #0,d0
	CALL OpenLibrary
	move.l d0,_GfxBase-data_base(a5)
	beq.s Error_Gfx

	move.l d0,a0
	move.l gb_copinit(a0),_cop1-data_base(a5)
	move.l gb_SHFlist(a0),_cop2-data_base(a5)

*-------------------------------> recherche le canal de sortie standart
	CALL _DosBase(pc),Output
	move.l d0,_StdOut-data_base(a5)

*-------------------------------> desassemble les coplist
	move.l _StdOut(pc),d1			"desassemblage cop1"
	move.l #Desa1,d2
	move.l #Desa1_size,d3
	CALL Write
	move.l _cop1(pc),a3			on commence par la première
	bsr.s disassemble

	move.l _StdOut(pc),d1			"desassemblage cop2"
	move.l #Desa2,d2
	move.l #Desa2_size,d3
	CALL Write
	move.l _cop2(pc),a3
	bsr.s disassemble

 	move.l _GfxBase(pc),a1			ferme la Gfx
	CALL _ExecBase(pc),CloseLibrary
Error_Gfx
	move.l _DosBase(pc),a1			ferme la Dos
	CALL CloseLibrary
Error_Dos
	moveq #0,d0				on se tire..
	rts

*---------------------------------> routine de desassemblage d'une coplist (a3)
disassemble
	btst #0,1(a3)				est-ce un MOVE ?
	beq.s this_is_MOVE
	btst #0,3(a3)				est-ce un WAIT ?
	beq.s this_is_WAIT

this_is_SKIP
	move.l _StdOut(pc),d1			écrit "SKIP "
	move.l #SKIP_str,d2
	moveq #str_size,d3
	CALL Write
	bra Write_Buffer

this_is_WAIT
	move.l _StdOut(pc),d1			écrit "WAIT "
	move.l #WAIT_str,d2
	moveq #str_size,d3
	CALL Write
	bra.s Write_Buffer

this_is_MOVE
	move.l _StdOut(pc),d1			écrit "MOVE "
	move.l #MOVE_str,d2
	moveq #str_size,d3
	CALL Write

	move.w (a3),d0				registre du MOVE
	move.w #256-1,d1			nb de registres dans la liste
	moveq #0,d7				ben on commence à $dff000
	lea instr_reg(pc),a4			pointe la liste
.search
	cmp.w d7,d0
	beq.s .found
	addq.w #2,d7				registre suivant
.next
	tst.b (a4)+				recherche fin de la chaine
	bne.s .next

	dbf d1,.search
	bra.s Unknown_Reg			pas trouvé => registre inconnu

.found
	move.l _StdOut(pc),d1			sortie std
	move.l a4,d2				adr de la chaine
	moveq #-1,d3				calcule de la longueur
.len
	tst.b (a4)+
	dbeq d3,.len
	not.l d3
	beq.s Unknown_Reg			si =0 => registre inconnu
	CALL Write

	move.l (a3)+,d0				écrit la valeur du move
	bsr.s to_buffer

	move.l _StdOut(pc),d1			affiche le buffer
	move.l #buffer+5,d2
	moveq #1+1+4+1,d3
	CALL Write

	bra disassemble

*---------------------------------> routine pour les registres inconnus
Unknown_Reg
	move.l _StdOut(pc),d1
	move.l #UR,d2
	move.l #UR_size,d3
	CALL Write

*---------------------------------> routine pour SKIP ou WAIT
Write_Buffer
	move.l (a3)+,d0				récupère le SKIP ou WAIT
	bsr.s to_buffer
	move.l _StdOut(pc),d1
	move.l #buffer,d2
	moveq #1+4+2+4+1,d3
	CALL Write
	cmp.l #$fffffffe,-4(a3)			on s'arrete sur un $fffffffe
	bne disassemble				uniquement
	rts

*---------------------------------> routine qui convertit d0 dans le buffer
to_buffer
	lea buffer+1(pc),a0
	moveq #8-1,d2
.convert
	cmp.w #8-1-4,d2
	bne.s .not_middle
	addq.l #2,a0

.not_middle
	rol.l #4,d0			fait pivoter
	move.b d0,d1
	and.b #$0f,d1			garde qu'un quartet
	cmp.b #$a,d1			sup à $A
	bge.s .sup
	add.b #"0",d1
	move.b d1,(a0)+
	dbf d2,.convert
	rts
.sup
	add.b #"A"-$a,d1
	move.b d1,(a0)+
	dbf d2,.convert
	rts
	
*---------------------------------> quelques variables
data_base
_ExecBase	dc.l 0
_DosBase	dc.l 0
_GfxBase	dc.l 0
_cop1		dc.l 0
_cop2		dc.l 0
_StdOut		dc.l 0

DosName	dc.b "dos.library",0
GfxName	dc.b "graphics.library",0
Marque	dc.b 2

buffer	dc.b "$0000,$0000",10
UR	dc.b "Unknown Register="
UR_size=*-UR
Desa1	dc.b $9b,$31,";33;40mCoplist Desassembler V2.0  (c)1992-1993 Sync/DreamDealers",10
	dc.b "AGA Chip Set Now Supported !!!",10,10
	dc.b "Desassemblage de    gb_copinit"
	dc.b $9b,$30,";31;40m",10
Desa1_size=*-Desa1
Desa2	dc.b 10,$9b,$31,";33;40mDesassemblage de    gb_LOFlist",$9b,$30,";31;40m",10
Desa2_size=*-Desa2
SKIP_str	dc.b 9,"SKIP  "
WAIT_str	dc.b 9,"WAIT  "
MOVE_str	dc.b 9,"MOVE  "
str_size=*-MOVE_str

I	MACRO
	dc.b \1,0
	ENDM

	even
code set 0
instr_reg
	I "BLTDDAT"
	I "DMACONR"
	I "VPOSR"
	I "VHSPOSR"
	I "DSDATR"
	I "JOY0DAT"
	I "JOY1DAT"
	I "CLXDAT"
	I "ADCONR"
	I "POT0DAT"
	I "POT1DAT"
	I "POTGOR"
	I "SERDATR"
	I "DSKBYTR"
	I "INTENAR"
	I "INTREQR"
	I "DSKPTH"
	I "DSKPTL"
	I "DSKLEN"
	I "DSKDAT"
	I "REFPTR"
	I "VPOSW"
	I "VHSPOSW"
	I "COPCON"
	I "SERDAT"
	I "SERPER"
	I "POTGO"
	I "JOYTEST"
	I "STREQU"
	I "STRVBL"
	I "STRHOR"
	I "STRLONG"
	I "BLTCON0"
	I "BLTCON1"
	I "BLTAFWM"
	I "BLTALWM"
	I "BLTCPTH"
	I "BLTCPTL"
	I "BLTBPTH"
	I "BLTBPTL"
	I "BLTAPTH"
	I "BLTAPTL"
	I "BLTDPTH"
	I "BLTDPTL"
	I "BLTSIZE"
	I "BLTCON0L"
	I "BLTSIZV"
	I "BLTSIZH"
	I "BLTCMOD"
	I "BLTBMOD"
	I "BLTAMOD"
	I "BLTDMOD"
	I ""
	I ""
	I ""
	I ""
	I "BLTCDAT"
	I "BLTBDAT"
	I "BLTADAT"
	I ""
	I ""
	I ""
	I "DENISEID"
	I "DSKSYNC"
	I "COP1LCH"
	I "COP1LCL"
	I "COP2LCH"
	I "COP2LCL"
	I "COPJMP1"
	I "COPJMP2"
	I "COPINS"
	I "DIWSTRT"
	I "DIWSTOP"
	I "DDFSTRT"
	I "DDFSTOP"
	I "DMACON"
	I "CLXCON"
	I "INTENA"
	I "INTREQ"
	I "ADKCON"
	I "AUD0LCH"
	I "AUD0LCL"
	I "AUD0LEN"
	I "AUD0PER"
	I "AUD0VOL"
	I "AUD0DAT"
	I ""
	I ""
	I "AUD1LCH"
	I "AUD1LCL"
	I "AUD1LEN"
	I "AUD1PER"
	I "AUD1VOL"
	I "AUD1DAT"
	I ""
	I ""
	I "AUD2LCH"
	I "AUD2LCL"
	I "AUD2LEN"
	I "AUD2PER"
	I "AUD2VOL"
	I "AUD2DAT"
	I ""
	I ""
	I "AUD3LCH"
	I "AUD3LCL"
	I "AUD3LEN"
	I "AUD3PER"
	I "AUD3VOL"
	I "AUD3DAT"
	I ""
	I ""
	I "BPL1PTH"
	I "BPL1PTL"
	I "BPL2PTH"
	I "BPL2PTL"
	I "BPL3PTH"
	I "BPL3PTL"
	I "BPL4PTH"
	I "BPL4PTL"
	I "BPL5PTH"
	I "BPL5PTL"
	I "BPL6PTH"
	I "BPL6PTL"
	I ""
	I ""
	I ""
	I ""
	I "BPLCON0"
	I "BPLCON1"
	I "BPLCON2"
	I "BPLCON3"
	I "BPL1MOD"
	I "BPL2MOD"
	I "BPLCON4"
	I "CLXCON2"
	I "BPL1DAT"
	I "BPL2DAT"
	I "BPL3DAT"
	I "BPL4DAT"
	I "BPL5DAT"
	I "BPL6DAT"
	I "BPL7DAT"
	I "BPL8DAT"
	I "SPR0PTH"
	I "SPR0PTL"
	I "SPR1PTH"
	I "SPR1PTL"
	I "SPR2PTH"
	I "SPR2PTL"
	I "SPR3PTH"
	I "SPR3PTL"
	I "SPR4PTH"
	I "SPR4PTL"
	I "SPR5PTH"
	I "SPR5PTL"
	I "SPR6PTH"
	I "SPR6PTL"
	I "SPR7PTH"
	I "SPR7PTL"
	I "SPR0POS"
	I "SPR0CTL"
	I "SPR0DATA"
	I "SPR0DATB"
	I "SPR1POS"
	I "SPR1CTL"
	I "SPR1DATA"
	I "SPR1DATB"
	I "SPR2POS"
	I "SPR2CTL"
	I "SPR2DATA"
	I "SPR2DATB"
	I "SPR3POS"
	I "SPR3CTL"
	I "SPR3DATA"
	I "SPR3DATB"
	I "SPR4POS"
	I "SPR4CTL"
	I "SPR4DATA"
	I "SPR4DATB"
	I "SPR5POS"
	I "SPR5CTL"
	I "SPR5DATA"
	I "SPR5DATB"
	I "SPR6POS"
	I "SPR6CTL"
	I "SPR6DATA"
	I "SPR6DATB"
	I "SPR7POS"
	I "SPR7CTL"
	I "SPR7DATA"
	I "SPR7DATB"
	I "COLOR00"
	I "COLOR01"
	I "COLOR02"
	I "COLOR03"
	I "COLOR04"
	I "COLOR05"
	I "COLOR06"
	I "COLOR07"
	I "COLOR08"
	I "COLOR09"
	I "COLOR10"
	I "COLOR11"
	I "COLOR12"
	I "COLOR13"
	I "COLOR14"
	I "COLOR15"
	I "COLOR16"
	I "COLOR17"
	I "COLOR18"
	I "COLOR19"
	I "COLOR20"
	I "COLOR21"
	I "COLOR22"
	I "COLOR23"
	I "COLOR24"
	I "COLOR25"
	I "COLOR26"
	I "COLOR27"
	I "COLOR28"
	I "COLOR29"
	I "COLOR30"
	I "COLOR31"
	I "HTOTAL"
	I "HSSTOP"
	I "HBSTRT"
	I "HBSTOP"
	I "VTOTAL"
	I "VSSTOP"
	I "VBSTRT"
	I "VBSTOP"
	I "SPRHSTRT"
	I "SPRHSTOP"
	I "BPLHSTRT"
	I "BPLHSTOP"
	I "HHPOSW"
	I "HHPOSR"
	I "BEAMCON0"
	I "HSSTRT"
	I "VSSTRT"
	I "HCENTER"
	I "DIWHIGH"
	I ""
	I ""
	I ""
	I ""
	I ""
	I ""
	I ""
	I ""
	I ""
	I ""
	I ""
	I "FMODE"
