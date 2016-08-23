
*			Fireworks !!!
*			------------------->
*			©1992 Sync/TSB


	incdir "asm:"
	incdir "asm:.s/Demos/"
	include sources/registers.i

	OPT NOCHKBIT

	section juillet,code_c

DemiG=1
NB_FUSE=200
DELAY=100

	KILL_SYSTEM Prout
	moveq #0,d0
	rts

Prout	
	lea d(pc),a5
	lea $dff000,a6
	move.w vhposr(a6),old_hazard-d(a5)

	move.l #coplist,cop1lc(a6)
	move.w d0,copjmp1(a6)
	move.l #vbl,$6c.w
	move.w #0,fmode(a6)

	move.w #$8380,dmacon(a6)
	move.w #$c020,intena(a6)

	WAIT_LMB_DOWN
	RESTORE_SYSTEM

vbl
	bsr.s flip_screen
	bsr.s clear_log_screen
	bsr.s Artifice
	bsr set_artifice_color

	btst #10,potinp(a6)
	bne.s no_red
	move.w #$f00,color00(a6)
no_red
	move.w #$0020,intreq(a6)
	rte

flip_screen
	movem.l phy_screen4(pc),a0-a4
	movem.l a0-a3,log_screen-d(a5)
	move.l a4,phy_screen4-d(a5)
	move.l (a1),bpl1ptH(a6)			affiche a1
	move.l (a2),bpl2ptH(a6)
	move.l (a3),bpl3ptH(a6)
	move.l (a4),bpl4ptH(a6)
	rts

clear_log_screen
	move.l 4(a0),a1				récupère adr du buffer
	moveq #0,d1
	move.l (a1)+,d0				on est obligé de passer
	bmi.s no_star_to_clear			par d0 à cause de movea
loop_clear_screen
	move.l d0,a2
	move.b d1,(a2)
	move.l (a1)+,d0
	bpl.s loop_clear_screen
no_star_to_clear
	rts

no_artifice
	addq.w #1,d0
	cmp.w #DELAY,d0
	bge compute_artifice
	move.w d0,Time-d(a5)
	rts

Artifice
	move.w Time(pc),d0
	cmp.w #DELAY-9,d0
	bge.s no_artifice

	move.l feu_ptr(pc),a1
	lea table_mulu(pc),a2
	move.l 4(a0),a3				clear_buffer de l'écran
	move.l (a0),a0				récupère adr de l'écran
	move.w #NB_FUSE-1,d0			nb d'étoile
	move.l (a1)+,d3				d3=centre X
	moveq #DemiG,d1				d1=G/2
	move.w Time(pc),d2			d2=T
	muls d2,d1
	muls d2,d1				d1=(G/2)*T²
	add.l (a1)+,d1				d1=(G/2)*T²+centre Z
LoopArtifice
	move.w (a1)+,d5
	muls d2,d5				(Vo*Cos A)*T
	add.l d3,d5				recentre sur X
	blt.s no_display1
	cmp.l #351<<4,d5
	bgt.s no_display1

	move.w (a1)+,d6
	muls d2,d6				(Vo*Sin A)*T
	add.l d1,d6				recentre sur Z+ (G/2)*T²
	blt.s no_display2
	cmp.l #271<<4,d6
	bgt.s no_display2

******	il y a 4 << de précision sur T

	lsr.w #4,d5
	move.b d5,d7
	not.b d7				décalage pour bset
	lsr.w #3,d5				adresse en octets
	lsr.w #4-1,d6				table de mots
	and.b #$fe,d6
	move.w 0(a2,d6.w),d6			d6=d6*40
	add.w d6,d5
	lea 0(a0,d5.w),a4
	bset d7,(a4)
	move.l a4,(a3)+
no_display2
	dbf d0,LoopArtifice
	moveq #-1,d0
	move.l d0,(a3)
	addq.w #1,Time-d(a5)
	rts
no_display1
	addq.l #2,a1
	dbf d0,LoopArtifice
	moveq #-1,d0
	move.l d0,(a3)
	addq.w #1,Time-d(a5)
	rts

a=$1af4
c=$4a681ad2

compute_artifice
	clr.l Time-d(a5)
	move.w old_hazard(pc),d0

	bsr.s hazard
	add.w vhposr(a6),d1
	and.w #$3<<3,d1
	lsr.w #1,d1
	lea table_feu(pc),a0
	move.l 0(a0,d1.w),a0
	move.l a0,feu_ptr-d(a5)

	bsr.s hazard
	and.l #$ff,d1
	add.w #33,d1
	lsl.w #4,d1
	move.l d1,(a0)+

	bsr.s hazard
	and.l #$7f,d1
	add.w #40,d1
	lsl.w #4,d1
	move.l d1,(a0)

	move.w d0,old_hazard-d(a5)

	bsr.s hazard
	add.w vhposr(a6),d1
	and.w #$7<<3,d1			table de LONG
	lsr.w #1,d1
	lea artifice_color_ptr(pc),a0
	move.l 0(a0,d1.w),a0
	move.l a0,color_ptr-d(a5)
	add.l #16*2,color_ptr-d(a5)
	lea coplist+2(pc),a1
	moveq #16-1,d0
