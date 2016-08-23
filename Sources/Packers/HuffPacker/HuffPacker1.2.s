
	opt O+,OW-,C+			Optimize On, Warning Off, Case Dependent

*		HuffPack 1.2	by 1992 Sync/TSB
*		-------------------------------------->

*--------------------> les includes
	incdir "asm:include1.3/"
	include "exec/exec_lib.i"
	include "exec/exec.i"
	include "libraries/dos_lib.i"
	include "libraries/dos.i"
	include "misc/macros.i"

*--------------------> structure utilisée pour les troncs de la foret
	rsreset
tr_frequency	rs.l 1
tr_node		rs.l 1
tr_next		rs.l 1
tr_SIZEOF	rs.b 0

*--------------------> structure utilisée par les branches
	rsreset
br_char		rs.b 1
br_size		rs.b 1
br_code		rs.l 1
br_node		rs.l 1
br_SIZEOF	rs.b 0

*--------------------> quelques constantes
AddWork equ 8*1024
MAXSIZEARGV=60
MAXARGC=3

*--------------------> programme principale
*--------------------> on commence par les allocations et vérification
*--------------------> du fichier
__main
	lea data_base(pc),a5			pointeur base de données
	movem.l d0/a0,-(sp)

*-------> ouverture de la dos.library
	lea DosName(pc),a1			on ouvre la dos.library
	moveq #0,d0
	move.l (_SysBase).w,a6
	CALL OpenLibrary
	move.l d0,_DosBase-data_base(a5)	sauve le ptr
	beq Dos_Error				c'est bon ?
	move.l d0,a6

*-------> canal de sortie standart
	CALL Output				recherche la sortie standart
	move.l d0,_StdOut-data_base(a5)

	move.l d0,d1				écrit la bannière
	move.l #Banner_Msg,d2
	move.l #Banner_Size,d3
	CALL Write

*-------> parsing de la ligne cli
	movem.l (sp)+,d0/a0			arguments du cli
	bsr line_parsing			parse la ligne
	lea Argv_Buffer,a0			regarde sya -r ou -R
	cmp.b #"-",(a0)
	bne.s open_input_file
	cmp.b #"r",1(a0)
	beq.s set_remove
	cmp.b #"R",1(a0)
	bne.s open_input_file
set_remove
	tst.b 2(a0)
	bne.s open_input_file
	subq.w #1,hunk_flag-data_base(a5)
	lea MAXSIZEARGV(a0),a0

*-------> ouverture du fichier
open_input_file
	lea MAXSIZEARGV(a0),a1
	move.l a1,Out_Name-data_base(a5)
	move.l a0,d1				essait d'obtenir un handle
	move.l #MODE_OLDFILE,d2			sur le fichier d'entrée
	move.l _DosBase(pc),a6
	CALL Open
	move.l d0,d4
	beq Open_Error

*-------> vire le hunk_code si nécessaire
	tst.w hunk_flag-data_base(a5)
	bne.s remove_hunk_code

	move.l d4,d1				cherche la taille du fichier
	moveq #0,d2
	moveq #OFFSET_END,d3
	CALL Seek

	move.l d4,d1				revient au début
	moveq #0,d2
	moveq #OFFSET_BEGINNING,d3
	CALL Seek
	bra do_AllocMem

remove_hunk_code
	move.l d4,d1				lit 4 octets
	move.l #Code_Buffer,d2
	moveq #4,d3
	CALL Read
	cmp.l #$3f3,Code_Buffer-data_base(a5)	executable ?
	bne Read_Error
	
