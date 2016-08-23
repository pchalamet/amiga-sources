
; ByteKiller Mega Profesionnal decrunch routine v1.4
; ©1993 Sync/Dreamdealers !!
; Based on Lord Blitter's ByteKiller1.2
; a0=source   a1=destination
; d0-d5/a0/a2 trashed !!

decrunch
	move.l a1,a2
	add.l (a0)+,a2
	add.l (a0),a0
	moveq #31,d5
	move.l -(a0),d0
dec1	lsr.l #1,d0
	bne.s dec2
	move.l -(a0),d0
	lsr.l #1,d0
	bset d5,d0
dec2	bcs.s dec11
	moveq #8,d1
	moveq #1,d3
	lsr.l #1,d0
	bne.s dec3
	move.l -(a0),d0
	lsr.l #1,d0
	bset d5,d0
dec3	bcs.w dec17
	moveq #3,d1
	moveq #0,d4
dec4	subq.w #1,d1
	moveq #0,d2
dec5	lsr.l #1,d0
	bne.s dec6
	move.l -(a0),d0
	lsr.l #1,d0
	bset d5,d0
dec6	addx.l d2,d2
	dbf d1,dec5
	move.w d2,d3
	add.w d4,d3
dec7	moveq #7,d1
dec8	lsr.l #1,d0
	bne.s dec9
	move.l -(a0),d0
	lsr.l #1,d0
	bset d5,d0
dec9	addx.l d2,d2
	dbf d1,dec8
	move.b d2,-(a2)
	dbf d3,dec7
	bra.s dec21
dec10	moveq #8,d1
	moveq #8,d4
	bra.s dec4
dec11	moveq #2,d1
	subq.w #1,d1
	moveq #0,d2
dec12	lsr.l #1,d0
	bne.s dec13
	move.l -(a0),d0
	lsr.l #1,d0
	bset d5,d0
dec13	addx.l d2,d2
	dbf d1,dec12
	cmp.b #2,d2
	blt.s dec16
	cmp.b #3,d2
	beq.s dec10
	moveq #8,d1
	subq.w #1,d1
	moveq #0,d2
dec14	lsr.l #1,d0
	bne.s dec15
	move.l -(a0),d0
	lsr.l #1,d0
	bset d5,d0
dec15	addx.l d2,d2
	dbf d1,dec14
	move.w d2,d3
	moveq #12,d1
	bra.s dec17
dec16	moveq #9,d1
	add.w d2,d1
	addq.w #2,d2
	move.w d2,d3
dec17	subq.w #1,d1
	moveq #0,d2
dec18	lsr.l #1,d0
	bne.s dec19
	move.l -(a0),d0
	lsr.l #1,d0
	bset d5,d0
dec19	addx.l d2,d2
	dbf d1,dec18
dec20	move.b -1(a2,d2.w),-(a2)
	dbf d3,dec20
***	move.w a2,$dff180
dec21	cmp.l a2,a1
	blt.w dec1
	rts

