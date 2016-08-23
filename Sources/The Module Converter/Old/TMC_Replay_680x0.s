
	*********************************************************
	*							*
	*    TMC_Replay.s v3.9  coded by Sync/DreamDealers	*
	*		Last change : 2 June 1993		*
	*							*
	*	bsr mt_init	: at the init (D0/A0-A1 used )	*
	*	bsr mt_music	: each vbl (D0-D7/A0-A5 used)	*
	*	bsr mt_end	: at the end (D0/A0 used )	*
	*							*
	*	Uses an interrupt of level 6  ( $78.w )		*
	*	DO NOT DISABLE the 13th and 14th bits of INTENA	*
	*	ALSO DO NOT DISABLE bit 9 of DMACON if ya want	*
	*	to hear something...				*
	*	Also uses the CIA-B timer B for initializing	*
	*	the samples while replaying			*
	*							*
	*  Suported commands :  0/1/2/3/4/5/6/7/9/A/B/C/D/F	*
	*			E0/E1/E2/E6/E9/EA/EB/EC/ED/EE	*
	*			+ FineTune			*
	*							*
	*********************************************************

	rsreset
mt_struct_voice	rs.b 0
mt_info		rs.b 1
mt_sampleoffset	rs.b 1
mt_finetune	rs.l 1
mt_samp_adr	rs.l 1
mt_len		rs.w 1
mt_volume	rs.w 1
mt_repeat	rs.l 1
mt_replen	rs.w 1
mt_period	rs.w 1
mt_port_per	rs.w 1
mt_port_speed	rs.w 1
mt_vib_depth	rs.w 1
mt_trem_depth	rs.w 1
mt_vib_rate	rs.b 1
mt_trem_rate	rs.b 1
mt_vib_pos	rs.b 1
mt_trem_pos	rs.b 1
mt_retrig_tic	rs.w 1
mt_cutnote_tic	rs.b 1
mt_delay_tic	rs.b 1
mt_loop_counter	rs.b 1
mt_pad		rs.b 1
mt_loop_start	rs.w 1
mt_function	rs.w 1
mt_dma		rs.w 1
mt_SIZEOF	rs.b 0
	rsreset
mt_sample	rs.b 0
mt_samp_repeat	rs.l 1
mt_samp_replen	rs.w 1
mt_samp_volume	rs.w 1
mt_samp_length	rs.w 1
mt_samp_data	rs.w 0
mt_init
	lea mt_voice0(pc),a0
	moveq #mt_SIZEOF-1,d0
mt_clear_voice
	clr.l (a0)+
	dbf d0,mt_clear_voice
	addq.w #$1,mt_voice0+mt_dma-mt_dmacon(a0)
	addq.w #$2,mt_voice1+mt_dma-mt_dmacon(a0)
	addq.w #$4,mt_voice2+mt_dma-mt_dmacon(a0)
	addq.w #$8,mt_voice3+mt_dma-mt_dmacon(a0)
	lea mt_pos(pc),a1
	move.l a1,mt_songpos-mt_dmacon(a0)
	move.l (a1),a1
	move.w (a1),mt_pattern_length-mt_dmacon(a0)
	move.b #5,mt_counter-mt_dmacon(a0)
	move.b #5,mt_speed-mt_dmacon(a0)
	move.w #2,mt_pattpos-mt_dmacon(a0)
	clr.b mt_pattdelay-mt_dmacon(a0)
	clr.w (a0)
	lea $dff000,a0
	lea $bfe000,a1
	move.w #$2000,$9a(a0)
	move.l #mt_IT6_1,$78.w
	move.b #$7f,$dd00-$e000(a1)
	move.b #$80,$d600-$e000(a1)
	move.b #$01,$d700-$e000(a1)
	move.b #$19,$df00-$e000(a1)
	bset #1,$e001-$e000(a1)
