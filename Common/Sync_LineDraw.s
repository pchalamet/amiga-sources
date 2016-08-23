
; Sync Line Drawing Routine
; d0=X1   d1=Y1   d2=X2   d3=Y3   a0=Bpl

Width=40
Heigth=256
Depth=1
MINTERM=$4a
WORD=1

Line	cmp.w d1,d3
	bgt.s Line1
	beq LineOut
	exg d0,d2
	exg d1,d3
Line1	sub.w d0,d2
	sub.w d1,d3
	subq.w #1,d3
	moveq #0,d4
	ror.w #4,d0
	move.b d0,d4
	and.w #$f000,d0
	add.b d4,d4
	add.w d1,d1
	IFEQ WORD
	add.w d1,d1
	ENDC
	add.w Table_Mulu_Line(pc,d1.w),d4
	lea 0(a0,d4.w),a0
	move.w d0,d4
	or.w #$0b<<8|MINTERM,d4
	moveq #0,d1
	tst.w d2
	bpl.s Line2
	neg.w d2
	moveq #4,d1
Line2	cmp.w d2,d3
	bpl.s Line3
	or.b #16,d1
	bra.s Line4
Line3	exg d2,d3
	add.b d1,d1
Line4	addq.b #3,d1
	or.w d0,d1
	add.w d3,d3
	add.w d3,d3
	add.w d2,d2
Line5	btst #14,dmaconr(a6)
	bne.s Line5
	move.w d3,bltbmod(a6)
	sub.w d2,d3
	bge.s Line6
	or.w #$40,d1
Line6	move.w d1,bltcon1(a6)
	move.w d3,bltapt+2(a6)
	sub.w d2,d3
	move.w d3,bltamod(a6)
	move.w d4,bltcon0(a6)
	move.l a0,bltcpt(a6)
	move.l a0,bltdpt(a6)
	addq.w #1<<1,d2
	lsl.w #5,d2
	addq.b #2,d2
	move.w d2,bltsize(a6)
LineOut	rts

Table_Mulu_Line
MuluCount set 0
	IFNE WORD
	rept Heigth
	dc.w MuluCount*Width*Depth
MuluCount set MuluCount+1
	endr
	ELSEIF
	rept Heigth
	dc.l MuluCount*Width*Depth
MuluCount set MuluCount+1
	endr
	ENDC

LineInit
	btst #14,dmaconr(a6)
	bne.s LineInit
	moveq #Width*Depth,d0
	move.w d0,bltcmod(a6)
	move.w d0,bltdmod(a6)
	moveq #-1,d0
	move.l d0,bltafwm(a6)
	move.l #-$8000,bltbdat(a6)
	rts	
