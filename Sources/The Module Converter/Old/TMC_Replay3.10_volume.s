
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


			*************************
			* structure de mt_voice *
			*************************
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
mt_vumetre	rs.b 1
mt_loop_start	rs.w 1
mt_function	rs.w 1
mt_dma		rs.w 1
mt_SIZEOF	rs.b 0

			*************************
			* structure d'un sample *
			*************************
	rsreset
mt_sample	rs.b 0
mt_samp_repeat	rs.l 1
mt_samp_replen	rs.w 1
mt_samp_volume	rs.w 1
mt_samp_length	rs.w 1
mt_samp_data	rs.w 0

			****************************
			* routine d'initialisation *
			****************************
mt_init
	lea mt_voice0(pc),a0			efface les structures voice
	moveq #mt_SIZEOF-1,d0
mt_clear_voice
	clr.l (a0)+
	dbf d0,mt_clear_voice
	addq.w #$1,mt_voice0+mt_dma-mt_dmacon(a0)
	addq.w #$2,mt_voice1+mt_dma-mt_dmacon(a0)
	addq.w #$4,mt_voice2+mt_dma-mt_dmacon(a0)
	addq.w #$8,mt_voice3+mt_dma-mt_dmacon(a0)
	lea mt_pos(pc),a1			init songpos
	move.l a1,mt_songpos-mt_dmacon(a0)
	move.l (a1),a1				init pattern_length
	move.w (a1),mt_pattern_length-mt_dmacon(a0)
	move.b #5,mt_counter-mt_dmacon(a0)
	move.b #5,mt_speed-mt_dmacon(a0)
	move.w #2,mt_pattpos-mt_dmacon(a0)
	clr.b mt_pattdelay-mt_dmacon(a0)
	clr.w (a0)				init mt_dmacon
	move.w #100,mt_percent-mt_dmacon(a0)	init le volume general
	lea $dff000,a0				pointe custom chip
	lea $bfe000,a1				pointe aux environs des CIA !!
	move.w #$2000,$9a(a0)			vire les IT
	move.l #mt_IT6_1,$78.w
	move.b #$7f,$dd00-$e000(a1)		vire icr
	move.b #$80,$d600-$e000(a1)		init TBLO CIA-B timer B
	move.b #$01,$d700-$e000(a1)		init TBHI CIA-B timer B
	move.b #$19,$df00-$e000(a1)		init le timer en oneshot
	bset #1,$e001-$e000(a1)			vire le filtre
mt_wait
	btst #1,$dd00-$e000(a1)			hey le timer, t'as fini ??!
	beq.s mt_wait
	move.b #$82,$dd00-$e000(a1)		IT quand CIA-B timerB=0
	move.w #$2000,$9c(a0)
	move.w #$a000,$9a(a0)			autorise IT6

			******************
			* routine de fin *
			******************
mt_end
	moveq #0,d0				et hop.. on vire tout !!
	lea $dff000,a0
	move.w d0,$a8(a0)
	move.w d0,$b8(a0)
	move.w d0,$c8(a0)
	move.w d0,$d8(a0)
	move.w #$f,$96(a0)
	rts

			**********************
			* routine de musique *
			**********************
mt_music
	lea mt_samples_list(pc),a4		pointe les instruments
	moveq #0,d0
	move.b mt_counter(pc),d0
	cmp.b mt_speed(pc),d0
	bne mt_nonew

****************************************************************
* PARTIE APPELLEE QUAND ON DOIT INITIALISER DE NOUVELLES NOTES *
****************************************************************
	move.l mt_songpos(pc),a0
	move.l (a0),a0				adr du pattern
	add.w mt_pattpos(pc),a0			offset dans le pattern

	lea mt_voice0(pc),a1			datas du channel 0
	lea $dff000,a3				custom base
	lea $a0(a3),a2				base registres channel 0
	moveq #0,d3				flag pattern break/song jump
	move.b d3,mt_counter-mt_samples_list(a4)
	move.w d3,mt_dmacon-mt_samples_list(a4)
	moveq #4-1,d4				4 voix à jouer
	moveq #3*4,d5				taille d'une ligne par defaut
	moveq #0,d6
	move.b mt_pattdelay(pc),d6		compteur pour le pattern delay
	moveq #0,d7				flag pour le pattern loop
	move.w #$0400,$96(a3)
	bra.s mt_playvoice