mt_wait
	btst #1,$dd00-$e000(a1)
	beq.s mt_wait
	move.b #$82,$dd00-$e000(a1)
	move.w #$2000,$9c(a0)
	move.w #$a000,$9a(a0)
mt_end
	moveq #0,d0
	lea $dff000,a0
	move.w d0,$a8(a0)
	move.w d0,$b8(a0)
	move.w d0,$c8(a0)
	move.w d0,$d8(a0)
	move.w #$f,$96(a0)
	rts
mt_music
	lea mt_samples_list(pc),a4
mt_counter=*+1
	moveq #0,d0
mt_speed=*+3
	cmp.b #0,d0
	bne mt_nonew
mt_songpos=*+2
	move.l $12345678,a0
mt_pattpos=*+2
	lea $1234(a0),a0
	lea mt_voice0(pc),a1
	lea $dff000,a3
	lea $a0(a3),a2
	moveq #0,d3
	move.b d3,mt_counter-mt_samples_list(a4)
	move.w d3,mt_dmacon-mt_samples_list(a4)
	moveq #4-1,d4
	moveq #3*4,d5
mt_pattdelay=*+1
	moveq #0,d6
	moveq #0,d7
	bra.s mt_playvoice
mt_loop_playvoice
	lea mt_SIZEOF(a1),a1
	lea $10(a2),a2
mt_playvoice
	move.b (a0)+,d1
	bmi mt_pack
	and.w #$7c,d1
	beq.s mt_oldinstr
	move.l -4(a4,d1.w),a5
	move.l (a5)+,mt_len(a1)
	move.w -2(a5),8(a2)
	move.l (a5)+,mt_repeat(a1)
	move.w (a5)+,mt_replen(a1)
	move.l (a5)+,mt_finetune(a1)
	move.l a5,mt_samp_adr(a1)
mt_oldinstr	
	move.b (a0)+,d0
	and.w #$f,d0
	add.w d0,d0
	add.w d0,d0
	move.w d0,mt_function(a1)
	jmp mt_com2_function(pc,d0.w)
mt_com2_function
	bra.w mt_others
	bra.w mt_others
	bra.w mt_others
	bra.w mt_setport
	bra.w mt_others
	bra.w mt_setvolport
	bra.w mt_others
	bra.w mt_others
	bra.w mt_others
	bra.w mt_sample_offset
	bra.w mt_others
	bra.w mt_posjmp
	bra.w mt_setvol
	bra.w mt_pattbreak
	bra.w mt_E_commands
mt_set_speed
	move.b (a0)+,mt_speed-mt_samples_list(a4)
	bra mt_set_instr
mt_setvolport
	move.b (a0)+,(a1)
	bra.s mt_do_setport
mt_setport
	move.b (a0)+,d1
	beq.s mt_do_setport
	move.w d1,mt_port_speed(a1)
mt_do_setport
	moveq #-16,d0
	and.b -2(a0),d0
	moveq #3,d1
	and.b -3(a0),d1
	or.b d0,d1
	ror.b #3,d1
	move.l mt_finetune(a1),a5
	move.w (a5,d1.w),d0
	beq mt_no_instr
	move.w d0,mt_port_per(a1)
	dbf d4,mt_loop_playvoice
	bra mt_end_playvoice
mt_sample_offset
	move.b (a0)+,d1
	beq.s mt_offset_old
	move.b d1,mt_sampleoffset(a1)
mt_offset_old
	move.b mt_sampleoffset(a1),d1
	lsl.w #7,d1
	cmp.w mt_len(a1),d1
	bge.s mt_offset_skip
	sub.w d1,mt_len(a1)
	add.w d1,d1
	add.l d1,mt_samp_adr(a1)
	bra mt_set_instr
mt_offset_skip
	move.w #$1,mt_len(a1)
	move.w mt_dma(a1),$96(a3)
	dbf d4,mt_loop_playvoice
	bra mt_end_playvoice
