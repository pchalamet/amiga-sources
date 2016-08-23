
; ByteKiller Mega Profesionnal v1.4
; ©1993 Sync/DreamDealers !!
; based on Lord Blitter's ByteKiller1.2

	opt O+,C+,P+

************************** Les includes du programme ***********************
	incdir "asm:include1.3/"
	include "exec/exec_lib.i"
	include "exec/memory.i"
	include "libraries/dos_lib.i"
	include "libraries/dos.i"
	include "intuition/intuition_lib.i"
	include "misc/Macros.i"

************************** Structures et constantes *************************
	rsreset
data_struct	rs.b 0
start		rs.l 1
stop		rs.l 1
write		rs.l 1
offset		rs.l 1
maxsoffset	rs.l 1
tbloffset	rs.w 1
offst		rs.w 4
lnoff		rs.w 4
length		rs.w 4
cdlen		rs.w 4
code		rs.w 4
_DosBase	rs.l 1
_IntuitionBase	rs.l 1
Code_Buffer	rs.l 1
StdIn		rs.l 1
StdOut		rs.l 1
FileIn		rs.l 1
FileOut		rs.l 1
File_Size	rs.l 1
Packed_Size	rs.l 1
Gain		rs.l 1
Gain_Percent	rs.w 1
Heures		rs.w 1
Minutes		rs.w 1
Secondes	rs.w 1
OutName		rs.b 300
Buffer		rs.b 300
data_SIZEOF	rs.b 0

ADDWORK=50

***************************  Le programme principal ************************
	section badaboum,code
main
	bra.s bingo
	dc.b "$VER: BKMP v1.4 ©1993 Sync/Dreamdealers",0
	even

bingo
	lea -data_SIZEOF(sp),sp			on se reserve de la place !!

	lea IntuitionName(pc),a1		ouvre la intuition.library
	moveq #0,d0				rien que pour utiliser
	move.l (_SysBase).w,a6			CurrentTime()  gasp...
	CALL OpenLibrary
	move.l d0,_IntuitionBase(sp)
	beq Error_Open_Intuition

	lea DosName(pc),a1			ouvre la dos.library
	moveq #0,d0
	CALL OpenLibrary
	move.l d0,_DosBase(sp)
	beq Error_Open_Dos

	move.l d0,a6
	CALL Input				recherche StdIn
	move.l d0,StdIn(sp)
	CALL Output
	move.l d0,StdOut(sp)			recherche StdOut

	move.l d0,d1				affiche la bannière
	lea Banner(pc),a0
	move.l a0,d2
	move.l #Banner_Size,d3
	CALL Write

****************************************************************************
**************************** Boucle principale *****************************
****************************************************************************

************************** Lecture du fichier IN ***************************
ReadIn
	clr.l write(sp)				reinit qq valeurs
	clr.l FileIn(sp)
	clr.l FileOut(sp)
	clr.l maxsoffset(sp)
	clr.w tbloffset(sp)

	lea restore_vars(pc),a0			restore les datas du cruncher
	lea offst(sp),a1
	moveq #2*5-1,d0
dup_data
	move.l (a0)+,(a1)+
	dbf d0,dup_data

ReadToto
	lea Buffer(sp),a2
	lea LoadFile(pc),a3
	bsr ReadKeyboard			va lire un nom de fichier

	move.l a2,d1				ouvre le fichier
	move.l #MODE_OLDFILE,d2
	CALL Open
	move.l d0,FileIn(sp)
	beq.s ReadToto

********************** Recherche la taille du fichier IN *******************
	move.l d0,d4
	move.l d4,d1				regarde si c'est un programme
	lea Code_Buffer(sp),a2
	move.l a2,d2
	moveq #4,d3
	CALL Read
	cmp.l d3,d0
	bne no_hunk_remove
	cmp.l #$3f3,(a2)
	bne no_hunk_remove
	
Find_end_hunk_name
	move.l d4,d1				saute le Hunk Name
	move.l a2,d2
	moveq #4,d3
	CALL Read
	cmp.l d3,d0
	bne.s no_hunk_remove
	tst.l (a2)
	bne.s Find_end_hunk_name
	
	move.l d4,d1				lit le nbr de hunks presents
	move.l a2,d2
	moveq #4,d3
	CALL Read
	cmp.l d3,d0
	bne.s no_hunk_remove
	
	move.l d4,d1				saute description des hunks
	move.l (a2),d2
	addq.l #2,d2
	lsl.l #2,d2
	moveq #OFFSET_CURRENT,d3
	CALL Seek
	
	move.l d4,d1				Hunk Code ?
	move.l a2,d2
	moveq #4,d3
	CALL Read
	cmp.l d3,d0
	bne.s no_hunk_remove
	cmp.w #$3e9,2(a2)
	bne.s no_hunk_remove

	move.l d4,d1
	move.l a2,d2
	moveq #4,d3
	CALL Read				lit la taille du Hunk_Code
	cmp.l d3,d0
	bne.s no_hunk_remove
	move.l (a2),d0				taille en longs mots
	add.l d0,d0				taille en octets
	add.l d0,d0
	move.l d0,File_Size(sp)