mt_loop_playvoice
	lea mt_SIZEOF(a1),a1			passe au mt_voice suivant
	lea $10(a2),a2				registres audio suivants

*********************************************************
* PARTIE QUI ANALYSE UNE NOTE ET LA RANGE DANS MT_VOICE *
*							*
* en entrée	a0=pointeur sur pattern			*
*		a1=pointeur sur mt_voice		*
*		a2=pointeur sur le hardware du channel	*
*		a3=$dff000				*
*		a4=mt_samples_list			*
*********************************************************
mt_playvoice
	tst.b mt_vumetre(a1)
	beq.s mt_vumetre_init
	subq.b #1,mt_vumetre(a1)
mt_vumetre_init
	move.b (a0)+,d1				récupère le # de l'instrument
	bmi mt_pack				notes packées ?
	and.w #$7c,d1
	beq.s mt_oldinstr			si =0 ya pas d'instrument

	move.l -4(a4,d1.w),a5			ptr sur datas du sample
	move.l (a5)+,mt_len(a1)			init la structure mt_voice
	move.w -2(a5),8(a2)			avec les datas du sample
	move.l (a5)+,mt_repeat(a1)
	move.w (a5)+,mt_replen(a1)
	move.l (a5)+,mt_finetune(a1)
	move.l a5,mt_samp_adr(a1)
	move.b mt_volume+1(a1),mt_vumetre(a1)

mt_oldinstr	
	move.w mt_volume(a1),d0			init le volume general
	mulu mt_percent(pc),d0
	divu #100,d0
	move.w d0,8(a2)

	move.b (a0)+,d0				récupère la fonction
	and.w #$f,d0
	add.w d0,d0				table de LONG
	add.w d0,d0
	move.w d0,mt_function(a1)		sauve le # de fonction
	jmp mt_com2_function(pc,d0.w)

mt_com2_function
	bra.w mt_others				fonction 0
	bra.w mt_others				fonction 1
	bra.w mt_others				fonction 2
	bra.w mt_setport			fonction 3
	bra.w mt_others				fonction 4
	bra.w mt_setvolport			fonction 5
	bra.w mt_others				fonction 6
	bra.w mt_others				fonction 7
	bra.w mt_others				fonction 8
	bra.w mt_sample_offset			fonction 9
	bra.w mt_others				fonction A
	bra.w mt_posjmp				fonction B
	bra.w mt_setvol				fonction C
	bra.w mt_pattbreak			fonction D
	bra.w mt_E_commands			fonction E

*************************************
* ROUTINE DE SET SPEED : COMMANDE F *
*************************************
mt_set_speed
	move.b (a0)+,mt_speed-mt_samples_list(a4)
	bra mt_set_instr

*******************************************************
* ROUTINE QUI ENCLENCHE LE PORTAMENTO : COMMANDES 3/5 *
*******************************************************
mt_setvolport
	move.b (a0)+,(a1)			sauve l'info
	bra.s mt_do_setport
mt_setport
	move.b (a0)+,d1				regarde si le speed est
	beq.s mt_do_setport			nouveau
	move.w d1,mt_port_speed(a1)
mt_do_setport
	moveq #-16,d0				va chercher la bonne periode
	and.b -2(a0),d0				en fonction du FineTune
	moveq #3,d1
	and.b -3(a0),d1
	or.b d0,d1
	ror.b #3,d1
	move.l mt_finetune(a1),a5		pointeur sur le FineTune
	move.w (a5,d1.w),d0			periode de la note à atteindre
	beq mt_no_instr
	move.b mt_volume+1(a1),mt_vumetre(a1)
	move.w d0,mt_port_per(a1)		stocke la periode
	dbf d4,mt_loop_playvoice
	bra mt_end_playvoice

*****************************************
* ROUTINE DE SAMPLE OFFSET : COMMANDE 9 *
*****************************************
mt_sample_offset
	move.b (a0)+,d1				récupère l'info
	beq.s mt_offset_old			on utilise l'ancien ?
	move.b d1,mt_sampleoffset(a1)		sauve le nouveau sample offset
mt_offset_old
	move.b mt_sampleoffset(a1),d1
	lsl.w #7,d1				offset dans le sample
	cmp.w mt_len(a1),d1			c'est plus grand que nature ?
	bge.s mt_offset_skip
	sub.w d1,mt_len(a1)			soustrait à la longueur
	add.w d1,d1
	add.l d1,mt_samp_adr(a1)		ajoute au sample adr
	bra mt_set_instr