mt_posjmp
	move.w #2,mt_pattpos-mt_samples_list(a4)
	move.b (a0)+,d1
	add.w d1,d1
	lea mt_pos-mt_samples_list(a4,d1.w),a5
	move.l a5,mt_songpos-mt_samples_list(a4)
	move.l (a5),a5
	move.w (a5),mt_pattern_length-mt_samples_list(a4)
	moveq #-5,d3
	bra mt_set_instr
mt_setvol
	move.b (a0)+,d1
	move.b d1,mt_volume+1(a1)
	move.w d1,8(a2)
	bra mt_set_instr
mt_pattbreak
	move.b (a0)+,d1
	move.w mt_break(pc,d1.w),mt_pattpos-mt_samples_list(a4)
	addq.w #1,d3
	bra mt_set_instr
mt_break
	dc.w 2,14,26,38,50,62,74,86,98,110,122,134,146,158,170,182,194
	dc.w 206,218,230,242,254,266,278,290,302,314,326,338,350,362
	dc.w 374,386,398,410,422,434,446,458,470,482,494,506,518,530
	dc.w 542,554,566,578,590,602,614,626,638,650,662,674,686,698
	dc.w 710,722,734,746,758
mt_E_commands
	move.b (a0)+,d1
	move.b d1,d2
	and.w #$f0,d1
	lsr.w #2,d1
	and.w #$f,d2
	jmp mt_com2_E_function(pc,d1.w)
mt_com2_E_function
	bra.w mt_set_filter
	bra.w mt_fineslide_up
	bra.w mt_fineslide_down
	bra.w mt_set_instr
	bra.w mt_set_instr
	bra.w mt_set_instr
	bra.w mt_set_loop
	bra.w mt_set_instr
	bra.w mt_set_instr
	bra.w mt_set_retrig
	bra.w mt_finevolslide_up
	bra.w mt_finevolslide_down
	bra.w mt_set_cutnote
	bra.w mt_set_notedelay
	bra.w mt_set_patterndelay
	bra.w mt_set_instr
mt_set_filter
	beq.s mt_filter_on
	bset #1,$bfe001
	bra mt_set_instr
mt_filter_on
	bclr #1,$bfe001
	bra mt_set_instr
mt_fineslide_up
	moveq #-16,d0
	and.b -2(a0),d0
	moveq #3,d1
	and.b -3(a0),d1
	or.b d0,d1
	ror.b #3,d1
	move.l mt_finetune(a1),a5
	move.w (a5,d1.w),d0
	beq mt_no_instr
	sub.w d2,d0
	bra mt_E_branch
mt_fineslide_down
	moveq #-16,d0
	and.b -2(a0),d0
	moveq #3,d1
	and.b -3(a0),d1
	or.b d0,d1
	ror.b #3,d1
	move.l mt_finetune(a1),a5
	move.w (a5,d1.w),d0
	beq mt_no_instr
	add.w d2,d0
	bra mt_E_branch
mt_set_loop
	beq.s mt_init_loop_start
	tst.b mt_loop_counter(a1)
	bne.s mt_jump_loop
	move.b d2,mt_loop_counter(a1)
	move.w mt_loop_start(a1),mt_pattpos-mt_samples_list(a4)
	moveq #-1,d7
	bra mt_set_instr
mt_init_loop_start
	move.w mt_pattpos(pc),mt_loop_start(a1)
	bra mt_set_instr
mt_jump_loop
	subq.b #1,mt_loop_counter(a1)
	beq.s mt_remove_loop
	move.w mt_loop_start(a1),mt_pattpos-mt_samples_list(a4)
	moveq #-1,d7
	bra mt_set_instr
mt_remove_loop
	clr.w mt_loop_start(a1)
	bra mt_set_instr
mt_set_retrig
	beq.s mt_zero_retrig
	move.w d2,mt_retrig_tic(a1)
	move.w #$10*4,mt_function(a1)