Find_end_hunk_name
	move.l d4,d1
	move.l #Code_Buffer,d2
	moveq #4,d3
	CALL Read				saute Hunk_Name
	tst.l Code_Buffer-data_base(a5)
	bne.s Find_end_hunk_name
	
	move.l d4,d1
	move.l #Code_Buffer,d2
	moveq #4,d3
	CALL Read
	
	move.l d4,d1				saute description des hunks
	move.l Code_Buffer(pc),d2
	addq.l #2,d2
	add.l d2,d2
	add.l d2,d2
	moveq #OFFSET_CURRENT,d3
	CALL Seek
	
	move.l d4,d1
	move.l #Code_Buffer,d2			lit 4 octets
	moveq #4,d3
	CALL Read
	cmp.w #$3e9,Code_Buffer+2-data_base(a5)	Hunk_Code ?
	bne Read_Error

	move.l d4,d1
	move.l #Code_Buffer,d2
	moveq #4,d3
	CALL Read				lit la taille du Hunk_Code
	move.l Code_Buffer(pc),d0		taille en longs mots
	add.l d0,d0				taille en octets
	add.l d0,d0

*-------> allocation des espaces mémoires
do_AllocMem
	move.l d0,Input_Size-data_base(a5)	alloue de la mémoire
	beq Open_Error

	add.l #AddWork,d0			ajoute l'espace de travail
	move.l #MEMF_PUBLIC|MEMF_CLEAR,d1	lecture du fichier
	move.l (_SysBase).w,a6
	CALL AllocMem
	tst.l d0
	beq Input_Mem_Error
	add.l #AddWork,d0			pointe les datas du fichier
	move.l d0,Input_Adr-data_base(a5)

	move.l #256*tr_SIZEOF,d0		alloue de la mémoire pour
	move.l #MEMF_PUBLIC|MEMF_CLEAR,d1	la forêt
	CALL AllocMem
	move.l d0,Forest_Adr-data_base(a5)
	beq Forest_Mem_Error
	
	move.l #256*br_SIZEOF,d0		alloue de la mémoire pour
	move.l #MEMF_PUBLIC|MEMF_CLEAR,d1	les branches
	CALL AllocMem
	move.l d0,Branche_Adr-data_base(a5)
	beq Branche_Mem_Error

*-------> lecture du fichier
	move.l d4,d1				lit le fichier entier
	move.l Input_Adr(pc),d2
	move.l Input_Size(pc),d3
	move.l _DosBase(pc),a6
	CALL Read

	move.l d4,d1				ferme le fichier
	CALL Close

*--------------------> compte les fréquences d'apparition des caractères
	move.l Input_Adr(pc),a0
	lea Table_Frequence(pc),a1		compte toute les fréquences
	move.l Input_Size(pc),d0		dans le fichier
loop_count_frequence
	moveq #0,d1
	move.b (a0)+,d1				récupère le # de byte
	add.w d1,d1
	add.w d1,d1				table de LONG
	addq.l #1,0(a1,d1.w)			fréquence++
	subq.l #1,d0				boucle pour tout le fichier
	bne.s loop_count_frequence

*--------------------> init les structures forest et branches
	move.l Forest_Adr(pc),a0		a0 *Forest ; a1 *Table_Frequence
	move.l Branche_Adr(pc),a2		a2 *Branche
	moveq #0,d0
loop_init_structure
	move.l (a1)+,tr_frequency(a0)		met la fréquence
	move.l a2,tr_node(a0)			ptr sur branche
	lea tr_SIZEOF(a0),a0			tronc suivant
	move.l a0,-tr_SIZEOF+tr_next(a0)	ptr sur tronc suivant
	move.b d0,br_char(a2)			met # du byte
	lea br_SIZEOF(a2),a2			branche suivante
	addq.b #1,d0
	bne.s loop_init_structure		256 branches modulo #$ff
	clr.l -tr_SIZEOF+tr_next(a0)		fin de la liste chainée

*--------------------> on trie les troncs
*--------------------> on trie suivant le # de byte du plus petit au plus grand
Bubble_Sort
	move.l Forest_Adr(pc),a0		*Forest
	move.w #256-1-1,d1
