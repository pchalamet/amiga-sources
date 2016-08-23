
*			Allocation des canaux audios
*			~~~~~~~~~~~~~~~~~~~~~~~~~~~~

	incdir "include:"
	include "exec/execbase.i"
	include "exec/exec_lib.i"
	include "exec/io.i"
	include "exec/ports.i"
	include "devices/audio.i"
	include "misc/macros.i"


	section tetard,code

	lea data_base(pc),a5
	move.l (_SysBase).w,a6

	move.l a6,_ExecBase-data_base(a5)
	move.l ThisTask(a6),Live_Task-data_base(a5)

* initialisation du message port
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	moveq #-1,d0
	CALL AllocSignal
	move.b d0,Live_Msg_Port+MP_SIGBIT-data_base(a5)
	bmi.s error_allocsignal
	move.l Live_Task(pc),Live_Msg_Port+MP_SIGTASK-data_base(a5)

* Ouverture de l'audio.device et allocation des 4 canaux audios
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	lea AudioName(pc),a0			ouvre l'audio.device
	lea Live_Audio_Request,a1		et alloue les 4 canaux audios
	moveq #0,d0
	moveq #0,d1
	CALL OpenDevice
	tst.l d0
	bne.s error_opendevice

	lea Live_Audio_Request(pc),a1		lock les canaux
	move.l IO_UNIT(a1),d0
	move.w #ADCMD_LOCK,IO_COMMAND(a1)
	clr.b IO_FLAGS(a1)
	move.l IO_DEVICE(a1),a6
	jsr DEV_BEGINIO(a6)

	lea Live_Audio_Request(pc),a1		
	CALL _ExecBase(pc),CheckIO
	tst.l d0
	bne.s error_lockaudio

	lea Live_Audio_Request(pc),a1		unlock les canaux
	move.w #ADCMD_FREE,IO_COMMAND(a1)
	move.b #IOF_QUICK,IO_FLAGS(a1)
	CALL DoIO

error_lockaudio
error_allocaudio
	lea Live_Audio_Request(pc),a1		ferme l'audio.device
	CALL CloseDevice
error_opendevice
	move.b Live_Msg_Port+MP_SIGBIT(pc),d0	libère le signal du port
	CALL FreeSignal
error_allocsignal

	moveq #0,d0
	rts


data_base

_ExecBase	dc.l 0
Live_Task	dc.l 0

Live_Msg_Port
	dc.l 0					LN_SUCC
	dc.l 0					LN_PRED
	dc.b NT_REPLYMSG			LN_TYPE
	dc.b 20					LN_PRI
	dc.l Live_Reply_Port_Name		LN_NAME
	dc.b PA_SIGNAL				MP_FLAGS
	dc.b 0					MP_SIGBIT
	dc.l 0					MP_SIGTASK
	dc.l Live_Msg_Port+MP_MSGLIST+LH_TAIL	LH_HEAD		MP_MSGLIST
	dc.l 0					LH_TAIL
	dc.l Live_Msg_Port+MP_MSGLIST+LH_HEAD	LH_TAILPRED
	dc.b 0					LH_TYPE
	dc.b 0					LH_PAD

Live_Audio_Request
	dc.l 0					LN_SUCC		IOAudio
	dc.l 0					LN_PRED
	dc.b NT_DEVICE				LN_TYPE
	dc.b 0					LN_PRI
	dc.l 0					LN_NAME
	dc.l Live_Msg_Port			MN_REPLYPORT
	dc.l 0					IO_DEVICE
	dc.l 0					IO_UNIT
	dc.w 0					IO_COMMAND
	dc.b 0					IO_FLAGS
	dc.b 0					IO_ERROR
	dc.w 0					ioa_AllocKey
	dc.l Live_Channels			ioa_Data
	dc.l 4					ioa_Length
	dc.w 0					ioa_Period
	dc.w 0					ioa_Volume
	dc.w 0					ioa_Cycles
	dc.l 0					LN_SUCC		ioa_WriteMsg
	dc.l 0					LN_PRED
	dc.b NT_DEVICE				LN_TYPE
	dc.b 0					LN_PRI
	dc.l 0					LN_NAME
	dc.l 0					MN_REPLYPORT
	dc.w 0					MN_LENGTH

Live_Channels
	dc.b %0001,%0010,%0100,%1000

Live_Reply_Port_Name
	dc.b "LiVe AuDiO RePly PoRt",0

AudioName
	dc.b "audio.device",0