mt_zero_retrig
	bra.s mt_set_instr
mt_finevolslide_up
	add.w d2,mt_volume(a1)
	cmp.w #64,mt_volume(a1)
	ble.s mt_finevolslide_ok
	move.w #64,mt_volume(a1)
mt_finevolslide_ok
	move.w mt_volume(a1),8(a2)
	bra.s mt_set_instr
mt_finevolslide_down
	sub.w d2,mt_volume(a1)
	bge.s mt_finevolslide_ok
	clr.w mt_volume(a1)
	move.w #0,8(a2)
	bra.s mt_set_instr
mt_set_cutnote
	move.b d2,mt_cutnote_tic(a1)
	move.w #$11*4,mt_function(a1)
	bra.s mt_set_instr
mt_set_notedelay
	move.b d2,mt_delay_tic(a1)
	move.w #$12*4,mt_function(a1)
	bra.s mt_no_instr
mt_set_patterndelay
	tst.b mt_pattdelay-mt_samples_list(a4)
	bne.s mt_set_instr
	move.w d2,d6
	addq.w #1,d6
	bra.s mt_set_instr
mt_pack
	and.w #$3,d1
	sub.w d1,d4
	addq.w #1,d5
mt_pack_skip
	clr.b (a1)
	clr.w mt_function(a1)
	lea mt_SIZEOF(a1),a1
	lea $10(a2),a2
	subq.w #3,d5
	dbf d1,mt_pack_skip
	dbf d4,mt_playvoice
	bra.s mt_end_playvoice
mt_others
	move.b (a0)+,(a1)
mt_set_instr
	moveq #-16,d0
	and.b -2(a0),d0
	moveq #3,d1
	and.b -3(a0),d1
	or.b d0,d1
	ror.b #3,d1
	move.l mt_finetune(a1),a5
	move.w (a5,d1.w),d0
	beq.s mt_no_instr
mt_E_branch
	move.w mt_dma(a1),d1
	move.w d1,$96(a3)
	or.w d1,mt_dmacon-mt_samples_list(a4)
	move.l mt_samp_adr(a1),(a2)
	move.w mt_len(a1),4(a2)
	move.w d0,mt_period(a1)
	move.w d0,6(a2)
	clr.w mt_vib_pos(a1)
mt_no_instr
	dbf d4,mt_loop_playvoice
mt_end_playvoice
	tst.w mt_dmacon-mt_samples_list(a4)
	beq.s mt_nodma
	move.b #$19,$bfdf00
	or.w #$8000,mt_dmacon-mt_samples_list(a4)
mt_nodma
	tst.w d6
	beq.s mt_no_pattdelay
	subq.w #1,d6
	move.b d6,mt_pattdelay-mt_samples_list(a4)
	bne.s mt_exit
mt_no_pattdelay
	tst.w d7
	bne.s mt_exit
	tst.w d3
	bmi.s mt_exit
	bne.s mt_do_break
	add.w d5,mt_pattpos-mt_samples_list(a4)
mt_pattern_length=*+2
	cmp.w #0,mt_pattpos-mt_samples_list(a4)
	bne.s mt_exit
	move.w #2,mt_pattpos-mt_samples_list(a4)
mt_do_break
	addq.l #4,mt_songpos-mt_samples_list(a4)
	move.l mt_songpos(pc),a0
	cmp.l #mt_pos_end,a0
	blt.s mt_exit2
	move.l mt_restart(pc),a0
	move.l a0,mt_songpos-mt_samples_list(a4)
mt_exit2
	move.l (a0),a0
	move.w (a0),mt_pattern_length-mt_samples_list(a4)
mt_exit
	rts
mt_do_retrig
	move.w mt_dmacon(pc),d1
	beq.s mt_retrig_nodma
	move.w d1,$96-$d0(a1)
	move.b #$19,$bfdf00
	or.w #$8000,mt_dmacon-mt_samples_list(a4)
