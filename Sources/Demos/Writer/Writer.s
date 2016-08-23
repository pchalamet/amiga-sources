
*
*		Writer pour la MegaDemo / TSB
*
*		Code................Sync
*		Gfx.................
*		Font................
*		Music...............
*

	incdir "asm:"
	incdir "asm:.s/Writer/"
	include "sources/registers.i"

	section yoyo,code_c

	bsr save_all
	
	lea data_base(pc),a5
	lea $dff000,a6
	move.w #$7fff,d0
	move.w d0,intena(a6)
	move.w d0,dmacon(a6)
	
	move.l #vbl,$6c.w
	move.l #coplist,cop1lc(a6)
	clr.w copjmp1(a6)

	move.l #work_screen,d0
	lea ptr_videos+2(pc),a0
	moveq #5-1,d1
loop_put_ptr
	move.w d0,(a0)
	swap d0
	move.w d0,4(a0)
	swap d0
	add.l #44,d0
	addq.l #8,a0
	dbf d1,loop_put_ptr

	bsr mt_init

	move.w #$87c0,dmacon(a6)
	move.w #$c020,intena(a6)

mickey
	btst #6,ciaapra
	bne.s mickey
	bsr mt_end
	bsr restore_all
	moveq #0,d0
	rts

	include "sources/save_all.s"
	include "sources/play100.s"

********************************************************************************
*************************                              *************************
*************************  L'INTERRUPTION DE NIVEAU 3  *************************
*************************                              *************************
********************************************************************************
vbl
	bsr mt_music
	btst #10,potgor(a6)
	beq.s right
	bsr writer
right
	move.w #$20,intreq(a6)
	rte

********************************************************************************
**********************************             *********************************
**********************************  LE WRITER  *********************************
**********************************             *********************************
********************************************************************************
writer
	move.w mask_number(pc),d0		regarde si on est en train
	bge next_mask				d'afficher une lettre

writer_read
	move.l texte_ptr(pc),a0			ptr sur le texte
	moveq #0,d0

read_more
	move.b (a0)+,d0				va chercher une lettre
	beq end_writer				si 0 c'est la fin
	cmp.w #" ",d0				filtre les espaces
	bne.s not_space
	add.w #15,PosX-data_base(a5)		met un espace
	bra.s read_more
not_space
	cmp.w #10,d0				et les retours de lignes
	bne.s good_letter
	move.w #100,PosX-data_base(a5)		revient au début de ligne
	add.w #34,PosY-data_base(a5)		et passe à la ligne suivante
	bra.s read_more

Lettre_Adr
	dc.l 0+charset,4+charset,8+charset,12+charset,16+charset,20+charset,24+charset,28+charset,32+charset,36+charset
	dc.l 6600+charset,6604+charset,6608+charset,6612+charset,6616+charset,6620+charset,6624+charset,6628+charset,6632+charset,6636+charset
	dc.l 13200+charset,13204+charset,13208+charset,13212+charset,13216+charset,13216+charset

good_letter
	move.l a0,texte_ptr-data_base(a5)	sauve le ptr de texte
	sub.b #"A",d0				A est la base de la table
	add.w d0,d0				table de LONG
	add.w d0,d0
	move.l Lettre_Adr(pc,d0.w),lettre_ptr-data_base(a5)	adr de la lettre
	moveq #-1,d0				1er mask

next_mask
	addq.w #1,d0				mask_suivant
	move.w d0,mask_number-data_base(a5)	sauve le # de mask actuel
	cmp.w #10,d0				on en est au dernier mask ?
	bne.s not_end_mask
	sub.w #11,mask_number-data_base(a5)	signal la fin des masks ( -1 )
	add.w #25,PosX-data_base(a5)		et passe à la lettre suivante
	bra writer_read

Mask_Adr
	dc.l mask0,Mask1,Mask2,Mask3,Mask4,Mask5,Mask6,Mask7,Mask8,Mask9

