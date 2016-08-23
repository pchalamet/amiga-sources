
*		The Module Converter v3.9   ©1993 Sync/DRD
*		----------------------------------------------->
*			Last change : 2 Juin 1993


*-----------------------> description des differents codages

* les notes sont codées sur 3 bytes :	1 bit  pour le package des notes
*					5 bits pour le numero du sample
*					6 bits pour l'offset de la periode
*					4 bits pour la fonction
*					8 bits pour l'info de la fonction

* les instruments sont codés :		1 mot pour LEN
*					1 mot pour VOLUME
*					1 pointeur sur le REPEAT
*					1 mot pour REPLEN
*					1 pointeur sur le FINETUNE
*					LEN mots de datas du sample


*-----------------------> options de compilations
	opt C+
	opt O+

*-----------------------> les includes de Mr Commodore...
	incdir "hd1:include"
	include "exec/execbase.i"
	include "exec/exec_lib.i"
	include "libraries/dos_lib.i"
	include "libraries/dos.i"
	include "libraries/dosextens.i"
	include "libraries/reqbase.i"
	include "libraries/req_lib.i"
	include "misc/macros.i"

*-----------------------> une ch'tite macro
KEY	macro
	dc.b $9b,"0;32;40m",9,9,"  <Press a key>"
	dc.b $9b,"0;31;40m"
	endm

*-----------------------> structure d'un module SoundTracker
	rsreset
module_struct	rs.b 0
ms_SongName	rs.b 20
ms_SampName	rs.b 22
ms_SampSize	rs.w 1
ms_SampFine	rs.b 1
ms_SampVol	rs.b 1
ms_SampReapeat	rs.w 1
ms_SampRepLen	rs.w 1
ms_SampSIZEOF	EQU __RS-ms_SampName
ms_SampOthers	rs.b ms_SampSIZEOF*30
ms_Length	rs.b 1
ms_Restart	rs.b 1
ms_Positions	rs.b 128
ms_Mark		rs.b 4
ms_Patterns	rs.b 0

*-----------------------> structure pour l'allocation des Mark
	rsreset
Mark_struct	rs.b 0
ma_Next		rs.l 1
ma_Mark		rs.l 1
ma_SIZEOF	rs.b 0

*-----------------------> le programme principal
	bra.s skip_copyright
	dc.b "$VER: TMC v3.9 ©1993 Sync of DreamDealers",0
	even
skip_copyright
	move.l (_SysBase).w,a6			cherche notre propre tache
	move.l ThisTask(a6),a3

	tst.l pr_CLI(a3)			on démarre du CLI ?
	bne.s _main

fromWorkbench
	lea pr_MsgPort(a3),a0			attend le WB message
	move.l a0,a3
	CALL WaitPort
	move.l a3,a0
	CALL GetMsg				va chercher le WB message
	move.l d0,-(sp)
	bsr.s _main	
	move.l (_SysBase).w,a6
	CALL Forbid
	move.l (sp)+,a1
	CALL ReplyMsg				retourne le WB message
	moveq #0,d0
	rts

_main	
	lea data_base(pc),a5			NE DOIT JAMAIS ETRE MODIFIE !!

	lea ReqName(pc),a1
	moveq #0,d0
	move.l (_SysBase).w,a6
	CALL OpenLibrary
	move.l d0,_ReqBase-data_base(a5)
	beq no_req

	lea DosName(pc),a1			ouverture de la dos.library
	moveq #0,d0
	CALL OpenLibrary
	move.l d0,_DosBase-data_base(a5)
	beq no_dos

	move.l #WindowName,d1			ouverture d'une fenetre de type
	move.l #MODE_OLDFILE,d2			RAW:
	move.l d0,a6
	CALL Open
	move.l d0,WindowHandle-data_base(a5)
	beq no_window

	bsr Load_Prefs				va lire les preferences

	move.l (_SysBase).w,a6			vire les requesters
	move.l ThisTask(a6),a6
	move.l pr_WindowPtr(a6),save_WindowPtr-data_base(a5)
	moveq #-1,d0
	move.l d0,pr_WindowPtr(a6)

MenuHandler
	move.l WindowHandle(pc),d1		affiche le menu
	move.l #MenuStr,d2
	move.l #MenuSize,d3
	move.l _DosBase(pc),a6
	CALL Write

WaitKey
	bsr ReadKey

	move.b KeyBuffer(pc),d0			gère l'appuie des touches
	cmp.b #"c",d0
	beq.s ConvertModule
	cmp.b #"C",d0
	beq.s ConvertModule
	cmp.b #"d",d0
	beq Change_Dir
	cmp.b #"D",d0
	beq Change_Dir
	cmp.b #"o",d0
	beq SampleOpt_Change
	cmp.b #"O",d0
	beq SampleOpt_Change
	cmp.b #"s",d0
	beq SplitOpt_Change
	cmp.b #"S",d0
	beq SplitOpt_Change
	cmp.b #"a",d0
	beq DisplayAbout
	cmp.b #"A",d0
	beq DisplayAbout
	cmp.b #"q",d0
	beq Quit
	cmp.b #"Q",d0
	beq Quit
	bra.s WaitKey

*-----------------------> routine pour convertir un module
ConvertModule
	move.l sp,save_SP-data_base(a5)		sauve le pointeur de pile

	bsr select_module
	bsr init_var
	bsr convert_patterns
	bsr match_notes
	bsr order_patterns
	bsr order_positions
	bsr order_samples
	bsr modify_datas
	bsr pack_patterns
	bsr save_module
	bsr display_stats

*----------------------> gestion de toutes les erreurs
No_Error
	bra.s ExitConvert
Error_Lock
	move.l #LockStr,d2
	moveq #LockSize,d3
	bra.s ExitConvert
Error_Examine
	move.l #ExamineStr,d2
	moveq #ExamineSize,d3
	bra.s ExitConvert
Error_Directory
	move.l #DirectoryStr,d2
	moveq #DirectorySize,d3
	bra.s ExitConvert
Error_Mem
	move.l #MemStr,d2
	moveq #MemSize,d3
	bra.s ExitConvert
Error_Open
	move.l #OpenStr,d2
	moveq #OpenSize,d3
	bra.s ExitConvert
Error_Read
	move.l #ReadStr,d2
	moveq #ReadSize,d3
	bra.s ExitConvert
Error_Mark
	move.l #MarkStr,d2
	moveq #MarkSize,d3
	bra.s ExitConvert
Error_Write
	move.l #WriteStr,d2
	moveq #WriteSize,d3
ExitConvert
	move.l WindowHandle(pc),d1
	lea data_base(pc),a5
	move.l _DosBase(pc),a6
	CALL Write

.toto1	move.l InputLock(pc),d1			libère le lock sur le fichier
	beq.s .toto2				source
	CALL UnLock
	clr.l InputLock-data_base(a5)

.toto2	move.l ModuleHandle(pc),d1		ferme le fichier source
	beq.s .toto3
	CALL Close
	clr.l ModuleHandle-data_base(a5)

.toto3	move.l SongHandle(pc),d1		ferme le fichier Song.s
	beq.s .toto4
	CALL Close
	clr.l SongHandle-data_base(a5)

.toto4	move.l PatternHandle(pc),d1		ferme le fichier Patterns.dat
	beq.s .toto5
	CALL Close
	clr.l PatternHandle-data_base(a5)

.toto5	move.l SampleHandle(pc),d1		ferme le fichier Sample##.dat
	beq.s .toto6
	CALL Close
	clr.l SampleHandle-data_base(a5)

.toto6	move.l Module_Adr(pc),d1		libère la mémoire allouée
	beq.s .toto7				pour le module
	move.l d1,a1
	move.l TMC_Fib+fib_Size(pc),d0
	move.l (_SysBase).w,a6
	CALL FreeMem
	clr.l Module_Adr-data_base(a5)

.toto7	move.l WindowHandle(pc),d1		attend l'appuie d'une touche
	move.l #PressKey,d2
	move.l #PressKeySize,d3
	move.l _DosBase(pc),a6
	CALL Write
	bsr ReadKey

	move.l save_SP(pc),sp			restore la pile...
	bra MenuHandler	

*-----------------------> lecture d'un module
select_module
	move.l WindowHandle(pc),d1		affiche "select.."
	move.l #StartMsg,d2
	move.l #StartSize,d3
	CALL Write

	lea ReqFileStruct(pc),a0		fait choisir un fichier
	move.l #ReqSelect,frq_Title(a0)		avec l'aide d'un requester
	move.l #ReadPath,frq_Dir(a0)
	clr.l frq_Flags(a0)
	move.l _ReqBase(pc),a6			avec l'aide d'un requester
	CALL FileRequester
	tst.l d0
	bne.s UserSelected
	move.l #CancelStr,d2
	move.l #CancelSize,d3
	bra ExitConvert

