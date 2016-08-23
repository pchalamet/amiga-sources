
;
; Effet machin chose vu sur canal...
;


SCREEN_WIDTH=320
SCREEN_HEIGHT=256
SCREEN_DEPTH=1
SCREEN_SIZE=(SCREEN_WIDTH/8)*SCREEN_HEIGHT*SCREEN_DEPTH
NB_COLORS=1<<SCREEN_DEPTH




	incdir "asm:sources/"
	incdir "asm:.s/demos/chinois/"
	include "registers.i"	


	section chinetok,code
	KILL_SYSTEM Entry_Point

	moveq #0,d0
	rts

Entry_Point
	lea _DataBase(pc),a5
	lea custom_base,a6

	bsr Init

	move.l #my_vbl,$6c.w
	move.l #coplist,cop1lc(a6)
	
	move.w #$87c0,dmacon(a6)
	move.w #$c020,intena(a6)
	
	WAIT_LMB_DOWN

	RESTORE_SYSTEM

Init
	move.l #screen1,d0
	move.l d0,d1
	add.l #SCREEN_SIZE,d1
	movem.l d0-d1,log_screen(a5)
	rts



*****************************************************************************
*                              LA NOUVELLE VBL                              *
*****************************************************************************
my_vbl
	SAVE_REGS
	lea _DataBase(pc),a5
	lea custom_base,a6

	bsr Swap_Screens
	bsr Clear_Log_Screen
	bsr Draw_Chinois


	VBL_SIZE color00,$f00
		
	move.w #$0020,intreq(a6)
	RESTORE_REGS
	rte


Swap_Screens
	move.l log_screen(a5),d0
	move.l phy_screen(a5),log_screen(a5)
	move.l d0,phy_screen(a5)

	move.l d0,bpl1ptH(a6)
	clr.w copjmp1(a6)
	rts

Clear_Log_Screen
	move.l log_screen(a5),bltdpt(a6)
	move.w #$0100,bltcon0(a6)
	clr.w bltcon1(a6)
	clr.w bltdmod(a6)
	move.w #(SCREEN_HEIGHT*SCREEN_DEPTH<<6)|(SCREEN_WIDTH>>4),bltsize(a6)
	rts


Draw_Chinois
	WAIT_BLITTER
	rts



*****************************************************************************
*                                  LES DATAS                                *
*****************************************************************************
	rsreset
DataBase_Struct	rs.b 0
log_screen	rs.l 1
phy_screen	rs.l 1
DataBase_SizeOf	rs.b 0

_DataBase	dcb.b DataBase_SizeOf


*****************************************************************************
*                              LA COPLIST                                   *
*****************************************************************************
	section bouba,data_c
coplist
	dc.w fmode,0
	dc.w diwstrt,$2b81
	dc.w diwstop,$2bc1
	dc.w ddfstrt,$38
	dc.w ddfstop,$d0
	dc.w bplcon0,$200|(SCREEN_DEPTH<<12)
	dc.w bplcon1,0
	dc.w bplcon2,0
	dc.w bplcon3,0
	dc.w bpl1mod,0
	dc.w bpl2mod,0
	dc.w color00,0
	dc.w color01,$f95
	dc.l $fffffffe
	
	CNOP 0,8
screen1
	dcb.b 40*256,$f0
screen2
	dcb.b 40*256,$0f