loop_bubble_sort
	moveq #0,d0				le flag
	move.w d1,d2				nb de branches restante à trier
	move.l a0,a1				ptr sur tronc
loop_sort_all
	move.l tr_frequency(a1),d3		fréquence1
	lea tr_SIZEOF(a1),a1			
	cmp.l tr_frequency(a1),d3		fréquence2
	bgt.s swap

	dbf d2,loop_sort_all
	tst.b d0				si aucun changement => on sort
	beq.s Bubble_Sort_End
	subq.b #1,d1
	bne.s loop_bubble_sort			plus rien à trier ?
	bra.s Bubble_Sort_End

swap
	move.l -tr_SIZEOF+tr_node(a1),d4	sauvegarde
	move.l tr_frequency(a1),-tr_SIZEOF+tr_frequency(a1)
	move.l tr_node(a1),-tr_SIZEOF+tr_node(a1)
	movem.l d3/d4,tr_frequency(a1)
	
	moveq #-1,d0				signal un changement
	dbf d2,loop_sort_all
	subq.l #1,d1				il en reste à trier ?
	bne.s loop_bubble_sort

*--------------------> la forêt est triée : on cherche un tronc avec
*--------------------> une fréquence <> 0
Bubble_Sort_End
	move.l Forest_Adr(pc),a0
	move.l #256-1,d0
loop_find_ne_freq
	tst.l tr_frequency(a0)
	bne.s Start_Forest_Found
	lea tr_SIZEOF(a0),a0
	dbf d0,loop_find_ne_freq
Start_Forest_Found
	move.l Input_Adr(pc),a1
	move.w d0,-AddWork(a1)			nb de code en tout
	lsl.l #3+1,d0				calcule la taille de Huffman
	addq.l #8,d0				Buffer
	move.l d0,Buffer_Size-data_base(a5)

*--------------------> commence à construire l'arbre d'Huffman
*--------------------> il est déja trié, on add les 2 premiers pointeurs
*--------------------> a0=Start_Forest
loop_build_arbre
	tst.l tr_next(a0)			regarde si on en a au moins 2
	beq build_arbre_end

	move.l tr_node(a0),d0			récupère la branche
	beq.s next_process
process_right
	move.l d0,a1
	addq.b #1,br_size(a1)
	lsl.w br_code+2(a1)			lsl.l #1,br_code(a1)
	roxl.w br_code(a1)
	addq.b #1,br_code+3(a1)			insère un bit 1
	move.l br_node(a1),d0			noeud suivant
	bne.s process_right

next_process
	move.l tr_next(a0),a1			tronc suivant
	move.l tr_node(a1),a1			récupère la branche
	move.l br_node(a1),d0			le noeud suivant existe ?
	beq.s process_end
process_left
	addq.b #1,br_size(a1)
	lsl.w br_code+2(a1)			lsl.l #1,br_code(a1)
	roxl.w br_code(a1)
	move.l d0,a1				noeud suivant
	move.l br_node(a1),d0			le noeud suivant existe ?
	bne.s process_left

process_end
	addq.b #1,br_size(a1)
	lsl.w br_code+2(a1)			lsl.l #1,br_code(a1)
	roxl.w br_code(a1)
	move.l tr_node(a0),br_node(a1)		insère à la suite les noeuds
	move.l tr_next(a0),a1
	move.l tr_frequency(a0),d0
	add.l d0,tr_frequency(a1)		ajoute les fréquences
	move.l a1,a0				tronc suivant ( StartForet )

selection_sort
	move.l tr_next(a0),d0			il reste encore des troncs ?
	beq.s build_arbre_end			non ! --> on sort
	move.l d0,a1
	move.l tr_frequency(a1),d0		frequency < frequency_next ?
	cmp.l tr_frequency(a0),d0
	bge.s loop_build_arbre

	move.l a1,a2				sauve le ptr sur tr_next(a0)