not_end_mask
	add.w d0,d0				table de LONG
	add.w d0,d0
	move.l Mask_Adr(pc,d0.w),bltbpt(a6)	B=adr du mask
	move.l lettre_ptr(pc),bltapt(a6)	A=adr lettre

	moveq #0,d0
	move.w PosX(pc),d0
	move.w d0,d1
	lsr.w #3,d0				met en octet  /8
	and.w #$f,d1				décalage à faire au blitter
	ror.w #4,d1				$x000
	move.w d1,bltcon1(a6)			décalage du mask ( B )
	or.w #$fea,d1
	move.w d1,bltcon0(a6)			D=(A&B)|C

	move.w PosY(pc),d1
	add.w d1,d1				table de LONG
	add.w d1,d1
	add.l Table_Mulu(pc,d1.w),d0		ptr=Y*44+X/8
	move.l d0,bltcpt(a6)			C=ecran
	move.l d0,bltdpt(a6)			D=ecran

	move.l #38<<16,bltcmod(a6)		C=38 / B=0	modulos
	move.l #(34<<16)+38,bltamod(a6)		A=34 / D=38

	moveq #-1,d0
	move.l d0,bltafwm(a6)			masques sur la source A

	move.w #(32*5)<<6+3,bltsize(a6)		lettre de 32x32x5
end_writer
	rts

data_base

Table_Mulu
a set 0
	rept 272
	dc.l a*44*5+work_screen
a set a+1
	endr

PosX		dc.w 100
PosY		dc.w 18
mask_number	dc.w -1
lettre_ptr	dc.l 0
texte_ptr	dc.l text

coplist
	dc.w ddfstrt,$0030			on se met en overscan
	dc.w ddfstop,$00d8			ecran de 352x272x32
	dc.w diwstrt,$2571			en entrelacée
	dc.w diwstop,$35d1
	dc.w bplcon0,$5200
	dc.w bplcon1,$0000
	dc.w bplcon2,$0000
	dc.w bpl1mod,44*4
	dc.w bpl2mod,44*4

screen_colors
	dc.w color00,$0000			la palette de couleurs
	dc.w color01,$0D97
	dc.w color02,$0FDB
	dc.w color03,$0FCA
	dc.w color04,$0FB9
	dc.w color05,$0EA8
	dc.w color06,$0FFF
	dc.w color07,$0C86
	dc.w color08,$0B75
	dc.w color09,$0400
	dc.w color10,$0FFF
	dc.w color11,$0854
	dc.w color12,$0632
	dc.w color13,$0621
	dc.w color14,$0510
	dc.w color15,$0FFF
	dc.w color16,$0FFF
	dc.w color17,$0EFF
	dc.w color18,$0DEF
	dc.w color19,$0CDE
	dc.w color20,$0ABC
	dc.w color21,$09AB
	dc.w color22,$089A
	dc.w color23,$0789
	dc.w color24,$0678
	dc.w color25,$0567
	dc.w color26,$0456
	dc.w color27,$0345
	dc.w color28,$0234
	dc.w color29,$0123
	dc.w color30,$0111
	dc.w color31,$0FFF

ptr_videos
	dc.w bpl1ptL,0,bpl1ptH,0		les pointeurs videos
	dc.w bpl2ptL,0,bpl2ptH,0
	dc.w bpl3ptL,0,bpl3ptH,0
	dc.w bpl4ptL,0,bpl4ptH,0
	dc.w bpl5ptL,0,bpl5ptH,0

	dc.l $fffffffe

charset		incbin "font32x32x32.RAW"

work_screen	incbin "logo_352x272x32.RAW"

Mask0		incbin "Mask0.RAW"
Mask1		incbin "Mask1.RAW"
Mask2		incbin "Mask2.RAW"
Mask3		incbin "Mask3.RAW"
Mask4		incbin "Mask4.RAW"
Mask5		incbin "Mask5.RAW"
Mask6		incbin "Mask6.RAW"
Mask7		incbin "Mask7.RAW"
Mask8		incbin "Mask8.RAW"
Mask9		incbin "Mask9.RAW"

text
	dc.b "ABCDEFGHI",10
	dc.b " JKLMNOP ",10
	dc.b "     ",10
	dc.b " YOOUUPI",10
	dc.b "CA MARCHE",10
	dc.b "YEEAAHHH",10
	dc.b " BYE BYE  ",0

	even

mt_data
	incbin "dh0:music/modules/mod.lovecraft"