mt_offset_skip
	move.w #$1,mt_len(a1)
	move.w mt_dma(a1),$96(a3)		vire la voix
	dbf d4,mt_loop_playvoice
	bra mt_end_playvoice

*****************************************
* ROUTINE DE POSITION JUMP : COMMANDE B *
*****************************************
mt_posjmp
	move.w #2,mt_pattpos-mt_samples_list(a4)
	move.b (a0)+,d1
	add.w d1,d1
	lea mt_pos-mt_samples_list(a4,d1.w),a5
	move.l a5,mt_songpos-mt_samples_list(a4)	nouvelle position
	move.l (a5),a5					va chercher la taille
	move.w (a5),mt_pattern_length-mt_samples_list(a4)	du pattern
	moveq #-5,d3				signal le song jump(N mis)
	bra mt_set_instr

**************************************
* ROUTINE DE SET VOLUME : COMMANDE C *
**************************************
mt_setvol
	move.b (a0)+,d1
	move.b d1,mt_volume+1(a1)		met le nouveau volume ds data

	mulu mt_percent(pc),d1			regle le volume general
	divu #100,d1
	move.w d1,8(a2)
	bra mt_set_instr

*****************************************
* ROUTINE DE PATTERN BREAK : COMMANDE D *
*****************************************
mt_pattbreak
	move.b (a0)+,d1
	move.w mt_break(pc,d1.w),mt_pattpos-mt_samples_list(a4)
	addq.w #1,d3				signal le pattern break(Z viré)
	bra mt_set_instr
mt_break
	dc.w 2,14,26,38,50,62,74,86,98,110,122,134,146,158,170,182,194
	dc.w 206,218,230,242,254,266,278,290,302,314,326,338,350,362
	dc.w 374,386,398,410,422,434,446,458,470,482,494,506,518,530
	dc.w 542,554,566,578,590,602,614,626,638,650,662,674,686,698
	dc.w 710,722,734,746,758

**************************
* GESTION DES COMMANDS E *
**************************
mt_E_commands
	move.b (a0)+,d1				va chercher l'info
	move.b d1,d2
	and.w #$f0,d1
	lsr.w #2,d1
	and.w #$f,d2
	jmp mt_com2_E_function(pc,d1.w)		saute à la fonction

mt_com2_E_function
	bra.w mt_set_filter			fonction E0
	bra.w mt_fineslide_up			fonction E1
	bra.w mt_fineslide_down			fonction E2
	bra.w mt_set_instr			fonction E3
	bra.w mt_set_instr			fonction E4
	bra.w mt_set_instr			fonction E5
	bra.w mt_set_loop			fonction E6
	bra.w mt_set_instr			fonction E7
	bra.w mt_set_instr			fonction E8
	bra.w mt_set_retrig			fonction E9
	bra.w mt_finevolslide_up		fonction EA
	bra.w mt_finevolslide_down		fonction EB
	bra.w mt_set_cutnote			fonction EC
	bra.w mt_set_notedelay			fonction ED
	bra.w mt_set_patterndelay		fonction EE
	bra.w mt_set_instr			fonction EF

******************************************************
* ROUTINE POUR LE CHANGEMENT DU FILTRE : COMMANDE E0 *
******************************************************
mt_set_filter
	beq.s mt_filter_on
	bset #1,$bfe001
	bra mt_set_instr
mt_filter_on
	bclr #1,$bfe001
	bra mt_set_instr

**********************************************
* ROUTINE POUR LE FINESLIDE UP : COMMANDE E1 *
**********************************************
mt_fineslide_up
	moveq #-16,d0				va chercher la bonne periode
	and.b -2(a0),d0				en fonction du FineTune
	moveq #3,d1
	and.b -3(a0),d1
	or.b d0,d1
	ror.b #3,d1
	move.l mt_finetune(a1),a5		pointeur sur le FineTune
	move.w (a5,d1.w),d0			periode de la note
	beq mt_no_instr
	sub.w d2,d0				diminue la periode de la note
	bra mt_E_branch

