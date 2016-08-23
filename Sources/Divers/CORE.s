
*		Commentary Remover ( CORE )
*		©1993 Sync of DRD
*		------------------------------->

	incdir "asm:include1.3/"
	include "exec/exec_lib.i"
	include "exec/execbase.i"
	include "libraries/dos_lib.i"
	include "libraries/dosextens.i"
	include "misc/macros.i"


	lea DosName(pc),a1			ouvre la dos.library
	moveq #0,d0
	move.l (_SysBase).w,a6
	CALL OpenLibrary
	move.l d0,_DosBase
	beq no_dos

	move.l d0,a6				ouvre le fichier d'entrée
	move.l #InputName,d1
	move.l #MODE_OLDFILE,d2
	CALL Open
	move.l d0,InputHandle
	beq error_open_in

	move.l #OutputName,d1			ouvre le fichier de sortie
	move.l #MODE_NEWFILE,d2
	CALL Open
	move.l d0,OutputHandle
	beq error_open_out

first_char
	move.l InputHandle(pc),d1		lit le 1er char d'une ligne
	move.l #Buffer,d2
	moveq #1,d3
	CALL Read	
	tst.l d0
	beq end_CORE
	move.b Buffer(pc),d0
	cmp.b #9,d0
	beq write_instruction
	cmp.b #"*",d0
	beq skip_commentary
	cmp.b #10,d0
	beq first_char

write_label
	move.l OutputHandle(pc),d1		écrit le char
	move.l #Buffer,d2
	moveq #1,d3
	CALL Write
loop_write_label
	move.l InputHandle(pc),d1
	move.l #Buffer,d2
	moveq #1,d3
	CALL Read
	tst.l d0
	beq end_CORE	
	move.l OutputHandle(pc),d1
	move.l #Buffer,d2
	moveq #1,d3
	CALL Write
	move.b Buffer(pc),d0
	cmp.b #10,d0
	bne loop_write_label
	bra first_char
	
skip_commentary
	move.l InputHandle(pc),d1		saute les commentaires
	move.l #Buffer,d2
	moveq #1,d3
	CALL Read
	tst.l d0
	beq end_CORE	
	move.b Buffer(pc),d0
	cmp.b #10,d0
	bne skip_commentary
	bra first_char	

write_instruction
	move.l OutputHandle(pc),d1		écrit le char
	move.l #Buffer,d2
	moveq #1,d3
	CALL Write
loop_write_instruction
	move.l InputHandle(pc),d1		ecrit l'instruction
	move.l #Buffer,d2
	moveq #1,d3
	CALL Read
	tst.l d0
	beq end_CORE	
	move.b Buffer(pc),d0
	cmp.b #9,d0
	beq skip_commentary2
	move.l OutputHandle(pc),d1
	move.l #Buffer,d2
	moveq #1,d3
	CALL Write
	move.b Buffer(pc),d0
	cmp.b #10,d0
	bne loop_write_instruction
	bra first_char
skip_commentary2
	move.l InputHandle(pc),d1
	move.l #Buffer,d2
	moveq #1,d3
	CALL Read
	tst.l d0
	beq end_CORE
	move.b Buffer(pc),d0
	cmp.b #10,d0
	bne.s skip_commentary2
	move.l OutputHandle(pc),d1
	move.l #Buffer,d2
	moveq #1,d3
	CALL Write
	bra first_char	

end_CORE
	move.l OutputHandle(pc),d1
	CALL Close
error_open_out
	move.l InputHandle(pc),d1
	CALL Close
error_open_in
	move.l a6,a1
	move.l (_SysBase).w,a6
	CALL CloseLibrary
	moveq #0,d0
no_dos
	rts

_DosBase
	dc.l 0
InputHandle
	dc.l 0
OutputHandle
	dc.l 0
DosName
	dc.b "dos.library",0
InputName
	dc.b "ram:CORE.in",0
OutputName
	dc.b "ram:CORE.out",0
Buffer
	dc.b 0
