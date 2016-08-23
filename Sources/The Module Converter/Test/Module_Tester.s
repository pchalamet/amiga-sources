
*
*			Module_Tester.s for the TMC_Replay
*			~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*			    (c) 1993 Sync/DreamDealers
*

	incdir "asm:sources/"
	incdir "ram:"			Path of the converted module
	include "registers.i"

	section zik,code_f

	KILL_SYSTEM TestZiZik

	lea data_base(pc),a5
	addq.w #1,Vert-data_base(a5)
	move.l Timer(pc),d0
	divu #50,d0
	and.l #$ffff,d0
	divu.w #60,d0
	move.w d0,Hours-data_base(a5)
	clr.w d0
	swap d0
	divu.w #60,d0
	move.w d0,Minutes-data_base(a5)
	swap d0
	move.w d0,Seconds-data_base(a5)

	lea DosName(pc),a1
	moveq #0,d0
	CALL (ExecBase).w,OpenLibrary
	move.l d0,DosBase-data_base(a5)

	lea StrFormat(pc),a0
	lea Vert(pc),a1
	lea Putch(pc),a2
	lea OutStr(pc),a3
	CALL RawDoFmt

	CALL DosBase(pc),Output

	move.l d0,d1
	lea OutStr(pc),a0
	move.l a0,d2
	moveq #-1,d3
StrLen
	tst.b (a0)+
	dbeq d3,StrLen
	not.l d3
	CALL Write

	move.l a6,a1
	CALL (ExecBase).w,CloseLibrary
	moveq #0,d0
	rts

Putch	move.b d0,(a3)+
	rts

TestZiZik
	lea custom_base,a6
	move.l #Vbl,$6c.w
	move.l #coplist,cop1lc(a6)
	bsr mt_init
	move.w #$8280,dmacon(a6)
	move.w #$c010,intena(a6)

mickey
	btst #6,ciaapra
	bne.s mickey

	bsr mt_end
	RESTORE_SYSTEM

Vbl
	bsr mt_music
	move.w #$fff,custom_base+color00
	move.l custom_base+vposr,d0
	lea data_base(pc),a5
	move.w d0,d1
	and.l #$1ff00,d0
	lsr.l #8,d0
	sub.w #$60,d0
	and.l #$ff,d1
	cmp.w Vert(pc),d0
	blt.s no_greater
	beq.s hpos_equal
	move.w d0,Vert-data_base(a5)
	clr.w Horiz-data_base(a5)
hpos_equal
	cmp.w Horiz(pc),d1
	ble.s no_greater
	move.w d1,Horiz-data_base(a5)
no_greater
	addq.l #1,Timer-data_base(a5)

;	btst #6,ciaapra
;	bne.s no_left
;	tst.w mt_global_volume-data_base(a5)
;	beq.s nothing
;	subq.w #1,mt_global_volume-data_base(a5)
;	bsr mt_set_global_volume
;	bra.s nothing
;no_left
;	btst #2,custom_base+potinp
;	bne.s nothing
;	cmp.w #100,mt_global_volume-data_base(a5)
;	beq.s nothing
;	addq.w #1,mt_global_volume-data_base(a5)
;	bsr mt_set_global_volume
;nothing
	move.w #$0010,custom_base+intreq
	rte

data_base
save_intena	dc.w 0
save_dmacon	dc.w 0
save_IT3	dc.l 0
save_IT6	dc.l 0
Vert		dc.w 0
Horiz		dc.w 0
Hours		dc.w 0
Minutes		dc.w 0
Seconds		dc.w 0
Timer		dc.l 0
DosBase		dc.l 0
DosName		dc.b "dos.library",0
GfxName		dc.b "graphics.library",0
StrFormat	dc.b $9b,"0;33;40m"
		dc.b "»» Module Tester for The Module Converter v3.5 ©1993 Sync/DRD ««",10
		dc.b $9b,"0;31;40m"
		dc.b "Vertical : %d    Horizontal : %d/227    Time : %02d:%02d:%02d",10,0
StrSize=*-StrFormat
OutStr		dcb.b StrSize+11*5,0

	include "asm:.s/The Module Converter/TMC_Replay4.4.s"
	include "Song.s"

;	include "PT-PLAY.s"

	section boumboum,data_c
coplist
	dc.w $5fdf,$fffe
	dc.w intreq,$8010
	dc.w color00,$f0f
	dc.l $fffffffe

	include "Samples.s"

;mt_data
;	incbin "st-00:modules/mod.enigma"