************************************************
* ROUTINE POUR LE FINESLIDE DOWN : COMMANDE E2 *
************************************************
mt_fineslide_down
	moveq #-16,d0				va chercher la bonne periode
	and.b -2(a0),d0				en fonction du FineTune
	moveq #3,d1
	and.b -3(a0),d1
	or.b d0,d1
	ror.b #3,d1
	move.l mt_finetune(a1),a5		pointeur sur le FineTune
	move.w (a5,d1.w),d0			periode de la note
	beq mt_no_instr
	add.w d2,d0				augmente la periode de la note
	bra mt_E_branch

*********************************************
* ROUTINE POUR LE PATTERNLOOP : COMMANDE E6 *
*********************************************
mt_set_loop
	beq.s mt_init_loop_start		init loop ?
	tst.b mt_loop_counter(a1)		yavait deja une loop ?
	bne.s mt_jump_loop

	move.b d2,mt_loop_counter(a1)		saute sur début de la loop
	move.w mt_loop_start(a1),mt_pattpos-mt_samples_list(a4)
	moveq #-1,d7
	bra mt_set_instr

mt_init_loop_start
	move.w mt_pattpos(pc),mt_loop_start(a1)	sauve la position de départ
	bra mt_set_instr			de la loop

mt_jump_loop
	subq.b #1,mt_loop_counter(a1)
	beq.s mt_remove_loop
	move.w mt_loop_start(a1),mt_pattpos-mt_samples_list(a4)
	moveq #-1,d7
	bra mt_set_instr
mt_remove_loop
	clr.w mt_loop_start(a1)
	bra mt_set_instr

******************************************
* ROUTINE D'INIT DU RETRIG : COMMANDE E9 *
******************************************
mt_set_retrig
	beq.s mt_zero_retrig
	move.w d2,mt_retrig_tic(a1)
	move.w #$10*4,mt_function(a1)
mt_zero_retrig
	bra mt_set_instr

*************************************************
* ROUTINE POUR LE FINEVOLSLIDE UP : COMMANDE EA *
*************************************************
mt_finevolslide_up
	add.w d2,mt_volume(a1)
	cmp.w #64,mt_volume(a1)
	ble.s mt_finevolslide_ok
	move.w #64,mt_volume(a1)
mt_finevolslide_ok
	move.w mt_volume(a1),d0
	mulu mt_percent(pc),d0
	divu #100,d0
	move.w d0,8(a2)
	bra.s mt_set_instr

***************************************************
* ROUTINE POUR LE FINEVOLSLIDE DOWN : COMMANDE EB *
***************************************************
mt_finevolslide_down
	sub.w d2,mt_volume(a1)
	bge.s mt_finevolslide_ok
	clr.w mt_volume(a1)
	move.w #0,8(a2)
	bra.s mt_set_instr

*******************************************
* ROUTINE D'INIT DU CUTNOTE : COMMANDE EC *
*******************************************
mt_set_cutnote
	move.b d2,mt_cutnote_tic(a1)
	move.w #$11*4,mt_function(a1)
	bra.s mt_set_instr

*********************************************
* ROUTINE D'INIT DU NOTEDELAY : COMMANDE ED *
*********************************************
mt_set_notedelay
	move.b d2,mt_delay_tic(a1)
	move.w #$12*4,mt_function(a1)
	bra mt_no_instr

*****************************************************
* ROUTINE POUR L'INIT DU PATTERNDELAY : COMMANDE EE *
*****************************************************
mt_set_patterndelay
	tst.b mt_pattdelay-mt_samples_list(a4)	ya deja un pattern delay ?
	bne.s mt_set_instr
	move.w d2,d6
	addq.w #1,d6
	bra.s mt_set_instr

*******************************
* ROUTINE POUR LA NOTE PACKEE *
*******************************
mt_pack
	and.w #$3,d1				garde que le nb de blank notes
	sub.w d1,d4
	addq.w #1,d5
mt_pack_skip
	move.w mt_volume(a1),d0			regle le volume general
	mulu mt_percent(pc),d0
	divu #100,d0
	move.w d0,8(a2)

	clr.b (a1)				pas d'info
	clr.w mt_function(a1)			pas de fonction
	lea mt_SIZEOF(a1),a1
	lea $10(a2),a2
	subq.w #3,d5				enleve à la taille de la ligne
	dbf d1,mt_pack_skip
	dbf d4,mt_playvoice
	bra.s mt_end_playvoice