UserSelected
	move.l #PathName,d1			essaie d'obtenir un lock
	moveq #ACCESS_READ,d2			sur le fichier
	move.l _DosBase(pc),a6
	CALL Lock
	move.l d0,InputLock-data_base(a5)
	beq Error_Lock

	move.l d0,d1				Examine le fichier
	move.l #TMC_Fib,d2
	CALL Examine
	tst.l d0
	beq Error_Examine

	tst.l TMC_Fib+fib_DirEntryType-data_base(a5)	c'est un dir ?
	bpl Error_Directory

	move.l InputLock(pc),d1			libère le lock sur le fichier
	CALL UnLock
	clr.l InputLock-data_base(a5)

	move.l TMC_Fib+fib_Size(pc),d0		alloue de la mémoire pour
	moveq #MEMF_PUBLIC,d1			charger le fichier
	move.l (_SysBase).w,a6
	CALL AllocMem
	move.l d0,Module_Adr-data_base(a5)
	beq Error_Mem

	move.l WindowHandle(pc),d1		affiche "read.."
	move.l #ReadMsg,d2
	move.l #ReadMsgSize,d3
	move.l _DosBase(pc),a6
	CALL Write
	
	move.l #PathName,d1			ouvre le fichier en lecture
	move.l #MODE_OLDFILE,d2
	CALL Open
	move.l d0,ModuleHandle-data_base(a5)
	beq Error_Open

	move.l ModuleHandle(pc),d1		lit le fichier en entier
	move.l Module_Adr(pc),d2
	move.l TMC_Fib+fib_Size(pc),d3
	CALL Read
	cmp.l d0,d3
	bne Error_Read

	move.l ModuleHandle(pc),d1		referme le fichier
	CALL Close
	clr.l ModuleHandle-data_base(a5)

	move.l Module_Adr(pc),a0
	move.l ms_Mark(a0),d0
	cmp.l #"M.K.",d0			c'est un module ProTracker ?
	beq.s Snd_Module

	move.l Mark_Adr(pc),d1
check_others_marks
	beq Error_Mark
	move.l d1,a1
	cmp.l ma_Mark(a1),d0
	beq.s Snd_Module
	move.l ma_Next(a1),d1
	bra.s check_others_marks
Snd_Module
	rts

*-----------------------> recherche le nb de patterns kia ds le module
init_var
	move.l Module_Adr(pc),a0		cherche l'adresse des patterns
	lea ms_Patterns(a0),a1			et de la positions list
	move.l a1,Patterns_Adr-data_base(a5)
	lea ms_Positions(a0),a0
	move.l a0,Positions_Adr-data_base(a5)

	moveq #128-1,d0
	moveq #0,d1
loop_search_higest
	move.b (a0)+,d2
	cmp.b d1,d2
	ble.s not_higest
	move.b d2,d1
not_higest
	dbf d0,loop_search_higest
	move.w d1,Nb_Patterns-data_base(a5)	sauve le nb de patterns-1
	addq.w #1,d1
	mulu #1024,d1
	add.l Patterns_Adr(pc),d1		cherche l'adresse des samples
	move.l d1,Samples_Adr-data_base(a5)

	moveq #0,d0				effaces quelques datas
	move.w #(64+128+32+16)/4-1,d1
	lea busy_Patterns(pc),a0
clear	move.l d0,(a0)+
	dbf d1,clear

	move.l #4,Size_Module-data_base(a5)
	clr.b NotImp-data_base(a5)
	rts

*-----------------------> convertit les patterns au format TMC
convert_patterns
	move.l WindowHandle(pc),d1	signal la convertion des patterns
	move.l #ConvertMsg,d2
	move.l #ConvertSize,d3
	move.l _DosBase(pc),a6
	CALL Write

	move.w Nb_Patterns(pc),d0	Nb de patterns -1
	move.l Patterns_Adr(pc),a0
loop_convert_all
	move.w #64*4-1,d1		nb de notes à changer
	move.l a0,a1			a0=source  a1=destination

loop_convert_pattern
	moveq #0,d2
	move.b 2(a0),d2			cherche l'instrument
	lsr.w #4,d2
	move.b (a0),d3
	and.w #$f0,d3
	or.w d3,d2
	lsl.w #6,d2

	move.w (a0),d3
	and.w #$fff,d3			garde que la periode

	lea periodes_table(pc),a2	recherche l'offset de la periode dans
	moveq #0,d4			la table
	moveq #36-1,d5
loop_search_periode	
	cmp.w (a2)+,d3
	bge.s periode_found
	addq.w #1,d4
	dbf d5,loop_search_periode

periode_found
	or.w d4,d2			# du sample + offset periode
	lsl.w #4,d2

	move.b 2(a0),d3			insere la fonction
	and.w #$f,d3
	or.w d3,d2

	move.b d2,1(a1)			met # + offset periode + fonction
	lsr.w #8,d2			on le met en 2 temps car c'est pas
	move.b d2,(a1)			toujours WORD aligned
	move.b 3(a0),2(a1)		met l'info de la fonction

optimize_functions
	tst.b d3
	beq end_FX

*-----------> VIBRATO
	cmp.b #$4,d3			regarde ici pour les vibratos et
	beq.s its_vibrato		les tremolos
	cmp.b #$7,d3
	bne.s no_vibrato
its_vibrato
	move.b 2(a1),d2
	rol.b #4,d2
	move.b d2,2(a1)
	bra.s end_FX

no_vibrato
*-----------> TONEP + VOLSLIDE , VIBRATO + VOLSLIDE et VOLUME SLIDE
	cmp.b #$5,d3			on précalcule ici les volumes slides
	beq.s its_volume_slide
	cmp.b #$6,d3
	beq.s its_volume_slide
	cmp.b #$a,d3
	bne.s no_volume_slide
its_volume_slide
	move.b 2(a1),d2
	lsr.b #4,d2
	bne.s volume_up
volume_down
	move.b 2(a1),d2
	and.b #$f,d2
	neg.b d2
volume_up
	move.b d2,2(a1)
	bra.s end_FX

no_volume_slide
*-----------> POSITION JUMP
	cmp.b #$b,d3
	bne.s no_position_jump
	move.b 2(a1),d2
	add.b d2,d2			on gagne un ADD dans la replay...
	move.b d2,2(a1)
	bra.s end_FX

no_position_jump
*-----------> PATTERN BREAK
	cmp.b #$d,d3			convertit le pattern break du
	bne.s no_pattern_break		decimal à l'hexadecimal
	moveq #0,d2
	move.b 2(a1),d2
	move.w d2,d3
	and.b #$f0,d2
	lsr.w #4,d2
	mulu #10,d2
	and.b #$0f,d3
	add.b d3,d2
	add.b d2,d2			on gagne ADD dans la replay
	move.b d2,2(a1)
	bra.s end_FX

no_pattern_break
*-----------> SPEED
	cmp.b #$f,d3
	bne.s end_FX
	subq.b #1,2(a1)			enleve 1 à la vitesse
	bge.s end_FX
	clr.b 2(a1)
end_FX
	addq.l #4,a0			passe aux notes suivantes
	addq.l #3,a1
	dbf d1,loop_convert_pattern	

	moveq #0,d1			efface la fin du pattern pour pouvoir
	moveq #64-1,d2			l'utiliser comme zone de datas plus tard
clear_end_pattern
	move.l d1,(a1)+
	dbf d2,clear_end_pattern
	dbf d0,loop_convert_all
	rts

*-----------------------> regarde quelles sont les notes utilisées
match_notes
	move.l Module_Adr(pc),a0		regarde si le restart n'est pas
	move.b ms_Restart(a0),d0		supérieur à Length
	cmp.b ms_Length(a0),d0
	blt.s no_restart_reset
	clr.b ms_Restart(a0)			Ya du ProTracker ds l'air...

	move.l WindowHandle(pc),d1
	move.l #ResetMsg,d2
	move.l #ResetSize,d3
	CALL Write

no_restart_reset
	moveq #0,d0				pattpos
	move.w #768,d1				pattpos occupation patterns
	moveq #0,d2
	move.l Patterns_Adr(pc),a0		adresse des patterns
	move.l Positions_Adr(pc),a1		adresse des positions
	lea busy_Patterns(pc),a2
	lea busy_Positions(pc),a3
	lea busy_Samples(pc),a4

next_position
	moveq #0,d3
	move.b 0(a1,d2.w),d3			pattern actuel
	or.b #$ff,0(a2,d3.w)			pattern utilisé
	mulu #1024,d3
	lea 0(a0,d3.l),a5			pointeur sur le pattern actuel

scan_notes
	tst.b 0(a3,d2.w)			déja passé par cette position ?
	beq.s not_came_here
	tst.w 0(a5,d1.w)			notes déja jouées ?
	bne end_scan
not_came_here
	moveq #4-1,d3				on traite une ligne de notes
	moveq #0,d4				flag pour les breaks
	addq.w #1,0(a5,d1.w)			signal le passage sur ces notes
	lea 0(a5,d0.w),a6			pointe les 4 notes