mt_retrig_nodma
	rts
mt_nonew
	pea mt_do_retrig(pc)
	clr.w mt_dmacon-mt_samples_list(a4)
	addq.b #1,mt_counter-mt_samples_list(a4)
	lea mt_voice0(pc),a0
	lea $dff0a0,a1
	moveq #4-1,d4
	bra.s mt_com
mt_loop_nonew
	lea mt_SIZEOF(a0),a0
	lea $10(a1),a1
mt_com
	move.w mt_function(a0),d0
	jmp mt_com_function(pc,d0.w)
mt_com_function
	bra.w mt_check_arp
	bra.w mt_portup
	bra.w mt_portdown
	bra.w mt_port
	bra.w mt_vibrato
	bra.w mt_volport
	bra.w mt_volvib
	bra.w mt_tremolo
	bra.w mt_com_exit
	bra.w mt_com_exit
	bra.w mt_volslide
	bra.w mt_com_exit
	bra.w mt_com_exit
	bra.w mt_com_exit
	bra.w mt_com_exit
	bra.w mt_com_exit
	bra.w mt_retrig
	bra.w mt_cutnote
	bra.w mt_notedelay
mt_check_arp
	move.b (a0),d1
	bne.s mt_arp
mt_normper
	move.w mt_period(a0),6(a1)
mt_com_exit
	dbf d4,mt_loop_nonew
	rts
mt_arp
	move.b mt_counter(pc),d0
	move.b mt_arplist(pc,d0.w),d0
	beq.s mt_normper
	bpl.s mt_arp2
mt_arp1
	lsr.b #4,d1
mt_arp2
	and.w d0,d1
mt_arpdo
	add.w d1,d1
	move.w mt_period(a0),d0
	move.l mt_finetune(a0),a2
mt_search_arp
	cmp.w (a2)+,d0
	blt.s mt_search_arp
mt_arpfound
	move.w -2(a2,d1.w),6(a1)
	dbf d4,mt_loop_nonew
	rts
mt_arplist
	dc.b 0,$8f,$f,0,$8f,$f,0,$8f,$f,0,$8f,$f,0,$8f,$f,0,$8f,$f
	dc.b 0,$8f,$f,0,$8f,$f,0,$8f,$f,0,$8f,$f,0,$8f,$f,0,$8f,$f
	dc.b 0,$8f,$f,0,$8f,$f,0,$8f,$f,0,$8f,$f,0,$8f,$f,0,$8f,$f
	dc.b 0,$8f,$f,0,$8f,$f,0,$8f,$f,0,$8f,$f,0,$8f,$f,0,$8f,$f
	dc.b 0,$8f,$f,0,$8f,$f,0,$8f,$f,0,$8f,$f,0,$8f,$f,0,$8f,$f
	dc.b 0,$8f,$f,0,$8f,$f,0,$8f,$f,0
mt_portup
 	move.b (a0),d0
	move.w mt_period(a0),d1
	sub.w d0,d1
	cmp.w #113,d1
	bge.s mt_portup2
	move.w #113,d1
mt_portup2
	move.w d1,mt_period(a0)
	move.w d1,6(a1)
	dbf d4,mt_loop_nonew
	rts
mt_portdown
	move.b (a0),d0
	move.w mt_period(a0),d1
	add.w d0,d1
	cmp.w #856,d1
	ble.s mt_portup2
	move.w #856,d1
	move.w d1,mt_period(a0)
	move.w d1,6(a1)
	dbf d4,mt_loop_nonew
	rts
mt_port
	pea mt_com_exit(pc)
mt_port2
	move.w mt_period(a0),d0
	beq.s mt_port_exit
	move.w mt_port_per(a0),d1
	beq.s mt_port_exit
	cmp.w d0,d1
	beq.s mt_port_end
	bgt.s mt_port_add