loop_selection
	move.l tr_next(a2),d0
	beq.s selection_end
	move.l d0,a3
	move.l tr_frequency(a3),d0
	cmp.l tr_frequency(a0),d0		frequency < frequency_next_next?
	bgt.s selection_end
	move.l a3,a2				tronc suivant
	bra.s loop_selection

selection_end
	move.l tr_next(a2),tr_next(a0)		insère le premier élément
	move.l a0,tr_next(a2)
	move.l a1,a0				tronc suivant
	bra loop_build_arbre			et on continue
	
*--------------------> à partir d'ici, l'arbre est trié
*--------------------> on le sauve d'abord
*--------------------> a0=start_foret
build_arbre_end
	move.l Input_Adr(pc),a1
	lea -AddWork+2(a1),a1			on se place juste après nb_code

	move.l tr_node(a0),d0
loop_save_tree
	move.l d0,a0
	move.b br_char(a0),(a1)+		sauve le # de byte
	moveq #0,d0
	move.b br_size(a0),d0
	subq.b #1,d0
	move.b d0,(a1)+				sauve la taille du code
	move.l br_code(a0),d1			récupère le code Huffman
	lsr.b #3,d0				divise par 8 (taille en octets)
	beq.s size_0
	subq.b #1,d0				taille 1 ?
	beq.s size_1
	subq.b #1,d0				taille 2 ?
	beq.s size_2
size_3
	move.l d1,d2
	swap d2
	lsr.w #8,d2
	move.b d2,(a1)+
size_2
	swap d1
	move.b d1,(a1)+
	swap d1
size_1
	move.w d1,d2
	lsr.w #8,d2
	move.b d2,(a1)+
size_0
	move.b d1,(a1)+				recopie byte à byte le code

	move.l br_node(a0),d0			noeud suivant
	bne.s loop_save_tree	

*--------------------> l'arbre est sauvé, il ne reste plus qu'a transmuter
*--------------------> le fichier
*--------------------> a1=destination
save_tree_end
	move.l Input_Adr(pc),a0			source
	move.l a1,d1				met le long sur une adresse
	addq.l #1,d1				paire si possible
	moveq #-2,d2				insère un EVEN s'il le faut
	and.l d2,d1
	move.l d1,a1 				* sur adresse paire
	move.l Branche_Adr(pc),a2		arbre
	lea Table_Mulu(pc),a3			table d'offset pour l'arbre
	move.l Input_Size(pc),d0

*--------------------> les choses sérieuses commencent ici...
*--------------------> a0=source
*--------------------> a1=destination
*--------------------> a2=arbre d'Huffman
*--------------------> a3=table d'offset pour l'arbre d'Huffman
*--------------------> d0=taille du fichier-1
	move.l Input_Size(pc),(a1)+		sauve la taille du fichier	
	moveq #1,d1				# de byte
next_code
	moveq #0,d2
	moveq #0,d3
	move.b (a0)+,d2				récupère un octet
	add.w d2,d2				table de mot
	move.w 0(a3,d2.w),d2			va chercher l'offset
	move.l br_code(a2,d2.w),d4		le code Huffman du byte
	move.b br_size(a2,d2.w),d3		la taille du code Huffman
	subq.b #1,d3				à cause du dbf
code_all
	lsr.l #1,d4				fait sortir un bit faible
	addx.w d5,d5				insère le bit dans out_byte
	add.w d1,d1				out_byte plein ?
	bne.s not_full
	moveq #1,d1				# de byte
	move.w d5,(a1)+				met out_byte
not_full
	dbf d3,code_all

	move.w d0,$dff1a2			fait clignoter : c'est Noel !!

	subq.l #1,d0
	bne.s next_code
	
	cmp.w #1,d1				on sort si out_byte a été écrit
	beq.s exit_code
zero_fill
	add.w d5,d5				<<1 out_byte
	add.w d1,d1				<<1 # de byte
	bne.s zero_fill
	move.w d5,(a1)+
