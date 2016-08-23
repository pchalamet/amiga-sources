save_all
	lea $dff000,a5
	move.b #%10000111,$bfd100
	move.l (ExecBase).w,a6
	jsr Forbid(a6)
	lea save_base(pc),a6
	move.l $6c.w,save_IT3-save_base(a6)
	move.l $78.w,save_IT6-save_base(a6)
	move.w intenar(a5),save_intena-save_base(a6)
	or.w #$c000,save_intena-save_base(a6)
	move.w dmaconr(a5),save_dmacon-save_base(a6)
	or.w #$8200,save_dmacon-save_base(a6)
	rts

restore_all
	lea $dff000,a5
.wait_blitter
	btst #14,dmaconr(a5)
	bne.s .wait_blitter
	move.l save_IT3(pc),$6c.w
	move.l save_IT6(pc),$78.w
	move.w #$7fff,d0
	move.w d0,intena(a5)
	move.w d0,dmacon(a5)
	move.w save_dmacon(pc),dmacon(a5)
	move.w save_intena(pc),intena(a5)
	move.l (ExecBase).w,a6
	lea GfxName(pc),a1
	moveq #0,d0
	jsr OpenLibrary(a6)
	move.l d0,a0
	move.l $26(a0),cop1lc(a5)
	move.l $32(a0),cop2lc(a5)
	clr.w copjmp1(a5)
	move.l d0,a1
	jsr CloseLibrary(a6)
	jsr Permit(a6)
	rts
save_base
save_intena	dc.w 0
save_dmacon	dc.w 0
save_IT3	dc.l 0
save_IT6	dc.l 0
GfxName		dc.b "graphics.library",0
	even