mt_port_sub
	sub.w mt_port_speed(a0),d0
	cmp.w d0,d1
	bge.s mt_port_end
	move.w d0,mt_period(a0)
	move.w d0,6(a1)
mt_port_exit
	rts
mt_port_add
	add.w mt_port_speed(a0),d0
	cmp.w d0,d1
	ble.s mt_port_end
	move.w d0,mt_period(a0)
	move.w d0,6(a1)
	rts
mt_port_end
	clr.w mt_port_per(a0)
	move.w d1,mt_period(a0)
	move.w d1,6(a1)
	rts
mt_vibrato
	pea mt_com_exit(pc)
	move.b (a0),d1
	beq.s mt_vibrato2
	move.b d1,d2
	and.w #$f,d2
	beq.s mt_vib_skip
	add.w d2,d2
	add.w d2,d2
	move.b d2,mt_vib_rate(a0)
mt_vib_skip
	and.w #$f0,d1
	beq.s mt_vibrato2
	add.w d1,d1
	move.w d1,mt_vib_depth(a0)
mt_vibrato2
	moveq #$3c,d1
	and.b mt_vib_pos(a0),d1
	lsr.w #2,d1
	add.w mt_vib_depth(a0),d1
	move.b mt_vibrato_table(pc,d1.w),d0
	move.w mt_period(a0),d1
	tst.b mt_vib_pos(a0)
	bpl.s mt_vib_add
	neg.w d0
mt_vib_add
	add.w d0,d1
	move.w d1,6(a1)
	move.b mt_vib_rate(a0),d0
	add.b d0,mt_vib_pos(a0)
	rts
mt_vibrato_table
	dc.b 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	dc.b 0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0
	dc.b 0,0,0,1,1,1,2,2,2,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,2,2,2,1,1,1,0,0
	dc.b 0,0,1,1,2,2,3,3,4,4,4,5,5,5,5,5,5,5,5,5,5,5,4,4,4,3,3,2,2,1,1,0
	dc.b 0,0,1,2,3,3,4,5,5,6,6,7,7,7,7,7,7,7,7,7,7,7,6,6,5,5,4,3,3,2,1,0
	dc.b 0,0,1,2,3,4,5,6,7,7,8,8,9,9,9,9,9,9,9,9,9,8,8,7,7,6,5,4,3,2,1,0
	dc.b 0,1,2,3,4,5,6,7,8,9,9,10,11,11,11,11,11,11,11,11,11,10,9,9,8,7,6,5,4,3,2,1
	dc.b 0,1,2,4,5,6,7,8,9,10,11,12,12,13,13,13,13,13,13,13,12,12,11,10,9,8,7,6,5,4,2,1
	dc.b 0,1,3,4,6,7,8,10,11,12,13,14,14,15,15,15,15,15,15,15,14,14,13,12,11,10,8,7,6,4,3,1
	dc.b 0,1,3,5,6,8,9,11,12,13,14,15,16,17,17,17,17,17,17,17,16,15,14,13,12,11,9,8,6,5,3,1
	dc.b 0,1,3,5,7,9,11,12,14,15,16,17,18,19,19,19,19,19,19,19,18,17,16,15,14,12,11,9,7,5,3,1
	dc.b 0,2,4,6,8,10,12,13,15,16,18,19,20,20,21,21,21,21,21,20,20,19,18,16,15,13,12,10,8,6,4,2
	dc.b 0,2,4,6,9,11,13,15,16,18,19,21,22,22,23,23,23,23,23,22,22,21,19,18,16,15,13,11,9,6,4,2
	dc.b 0,2,5,7,9,12,14,16,18,20,21,22,23,24,25,25,25,25,25,24,23,22,21,20,18,16,14,12,9,7,5,2
	dc.b 0,2,5,8,10,13,15,17,19,21,23,24,25,26,27,27,27,27,27,26,25,24,23,21,19,17,15,13,10,8,5,2
	dc.b 0,2,5,8,11,14,16,18,21,23,24,26,27,28,29,29,29,29,29,28,27,26,24,23,21,18,16,14,11,8,5,2