play_4_notes
	moveq #0,d5				signale que ce sample
	move.b (a6),d5				est utlisé
	lsr.w #2,d5
	move.b #$ff,0(a4,d5.w)

	move.b 1(a6),d5				\ va chercher la fonction
	and.b #$0f,d5				/ de la note

	cmp.b #$b,d5				position jump ?
	bne.s not_position_jump

	moveq #0,d0				revient en haut du pattern
	move.w #768,d1
	moveq #0,d6				va checher la nouvelle position
	move.b 2(a6),d6
	lsr.w #1,d6				déja multiplié par 2 !!
	cmp.b ms_Length-ms_Patterns(a0),d6	fait un clipping sur le
	blt.s valid_pos_jump			position jump
	move.b ms_Restart-ms_Patterns(a0),d6
	move.b d6,2(a6)
	add.b d6,2(a6)				multiplie par 2
valid_pos_jump
	moveq #-5,d4				signale le position jump
	addq.l #3,a6				passe à la note suivante
	dbf d3,play_4_notes
	bra.s test_break

not_position_jump
	cmp.b #$d,d5				pattern break ?
	bne.s no_commands
	moveq #0,d0
	move.b 2(a6),d0
	move.w d0,d1
	add.w d1,d1				pointe des LONG
	add.w #768,d1
	mulu #(3*4)/2,d0			déja multiplié par 2 !!
	addq.w #1,d4				signale le pattern break
no_commands
	addq.l #3,a6				passe à la note suivante
	dbf d3,play_4_notes

test_break
	tst.w d4
	bmi.s do_position_jump			position jump ?
	bne.s do_pattern_break			pattern break ?

no_break
	add.w #4*3,d0				passe à la ligne suivante
	addq.w #4,d1
	cmp.w #768,d0				fin du pattern ?
	bne scan_notes
	move.w d0,d1				\ redemare au début d'un pattern
	moveq #0,d0				/
do_pattern_break
	move.b #$ff,0(a3,d2.w)			signale le passage sur cette pos
	addq.w #1,d2				position suivante
	cmp.b ms_Length-ms_Patterns(a0),d2
	blt.s set_branch
	move.b ms_Restart-ms_Patterns(a0),d2
	bra.s set_branch

do_position_jump
	or.b #$ff,0(a3,d2.w)			signal le passage sur cette pos
	move.w d6,d2

set_branch
	moveq #0,d3
	move.b 0(a1,d2.w),d3			pattern actuel
	or.b #$ff,0(a2,d3.w)			pattern utilisé
	mulu #1024,d3
	lea 0(a0,d3.l),a5			pointeur sur le pattern actuel
	move.w #$ffff,2(a5,d1.w)		signale un branchement sur ces
	bra scan_notes				notes
	
end_scan
	rts

*-----------------------> rearangement des patterns
order_patterns
	lea busy_Patterns(pc),a0
	moveq #1,d0				le 0 signal pas de pattern
	moveq #64-1,d1
loop_order_pattern
	tst.b (a0)+
	beq.s no_pattern
	move.b d0,-1(a0)
	addq.b #1,d0
no_pattern
	dbf d1,loop_order_pattern
	rts

*-----------------------> rearangement des positions
order_positions
	lea data_base(pc),a5
	lea busy_Positions(pc),a0		reorganise la position list
	move.l Positions_Adr(pc),a1		en lecture
	move.l a1,a2				en écriture
	lea busy_Patterns(pc),a3
	moveq #128-1,d0
	moveq #0,d1
	moveq #0,d2
loop_change_positionlist
	tst.b (a0)+				position utilisée ?
	beq.s skip_position
	move.b d2,-1(a0)			reassigne la position
	addq.b #1,d2
	move.b (a1),d1				ancien # de pattern
	move.b 0(a3,d1.w),d1
	subq.b #1,d1
	move.b d1,(a2)+				-> nouveau # de pattern
skip_position
	addq.l #1,a1
	dbf d0,loop_change_positionlist

	subq.w #1,d2				calcul le nb de positions final
	move.w d2,Nb_Positions-data_base(a5)
	rts

*-----------------------> rearangement des samples + recherche des finetunes
order_samples
	lea busy_Samples(pc),a0
	clr.b (a0)+				vire le sample 0

	tst.b sample_opt-data_base(a5)		remet tous les samples
	beq.s optimize_sample
	moveq #31-1,d0
	move.l a0,a1
enable_samples
	move.b #$ff,(a1)+
	dbf d0,enable_samples

optimize_sample
	move.l Module_Adr(pc),a1
	lea ms_SampFine(a1),a1			pointe les Finetunes
	lea busy_Finetunes(pc),a2
	moveq #1,d0
	moveq #31-1,d1
	moveq #0,d2
loop_order_sample
	tst.b (a0)+
	beq.s no_used_sample
	move.b d0,-1(a0)
	addq.b #1,d0
	move.b (a1),d2				signale que ce finetune est
	or.b #$ff,0(a2,d2.w)			utilisé
no_used_sample
	lea ms_SampSIZEOF(a1),a1
	dbf d1,loop_order_sample
	rts

*-----------------------> changement des position jump & samples
modify_datas
	move.l Patterns_Adr(pc),a0
	lea busy_Patterns(pc),a1
	lea busy_Positions(pc),a2
	lea busy_Samples(pc),a3
	move.w Nb_Patterns(pc),d0
loop_modify
	tst.b (a1)+				patterns utilisé ?
	beq no_modify

	move.l a0,a4
	lea 768(a0),a5
	moveq #64-1,d1				64 lignes à modifier
	moveq #0,d2
change_pattern
	moveq #4-1,d4				4 notes sur une ligne
	addq.w #1,d2
	tst.w (a5)				notes utilisées ?
	beq.s change_line
	move.w d2,d3				taille du pattern
change_line
	move.b (a4),d5				change le # du sample
	lsr.b #2,d5
	and.w #$3f,d5
	move.b 0(a3,d5.w),d5
	add.w d5,d5
	add.w d5,d5
	and.b #$3,(a4)
	or.b d5,(a4)

	move.b 1(a4),d5				va chercher la fonction
	and.w #$f,d5

	cmp.b #$8,d5				regarde si la function est
	beq.s set_notimp			implementée
	cmp.b #$e,d5
	bne.s imp_function
	move.b 2(a4),d6
	and.w #$f0,d6
	cmp.w #$30,d6
	beq.s set_notimp
	cmp.w #$40,d6
	beq.s set_notimp
	cmp.w #$50,d6
	beq.s set_notimp
	cmp.w #$70,d6
	beq.s set_notimp
	cmp.w #$80,d6
	beq.s set_notimp
	cmp.w #$f0,d6
	bne.s imp_function
set_notimp
	move.b #$ff,NotImp
	move.w d0,ImpPattern
	move.w d1,ImpPosition
	move.w d4,ImpVoice
imp_function
	cmp.b #$b,d5				position jump ?
	bne.s not_posjmp_function
	move.b 2(a4),d5
	lsr.b #1,d5
	move.b 0(a2,d5.w),d5
	add.b d5,d5
	move.b d5,2(a4)				met la nouvelle position

not_posjmp_function
	addq.l #3,a4				note suivante
	dbf d4,change_line
	addq.l #4,a5				table de LONG
	dbf d1,change_pattern

no_modify
	lea 1024(a0),a0				pattern suivant
	dbf d0,loop_modify

	tst.b NotImp
	beq.s no_Warning_Msg
	move.l WindowHandle(pc),d1		signale l'utilisation
	move.l #WarningMsg,d2			de commande non supportées
	move.l #WarningMsgSize,d3
	move.l _DosBase(pc),a6
	CALL Write
no_Warning_Msg
	rts

*-----------------------> package des blank notes
pack_patterns
	move.l WindowHandle(pc),d1		signale kon pack les patterns
	move.l #PackMsg,d2
	move.l #PackSize,d3
	move.l _DosBase(pc),a6
	CALL Write

	move.l Patterns_Adr(pc),a0
	lea busy_Patterns(pc),a1
	moveq #64-1,d0
loop_pack_patterns
	tst.b (a1)+
	beq no_pack

	lea 768(a0),a2				recherche le nb de ligne
	moveq #64-1,d1				du pattern
	moveq #0,d2
	moveq #0,d3
search_max_patt_line
	tst.w (a2)
	beq.s not_busy_line
	move.w d2,d3
not_busy_line
	addq.w #1,d2
	addq.l #4,a2
	dbf d1,search_max_patt_line

	moveq #2,d1				taille actuelle du pattern
	move.w d3,d2
	add.w d2,d2
	add.w d2,d2				pointe des LONG
	add.w #768+2,d2
	lea 0(a0,d2.w),a2
	moveq #1-1,d2