.loop
	move.w (a0)+,(a1)
	addq.l #4,a1
	dbf d0,.loop

	rts

hazard
	add.w vhposr(a6),d0
	mulu #a,d0
	add.l #c,d0
divise
	divu #180,d0
	bvc.s no_over
	lsr.l #1,d0
	bra.s divise
no_over
	lsl.l #4,d0
	clr.w d0
	swap d0
	move.w d0,d1
	rts	

set_artifice_color
	move.w Time(pc),d0
	cmp.w #DELAY-16*4,d0
	blt.s no_fade_artifice

	addq.w #1,fade_flag-d(a5)
	and.w #%11,fade_flag-d(a5)
	bne.s no_fade_artifice
	move.l color_ptr(pc),a0
	lea coplist+2(pc),a1
	moveq #16-1,d0
.loop
	move.w (a0)+,(a1)
	addq.l #4,a1
	dbf d0,.loop
	move.l a0,color_ptr-d(a5)
no_fade_artifice
	rts	

d
phy_screen4	dc.l screen_struct1
log_screen	dc.l screen_struct2
phy_screen1	dc.l screen_struct3
phy_screen2	dc.l screen_struct4
phy_screen3	dc.l screen_struct5

screen_struct1	dc.l screen1
		dc.l clear_buffer1
screen_struct2	dc.l screen2
		dc.l clear_buffer2
screen_struct3	dc.l screen3
		dc.l clear_buffer3
screen_struct4	dc.l screen4
		dc.l clear_buffer4
screen_struct5	dc.l screen5
		dc.l clear_buffer5

Time		dc.w 0
fade_flag	dc.w 0
old_hazard	dc.w 0
color_ptr	dc.l art_color7+16*2
feu_ptr		dc.l feu1

table_feu
	dc.l feu1
	dc.l feu2
	dc.l feu3
	dc.l feu4

feu1
	dc.l 160<<4
	dc.l 128<<4
	incbin "artifice/fusee2.dat"

feu2
	dc.l 160<<4
	dc.l 128<<4
	incbin "artifice/fusee3.dat"

feu3
	dc.l 160<<4
	dc.l 128<<4
	incbin "artifice/fusee4.dat"

feu4
	dc.l 160<<4
	dc.l 128<<4
	incbin "artifice/fusee5.dat"

make_color	macro
	dc.w 0,\1,\2,\1
	dc.w \3,\1,\2,\1
	dc.w \4,\1,\2,\1
	dc.w \3,\1,\2,\1
	endm

artifice_color_ptr
	dc.l art_color1
	dc.l art_color2
	dc.l art_color3
	dc.l art_color4
	dc.l art_color5
	dc.l art_color6
	dc.l art_color7
	dc.l art_color8

art_color1
	make_color $f00,$c00,$900,$600
	make_color $e00,$b00,$800,$500
	make_color $d00,$a00,$700,$400
	make_color $c00,$900,$600,$300
	make_color $b00,$800,$500,$200
	make_color $a00,$700,$400,$100
	make_color $900,$600,$300,$000
	make_color $800,$500,$200,$000
	make_color $700,$400,$100,$000
	make_color $600,$300,$000,$000
	make_color $500,$200,$000,$000
	make_color $400,$100,$000,$000
	make_color $300,$000,$000,$000
	make_color $200,$000,$000,$000
	make_color $100,$000,$000,$000
	make_color $000,$000,$000,$000
art_color2
	make_color $0f0,$0c0,$090,$060
	make_color $0e0,$0b0,$080,$050
	make_color $0d0,$0a0,$070,$040
	make_color $0c0,$090,$060,$030
	make_color $0b0,$080,$050,$020
	make_color $0a0,$070,$040,$010
	make_color $090,$060,$030,$000
	make_color $080,$050,$020,$000
	make_color $070,$040,$010,$000
	make_color $060,$030,$000,$000
	make_color $050,$020,$000,$000
	make_color $040,$010,$000,$000
	make_color $030,$000,$000,$000
	make_color $020,$000,$000,$000
	make_color $010,$000,$000,$000
	make_color $000,$000,$000,$000
art_color3
	make_color $00f,$00c,$009,$006
	make_color $00e,$00b,$008,$005
	make_color $00d,$00a,$007,$004
	make_color $00c,$009,$006,$003
	make_color $00b,$008,$005,$002
	make_color $00a,$007,$004,$001
	make_color $009,$006,$003,$000
	make_color $008,$005,$002,$000
	make_color $007,$004,$001,$000
	make_color $006,$003,$000,$000
	make_color $005,$002,$000,$000
	make_color $004,$001,$000,$000
	make_color $003,$000,$000,$000
	make_color $002,$000,$000,$000
	make_color $001,$000,$000,$000
	make_color $000,$000,$000,$000