mt_tremolo
	move.b (a0),d1
	beq.s mt_tremolo2
	move.b d1,d2
	and.w #$f,d2
	beq.s mt_trem_skip
	add.w d2,d2
	add.w d2,d2
	move.b d2,mt_trem_rate(a0)
mt_trem_skip
	and.w #$f0,d1
	beq.s mt_tremolo2
	add.w d1,d1
	move.w d1,mt_trem_depth(a0)
mt_tremolo2
	moveq #$3c,d1
	and.b mt_trem_pos(a0),d1
	lsr.w #2,d1
	add.w mt_trem_depth(a0),d1
	move.b mt_tremolo_table(pc,d1.w),d0
	move.w mt_volume(a0),d1
	tst.b mt_trem_pos(a0)
	bpl.s mt_trem_add
	neg.w d0
mt_trem_add
	add.w d0,d1
	bpl.s mt_trem_pl
	moveq #0,d1
	bra.s mt_trem_le
mt_trem_pl
	cmp.b #$40,d1
	ble.s mt_trem_le
	moveq #$40,d1
mt_trem_le
	move.w d1,8(a1)
	move.b mt_trem_rate(a0),d0
	add.b d0,mt_trem_pos(a0)
	dbf d4,mt_loop_nonew
	rts
mt_tremolo_table
	dc.b 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	dc.b 0,0,0,1,1,1,2,2,2,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,2,2,2,1,1,1,0,0
	dc.b 0,0,1,2,3,3,4,5,5,6,6,7,7,7,7,7,7,7,7,7,7,7,6,6,5,5,4,3,3,2,1,0
	dc.b 0,1,2,3,4,5,6,7,8,9,9,10,11,11,11,11,11,11,11,11,11,10,9,9,8,7,6,5,4,3,2,1
	dc.b 0,1,3,4,6,7,8,10,11,12,13,14,14,15,15,15,15,15,15,15,14,14,13,12,11,10,8,7,6,4,3,1
	dc.b 0,1,3,5,7,9,11,12,14,15,16,17,18,19,19,19,19,19,19,19,18,17,16,15,14,12,11,9,7,5,3,1
	dc.b 0,2,4,6,9,11,13,15,16,18,19,21,22,22,23,23,23,23,23,22,22,21,19,18,16,15,13,11,9,6,4,2
	dc.b 0,2,5,8,10,13,15,17,19,21,23,24,25,26,27,27,27,27,27,26,25,24,23,21,19,17,15,13,10,8,5,2
	dc.b 0,3,6,9,12,15,17,20,22,24,26,28,29,30,31,31,31,31,31,30,29,28,26,24,22,20,17,15,12,9,6,3
	dc.b 0,3,6,10,13,16,19,22,25,27,29,31,33,34,35,35,35,35,35,34,33,31,29,27,25,22,19,16,13,10,6,3
	dc.b 0,3,7,11,15,18,22,25,28,30,33,35,36,38,39,39,39,39,39,38,36,35,33,30,28,25,22,18,15,11,7,3
	dc.b 0,4,8,12,16,20,24,27,30,33,36,38,40,41,42,43,43,43,42,41,40,38,36,33,30,27,24,20,16,12,8,4
	dc.b 0,4,9,13,18,22,26,30,33,36,39,42,44,45,46,47,47,47,46,45,44,42,39,36,33,30,26,22,18,13,9,4
	dc.b 0,5,10,15,19,24,28,32,36,40,43,45,47,49,50,51,51,51,50,49,47,45,43,40,36,32,28,24,19,15,10,5
	dc.b 0,5,10,16,21,26,30,35,39,43,46,49,51,53,54,55,55,55,54,53,51,49,46,43,39,35,30,26,21,16,10,5
	dc.b 0,5,11,17,22,28,33,37,42,46,49,52,55,57,58,59,59,59,58,57,55,52,49,46,42,37,33,28,22,17,11,5
