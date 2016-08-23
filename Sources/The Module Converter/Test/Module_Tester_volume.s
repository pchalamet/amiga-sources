	***************************************************
	* Module_Tester  for the TMC_Replay   by Sync/DRD *
	* Run it from the CLI, listen and exit : you've   *
	* got the maximum time taken by the replay	  *
	*      Feel free to modify it if you want !!      *
	***************************************************

	opt O+

	incdir "ram:"			Path of the converted module

	section sklong,code
	bsr save_all
	lea $dff000,a6
	move.w #$7fff,d0
	move.w d0,$9a(a6)
	move.w d0,$96(a6)
	move.l #vbl,$6c.w
	jsr mt_init
	move.w #$8200,$96(a6)
	move.w #$c020,$9a(a6)
mickey	btst #6,$bfe001
	bne.s mickey
	btst #2,$dff016
	bne.s mickey
	jsr mt_end
	bsr restore_all
	addq.w #1,Vert
	move.l Timer(pc),d0
	divu #50,d0
	and.l #$ffff,d0
	divu.w #60,d0
	move.w d0,Hours
	clr.w d0
	swap d0
	divu.w #60,d0
	move.w d0,Minutes
	swap d0
	move.w d0,Seconds
	lea DosName(pc),a1
	moveq #0,d0
	move.l 4.w,a6
	jsr -552(a6)
	move.l d0,DosBase
	lea StrFormat(pc),a0
	lea Vert(pc),a1
	lea Putch(pc),a2
	lea OutStr(pc),a3
	jsr -522(a6)
	move.l DosBase(pc),a6
	jsr -60(a6)
	move.l d0,d1
	move.l #OutStr,d2
	lea 1(a3),a0
StrLen	tst.b (a3)+
	bne.s StrLen
end_found
	sub.l a0,a3
	move.l a3,d3
	jsr -48(a6)
	move.l a6,a1
	move.l 4.w,a6
	jsr -414(a6)
	moveq #0,d0
	rts
vbl	jsr mt_music
	move.l $dff004,d0
	move.l d0,d1
	and.l #$1ff00,d0
	lsr.l #8,d0
	and.l #$ff,d1
	cmp.w Vert(pc),d0
	blt.s no_greater
	beq.s hpos_equal
	move.w d0,Vert
	clr.w Horiz
hpos_equal
	cmp.w Horiz(pc),d1
	ble.s no_greater
	move.w d1,Horiz
no_greater
	addq.l #1,Timer

	btst #6,$bfe001
	bne.s no_left
	tst.w mt_percent
	beq.s no_right
	subq.w #1,mt_percent
	bra.s no_right
no_left
	btst #2,$dff016
	bne.s no_right
	cmp.w #100,mt_percent
	beq.s no_right
	addq.w #1,mt_percent
no_right

	move.w #$0020,$dff09c
	rte
save_all
	lea $dff000,a5
	move.b #%10000111,$bfd100
	move.l 4.w,a6
	jsr -132(a6)
	lea data_base(pc),a6
	move.l $6c.w,save_IT3-data_base(a6)
	move.l $78.w,save_IT6-data_base(a6)
	move.w $1c(a5),save_intena-data_base(a6)
	or.w #$c000,save_intena-data_base(a6)
	move.w $2(a5),save_dmacon-data_base(a6)
	or.w #$8200,save_dmacon-data_base(a6)
	rts
restore_all
	lea $dff000,a5
.wait_blitter
	btst #6,$2(a5)
	bne.s .wait_blitter
	move.l save_IT3(pc),$6c.w
	move.l save_IT6(pc),$78.w
	move.w #$7fff,d0
	move.w d0,$9a(a5)
	move.w d0,$96(a5)
	move.w save_dmacon(pc),$96(a5)
	move.w save_intena(pc),$9a(a5)
	move.l 4.w,a6
	lea GfxName(pc),a1
	moveq #0,d0
	jsr -552(a6)
	move.l d0,a0
	move.l $26(a0),$80(a5)
	move.l $32(a0),$84(a5)
	clr.w $88(a5)
	move.l d0,a1
	jsr -414(a6)
	jsr -138(a6)
	rts
Putch	move.b d0,(a3)+
	rts
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

	section prout,data_c
	include "asm:.s/The Module Converter/TMC_Replay3.9_volume.s"
	include "Song.s"
	include "Samples.s"
