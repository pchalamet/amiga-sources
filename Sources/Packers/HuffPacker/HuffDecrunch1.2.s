
*		HuffDepacker v1.2  by Sync of ThE SpeCiaL BroThErs
*		--------------------------------------------------

************************************************
* INIT THE FOLLOWING REGISTERS LIKE THIS :     *
* a0=source  a1=destination  a2=Huffman buffer *
* AND BSR OR JSR TO HP_Decrunch                *
* THIS ROUTINE DESTROYS  D0-D5/A0/A1/A3/A4     *
************************************************

HP_Decrunch
	move.w (a0)+,d0
	move.l a2,a3
	moveq #0,d4
	move.l d4,(a3)
	move.l d4,4(a3)
HP_loop_build_tree
	move.l a2,a4
	move.b (a0)+,d5
	moveq #0,d1
	move.b (a0)+,d1
	move.w d1,d3
	lsr.b #3,d3
HP_loop_get_huffman_code
	lsl.l #8,d2
	move.b (a0)+,d2
	dbf d3,HP_loop_get_huffman_code
HP_loop_build_for_code
	lsr.l #1,d2
	bcc.s HP_process_left
HP_process_right
	tst.l (a4)
	bne.s HP_already_right
	addq.l #8,a3
	move.l d4,(a3)
	move.l d4,4(a3)
	move.l a3,(a4)
	move.l a3,a4
	dbf d1,HP_loop_build_for_code
	move.b d5,4(a4)
	dbf d0,HP_loop_build_tree
	bra.s HP_decompress
HP_already_right
	move.l (a4),a4
	dbf d1,HP_loop_build_for_code
	move.b d5,4(a4)
	dbf d0,HP_loop_build_tree
	bra.s HP_decompress
HP_process_left
	tst.l 4(a4)
	bne.s HP_already_left
	addq.l #8,a3
	move.l d4,(a3)
	move.l d4,4(a3)
	move.l a3,4(a4)
	move.l a3,a4
	dbf d1,HP_loop_build_for_code
	move.b d5,4(a4)
	dbf d0,HP_loop_build_tree
	bra.s HP_decompress
HP_already_left
	move.l 4(a4),a4
	dbf d1,HP_loop_build_for_code
	move.b d5,4(a4)
	dbf d0,HP_loop_build_tree
HP_decompress
	move.l a0,d0
	addq.l #1,d0
	moveq #-2,d2
	and.l d2,d0
	move.l d0,a0
	move.l (a0)+,d0
	moveq #32-1,d1
	move.l (a0)+,d2
	move.l a2,a3
HP_loop_depack
	add.l d2,d2
	bcc.s HP_To_Left
	move.l (a3),a3
	tst.l (a3)
	beq.s HP_Terminaison
	dbf d1,HP_loop_depack
	moveq #32-1,d1
	move.l (a0)+,d2
	bra.s HP_loop_depack
HP_To_Left
	move.l 4(a3),a3
	tst.l (a3)
	beq.s HP_Terminaison
	dbf d1,HP_loop_depack
	moveq #32-1,d1
	move.l (a0)+,d2
	bra.s HP_loop_depack
HP_Terminaison
	move.b 4(a3),(a1)+
	move.l a2,a3
	move.w d0,$dff180		THIZ LINE CAN BE REMOVED IF YA WANT!!
	subq.l #1,d0
	dbeq d1,HP_loop_depack
	beq.s HP_end
	moveq #32-1,d1
	move.l (a0)+,d2
	bra.s HP_loop_depack
HP_end	rts

