	incdir "asm:"
	include "sources/registers.i"

*--------------------------> quelques constantes
TL_SIZE=512*12+256
TL_SYNC=$4489
TL_TRUE=0
TL_FALSE=$ffff

*--------------------------> definition des Tags pour le trackload
*---------------------> Arguments	| Return Value
TL_START_TAG=0		None		| None
TL_STOP_TAG=1		None		| None
TL_MOTOR_ON=2		None		| None
TL_MOTOR_OFF=3		None		| None
TL_SEEK=4		Track.W		| None
TL_SEEK_ZERO=5		None		| None
TL_READ=6		None		| None
TL_WRITE=7		None		| None
TL_CODE=8		Adr.L		| None
TL_UNCODE=9		Adr.L		| if Ok then TL_TRUE Else TL_FALSE
TL_SET_LOAD_BUFFER=10	Buffer Adr.L	| None
TL_SET_WRITE_BUFFER=11	Buffer Adr.L	| None
TL_DO_LOOP=13		Repeat Nbr or 0	| TL_WORD=Loop Number
TL_STEP=14		None		| None
TL_DISK_PRESENT=15	None		| If Disk then TL_TRUE Else TL_FALSE
TL_DISK_PROTECT=16	None		| If Protect then TL_TRUE Else TL_FALSE
TL_SET_UNIT=17		Unit.W		| If Ok then TL_TRUE Else TL_FALSE
TL_SET_TRY=19		Nb Try.W	| None
TL_IF=21		None		| If TL_TRUE Then continue Else Skip
TL_ELSE=22		None		| to TL_ELSE or TL_ENDIF
TL_ENDIF=23		None		| These 3 Tags returns Nothing
TL_GET_BYTE=24		Offset.L	| None
TL_GET_WORD=25		Offset.L	| None
TL_GET_LONG=26		Offset.L	| None
TL_SET_BYTE=27		Adr.L		| None
TL_SET_WORD=28		Adr.L		| None
TL_SET_LONG=29		Adr.L		| None
TL_CMP_BYTE=30		Value.W		| If Equal then TL_TRUE Else TL_FALSE
TL_CMP_WORD=31		Value.W		| If Equal then TL_TRUE Else TL_FALSE
TL_CMP_LONG=32		Value.L		| If Equal then TL_TRUE Else TL_FALSE
TL_RESET=33		None		| None
TL_EXECUTE=34		Adr.L		| None

*--------------------------> allure de la pile
	rsreset
TL_Track	rs.l 1
TL_Load_Buffer	rs.l 1
TL_Write_Buffer	rs.l 1
TL_Data		rs.l 1
TL_Try		rs.w 1
TL_Boolean	rs.w 1
TL_Loop		rs.w 1
TL_Unit		rs.w 1
TL_SIZEOF	rs.w 0

*--------------------------> routine qui gere les Tags pour le track load
*--------------------------> a0=Tags List
TL_Execute_Tags
	lea ciaapra,a4
	lea ciabprb,a5
	lea custom_base,a6
loop_execute_Tags
	move.w (a0)+,d0			lit un Tag
	add.w d0,d0
	add.w d0,d0
	jmp Tags_Jumps(pc,d0.w)		saute à la routine du Tag
Tags_Jumps
	bra.w do_start
	bra.w do_stop
	bra.w do_motor_on
	bra.w do_motor_off
	bra.w do_seek
	bra.w do_seek_zero
	bra.w do_load
	bra.w do_write
	bra.w do_code
	bra.w do_uncode
	bra.w do_set_load_buffer
	bra.w do_set_write_buffer
	bra.w do_set_code_buffer
	bra.w do_loop
	bra.w do_step
	bra.w do_disk_present
	bra.w do_disk_protect
	bra.w do_set_unit
	bra.w do_set_size
	bra.w do_try
	bra.w do_sync
	bra.w do_if
	bra.w do_else
	bra.w do_endif
	bra.w do_get_byte
	bra.w do_get_word
	bra.w do_get_long
	bra.w do_set_byte
	bra.w do_set_word
	bra.w do_set_long
	bra.w do_cmp_byte
	bra.w do_cmp_word
	bra.w do_cmp_long
	bra.w do_reset

*----------------------------> routine qui demarre une Tag_List
do_start
	link sp,#TL_SIZEOF
	bsr loop_execute_Tags
	bra loop_execute_Tags

*----------------------------> on sort du Tag_List
do_stop	
	unlk sp
	rts

*----------------------------> allume le moteur
do_motor_on
	bset #3,(a5)				deselect df0:
	bclr #7,(a5)				ordre motor on
	bclr #3,(a5)				select df0:
disk_ready
	btst #5,(a4)				test dskrdy
	bne.s disk_ready
	bra loop_execute_Tags

*----------------------------> coupe le moteur
do_motor_off		
	bset #3,(a5)				deselect df0:
	bset #7,(a5)				ordre motor off
	bclr #3,(a5)				select df0:
	bra loop_execute_Tags	

*----------------------------> recherche une piste
do_seek
	move.w (a0)+,d0
	bset #2,(a5)				face 0 ( dessous )
	lsr.w #1,d0				quelle face ?
	bcc.s lower_side
	bclr #2,(a5)				face 1 ( dessus )
lower_side
	bclr #1,(a5)				direction=intérieur
	lea TL_track(pc),a1
	move.w (a1),d1				on est ici pour l'instant
	move.w d0,(a1)				on va sur cette piste
	sub.w d1,d0				on va ou ?
	beq.s track_found			nulle part, on y est déja !
	bpl.s dir_good
	neg.w d0				différence positive
	bset #1,(a5)				direction=extérieur