art_color4
	make_color $f0f,$c0c,$909,$606
	make_color $e0e,$b0b,$808,$505
	make_color $d0d,$a0a,$707,$404
	make_color $c0c,$909,$606,$303
	make_color $b0b,$808,$505,$202
	make_color $a0a,$707,$404,$101
	make_color $909,$606,$303,$000
	make_color $808,$505,$202,$000
	make_color $707,$404,$101,$000
	make_color $606,$303,$000,$000
	make_color $505,$202,$000,$000
	make_color $404,$101,$000,$000
	make_color $303,$000,$000,$000
	make_color $202,$000,$000,$000
	make_color $101,$000,$000,$000
	make_color $000,$000,$000,$000
art_color5
	make_color $ff0,$cc0,$990,$660
	make_color $ee0,$bb0,$880,$550
	make_color $dd0,$aa0,$770,$440
	make_color $cc0,$990,$660,$330
	make_color $bb0,$880,$550,$220
	make_color $aa0,$770,$440,$110
	make_color $990,$660,$330,$000
	make_color $880,$550,$220,$000
	make_color $770,$440,$110,$000
	make_color $660,$330,$000,$000
	make_color $550,$220,$000,$000
	make_color $440,$110,$000,$000
	make_color $330,$000,$000,$000
	make_color $220,$000,$000,$000
	make_color $110,$000,$000,$000
	make_color $000,$000,$000,$000
art_color6
	make_color $0ff,$0cc,$099,$066
	make_color $0ee,$0bb,$088,$055
	make_color $0dd,$0aa,$077,$044
	make_color $0cc,$099,$066,$033
	make_color $0bb,$088,$055,$022
	make_color $0aa,$077,$044,$011
	make_color $099,$066,$033,$000
	make_color $088,$055,$022,$000
	make_color $077,$044,$011,$000
	make_color $066,$033,$000,$000
	make_color $055,$022,$000,$000
	make_color $044,$011,$000,$000
	make_color $033,$000,$000,$000
	make_color $022,$000,$000,$000
	make_color $011,$000,$000,$000
	make_color $000,$000,$000,$000
art_color7
	make_color $fff,$ccc,$999,$666
	make_color $eee,$bbb,$888,$555
	make_color $ddd,$aaa,$777,$444
	make_color $ccc,$999,$666,$333
	make_color $bbb,$888,$555,$222
	make_color $aaa,$777,$444,$111
	make_color $999,$666,$333,$000
	make_color $888,$555,$222,$000
	make_color $777,$444,$111,$000
	make_color $666,$333,$000,$000
	make_color $555,$222,$000,$000
	make_color $444,$111,$000,$000
	make_color $333,$000,$000,$000
	make_color $222,$000,$000,$000
	make_color $111,$000,$000,$000
	make_color $000,$000,$000,$000
art_color8
	make_color $633,$966,$c99,$fcc
	make_color $522,$855,$b88,$ebb
	make_color $411,$744,$a77,$daa
	make_color $300,$633,$966,$c99
	make_color $200,$522,$855,$b88
	make_color $100,$411,$744,$a77
	make_color $000,$300,$633,$966
	make_color $000,$200,$522,$855
	make_color $000,$100,$411,$744
	make_color $000,$000,$300,$633
	make_color $000,$000,$200,$522
	make_color $000,$000,$100,$411
	make_color $000,$000,$000,$300
	make_color $000,$000,$000,$200
	make_color $000,$000,$000,$100
	make_color $000,$000,$000,$000

table_mulu
mul set 0
	rept 272
	dc.w mul
mul set mul+44
	endr

coplist
	dc.w color00,$000,color01,$fff,color02,$ccc,color03,$fff
	dc.w color04,$999,color05,$fff,color06,$ccc,color07,$fff
	dc.w color08,$666,color09,$fff,color10,$ccc,color11,$fff
	dc.w color12,$999,color13,$fff,color14,$ccc,color15,$fff
	dc.w bplcon0,$4200
	dc.w bplcon1,$0000
	dc.w bplcon2,$0000
	dc.w bpl1mod,$0000
	dc.w bpl2mod,$0000
	dc.w ddfstrt,$0030
	dc.w ddfstop,$00d8
	dc.w diwstrt,$2571
	dc.w diwstop,$35d1
	dc.l $fffffffe

screen1	dcb.b 44*272,$0
screen2	dcb.b 44*272,$0
screen3	dcb.b 44*272,$0
screen4	dcb.b 44*272,$0
screen5	dcb.b 44*272,$0
clear_buffer1	dcb.l NB_FUSE+1,$ffffffff
clear_buffer2	dcb.l NB_FUSE+1,$ffffffff
clear_buffer3	dcb.l NB_FUSE+1,$ffffffff
clear_buffer4	dcb.l NB_FUSE+1,$ffffffff
clear_buffer5	dcb.l NB_FUSE+1,$ffffffff