exit_code

*--------------------> à partir d'ici, le fichier est codé, on le sauve
*--------------------> sur le disque
*--------------------> a1=end_destination	
	sub.l Input_Adr(pc),a1
	add.l #AddWork,a1
	move.l a1,a3				taille du fichier de sortie

	move.l Out_Name(pc),d1
	move.l #MODE_NEWFILE,d2
	CALL Open
	move.l d0,d7
	beq Save_Error

	move.l d7,d1				écrit le fichier
	move.l Input_Adr(pc),d2
	sub.l #AddWork,d2
	move.l a3,d3
	CALL Write

	move.l d7,d1				recherche la taille du fichier
	moveq #0,d2				de sortie
	moveq #OFFSET_END,d3
	CALL Seek
	move.l d0,Output_Size-data_base(a5)

	sub.l Input_Size(pc),d0			calcule du gain
	neg.l d0
	move.l d0,Gain-data_base(a5)

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

	move.l Input_Size(pc),d2
	moveq #0,d3

search_percent
	sub.l d2,d0
	blt.s end_percent
	add.w d1,d3
	bra.s search_percent
end_percent
	move.w d3,Gain_Percent-data_base(a5)

	move.l d7,d1				ferme le fichier
	CALL Close	

	lea Info_Msg(pc),a0			transmutte la partie info
	lea Input_Size(pc),a1
	lea Putch(pc),a2
	move.l Input_Adr(pc),a3
	lea -AddWork(a3),a3
	move.l (_SysBase).w,a6
	CALL RawDoFmt

	move.l _StdOut(pc),d1			affiche la partie info
	move.l a3,d2
search_size
	tst.b (a3)+
	bne.s search_size
	sub.l d2,a3
	move.l a3,d3
	subq.l #1,d3
	move.l _DosBase(pc),a6
	CALL Write	

	move.l Branche_Adr(pc),a1		libère la mémoire des branches
	move.l #256*br_SIZEOF,d0
	move.l (_SysBase).w,a6
	CALL FreeMem
	move.l Forest_Adr(pc),a1		libère la mémoire des troncs
	move.l #256*tr_SIZEOF,d0
	CALL FreeMem
	move.l Input_Adr(pc),a1			libère la mémoire du fichier
	move.l #AddWork,d0
	sub.l d0,a1
	add.l Input_Size(pc),d0
	CALL FreeMem

	move.l _DosBase(pc),a1			ferme la dos.library
	CALL CloseLibrary
	moveq #0,d0
	rts

Putch
	move.b d0,(a3)+
	rts

*-----------------------------> gestion des erreurs
Save_Error
	move.l Branche_Adr(pc),a1		libère la mémoire des branches
	move.l #256*br_SIZEOF,d0
	move.l (_SysBase).w,a6
	CALL FreeMem

Branche_Mem_Error
	move.l Forest_Adr(pc),a1		libère la mémoire des troncs
	move.l #256*tr_SIZEOF,d0
	CALL FreeMem

Forest_Mem_Error
	move.l Input_Adr(pc),a1			libère la mémoire du fichier
	move.l #AddWork,d0
	sub.l d0,a1
	add.l Input_Size(pc),d0
	CALL FreeMem
	bra.s Input_Mem_Error

Read_Error
	move.l d4,d1
	CALL Close

Cli_Error
Usage_Error
Open_Error
	move.l _StdOut(pc),d1			affiche l'usage
	move.l #Usage_Msg,d2
	move.l #Usage_Size,d3
	move.l _DosBase(pc),a6
	CALL Write

Input_Mem_Error
	move.l _StdOut(pc),d1			signal une erreur
	move.l #Error_Msg,d2
	move.l #Error_Size,d3
	move.l _DosBase(pc),a6
	CALL Write

	move.l _DosBase(pc),a1			ferme la dos.library
	move.l (_SysBase).w,a6
	CALL CloseLibrary