dir_good
	subq.w #1,d0				à cause du dbf
loop_move_head
	bsr give_step
	dbf d0,loop_move_head			boucle pour la différence
track_found
	bra loop_execute_Tags

*----------------------------> recherche la piste 0
do_seek_zero
	bset #1,(a5)				direction exterieur
	bset #2,(a5)				face 0 ( dessous )
.seek
	btst #4,(a4)				piste 0 ?
	beq.s .track_zero
	bsr give_step
	bra.s .seek
.track_zero
	lea TL_track(pc),a1
	clr.w (a1)				on est sur la piste 0
	bra loop_execute_Tags

*----------------------------> routine qui donne un step
give_step
	bset #0,(a5)
	nop
	nop
	nop
	bclr #0,(a5)				donne un step
	nop
	nop
	nop
	bset #0,(a5)
	move.w #4000,d1				delay ( 3 milliseconds )
	dbf d1,*
	rts

*--------------------------> lecture d'une piste
do_load_track
	move.w #$4000,dsklen(a6)		efface dsklen
	move.w #TL_SYNC,dsksync(a6)		valeur de synchro
	move.w #$7f00,adkcon(a6)		efface adkcon
	move.w #$8500,adkcon(a6)		met les bonnes valeurs
	move.l TL_load_Buffer(pc),dskpt(a6)	adresse de lecture
	move.w #$8000|TL_SIZE,dsklen(a6)	met la taille + lecture
	move.w #$8000|TL_SIZE,dsklen(a6)	et lance le dma
wait_dma_end
	btst #1,intreqr+1(a6)			attend la fin du dma-disk
	beq.s wait_dma_end
	move.w #$0002,intreq(a6)		vire l'IT
	move.w #$4000,dsklen(a6)		stop le dma disk
	bra loop_execute_Tags

*---------------------------> écriture d'une piste  a0=Buffer
write_track
	move.w #$4000,dsklen(a6)		efface dsklen
	move.w #$7f00,adkcon(a6)		efface adkcon
	move.w TL_track(pc),d0
	move.w #$1100,d1			($f100+$2000).W
search_precom
	sub.w #$2000,d1
	sub.w #40,d0
	bge.s search_precom
	move.w d1,adkcon(a6)
do_write
	move.l TL_write_Buffer(pc),dskpt(a6)
	move.w #$c000|TL_SIZE,dsklen(a6)	mode write
	move.w #$c000|TL_SIZE,dsklen(a6)
.wait_end_dma_disk
	btst #1,intreqr+1(a6)			attend la fin du dma disk
	beq.s .wait_end_dma_disk
	move.w #$0002,intreq(a6)		mâte l'IT
	move.w #$4000,dsklen(a6)		stop le dma disk
	bra loop_execute_Tags

*--------------------------> codage en MFM
MFM_Code
	move.w #TL_SIZE/2-1,d0
	move.l #$55555555,d1
	move.l (a0)+,a1				source
	move.l TL_write_Buffer(pc),a2		destination
loop_Code
	move.l (a1)+,d2				va chercher un LONG
	move.l d2,d3
	lsr.l #1,d3				code les bits impairs en premier
	and.l d1,d3
	move.l d3,d5
	eor.l d1,d3
	move.l d3,d4
	add.l d4,d4
	lsr.l #1,d3
	bset #31,d3
	and.l d4,d3
	or.l d5,d3
	move.l d3,(a2)+
	and.l d1,d2				code ensuite les bits pairs
	move.l d2,d4
	eor.l d1,d2
	move.l d2,d3
	add.l d3,d3
	lsr.l #1,d2
	bset #31,d2
	and.l d3,d2
	or.l d4,d2
	move.l d2,(a2)+
	dbf d0,loop_Code			boucle pour tout le buffer
	bra loop_execute_Tags

*--------------------------> décodage en MFM
MFM_Uncode
	move.l TL_load_Buffer(pc),a1		source
	move.l (a0)+,a2				destination
	move.l #$55555555,d0			d0=masque bit de syncro
	moveq #11-1,d1				11 secteurs à decoder
search_sync
	cmp.w #TL_SYNC,(a1)+			recherche la syncro
	bne.s search_sync
	cmp.w #TL_SYNC,(a1)
	beq.s search_sync

	movem.l (a1),d3-d4			decode description secteur
	and.l d0,d3				masque bit impaires
	and.l d0,d4				masque bit paires
	add.l d3,d3				pivote bit impaires
	or.l d4,d3				format, piste, secteur, next
	add.w d3,d3				multiple de 512
	and.w #$1e00,d3				garde que N° de secteur
	lea 0(a2,d3.w),a4			adresse oû décoder

	move.l 40+4(a1),d2			calcul de la somme
	moveq #10-1,d3				d'auto-controle du header
header_checksum
	move.l (a1)+,d4
	eor.l d4,d2
	dbf d3,header_checksum
	and.l d0,d2
	bne.s read_error

	lea 16-4(a1),a1
	move.l (a1)+,d5
	lea 512(a1),a3				pointe données paires
	moveq #512/4-1,d2			nb de long mot à decoder
decode_sect	
	move.l (a1)+,d3				données impaires
	move.l (a3)+,d4				données paires
	eor.l d3,d5				calcul le checksum au passage
	eor.l d4,d5
	and.l d0,d3				vire bit de syncro
	and.l d0,d4
	add.l d3,d3
	or.l d4,d3
	move.l d3,(a4)+				sauve le mot décodé
	dbf d2,decode_sect			décode le secteur
	and.l d0,d5
	bne.s read_error

	dbf d1,search_sync			décode la piste
	moveq #0,d0				pas d'erreur sur la piste
read_error
	rts