ReadAnswer
	lea Buffer(sp),a2
	lea Extract(pc),a3			demande si faut enlever le
	bsr ReadKeyboard			hunk code
	cmp.w #"y"<<8,(a2)
	beq.s ReadOut
	cmp.w #"Y"<<8,(a2)
	beq.s ReadOut
	cmp.w #"n"<<8,(a2)
	beq.s no_hunk_remove
	cmp.w #"N"<<8,(a2)
	bne.s ReadAnswer

no_hunk_remove
	move.l d4,d1				recherche la taille du fichier
	moveq #0,d2
	moveq #OFFSET_END,d3
	CALL Seek
	move.l d4,d1
	moveq #0,d2
	moveq #OFFSET_BEGINNING,d3
	CALL Seek
	move.l d0,File_Size(sp)

************************ Lecture du fichier de sortie ***********************
ReadOut
	lea OutName(sp),a2
	lea SaveFile(pc),a3
	bsr ReadKeyboard

	move.l a2,d1
	move.l #MODE_NEWFILE,d2
	CALL Open
	move.l d0,FileOut(sp)
	beq.s ReadOut

************************* Lecture d'un offset en hexa ***********************
ReadOffset
	lea Buffer(sp),a2
	lea Offset(pc),a3			lit l'offset
	bsr ReadKeyboard
	moveq #8-1,d0
	moveq #0,d1
get_offset
	move.b (a2)+,d2
	beq.s end_offset2

	lea MinConv(pc),a0			recherche dans la table
	moveq #16-1,d3				des majuscules
search1	cmp.b (a0)+,d2
	beq.s found
	dbf d3,search1

	moveq #16-1,d3				tables des minuscules
search2	cmp.b (a0)+,d2
	beq.s found
	dbf d3,search2
	bra.s ReadOffset
found
	lsl.l #4,d1				insere le quartet ds l'offset
	or.b d3,d1
	dbf d0,get_offset
end_offset
	tst.b (a2)				yan a d'autres derriere ?
	bne.s ReadOffset
end_offset2
	cmp.l #$20,d1				$20<=Offset<=$1000 ?
	blt.s ReadOffset
	cmp.l #$1000,d1
	bgt.s ReadOffset
	move.l d1,offset(sp)

***************************** Lecture du fichier ***************************
ReadFile
	move.l File_Size(sp),d0			essait d'allouer de la mémoire
	beq No_Memory				le fichier est vide ?
	add.l #ADDWORK,d0
	moveq #MEMF_PUBLIC,d1
	move.l (_SysBase).w,a6
	CALL AllocMem
	move.l d0,write(sp)
	beq No_Memory

	move.l FileIn(sp),d1			lit le fichier entierement
	move.l write(sp),d2
	add.l #ADDWORK,d2
	move.l File_Size(sp),d3
	move.l _DosBase(sp),a6
	CALL Read

****************************** Package du fichier **************************
PackFile
	lea Heures(sp),a0			heure de départ
	lea Buffer(sp),a1
	move.l _IntuitionBase(sp),a6
	CALL CurrentTime

	move.l write(sp),a0			init les datas du cruncher
	lea ADDWORK(a0),a0
	move.l a0,start(sp)
	add.l File_Size(sp),a0
	move.l a0,stop(sp)
	bsr cruncher
	move.l a2,Packed_Size(sp)		taille à sauver

	lea Gain(sp),a0
	lea Buffer(sp),a1
	move.l _IntuitionBase(sp),a6		heure de fin
	CALL CurrentTime

*************************** sauvegarde du fichier **************************
	move.l FileOut(sp),d1
	move.l write(sp),d2
	move.l Packed_Size(sp),d3
	move.l _DosBase(sp),a6
	CALL Write

	cmp.l d3,d0				erreur ds l'ecriture ?
	beq.s write_ok

	move.l write(sp),a1			libère la mémoire
	move.l File_Size(sp),d0
	add.l #ADDWORK,d0
	move.l (_SysBase).w,a6
	CALL FreeMem

	move.l FileOut(sp),d1			ferme les fichier IN et OUT
	move.l _DosBase(sp),a6
	CALL Close
	move.l FileIn(sp),d1
	CALL Close

	lea OutName(sp),a0			vire le fichier
	move.l a0,d1
	CALL DeleteFile

	move.l StdOut(sp),d1			affiche un message
	lea Error(pc),a0
	move.l a0,d2
	move.l #Error_Size,d3
	CALL Write
	bra ReadIn

