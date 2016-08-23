

;
; For convenience and efficiency, this routine processes 8 pixels at
; a time.  In effect, it rotates the 64 bits (from the 8 consecutive
; 8-bit pixels) in the chunky pixel figure above counterclockwise 90
; degrees so that the data is organized as in the planar pixel figure
; above.
;
; This routine proceeds like this:
;
; (A) Initialize
; (B) Process 8 pixels at a time
;     (B1) Load registers with 8 pixels in chunky form
;     (B2) Rotate bits counterclockwise 90 degrees
;	   (B2a) Rotate 4x4 groups within full 8x8
;	   (B2b) Prepare to rotate 2x2 groups within each 4x4 group
;	   (B2c) Rotate 2x2 groups within each 4x4 group |
;	   (B2d) Prepare to rotate single bits within each 2x2 group
;	   (B2e) Rotate single bits within each 2x2 group
;     (B3)  Store 8 pixels in planar form
; (C) Continue processing
; (D) Finish



; +----------------------+
; | Step (A): Initialize |
; +----------------------+

*   -->	a0=chunky
*	a1=bitmap
_ChunkyToPlanar

	MoveM.L D0-D7/A0-A6,-(A7)          ;Save appropriate registers

; Register usage:
;
;	D0	64-bits of the 8 8-bit pixels
;	D1	Another 64-bits of the 8 8-bit pixels
;	D2	Masked copy of D0
;	D3	Masked copy of D1
;	D4	Mask
;	D5	Complement of D4
;	D6	Offset for bitmap
;	A0	Input chunky pixel scanning pointer
;	A1	Pointer to bitmap
;	a2=$aaaaaaaa
;	a3=$0f0f0f0f
;	a4=$f0f0f0f0
;	a5=$cccccccc
;	a6=$ff00ff00
;	d7=$33333333
; +--------------------------------------+
; | Step (B): Process 8 pixels at a time |
; +--------------------------------------+

	move.l	#$AAAAAAAA,a2
	move.l	#$0f0f0f0f,a3
	move.l	#$f0f0f0f0,a4
	move.l	#$cccccccc,a5
	move.l	#$ff00ff00,a6
	move.l	#$33333333,d7

	move.w	#BITMAP_SIZE-1,d6

; +--------------------------------------------------------+
; | Step (B1): Load registers with 8 pixels in chunky form |
; +--------------------------------------------------------+
EnPlane
	move.l	(a0)+,d0	; a b c d
	rol.w	#8,d0		; a b d c
	swap	d0
	rol.w	#8,d0		; d c b a
	move.l	(a0)+,d1	; a b c d
	rol.w	#8,d1		; a b d c
	swap	d1
	rol.w	#8,d1		; d c b a

;	move.l (a0)+,d0
;	move.l (a0)+,d1

; +----------------------------------------------------+
; | Step (B2): Rotate bits counterclockwise 90 degrees |
; +----------------------------------------------------+
;
; +-----------------------------------------------+
; | Step (B2a): Rotate 4x4 groups within full 8x8 |
; +-----------------------------------------------+
;
; Registers D0 and D1 are arranged like this:
;
;		+-------------+-------------+
; D0[ 7 -  0] = | a7 a6 a5 a4 | a3 a2 a1 a0 |
; D0[15 -  8] = | b7 b6 b5 b4 | b3 b2 b1 b0 |
; D0[23 - 16] = | c7 c6 c5 c4 | c3 c2 c1 c0 |
; D0[31 - 24] = | d7 d6 d5 d4 | d3 d2 d1 d0 |
;		+-------------+-------------+
; D1[ 7 -  0] = | e7 e6 e5 e4 | e3 e2 e1 e0 |
; D1[15 -  8] = | f7 f6 f5 f4 | f3 f2 f1 f0 |
; D1[23 - 16] = | g7 g6 g5 g4 | g3 g2 g1 g0 |
; D1[31 - 24] = | h7 h6 h5 h4 | h3 h2 h1 h0 |
;		+-------------+-------------+
;
;	 +----+----+	  +----+----+
;	 | TL | TR |	  | TR | BR |
; Rotate +----+----+ into +----+----+
;	 | BL | BR |	  | TL | BL |
;	 +----+----+	  +----+----+
;
; where each ?? (TL, TR, BL, or BR) is a 4-bit by 4-bit submatrix.