*************************************
* ROUTINE POUR LES AUTRES COMMANDES *
*************************************
mt_others
	move.b (a0)+,(a1)			sauve l'info

*******************************************
* INITIALISATIONS DU CHANNEL AVEC LA NOTE *
*******************************************
mt_set_instr
	moveq #-16,d0				va chercher la bonne periode
	and.b -2(a0),d0				en fonction du FineTune
	moveq #3,d1
	and.b -3(a0),d1
	or.b d0,d1
	ror.b #3,d1
	move.l mt_finetune(a1),a5		pointeur sur le FineTune
	move.w (a5,d1.w),d0			periode de la note
	beq.s mt_no_instr
	move.b mt_volume+1(a1),mt_vumetre(a1)
mt_E_branch
	move.w mt_dma(a1),d1			
	move.w d1,$96(a3)			vire le dma du channel
	or.w d1,mt_dmacon-mt_samples_list(a4)	lance le dma sur cette voix
	move.l mt_samp_adr(a1),(a2)		met adr dans registre
	move.w mt_len(a1),4(a2)			met sa taille
	move.w d0,mt_period(a1)			et sa periode
	move.w d0,6(a2)
	clr.w mt_vib_pos(a1)			efface vib_pos et trem_pos
mt_no_instr
	dbf d4,mt_loop_playvoice

mt_end_playvoice
	tst.w mt_dmacon-mt_samples_list(a4)
	beq.s mt_nodma
	move.b #$19,$bfdf00			lance le CIA-B timer B
	or.w #$8000,mt_dmacon-mt_samples_list(a4)
mt_nodma
	tst.w d6				ya du pattern delay ?
	beq.s mt_no_pattdelay
	subq.w #1,d6
	move.b d6,mt_pattdelay-mt_samples_list(a4)
	bne.s mt_exit
mt_no_pattdelay
	tst.w d7				ya une loop ?
	bne.s mt_exit

	tst.w d3
	bmi.s mt_exit				position jump ? ( N mis ? )
	bne.s mt_do_break			pattern break ? ( Z viré ? )

	add.w d5,mt_pattpos-mt_samples_list(a4)		"ligne" suivante
	move.w mt_pattpos(pc),d0
	cmp.w mt_pattern_length(pc),d0			fait gaffe de pas sortir
	bne.s mt_exit					du pattern
	move.w #2,mt_pattpos-mt_samples_list(a4)
mt_do_break
	addq.l #4,mt_songpos-mt_samples_list(a4)	fait gaffe de pas sortir
	move.l mt_songpos(pc),a0			des positions
	cmp.l #mt_pos_end,a0
	blt.s mt_exit2
	move.l mt_restart(pc),a0
	move.l a0,mt_songpos-mt_samples_list(a4)
mt_exit2
	move.l (a0),a0					récupère la taille du
	move.w (a0),mt_pattern_length-mt_samples_list(a4)	pattern
mt_exit
	rts	

**************************************************************
* PARTIE APPELLEE QUAND MT_COUNTER EST DIFFERENT DE MT_SPEED *
**************************************************************
mt_do_retrig
	move.w mt_dmacon(pc),d1
	beq.s mt_retrig_nodma
	move.w d1,$96-$d0(a1)			vire les dma audio
	move.b #$19,$bfdf00			lance la minuterie
	or.w #$8000,mt_dmacon-mt_samples_list(a4)
mt_retrig_nodma
	rts

mt_nonew
	pea mt_do_retrig(pc)
	clr.w mt_dmacon-mt_samples_list(a4)
	addq.b #1,mt_counter-mt_samples_list(a4)
	lea mt_voice0(pc),a0			data voix 0
	lea $dff0a0,a1				hardware channel 0
	moveq #4-1,d4				4 voix à jouer
	bra.s mt_com
mt_loop_nonew
	lea mt_SIZEOF(a0),a0
	lea $10(a1),a1

*********************************************************
* SAUTE A LA ROUTINE DE COMMANDE			*
*							*
* en entrée	a0=pointeur sur mt_voice		*
*		a1=pointeur sur le hardware du channel	*
*********************************************************
mt_com
	tst.b mt_vumetre(a0)
	beq.s mt_vumetre_com
	subq.b #1,mt_vumetre(a0)
