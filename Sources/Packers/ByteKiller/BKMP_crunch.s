
; ByteKiller Mega Profesionnal crunch routine v1.4
; ©1993 Sync/Dreamdealers !!
; based on Lord Blitter's ByteKiller1.2
;
; initialize the following adresses:
;	start  : put there a pointer to the start of the data (LONG)
;	stop   : put there a pointer to the end of the data (LONG)
;	write  : put there a pointer where to write the crunched datas (LONG)
;	offset : put there an offset between $20 and $1000 (LONG)
;	then BSR or JSR to crunch the datas.
;	At the return, A0 gives you the start of the crunched datas
;		       A2 gives you the size of the crunched datas
;
;
; yeah !!! here is a little example !!!
;
;main
;		....
;	move.l #start_data,start
;	move.l #end_data,stop
;	move.l #$50000,write
;	move.l #$1000,offset
;	bsr crunch
;		....
;start_data
;	dcb.b 130,$f0
;end_data


crunch
	move.l start(pc),a0			adresse de départ
	move.l stop(pc),a1			adresse de fin
	move.l write(pc),a2			adresse oû l'on sauve
	addq.l #8,a2				reserve de la place
	lea data(pc),a6				pointe la zone de datas
	moveq #0,d1
	moveq #1,d2

noteocrunch
	bsr.s cruncher				va cruncher qqchose
	beq.s crunched				ca a marcher ??

	addq.w #1,d1
	beq.s nojmp
	cmp.w #264,d1
	bne.s nojmp
	bsr dojmp2

nojmp
crunched
	cmp.l a0,a1				yan a encore a cruncher ??
	bgt.s noteocrunch

	bsr dojmp
	bsr write1lwd	

	move.l write(pc),a0
	move.l stop(pc),d0
	sub.l start(pc),d0
	move.l d0,(a0)+				stocke la taille originale
	sub.l a0,a2				stocke la taille finale
	move.l a2,(a0)				en retour :  a0=write
	subq.l #4,a0					     a2=taille à sauver
	addq.l #4,a2
	rts

cruncher
	move.l a0,a3				adresse oû on est
	add.l offset(pc),a3			ajoute l'offset
	cmp.l a1,a3				on dépasse ?
	ble.s nottop				non => on continue
	move.l a1,a3				on dépasse pas la fin
nottop
	moveq #1,d5				taille du block ki s'répète:init
	lea 1(a0),a5				pointe juste après
contcrunch
	move.b (a0),d3				récupère un octet
	move.b 1(a0),d4				récupère le suivant

quickfind
	cmp.b (a5)+,d3				cherche une autre occurence de
	bne.s contfind				cet octet dans cette zone
	cmp.b (a5),d4				si c'est pareil => on saute
	beq.s lenfind
contfind
	cmp.l a5,a3				on est à la fin ?
	bgt.s quickfind				non => on continue
	bra.s endquickfind			oui => on sort de la recherche

lenfind
	subq.l #1,a5				on se place sur la répétition
	move.l a0,a4				on pointe les 2 mêmes octets
scan
	cmpm.b (a5)+,(a4)+			regarde jusqu'oû c'est égal
	bne.s endequ
	cmp.l a5,a3				on arrive à la fin ?
	bgt.s scan

endequ
	move.l a4,d3				pointeur actuel
	sub.l a0,d3				d3=taille de la zone égale
	subq.l #1,d3				corrige à cause du (An)+
	cmp.l d3,d5				c'est plus grand qu'avant ?
	bge.s nocrunch				non => on crunche pas

	move.l a5,d4				taille de la zone égale +
	sub.l a0,d4				un reste non égale
	sub.l d3,d4
	subq.l #1,d4	

	cmp.l #4,d3				taille égale <= 4 ?
	ble.s small				oui !!

	moveq #6,d6
	cmp.l #257,d3				on clippe d3 avec un max de 256
	blt.s cont1				d6=6 ( pointe le 4ème élément )
	move.w #256,d3
	bra.s cont1
small
	move.w d3,d6				\
	subq.w #2,d6				 > d6=offset pair
	add.w d6,d6				/
cont1
	cmp.w offst-data(a6,d6.w),d4
	bge.s nocrunch		
	move.l d3,d5				grandeur maximale pour l'instant
	move.l d4,maxsoffset-data(a6)		\ sauvegarde ces valeurs
	move.w d6,tbloffset-data(a6)		/
nocrunch
	cmp.l a5,a3				on est à la fin ?
	bgt.s contcrunch			non => on continue

endquickfind	
	cmp.l #1,d5				on a trouvé qq chose à packer ?
	beq.s nothingfound			bou.. non !!

	bsr.s dojmp				oui !! => on insère un saut
		
	move.w tbloffset(pc),d6
	move.l maxsoffset(pc),d3
	move.w lnoff-data(a6,d6.w),d0	
	bsr.s wd0bits		

	move.w length-data(a6,d6.w),d0	
	beq.s nolength		
	move.l d5,d3		
	subq.l #1,d3
	bsr.s wd0bits

nolength
	move.w cdlen-data(a6,d6.w),d0	
	move.w code-data(a6,d6.w),d3	
	bsr.s wd0bits		
	add.l d5,a0
	move.w a0,$dff180
	moveq #0,d0				ca a foiré !!
	rts

nothingfound
	move.b (a0)+,d3
	moveq #8,d0
	bsr.s wd0bits
	moveq #1,d0				ca a marché !!
	rts

dojmp
	tst.w d1
	beq.s skipjmp
dojmp2
	move.w d1,d3
	moveq #0,d1
	cmp.w #9,d3
	bge.s bigjmp
	subq.w #1,d3
	moveq #5,d0		
	bra.s wd0bits
skipjmp
	rts
bigjmp
	sub.w #9,d3
	or.w #%0000011100000000,d3	
	moveq #11,d0
wd0bits	
	subq.w #1,d0
copybits
	lsr.l #1,d3
	addx.l d2,d2
	bcs.s writelwd
	dbf d0,copybits
	rts
write1lwd
	moveq #0,d0
writelwd
	move.l d2,(a2)+	
	moveq #1,d2			
	dbf d0,copybits			
	rts

data
start		dc.l 0
stop		dc.l 0
write		dc.l 0
offset		dc.l 0
maxsoffset	dc.l 0
tbloffset	dc.w 0
offst		dc.w $0100,$0200,$0400,$1000
lnoff		dc.w $0008,$0009,$000a,$000c
length		dc.w $0000,$0000,$0000,$0008
cdlen		dc.w $0002,$0003,$0003,$0003
code		dc.w $0001,$0004,$0005,$0006

