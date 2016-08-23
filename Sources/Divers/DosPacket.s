
; Arg1=-1	DosPacket pris en compte
; Arg1=0	DosPacket annulé

	incdir "asm:include1.3/"
	include "exec/execbase.i"
	include "exec/exec_lib.i"
	include "libraries/dos_lib.i"
	include "libraries/dosextens.i"

	move.l (_SysBase).w,a6			ptr Task
	move.l ThisTask(a6),a0
	lea pr_MsgPort(a0),a0			pointe le MsgPort
	move.l a0,Task_MP
	move.l a0,DosPacket2+dp_Port

	lea DosName(pc),a1			ouvre la dos.library
	moveq #0,d0
	jsr _LVOOpenLibrary(a6)
	tst.l d0
	beq.s Error_Dos

	move.l d0,a6				MsgPort du DF0:
	move.l #DF0_name,d1
	jsr _LVODeviceProc(a6)
	move.l d0,d3

	move.l a6,a1				ferme la dos.library
	move.l (_SysBase).w,a6
	jsr _LVOCloseLibrary(a6)

	move.l d3,a0				balance le Msg
	lea StandardPacket2(pc),a1
	jsr _LVOPutMsg(a6)

	move.l Task_MP(pc),a0			attend le Msg en retour
	jsr _LVOWaitPort(a6)

	move.l Task_MP(pc),a0			récupère le Msg
	jsr _LVOGetMsg(a6)

Error_Dos		
	moveq #0,d0
	rts

	cnop 0,4
StandardPacket2
	dc.l 0					LN_SUCC
	dc.l 0					LN_PRED
	dc.b 0					LN_TYPE
	dc.b 0					LN_PRI	
	dc.l DosPacket2				LN_NAME
	dc.l 0					MN_REPLYPORT
	dc.w 0					MN_LENGTH
DosPacket2
	dc.l StandardPacket2			dp_Link
	dc.l 0					dp_Port
	dc.l ACTION_INHIBIT			dp_Type
	dc.l 0					dp_Res1
	dc.l 0					dp_Res2
	dc.l -1					dp_Arg1
	dc.l 0					dp_Arg2
	dc.l 0					dp_Arg3
	dc.l 0					dp_Arg4
	dc.l 0					dp_Arg5
	dc.l 0					dp_Arg6
	dc.l 0					dp_Arg7

Task_MP
	dc.l 0
DF0_Name
	dc.b "DF0:",0
DosName
	dc.b "dos.library",0