mt_vumetre_com
	move.w mt_volume(a0),d1			regle le volume general
	mulu mt_percent(pc),d1
	divu #100,d1
	move.w d1,8(a1)

	move.w mt_function(a0),d0
	jmp mt_com_function(pc,d0.w)

mt_com_function
	bra.w mt_check_arp			fonction 0
	bra.w mt_portup				fonction 1
	bra.w mt_portdown			fonction 2
	bra.w mt_port				fonction 3
	bra.w mt_vibrato			fonction 4
	bra.w mt_volport			fonction 5
	bra.w mt_volvib				fonction 6
	bra.w mt_tremolo			fonction 7
	bra.w mt_com_exit			fonction 8
	bra.w mt_com_exit			fonction 9
	bra.w mt_volslide			fonction A
	bra.w mt_com_exit			fonction B
	bra.w mt_com_exit			fonction C
	bra.w mt_com_exit			fonction D
	bra.w mt_com_exit			fonction E
	bra.w mt_com_exit			fonction F
	bra.w mt_retrig				fonction E9
	bra.w mt_cutnote			fonction EC
	bra.w mt_notedelay			fonction ED

***********************************
* ROUTINE D'ARPEGGIO : COMMANDE 0 *
***********************************
mt_check_arp
	move.b (a0),d1				va chercher l'info
	bne.s mt_arp				faut faire un arpeggio ?
mt_normper
	move.w mt_period(a0),6(a1)		met la période normale
mt_com_exit
	dbf d4,mt_loop_nonew
	rts
mt_arp
	move.b mt_counter(pc),d0		va chercher le compteur
	move.b mt_arplist(pc,d0.w),d0		va chercher le masque
	beq.s mt_normper			=0 ?
	bpl.s mt_arp2				>0 ?
mt_arp1
	lsr.b #4,d1				garde que le 1er
mt_arp2
	and.w d0,d1				garde que le 2ème
mt_arpdo
	add.w d1,d1				table de WORD
	move.w mt_period(a0),d0			période actuelle
	move.l mt_finetune(a0),a2		base des périodes
mt_search_arp
	cmp.w (a2)+,d0				recherche la note
	blt.s mt_search_arp			on la tient ?
mt_arpfound
	move.w -2(a2,d1.w),6(a1)		met la note arpegiotée
	dbf d4,mt_loop_nonew
	rts
mt_arplist
	dc.b 0,$8f,$f,0,$8f,$f,0,$8f,$f,0,$8f,$f,0,$8f,$f,0,$8f,$f
	dc.b 0,$8f,$f,0,$8f,$f,0,$8f,$f,0,$8f,$f,0,$8f,$f,0,$8f,$f
	dc.b 0,$8f,$f,0,$8f,$f,0,$8f,$f,0,$8f,$f,0,$8f,$f,0,$8f,$f
	dc.b 0,$8f,$f,0,$8f,$f,0,$8f,$f,0,$8f,$f,0,$8f,$f,0,$8f,$f
	dc.b 0,$8f,$f,0,$8f,$f,0,$8f,$f,0,$8f,$f,0,$8f,$f,0,$8f,$f
	dc.b 0,$8f,$f,0,$8f,$f,0,$8f,$f,0

*****************************************
* ROUTINE DE PORTAMENTO UP : COMMANDE 1 *
*****************************************
mt_portup
 	move.b (a0),d0				récupère l'info
	move.w mt_period(a0),d1			récupère la période courante
	sub.w d0,d1				diminue la période
	cmp.w #113,d1				test avec période la plus basse
	bge.s mt_portup2
	move.w #113,d1				on va pas plus bas !
mt_portup2
	move.w d1,mt_period(a0)			sauve la période
	move.w d1,6(a1)				période dans le registre
	dbf d4,mt_loop_nonew
	rts

*******************************************
* ROUTINE DE PORTAMENTO DOWN : COMMANDE 2 *
*******************************************
mt_portdown
	move.b (a0),d0				récupère l'info
	move.w mt_period(a0),d1			récupère la période courante
	add.w d0,d1				augmente la période
	cmp.w #856,d1				test avec période la plus haute
	ble.s mt_portup2
	move.w #856,d1				on va pas plus haut !
	move.w d1,mt_period(a0)			sauve la période
	move.w d1,6(a1)				période dans le registre
	dbf d4,mt_loop_nonew
	rts