; D0 = d7d6d5d4d3d2d1d0 c7c6c5c4c3c2c1c0 b7b6b5b4b3b2b1b0 a7a6a5a4a3a2a1a0
; D1 = h7h6h5h4h3h2h1h0 g7g6g5g4g3g2g1g0 f7f6f5f4f3f2f1f0 e7e6e5e4e3e2e1e0

	Move.L	a4,D4	; d4=$f0f0f0f0
	Move.L	a3,D5	; a3=$0f0f0f0f

	Move.L	D0,D2
	And.L	D4,D2

; D2 = d7d6d5d4-------- c7c6c5c4-------- b7b6b5b4-------- a7a6a5a4--------

	Move.L	D1,D3
	And.L	D5,D3

; D3 = --------h3h2h1h0 --------g3g2g1g0 --------f3f2f1f0 --------e3e2e1e0

	LSL.L	#4,D0
	And.L	D4,D0

; D0 = d3d2d1d0-------- c3c2c1c0-------- b3b2b1b0-------- a3a2a1a0--------

	Or.L	D3,D0

; D0 = d3d2d1d0h3h2h1h0 c3c2c1c0g3g2g1g0 b3b2b1b0f3f2f1f0 a3a2a1a0e3e2e1e0

	LSR.L	#4,D1
	And.L	D5,D1

; D1 = --------h7h6h5h4 --------g7g6g5g4 --------f7f6f5f4 --------e7e6e5e4

	Or.L	D2,D1

; D1 = d7d6d5d4h7h6h5h4 c7c6c5c4g7g6g5g4 b7b6b5b4f7f6f5f4 a7a6a5a4e7e6e5e4


; +----------------------------------------------------------------+
; | Step (B2b): Prepare to rotate 2x2 groups within each 4x4 group |
; +----------------------------------------------------------------+
;
; Registers D0 and D1 are arranged like this:
;
;		+-------------+-------------+
; D0[ 7 -  0] = | a3 a2 a1 a0 | e3 e2 e1 e0 |
; D0[15 -  8] = | b3 b2 b1 b0 | f3 f2 f1 f0 |
; D0[23 - 16] = | c3 c2 c1 c0 | g3 g2 g1 g0 |
; D0[31 - 24] = | d3 d2 d1 d0 | h3 h2 h1 h0 |
;		+-------------+-------------+
; D1[ 7 -  0] = | a7 a6 a5 a4 | e7 e6 e5 e4 |
; D1[15 -  8] = | b7 b6 b5 b4 | f7 f6 f5 f4 |
; D1[23 - 16] = | c7 c6 c5 c4 | g7 g6 g5 g4 |
; D1[31 - 24] = | d7 d6 d5 d4 | h7 h6 h5 h4 |
;		+-------------+-------------+
;
; Exchange D0[31-16] with D1[15-0]


; D0 = d3d2d1d0h3h2h1h0 c3c2c1c0g3g2g1g0 b3b2b1b0f3f2f1f0 a3a2a1a0e3e2e1e0
; D1 = d7d6d5d4h7h6h5h4 c7c6c5c4g7g6g5g4 b7b6b5b4f7f6f5f4 a7a6a5a4e7e6e5e4

	Swap	D0

; D0 = b3b2b1b0f3f2f1f0 a3a2a1a0e3e2e1e0 d3d2d1d0h3h2h1h0 c3c2c1c0g3g2g1g0

	Move.W	D0,D2
	Move.W	D1,D0
	Move.W	D2,D1

; D0 = b3b2b1b0f3f2f1f0 a3a2a1a0e3e2e1e0 b7b6b5b4f7f6f5f4 a7a6a5a4e7e6e5e4
; D1 = d7d6d5d4h7h6h5h4 c7c6c5c4g7g6g5g4 d3d2d1d0h3h2h1h0 c3c2c1c0g3g2g1g0

	Swap	D0

; D0 = b7b6b5b4f7f6f5f4 a7a6a5a4e7e6e5e4 b3b2b1b0f3f2f1f0 a3a2a1a0e3e2e1e0