search_branch
	tst.w (a2)
	bne.s branch_found
	addq.w #1,d2				incrémente le nb de ligne
	subq.l #4,a2
	dbf d3,search_branch

branch_found
	mulu #3*4,d3				ajoute la taille des notes
	add.w d3,d1				précédentes
	lea 0(a0,d3.w),a2			pointe les notes à packer
	lea 768(a0),a3				pointe la fin du pattern
loop_search_blank_notes
	moveq #4-1,d3				4 notes par ligne
loop_search_blank_repeat
	move.l a2,a4				recherche le nb de blank note
	moveq #0,d4				à la suite
search_repeat
	cmp.b #$02,(a4)+			regarde si c'est la note
	bne.s end_blank				$024000
	cmp.b #$40,(a4)+
	bne.s end_blank
	tst.b (a4)+
	bne.s end_blank
	addq.w #1,d4
	cmp.w d3,d4
	ble.s search_repeat
end_blank
	move.w d4,d5
	beq.s no_blank_note
	add.w d5,d5				\ mulu #3,d4
	add.w d4,d5				/
	lea 0(a2,d5.w),a4			pointe les note suivante(SOURCE)
	subq.w #1,d4				à cause du dbf dans la replay !!
	sub.w d4,d3				enleve le nb de blank notes
	or.b #$80,d4				met le bit de package
	move.b d4,(a2)+
	move.l a2,a5				pointe DESTINATION
kill_blank_notes
	move.b (a4)+,(a5)+			déplace tout le reste du
	cmp.l a3,a4				pattern
	bmi.s kill_blank_notes
	addq.w #1,d1				taille des patterns packées
	dbf d3,loop_search_blank_repeat
	dbf d2,loop_search_blank_notes
	bra.s move_the_pattern

no_blank_note
	addq.w #3,d1				pas de package de la note
	addq.l #3,a2
	dbf d3,loop_search_blank_repeat
	dbf d2,loop_search_blank_notes

move_the_pattern
	lea 768(a0),a2				déplace le pattern
	lea 2(a2),a3				de 1 mot à droite
	move.w #768/4-1,d2
move_pattern
	move.l -(a2),-(a3)
	dbf d2,move_pattern
	move.w d1,(a2)				sauve la taille du pattern
no_pack
	lea 1024(a0),a0				pattern suivant
	dbf d0,loop_pack_patterns
	rts

*-----------------------> sauvegarde du module au format TMC
save_module
	move.l WindowHandle(pc),d1		signale kon sauve tout
	move.l #SaveMsg,d2
	move.l #SaveSize,d3
	lea data_base(pc),a5
	move.l _DosBase(pc),a6
	CALL Write

	move.l #DOS_SongName,d1			ouvre le fichier "Song.s"
	move.l #MODE_NEWFILE,d2
	CALL Open
	move.l d0,SongHandle-data_base(a5)
	beq Error_Open

*----------> ecrit la bannière
	lea FileName(pc),a0			écrit le nom du fichier
	lea NamePatch(pc),a1
	moveq #30-1,d0
put_FileName
	move.b (a0)+,d1
	beq.s end_put_FileName
	move.b d1,(a1)+
	dbf d0,put_FileName
	bra.s action1
end_put_FileName
	move.b #" ",(a1)+
	dbf d0,end_put_FileName

action1
	move.l Module_Adr(pc),a0		écrit le nom de la zik
	lea SongPatch(pc),a1
	moveq #20-1,d0
put_SongName
	move.b (a0)+,d1
	beq.s end_put_SongName
	move.b d1,(a1)+
	dbf d0,put_SongName
	bra.s action2
end_put_SongName
	move.b #" ",(a1)+
	dbf d0,end_put_SongName

action2
	move.l Module_Adr(pc),a0
	moveq #2-1,d0				écrit le restart
	move.b ms_Restart(a0),d1
	lea RestartPatch(pc),a0
	bsr write_hex

	move.l SongHandle(pc),d1		écrit la banniere
	move.l #Banner,d2
	move.l #BannerSize,d3
	CALL Write
	cmp.l d0,d3
	bne Error_Write

*----------> ecrit si besoin le warning
	tst.b NotImp-data_base(a5)
	beq.s no_warning

	moveq #2-1,d0				ecrit le # du pattern
	move.w ImpPattern(pc),d1
	sub.w Nb_Patterns(pc),d1
	neg.w d1
	lea Warning_patch1(pc),a0
	bsr write_hex

	moveq #2-1,d0				ecrit le # de la position
	moveq #64-1,d1
	sub.w ImpPosition(pc),d1
	lea Warning_patch2(pc),a0
	bsr write_hex

	moveq #1-1,d0				ecrit le # de la voix
	moveq #4-1,d1
	sub.w ImpVoice(pc),d1
	lea Warning_patch3(pc),a0
	bsr write_hex

	move.l SongHandle(pc),d1		ecrit le warning
	move.l #WarningImp,d2
	move.l #WarningImpSize,d3
	CALL Write
	cmp.l d0,d3
	bne Error_Write

no_warning
	move.l SongHandle(pc),d1		ecrit le restart
	move.l #Restart,d2
	move.l #RestartSize,d3
	CALL Write
	cmp.l d0,d3
	bne Error_Write

*---------> écrit les adresses des samples
	moveq #31-1,d7
	lea busy_Samples+1(pc),a3
loop_save_sample_list
	tst.b (a3)+
	beq.s no_sample_list

	moveq #2-1,d0				écrit le # de l'instrument
	move.b -1(a3),d1
	lea SamplePatch(pc),a0
	bsr write_hex

	move.l SongHandle(pc),d1
	move.l #SampleLine,d2
	move.l #SampleLineSize,d3
	CALL Write
	cmp.l d0,d3
	bne Error_Write
	addq.l #4,Size_Module-data_base(a5)
no_sample_list
	dbf d7,loop_save_sample_list

	move.l SongHandle(pc),d1		écrit le label "mt_pos"
	move.l #PosLabel,d2
	move.l #PosLabelSize,d3
	CALL Write
	cmp.l d0,d3
	bne Error_Write

*---------> sauvegarde des patterns
	move.l #DOS_PattName,d1
	move.l #MODE_NEWFILE,d2
	CALL Open
	move.l d0,PatternHandle-data_base(a5)
	beq Error_Open

	lea busy_Patterns(pc),a3
	move.l Patterns_Adr(pc),a4
	lea Patterns_Offset(pc),a5
	move.w Nb_Patterns(pc),d4
	moveq #0,d5
	moveq #0,d6
loop_save_patterns
	tst.b (a3)+				le pattern existe ?
	beq.s no_save_pattern

	move.l d5,(a5,d6.w)			sauve l'offset du pattern
	addq.l #4,d6

	move.l PatternHandle(pc),d1
	move.l a4,d2
	moveq #0,d3
	move.w (a4),d3
	addq.w #1,d3				\ pour avoir une adresse paire
	and.w #$fffe,d3				/
	add.l d3,d5				ajoute la taille à l'offset
	CALL Write
	cmp.l d0,d3
	bne Error_Write
no_save_pattern
	lea 1024(a4),a4
	dbf d4,loop_save_patterns

	move.l PatternHandle(pc),d1		ferme le fichier
	CALL Close
	lea data_base(pc),a5
	clr.l PatternHandle-data_base(a5)
	add.l d5,Size_Module-data_base(a5)	ajoute la taille des patterns
	
*---------> écrit les positions
	move.l Positions_Adr(pc),a3
	lea Patterns_Offset(pc),a4
	move.w Nb_Positions(pc),d7		longueur du pattern_list
loop_write_position
	moveq #4-1,d0				écrit l'offset pour atteindre
	moveq #0,d1				le pattern
	move.b (a3)+,d1
	add.w d1,d1
	add.w d1,d1
	move.l 0(a4,d1.w),d1
	lea PosLinePatch(pc),a0
	bsr write_hex

	move.l SongHandle(pc),d1
	move.l #PosLine,d2
	move.l #PosLineSize,d3
	CALL Write
	cmp.l d0,d3
	bne Error_Write

	addq.l #4,Size_Module-data_base(a5)
	dbf d7,loop_write_position

	move.l SongHandle(pc),d1		écrit le label "mt_pos_end"
	move.l #PosEnd,d2			+ incbin patterns.dat
	move.l #PosEndSize,d3
	CALL Write
	cmp.l d0,d3
	bne Error_Write

*----------> écrit les finetunes utilisé
	lea busy_Finetunes(pc),a3
	lea FineTune_Msg(pc),a4			pointe les tables de FineTunes
	moveq #16-1,d6
	moveq #0,d7
loop_save_FineTune
	tst.b (a3)+
	beq.s no_FineTune

	move.l SongHandle(pc),d1		écrit le FineTune
	move.w d7,d5
	move.l #FineTune_Msg_Size,d3
	mulu.w d3,d5
	add.l a4,d5
	move.l d5,d2
	CALL Write
	cmp.l d0,d3
	bne Error_Write
	add.l #37*2,Size_Module-data_base(a5)