**************************************
* ROUTINE DE PORTAMENTO : COMMANDE 3 *
**************************************
mt_port
	pea mt_com_exit(pc)
mt_port2
	move.w mt_period(a0),d0			on est à cette periode
	beq.s mt_port_exit
	move.w mt_port_per(a0),d1		on veut aller à celle là
	beq.s mt_port_exit
	cmp.w d0,d1
	beq.s mt_port_end			on y est déja ?
	bgt.s mt_port_add			faut augmenter la periode ?
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

***********************************
* ROUTINE DE VIBRATO : COMMANDE 4 *
***********************************
mt_vibrato
	pea mt_com_exit(pc)
	move.b (a0),d1				récupère l'info actuel
	beq.s mt_vibrato2			si =0 on utilise l'ancien
	move.b d1,d2
	and.w #$f,d2				garde que le rate
	beq.s mt_vib_skip
	add.w d2,d2
	add.w d2,d2
	move.b d2,mt_vib_rate(a0)
mt_vib_skip
	and.w #$f0,d1				garde que le depth
	beq.s mt_vibrato2
	add.w d1,d1
	move.w d1,mt_vib_depth(a0)
mt_vibrato2
	moveq #$3c,d1
	and.b mt_vib_pos(a0),d1			pointeur sur mt_sin
	lsr.w #2,d1
	add.w mt_vib_depth(a0),d1		pointe la bonne table
	move.b mt_vibrato_table(pc,d1.w),d0	va chercher l'amplitude

	move.w mt_period(a0),d1			période de la note
	tst.b mt_vib_pos(a0)			il faut add ou sub ?
	bpl.s mt_vib_add
	neg.w d0
mt_vib_add
	add.w d0,d1
	move.w d1,6(a1)				met la période dans le registre
	move.b mt_vib_rate(a0),d0		récupère l'info
	add.b d0,mt_vib_pos(a0)			ajoute le rate
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

***********************************
* ROUTINE DE TREMOLO : COMMANDE 7 *
***********************************
mt_tremolo
	move.b (a0),d1				récupère l'info actuel
	beq.s mt_tremolo2			si =0 on utilise l'ancien
	move.b d1,d2
	and.w #$f,d2				garde que le rate
	beq.s mt_trem_skip
	add.w d2,d2
	add.w d2,d2
	move.b d2,mt_trem_rate(a0)
mt_trem_skip
	and.w #$f0,d1				garde que le depth
	beq.s mt_tremolo2
	add.w d1,d1
	move.w d1,mt_trem_depth(a0)
mt_tremolo2
	moveq #$3c,d1
	and.b mt_trem_pos(a0),d1		pointeur sur mt_sin
	lsr.w #2,d1
	add.w mt_trem_depth(a0),d1		pointe la bonne table
	move.b mt_tremolo_table(pc,d1.w),d0	va chercher l'amplitude

	move.w mt_volume(a0),d1			volume de la note
	tst.b mt_trem_pos(a0)			il faut add ou sub
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
	mulu mt_percent(pc),d1			regle le volume general
	divu #100,d1
	move.w d1,8(a1)				met la période dans le registre
	move.b mt_trem_rate(a0),d0
	add.b d0,mt_trem_pos(a0)		ajoute le rate
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

*****************************************************
* ROUTINE DE PORTAMENTO + VOLUME SLIDE : COMMANDE 5 *
*****************************************************
mt_volport
	pea mt_volslide(pc)
	bra mt_port2				continue le portamento

**************************************************
* ROUTINE DE VIBRATO + VOLUME SLIDE : COMMANDE 6 *
**************************************************
mt_volvib
	bsr mt_vibrato2				continue le vibrato

****************************************
* ROUTINE DE VOLUME SLIDE : COMMANDE A *
****************************************
mt_volslide
	move.b (a0),d0
	add.b d0,mt_volume+1(a0)		ajoute le volume ( signed )
	bmi.s mt_vol2
	cmp.w #64,mt_volume(a0)			ça dépasse ?
	ble.s mt_vol1				non c'est bon
	move.w #64,mt_volume(a0)
mt_vol1
	move.w mt_volume(a0),d0			regle le volume general
	mulu mt_percent(pc),d0
	divu #100,d0
	move.w d0,8(a1)				met le volume dans le registre
	dbf d4,mt_loop_nonew
	rts