; +-----------------------------------------------------+
; | Step (B2c): Rotate 2x2 groups within each 4x4 group |
; +-----------------------------------------------------+
;
; Registers D0 and D1 are arranged like this:
;
;		+-------------+-------------+
; D0[ 7 -  0] = | a3 a2 a1 a0 | e3 e2 e1 e0 |
; D0[15 -  8] = | b3 b2 b1 b0 | f3 f2 f1 f0 |
; D1[ 7 -  0] = | c3 c2 c1 c0 | g3 g2 g1 g0 |
; D1[15 -  8] = | d3 d2 d1 d0 | h3 h2 h1 h0 |
;		+-------------+-------------+
; D0[23 - 16] = | a7 a6 a5 a4 | e7 e6 e5 e4 |
; D0[31 - 24] = | b7 b6 b5 b4 | f7 f6 f5 f4 |
; D1[23 - 16] = | c7 c6 c5 c4 | g7 g6 g5 g4 |
; D1[31 - 24] = | d7 d6 d5 d4 | h7 h6 h5 h4 |
;		+-------------+-------------+
;
;	 +------+------+      +------+------+
;	 | ??tl | ??tr |      | ??tr | ??br |
; Rotate +------+------+ into +------+------+
;	 | ??bl | ??br |      | ??tl | ??bl |
;	 +------+------+      +------+------+
;
; Each ???? (??tl, ??tr, ??bl, or ??br) is a 2-bit by 2-bit
; submatrix that is part of the 4-bit by 4-bit submatrix ??
; (TL, TR, BL, or BR):
;
; +----+----+
; | TL | TR |
; +----+----+
; | BL | BR |
; +----+----+


; D0 = b7b6b5b4f7f6f5f4 a7a6a5a4e7e6e5e4 b3b2b1b0f3f2f1f0 a3a2a1a0e3e2e1e0
; D1 = d7d6d5d4h7h6h5h4 c7c6c5c4g7g6g5g4 d3d2d1d0h3h2h1h0 c3c2c1c0g3g2g1g0

	Move.L	a5,d4	; d4=$CCCCCCCC

	Move.L	D0,D2
	And.L	D4,D2

; D2 = b7b6----f7f6---- a7a6----e7e6---- b3b2----f3f2---- a3a2----e3e2----

	Move.L	D1,D3
	And.L	D7,D3

; D3 = ----d5d4----h5h4 ----c5c4----g5g4 ----d1d0----h1h0 ----c1c0----g1g0

	LSL.L	#2,D0
	And.L	D4,D0

; D0 = b5b4----f5f4---- a5a4----e5e4---- b1b0----f1f0---- a1a0----e1e0----

	Or.L	D3,D0

; D0 = b5b4d5d4f5f4h5h4 a5a4c5c4e5e4g5g4 b1b0d1d0f1f0h1h0 a1a0c1c0e1e0g1g0

	LSR.L	#2,D1
	And.L	D7,D1

; D1 = ----d7d6----h7h6 ----c7c6----g7g6 ----d3d2----h3h2 ----c3c2----g3g2

	Or.L	D2,D1

; D1 = b7b6d7d6f7f6h7h6 a7a6c7c6e7e6g7g6 b3b2d3d2f3f2h3h2 a3a2c3c2e3e2g3g2


; +-----------------------------------------------------------------+
; | Step (B2d): Prepare to rotate single bits within each 2x2 group |
; +-----------------------------------------------------------------+
;
; Registers D0 and D1 are arranged like this:
;
;		+-------------+-------------+
; D0[ 7 -  0] = | a1 a0 c1 c0 | e1 e0 g1 g0 |
; D0[15 -  8] = | b1 b0 d1 d0 | f1 f0 h1 h0 |
; D1[ 7 -  0] = | a3 a2 c3 c2 | e3 e2 g3 g2 |
; D1[15 -  8] = | b3 b2 d3 d2 | f3 f2 h3 h2 |
;		+-------------+-------------+
; D0[23 - 16] = | a5 a4 c5 c4 | e5 e4 g5 g4 |
; D0[31 - 24] = | b5 b4 d5 d4 | f5 f4 h5 h4 |
; D1[23 - 16] = | a7 a6 c7 c6 | e7 e6 g7 g6 |
; D1[31 - 24] = | b7 b6 d7 d6 | f7 f6 h7 h6 |
;		+-------------+-------------+
;
; Exchange D0[15-8] with D1[7-0], and exchange D0[31-24] with D1[23-16]