no_FineTune
	addq.w #1,d7
	dbf d6,loop_save_FineTune

*-------------> sauvegarde des samples
	tst.b split_opt-data_base(a5)		regarde si on split les
	bne.s do_not_split			fichier

	move.l SongHandle(pc),d1		referme le fichier "Song.s"
	CALL Close

	move.l #DOS_SampleName,d1		ouvre le fichier "Samples.s"
	move.l #MODE_NEWFILE,d2
	CALL Open
	move.l d0,SongHandle-data_base(a5)
	beq Error_Open

	move.l d0,d1				écrit la bannière
	move.l #Banner,d2
	move.l #BannerSize-2,d3			vire les 2 chr(10)...
	CALL Write

do_not_split
	move.l SongHandle(pc),d1		écrit le warning
	move.l #Warning,d2
	move.l #WarningSize,d3
	CALL Write
	cmp.l d0,d3
	bne Error_Write

	move.l Module_Adr(pc),a3
	lea ms_SampName(a3),a3			pointe le 1er instrument
	move.l Samples_Adr(pc),a4		pointe data 1er sample
	lea busy_Samples+1(pc),a5
	moveq #31-1,d7
loop_save_sample
	tst.b (a5)+
	beq no_sample

	moveq #2-1,d0				écrit le # de l'instrument
	move.b -1(a5),d1
	lea DOS_SampPatch(pc),a0
	bsr write_hex
	move.b DOS_SampPatch-2(pc),Sample_patch1-2
	move.b DOS_SampPatch-1(pc),Sample_patch1-1
	move.b DOS_SampPatch-2(pc),Sample_patch7-2
	move.b DOS_SampPatch-1(pc),Sample_patch7-1

	moveq #1-1,d0				écrit le FineTune
	move.b 22+2(a3),d1
	lea Sample_patch6(pc),a0
	bsr write_hex

	moveq #2-1,d0				écrit le volume
	move.b 22+3(a3),d1
	lea Sample_patch3(pc),a0
	bsr write_hex

	moveq #4-1,d0				écrit le repeat
	move.w 22+2+2(a3),d1
	lea Sample_patch4(pc),a0
	bsr write_hex

	moveq #4-1,d0				écrit le replen
	move.w 22+2+2+2(a3),d1
	lea Sample_patch5(pc),a0
	bsr write_hex

	moveq #4-1,d0				écrit la longueur de départ
	moveq #0,d3
	move.w 22+2+2(a3),d1
	beq.s write_all_sample
	add.w 22+2+2+2(a3),d1
	bra.s write_patch2
write_all_sample
	move.w 22(a3),d1
write_patch2
	move.w d1,d3				sauve la longueur du sample
	lea Sample_patch2(pc),a0
	bsr write_hex
	
	move.l #DOS_SampName,d1
	move.l #MODE_NEWFILE,d2
	CALL Open
	move.l d0,SampleHandle
	beq Error_Open

	move.l d0,d1				sauve les datas du sample
	move.l a4,d2
	add.l d3,d3				d3 déja initialisé
	bne.s not_empty_sample
	move.l #Empty_Sample,d2
	moveq #2,d3
not_empty_sample
	add.l d3,Size_Module
	add.l #14,Size_Module
	CALL Write
	cmp.l d0,d3
	bne Error_Write

	move.l SampleHandle(pc),d1
	CALL Close
	clr.l SampleHandle

	move.l SongHandle(pc),d1		écrit la structure du sample
	move.l #Sample_Msg,d2
	move.l #Sample_Size,d3
	CALL Write
	cmp.l d0,d3
	bne Error_Write

no_sample
	moveq #0,d0				passe au datas du sample suivant
	move.w 22(a3),d0
	add.l d0,d0
	add.l d0,a4
	lea ms_SampSIZEOF(a3),a3		passe au sample suivant
	dbf d7,loop_save_sample	

*----------> referme le fichier "Song.s"
	lea data_base(pc),a5
	move.l SongHandle(pc),d1
	CALL Close
	clr.l SongHandle-data_base(a5)
	rts

*-----------------------------> les statistiques sur la conversion
display_stats
	lea data_base(pc),a5
	move.l TMC_Fib+fib_Size(pc),d3
	sub.l Size_Module(pc),d3
	move.l d3,Gain-data_base(a5)
	move.l d3,d0

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

	move.l Size_Module(pc),d2
	add.l Gain(pc),d2
	moveq #0,d3

search_percent
	sub.l d2,d0
	blt.s end_percent
	add.w d1,d3
	bra.s search_percent
end_percent
	move.w d3,Gain_Percent-data_base(a5)

	lea SuccessStr(pc),a0			met la taille du module en
	lea Size_Module(pc),a1			ASCII
	lea Putch(pc),a2
	lea Size_Buffer(pc),a3
	move.l (_SysBase).w,a6
	CALL RawDoFmt

	lea 1(a3),a0
.strlen	tst.b (a3)+				affiche les resultats
	bne.s .strlen
	sub.l a0,a3
	move.l a3,d3
	move.l #Size_Buffer,d2
	rts

*-----------------------> routine pour changer de path
Change_Dir
	lea ReqFileStruct(pc),a0		ouvre un dir requester
	move.l #ReqDir,frq_Title(a0)
	move.l #WritePath,frq_Dir(a0)
	move.l #FRQDIRONLYM,frq_Flags(a0)
	move.l _ReqBase(pc),a6
	CALL FileRequester
	move.l _DosBase(pc),a6
	tst.l d0
	beq WaitKey
	move.l #WritePath,d1
	moveq #ACCESS_READ,d2
	CALL Lock
	move.l d0,d1
	beq WaitKey
	CALL CurrentDir
	move.l d0,d1
	CALL UnLock
	bra WaitKey

*-----------------------> changement du status de l'optimisation sample
SampleOpt_Change
	eor.b #$ff,sample_opt-data_base(a5)
	beq.s samp_on
	move.b #"f",Menu_patch1-data_base(a5)
	move.b #"f",Menu_patch1+1-data_base(a5)
	bra MenuHandler
samp_on
	move.b #"n",Menu_patch1-data_base(a5)
	move.b #" ",Menu_patch1+1-data_base(a5)
	bra MenuHandler

*-----------------------> changement du status du splitage
SplitOpt_Change
	eor.b #$ff,split_opt-data_base(a5)
	beq.s split_on
	move.b #"f",Menu_patch2-data_base(a5)
	move.b #"f",Menu_patch2+1-data_base(a5)
	bra MenuHandler
split_on
	move.b #"n",Menu_patch2-data_base(a5)
	move.b #" ",Menu_patch2+1-data_base(a5)
	bra MenuHandler

*-----------------------> routine pour afficher le about
DisplayAbout
	move.l WindowHandle(pc),d1
	move.l #AboutStr,d2
	move.l #AboutSize,d3
	CALL Write
	bsr ReadKey
	bra MenuHandler

*-----------------------> routine pour sortir de TMC
Quit
	move.l (_SysBase).w,a6			remet les requesters
	move.l ThisTask(a6),a6
	move.l save_WindowPtr(pc),pr_WindowPtr(a6)

	bsr Free_Mark

	move.l CLI_Dir(pc),d1			libère le Lock sur le path write
	move.l _DosBase(pc),a6
	CALL CurrentDir
	move.l d0,d1
	CALL UnLock

	move.l WindowHandle(pc),d1		ferme la fenetre
	CALL Close
no_window
	move.l _DosBase(pc),a1			ferme la dos.library
	move.l (_SysBase).w,a6
	CALL CloseLibrary
no_dos
	move.l _ReqBase(pc),a1			ferme la req.library
	CALL CloseLibrary
no_req
	moveq #0,d0
	rts

*-----------------------> chargement du fichier de preferences
Load_Prefs
	move.l #DOS_Prefs,d1			ouvre le fichier de preferences
	move.l #MODE_OLDFILE,d2
	CALL Open
	move.l d0,PrefsHandle-data_base(a5)
	beq.s End_Prefs

	move.l WindowHandle(pc),d1		affiche "reading prefs.."
	move.l #PrefsMsg,d2
	move.l #PrefsSize,d3
	CALL Write

read_pref_line
	addq.w #1,Prefs_Line-data_base(a5)	incrémente le # de ligne
	tst.w Prefs_EOF-data_base(a5)		on est à la fin du fichier ?
	beq.s End_Prefs
	moveq #100-1,d4				100 chars maximum !!
	lea TMC_Fib(pc),a3
