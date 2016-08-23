
*				Byte Run 0 Packer
*				~~~~~~~~~~~~~~~~~



* Routine de package
* ~~~~~~~~~~~~~~~~~~
*  -->	a0=Source
*	a1=End_Source
*	a2=Destination
*	d0=Screen Width in bytes
*	d1=Clipart Width in bytes
* <--	Destination filed with packed data
*	a0-a3/d0-d1 trashed
Packer
	addq.l #4,a2				taille des datas packés
	move.w d1,(a2)+				sauve Clipart Width
	sub.w d1,d0
	move.w d0,(a2)+				sauve Modulo
	move.l a2,a3
	addq.l #1,a2
	move.b #$ff,(a3)
loop_pack
	cmp.l a0,a1				on arrive à la fin des datas ?
	beq.s exit_packer

* IL FAUT 2 REPETITIONS AU MINIMUM POUR PACKER
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.b (a0)+,d0				lit un octet et regarde si
	cmp.l a0,a1				il y est pas 2 autres fois
	beq.s no_more
	cmp.b (a0),d0
	beq.s get_replen
no_more
	move.b d0,(a2)+				non => sauve l'octet dans la
	addq.b #1,(a3)				destination et incremente le
	cmp.b #$ff,(a3)				nombre d'octets non packés
	bne.s loop_pack
	move.l a2,a3
	move.b #$7f,(a3)
	addq.l #1,a2
	bra.s loop_pack

get_replen
	moveq #0,d1				1-1=0 à cause du dbf
cmp_all
	cmp.l a0,a1				yen a d'autres ?
	beq.s end_cmp
	cmp.b (a0)+,d0				c'est le meme octet ?
	bne.s end_cmp				non => on sort
	addq.b #1,d1				oui => on les compte
	cmp.b #$7f,d1				yen a combien la ?
	bne.s cmp_all
end_cmp
	or.b #$80,d1				signal une repetition
	move.b d1,(a2)+
	move.b d0,(a2)+
	move.l a2,a3
	move.b #$ff,(a3)
	addq.l #1,a2
	bra.s loop_pack

exit_packer
	sub.l #Destination,a2			calcul la taille du fichier
	move.l a2,Destination			packé à cause du dbf
	rts


* Routine de decompactage
* ~~~~~~~~~~~~~~~~~~~~~~~
*  -->	a0=Source
*	a2=Destination
* <--	Destination filed with depacked datas
Depacker
	move.l a0,a3				recherche la fin du fichier
	add.l (a0)+,a3				packé
	movem.w (a0)+,d0-d1			d0=Clipart Width  d1=Modulo
	moveq #0,d2
loop_unpack
	cmp.l a0,a3
	beq.s exit_depacker

	moveq #0,d3
	move.b (a0)+,d3				lit octet de control
	blt.s packed_data
unpack
	move.b (a0)+,(a1)+			recopie l'octet qui viens
	addq.w #1,d2				et un en plus sur la ligne !
	cmp.w d0,d2				fin de la ligne ?
	beq.s unpacked_eol			oui => modulo
	dbf d3,unpack
	bra.s loop_unpack
unpacked_eol
	moveq #0,d2				va à la ligne suivante
	lea (a1,d1.w),a1
	dbf d3,unpack
	bra.s loop_unpack

packed_data
	and.w #$7f,d3				vire le bit de package
	move.b (a0)+,d4				octet à repeter
depack
	move.b d4,(a1)+
	addq.w #1,d2				et un en plus sur la ligne !
	cmp.w d0,d2				fin de la ligne ?
	beq.s packed_eol			oui => modulo
	dbf d3,depack
	bra.s loop_unpack
packed_eol
	moveq #0,d2				va à la ligne suivante
	lea (a1,d1.w),a1
	dbf d3,depack
	bra.s loop_unpack

exit_depacker
	rts


Source
	incbin "Live2:Cliparts/RAW/Fletch.RAW"
End_Source

Destination
	dcb.b 30*1024,0