; D0 = b5b4d5d4f5f4h5h4 a5a4c5c4e5e4g5g4 b1b0d1d0f1f0h1h0 a1a0c1c0e1e0g1g0
; D1 = b7b6d7d6f7f6h7h6 a7a6c7c6e7e6g7g6 b3b2d3d2f3f2h3h2 a3a2c3c2e3e2g3g2

	Move.L	a6,d4	;d4=FF00FF00
	Move.L	D4,D5
	Not.L	D5

	Move.L	D0,D2
	And.L	D4,D2

; D2 = b5b4d5d4f5f4h5h4 ---------------- b1b0d1d0f1f0h1h0 ----------------

	LSR.L	#8,D2

; D2 = ---------------- b5b4d5d4f5f4h5h4 ---------------- b1b0d1d0f1f0h1h0

	Move.L	D1,D3
	And.L	D5,D3

; D3 = ---------------- a7a6c7c6e7e6g7g6 ---------------- a3a2c3c2e3e2g3g2

	LSL.L	#8,D3

; D3 = a7a6c7c6e7e6g7g6 ---------------- a3a2c3c2e3e2g3g2 ----------------

	And.L	D5,D0

; D0 = ---------------- a5a4c5c4e5e4g5g4 ---------------- a1a0c1c0e1e0g1g0

	Or.L	D3,D0

; D0 = a7a6c7c6e7e6g7g6 a5a4c5c4e5e4g5g4 a3a2c3c2e3e2g3g2 a1a0c1c0e1e0g1g0

	And.L	D4,D1

; D1 = b7b6d7d6f7f6h7h6 ---------------- b3b2d3d2f3f2h3h2 ----------------

	Or.L	D2,D1

; D1 = b7b6d7d6f7f6h7h6 b5b4d5d4f5f4h5h4 b3b2d3d2f3f2h3h2 b1b0d1d0f1f0h1h0


; +------------------------------------------------------+
; | Step (B2e): Rotate single bits within each 2x2 group |
; +------------------------------------------------------+
;
; Registers D0 and D1 are arranged like this:
;
;		+-------------+-------------+
; D0[ 7 -  0] = | a1 a0 c1 c0 | e1 e0 g1 g0 |
; D1[ 7 -  0] = | b1 b0 d1 d0 | f1 f0 h1 h0 |
; D0[15 -  8] = | a3 a2 c3 c2 | e3 e2 g3 g2 |
; D1[15 -  8] = | b3 b2 d3 d2 | f3 f2 h3 h2 |
;		+-------------+-------------+
; D0[23 - 16] = | a5 a4 c5 c4 | e5 e4 g5 g4 |
; D1[23 - 16] = | b5 b4 d5 d4 | f5 f4 h5 h4 |
; D0[31 - 24] = | a7 a6 c7 c6 | e7 e6 g7 g6 |
; D1[31 - 24] = | b7 b6 d7 d6 | f7 f6 h7 h6 |
;		+-------------+-------------+
;
;	 +--------+--------+	  +--------+--------+
;	 | ????TL | ????TR |	  | ????TR | ????BR |
; Rotate +--------+--------+ into +--------+--------+
;	 | ????BL | ????BR |	  | ????TL | ????BL |
;	 +--------+--------+	  +--------+--------+
;
; Each ?????? (?????TL, ????TR, ????BL, or ????BR) is a single bit
; that is part of the 2-bit by 2-bit submatrix ???? (??tl, ??tr, ??bl,
; or ??br):
;
; +------+------+
; | ??tl | ??tr |
; +------+------+
; | ??bl | ??br |
; +------+------+
;
; Each ???? (??tl, ??tr, ??bl, or ??br) is a 2-bit by 2-bit submatrix
; that is part of the 4-bit by 4-bit submatrix ?? (TL, TR, BL, or BR):
;
; +----+----+
; | TL | TR |
; +----+----+
; | BL | BR |
; +----+----+


; D0 = a7a6c7c6e7e6g7g6 a5a4c5c4e5e4g5g4 a3a2c3c2e3e2g3g2 a1a0c1c0e1e0g1g0
; D1 = b7b6d7d6f7f6h7h6 b5b4d5d4f5f4h5h4 b3b2d3d2f3f2h3h2 b1b0d1d0f1f0h1h0

	Move.L	a2,D4		;a2=$AAAAAAAA
	Move.L	D4,D5
	Not.L	D5

	Move.L	D0,D2
	And.L	D4,D2

; D2 = a7--c7--e7--g7-- a5--c5--e5--g5-- a3--c3--e3--g3-- a1--c1--e1--g1--

	Move.L	D1,D3
	And.L	D5,D3