read_pref_char
	move.l PrefsHandle(pc),d1		lit un char jusqu'a temps de
	move.l a3,d2				trouver un CR ou une erreur
	moveq #1,d3
	CALL Read
	move.w d0,Prefs_EOF-data_base(a5)	sauve ca en temps que flag
	beq.s pref_line_read			fin du fichier
	bmi.s Reset_Prefs			erreur
	cmp.b #10,(a3)				on est à la fin de la ligne ?
	beq.s pref_line_read			oui !!
	addq.l #1,a3
	dbf d4,read_pref_char
	bra.s Reset_Prefs			ouarf  trop long !!!

pref_line_read
	clr.b (a3)				met un zero en fin de ligne

	cmp.l #TMC_Fib,a3			fait gaffe aux lignes vides
	beq.s read_pref_line
	lea OptionsTable(pc),a0			pointe la table des options
check_next_option
	lea TMC_Fib(pc),a1			pointe le début de la ligne
	lea 4(a0),a2				pointe l'option
check_option
	move.b (a2)+,d0				on arrive à la fin de l'option ?
	beq.s Option_Recognized
	cmp.b (a1)+,d0				c'est la même lettre ?
	beq.s check_option
Not_This_Option
	move.l (a0),d0				prend l'option suivante
	move.l d0,a0
	bne.s check_next_option			c'est la derniere option ?
	bra.s Reset_Prefs			option non reconnu => on sort
Option_Recognized
	move.l a2,d0				\  pointe une adresse paire
	addq.l #1,d0				 \ pour aller pecher l'adresse
	and.l #-2,d0				 / de la fonction et des
	move.l d0,a0				/  parametres
	move.l (a0)+,a2				a0=adresse parametres
	jmp (a2)				a1=datas de l'option

End_Prefs
	move.l #WritePath,d1			essaie d'obtenir un lock
	moveq #ACCESS_READ,d2			sur le nouveau repertoire
	CALL Lock				courant
	move.l d0,d1
	beq.s Reset_Prefs			on l'a eut ?
	CALL CurrentDir
	move.l d0,CLI_Dir-data_base(a5)

	move.l PrefsHandle(pc),d1		ferme le fichier
	beq.s No_Close_Prefs
	CALL Close
	clr.l PrefsHandle-data_base(a5)
No_Close_Prefs
	rts

Reset_Prefs
	clr.b sample_opt-data_base(a5)		optimization samples
	move.b #"n",Menu_patch1-data_base(a5)
	move.b #" ",Menu_patch1+1-data_base(a5)

	move.b #$ff,split_opt-data_base(a5)	split samples
	move.b #"f",Menu_patch2-data_base(a5)
	move.b #"f",Menu_patch2+1-data_base(a5)

	lea ReadPath(pc),a0			efface les paths
	lea WritePath(pc),a1
	move.w #DSIZE+1-1,d0
loop_clear_path
	clr.b (a0)+
	clr.b (a1)+
	dbf d0,loop_clear_path
	bsr Free_Mark

	lea ReqFileStruct+frq_Hide(pc),a0	effaces les filtres
	lea ReqFileStruct+frq_Show(pc),a1
	moveq #WILDLENGTH+2-1,d0
loop_clear_filter
	clr.b (a0)+
	clr.b (a1)+
	dbf d0,loop_clear_filter

	lea PrefsErrorMsg(pc),a0		affiche le # de ligne ou
	lea Prefs_Line(pc),a1			ca a planté
	lea Putch(pc),a2
	lea TMC_Fib(pc),a3
	CALL RawDoFmt

	lea 1(a3),a0
.strlen	tst.b (a3)+
	bne.s .strlen
	sub.l a0,a3

	move.l WindowHandle(pc),d1		affiche "error.."
	move.l #TMC_Fib,d2
	move.l a3,d3
	move.l _DosBase(pc),a6
	CALL Write
	bsr ReadKey

	bra End_Prefs

*-----------------------> function qui lit un path
ReadPathFunction
	move.l (a0),a0				va chercher l'adresse du buffer
put_path
	move.b (a1)+,(a0)+			recopie le path
	bne.s put_path
	bra read_pref_line

*-----------------------> function qui lit une mark
ReadMarkFunction
	moveq #4-1,d0				une mark a 4 chars
	moveq #0,d7
read_mark_char
	lsl.l #8,d7
	move.b (a1)+,d1				va chercher un char
	cmp.b #"\",d1				char special ?
	beq.s mark_slash
return_slash
	move.b d1,d7
	dbf d0,read_mark_char
	tst.b (a1)				regarde si ya un zero à la fin
	bne Reset_Prefs

	moveq #ma_SIZEOF,d0			alloue de la mémoire
	moveq #MEMF_PUBLIC,d1			pour stocker la Mark
	move.l (_SysBase).w,a6
	CALL AllocMem
	move.l _DosBase(pc),a6
	tst.l d0
	beq Reset_Prefs

	move.l Mark_Adr(pc),d1			insere la structure ds la
	move.l d0,Mark_Adr-data_base(a5)	chaine
	move.l d0,a0
	move.l d1,ma_Next(a0)
	move.l d7,ma_Mark(a0)
	bra read_pref_line

mark_slash
	cmp.b #"\",(a1)				c'est un vrai slash ?
	beq.s return_slash
	moveq #0,d1				char de retour
	moveq #3-1,d2				3 nb décimaux pour un special
	moveq #100,d3
loop_read_special
	moveq #0,d4
	move.b (a1)+,d4				lit un nombre
	cmp.b #"0",d4
	blt Reset_Prefs			il est valable ?
	cmp.b #"9",d4
	bgt Reset_Prefs
	sub.b #"0",d4
	mulu d3,d4				mulu #100,#10,#1
	add.w d4,d1
	divu #10,d3
	dbf d2,loop_read_special
	cmp.w #$ff,d1				le nb est entre 0 et 255 ?
	ble.s return_slash
	bra Reset_Prefs
	
*-----------------------> function pour lire un mask
ReadMaskFunction
	move.l (a0),a0
	moveq #30-1,d0
read_mask
	move.b (a1)+,(a0)+
	beq read_pref_line
	dbf d0,read_mask
	bra Reset_Prefs

*-----------------------> function qui autorise l'optimisation des samples
SampleOnFunction
	clr.b sample_opt-data_base(a5)
	move.b #"n",Menu_patch1-data_base(a5)
	move.b #" ",Menu_patch1+1-data_base(a5)
	bra read_pref_line

*-----------------------> function qui interdit l'optimisation des samples
SampleOffFunction
	move.b #$ff,sample_opt-data_base(a5)
	move.b #"f",Menu_patch1-data_base(a5)
	move.b #"f",Menu_patch1+1-data_base(a5)
	bra read_pref_line

*-----------------------> function qui autorise le splitage des modules
SplitOnFunction
	clr.b split_opt-data_base(a5)
	move.b #"n",Menu_patch2-data_base(a5)
	move.b #" ",Menu_patch2+1-data_base(a5)
	bra read_pref_line

*-----------------------> function qui interdit le splitage des modules
SplitOffFunction
	move.b #$ff,split_opt-data_base(a5)
	move.b #"f",Menu_patch2-data_base(a5)
	move.b #"f",Menu_patch2+1-data_base(a5)
	bra read_pref_line

*-----------------------> routine qui libère toutes les Marks
Free_Mark
	move.l Mark_Adr(pc),d3
	move.l (_SysBase).w,a6
loop_free
	tst.l d3
	beq.s end_free
	move.l d3,a1
	move.l ma_Next(a1),d3
	moveq #ma_SIZEOF,d0
	CALL FreeMem
	bra.s loop_free
end_free
	clr.l Mark_Adr-data_base(a5)
	rts

*-----------------------> routine pour lire une touche
ReadKey
	move.l WindowHandle(pc),d1
	move.l #KeyBuffer,d2
	moveq #1,d3
	CALL Read
	rts

*--------------------------------> routine qui écrit un nb en hex
*--------------------> d0=nb de digits-1
*--------------------> d1=nb
*--------------------> a0=adr d'écriture
write_hex
	move.b d1,d2
	and.b #$f,d2
	cmp.b #9,d2
	bgt.s do_A
	add.b #"0",d2
	move.b d2,-(a0)
	lsr.l #4,d1
	dbf d0,write_hex
	rts
do_A
	add.b #"A"-$a,d2
	move.b d2,-(a0)
	lsr.l #4,d1
	dbf d0,write_hex
	rts

*-----------------------> une routine pour exec
Putch
	move.b d0,(a3)+
	rts