mt_vol2
	clr.w mt_volume(a0)			y a pas de volume
	move.w #0,8(a1)				vire le volume
	dbf d4,mt_loop_nonew
	rts

***********************************
* ROUTINE DE RETRIG : COMMANDE E9 *
***********************************
mt_retrig
	move.b mt_speed(pc),d0
	sub.b mt_counter(pc),d0
	divu.w mt_retrig_tic(a0),d0
	swap d0
	tst.w d0
	bne.s mt_no_retrig

	move.w mt_dma(a0),d0
	or.w d0,mt_dmacon-mt_samples_list(a4)	lance le dma sur cette voix
	move.l mt_samp_adr(a0),(a1)		met adr dans registre
	move.w mt_len(a0),4(a1)			met sa taille
	move.w mt_period(a0),6(a1)
mt_no_retrig
	dbf d4,mt_loop_nonew
	rts

************************************
* ROUTINE DE CUTNOTE : COMMANDE EC *
************************************
mt_cutnote
	move.b mt_speed(pc),d0
	sub.b mt_counter(pc),d0
	cmp.b mt_cutnote_tic(a0),d0
	bge.s mt_no_cutnote

	clr.w mt_volume(a0)
	move.w #0,8(a1)
	move.w #$E*4,mt_function(a0)		vire la fonction
mt_no_cutnote
	dbf d4,mt_loop_nonew
	rts

**************************************
* ROUTINE DE NOTEDELAY : COMMANDE ED *
**************************************
mt_notedelay
	move.b mt_speed(pc),d0
	sub.b mt_counter(pc),d0
	cmp.b mt_delay_tic(a0),d0
	bge.s mt_no_notedelay

	move.w mt_dma(a0),d0
	or.w d0,mt_dmacon-mt_samples_list(a4)	lance le dma sur cette voix
	move.l mt_samp_adr(a0),(a1)		met adr dans registre
	move.w mt_len(a0),4(a1)			met sa taille
	move.w mt_period(a0),6(a1)
	move.w #$E*4,mt_function(a0)		vire la fonction
mt_no_notedelay
	dbf d4,mt_loop_nonew
	rts

************************************************************************
* LES ROUTINES D'INTERRUPTION DE NIVEAU 6 : INITIALISATION DES SAMPLES *
************************************************************************
mt_IT6_1
	move.w mt_dmacon(pc),$dff096		autorise le dma audio
	tst.b $bfdd00				vire l'IT
	add.l #mt_IT6_2-mt_IT6_1,$78.w		passe à l'IT suivante
	move.b #$19,$bfdf00			relance la minuterie
	move.w #$2000,$dff09c
	rte

mt_IT6_2
	move.l a0,-(sp)
	lea $dff0a0,a0
	move.l mt_voice0+mt_repeat(pc),(a0)+	met les valeurs de boucles
	move.w mt_voice0+mt_replen(pc),(a0)
	move.l mt_voice1+mt_repeat(pc),$b0-$a4(a0)
	move.w mt_voice1+mt_replen(pc),$b4-$a4(a0)
	move.l mt_voice2+mt_repeat(pc),$c0-$a4(a0)
	move.w mt_voice2+mt_replen(pc),$c4-$a4(a0)
	move.l mt_voice3+mt_repeat(pc),$d0-$a4(a0)
	move.w mt_voice3+mt_replen(pc),$d4-$a4(a0)
	tst.b $bfdd00				vire l'IT
	sub.l #mt_IT6_2-mt_IT6_1,$78.w		remet l'ancienne IT
	move.w #$2000,$9c-$a4(a0)
	move.w #$8400,$96-$a4(a0)
	move.l (sp)+,a0
	rte

**************************
* LES DATAS DE LA REPLAY *
**************************
mt_voice0		ds.b mt_SIZEOF		datas pour les <> channels
mt_voice1		ds.b mt_SIZEOF
mt_voice2		ds.b mt_SIZEOF
mt_voice3		ds.b mt_SIZEOF
mt_dmacon		dc.w 0
mt_percent		dc.w 0
mt_pattern_length	dc.w 0
mt_pattpos		dc.w 0
mt_songpos		dc.l 0
mt_counter		dc.b 0
mt_speed		dc.b 0
mt_pattdelay		dc.b 0
			even

*************************************************
* INCLUDE here the file Song.s generated by TMC *
* and -maybe- somewhere else the file Samples.s *
*************************************************