mt_volport
	pea mt_volslide(pc)
	bra mt_port2
mt_volvib
	bsr mt_vibrato2
mt_volslide
	move.b (a0),d0
	add.b d0,mt_volume+1(a0)
	bmi.s mt_vol2
	cmp.w #64,mt_volume(a0)
	ble.s mt_vol1
	move.w #64,mt_volume(a0)
mt_vol1
	move.w mt_volume(a0),8(a1)
	dbf d4,mt_loop_nonew
	rts
mt_vol2
	clr.w mt_volume(a0)
	move.w #0,8(a1)
	dbf d4,mt_loop_nonew
	rts
mt_retrig
	move.b mt_speed(pc),d0
	sub.b mt_counter(pc),d0
	divu.w mt_retrig_tic(a0),d0
	swap d0
	tst.w d0
	bne.s mt_no_retrig
	move.w mt_dma(a0),d0
	or.w d0,mt_dmacon-mt_samples_list(a4)
	move.l mt_samp_adr(a0),(a1)
	move.w mt_len(a0),4(a1)
	move.w mt_period(a0),6(a1)
mt_no_retrig
	dbf d4,mt_loop_nonew
	rts
mt_cutnote
	move.b mt_speed(pc),d0
	sub.b mt_counter(pc),d0
	cmp.b mt_cutnote_tic(a0),d0
	bge.s mt_no_cutnote
	clr.w mt_volume(a0)
	move.w #0,8(a1)
	move.w #$E*4,mt_function(a0)
mt_no_cutnote
	dbf d4,mt_loop_nonew
	rts
mt_notedelay
	move.b mt_speed(pc),d0
	sub.b mt_counter(pc),d0
	cmp.b mt_delay_tic(a0),d0
	bge.s mt_no_notedelay
	move.w mt_dma(a0),d0
	or.w d0,mt_dmacon-mt_samples_list(a4)
	move.l mt_samp_adr(a0),(a1)
	move.w mt_len(a0),4(a1)
	move.w mt_period(a0),6(a1)
	move.w #$E*4,mt_function(a0)
mt_no_notedelay
	dbf d4,mt_loop_nonew
	rts
mt_IT6_1
	move.w mt_dmacon(pc),$dff096
	tst.b $bfdd00
	add.l #mt_IT6_2-mt_IT6_1,$78.w
	move.b #$19,$bfdf00
	move.w #$2000,$dff09c
	rte
mt_IT6_2
	move.l a0,-(sp)
	lea $dff0a0,a0
	move.l mt_voice0+mt_repeat(pc),(a0)+
	move.w mt_voice0+mt_replen(pc),(a0)
	move.l mt_voice1+mt_repeat(pc),$b0-$a4(a0)
	move.w mt_voice1+mt_replen(pc),$b4-$a4(a0)
	move.l mt_voice2+mt_repeat(pc),$c0-$a4(a0)
	move.w mt_voice2+mt_replen(pc),$c4-$a4(a0)
	move.l mt_voice3+mt_repeat(pc),$d0-$a4(a0)
	move.w mt_voice3+mt_replen(pc),$d4-$a4(a0)
	tst.b $bfdd00
	sub.l #mt_IT6_2-mt_IT6_1,$78.w
	move.w #$2000,$9c-$a4(a0)
	move.l (sp)+,a0
	rte
mt_voice0	ds.b mt_SIZEOF
mt_voice1	ds.b mt_SIZEOF
mt_voice2	ds.b mt_SIZEOF
mt_voice3	ds.b mt_SIZEOF
mt_dmacon	dc.w 0

*************************************************
* INCLUDE here the file Song.s generated by TMC *
* and -maybe- somewhere else the file Samples.s *
*************************************************
