
*		Master Devpac  v2.0   Sync/TSB
*		------------------------------------>


;;	OPT O+
	OPT C+

*--------------------------> les includes
	incdir "asm:include1.3/"
	include "exec/exec_lib.i"
	include "exec/io.i"
	include "exec/memory.i"
	include "devices/console.i"
	include "libraries/dos_lib.i"
	include "libraries/dosextens.i"
	include "intuition/intuition_lib.i"
	include "intuition/intuition.i"
	include "graphics/graphics_lib.i"
	include "graphics/display.i"
	include "misc/macros.i"

*---------------------------> constantes
FONTWIDTH=8
FONTHEIGHT=8
FONTBASELINE=6
SCREENWIDTH=640
SCREENHEIGHT=256
WINDOWWIDTH=SCREENWIDTH
WINDOWHEIGHT=246
MAXLINE=29
LINEOFFSET=3

*---------------------------> structure des datas
	rsreset
data_struct	rs.b 0
_ConsoleDevice	rs.l 1
_DosBase	rs.l 1
_GfxBase	rs.l 1
_IntuitionBase	rs.l 1
_ReqBase	rs.l 1
IoReq		rs.b IOSTD_SIZE
ScreenBase	rs.l 1
WindowBase	rs.l 1
MDRastPort	rs.l 1
MDUserPort	rs.l 1
TextAdr		rs.l 1
TextSize	rs.l 1
CurrentLine	rs.l 1
CursX		rs.l 1
CursY		rs.l 1
Free		rs.l 1
Size		rs.l 1
Modified	rs.l 1
EditLine	rs.b 100
StatusLine	rs.b 80
data_SIZEOF	rs.b 0

*---------------------------> le programme principale
main
	move.l #data_SIZEOF,d0			allocation de mémoire pour
	move.l #MEMF_PUBLIC|MEMF_CLEAR,d1	les datas
	move.l (_SysBase).w,a6
	CALL AllocMem
	tst.l d0
	beq no_memory
	move.l d0,a5				a5 ne DOIT jamais être modifié

	moveq #-1,d0				ouvre le console.device
	moveq #0,d1
	lea ConsoleName(pc),a0
	lea IoReq(a5),a1
	CALL OpenDevice
	tst.b d0
	bne no_console
	move.l IoReq+IO_DEVICE(a5),_ConsoleDevice(a5)

	moveq #0,d0				ouverture de la dos.library
	lea DosName(pc),a1
	CALL OpenLibrary
	move.l d0,_DosBase(a5)
	beq no_dos

	moveq #0,d0				ouverture de la graphics.library
	lea GfxName(pc),a1
	CALL OpenLibrary
	move.l d0,_GfxBase(a5)
	beq no_gfx

	moveq #0,d0				ouverture de l'intuition.library
	lea IntuitionName(pc),a1
	CALL OpenLibrary
	move.l d0,_IntuitionBase(a5)
	beq no_intuition

	pea 0.w					ouverture d'un écran
	pea 0.w
	pea Title(pc)
	pea DefaultFont(pc)
	move.w #CUSTOMSCREEN,-(sp)
	move.w #MODE_640,-(sp)
	move.w #1,-(sp)
	move.w #2,-(sp)
	move.w #SCREENHEIGHT,-(sp)
	move.w #SCREENWIDTH,-(sp)
	pea 0.w
	move.l sp,a0
	move.l d0,a6
	CALL OpenScreen
	lea ns_SIZEOF(sp),sp
	move.l d0,ScreenBase(a5)
	beq no_screen

	move.w #CUSTOMSCREEN,-(sp)		ouverture d'une fenêtre
	pea 0.w
	pea 0.w
	pea 0.w
	move.l d0,-(sp)
	pea 0.w
	pea 0.w
	pea 0.w
	pea (BACKDROP|BORDERLESS|ACTIVATE|NOCAREREFRESH)
	pea (MOUSEBUTTONS|RAWKEY|ACTIVEWINDOW)
	move.w #$1,-(sp)
	move.w #WINDOWHEIGHT,-(sp)
	move.w #WINDOWWIDTH,-(sp)
	pea 10.w
	move.l sp,a0
	CALL OpenWindow
	lea nw_SIZE(sp),sp
	move.l d0,WindowBase(a5)
	beq no_window
	move.l d0,a0
	move.l wd_RPort(a0),MDRastPort(a5)
	move.l wd_UserPort(a0),MDUserPort(a5)

	move.l #NotModifyStr,Modified(a5)
	bsr DispText
	bsr DispCursor
	bsr DispStatus