*-----------------------> les datas de TMC
data_base
ReqFileStruct
	dc.w REQVERSION			frq_VersionNumber
	dc.l 0				Title
	dc.l ReadPath			Dir
	dc.l FileName			File
	dc.l PathName			pathName
	dc.l 0				Window
	dc.w 0				MaxExtendedSelect
	dc.w 0				numlines
	dc.w 0				numcolumns
	dc.w 0				devcolumns
	dc.l 0				Flags
	dc.w 3				dirnamescolor
	dc.w 0				filenamescolor
	dc.w 3				devicenamescolor
	dc.w 0				fontnamescolor
	dc.w 0				fontsizecolor
	dc.w 0				detailcolor
	dc.w 0				blockcolor
	dc.w 0				gadgettextcolor
	dc.w 0				textmessagecolor
	dc.w 0				stringnamecolor
	dc.w 0				stringgadgetcolor
	dc.w 0				boxbordercolor
	dc.w 0				gadgetboxcolor
	dcb.b 36,0			RFU_Stuff
	dcb.b ds_SIZEOF,0		DirDateStamp
	dc.w 0				WindowLeftEdge
	dc.w 0				WindowTopEdge
	dc.w 0				FontYSize
	dc.w 0				FontStyle
	dc.l 0				ExtendedSelect
	dcb.b WILDLENGTH+2,0		Hide
	dcb.b WILDLENGTH+2,0		Show
	dc.w 0				FileBufferPos
	dc.w 0				FileDispPos
	dc.w 0				DirBufferPos
	dc.w 0				DirDispPos
	dc.w 0				HideBufferPos
	dc.w 0				HideDispPos
	dc.w 0				ShowBufferPos
	dc.w 0				ShowDispPos
	dc.l 0				Memory
	dc.l 0				Memory2
	dc.l 0				Lock
	dcb.b DSIZE+2,0			PrivateDirBuffer
	dc.l 0				FileInfoBlock
	dc.w 0				NumEntries
	dc.w 0				NumHiddenEntries
	dc.w 0				filestartnumber
	dc.w 0				devicestartnumber

periodes_table
	dc.w 856,808,762,720,678,640,604,570,538,508,480,453
	dc.w 428,404,381,360,339,320,302,285,269,254,240,226
	dc.w 214,202,190,180,170,160,151,143,135,127,120,113

InputLock	dc.l 0
ModuleHandle	dc.l 0
SongHandle	dc.l 0
PatternHandle	dc.l 0
SampleHandle	dc.l 0
PrefsHandle	dc.l 0
Module_Adr	dc.l 0
Mark_Adr	dc.l 0

Patterns_Adr	dc.l 0
Positions_Adr	dc.l 0
Samples_Adr	dc.l 0
mt_Pos		dc.w 0
Nb_Patterns	dc.w 0
Nb_Positions	dc.w 0
Size_Module	dc.l 0
Gain		dc.l 0
Gain_Percent	dc.w 0

busy_Patterns	dcb.b 64,0
busy_Positions	dcb.b 128,0
busy_Samples	dcb.b 32,0
busy_Finetunes	dcb.b 16,0
Patterns_Offset	dcb.l 64,0

_DosBase	dc.l 0
_ReqBase	dc.l 0
save_SP		dc.l 0
save_WindowPtr	dc.l 0
CLI_Dir		dc.l 0
Prefs_Line	dc.w 0
Prefs_EOF	dc.w $ffff
WindowHandle	dc.l 0
sample_opt	dc.b 0
split_opt	dc.b $ff
KeyBuffer	dc.b 0
NotImp		dc.b 0
ImpPattern	dc.w 0
ImpPosition	dc.w 0
ImpVoice	dc.w 0

OptionsTable
CommentOpt	dc.l SourceOpt
		dc.b ";",0
		even
		dc.l read_pref_line

SourceOpt	dc.l DestOpt
		dc.b "SOURCE=",0
		even
		dc.l ReadPathFunction
		dc.l ReadPath

DestOpt		dc.l MarkOpt
		dc.b "DESTINATION=",0
		even
		dc.l ReadPathFunction
		dc.l WritePath

MarkOpt		dc.l MaskShowOpt
		dc.b "MARK=",0
		even
		dc.l ReadMarkFunction

MaskShowOpt	dc.l MaskHideOpt
		dc.b "MASKSHOW=",0
		even
		dc.l ReadMaskFunction
		dc.l ReqFileStruct+frq_Show

MaskHideOpt	dc.l SampleOnOpt
		dc.b "MASKHIDE=",0
		even
		dc.l ReadMaskFunction
		dc.l ReqFileStruct+frq_Hide

SampleOnOpt	dc.l SampleOffOpt
		dc.b "OPTSAMPLES ON",0
		even
		dc.l SampleOnFunction

SampleOffOpt	dc.l SplitOnOpt
		dc.b "OPTSAMPLES OFF",0
		even
		dc.l SampleOffFunction

SplitOnOpt	dc.l SplitOffOpt
		dc.b "SPLITMOD ON",0
		even
		dc.l SplitOnFunction

SplitOffOpt	dc.l 0
		dc.b "SPLITMOD OFF",0
		even
		dc.l SplitOffFunction

DosName		dc.b "dos.library",0
ReqName		dc.b "req.library",0
FileName	dcb.b FCHARS+1,0
PathName	dcb.b FCHARS+DSIZE+2,0
ReadPath	dcb.b DSIZE+1,0
WritePath	dcb.b DSIZE+1,0

WindowName	dc.b "RAW:120/60/400/110/The Module Converter v3.9 by Sync of DRD",0
CancelStr	dc.b $9b,"0;33;40m",9,"No Module Selected.",10
CancelSize=*-CancelStr
SuccessStr	dc.b $9b,"0;33;40m",9,"Module Size : %ld  Gain : %ld(%d%%)",10,0
LockStr		dc.b $9b,"0;33;40m",9,"Lock() Error.",10
LockSize=*-LockStr
ExamineStr	dc.b $9b,"0;33;40m",9,"Examine() Error.",10
ExamineSize=*-ExamineStr
DirectoryStr	dc.b $9b,"0;33;40m",9,"Error: FileName is a directory.",10
DirectorySize=*-DirectoryStr
MemStr		dc.b $9b,"0;33;40m",9,"AllocMem() Error.",10
MemSize=*-MemStr
OpenStr		dc.b $9b,"0;33;40m",9,"Open() Error.",10
OpenSize=*-OpenStr
ReadStr		dc.b $9b,"0;33;40m",9,"Read() Error.",10
ReadSize=*-ReadStr
MarkStr		dc.b $9b,"0;33;40m",9,"FileName is not a module.",10
MarkSize=*-MarkStr
WriteStr	dc.b $9b,"0;33;40m",9,"Write() Error.",10
WriteSize=*-MarkStr

PrefsMsg	dc.b $c,$9b,$30,$20,$70
		dc.b 10,10,10
		dc.b 9,"Reading preferences file...",10
PrefsSize=*-PrefsMsg

PrefsErrorMsg	dc.b $9b,"0;33;40m"
		dc.b 9,"Error on line %d",10,10
		dc.b $9b,"0;31;40m"
		KEY
		dc.b 0
PrefsErrorSize=*-PrefsErrorMsg

StartMsg	dc.b $c,10
		dc.b 9,9,"Select a module",10
StartSize=*-StartMsg
ReadMsg		dc.b 9,9,"Reading module",10
ReadMsgSize=*-ReadMsg
ConvertMsg	dc.b 9,9,"Converting patterns",10
ConvertSize=*-ConvertMsg
ResetMsg	dc.b $9b,"0;33;40m",9,"Warning : Restart zero'ed",10
		dc.b $9b,"0;31;40m"
ResetSize=*-ResetMsg
WarningMsg	dc.b $9b,"0;33;40m",9,"Warning : Unimplemented function found",10
		dc.b $9b,"0;31;40m"
WarningMsgSize=*-WarningMsg
PackMsg		dc.b 9,9,"Packing patterns",10
PackSize=*-PackMsg
SaveMsg		dc.b 9,9,"Saving module",10
SaveSize=*-SaveMsg
PressKey	dc.b 10
		KEY
PressKeySize=*-PressKey

AboutStr	dc.b $c,$9b,"0;33;40m",10
		dc.b "            The Module Converter  v3.9",10,$9b,"0;31;40m"
		dc.b "             © 1993 Sync/DreamDealers",10
		dc.b "       You can contact me for bugs reports",10
		dc.b "              or LEGALS things at :",10
		dc.b 10
		dc.b "                 Pierre Chalamet",10
		dc.b "               5 Rue du 11 Octobre",10
		dc.b "            45140 St Jean de la Ruelle",10
		dc.b "                     FRANCE",10
		KEY
AboutSize=*-AboutStr

ReqSelect	dc.b "Select A Module",0
ReqDir		dc.b "Select A New Directory",0

MenuStr		dc.b $c,$9b,$30,$20,$70,$9b,"0;33;40m",10
		dc.b 9,9,"  »» TMC Menu ««",10,10,$9b,"0;31;40m"
		dc.b 9,9,"C) Convert Module",10
		dc.b 9,9,"D) Change Directory",10
		dc.b 9,9,"O) Optimize Samples O"
Menu_patch1	dc.b "n ",10
		dc.b 9,9,"S) Split Module O"
Menu_patch2	dc.b "ff",10
		dc.b 9,9,"A) About",10
		dc.b 9,9,"Q) Quit",10
		dc.b 10
		KEY
