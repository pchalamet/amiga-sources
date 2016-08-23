
*			Huffman Depacker v1.0 © 1991 Sync/TSB France
*			--------------------------------------------

*--------------------> structure utilisé par l'arbre
ar_right	rs.l 1
ar_left		rs.l 1
ar_SIZEOF	rs.b 0


* a0=source  a1=destination  a2=Huffman buffer

Decrunch
	move.w (a0)+,d0				nbr de char packés-1

	move.l a2,a3				PtArbre
	moveq #0,d5
	move.l d5,(a3)
	move.l d5,ar_left(a3)
loop_build_tree
	move.l a2,a4				Racine
	move.b (a0)+,d6				le char normal

	moveq #0,d1
	move.b (a0)+,d1				taille du code en bits-1
	move.w d1,d3
	lsr.b #3,d3				taille du code en octets
loop_get_huffman_code
	lsl.l #8,d2
	move.b (a0)+,d2				recopie le code octet par octet
	dbf d3,loop_get_huffman_code

loop_build_for_code
	lsr.l #1,d2				sort un bit
	bcc.s process_left
process_right
	tst.l (a4)
	bne.s .already
	lea ar_SIZEOF(a3),a3
	move.l d5,(a3)
	move.l d5,ar_left(a3)
	move.l a3,(a4)
	move.l a3,a4
	dbf d1,loop_build_for_code
	move.b d6,ar_left(a4)
	dbf d0,loop_build_tree
	bra.s decompress
.already
	move.l (a4),a4
	dbf d1,loop_build_for_code
	move.b d6,ar_left(a4)
	dbf d0,loop_build_tree
	bra.s decompress

process_left
	tst.l ar_left(a4)
	bne.s .already
	lea ar_SIZEOF(a3),a3
	move.l d5,(a3)
	move.l d5,ar_left(a3)
	move.l a3,ar_left(a4)
	move.l a3,a4
	dbf d1,loop_build_for_code
	move.b d6,ar_left(a4)
	dbf d0,loop_build_tree
	bra.s decompress
.already
	move.l ar_left(a4),a4
	dbf d1,loop_build_for_code
	move.b d6,ar_left(a4)
	dbf d0,loop_build_tree

* a0=source  a1=destination  a2=Huffman buffer
decompress
	move.l a0,d0				pointe une adresse paire
	addq.l #1,d0
	moveq #-2,d2
	and.l d2,d0
	move.l d0,a0

	move.l (a0)+,d0				Taille du fichier dépacké
	moveq #16-1,d1				nb de bytes en tout
	move.w (a0)+,d2
	move.l a2,a3
loop_depack
	add.w d2,d2				sort un bit
	bcc.s Agauche
Adroite
	move.l (a3),a3
	tst.l (a3)
	beq.s Terminaison
	dbf d1,loop_depack
	moveq #16-1,d1
	move.w (a0)+,d2
	bra.s loop_depack
Agauche
	move.l ar_left(a3),a3
	tst.l (a3)
	beq.s Terminaison
	dbf d1,loop_depack
	moveq #16-1,d1
	move.w (a0)+,d2
	bra.s loop_depack
Terminaison
	move.b ar_left(a3),(a1)+
	move.l a2,a3
	move.w d0,$dff180
	subq.l #1,d0
	dbeq d1,loop_depack
	beq.s fin
	moveq #16-1,d1
	move.w (a0)+,d2
	bra.s loop_depack
fin
	rts