write_ok
	move.l Gain(sp),d0			calcule l'heure
	sub.l Heures(sp),d0
	divu #60*60,d0
	move.w d0,Heures(sp)
	clr.w d0
	swap d0
	divu #60,d0
	move.w d0,Minutes(sp)
	swap d0
	move.w d0,Secondes(sp)

	move.l File_Size(sp),d0			calcul le gain
	sub.l Packed_Size(sp),d0
	move.l d0,Gain(sp)

	moveq #1,d1				calcule du gain en pourcent
	tst.l d0				prend la valeur absolue
	bge.s do_percent
	neg.l d0
	moveq #-1,d1
do_percent
	add.l d0,d0				4*Gain
	add.l d0,d0
	move.l d0,d2
	lsl.l #6-2,d2				64*Gain
	move.l d0,d3
	lsl.l #5-2,d3				32*Gain
	add.l d2,d0
	add.l d3,d0				100*Gain

	move.l File_Size(sp),d2
	moveq #0,d3

search_percent
	sub.l d2,d0
	blt.s end_percent
	add.w d1,d3
	bra.s search_percent
end_percent
	move.w d3,Gain_Percent(sp)

	lea Info(pc),a0				format tout ca avec exec
	lea File_Size(sp),a1
	lea putch(pc),a2
	lea Buffer(sp),a3
	move.l (_SysBase).w,a6
	CALL RawDoFmt

	lea 1(a3),a0
strlen	tst.b (a3)+
	bne.s strlen
	sub.l a0,a3

	move.l StdOut(sp),d1			affiche les resulats
	move.l a0,d2
	subq.l #1,d2
	move.l a3,d3
	move.l _DosBase(sp),a6
	CALL Write

	move.l write(sp),a1			libère la mémoire
	move.l File_Size(sp),d0
	add.l #ADDWORK,d0
	move.l (_SysBase).w,a6
	CALL FreeMem

No_Memory
	move.l FileOut(sp),d1			ferme le fichier de sortie
	move.l _DosBase(sp),a6
	CALL Close

	move.l FileIn(sp),d1			ferme le fichier d'entrée
	CALL Close
	bra ReadIn

******************** P'tite routine pour RawDoFmt d'exec *******************
putch
	move.b d0,(a3)+
	rts

******************* Routine pour lire un nom de fichier ********************
* a2=ptr sur buffer   a3=ptr sur texte
ReadKeyboard
	move.l StdOut+4(sp),d1
	move.l a3,d2
	move.l #LoadFile_Size,d3
	CALL Write				affiche "Enter FileName :"

	move.l StdIn+4(sp),d1
	move.l a2,d2
	move.l #300,d3
	CALL Read				lit le nom du fichier

	clr.b -1(a2,d0.l)			met un 0 à la fin

	cmp.w #"*"<<8,(a2)
	bne.s no_star

	bsr.s FreeAll				libère tout

	move.l StdOut+4(sp),d1
	lea Banner(pc),a0
	move.l a0,d2
	move.l #Banner_Size,d3
	CALL Write

	addq.l #4,sp				corrige la pile
	bra ReadIn

no_star
	cmp.b #"$",(a2)				commande "$" ?
	bne.s no_dollar

	move.l a2,d1				execute la commande
	addq.l #1,d1
	moveq #0,d2
	moveq #0,d3
	CALL Execute
	bra.s ReadKeyboard

no_dollar
	subq.l #5,d0				exit ?
	bne.s not_exit
	cmp.l #"exit",(a2)
	bne.s not_exit

*************************** Routine qui fait sortir ************************
Exit
	bsr.s FreeAll				libere tout

	move.l a6,a1
	move.l (_SysBase).w,a6
	CALL CloseLibrary			ferme la dos.library

Error_Open_Dos
	move.l _IntuitionBase+4(sp),a1		ferme la intuition.library
	CALL CloseLibrary

	lea data_SIZEOF+4(sp),sp		corrige la pile
	moveq #0,d0
not_exit
Error_Open_Intuition
	rts

************************* Routine qui libere tout *************************
FreeAll
	tst.l write+8(sp)			libère la mémoire car on
	beq.s no_mem				sait pas d'où on sort
	move.l write+8(sp),a1
	move.l File_Size(sp),d0
	add.l #ADDWORK,d0
	move.l (_SysBase).w,a6
	CALL FreeMem