MenuSize=*-MenuStr

Banner		dc.b 10
		dc.b "*******************************************************************",10
		dc.b "* Source-Song Generated With  TMC v3.9 ©1993 Sync of DreamDealers *",10
		dc.b "* From Module : "
NamePatch	dc.b "                                                  *",10
		dc.b "* SongName    : "
SongPatch	dc.b "                                                  *",10
		dc.b "*******************************************************************",10
		dc.b 10
		dc.b 10
BannerSize=*-Banner

WarningImp	dc.b "******************************************************************************",10
		dc.b "* WARNING : UNIMPLEMENTED FUNCTION FOUND IN PATTERN $00"
Warning_patch1	dc.b " POSITION $00"
Warning_patch2	dc.b " VOICE 0"
Warning_patch3	dc.b " *",10
		dc.b "******************************************************************************",10
		dc.b 10
WarningImpSize=*-WarningImp

Restart		dc.b 9,9,"*****************************************************",10
		dc.b 9,9,"* THIS SECTION CAN BE EITHER IN FAST OR CHIP MEMORY *",10
		dc.b 9,9,"*****************************************************",10
		dc.b "mt_restart",10
		dc.b 9,"dc.l mt_pos+4*$00"
RestartPatch	dc.b 10,"mt_samples_list",10
RestartSize=*-Restart

FineTune_Msg
	dc.b "mt_FineTune0",10
	dc.b 9,"dc.w 856,808,762,720,678,640,604,570,538,508,480,453",10
	dc.b 9,"dc.w 428,404,381,360,339,320,302,285,269,254,240,226",10
	dc.b 9,"dc.w 214,202,190,180,170,160,151,143,135,127,120,113,0",10
FineTune_Msg_Size=*-FineTune_Msg

	dc.b "mt_FineTune1",10
	dc.b 9,"dc.w 850,802,757,715,674,637,601,567,535,505,477,450",10
	dc.b 9,"dc.w 425,401,379,357,337,318,300,284,268,253,239,225",10
	dc.b 9,"dc.w 213,201,189,179,169,159,150,142,134,126,119,113,0",10

	dc.b "mt_FineTune2",10
	dc.b 9,"dc.w 844,796,752,709,670,632,597,563,532,502,474,447",10
	dc.b 9,"dc.w 422,398,376,355,335,316,298,282,266,251,237,224",10
	dc.b 9,"dc.w 211,199,188,177,167,158,149,141,133,125,118,112,0",10

	dc.b "mt_FineTune3",10
	dc.b 9,"dc.w 838,791,746,704,665,628,592,559,528,498,470,444",10
	dc.b 9,"dc.w 419,395,373,352,332,314,296,280,264,249,235,222",10
	dc.b 9,"dc.w 209,198,187,176,166,157,148,140,132,125,118,111,0",10

	dc.b "mt_FineTune4",10
	dc.b 9,"dc.w 832,785,741,699,660,623,588,555,524,495,467,441",10
	dc.b 9,"dc.w 416,392,370,350,330,312,294,278,262,247,233,220",10
	dc.b 9,"dc.w 208,196,185,175,165,156,147,139,131,124,117,110,0",10

	dc.b "mt_FineTune5",10
	dc.b 9,"dc.w 826,779,736,694,655,619,584,551,520,491,463,437",10
	dc.b 9,"dc.w 413,390,368,347,328,309,292,276,260,245,232,219",10
	dc.b 9,"dc.w 206,195,184,174,164,155,146,138,130,123,116,109,0",10

	dc.b "mt_FineTune6",10
	dc.b 9,"dc.w 820,774,730,689,651,614,580,547,516,487,460,434",10
	dc.b 9,"dc.w 410,387,365,345,325,307,290,274,258,244,230,217",10
	dc.b 9,"dc.w 205,193,183,172,163,154,145,137,129,122,115,109,0",10

	dc.b "mt_FineTune7",10
	dc.b 9,"dc.w 814,768,725,684,646,610,575,543,513,484,457,431",10
	dc.b 9,"dc.w 407,384,363,342,323,305,288,272,256,242,228,216",10
	dc.b 9,"dc.w 204,192,181,171,161,152,144,136,128,121,114,108,0",10

	dc.b "mt_FineTune8",10
	dc.b 9,"dc.w 907,856,808,762,720,678,640,604,570,538,508,480",10
	dc.b 9,"dc.w 453,428,404,381,360,339,320,302,285,269,254,240",10
	dc.b 9,"dc.w 226,214,202,190,180,170,160,151,143,135,127,120,0",10

	dc.b "mt_FineTune9",10
	dc.b 9,"dc.w 900,850,802,757,715,675,636,601,567,535,505,477",10
	dc.b 9,"dc.w 450,425,401,379,357,337,318,300,284,268,253,238",10
	dc.b 9,"dc.w 225,212,200,189,179,169,159,150,142,134,126,119,0",10

	dc.b "mt_FineTuneA",10
	dc.b 9,"dc.w 894,844,796,752,709,670,632,597,563,532,502,474",10
	dc.b 9,"dc.w 447,422,398,376,355,335,316,298,282,266,251,237",10
	dc.b 9,"dc.w 223,211,199,188,177,167,158,149,141,133,125,118,0",10

	dc.b "mt_FineTuneB",10
	dc.b 9,"dc.w 887,838,791,746,704,665,628,592,559,528,498,470",10
	dc.b 9,"dc.w 444,419,395,373,352,332,314,296,280,264,249,235",10
	dc.b 9,"dc.w 222,209,198,187,176,166,157,148,140,132,125,118,0",10

	dc.b "mt_FineTuneC",10
	dc.b 9,"dc.w 881,832,785,741,699,660,623,588,555,524,494,467",10
	dc.b 9,"dc.w 441,416,392,370,350,330,312,294,278,262,247,233",10
	dc.b 9,"dc.w 220,208,196,185,175,165,156,147,139,131,123,117,0",10

	dc.b "mt_FineTuneD",10
	dc.b 9,"dc.w 875,826,779,736,694,655,619,584,551,520,491,463",10
	dc.b 9,"dc.w 437,413,390,368,347,328,309,292,276,260,245,232",10
	dc.b 9,"dc.w 219,206,195,184,174,164,155,146,138,130,123,116,0",10

	dc.b "mt_FineTuneE",10
	dc.b 9,"dc.w 868,820,774,730,689,651,614,580,547,516,487,460",10
	dc.b 9,"dc.w 434,410,387,365,345,325,307,290,274,258,244,230",10
	dc.b 9,"dc.w 217,205,193,183,172,163,154,145,137,129,122,115,0",10

	dc.b "mt_FineTuneF",10
	dc.b 9,"dc.w 862,814,768,725,684,646,610,575,543,513,484,457",10
	dc.b 9,"dc.w 431,407,384,363,342,323,305,288,272,256,242,228",10
	dc.b 9,"dc.w 216,203,192,181,171,161,152,144,136,128,121,114,0",10

SampleLine	dc.b 9,"dc.l mt_sample00"
SamplePatch	dc.b 10
SampleLineSize=*-SampleLine

PosLabel	dc.b "mt_pos",10
PosLabelSize=*-PosLabel

PosLine		dc.b 9,"dc.l mt_pos_end+$0000"
PosLinePatch	dc.b 10
PosLineSize=*-PosLine

PosEnd		dc.b "mt_pos_end",10
		dc.b 9,'incbin "Patterns.dat"',10
PosEndSize=*-PosEnd

Sample_Msg	dc.b "mt_sample00"
Sample_patch1	dc.b 10,9,"dc.w $0000"			mt_len
Sample_patch2	dc.b 10,9,"dc.w $00"			mt_volume
Sample_patch3	dc.b 10,9,"dc.l *+10+2*$0000"		mt_repeat
Sample_patch4	dc.b 10,9,"dc.w $0000"			mt_replen
Sample_patch5	dc.b 10,9,"dc.l mt_FineTune0"		mt_FineTune
Sample_patch6	dc.b 10,9,'incbin "Sample00'		mt_samp_adr
Sample_patch7	dc.b '.dat"',10
Sample_Size=*-Sample_Msg

Warning		dc.b 10,10
		dc.b 9,9,"***************************************",10
		dc.b 9,9,"* THIS SECTION MUST BE IN CHIP MEMORY *",10
		dc.b 9,9,"***************************************",10
WarningSize=*-Warning

DOS_SongName	dc.b "Song.s",0
DOS_SampleName	dc.b "Samples.s",0
DOS_PattName	dc.b "Patterns.dat",0
DOS_SampName	dc.b "Sample00"
DOS_SampPatch	dc.b ".dat",0
DOS_Prefs	dc.b "S:TMC.Prefs",0

Empty_Sample	dc.b 0,0

	cnop 0,4
TMC_Fib		dcb.b fib_SIZEOF
Size_Buffer	dcb.b 50
