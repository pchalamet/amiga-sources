	incdir "dh0:asm/include/"

	include exec/nodes.i
	include exec/memory.i
	include exec/tasks.i
	include libraries/dos.i
	include libraries/dos_lib.i
	include libraries/dosextens.i

	section backstart,code_f

_start_backstart
	sub.l a1,a1
	move.l (ExecBase).w,a6
	jsr FindTask(a6)

	move.l d0,a4
	tst.l pr_Cli(a4)
	beq.s _from_workbench

	lea dosname(pc),a1
	moveq #0,d0
	jsr OpenLibrary(a6)
	tst.l d0
	beq.s error_open_dos

	move.l d0,a6
	lea _start_backstart-4(pc),a0
	move.l (a0),d3
	move.l d3,_seglist
	clr.l (a0)

	move.l pr_Cli(a4),a1
	add.l a1,a1
	add.l a1,a1
	move.l cli_Module(a1),a2
	add.l a2,a2
	add.l a2,a2
	clr.l (a2)

	move.l #_progname,d1			name
	moveq #0,d2				priority
	move.l #1024,d4				stack size
	jsr CreateProc(a6)

	move.l a6,a1
	move.l (ExecBase).w,a6
	jsr CloseLibrary(a6)

error_open_dos
	moveq #0,d0
	rts

_from_workbench
	lea pr_MsgPort(a4),a0
	move.l (ExecBase).w,a6
	jsr WaitPort(a6)

	lea pr_MsgPort(a4),a0
	jsr GetMsg(a6)

	move.l d0,-(sp)

	bsr _main

	move.l (sp)+,d0
	move.l _returnMsg(pc),a1
	move.l (ExecBase).w,a6
	jsr ReplyMsg(a6)

	rts

_returnMsg	dc.l 0
dosname		dc.b "dos.library",0
		even
