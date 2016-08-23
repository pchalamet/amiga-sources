
	OPT O-

*
*			TrackLoad & TrackWrite
*			--------------------------->
*			© Sync\Dreamdealers
*

*	Ces routines utilisent le CIA-B TIMER B histoire de pas trop
*	embeter le systeme et surtout ProTracker !!! aaaaaarrrrggggg...
*

*--------------------------> taille de la piste en mots
MFM_SIZE=512*12+256	taille du buffer
RAW_SIZE=11*512
MFM_SYNC=$4489		marque de synchro
MFM_TRY=3		nb d'essai
DRIVE=0			disk sur lequel on bosse
DELAY=2148		\
DELAY_LO=DELAY&$ff	 | delay de 3 millisecondes pour les TIMERs des CIAs
DELAY_HI=DELAY>>8	/

	include "asm:sources/registers.i"

	section gaston,code_c

		KILL_SYSTEM do_track
bingo
		moveq #0,d0
		rts


do_track
		lea custom_base,a6
		move.w #$8210,dmacon(a6)	enable dma + dma disk
		move.w #$8002,intena(a6)	dma finished

		bsr init_regs
		bsr motor_on
		bsr seek_track_zero
		bsr motor_off
;
;		moveq #40,d0
;		bsr seek_track
;
		moveq #1-1,d7
		lea Buffer(pc),a0
		bsr read_disk

		RESTORE_SYSTEM


*--------------------------> init qq registres
init_regs	lea ciaapra,a4
		lea ciabprb,a5
		lea custom_base,a6

		move.b #$7f,ciabicr-ciabprb(a5)		vire icr
		move.b #DELAY_LO,ciabtblo-ciabprb(a5)	init TBLO CIA-B timer B
		move.b #DELAY_HI,ciabtbhi-ciabprb(a5)	init TBHI CIA-B timer B
		move.b #$19,ciabcrb-ciabprb(a5)		init le timer en oneshot
.wait		btst #1,ciabicr-ciabprb(a5)		attend la fin du timer
		beq.s .wait
		rts

*--------------------------> routine qui charge quelque chose
*--------------------------> d7=nb de pistes-1
*--------------------------> a0=ou l'on charge
read_disk	move.w current_track(pc),d6
		bsr motor_on
loop_read_file	move.w d6,d0			recherche la piste
		bsr seek_track
	rept MFM_TRY
		bsr read_track			lit la piste
		bsr MFM_Uncode			et la decode
		beq.s no_error_read		ya une erreur ???
	endr
disk_damaged	illegal
no_error_read	lea 512*11(a0),a0
		addq.w #1,d6
		dbf d7,loop_read_file
		bra motor_off

*--------------------------> mise en marche du moteur
motor_on	bset #3+DRIVE,(a5)		deselect drive
		bclr #7,(a5)			motor on
		bclr #3+DRIVE,(a5)		select drive

*--------------------------> attend que le lecteur soit pret
disk_ready	btst #5,(a4)			test dskrdy
		bne.s disk_ready
		rts

*--------------------------> stoppe le moteur
motor_off	bset #3+DRIVE,(a5)		deselect drive
		bset #7,(a5)			moteur off
		bclr #3+DRIVE,(a5)		select drive
		rts

*--------------------------> routine pour balancer un step
give_step	bset #0,(a5)
		nop
		nop
		nop
		bclr #0,(a5)			balance un bô step
		nop
		nop
		nop
		bset #0,(a5)

		move.b #$19,ciabcrb-ciabprb(a5)	lance le CIA-B timer B
.wait		btst #1,ciabicr-ciabprb(a5)
		beq.s .wait
		rts

*--------------------------> routine qui recherche la piste 0
seek_track_zero	bset #1,(a5)			direction exterieur
		bset #2,(a5)			face 0 ( dessous )
seek_zero	btst #4,(a4)
		beq.s track_zero		piste 0 ?
		bsr give_step			saute à la piste suivante
		bra.s seek_zero
track_zero	clr.w current_track		on est sur la piste 0
		rts

*--------------------------> positionne la tête de lecture  d0=track
seek_track	bset #2,(a5)			face 0 ( dessous )
		lsr.w #1,d0			quelle face ?
		bcc.s lower_side
		bclr #2,(a5)			face 1 ( dessus )
lower_side	bclr #1,(a5)			direction interieur
		lea current_track(pc),a1
		move.w (a1),d1			on est ici pour l'instant
		move.w d0,(a1)			on va sur cette piste
		sub.w d1,d0			on va ou ?
		beq.s track_found		nulle part, on y est déja !!
		bpl.s dir_good			on va vers l'interieur ?
		neg.w d0			nan.. on va vers l'exterieur
		bset #1,(a5)
dir_good	subq.w #1,d0			à cause du dbf
loop_move_head	bsr give_step			tu booouuuge bien...
		dbf d0,loop_move_head