Dos_Error
	moveq #0,d0
	rts

*  en entrée :	a0/d0 initialisés par le Dos  ;  a0=&CliLine  ; d0=Size
*  en sortie :	d0=nb d'arguments-1
*  d0-d2/a0-a2 trashed !!
line_parsing
	clr.b -1(a0,d0.w)			met un bo zero à la fin

	moveq #0,d0				Argc
	lea Argv_Buffer,a1
	bra.s search_end_space
loop_parse_line
	clr.b (a2)
	addq.w #1,d0				incrémente argc
	lea MAXSIZEARGV(a1),a1			passe au buffer suivant
	cmp.w #MAXARGC,d0
	beq.s end_of_parsing
search_end_space
	cmp.b #" ",(a0)+			saute tous les espaces
	beq.s search_end_space
	move.l a1,a2				pointeur sur le buffer
	move.w #MAXSIZEARGV-2,d2		taille maximale d'un argument
	tst.b -1(a0)				fin de la ligne ?
	beq.s end_of_parsing
	cmp.b #'"',-1(a0)			argument entre quotes ?
	beq.s quoted_arg	

	subq.l #1,a0				revient un peu en arriere
non_quoted_arg
	move.b (a0)+,d1
	beq.s end_non_quoted			fin de la ligne ?
	cmp.b #" ",d1				espace ?
	beq.s loop_parse_line
	move.b d1,(a2)+
	dbf d2,non_quoted_arg
end_non_quoted
	clr.b (a2)				met une zero en fin d'argument
	addq.w #1,d0				incrémente argc
end_of_parsing
	rts

quoted_arg
	move.b (a0)+,d1
	beq.s end_of_parsing			fin de la ligne ?
	cmp.b #'"',d1				fin de l'argument ?
	beq.s loop_parse_line
	move.b d1,(a2)+
	dbf d2,quoted_arg
	rts

data_base
_StdOut		dc.l 0				sortie std
_DosBase	dc.l 0				ptr base de la dos
Out_Name	dc.l 0				nom de sortie
Code_Buffer	dcb.b 4,0			buffer pour le dos
hunk_flag	dc.w 0				flag pour le programme

Input_Size	dc.l 0				variables pour les stats !
Output_Size	dc.l 0
Gain		dc.l 0
Gain_Percent	dc.w 0
Buffer_Size	dc.l 0

Input_Adr	dc.l 0				pointeurs sur les zones de datas
Forest_Adr	dc.l 0
Branche_Adr	dc.l 0

Table_Frequence	dcb.l 256,0
Table_Mulu
val set 0
	rept 256
	dc.w val*br_SIZEOF
val set val+1
	endr

DosName		dc.b "dos.library",0

Banner_Msg	dc.b 10,9,$9b,"0;33;40mHuffPacker v1.2 © 1993 by  >> Sync of ThE SpeCiAl BrOthErS <<",10,10
		dc.b $9b,"0;31;40mPlease, wait while packing..."
Banner_Size=*-Banner_Msg

Info_Msg	dc.b 10,10,9,9,"File succefully packed !!",10
		dc.b 9,9,"Unpacked Size..........%ld",10
		dc.b 9,9,"Packed Size............%ld",10
		dc.b 9,9,"Gain...................%ld(%d%%)",10
		dc.b 9,9,"Huffman Buffer Size....%ld",10,10,0
Info_Size=*-Info_Msg

Usage_Msg	dc.b 10,10,"Usage: HuffPacker [-R] <InFile> <OutFile>",10
		dc.b "See the doc for more info",10
Usage_Size=*-Usage_Msg

Error_Msg	dc.b 10,$9b,"0;32;40mError !!!",10,10,$9b,"0;31;40m"
Error_Size=*-Error_Msg

	section binouze,bss
Argv_Buffer
	ds.b MAXSIZEARGV*3		espace pour le line parsing

