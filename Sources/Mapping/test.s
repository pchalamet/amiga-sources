
*
*			test du Chunky To Planar
*			~~~~~~~~~~~~~~~~~~~~~~~~


BITMAP_X=320
BITMAP_HEIGHT=117
BITMAP_WIDTH=BITMAP_X/8
BITMAP_SIZE=BITMAP_WIDTH*BITMAP_HEIGHT
SCREEN_DEPTH=8
SCREEN_SIZE=BITMAP_WIDTH*BITMAP_HEIGHT*SCREEN_DEPTH




	incdir "asm:Sources"
	incdir "asm:.s/Mapping"
	include "registers.i"


	OPT DEBUG
	OPT O+


	section toto,code

Entry_Point
	KILL_SYSTEM Main
	moveq #0,d0
	rts



Main
	lea custom_base,a6

	bsr Init_Coplist

	move.l #coplist,cop1lc(a6)
	clr.w copjmp1(a6)
	move.w #$83c0,dmacon(a6)
	

	lea Chunky,a0
	lea Bitmap,a1
	bsr _ChunkyToPlanar

	WAIT_LMB_DOWN
	RESTORE_SYSTEM




Init_Coplist
	move.l #Bitmap,d1
	moveq #SCREEN_DEPTH-1,d0
	lea bpl,a0
.loop
	move.w d1,4(a0)
	swap d1
	move.w d1,(a0)
	swap d1
	add.l #BITMAP_SIZE,d1
	addq.l #8,a0
	dbf d0,.loop
	rts




	include "ChunkyToPlanar.s"




	section piccy,data_c

coplist
	dc.w fmode,$3
	dc.w diwstrt,$2b81
	dc.w diwstop,$2bc1
	dc.w ddfstrt,$38
	dc.w ddfstop,$a0
	dc.w bplcon0,$210
	dc.w bplcon1,0
	dc.w bplcon2,0
	dc.w bplcon3,0

	dc.w color00,$000
	dc.w color01,$f00
	dc.w color02,$0f0
	dc.w color03,$00f
	dc.w color04,$fff

b set bpl1ptH
bpl=*+2
	REPT SCREEN_DEPTH
	dc.w b,0
	dc.w b+2,0
b set b+4
	ENDR

;; dedoublement de l'écran avec les modulos
pos set $2b-1
	REPT BITMAP_HEIGHT
	dc.b pos&$ff,$df
	dc.w $fffe
	dc.w bpl1mod,-BITMAP_WIDTH
	dc.w bpl2mod,-BITMAP_WIDTH

	dc.b (pos+1)&$ff,$df
	dc.w $fffe
	dc.w bpl1mod,0
	dc.w bpl2mod,0

pos set pos+2
	ENDR

	dc.l $fffffffe



Chunky
	incbin "Texture_Easy.CHK"


	section toto,bss_c
	CNOP 0,8
Bitmap
	ds.b SCREEN_SIZE