track_found	rts

current_track	dc.w 0

*--------------------------> lecture d'une piste
read_track	move.w #$7700,adkcon(a6)		vire adkcon coté disk
		move.w #$8500,adkcon(a6)		mfm, word sync, fast
		move.w #MFM_SYNC,dsksync(a6)		marque de synchro
		move.l #MFM_Buffer,dskpt(a6)		adresse ou écrire
		move.w #$4000,dsklen(a6)		efface dsklen
		move.w #$8000|MFM_SIZE,dsklen(a6)	\ met la taille +
		move.w #$8000|MFM_SIZE,dsklen(a6)	/ lecture
wait_dma_end	btst #1,intreqr+1(a6)			fini ce transfer ??
		beq.s wait_dma_end
		move.w #$0002,intreq(a6)		vire l'IT
		move.w #$4000,dsklen(a6)		stop le dma disk
		rts

*---------------------------> écriture d'une piste  a0=Buffer MFM
write_track	move.w #$4000,dsklen(a6)		efface dsklen
		move.w #$7f00,adkcon(a6)		efface adkcon
		move.w current_track(pc),d0		ballon ballon..
		move.w #$1100,d1			($f100+$2000).w
search_precom	sub.w #$2000,d1
		sub.w #40,d0
		bge.s search_precom			cherche cherche!!
		move.w d1,adkcon(a6)			init ca
		move.l a0,dskpt(a6)			adr du buffer
		move.w #$c000|MFM_SIZE,dsklen(a6)	\ mode write
		move.w #$c000|MFM_SIZE,dsklen(a6)	/ et lance le dma
.wait_end_dma	btst #1,intreqr+1(a6)
		beq.s .wait_end_dma
		move.w #$0002,intreq(a6)		mâte l'IT
		move.w #$4000,dsklen(a6)		stop le dma disk
		rts

*------------------> décodage d'une piste  a0=Buffer --> Z=Error Flag => 0=Ok
MFM_Uncode	lea MFM_Buffer,a1
		move.l #$55555555,d0		d0=masque bit de synchro
		moveq #11-1,d1			11 secteur à décoder
search_sync	cmp.w #MFM_SYNC,(a1)+		recherche la synchro
		bne.s search_sync
		cmp.w #MFM_SYNC,(a1)
		beq.s search_sync

		movem.l (a1),d3-d4		decode description secteur
		and.l d0,d3			masque bits impairs
		and.l d0,d4			masque bits pairs
		add.l d3,d3			pivote bits impaires
		or.l d4,d3			format, piste, secteur, next
		add.w d3,d3			multiple de 512
		and.w #$1e00,d3			garde que le N° de secteur
		lea 0(a0,d3.w),a2

		move.l 40+4(a1),d2		calcul de la somme
		moveq #10-1,d3			d'auto-controle du header
header_checksum	move.l (a1)+,d4
		eor.l d4,d2
		dbf d3,header_checksum
		and.l d0,d2
		bne.s read_error

		lea 16-4(a1),a1
		move.l (a1)+,d5
		lea 512(a1),a3			pointe données paires
		moveq #512/4-1,d2		nb de long mot à decoder
decode_sect	move.l (a1)+,d3			données impaires
		move.l (a3)+,d4			données paires
		eor.l d3,d5			calcul le checksum au passage
		eor.l d4,d5
		and.l d0,d3			vire bit de synchro
		and.l d0,d4
		add.l d3,d3
		or.l d4,d3
		move.l d3,(a2)+			sauve le LONG décodé
		dbf d2,decode_sect		décode tout le secteur
		and.l d0,d5			euh.. erreur ???
		bne.s read_error

		dbf d1,search_sync		décode la piste
		moveq #0,d0			pas d'erreur sur la piste
read_error	rts


*--------------------------> codage en MFM  a0=source a1=destination d0=NbLong-1
MFM_Code	move.l #$55555555,d1
loop_Code	move.l (a0)+,d2			va chercher un LONG
		move.l d2,d3
		lsr.l #1,d3			code les bits impairs en premier
		and.l d1,d3
		move.l d3,d5
		eor.l d1,d3
		move.l d3,d4
		add.l d4,d4
		lsr.l #1,d3
		bset #31,d3
		and.l d4,d3
		or.l d5,d3
		move.l d3,(a1)+			code ensuite les bits pairs
		and.l d1,d2
		move.l d2,d4
		eor.l d1,d2
		move.l d2,d3
		add.l d3,d3
		lsr.l #1,d2
		bset #31,d2
		and.l d3,d2
		or.l d4,d2
		move.l d2,(a1)+			boucle pour tout le buffer
		dbf d0,loop_Code
		rts

MFM_Buffer
	dcb.w MFM_SIZE,0
Buffer
	dcb.b RAW_SIZE,0