; D3 = --b6--d6--f6--h6 --b4--d4--f4--h4 --b2--d2--f2--h2 --b0--d0--f0--h0

	add.l	d0,d0
	And.L	D4,D0

; D0 = a6--c6--e6--g6-- a4--c4--e4--g4-- a2--c2--e2--g2-- a0--c0--e0--g0--

	Or.L	D3,D0

; D0 = a6b6c6d6e6f6g6h6 a4b4c4d4e4f4g4h4 a2b2c2d2e2f2g2h2 a0b0c0d0e0f0g0h0



; +-------------------------------------------+
; | Step (B3):  Store 8 pixels in planar form |
; +-------------------------------------------+
;
; Registers D0 and D1 are arranged like this:
;
;		+-------------+-------------+
; D0[ 7 -  0] = | a0 b0 c0 d0 | e0 f0 g0 h0 |
; D1[ 7 -  0] = | a1 b1 c1 d1 | e1 f1 g1 h1 |
; D0[15 -  8] = | a2 b2 c2 d2 | e2 f2 g2 h2 |
; D1[15 -  8] = | a3 b3 c3 d3 | e3 f3 g3 h3 |
;		+-------------+-------------+
; D0[23 - 16] = | a4 b4 c4 d4 | e4 f4 g4 h4 |
; D1[23 - 16] = | a5 b5 c5 d5 | e5 f5 g5 h5 |
; D0[31 - 24] = | a6 b6 c6 d6 | e6 f6 g6 h6 |
; D1[31 - 24] = | a7 b7 c7 d7 | e7 f7 g7 h7 |
;		+-------------+-------------+


; D0 = a6b6c6d6e6f6g6h6 a4b4c4d4e4f4g4h4 a2b2c2d2e2f2g2h2 a0b0c0d0e0f0g0h0

plane0
	move.b	d0,(a1)+
	Swap	D0
	LSR.L	#1,D1
	And.L	D5,D1

; D1 = --b7--d7--f7--h7 --b5--d5--f5--h5 --b3--d3--f3--h3 --b1--d1--f1--h1


; D0 = a2b2c2d2e2f2g2h2 a0b0c0d0e0f0g0h0 a6b6c6d6e6f6g6h6 a4b4c4d4e4f4g4h4

plane4
	move.b	d0,(BITMAP_SIZE*4-1.w,a1)
	RoR.L	#8,D0

; D0 = a4b4c4d4e4f4g4h4 a2b2c2d2e2f2g2h2 a0b0c0d0e0f0g0h0 a6b6c6d6e6f6g6h6

plane6
	move.b	d0,(BITMAP_SIZE*6-1.w,a1)
	Or.L	D2,D1

; D1 = a7b7c7d7e7f7g7h7 a5b5c5d5e5f5g5h5 a3b3c3d3e3f3g3h3 a1b1c1d1e1f1g1h1
	Swap	D0

; D0 = a0b0c0d0e0f0g0h0 a6b6c6d6e6f6g6h6 a4b4c4d4e4f4g4h4 a2b2c2d2e2f2g2h2

plane2
	move.b	d0,BITMAP_SIZE*2-1(a1)
plane1
	Move.B	D1,BITMAP_SIZE*1-1(a1)
	Swap	D1

; D1 = a3b3c3d3e3f3g3h3 a1b1c1d1e1f1g1h1 a7b7c7d7e7f7g7h7 a5b5c5d5e5f5g5h5

plane5
	move.b	d1,(BITMAP_SIZE*5-1.w,a1)
	RoR.L	#8,D1

; D1 = a5b5c5d5e5f5g5h5 a3b3c3d3e3f3g3h3 a1b1c1d1e1f1g1h1 a7b7c7d7e7f7g7h7

plane7
	move.b	d1,(BITMAP_SIZE*7-1.w,a1)
	Swap	D1

; D1 = a1b1c1d1e1f1g1h1 a7b7c7d7e7f7g7h7 a5b5c5d5e5f5g5h5 a3b3c3d3e3f3g3h3

plane3
	Move.B	D1,BITMAP_SIZE*3-1(a1)

; +-------------------------------+
; | Step (C): Continue processing |
; +-------------------------------+

	dbf	d6,EnPlane
	MoveM.L (A7)+,D0-D7/A0-a6       ;Restore registers
	Rts				;Return

