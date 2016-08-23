
;
; communication ensérie pour faire des transferts
; RECEPTION
;


; taille du fichier à transferer en octets
FILE_SIZE=1


	incdir "asm:"
	incdir "asm:sources/"
	include "registers.i"

	OPT DEBUG
	

	section main,code
main
	KILL_SYSTEM Entry_Point
	moveq #0,d0
toto
	rts


Entry_Point
	lea _Custom,a6

	lea buffer,a0
	move.l #FILE_SIZE,d0


; init les registres série
	move.w #372,serper(a6)		9600 bauds + 8 bits de données
	move.w #$0801,intena(a6)
	move.w #$0801,intreq(a6)


loop_get_bytes
	move.w #$f00,color00(a6)
	btst #6,ciaapra			TEST SOURIS   DEBUG !!
	beq.s fin

	move.w serdatr(a6),d1		lit ce machin là
	btst #14,d1			on a recu l'octet ?
	beq.s loop_get_bytes

	move.w #$0f0,color00(a6)
	move.b d1,(a0)+			sauve l'octet recu dans le buffer

	subq.l #1,d0			et hop.. c'est lu !
get_bytes_start
	move.w #$0800,intreq(a6)	vide le tampon série
	tst.l d0			yen a encore ?
	bne.s loop_get_bytes

fin
	RESTORE_SYSTEM



	section buffer,bss
buffer
	ds.b FILE_SIZE