no_mem
	move.l _DosBase+8(sp),a6		ferme le fichier OUT
	move.l FileOut+8(sp),d1
	beq.s no_out_file
	CALL Close
no_out_file
	move.l FileIn+8(sp),d1			ferme le fichier IN
	beq.s no_in_file
	CALL Close
no_in_file
	rts

********************************* Le cruncher ******************************

; ByteKiller Mega Profesionnal crunch routine v1.4
; ©1993 Sync/ThE SpeCiAl BrOthErS
; based on Lord Blitter's ByteKiller1.2

	opt O+,P+,C+

cruncher
	lea 4(sp),a6				pointe la zone de datas
	move.l start(a6),a0			adresse de départ
	move.l stop(a6),a1			adresse de fin
	move.l write(a6),a2			adresse oû l'on sauve
	addq.l #8,a2				reserve de la place
	moveq #0,d1
	moveq #1,d2

noteocrunch
	bsr.s crunch				va cruncher qqchose
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

	move.l write(a6),a0
	move.l stop(a6),d0
	sub.l start(a6),d0
	move.l d0,(a0)+				stocke la taille originale
	sub.l a0,a2				stocke la taille finale
	move.l a2,(a0)				en retour :  a0=write
	subq.l #4,a0					     a2=taille à sauver
	addq.l #4,a2
	rts

crunch
	move.l a0,a3				adresse oû on est
	add.l offset(a6),a3			ajoute l'offset
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
	cmp.b (a5)+,(a4)+			regarde jusqu'oû c'est égal
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
	cmp.w offst(a6,d6.w),d4
	bge.s nocrunch		
	move.l d3,d5				grandeur maximale pour l'instant
	move.l d4,maxsoffset(a6)		\ sauvegarde ces valeurs
	move.w d6,tbloffset(a6)			/
nocrunch
	cmp.l a5,a3				on est à la fin ?
	bgt.s contcrunch			non => on continue

endquickfind	
	cmp.l #1,d5				on a trouvé qq chose à packer ?
	beq.s nothingfound			bou.. non !!

	bsr.s dojmp				oui !! => on insère un saut
		
	move.w tbloffset(a6),d6
	move.l maxsoffset(a6),d3
	move.w lnoff(a6,d6.w),d0	
	bsr.s wd0bits		

	move.w length(a6,d6.w),d0	
	beq.s nolength		
	move.l d5,d3		
	subq.l #1,d3
	bsr.s wd0bits

nolength
	move.w cdlen(a6,d6.w),d0	
	move.w code(a6,d6.w),d3	
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

restore_vars
	dc.w $0100,$0200,$0400,$1000
	dc.w $0008,$0009,$000a,$000c
	dc.w $0000,$0000,$0000,$0008
	dc.w $0002,$0003,$0003,$0003
	dc.w $0001,$0004,$0005,$0006

*************************** Les datas du programme *************************
DosName
	dc.b "dos.library",0
IntuitionName
	dc.b "intuition.library",0
Banner
	dc.b 10,$9b,"0;33;40m"
	dc.b " »» ByteKiller Mega Professionnal :-) v1.4  ©1993 Sync/DRD ««",10
	dc.b $9b,"0;31;40m"
	dc.b " Based on Lord Blitter's ByteKiller v1.2 crunch & decrunch routines",10
	dc.b 10," Type: 'exit' to leave BKMP",10
	dc.b "       '$<command>' to execute a CLI command",10
	dc.b "       '*' to restart",10
Banner_Size=*-Banner
Info
	dc.b $9b,"0;33;40m"
	dc.b " »» Pack Informations ««",10
	dc.b $9b,"0;31;40m"
	dc.b " Original File Size...%ld",10
	dc.b " Packed File Size.....%ld",10
	dc.b " Gain.................%ld(%d%%)",10
	dc.b " Pack Time............%02d:%02d:%02d",10,10
	dc.b " Type: 'exit' to leave BKMP",10
	dc.b "       '$<command>' to execute a CLI command",10
	dc.b "       '*' to restart",10,0
Info_Size=*-Info
LoadFile
	dc.b " Load File............"
LoadFile_Size=*-LoadFile
Extract
	dc.b " Extract Hunk (y/n)..."
SaveFile
	dc.b " Save File............"
Offset
	dc.b " Crunch Offset........"
Error
	dc.b $9b,"0;33;40m"
	dc.b " Write Error. Aborting!",10,10
	dc.b $9b,"0;31;40m"
	dc.b " Type: 'exit' to leave BKMP",10
	dc.b "       '$<command>' to execute a CLI command",10
	dc.b "       '*' to restart",10
Error_Size=*-Error
MajConv
	dc.b "FEDCBA9876543210",0
MinConv
	dc.b "fedcba9876543210",0