Wait_Loop
	bra exit

*--------------------------> routine d'affichage du curseur
DispCursor
	move.l MDRastPort(a5),d7

	moveq #3,d0				passe au orange
	move.l d7,a1
	move.l _GfxBase(a5),a6
	CALL SetAPen

	moveq #1,d0
	move.l d7,a1
	CALL SetBPen

	moveq #RP_COMPLEMENT,d0
	move.l d7,a1
	CALL SetDrMd

	movem.l CursX(a5),d0-d1
	lsl.l #3,d0				mulu #FONTWIDTH,d0
	lsl.l #3,d1				mulu #FONTHEIGHT,d0
	addq.l #LINEOFFSET,d1
	move.l d0,d2
	move.l d1,d3
	addq.l #FONTWIDTH-1,d2
	addq.l #FONTHEIGHT-1,d3
	move.l d7,a1
	CALL RectFill
	rts	

*--------------------------> routine qui affiche la barre de status en bas
DispStatus
	lea StatusFormat(pc),a0
	lea CurrentLine(a5),a1
	lea putch(pc),a2
	lea StatusLine(a5),a3
	move.l (_SysBase).w,a6
	CALL RawDoFmt

	move.l MDRastPort(a5),d7

	moveq #0,d0
	move.l d7,a1
	move.l _GfxBase(a5),a6
	CALL SetAPen

	moveq #1,d0
	move.l d7,a1
	CALL SetBPen

	moveq #RP_JAM2,d0
	move.l d7,a1
	CALL SetDrMd

	moveq #0,d0
	move.l #WINDOWHEIGHT-(FONTHEIGHT-FONTBASELINE),d1
	move.l d7,a1
	CALL Move

	lea 1(a3),a0
StrLen	tst.b (a3)+
	bne.s StrLen
	sub.l a0,a3

	move.l a3,d0
	lea StatusLine(a5),a0
	move.l d7,a1
	CALL Text
	rts

putch
	move.b d0,(a3)+
	rts

*--------------------------> routine pour reafficher le texte
DispText
	move.l MDRastPort(a5),d7

	move.l d7,a1
	move.l _GfxBase(a5),a6
	CALL ClearScreen

	moveq #1,d0
	move.l d7,a1
	CALL SetAPen

	moveq #RP_JAM1,d0
	move.l d7,a1
	CALL SetDrMd

	moveq #MAXLINE-1,d5
	moveq #LINEOFFSET+8-(FONTHEIGHT-FONTBASELINE),d6
put_text
	moveq #0,d0
	move.l d6,d1
	move.l d7,a1
	CALL Move

	moveq #5,d0
	lea TopazName(pc),a0
	move.l d7,a1
	CALL Text

	addq.l #FONTHEIGHT,d6

	dbf d5,put_text
	rts	

*--------------------------> Les routines de sorties
exit
	btst #6,$bfe001
	bne.s exit

	move.l WindowBase(a5),a0
	move.l _IntuitionBase(a5),a6
	CALL CloseWindow
no_window
	move.l ScreenBase(a5),a0
	CALL CloseScreen
no_screen
	move.l _IntuitionBase(a5),a1
	move.l (_SysBase).w,a6
	CALL CloseLibrary
no_intuition
	move.l _GfxBase(a5),a1
	CALL CloseLibrary
no_gfx
	move.l _DosBase(a5),a1
	CALL CloseLibrary
no_dos
	lea IoReq(a5),a1
	CALL CloseDevice
no_console
	move.l a5,a1
	move.l #data_SIZEOF,d0
	CALL FreeMem
no_memory
	moveq #0,d0
	rts

DefaultFont	dc.l TopazName
		dc.w FONTHEIGHT
		dc.b FS_NORMAL
		dc.b FPF_ROMFONT

ConsoleName	dc.b "console.device",0
DosName		dc.b "dos.library",0
GfxName		dc.b "graphics.library",0
IntuitionName	dc.b "intuition.library",0
Title		dc.b "Master Devpac v2.0 - Assembler v2.15 - ©1993 Sync/ThE SpeCiAl BrOthErS",0
WindowName	dc.b "Toto Prout",0
TopazName	dc.b "topaz.font",0
StatusFormat	dc.b " Line: %-6ld - Cursor X: %-2ld - Cursor Y: %-2ld - Free: %-8ld - Size: %-8ld %s",0
ModifyStr	dc.b "+ ",0
NotModifyStr	dc.b "  ",0
