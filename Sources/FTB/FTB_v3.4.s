 
*
*		FTB v3.4  ©1993 by Sync of ThE SpeCiAl BrOthErS
*		------------------------------------------------->
*		derniere modification : 10 fevrier 1993


	opt O+,OW-

	incdir "dh1:asm/include1.3/" "asm:.s/FTB/"

	include "intuition/intuition_lib.i"
	include "intuition/intuition.i"
	include "exec/execbase.i"
	include "exec/exec_lib.i"
	include	"exec/exec.i"
	include "exec/nodes.i"
	include "exec/memory.i"
	include "exec/tasks.i"
	include "libraries/dos.i"
	include "libraries/dos_lib.i"
	include	"libraries/dosextens.i"
	include "graphics/gfxbase.i"
	include "graphics/graphics_lib.i"
	include "devices/trackdisk.i"
	include "libraries/reqbase.i"
	include "libraries/req_lib.i"
	include "misc/Macros.i"

		*************************************
		* PREMIER SEGMENT POUR LE BACKSTART *
		*************************************

	section FTB_init,code			premier segment pour backstart
_start_backstart
	bra skip_copyright

	dc.b '$VER: FTB  v3.4  --  © 1993 Pierre "Sync" Chalamet  --$',0

skip_copyright
	lea data_base,a5			base des données

	move.l (_SysBase).w,a6			équivalent de FindTask
	move.l ThisTask(a6),a4			mais en plus rapide

	tst.l pr_CLI(a4)			CLI ou WB ?
	beq.s fromWorkbench

	lea ReqName(pc),a1			ouvre la req.library 2.5
	moveq #REQVERSION,d0
	CALL OpenLibrary
	move.l d0,_ReqBase-data_base(a5)
	beq.s Error_Open_Req_CLI

	move.l d0,a0				quelques bases de library
	move.l rl_DosLib(a0),_DosBase-data_base(a5)
	move.l rl_IntuiLib(a0),_IntuitionBase-data_base(a5)
	move.l rl_GfxLib(a0),_GfxBase-data_base(a5)

	lea Reply_Port_Name-data_base(a5),a1	recherche le reply_port de FTB
	CALL FindPort
	tst.l d0
	bne.s Already_Installed_CLI

	lea _start_backstart-4(pc),a0
	move.l (a0),d3
	move.l d3,_SegList-data_base(a5)	le segment est coupé
	clr.l (a0)				de la chaine

	move.l pr_CLI(a4),a1
	add.l a1,a1				BCPL -> APTR
	add.l a1,a1
	move.l cli_Module(a1),a2
	add.l a2,a2				BCPL -> APTR
	add.l a2,a2
	clr.l (a2)				prg coupé du CLI

	move.l #IconizeName,d1			name
	moveq #0,d2				priority
	move.l #2048,d4				stack size
	move.l _DosBase-data_base(a5),a6
	CALL CreateProc				crée un Process
	tst.l d0				erreur dans CreateProc ?
	bne.s Error_Open_Req_CLI		non !

Already_Installed_CLI
	move.l _ReqBase-data_base(a5),a1	ferme la library si CreateProc
	CALL CloseLibrary			a foiré !
Error_Open_Req_CLI
	moveq #0,d0				on sort de la tache initiatrice
	rts

fromWorkbench
	lea pr_MsgPort(a4),a0			Msg port de notre task
	CALL WaitPort				attend le Msg du WB
	lea pr_MsgPort(a4),a0			Msg port de notre task
	CALL GetMsg				récupère le Msg
	move.l d0,-(sp)				et on le sauve sur la pile

	lea ReqName(pc),a1			ouvre la req.library 2.5
	moveq #REQVERSION,d0
	CALL OpenLibrary
	move.l d0,_ReqBase-data_base(a5)
	beq.s Error_Open_Req_WB

	move.l d0,a0				quelques bases de library
	move.l rl_DosLib(a0),_DosBase-data_base(a5)
	move.l rl_IntuiLib(a0),_IntuitionBase-data_base(a5)
	move.l rl_GfxLib(a0),_GfxBase-data_base(a5)

	lea Reply_Port_Name-data_base(a5),a1	recherche le reply_port de FTB
	CALL FindPort
	tst.l d0
	bne.s Already_Installed_WB

	jsr _main				saute au programme

Error_Open_Req_WB
	move.l (_SysBase).w,a6
	CALL Forbid
	move.l (sp)+,a1				récupère le WB Msg
	CALL ReplyMsg				on le redonne gentillement au WB
	moveq #0,d0				bye bye !
	rts

Already_Installed_WB
	move.l _ReqBase-data_base(a5),a1	referme la req.library
	CALL CloseLibrary
	bra.s Error_Open_Req_WB

ReqName
	dc.b "req.library",0

			**************************************
			* DEUXIEME SEGMENT POUR LE BACKSTART *
			**************************************

	section FTB_main,code			section en public memory
__main
	bsr.s _main				saute au programe
	move.l _SegList(pc),d1			libère le segment
	move.l _DosBase(pc),a6
	CALL UnLoadSeg
	moveq #0,d0
	rts

_main
*----------------------------> essaie d'ouvrir le Trackdisk
	lea data_base(pc),a5

	lea Reply_Port(pc),a1
	move.l (_SysBase).w,a6			met ptr task dans Reply_Port
	move.l ThisTask(a6),a0			plus rapide que Findtask(0)
	move.l a0,MP_SIGTASK(a1)
	move.l pr_WindowPtr(a0),FTB_pr_WindowPtr-data_base(a5)
	moveq #-1,d0				vire les requesters
	move.l d0,pr_WindowPtr(a0)
	CALL AddPort				déclare notre port
	
	moveq #0,d0				lecteur DF0:
	moveq #0,d1				pas de flags
	lea TD_DeviceName(pc),a0		le nom du device
	lea TD_Struct(pc),a1			la structure pour le device
	CALL OpenDevice				ouvre le device
	tst.l d0
	bne Close_Libraries			si erreur on sort

	move.l #11*512,d0			alloue un buffer en chip
	move.l #MEMF_CHIP,d1			pour le trackdisk
	CALL AllocMem
	move.l d0,TD_Buffer-data_base(a5)
	beq Close_Device

*--------------------------------> ouvre la fenètre avec ses gadgets
Draw_FTB_Window
	lea Window_struct(pc),a0		ouvre la fenetre avec tous
	move.l _IntuitionBase(pc),a6		ses gadgets
	CALL OpenWindow
	move.l d0,Window_handle-data_base(a5)
	beq Free_Memory				problème à l'ouverture ?
	move.l d0,a0
	move.l wd_RPort(a0),a3
	move.l a3,RastPort_wd-data_base(a5)	récupère le RastPort et le
	move.l wd_UserPort(a0),UserPort-data_base(a5)	UserPort de la fenetre

	moveq #16,d0				affiche le busy sprite
	moveq #16,d1
	moveq #-6,d2
	moveq #0,d3
	lea Busy_Spr,a1
	CALL SetPointer

*--------------------------------> dessine des trucs dans la fenètre
	move.l a3,a0
	lea IntuiTextInfo(pc),a1		affiche "Current Block :"
	moveq #0,d0				+ "Install From :    To :"
	moveq #0,d1				+ Option
	move.l _IntuitionBase(pc),a6		+ FileName
	CALL PrintIText

	move.l a3,a0				affiche le block de départ
	lea IntuiTextStart(pc),a1
	moveq #0,d0
	moveq #0,d1
	CALL PrintIText

	move.l a3,a0				affiche le block de fin
	lea IntuiTextStop(pc),a1
	moveq #0,d0
	moveq #0,d1
	CALL PrintIText

*-----------------> affichage des encadrements blancs
	moveq #2,d0				couleur blanche
	move.l a3,a1
	move.l _GfxBase(pc),a6
	CALL SetAPen

	lea WindowLines(pc),a4
	moveq #lc_Lines+4*lr_Lines-1,d7
put_Window_Lines1
	movem.l (a4)+,d0-d1			ici on affiche les boites
	move.l a3,a1
	CALL Move				qui encadrent les textes
	movem.l (a4)+,d0-d1
	move.l a3,a1
	CALL Draw
	dbf d7,put_Window_Lines1

*-----------------> affiche les encadrements noirs + tirets sous les lettres
	moveq #1,d0				couleur noire
	move.l a3,a1
	CALL SetAPen

	moveq #10+lc_Lines+4*lr_Lines-1,d7
put_Window_Lines2
	movem.l (a4)+,d0-d1			ici on affiche les boites
	move.l a3,a1
	CALL Move				qui encadrent les textes
	movem.l (a4)+,d0-d1			+ tirets sous les lettres
	move.l a3,a1
	CALL Draw
	dbf d7,put_Window_Lines2

	move.l Window_handle(pc),a0
	move.l _IntuitionBase(pc),a6
	CALL ClearPointer

*---------------------------> routine qui gère le port IDCMP de la fenètre
Msg_handler
	move.l UserPort(pc),a0
	move.l (_SysBase).w,a6
	CALL WaitPort				attend un message

	move.l UserPort(pc),a0
	CALL GetMsg				on récupère le message

	move.l d0,a1				ptr sur IntuiMessage
	move.l im_Class(a1),Classe_message-data_base(a5)	Class_message
	move.l im_IAddress(a1),Gadget_adr-data_base(a5)		gadget émeteur
	move.w im_Code(a1),Key_Pressed-data_base(a5)		touche pressée
	
	CALL ReplyMsg				retourne le Msg

	move.l Classe_message(pc),d0
	cmp.l #GADGETUP,d0
	beq Gadget_Up
	cmp.l #VANILLAKEY,d0			c'est une touche ?
	beq Key_handler
	cmp.l #CLOSEWINDOW,d0			c'est CLOSE_GADGET ?
	bne.s Msg_handler
*-----------------------------------> l'utilisateur veut sortir
Close_Window
	move.l Window_handle(pc),a0		ferme la fenetre
	move.l _IntuitionBase(pc),a6
	CALL CloseWindow

Free_Memory
	move.l #11*512,d0			libère la mémoire du buffer
	move.l TD_Buffer(pc),a1			pour le trackdisk
	move.l (_SysBase).w,a6
	CALL FreeMem

Close_Device
	lea TD_Struct(pc),a1			ferme le trackdisk.device
	CALL CloseDevice

	lea Reply_Port(pc),a1			enlève le port
	CALL RemPort

Close_Libraries
	lea ReqFileStruct(pc),a0
	move.l _ReqBase(pc),a6
	CALL PurgeFiles

	move.l _ReqBase(pc),a1			on ferme la req.library
	move.l (_SysBase).w,a6
	CALL CloseLibrary

	move.l ThisTask(a6),a0
	move.l FTB_pr_WindowPtr(pc),pr_WindowPtr(a0)	remet les requesters

	tst.b DF0_Status-data_base(a5)
	beq.s clean_exit
	bsr Unlock_DF0
clean_exit
	moveq #0,d0				bye bye !
	rts

*--------------------------------> routine appelée quand un gadget est relaché
Gadget_Up
	move.l Gadget_adr(pc),d0

	cmp.l #Gadget1,d0			gadget1 ?  ( Select File )
	beq NewFile
	cmp.l #Gadget2,d0			gadget2 ?  ( Start Block )
	beq NewStart
	cmp.l #Gadget3,d0			gadget3 ?  ( End Block )
	beq NewStop
	cmp.l #Gadget4,d0			gadget4 ?  ( Options )
	beq NewOption
	cmp.l #Gadget5,d0			gadget5 ?  ( Start )
	beq Start
	cmp.l #Gadget7,d0			gadget7 ?  ( Bitmap )
	beq Bitmap_Editor
	cmp.l #Gadget8,d0			gadget8 ?  ( Format )
	beq Format_Disk
	cmp.l #Gadget9,d0			gadget9 ?  ( Iconize )
	beq Iconize
	cmp.l #Gadget10,d0			gadget10 ? ( About )
	beq About
	cmp.l #Gadget11,d0			gadget11 ? ( Lock )
	beq DF0_Locker
	bra Msg_handler

*--------------------------------> routine appelé quand une touche est appuyé
Key_handler
	move.w Key_Pressed(pc),d0
	cmp.w #"f",d0				Select File ?
	beq.s NewFile
	cmp.w #"s",d0				Start Block ?
	beq NewStart
	cmp.w #"e",d0				End Block ?
	beq NewStop
	cmp.w #"n",d0				Next Option ?
	beq NewOption
	cmp.w #"t",d0				Start ?
	beq Start
	cmp.w #"b",d0				Bitmap ?
	beq Bitmap_Editor
	cmp.w #"m",d0				Format ?
	beq Format_Disk
	cmp.w #"i",d0				Iconize ?
	beq Iconize
	cmp.w #"a",d0				About ?
	beq About
	cmp.w #"l",d0
	beq DF0_Locker_Key
	bra Msg_handler

*--------------------------> le gadget select file a été clické
NewFile
	lea ReqFileStruct(pc),a0
	move.l _ReqBase(pc),a6
	CALL FileRequester			l'utilisateur choisit un file
	tst.l d0				c'est vrai ce mensonge ?
	beq Msg_handler

	lea FileName(pc),a0			recherche la fin du nom du
	moveq #30-1,d0				fichier
.erase_end_filename
	move.b (a0)+,d1
	beq.s .end_found
	dbf d0,.erase_end_filename	
	bra.s .end_erase
.end_found
	moveq #" ",d1
	move.b d1,-1(a0)
.space
	move.b d1,(a0)+
	dbf d0,.space
	clr.b -1(a0)
.end_erase

	move.l RastPort_wd(pc),a0		affiche le nouveau nom
	lea IntuiTextFileName(pc),a1		du fichier
	moveq #0,d0
	moveq #0,d1
	move.l _IntuitionBase(pc),a6
	CALL PrintIText
	bra Msg_handler

*--------------------------> le gadget Start Block a été clické
NewStart
	lea LongStruct(pc),a0
	clr.l gl_minlimit(a0)
	move.l Drive_Start(pc),gl_defaultval(a0)
	move.l Drive_Stop(pc),gl_maxlimit(a0)
	move.l #StartLong,gl_titlebar(a0)
	move.l _ReqBase(pc),a6
	CALL GetLong
	tst.l d0
	beq Msg_handler
	
	lea DriveStartStr(pc),a0		convertit NB->ASCII
	move.l LongStruct+gl_result(pc),d0
	move.l d0,Drive_Start-data_base(a5)
	bsr Long_To_Ascii

	move.l RastPort_wd(pc),a0
	lea IntuiTextStart(pc),a1
	moveq #0,d0
	moveq #0,d1
	move.l _IntuitionBase(pc),a6
	CALL PrintIText
	bra Msg_handler

*-----------------------------> le gadget end block a été clické
NewStop
	lea LongStruct(pc),a0
	move.l Drive_Stop(pc),gl_defaultval(a0)
	move.l Drive_Start(pc),gl_minlimit(a0)
	move.l #1759,gl_maxlimit(a0)
	move.l #StopLong,gl_titlebar(a0)
	move.l _ReqBase(pc),a6
	CALL GetLong
	tst.l d0
	beq Msg_handler

	lea DriveStopStr(pc),a0			convertit NB->ASCII
	move.l LongStruct+gl_result(pc),d0
	move.l d0,Drive_Stop
	bsr Long_To_Ascii

	move.l RastPort_wd(pc),a0
	lea IntuiTextStop(pc),a1
	moveq #0,d0
	moveq #0,d1
	move.l _IntuitionBase(pc),a6
	CALL PrintIText
	bra Msg_handler

*-----------------------> le gadget next option a été clické
NewOption
	moveq #0,d0
	move.b Option_Number(pc),d0
	addq.b #1,d0				option suivante
	and.b #$3,d0				4 options en tout
	move.b d0,Option_Number-data_base(a5)

	add.w d0,d0
	add.w d0,d0
	lea IntuiTextOption(pc),a1
	move.l Option_List(pc,d0.w),it_IText(a1)

	move.l RastPort_wd(pc),a0
	moveq #0,d0
	moveq #0,d1
	move.l _IntuitionBase(pc),a6
	CALL PrintIText
	bra Msg_handler

Option_List
	dc.l InstallFull
	dc.l InstallRemove
	dc.l InstallFullCheck
	dc.l InstallRemoveCheck

*------------------------> routine appellé quand le gadget Start est relaché
Start
	lea TextRequestSure(pc),a0		c'est vrai ca ?
	move.l #ReqTextInstallSure,trs_Text(a0)
	move.l _ReqBase(pc),a6
	CALL TextRequest
	tst.l d0
	beq Msg_handler

	bsr.s do_installation
	bra Msg_handler

*-------------------------> analyse du fichier en fonction de l'option
do_installation
	move.l #PathName,d1			ouvre le fichier en lecture
	move.l #MODE_OLDFILE,d2
	move.l _DosBase(pc),a6
	CALL Open
	move.l d0,d4
	beq File_Error_Open

	move.l d4,d1				cherche la taille du fichier
	moveq #0,d2
	moveq #OFFSET_END,d3
	CALL Seek

	move.l d4,d1
	moveq #0,d2
	moveq #OFFSET_BEGINNING,d3
	CALL Seek
	move.l d0,FileSize-data_base(a5)
	bne.s not_empty
	rts

not_empty
	btst #0,Option_Number-data_base(a5)	option Hunk_Code ?
	beq not_hunk_code

	move.l d4,d1				lit 4 octets
	move.l #Code_Buffer,d2
	moveq #4,d3
	CALL Read
	subq.l #4,d0
	bne File_Error_Read
	cmp.l #$3f3,Code_Buffer-data_base(a5)	executable ?
	bne File_Error_Not_Exe
	
Find_end_hunk_name
	move.l d4,d1
	move.l #Code_Buffer,d2
	moveq #4,d3
	CALL Read				saute Hunk_Name
	subq.l #4,d0
	bne File_Error_Read
	tst.l Code_Buffer-data_base(a5)
	bne.s Find_end_hunk_name
	
	move.l d4,d1
	move.l #Code_Buffer,d2
	moveq #4,d3
	CALL Read
	subq.l #4,d0
	bne File_Error_Read
	
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
	subq.l #4,d0
	bne File_Error_Read			
	cmp.w #$3e9,Code_Buffer+2-data_base(a5)	Hunk_Code ?
	bne File_Error_Not_Exe

	move.l d4,d1
	move.l #Code_Buffer,d2
	moveq #4,d3
	CALL Read				lit la taille du Hunk_Code
	subq.l #4,d0
	bne File_Error_Read
	move.l Code_Buffer(pc),d0		taille en longs mots
	add.l d0,d0				taille en octets
	add.l d0,d0
	move.l d0,FileSize-data_base(a5)

*----------------------------> l'installation commence
not_hunk_code
	move.l RastPort_wd(pc),a1
	move.l #154,d0				affiche Install From
	moveq #102,d1
	move.l _GfxBase(pc),a6
	CALL Move
	
	lea DriveStartStr(pc),a0
	move.l RastPort_wd(pc),a1
	moveq #4,d0
	CALL Text

	move.l FileSize(pc),d0			calcul le block de fin
	divu #512,d0
	swap d0					regarde si il y a un reste
	tst.w d0				un reste signifie que le dernier
	bne.s divu_is_good			block est entammé
	sub.l #1<<16,d0				== le block n'est pas entamé
divu_is_good
	swap d0					nb de block
	ext.l d0
	add.l Drive_Start(pc),d0		block final
	cmp.l Drive_Stop(pc),d0			on dépasse le block de fin ?
	ble.s good_stop
	move.l Drive_Stop(pc),d0
good_stop
	lea DriveCurrentStr(pc),a0		affiche les résultats
	bsr Long_To_Ascii
	
	move.l RastPort_wd(pc),a1		affiche Install To
	move.l #250,d0
	moveq #102,d1
	CALL Move
	
	lea DriveCurrentStr(pc),a0
	move.l RastPort_wd(pc),a1
	moveq #4,d0
	CALL Text
		
	move.l Drive_Start(pc),Drive_Current-data_base(a5)

	lea TD_Struct(pc),a1			vire le buffer du trackdisk
	move.w #CMD_CLEAR,IO_COMMAND(a1)
	move.l (_SysBase).w,a6
	CALL DoIO

	lea TD_Struct(pc),a1			regarde si ya un disk dans le
	move.w #TD_CHANGESTATE,IO_COMMAND(a1)	DF0:
	CALL DoIO
	lea TD_Struct(pc),a1
	tst.l IO_ACTUAL(a1)
	bne TD_Error_No_Disk

	move.w #TD_PROTSTATUS,IO_COMMAND(a1)	regarde si le disk est protégé
	CALL DoIO
	lea TD_Struct(pc),a1
	tst.l IO_ACTUAL(a1)
	bne TD_Error_Protect

Next_Block
	move.l Drive_Current(pc),d0		convertit Current_Drive
	lea DriveCurrentStr(pc),a0		en Ascii
	bsr Long_To_Ascii
	
	move.l RastPort_wd(pc),a1
	move.l #154,d0				et on l'affiche
	moveq #92,d1
	move.l _GfxBase(pc),a6
	CALL Move
	
	lea DriveCurrentStr(pc),a0
	move.l RastPort_wd(pc),a1
	moveq #4,d0
	CALL Text

	move.l d4,d1				le handle du file
	move.l TD_Buffer(pc),d2			adr du buffer
	move.l #512,d3				taille à charger
	move.l _DosBase(pc),a6
	CALL Read				lit le fichier
	cmp.l #-1,d0
	beq TD_Error_Read

	lea TD_Struct(pc),a1
	move.w #CMD_WRITE,IO_COMMAND(a1)	commande WRITE
	move.l TD_Buffer(pc),IO_DATA(a1)	adr du buffer en chip
	move.l #512,IO_LENGTH(a1)		longueur à écrite
	move.l Drive_Current(pc),d0
	mulu #512,d0
	move.l d0,IO_OFFSET(a1)			met l'offset
	move.l (_SysBase).w,a6
	CALL DoIO				ecrit sur le disque
	lea TD_Struct(pc),a1
	tst.b IO_ERROR(a1)
	bne TD_Error_Write

	sub.l #512,FileSize-data_base(a5)	un block d'écrit
	ble TD_Exit				on a écrit tout le fichier ?
	move.l Drive_Stop(pc),d0		\ regarde si on est sur le block
	cmp.l Drive_Current(pc),d0		 | de fin alors que le fichier
	beq TD_Error_Incomplete			/  n'est pas entièrement écrit
	addq.l #1,Drive_Current-data_base(a5)	block suivant
	
	move.l UserPort(pc),a0
	CALL GetMsg				on récupère le message

	tst.l d0				un Msg ?
	beq Next_Block				pas de Msg on continue
	move.l d0,a1				ptr sur IntuiMessage
	move.l im_Class(a1),Classe_message-data_base(a5)	Class_message
	move.l im_IAddress(a1),Gadget_adr-data_base(a5)		gadget émeteur
	move.w im_Code(a1),Key_Pressed-data_base(a5)		touche
	
	CALL ReplyMsg				retourne le Msg

	cmp.l #VANILLAKEY,Classe_message-data_base(a5)		une touche ?
	bne.s TD_not_Test_Key
TD_Test_Key
	cmp.w #"o",Key_Pressed-data_base(a5)		touche Stop ?
	beq AskStopSure
	bra Next_Block

TD_not_Test_Key
	cmp.l #GADGETUP,Classe_message-data_base(a5)	c'est un gadget ?
	bne Next_Block
	cmp.l #Gadget6,Gadget_adr-data_base(a5)		regarde si gadget Stop
	bne Next_Block

AskStopSure
	lea TextRequestSure(pc),a0		requester "Are U sure ?"
	move.l #ReqTextStopSure,trs_Text(a0)
	move.l _ReqBase(pc),a6
	CALL TextRequest
	tst.l d0
	bne TD_Error_Incomplete
	bra Next_Block

TD_Exit
	lea TD_Struct(pc),a1			met le buffer sur disk
	move.w #CMD_UPDATE,IO_COMMAND(a1)	commande UPDATE
	CALL DoIO				ecrit sur le disque

	lea TD_Struct(pc),a1			arrete le moteur
	move.w #TD_MOTOR,IO_COMMAND(a1)
	clr.l IO_LENGTH(a1)
	CALL DoIO

	move.l d4,d1				ferme le fichier
	move.l _DosBase(pc),a6
	CALL Close

TD_do_CheckSum
	btst #1,Option_Number-data_base(a5)	CheckSum demandé ?
	bne.s Make_CheckSum			bit 1 car option 2 et 3
	rts

*-----------------------------> routine qui recalcule le CheckSum Block 0 et 1
Make_CheckSum
	lea TD_Struct(pc),a1			vire le buffer du trackdisk
	move.w #CMD_CLEAR,IO_COMMAND(a1)
	move.l (_SysBase).w,a6
	CALL DoIO

	lea TD_Struct(pc),a1
	move.w #CMD_READ,IO_COMMAND(a1)		commande READ
	move.l TD_Buffer(pc),IO_DATA(a1)	adr du buffer en chip
	move.l #512*2,IO_LENGTH(a1)		2 blocks à lire
	clr.l IO_OFFSET(a1)			block 0
	CALL DoIO				lit les 2 blocks
	lea TD_Struct(pc),a1
	tst.b IO_ERROR(a1)
	bne Check_Error_Read

	move.l TD_Buffer(pc),a0			pointe le buffer
	lea 4(a0),a1				pointe le CheckSum
	clr.l (a1)				on l'efface pour l'addition
	move.w #1024/4-1,d1			nb de long mot
	moveq #0,d0
Loop_CheckSum
	add.l (a0)+,d0				calcule du CheckSum du
	bcc.s Jump				bootblock
	addq.l #1,d0
Jump
	dbf d1,Loop_CheckSum
	not.l d0
	move.l d0,(a1)				sauve le CheckSum
	
	lea TD_Struct(pc),a1
	move.w #CMD_WRITE,IO_COMMAND(a1)	commande WRITE
	move.l TD_Buffer(pc),IO_DATA(a1)	adr du buffer en chip
	move.l #512*2,IO_LENGTH(a1)		2 blocks à lire
	clr.l IO_OFFSET(a1)			block 0
	CALL DoIO				lit les 2 blocks
	lea TD_Struct(pc),a1
	tst.b IO_ERROR(a1)
	bne Check_Error_Write

	move.w #CMD_UPDATE,IO_COMMAND(a1)	commande UPDATE
	CALL DoIO				ecrit sur le disque

	lea TD_Struct(pc),a1			arrete le moteur
	move.w #TD_MOTOR,IO_COMMAND(a1)
	clr.l IO_LENGTH(a1)
	CALL DoIO
	rts
	
*-----------------------> gestion des erreurs étude du fichier
File_Error_Open
	lea TextRequestStructure(pc),a0
	move.l #ReqTextOpen,trs_Text(a0)
	bra.s File_display_error

File_Error_Read
	move.l d4,d1
	CALL Close
	lea TextRequestStructure(pc),a0
	move.l #ReqTextRead,trs_Text(a0)
	bra.s File_display_error

File_Error_Not_Exe
	move.l d4,d1
	CALL Close
	lea TextRequestStructure(pc),a0
	move.l #ReqTextExe,trs_Text(a0)

File_display_error
	move.l _ReqBase(pc),a6
	CALL TextRequest
	rts

*---------------------------> gestion des erreurs pour l'installation
TD_Error_No_Disk
	lea TextRequestStructure(pc),a3
	move.l #ReqTextDisk,trs_Text(a3)
	bra.s TD_display_error

TD_Error_Protect
	lea TextRequestStructure(pc),a3
	move.l #ReqTextProtect,trs_Text(a3)
	bra.s TD_display_error

TD_Error_Read
	lea TextRequestStructure(pc),a3
	move.l #ReqTextRead,trs_Text(a3)
	bra.s TD_display_error

TD_Error_Write
	lea TextRequestStructure(pc),a3
	move.l #ReqTextWrite,trs_Text(a3)
	bra.s TD_display_error

TD_Error_Incomplete
	lea TextRequestStructure(pc),a3
	move.l #ReqTextIncomplete,trs_Text(a3)

TD_display_error
	move.l d4,d1				ferme le fichier
	move.l _DosBase(pc),a6
	CALL Close

	lea TD_Struct(pc),a1			arrete le moteur
	move.w #TD_MOTOR,IO_COMMAND(a1)
	clr.l IO_LENGTH(a1)
	move.l (_SysBase).w,a6
	CALL DoIO

	move.l a3,a0
	move.l _ReqBase(pc),a6
	CALL TextRequest
	rts

*---------------------------> gestion des erreurs pour le CheckSum
Check_Error_Read
	lea TextRequestStructure(pc),a3
	move.l #ReqTextCheckRead,trs_Text(a3)
	bra.s Check_display_error

Check_Error_Write
	lea TextRequestStructure(pc),a3
	move.l #ReqTextCheckWrite,trs_Text(a3)

Check_display_error
	move.w #TD_MOTOR,IO_COMMAND(a1)
	clr.l IO_LENGTH(a1)
	CALL DoIO

	move.l a3,a0
	move.l _ReqBase(pc),a6
	CALL TextRequest
	rts
	
*-------------------------> routine qui affiche le Bitmap Editor
Bitmap_Editor
	lea BitmapWindow_struct(pc),a0		ouvre la fenetre avec tous
	move.l _IntuitionBase(pc),a6		ses gadgets
	CALL OpenWindow
	move.l d0,Bitmap_handle-data_base(a5)
	beq Msg_handler

	move.l d0,a0
	move.l wd_RPort(a0),a3
	move.l a3,Bitmap_RastPort-data_base(a5)	récupère le RastPort et le
	move.l wd_UserPort(a0),Bitmap_UserPort-data_base(a5)	UserPort de la fenetre

	moveq #16,d0				affiche le busy sprite
	moveq #16,d1
	moveq #-6,d2
	moveq #0,d3
	lea Busy_Spr,a1
	CALL SetPointer

	moveq #3,d0				met 2 carrés bleue pour le boot
	move.l a3,a1
	move.l _GfxBase(pc),a6
	CALL SetAPen
	moveq #29,d0
	moveq #32,d1
	moveq #34,d2
	moveq #43,d3
	move.l a3,a1	
	CALL RectFill

	moveq #2,d0				couleur blanche
	move.l a3,a1
	CALL SetAPen
	moveq #32,d3
	moveq #22-1,d4
draw_white_horiz
	moveq #29,d0
	move.l d3,d1
	move.l a3,a1
	CALL Move
	move.l #508,d0
	move.l d3,d1
	move.l a3,a1
	CALL Draw
	addq.l #6,d3
	dbf d4,draw_white_horiz

	moveq #1,d0				couleur noire
	move.l a3,a1
	CALL SetAPen
	moveq #32+5,d3
	moveq #22-1,d4
draw_black_horiz
	moveq #29,d0
	move.l d3,d1
	move.l a3,a1
	CALL Move
	move.l #508,d0
	move.l d3,d1
	move.l a3,a1
	CALL Draw
	addq.l #6,d3
	dbf d4,draw_black_horiz

	moveq #2,d0				couleur blanche
	move.l a3,a1
	CALL SetAPen
	moveq #29,d3
	moveq #80-1,d4
draw_white_vert
	move.l d3,d0
	moveq #32,d1
	move.l a3,a1
	CALL Move
	move.l d3,d0
	move.l #163,d1
	move.l a3,a1
	CALL Draw
	addq.l #6,d3
	dbf d4,draw_white_vert

	moveq #1,d0				couleur blanche
	move.l a3,a1
	CALL SetAPen
	moveq #29+5,d3
	moveq #80-1,d4
draw_black_vert
	move.l d3,d0
	moveq #32,d1
	move.l a3,a1
	CALL Move
	move.l d3,d0
	move.l #163,d1
	move.l a3,a1
	CALL Draw
	addq.l #6,d3
	dbf d4,draw_black_vert

*-----------------> affichage des encadrements blancs
	moveq #2,d0				couleur blanche
	move.l a3,a1
	CALL SetAPen

	lea BitmapLines(pc),a4
	moveq #2*lr_Lines-1,d7
put_Bitmap_Lines1
	movem.l (a4)+,d0-d1			ici on affiche les boites
	move.l a3,a1
	CALL Move				qui encadrent les textes
	movem.l (a4)+,d0-d1
	move.l a3,a1
	CALL Draw
	dbf d7,put_Bitmap_Lines1

*-----------------> affiche les encadrements noirs + tirets sous les lettres
	moveq #1,d0				couleur noire
	move.l a3,a1
	CALL SetAPen

	moveq #4+2*lr_Lines-1,d7
put_Bitmap_Lines2
	movem.l (a4)+,d0-d1			ici on affiche les boites
	move.l a3,a1
	CALL Move				qui encadrent les textes
	movem.l (a4)+,d0-d1			+ tirets sous les lettres
	move.l a3,a1
	CALL Draw
	dbf d7,put_Bitmap_Lines2

	move.l TD_Buffer(pc),a0			efface le buffer pour stocker
	moveq #-1,d0				le Bitmap
	moveq #128-1,d1
clear_Bitmap_Buffer
	move.l d0,(a0)+
	dbf d1,clear_Bitmap_Buffer

	clr.b Click_Mode-data_base(a5)
	move.w #$ff00,Bitmap_Option-data_base(a5)	affiche option & valid
	bsr Bitmap_Set_Option
	bsr Bitmap_Set_Valid

	moveq #28,d3				affiche les # de pistes
	moveq #8-1,d4
	move.b #"0",Code_Buffer-data_base(a5)
loop_display_track_number
	move.l d3,d0
	moveq #29,d1
	move.l Bitmap_RastPort(pc),a1
	CALL Move
	moveq #1,d0
	lea Code_Buffer(pc),a0
	move.l Bitmap_RastPort(pc),a1
	CALL Text
	add.l #60,d3
	addq.b #1,Code_Buffer-data_base(a5)
	dbf d4,loop_display_track_number

	moveq #38,d3				affiche les # de secteurs
	moveq #2-1,d7
	moveq #0,d5
	moveq #6-1,d4
loop_display_sector_number
	moveq #11,d0
	move.l d3,d1
	move.l Bitmap_RastPort(pc),a1
	CALL Move
	move.l d5,d6
	divu #10,d6
	add.b #"0",d6
	move.b d6,Code_Buffer-data_base(a5)
	swap d6
	add.b #"0",d6
	move.b d6,Code_Buffer+1-data_base(a5)
	moveq #2,d0
	lea Code_Buffer(pc),a0
	move.l Bitmap_RastPort(pc),a1
	CALL Text
	add.l #12,d3
	addq.w #2,d5
	dbf d4,loop_display_sector_number
	moveq #1,d5
	moveq #5-1,d4
	dbf d7,loop_display_sector_number

	clr.w Click_Mode-data_base(a5)		vire le click & toggle
	clr.w Block_Edit-data_base(a5)

	move.l Bitmap_handle(pc),a0
	move.l _IntuitionBase(pc),a6
	CALL ClearPointer

	bra Bitmap_Msg_Wait

Bitmap_Msg_Wait
	move.l Bitmap_UserPort(pc),a0
	move.l (_SysBase).w,a6
	CALL WaitPort				attend un Msg

	move.l Bitmap_UserPort(pc),a0
	CALL GetMsg				on récupère le message

	move.l d0,a1				ptr sur IntuiMessage
	move.l im_Class(a1),Classe_message-data_base(a5)	Class_message
	move.l im_IAddress(a1),Gadget_adr-data_base(a5)		gadget émeteur
	move.w im_Code(a1),Key_Pressed-data_base(a5)		touche pressée

	CALL ReplyMsg				retourne le Msg

	move.l Classe_message(pc),d0
	cmp.l #MOUSEBUTTONS,d0			un bouton de la souris ?
	beq Bitmap_Click
	cmp.l #MOUSEMOVE,d0			mouvement de la souris ?
	beq Display_Mouse
	cmp.l #GADGETUP,d0			c'est un gadget ?
	beq.s Bitmap_Gadget
	cmp.l #VANILLAKEY,d0			c'est une touche ?
	beq.s Bitmap_Key
	cmp.l #CLOSEWINDOW,d0			c'est CLOSE_GADGET ?
	bne.s Bitmap_Msg_Wait

*-----> on sort du Bitmap Editor
	move.l Bitmap_handle(pc),a0		ferme la fenetre
	move.l _IntuitionBase(pc),a6
	CALL CloseWindow
	
	bra Msg_handler

Bitmap_Gadget
	move.l Gadget_adr(pc),d0
	cmp.l #Bitmap_Gadget1,d0		READ ?
	beq Bitmap_Read
	cmp.l #Bitmap_Gadget2,d0		WRITE ?
	beq Bitmap_Write
	pea Bitmap_Msg_Wait(pc)
	cmp.l #Bitmap_Gadget3,d0		SELECT MODE ?
	beq Bitmap_Set_Option
	cmp.l #Bitmap_Gadget4,d0		VALID ?
	beq Bitmap_Set_Valid
	bra Bitmap_Msg_Wait

Bitmap_Key
	move.w Key_Pressed(pc),d0
	cmp.w #"r",d0
	beq Bitmap_Read
	cmp.w #"w",d0
	beq Bitmap_Write
	pea Bitmap_Msg_Wait(pc)
	cmp.w #"e",d0
	beq Bitmap_Set_Option
	cmp.w #"v",d0
	beq Bitmap_Set_Valid
	bra Bitmap_Msg_Wait

Bitmap_Click
	cmp.w #SELECTDOWN,Key_Pressed-data_base(a5)	LMB appuyé ?
	bne.s Bitmap_Click2
	move.b #$ff,Click_Mode-data_base(a5)
	bra set_the_block
Bitmap_Click2
	cmp.w #SELECTUP,Key_Pressed-data_base(a5)	LMB relaché ?
	bne.s Bitmap_Click3
	clr.b Click_Mode-data_base(a5)
	bra Bitmap_Msg_Wait
Bitmap_Click3
	cmp.w #MENUDOWN,Key_Pressed-data_base(a5)	RMB appuyé ?
	bne.s Bitmap_Click4
	move.b #$ff,Toggle_Mode-data_base(a5)
	bra set_the_block
Bitmap_Click4
	cmp.w #MENUUP,Key_Pressed-data_base(a5)		RMB relaché ?
	bne Bitmap_Msg_Wait
	clr.b Toggle_Mode-data_base(a5)
	bra Bitmap_Msg_Wait

Display_Mouse
	move.l Bitmap_RastPort(pc),a3
	moveq #3,d0
	move.l a3,a1
	move.l _GfxBase(pc),a6
	CALL SetAPen

	moveq #17,d0
	moveq #20,d1
	move.l a3,a1
	CALL Move

	lea FormatOut(pc),a0
	move.l Bitmap_handle(pc),a1
	move.w wd_MouseX(a1),d0			regarde si la souris est
	sub.w #29,d0				dans le tableau bitmap
	blt Mouse_is_Out
	cmp.w #80*6,d0
	bge Mouse_is_Out
	move.w wd_MouseY(a1),d1
	sub.w #32,d1
	blt Mouse_is_Out
	cmp.w #22*6,d1
	bge Mouse_is_Out

	divs #6,d0				0-79
	divs #6,d1				0-21
	lea FormatLower(pc),a0
	moveq #0,d2
	move.w d0,d2
	add.w d0,d0				passe en piste
	cmp.w #11,d1
	blt.s Side_Low
	lea FormatUpper(pc),a0
	bset #0,d0
	sub.w #11,d1
Side_Low
	divu #10,d2				init CYLINDER
	add.b #"0",d2
	move.b d2,9(a0)
	swap d2
	add.b #"0",d2
	move.b d2,10(a0)

	moveq #0,d2
	move.w d0,d2				init TRACK
	divu #100,d2
	add.b #"0",d2
	move.b d2,20(a0)
	clr.w d2
	swap d2
	divu #10,d2
	add.b #"0",d2
	move.b d2,21(a0)
	swap d2
	add.b #"0",d2
	move.b d2,22(a0)	
	
	moveq #0,d2
	move.w d1,d2				init SECTOR
	divu #10,d2
	add.b #"0",d2
	move.b d2,46(a0)
	swap d2
	add.b #"0",d2
	move.b d2,47(a0)	

	mulu #11,d0				init BLOCK
	add.w d1,d0
	ext.l d0
	cmp.w Block_Edit(pc),d0
	beq Bitmap_Msg_Wait
	move.w d0,Block_Edit-data_base(a5)
	divu #1000,d0
	add.b #"0",d0
	move.b d0,57(a0)
	clr.w d0
	swap d0
	divu #100,d0
	add.b #"0",d0
	move.b d0,58(a0)
	clr.w d0
	swap d0
	divu #10,d0
	add.b #"0",d0
	move.b d0,59(a0)
	swap d0
	add.b #"0",d0
	move.b d0,60(a0)
	bra.s Mouse_is_In
Mouse_is_Out
	clr.w Block_Edit-data_base(a5)
Mouse_is_In
	moveq #FormatSize,d0
	move.l a3,a1
	CALL Text

	moveq #1,d0
	move.l Bitmap_RastPort(pc),a1
	CALL SetAPen

	tst.w Click_Mode-data_base(a5)		on est en mode Click ?
	beq Bitmap_Msg_Wait

set_the_block
	cmp.w #2,Block_Edit-data_base(a5)	on est sur un block ?
	blt Bitmap_Msg_Wait

	moveq #3,d0
	moveq #0,d1
	tst.b Toggle_Mode-data_base(a5)
	beq.s normal_mode
	exg d0,d1
normal_mode
	tst.b Bitmap_Option-data_base(a5)
	beq.s set_box_color
	move.l d1,d0
set_box_color
	move.l Bitmap_RastPort(pc),a1
	move.l _GfxBase(pc),a6
	CALL SetAPen

	moveq #0,d0
	move.w Block_Edit(pc),d0
	move.l d0,d1
	divu #22,d0				recherche la piste
	mulu #6,d0
	add.w #29+1,d0				position sur les X
	divu #22,d1
	swap d1
	mulu #6,d1
	add.w #32+1,d1
	move.w d0,d2
	addq.w #3,d2
	move.w d1,d3
	addq.w #3,d3
	move.l Bitmap_RastPort(pc),a1		trace un carre
	CALL RectFill

	moveq #1,d0				remet couleur noire
	move.l Bitmap_RastPort(pc),a1
	CALL SetAPen

	moveq #0,d0				met le bit dans le bitmap
	move.w Block_Edit(pc),d0
	subq.w #2,d0
	divu #32,d0
	lsl.w #2,d0
	move.l TD_Buffer(pc),a0
	lea 4(a0,d0.w),a0
	move.l (a0),d1
	swap d0
	tst.b Bitmap_Option-data_base(a5)
	beq.s Clr_Bit
Set_Bit
	tst.b Toggle_Mode-data_base(a5)
	bne.s Clr_Bit2
Set_Bit2
	bset d0,d1
	move.l d1,(a0)
	bra Bitmap_Msg_Wait
Clr_Bit
	tst.b Toggle_Mode-data_base(a5)
	bne.s Set_Bit2
Clr_Bit2
	bclr d0,d1
	move.l d1,(a0)
	bra Bitmap_Msg_Wait

*--------------------------> routine qui lit le bitmap et l'affiche
Bitmap_Read
	moveq #16,d0				affiche le busy sprite
	moveq #16,d1
	moveq #-6,d2
	moveq #0,d3
	move.l Bitmap_handle(pc),a0
	lea Busy_Spr,a1
	move.l _IntuitionBase(pc),a6
	CALL SetPointer

	lea TD_Struct(pc),a1			vire le buffer du trackdisk
	move.w #CMD_CLEAR,IO_COMMAND(a1)
	move.l (_SysBase).w,a6
	CALL DoIO

	lea TD_Struct(pc),a1			regarde si ya un disk dans le
	move.w #TD_CHANGESTATE,IO_COMMAND(a1)	DF0:
	CALL DoIO
	lea TD_Struct(pc),a1
	tst.l IO_ACTUAL(a1)
	bne ReadBitmap_Error_No_Disk

	move.w #CMD_READ,IO_COMMAND(a1)		commande READ
	move.l TD_Buffer(pc),IO_DATA(a1)	adr du buffer en chip
	move.l #512,IO_LENGTH(a1)		2 blocks à lire
	move.l #880*512,IO_OFFSET(a1)		block 880 ( Root Block )
	CALL DoIO				lit les 2 blocks
	lea TD_Struct(pc),a1
	tst.b IO_ERROR(a1)
	bne ReadBitmap_Error_Read

	move.l TD_Buffer(pc),a0
	tst.l 312(a0)				regarde la validation du
	sne Valid_Bitmap-data_base(a5)		bitmap

	move.w #CMD_READ,IO_COMMAND(a1)		commande READ
	move.l TD_Buffer(pc),IO_DATA(a1)	adr du buffer en chip
	move.l #512,IO_LENGTH(a1)		2 blocks à lire
	move.l TD_Buffer(pc),a0
	move.l 316(a0),d0
	mulu #512,d0
	move.l d0,IO_OFFSET(a1)			lit le block bitmap
	CALL DoIO				lit les 2 blocks
	lea TD_Struct(pc),a1
	tst.b IO_ERROR(a1)
	bne ReadBitmap_Error_Read

	move.w #TD_MOTOR,IO_COMMAND(a1)
	clr.l IO_LENGTH(a1)
	CALL DoIO

	bsr.s Display_Bitmap
	bra Bitmap_Msg_Wait

*---------------------------> gestion des erreurs pour Read Bitmap
ReadBitmap_Error_No_Disk
	lea TextRequestStructure(pc),a3
	move.l #ReqTextDisk,trs_Text(a3)
	bra.s ReadBitmap_display_error

ReadBitmap_Error_Read
	lea TextRequestStructure(pc),a3
	move.l #ReqTextReadBitmapRead,trs_Text(a3)

ReadBitmap_display_error
	move.w #TD_MOTOR,IO_COMMAND(a1)		arrete le moteur
	clr.l IO_LENGTH(a1)
	CALL DoIO

	move.l a3,a0
	move.l _ReqBase(pc),a6
	CALL TextRequest

	pea Bitmap_Msg_Wait(pc)

*------------------------> affichage du bitmap
Display_Empty_Bitmap
	move.l TD_Buffer(pc),a0			efface le buffer pour stocker
	moveq #-1,d0				le Bitmap
	moveq #128-1,d1
reset_Bitmap_Buffer
	move.l d0,(a0)+
	dbf d1,reset_Bitmap_Buffer
	move.b #$ff,Valid_Bitmap-data_base(a5)

Display_Bitmap
	move.l Bitmap_RastPort(pc),a4		affiche "Redrawing..."
	moveq #3,d0
	move.l a4,a1
	move.l _GfxBase(pc),a6
	CALL SetAPen
	move.l #204,d0
	moveq #20,d1
	move.l a4,a1
	CALL Move
	lea Redrawing(pc),a0
	move.l a4,a1
	moveq #14,d0
	CALL Text

	move.l TD_Buffer(pc),a3
	addq.l #4,a3
	moveq #29+1,d4				position X
	moveq #32+6*2+1,d5			position Y
	moveq #32,d6				nb de bit à tester dans le long
	move.l (a3)+,d7
loop_display_colonne
	moveq #3,d0				met un block
	move.l a4,a1
	lsr.l #1,d7
	bcc.s busy_block
	moveq #0,d0				efface le block
busy_block
	CALL SetAPen

	move.l d4,d0
	move.l d5,d1
	move.l d0,d2
	addq.l #3,d2
	move.l d1,d3
	addq.l #3,d3
	move.l a4,a1
	CALL RectFill

	subq.w #1,d6
	bne.s not_next_long
	moveq #32,d6
	move.l (a3)+,d7
not_next_long
	addq.l #6,d5
	cmp.l #32+1+22*6,d5
	bne.s loop_display_colonne
	moveq #32+1,d5
	addq.l #6,d4
	cmp.l #29+1+80*6,d4
	bne.s loop_display_colonne

	moveq #0,d0
	move.l a4,a1
	CALL SetAPen
	move.l #204,d0				vire le "Redrawing..."
	moveq #11,d1
	move.l #316,d2
	moveq #20,d3
	move.l a4,a1
	CALL RectFill

	moveq #1,d0
	move.l a4,a1
	CALL SetAPen
	eor.b #$ff,Valid_Bitmap-data_base(a5)
	bsr Bitmap_Set_Valid

	move.l Bitmap_handle(pc),a0
	move.l _IntuitionBase(pc),a6
	CALL ClearPointer
	rts

*--------------------> rountine d'ecriture du bitmap
Bitmap_Write
	lea TextRequestSure(pc),a0		requester "Are U sure ?"
	move.l #ReqTextBitmapSure,trs_Text(a0)
	move.l _ReqBase(pc),a6
	CALL TextRequest
	tst.l d0
	beq Bitmap_Msg_Wait

	moveq #16,d0				affiche le busy sprite
	moveq #16,d1
	moveq #-6,d2
	moveq #0,d3
	move.l Bitmap_handle(pc),a0
	lea Busy_Spr,a1
	move.l _IntuitionBase(pc),a6
	CALL SetPointer

	move.l TD_Buffer(pc),a0			calcul le checksum du Bitmap
	move.l a0,a1
	moveq #0,d0
	move.l d0,(a1)
	moveq #128-1,d1
make_Bitmap_CheckSum
	sub.l (a1)+,d0
	dbf d1,make_Bitmap_CheckSum
	move.l d0,(a0)

*-------------------------------> lit le Root Block d'abord
	lea TD_Struct(pc),a1			vire le tampon du trackdisk
	move.w #CMD_CLEAR,IO_COMMAND(a1)
	move.l (_SysBase).w,a6
	CALL DoIO

	lea TD_Struct(pc),a1			regarde si ya un disk dans
	move.w #TD_CHANGESTATE,IO_COMMAND(a1)	DF0:
	CALL DoIO
	lea TD_Struct(pc),a1
	tst.l IO_ACTUAL(a1)
	bne WriteBitmap_Error_No_Disk

	move.w #TD_PROTSTATUS,IO_COMMAND(a1)	regarde si le disk est protégé
	CALL DoIO
	lea TD_Struct(pc),a1
	tst.l IO_ACTUAL(a1)
	bne WriteBitmap_Error_Protect

	move.w #CMD_READ,IO_COMMAND(a1)		commande READ
	move.l TD_Buffer(pc),a0
	lea 512(a0),a0
	move.l a0,IO_DATA(a1)			adr du buffer en chip
	move.l #512,IO_LENGTH(a1)		2 blocks à lire
	move.l #880*512,IO_OFFSET(a1)		block 880 ( Root Block )
	CALL DoIO				lit les 2 blocks
	lea TD_Struct(pc),a1
	tst.b IO_ERROR(a1)
	bne WriteBitmap_Error_Read

	move.l TD_Buffer(pc),a0
	clr.l 512+312(a0)			met l'EMFLAG
	tst.b Valid_Bitmap-data_base(a5)
	beq.s Bitmap_set_not_valid
	move.l #$ffffffff,512+312(a0)
Bitmap_set_not_valid

	lea 512(a0),a0				fait le CheckSum du Root Block
	move.l a0,a1
	moveq #0,d0
	move.l d0,20(a1)
	moveq #128-1,d1
make_Root_CheckSum
	sub.l (a0)+,d0
	dbf d1,make_Root_CheckSum
	move.l d0,20(a1)

	lea TD_Struct(pc),a1
	move.w #CMD_WRITE,IO_COMMAND(a1)	commande WRITE
	move.l TD_Buffer(pc),a0
	lea 512(a0),a0
	move.l a0,IO_DATA(a1)			adr du buffer en chip
	move.l #512,IO_LENGTH(a1)		1 Block
	move.l #880*512,IO_OFFSET(a1)		block 880 ( Root Block )
	CALL DoIO				écrit le Root Block
	lea TD_Struct(pc),a1
	tst.b IO_ERROR(a1)
	bne WriteBitmap_Error_Write

	move.w #CMD_WRITE,IO_COMMAND(a1)	commande WRITE
	move.l TD_Buffer(pc),a0
	move.l a0,IO_DATA(a1)			adr du buffer en chip
	move.l #512,IO_LENGTH(a1)		1 Block
	move.l 512+316(a0),d0
	mulu #512,d0
	move.l d0,IO_OFFSET(a1)			pointe le block Bitmap
	CALL DoIO				écrit le Root Block
	lea TD_Struct(pc),a1
	tst.b IO_ERROR(a1)
	bne WriteBitmap_Error_Write

	move.w #CMD_UPDATE,IO_COMMAND(a1)	commande UPDATE
	CALL DoIO				ecrit sur le disque

	lea TD_Struct(pc),a1			arrete le moteur
	move.w #TD_MOTOR,IO_COMMAND(a1)
	clr.l IO_LENGTH(a1)
	CALL DoIO

	move.l Bitmap_handle(pc),a0
	move.l _IntuitionBase(pc),a6
	CALL ClearPointer
	bra Bitmap_Msg_Wait	

*---------------------------> gestion des erreurs pour le Write Bitmap
WriteBitmap_Error_No_Disk
	lea TextRequestStructure(pc),a3
	move.l #ReqTextBitmapDisk,trs_Text(a3)
	bra.s WriteBitmap_display_error

WriteBitmap_Error_Protect
	lea TextRequestStructure(pc),a3
	move.l #ReqTextBitmapProtect,trs_Text(a3)
	bra.s WriteBitmap_display_error

WriteBitmap_Error_Read
	lea TextRequestStructure(pc),a3
	move.l #ReqTextBitmapRead,trs_Text(a3)
	bra.s WriteBitmap_display_error

WriteBitmap_Error_Write
	lea TextRequestStructure(pc),a3
	move.l #ReqTextBitmapWrite,trs_Text(a3)

WriteBitmap_display_error
	move.w #TD_MOTOR,IO_COMMAND(a1)			arrete le moteur
	clr.l IO_LENGTH(a1)
	CALL DoIO

	move.l Bitmap_handle(pc),a0
	move.l _IntuitionBase(pc),a6
	CALL ClearPointer

	move.l a3,a0
	move.l _ReqBase(pc),a6
	CALL TextRequest
	bra Bitmap_Msg_Wait

*--------------------> routine de selection du mode de fonctionnement du bitmap
Bitmap_Set_Option
	move.l #270,d0
	move.l #178,d1
	move.l Bitmap_RastPort(pc),a1
	move.l _GfxBase(pc),a6
	CALL Move
	
	lea BitmapAllocate(pc),a0
	eor.b #$ff,Bitmap_Option-data_base(a5)
	beq.s Bitmap_Option_Allocate
	lea BitmapFree(pc),a0
Bitmap_Option_Allocate
	moveq #15,d0
	move.l Bitmap_RastPort(pc),a1
	CALL Text
	rts

*-------------------------> changement de la validité
Bitmap_Set_Valid
	move.l #475,d0
	move.l #178,d1
	move.l Bitmap_RastPort(pc),a1
	move.l _GfxBase(pc),a6
	CALL Move

	lea BitmapYes(pc),a0
	eor.b #$ff,Valid_Bitmap-data_base(a5)
	bne.s Bitmap_is_Valid
	lea BitmapNo(pc),a0
Bitmap_is_Valid
	moveq #3,d0
	move.l Bitmap_RastPort(pc),a1
	CALL Text
	rts

*-------------------------> routine pour FORMAT
Format_Disk
	lea DiskName(pc),a0			efface le nom du disk
	moveq #32/4-1,d0
clear_string
	clr.b (a0)+
	dbf d0,clear_string

	lea GetString_Struct(pc),a0		demande le nom du disk
	move.l _ReqBase(pc),a6
	CALL NewGetString
	tst.l d0
	beq Msg_handler

	lea DiskName(pc),a0			recherche la taille du diskname
	lea 1(a0),a1
strlen	tst.b (a0)+
	bne.s strlen
	move.l a0,d0
	sub.l a1,d0
	beq Msg_handler

	lea -1(a1,d0.w),a1			met la chaine en BCPL
	lea 1(a1),a2
	move.w d0,d1
	subq.w #1,d1
move_string
	move.b -(a1),-(a2)
	dbf d1,move_string	
	move.b d0,(a1)	

	lea FormatWindow_struct(pc),a0		essait d'ouvrir la fenetre
	move.l _IntuitionBase(pc),a6
	CALL OpenWindow
	move.l d0,Format_handle-data_base(a5)
	beq Msg_handler
	move.l d0,a0
	move.l wd_RPort(a0),Format_RastPort-data_base(a5)

	moveq #16,d0				affiche le busy sprite
	moveq #16,d1
	moveq #-6,d2
	moveq #0,d3
	lea Busy_Spr,a1
	CALL SetPointer

	move.l Format_RastPort(pc),a3
	moveq #2,d0				couleur blanche
	move.l a3,a1
	move.l _GfxBase(pc),a6
	CALL SetAPen

	lea FormatLines(pc),a4
	moveq #lc_Lines-1,d7
draw_FormatLine1
	movem.l (a4)+,d0-d1
	move.l a3,a1
	CALL Move
	movem.l (a4)+,d0-d1
	move.l a3,a1
	CALL Draw
	dbf d7,draw_FormatLine1

	moveq #1,d0				couleur noire
	move.l a3,a1
	CALL SetAPen
	moveq #lc_Lines-1,d7
draw_FormatLine2
	movem.l (a4)+,d0-d1
	move.l a3,a1
	CALL Move
	movem.l (a4)+,d0-d1
	move.l a3,a1
	CALL Draw
	dbf d7,draw_FormatLine2

	move.l TD_Buffer(pc),a0			efface le buffer de formatage
	moveq #0,d0
	move.w #(11*512)/4-1,d1
clear_Format_Buffer
	move.l d0,(a0)+
	dbf d1,clear_Format_Buffer

	moveq #11,d6
	moveq #0,d7
	move.l Format_RastPort(pc),a3

	moveq #3,d0
	move.l a3,a1
	move.l _GfxBase(pc),a6
	CALL SetAPen

	lea TD_Struct(pc),a1			regarde si ya un disk dans
	move.w #TD_CHANGESTATE,IO_COMMAND(a1)	DF0:
	move.l (_SysBase).w,a6
	CALL DoIO
	lea TD_Struct(pc),a1
	tst.l IO_ACTUAL(a1)
	bne Format_Error_No_Disk

	move.w #TD_PROTSTATUS,IO_COMMAND(a1)	regarde si le disk est protégé
	CALL DoIO
	lea TD_Struct(pc),a1
	tst.l IO_ACTUAL(a1)
	bne Format_Error_Protect
do_Format
	move.l d6,d0				affiche une barre bleue
	moveq #16,d1
	move.l a3,a1
	move.l _GfxBase(pc),a6
	CALL Move
	move.l d6,d0
	moveq #26,d1
	move.l a3,a1
	CALL Draw

	moveq #1,d0
	move.l a3,a1
	CALL SetAPen
	move.l d6,d0				affiche Formating xx
	sub.l #11,d0
	lsr.w #2,d0
	divu #10,d0
	add.b #"0",d0
	move.b d0,Formating+10-data_base(a5)
	swap d0
	add.b #"0",d0
	move.b d0,Formating+11-data_base(a5)	
	moveq #122,d0
	moveq #39,d1
	move.l a3,a1
	CALL Move
	lea Formating(pc),a0
	move.l a3,a1
	moveq #12,d0
	CALL Text	
	addq.w #1,d6

	lea TD_Struct(pc),a1			format la piste
	move.w #TD_FORMAT,IO_COMMAND(a1)
	move.l TD_Buffer(pc),IO_DATA(a1)
	move.l #11*512,IO_LENGTH(a1)
	move.l d7,IO_OFFSET(a1)
	move.l (_SysBase).w,a6
	CALL DoIO
	lea TD_Struct(pc),a1
	tst.b IO_ERROR(a1)
	bne Format_Error_Write

	moveq #122,d0				affiche Verifying
	moveq #39,d1
	move.l a3,a1
	move.l _GfxBase(pc),a6
	CALL Move
	lea Verifying(pc),a0
	move.l a3,a1
	moveq #6,d0
	CALL Text	

	moveq #3,d0				met une barre en plus
	move.l a3,a1
	CALL SetAPen
	move.l d6,d0
	moveq #16,d1
	move.l a3,a1
	CALL Move
	move.l d6,d0
	moveq #26,d1
	move.l a3,a1
	CALL Draw

	lea TD_Struct(pc),a1			relit la piste
	move.w #CMD_READ,IO_COMMAND(a1)
	move.l TD_Buffer(pc),IO_DATA(a1)
	move.l #11*512,IO_LENGTH(a1)
	move.l d7,IO_OFFSET(a1)
	move.l (_SysBase).w,a6
	CALL DoIO
	lea TD_Struct(pc),a1			erreur ?
	tst.b IO_ERROR(a1)
	bne Format_Error_Verify

	addq.w #1,d6
	add.l #11*512,d7
	cmp.l #160*11*512,d7
	bne do_Format

	moveq #1,d0
	move.l a3,a1
	move.l _GfxBase(pc),a6
	CALL SetAPen
	moveq #122,d0				affiche Intializing
	moveq #39,d1
	move.l a3,a1
	CALL Move

	lea Initializing(pc),a0
	move.l Format_RastPort(pc),a1
	moveq #12,d0
	CALL Text	

*------------> on prépare le boot
	move.l TD_Buffer(pc),a0
	move.l #"DOS"<<8,(a0)
	move.w #880,10(a0)

	lea TD_Struct(pc),a1			ecrit le boot
	move.w #CMD_WRITE,IO_COMMAND(a1)
	move.l a0,IO_DATA(a1)
	clr.l IO_OFFSET(a1)
	move.l #512,IO_LENGTH(a1)
	move.l (_SysBase).w,a6
	CALL DoIO
	lea TD_Struct(pc),a1
	tst.b IO_ERROR(a1)
	bne Format_Error_Write

	move.l #DateStampBuffer,d1		va chercher la date actuelle
	move.l _DosBase(pc),a6
	CALL DateStamp
	
	move.l TD_Buffer(pc),a2
	clr.w 10(a2)
	move.l #2,(a2)				type : T.SHORT	
	move.w #72,14(a2)			taille du HashTable
	moveq #-1,d0
	move.l d0,312(a2)			EMFLAG mis => bitmap valide
	move.w #1,510(a2)			type : ST.ROOT

	lea DiskName(pc),a0			met le nom du disk
	lea 432(a2),a1
	moveq #0,d0
	move.b (a0),d0
put_disk_name
	move.b (a0)+,(a1)+
	dbf d0,put_disk_name

	lea DateStampBuffer(pc),a0		met la date dans le root block
	lea 420(a2),a3
	moveq #3-1,d0
put_date
	move.l (a0)+,d1
	move.l d1,(a3)+
	move.l d1,484-(420+4)(a3)
	dbf d0,put_date

*---------------> fabrication du bitmap
	move.w #881,318(a2)			position du block bitmap
	move.l #$c000c037,512(a2)		checksum du bitmap
	lea 512+4(a2),a3
	moveq #-1,d0
	moveq #55-1,d1				le bitmap tient dans 55 LONG
loop_init_bitmap
	move.l d0,(a3)+
	dbf d1,loop_init_bitmap
	move.w #$3fff,626(a2)			reserve le Boot et le Bitmap
	move.w #$3fff,732(a2)			vire s'kia en trop

*----------------------> checksum du Root Block
	move.l a2,a3
	moveq #0,d0				checksum du Root Block
	move.l d0,20(a2)
	moveq #128-1,d1
compute_checksum1
	sub.l (a3)+,d0
	dbf d1,compute_checksum1
	move.l d0,20(a2)

	lea TD_Struct(pc),a1
	move.w #CMD_WRITE,IO_COMMAND(a1)
	move.l a2,IO_DATA(a1)
	move.l #880*512,IO_OFFSET(a1)
	move.l #2*512,IO_LENGTH(a1)
	move.l (_SysBase).w,a6
	CALL DoIO
	lea TD_Struct(pc),a1
	tst.b IO_ERROR(a1)
	bne Format_Error_Write

	lea TD_Struct(pc),a1
	move.w #CMD_UPDATE,IO_COMMAND(a1)	on update la piste
	CALL DoIO

	lea TD_Struct(pc),a1
	move.w #TD_MOTOR,IO_COMMAND(a1)		eteint le moteur
	clr.l IO_LENGTH(a1)
	CALL DoIO

	move.l Format_handle(pc),a0		ferme la fenetre
	move.l _IntuitionBase(pc),a6
	CALL CloseWindow
	bra Msg_handler

*-----------------------> gestion des erreurs du format
Format_Error_No_Disk
	lea TextRequestStructure(pc),a3
	move.l #ReqTextFormatDisk,trs_Text(a3)
	bra.s Format_display_error

Format_Error_Protect
	lea TextRequestStructure(pc),a3
	move.l #ReqTextFormatProtect,trs_Text(a3)
	bra.s Format_display_error

Format_Error_Write
	lea TextRequestStructure(pc),a3
	move.l #ReqTextFormatWrite,trs_Text(a3)
	bra.s Format_display_error

Format_Error_Verify
	lea TextRequestStructure(pc),a3
	move.l #ReqTextFormatVerify,trs_Text(a3)

Format_display_error
	move.w #TD_MOTOR,IO_COMMAND(a1)		arrete le moteur
	clr.l IO_LENGTH(a1)
	CALL DoIO

	move.l Format_handle(pc),a0		ferme la fenetre
	move.l _IntuitionBase(pc),a6
	CALL CloseWindow

	move.l a3,a0
	move.l _ReqBase(pc),a6
	CALL TextRequest
	bra Msg_handler

*-------------------------> routine qui affiche le ABOUT
About
	lea TextRequestStructure(pc),a0
	move.l #ReqTextAbout,trs_Text(a0)
	move.l #TextReqTitleAbout,trs_Title(a0)
	move.l _ReqBase(pc),a6
	CALL TextRequest
	lea TextRequestStructure(pc),a0
	move.l #TextReqTitle,trs_Title(a0)
	bra Msg_handler

*-------------------------> Iconize la fenetre
Iconize
	move.l Window_handle(pc),a0		handle de la fenetre
	move.l wd_LeftEdge(a0),Window_struct-data_base(a5)
	move.l _IntuitionBase(pc),a6
	CALL CloseWindow			et on la ferme
	
	lea Iconize_Window(pc),a0		ouvre la fenetre iconize
	CALL OpenWindow
	move.l d0,Iconize_handle-data_base(a5)
	beq Free_Memory				si erreur on sort

	move.l d0,a0
	move.l wd_UserPort(a0),Iconize_UserPort-data_base(a5)

	moveq #16,d0				affiche le busy sprite
	moveq #16,d1
	moveq #-6,d2
	moveq #0,d3
	lea Busy_Spr,a1
	CALL SetPointer

	move.l Iconize_UserPort(pc),a0		attend un Msg
	move.l (_SysBase).w,a6
	CALL WaitPort
	move.l Iconize_UserPort(pc),a0
	CALL GetMsg
	
	move.l d0,a1				ptr sur IntuiMessage
	move.l im_Class(a1),Classe_message-data_base(a5)	Class_message

	CALL ReplyMsg
	
	move.l Iconize_handle(pc),a0		handler de la fenêtre
	move.l _IntuitionBase(pc),a6
	CALL ClearPointer

	move.l Iconize_handle(pc),a0
	move.l wd_LeftEdge(a0),Iconize_Window-data_base(a5)	position fenetre
	CALL CloseWindow			et on la ferme

	cmp.l #MENUPICK,Classe_message-data_base(a5)	bouton droit souris ?
	beq Draw_FTB_Window			on réouvre la fenêtre
	bra Close_Device			c'est CLOSEWINDOW => on sort

*-------------------------> routine appelée quand le gadget lock est appuyé
DF0_Locker_Key
	bchg #7,Gadget11+gg_Flags+1-data_base(a5)
	sne DF0_Status-data_base(a5)		set en inverse car suite !!
	lea Gadget11(pc),a0
	move.l Window_handle(pc),a1
	sub.l a2,a2
	move.l _IntuitionBase(pc),a6
	CALL RefreshGadgets

DF0_Locker
	pea Msg_handler(pc)
	eor.b #$ff,DF0_Status-data_base(a5)
	beq.s Unlock_DF0

*-------------------------> routine qui lock le DF0:
Lock_DF0
	move.l (_SysBase).w,a4			ptr Task
	move.l ThisTask(a4),a4
	lea pr_MsgPort(a4),a4			pointe le MsgPort
	move.l a4,DosPacket2+dp_Port-data_base(a5)
	moveq #-1,d0
	move.l d0,DosPacket2+dp_Arg1-data_base(a5)

	move.l #DF0_Name,d1			recherche MsgPort du DF0:
	move.l _DosBase(pc),a6
	CALL DeviceProc

	move.l d0,a0				balance le Msg
	lea StandardPacket2(pc),a1
	move.l (_SysBase).w,a6
	CALL PutMsg

	move.l a4,a0				attend le Msg en retour
	CALL WaitPort

	move.l a4,a0				récupère le Msg
	CALL GetMsg
	rts

*-------------------------> routine qui unlock le DF0:
Unlock_DF0
	move.l (_SysBase).w,a4			ptr Task
	move.l ThisTask(a4),a4
	lea pr_MsgPort(a4),a4			pointe le MsgPort
	move.l a4,DosPacket2+dp_Port-data_base(a5)
	clr.l DosPacket2+dp_Arg1-data_base(a5)

	move.l #DF0_Name,d1			recherche MsgPort du DF0:
	move.l _DosBase(pc),a6
	CALL DeviceProc

	move.l d0,a0				balance le Msg
	lea StandardPacket2(pc),a1
	move.l (_SysBase).w,a6
	CALL PutMsg

	move.l a4,a0				attend le Msg en retour
	CALL WaitPort

	move.l a4,a0				récupère le Msg
	CALL GetMsg
	rts

*------------------------> transforme un LONG en ASCII pour 4 digits decimaux
Long_To_Ascii
	divu #1000,d0				méthode "gros boeuf" mais qui
	add.b #"0",d0				marche bien !
	move.b d0,(a0)+
	clr.w d0
	swap d0
	divu #100,d0
	add.b #"0",d0
	move.b d0,(a0)+
	clr.w d0
	swap d0
	divu #10,d0
	add.b #"0",d0
	move.b d0,(a0)+
	clr.w d0
	swap d0
	add.b #"0",d0
	move.b d0,(a0)
	rts

data_base
_IntuitionBase		dc.l 0
_GfxBase		dc.l 0
_DosBase		dc.l 0
_ReqBase		dc.l 0
TD_Buffer		dc.l 0
RastPort_wd		dc.l 0
UserPort		dc.l 0
Window_handle		dc.l 0
Iconize_handle		dc.l 0
Iconize_UserPort	dc.l 0
Bitmap_handle		dc.l 0
Bitmap_RastPort		dc.l 0
Bitmap_UserPort		dc.l 0
Format_handle		dc.l 0
Format_RastPort		dc.l 0
Classe_message		dc.l 0
Gadget_adr		dc.l 0
Key_Pressed		dc.w 0
Drive_Start		dc.l 0
Drive_Stop		dc.l 1759
Drive_Current		dc.l 0
Bitmap_Option		dc.b 0
Valid_Bitmap		dc.b 0
Click_Mode		dc.b 0
Toggle_Mode		dc.b 0
DF0_Status		dc.b 0
Option_Number		dc.b 0
Block_Edit		dc.w 0
Code_Buffer		dc.l 0
FileSize		dc.l 0
_SegList		dc.l 0
FTB_pr_WindowPtr	dc.l 0
DateStampBuffer		dcb.l 3,0

			*******************************
			* STRUCTURE POUR LE TRACKDISK *
			*******************************
TD_Struct
	dc.l 0				LN_SUCC
	dc.l 0				LN_PRED
	dc.b NT_DEVICE			LN_TYPE
	dc.b 0				LN_PRI
	dc.l 0				LN_NAME
	dc.l Reply_Port			MN_REPLYPORT
	dc.l 0				IO_DEVICE
	dc.l 0				IO_UNIT
	dc.w 0				IO_COMMAND
	dc.b 0				IO_FLAGS
	dc.b 0				IO_ERROR
	dc.w 0				IO_SIZE
	dc.l 0				IO_ACTUAL
	dc.l 0				IO_LENGTH
	dc.l 0				IO_DATA
	dc.l 0				IO_OFFSET
	dc.l 0				IOTD_COUNT
	dc.l 0				IOTD_SECLABEL
Reply_Port
	dc.l 0				LN_SUCC
	dc.l 0				LN_PRED
	dc.b NT_REPLYMSG		LN_TYPE
	dc.b 0				LN_PRI
	dc.l Reply_Port_Name		LN_NAME
	dc.b 0				MP_FLAGS
	dc.b 0				MP_SIGBIT
	dc.l 0				MP_SIGTASK
	dc.l 0				LH_HEAD
	dc.l 0				LH_TAIL
	dc.l 0				LH_TAILPRED
	dc.b NT_REPLYMSG		LH_TYPE
	dc.b 0				LH_PAD	

			********************************
			* STRUCTURE POUR LE DOS PACKET *
			********************************
	cnop 0,4
StandardPacket2
	dc.l 0				LN_SUCC
	dc.l 0				LN_PRED
	dc.b 0				LN_TYPE
	dc.b 0				LN_PRI	
	dc.l DosPacket2			LN_NAME
	dc.l 0				MN_REPLYPORT
	dc.w 0				MN_LENGTH
DosPacket2
	dc.l StandardPacket2		dp_Link
	dc.l 0				dp_Port
	dc.l ACTION_INHIBIT		dp_Type
	dc.l 0				dp_Res1
	dc.l 0				dp_Res2
	dc.l -1				dp_Arg1
	dc.l 0				dp_Arg2
	dc.l 0				dp_Arg3
	dc.l 0				dp_Arg4
	dc.l 0				dp_Arg5
	dc.l 0				dp_Arg6
	dc.l 0				dp_Arg7

			*******************************
			* STRUCTURE POUR LES FENETRES *
			*******************************	

Window_struct
	dc.w 131			nw_LeftEdge
	dc.w 50				TopEdge
	dc.w 379			Width
	dc.w 136			Height
	dc.b 2				DetailPen
	dc.b 1				BlockPen
	dc.l CLOSEWINDOW|GADGETUP|VANILLAKEY	IDCMPFlags
	dc.l SMART_REFRESH|NOCAREREFRESH|ACTIVATE|WINDOWCLOSE|WINDOWDEPTH|WINDOWDRAG|RMBTRAP	Flags
	dc.l Gadget1			FirstGadget
	dc.l 0				CheckMark
	dc.l WindowName			Title
	dc.l 0				Screen
	dc.l 0				BitMap
	dc.w 200			MinWidth
	dc.w 110			MinHeight
	dc.w 320			MaxWidth
	dc.w 256			MaxHeight
	dc.w WBENCHSCREEN		Type

Gadget1
	dc.l Gadget2			gg_NextGadget
	dc.w 14				LeftEdge
	dc.w 17				TopEdge
	dc.w 95				Width
	dc.w 15				Height
	dc.w 0				Flags
	dc.w RELVERIFY			Activation
	dc.w BOOLGADGET			GadgetType
	dc.l .Border			GadgetRender
	dc.l 0				SelectRender
	dc.l .IntuiText			GadgetText
	dc.l 0				MutualExclude
	dc.l 0				SpecialInfo
	dc.w 0				gadgetID
	dc.l 0				UserData
.Border
	dc.w -1				bd_LeftEdge
	dc.w -1				TopEdge
	dc.b 2				FrontPen
	dc.b 0				BackPen
	dc.b RP_JAM1			DrawMode
	dc.b 5				Count
	dc.l .Cadre			XY
	dc.l .BorderNext		NextBorder
.Cadre
	Border_White 1,1,95,15
.BorderNext
	dc.w -1				bd_LeftEdge
	dc.w -1				TopEdge
	dc.b 1				FrontPen
	dc.b 0				BackPen
	dc.b RP_JAM1			DrawMode
	dc.b 5				Count
	dc.l .CadreNext			XY
	dc.l 0				NextBorder
.CadreNext
	Border_Black 1,1,95,15
.IntuiText
	dc.b 3				it_FrontPen
	dc.b 0				BackPen
	dc.b RP_JAM2			DrawMode
	dc.b 0				KludgeFill00
	dc.w 4				LeftEdge
	dc.w 4				TopEdge
	dc.l 0				ITextFont
	dc.l Text1			Itext
	dc.l 0				NextText

Gadget2
	dc.l Gadget3			gg_NextGadget
	dc.w 14				LeftEdge
	dc.w 39				TopEdge
	dc.w 95				Width
	dc.w 15				Height
	dc.w 0				Flags
	dc.w RELVERIFY			Activation
	dc.w BOOLGADGET			GadgetType
	dc.l .Border			GadgetRender
	dc.l 0				SelectRender
	dc.l .IntuiText			GadgetText
	dc.l 0				MutualExclude
	dc.l 0				SpecialInfo
	dc.w 0				gadgetID
	dc.l 0				UserData
.Border
	dc.w -1				bd_LeftEdge
	dc.w -1				TopEdge
	dc.b 2				FrontPen
	dc.b 0				BackPen
	dc.b RP_JAM1			DrawMode
	dc.b 5				Count
	dc.l .Cadre			XY
	dc.l .BorderNext		NextBorder
.Cadre
	Border_White 1,1,95,15
.BorderNext
	dc.w -1				bd_LeftEdge
	dc.w -1				TopEdge
	dc.b 1				FrontPen
	dc.b 0				BackPen
	dc.b RP_JAM1			DrawMode
	dc.b 5				Count
	dc.l .CadreNext			XY
	dc.l 0				NextBorder
.CadreNext
	Border_Black 1,1,95,15
.IntuiText
	dc.b 3				it_FrontPen
	dc.b 0				BackPen
	dc.b RP_JAM2			DrawMode
	dc.b 0				KludgeFill00
	dc.w 4				LeftEdge
	dc.w 4				TopEdge
	dc.l 0				ITextFont
	dc.l Text2			Itext
	dc.l 0				NextText

Gadget3
	dc.l Gadget4			gg_NextGadget
	dc.w 195			LeftEdge
	dc.w 39				TopEdge
	dc.w 95				Width
	dc.w 15				Height
	dc.w 0				Flags
	dc.w RELVERIFY			Activation
	dc.w BOOLGADGET			GadgetType
	dc.l .Border			GadgetRender
	dc.l 0				SelectRender
	dc.l .IntuiText			GadgetText
	dc.l 0				MutualExclude
	dc.l 0				SpecialInfo
	dc.w 0				gadgetID
	dc.l 0				UserData
.Border
	dc.w -1				bd_LeftEdge
	dc.w -1				TopEdge
	dc.b 2				FrontPen
	dc.b 0				BackPen
	dc.b RP_JAM1			DrawMode
	dc.b 5				Count
	dc.l .Cadre			XY
	dc.l .BorderNext		NextBorder
.Cadre
	Border_White 1,1,95,15
.BorderNext
	dc.w -1				bd_LeftEdge
	dc.w -1				TopEdge
	dc.b 1				FrontPen
	dc.b 0				BackPen
	dc.b RP_JAM1			DrawMode
	dc.b 5				Count
	dc.l .CadreNext			XY
	dc.l 0				NextBorder
.CadreNext
	Border_Black 1,1,95,15
.IntuiText
	dc.b 3				it_FrontPen
	dc.b 0				BackPen
	dc.b RP_JAM2			DrawMode
	dc.b 0				KludgeFill00
	dc.w 13				LeftEdge
	dc.w 4				TopEdge
	dc.l 0				ITextFont
	dc.l Text3			Itext
	dc.l 0				NextText

Gadget4
	dc.l Gadget5			gg_NextGadget
	dc.w 14				LeftEdge
	dc.w 61				TopEdge
	dc.w 95				Width
	dc.w 15				Height
	dc.w 0				Flags
	dc.w RELVERIFY			Activation
	dc.w BOOLGADGET			GadgetType
	dc.l .Border			GadgetRender
	dc.l 0				SelectRender
	dc.l .IntuiText			GadgetText
	dc.l 0				MutualExclude
	dc.l 0				SpecialInfo
	dc.w 0				gadgetID
	dc.l 0				UserData
.Border
	dc.w -1				bd_LeftEdge
	dc.w -1				TopEdge
	dc.b 2				FrontPen
	dc.b 0				BackPen
	dc.b RP_JAM1			DrawMode
	dc.b 5				Count
	dc.l .Cadre			XY
	dc.l .BorderNext		NextBorder
.Cadre
	Border_White 1,1,95,15
.BorderNext
	dc.w -1				bd_LeftEdge
	dc.w -1				TopEdge
	dc.b 1				FrontPen
	dc.b 0				BackPen
	dc.b RP_JAM1			DrawMode
	dc.b 5				Count
	dc.l .CadreNext			XY
	dc.l 0				NextBorder
.CadreNext
	Border_Black 1,1,95,15
.IntuiText
	dc.b 3				it_FrontPen
	dc.b 0				BackPen
	dc.b RP_JAM2			DrawMode
	dc.b 0				KludgeFill00
	dc.w 4				LeftEdge
	dc.w 4				TopEdge
	dc.l 0				ITextFont
	dc.l Text4			Itext
	dc.l 0				NextText

Gadget5
	dc.l Gadget6			gg_NextGadget
	dc.w 14				LeftEdge
	dc.w 113			TopEdge
	dc.w 48				Width
	dc.w 15				Height
	dc.w 0				Flags
	dc.w RELVERIFY			Activation
	dc.w BOOLGADGET			GadgetType
	dc.l .Border			GadgetRender
	dc.l 0				SelectRender
	dc.l .IntuiText			GadgetText
	dc.l 0				MutualExclude
	dc.l 0				SpecialInfo
	dc.w 0				gadgetID
	dc.l 0				UserData
.Border
	dc.w -1				bd_LeftEdge
	dc.w -1				TopEdge
	dc.b 2				FrontPen
	dc.b 0				BackPen
	dc.b RP_JAM1			DrawMode
	dc.b 5				Count
	dc.l .Cadre			XY
	dc.l .BorderNext		NextBorder
.Cadre
	Border_White 1,1,48,15
.BorderNext
	dc.w -1				bd_LeftEdge
	dc.w -1				TopEdge
	dc.b 1				FrontPen
	dc.b 0				BackPen
	dc.b RP_JAM1			DrawMode
	dc.b 5				Count
	dc.l .CadreNext			XY
	dc.l 0				NextBorder
.CadreNext
	Border_Black 1,1,48,15
.IntuiText
	dc.b 3				it_FrontPen
	dc.b 0				BackPen
	dc.b RP_JAM2			DrawMode
	dc.b 0				KludgeFill00
	dc.w 4				LeftEdge
	dc.w 4				TopEdge
	dc.l 0				ITextFont
	dc.l Text5			Itext
	dc.l 0				NextText

Gadget6
	dc.l Gadget7			gg_NextGadget
	dc.w 71				LeftEdge
	dc.w 113			TopEdge
	dc.w 39				Width
	dc.w 15				Height
	dc.w 0				Flags
	dc.w RELVERIFY			Activation
	dc.w BOOLGADGET			GadgetType
	dc.l .Border			GadgetRender
	dc.l 0				SelectRender
	dc.l .IntuiText			GadgetText
	dc.l 0				MutualExclude
	dc.l 0				SpecialInfo
	dc.w 0				gadgetID
	dc.l 0				UserData
.Border
	dc.w -1				bd_LeftEdge
	dc.w -1				TopEdge
	dc.b 2				FrontPen
	dc.b 0				BackPen
	dc.b RP_JAM1			DrawMode
	dc.b 5				Count
	dc.l .Cadre			XY
	dc.l .BorderNext		NextBorder
.Cadre
	Border_White 1,1,39,15
.BorderNext
	dc.w -1				bd_LeftEdge
	dc.w -1				TopEdge
	dc.b 1				FrontPen
	dc.b 0				BackPen
	dc.b RP_JAM1			DrawMode
	dc.b 5				Count
	dc.l .CadreNext			XY
	dc.l 0				NextBorder
.CadreNext
	Border_Black 1,1,39,15
.IntuiText
	dc.b 3				it_FrontPen
	dc.b 0				BackPen
	dc.b RP_JAM2			DrawMode
	dc.b 0				KludgeFill00
	dc.w 4				LeftEdge
	dc.w 4				TopEdge
	dc.l 0				ITextFont
	dc.l Text6			Itext
	dc.l 0				NextText

Gadget7
	dc.l Gadget8			gg_NextGadget
	dc.w 119			LeftEdge
	dc.w 113			TopEdge
	dc.w 55				Width
	dc.w 15				Height
	dc.w 0				Flags
	dc.w RELVERIFY			Activation
	dc.w BOOLGADGET			GadgetType
	dc.l .Border			GadgetRender
	dc.l 0				SelectRender
	dc.l .IntuiText			GadgetText
	dc.l 0				MutualExclude
	dc.l 0				SpecialInfo
	dc.w 0				gadgetID
	dc.l 0				UserData
.Border
	dc.w -1				bd_LeftEdge
	dc.w -1				TopEdge
	dc.b 2				FrontPen
	dc.b 0				BackPen
	dc.b RP_JAM1			DrawMode
	dc.b 5				Count
	dc.l .Cadre			XY
	dc.l .BorderNext		NextBorder
.Cadre
	Border_White 1,1,55,15
.BorderNext
	dc.w -1				bd_LeftEdge
	dc.w -1				TopEdge
	dc.b 1				FrontPen
	dc.b 0				BackPen
	dc.b RP_JAM1			DrawMode
	dc.b 5				Count
	dc.l .CadreNext			XY
	dc.l 0				NextBorder
.CadreNext
	Border_Black 1,1,55,15
.IntuiText
	dc.b 3				it_FrontPen
	dc.b 0				BackPen
	dc.b RP_JAM2			DrawMode
	dc.b 0				KludgeFill00
	dc.w 4				LeftEdge
	dc.w 4				TopEdge
	dc.l 0				ITextFont
	dc.l Text7			Itext
	dc.l 0				NextText

Gadget8
	dc.l Gadget9			gg_NextGadget
	dc.w 183			LeftEdge
	dc.w 113			TopEdge
	dc.w 55				Width
	dc.w 15				Height
	dc.w 0				Flags
	dc.w RELVERIFY			Activation
	dc.w BOOLGADGET			GadgetType
	dc.l .Border			GadgetRender
	dc.l 0				SelectRender
	dc.l .IntuiText			GadgetText
	dc.l 0				MutualExclude
	dc.l 0				SpecialInfo
	dc.w 0				gadgetID
	dc.l 0				UserData
.Border
	dc.w -1				bd_LeftEdge
	dc.w -1				TopEdge
	dc.b 2				FrontPen
	dc.b 0				BackPen
	dc.b RP_JAM1			DrawMode
	dc.b 5				Count
	dc.l .Cadre			XY
	dc.l .BorderNext		NextBorder
.Cadre
	Border_White 1,1,55,15
.BorderNext
	dc.w -1				bd_LeftEdge
	dc.w -1				TopEdge
	dc.b 1				FrontPen
	dc.b 0				BackPen
	dc.b RP_JAM1			DrawMode
	dc.b 5				Count
	dc.l .CadreNext			XY
	dc.l 0				NextBorder
.CadreNext
	Border_Black 1,1,55,15
.IntuiText
	dc.b 3				it_FrontPen
	dc.b 0				BackPen
	dc.b RP_JAM2			DrawMode
	dc.b 0				KludgeFill00
	dc.w 4				LeftEdge
	dc.w 4				TopEdge
	dc.l 0				ITextFont
	dc.l Text8			Itext
	dc.l 0				NextText

Gadget9
	dc.l Gadget10			gg_NextGadget
	dc.w 247			LeftEdge
	dc.w 113			TopEdge
	dc.w 61				Width
	dc.w 15				Height
	dc.w 0				Flags
	dc.w RELVERIFY			Activation
	dc.w BOOLGADGET			GadgetType
	dc.l .Border			GadgetRender
	dc.l 0				SelectRender
	dc.l .IntuiText			GadgetText
	dc.l 0				MutualExclude
	dc.l 0				SpecialInfo
	dc.w 0				gadgetID
	dc.l 0				UserData
.Border
	dc.w -1				bd_LeftEdge
	dc.w -1				TopEdge
	dc.b 2				FrontPen
	dc.b 0				BackPen
	dc.b RP_JAM1			DrawMode
	dc.b 5				Count
	dc.l .Cadre			XY
	dc.l .BorderNext		NextBorder
.Cadre
	Border_White 1,1,61,15
.BorderNext
	dc.w -1				bd_LeftEdge
	dc.w -1				TopEdge
	dc.b 1				FrontPen
	dc.b 0				BackPen
	dc.b RP_JAM1			DrawMode
	dc.b 5				Count
	dc.l .CadreNext			XY
	dc.l 0				NextBorder
.CadreNext
	Border_Black 1,1,61,15
.IntuiText
	dc.b 3				it_FrontPen
	dc.b 0				BackPen
	dc.b RP_JAM2			DrawMode
	dc.b 0				KludgeFill00
	dc.w 2				LeftEdge
	dc.w 4				TopEdge
	dc.l 0				ITextFont
	dc.l Text9			Itext
	dc.l 0				NextText

Gadget10
	dc.l Gadget11			gg_NextGadget
	dc.w 317			LeftEdge
	dc.w 113			TopEdge
	dc.w 48				Width
	dc.w 15				Height
	dc.w 0				Flags
	dc.w RELVERIFY			Activation
	dc.w BOOLGADGET			GadgetType
	dc.l .Border			GadgetRender
	dc.l 0				SelectRender
	dc.l .IntuiText			GadgetText
	dc.l 0				MutualExclude
	dc.l 0				SpecialInfo
	dc.w 0				gadgetID
	dc.l 0				UserData
.Border
	dc.w -1				bd_LeftEdge
	dc.w -1				TopEdge
	dc.b 2				FrontPen
	dc.b 0				BackPen
	dc.b RP_JAM1			DrawMode
	dc.b 5				Count
	dc.l .Cadre			XY
	dc.l .BorderNext		NextBorder
.Cadre
	Border_White 1,1,48,15
.BorderNext
	dc.w -1				bd_LeftEdge
	dc.w -1				TopEdge
	dc.b 1				FrontPen
	dc.b 0				BackPen
	dc.b RP_JAM1			DrawMode
	dc.b 5				Count
	dc.l .CadreNext			XY
	dc.l 0				NextBorder
.CadreNext
	Border_Black 1,1,48,15
.IntuiText
	dc.b 3				it_FrontPen
	dc.b 0				BackPen
	dc.b RP_JAM2			DrawMode
	dc.b 0				KludgeFill00
	dc.w 4				LeftEdge
	dc.w 4				TopEdge
	dc.l 0				ITextFont
	dc.l Text10			Itext
	dc.l 0				NextText

Gadget11
	dc.l 0				gg_NextGadget
	dc.w 317			LeftEdge
	dc.w 82				TopEdge
	dc.w 48				Width
	dc.w 25				Height
	dc.w GADGIMAGE|GADGHIMAGE	Flags
	dc.w TOGGLESELECT|RELVERIFY	Activation
	dc.w BOOLGADGET			GadgetType
	dc.l LockImage1			GadgetRender
	dc.l LockImage2			SelectRender
	dc.l 0				GadgetText
	dc.l 0				MutualExclude
	dc.l 0				SpecialInfo
	dc.w 0				gadgetID
	dc.l 0				UserData
LockImage1
	dc.w 0				ig_LeftEdge
	dc.w 0				TopEdge
	dc.w 48				Width
	dc.w 25				Height
	dc.w 2				Depth
	dc.l LockPic1			ImageData
	dc.b %11			PlanePick
	dc.b 0				PlanenOnOff
	dc.l 0				NextImage
LockImage2
	dc.w 0				ig_LeftEdge
	dc.w 0				TopEdge
	dc.w 48				Width
	dc.w 25				Height
	dc.w 2				Depth
	dc.l LockPic2			ImageData
	dc.b %11			PlanePick
	dc.b 0				PlaneOnOff
	dc.l 0				NextImage

Iconize_Window
	dc.w 131			nw_LeftEdge
	dc.w 50				TopEdge
	dc.w 200			Width
	dc.w 10				Height
	dc.b 2				DetailPen
	dc.b 1				BlockPen
	dc.l CLOSEWINDOW|MENUPICK	IDCMPFlags
	dc.l SMART_REFRESH|NOCAREREFRESH|ACTIVATE|WINDOWCLOSE|WINDOWDEPTH|WINDOWDRAG	Flags
	dc.l 0				FirstGadget
	dc.l 0				CheckMark
	dc.l IconizeName		Title
	dc.l 0				Screen
	dc.l 0				BitMap
	dc.w 200			MinWidth
	dc.w 110			MinHeight
	dc.w 320			MaxWidth
	dc.w 256			MaxHeight
	dc.w WBENCHSCREEN		Type

BitmapWindow_struct
	dc.w 60				nw_LeftEdge
	dc.w 30				TopEdge
	dc.w 520			Width
	dc.w 189			Height
	dc.b 2				DetailPen
	dc.b 1				BlockPen
	dc.l CLOSEWINDOW|GADGETUP|VANILLAKEY|MOUSEMOVE|MOUSEBUTTONS	IDCMPFlags
	dc.l SMART_REFRESH|REPORTMOUSE|NOCAREREFRESH|ACTIVATE|WINDOWCLOSE|WINDOWDEPTH|WINDOWDRAG|RMBTRAP	Flags
	dc.l Bitmap_Gadget1		FirstGadget
	dc.l 0				CheckMark
	dc.l BitmapName			Title
	dc.l 0				Screen
	dc.l 0				BitMap
	dc.w 200			MinWidth
	dc.w 110			MinHeight
	dc.w 320			MaxWidth
	dc.w 256			MaxHeight
	dc.w WBENCHSCREEN		Type

Bitmap_Gadget1
	dc.l Bitmap_Gadget2		gg_NextGadget
	dc.w 44				LeftEdge
	dc.w 168			TopEdge
	dc.w 47				Width
	dc.w 15				Height
	dc.w 0				Flags
	dc.w RELVERIFY			Activation
	dc.w BOOLGADGET			GadgetType
	dc.l .Border			GadgetRender
	dc.l 0				SelectRender
	dc.l .IntuiText			GadgetText
	dc.l 0				MutualExclude
	dc.l 0				SpecialInfo
	dc.w 0				gadgetID
	dc.l 0				UserData
.Border
	dc.w -1				bd_LeftEdge
	dc.w -1				TopEdge
	dc.b 2				FrontPen
	dc.b 0				BackPen
	dc.b RP_JAM1			DrawMode
	dc.b 5				Count
	dc.l .Cadre			XY
	dc.l .BorderNext		NextBorder
.Cadre
	Border_White 1,1,47,15
.BorderNext
	dc.w -1				bd_LeftEdge
	dc.w -1				TopEdge
	dc.b 1				FrontPen
	dc.b 0				BackPen
	dc.b RP_JAM1			DrawMode
	dc.b 5				Count
	dc.l .CadreNext			XY
	dc.l 0				NextBorder
.CadreNext
	Border_Black 1,1,47,15
.IntuiText
	dc.b 3				it_FrontPen
	dc.b 0				BackPen
	dc.b RP_JAM2			DrawMode
	dc.b 0				KludgeFill00
	dc.w 8				LeftEdge
	dc.w 4				TopEdge
	dc.l 0				ITextFont
	dc.l BitmapText1		Itext
	dc.l 0				NextText

Bitmap_Gadget2
	dc.l Bitmap_Gadget3		gg_NextGadget
	dc.w 111			LeftEdge
	dc.w 168			TopEdge
	dc.w 47				Width
	dc.w 15				Height
	dc.w 0				Flags
	dc.w RELVERIFY			Activation
	dc.w BOOLGADGET			GadgetType
	dc.l .Border			GadgetRender
	dc.l 0				SelectRender
	dc.l .IntuiText			GadgetText
	dc.l 0				MutualExclude
	dc.l 0				SpecialInfo
	dc.w 0				gadgetID
	dc.l 0				UserData
.Border
	dc.w -1				bd_LeftEdge
	dc.w -1				TopEdge
	dc.b 2				FrontPen
	dc.b 0				BackPen
	dc.b RP_JAM1			DrawMode
	dc.b 5				Count
	dc.l .Cadre			XY
	dc.l .BorderNext		NextBorder
.Cadre
	Border_White 1,1,47,15
.BorderNext
	dc.w -1				bd_LeftEdge
	dc.w -1				TopEdge
	dc.b 1				FrontPen
	dc.b 0				BackPen
	dc.b RP_JAM1			DrawMode
	dc.b 5				Count
	dc.l .CadreNext			XY
	dc.l 0				NextBorder
.CadreNext
	Border_Black 1,1,47,15
.IntuiText
	dc.b 3				it_FrontPen
	dc.b 0				BackPen
	dc.b RP_JAM2			DrawMode
	dc.b 0				KludgeFill00
	dc.w 4				LeftEdge
	dc.w 4				TopEdge
	dc.l 0				ITextFont
	dc.l BitmapText2		Itext
	dc.l 0				NextText

Bitmap_Gadget3
	dc.l Bitmap_Gadget4		gg_NextGadget
	dc.w 178			LeftEdge
	dc.w 168			TopEdge
	dc.w 79				Width
	dc.w 15				Height
	dc.w 0				Flags
	dc.w RELVERIFY			Activation
	dc.w BOOLGADGET			GadgetType
	dc.l .Border			GadgetRender
	dc.l 0				SelectRender
	dc.l .IntuiText			GadgetText
	dc.l 0				MutualExclude
	dc.l 0				SpecialInfo
	dc.w 0				gadgetID
	dc.l 0				UserData
.Border
	dc.w -1				bd_LeftEdge
	dc.w -1				TopEdge
	dc.b 2				FrontPen
	dc.b 0				BackPen
	dc.b RP_JAM1			DrawMode
	dc.b 5				Count
	dc.l .Cadre			XY
	dc.l .BorderNext		NextBorder
.Cadre
	Border_White 1,1,79,15
.BorderNext
	dc.w -1				bd_LeftEdge
	dc.w -1				TopEdge
	dc.b 1				FrontPen
	dc.b 0				BackPen
	dc.b RP_JAM1			DrawMode
	dc.b 5				Count
	dc.l .CadreNext			XY
	dc.l 0				NextBorder
.CadreNext
	Border_Black 1,1,79,15
.IntuiText
	dc.b 3				it_FrontPen
	dc.b 0				BackPen
	dc.b RP_JAM2			DrawMode
	dc.b 0				KludgeFill00
	dc.w 4				LeftEdge
	dc.w 4				TopEdge
	dc.l 0				ITextFont
	dc.l BitmapText3		Itext
	dc.l 0				NextText

Bitmap_Gadget4
	dc.l 0				gg_NextGadget
	dc.w 416			LeftEdge
	dc.w 168			TopEdge
	dc.w 47				Width
	dc.w 15				Height
	dc.w 0				Flags
	dc.w RELVERIFY			Activation
	dc.w BOOLGADGET			GadgetType
	dc.l .Border			GadgetRender
	dc.l 0				SelectRender
	dc.l .IntuiText			GadgetText
	dc.l 0				MutualExclude
	dc.l 0				SpecialInfo
	dc.w 0				gadgetID
	dc.l 0				UserData
.Border
	dc.w -1				bd_LeftEdge
	dc.w -1				TopEdge
	dc.b 2				FrontPen
	dc.b 0				BackPen
	dc.b RP_JAM1			DrawMode
	dc.b 5				Count
	dc.l .Cadre			XY
	dc.l .BorderNext		NextBorder
.Cadre
	Border_White 1,1,47,15
.BorderNext
	dc.w -1				bd_LeftEdge
	dc.w -1				TopEdge
	dc.b 1				FrontPen
	dc.b 0				BackPen
	dc.b RP_JAM1			DrawMode
	dc.b 5				Count
	dc.l .CadreNext			XY
	dc.l 0				NextBorder
.CadreNext
	Border_Black 1,1,47,15
.IntuiText
	dc.b 3				it_FrontPen
	dc.b 0				BackPen
	dc.b RP_JAM2			DrawMode
	dc.b 0				KludgeFill00
	dc.w 4				LeftEdge
	dc.w 4				TopEdge
	dc.l 0				ITextFont
	dc.l BitmapText4		Itext
	dc.l 0				NextText

FormatWindow_struct
	dc.w 150			nw_LeftEdge
	dc.w 88				TopEdge
	dc.w 342			Width
	dc.w 46				Height
	dc.b 2				DetailPen
	dc.b 1				BlockPen
	dc.l 0				IDCMPFlags
	dc.l SMART_REFRESH|RMBTRAP|ACTIVATE|NOCAREREFRESH|WINDOWDRAG|WINDOWDEPTH	Flags
	dc.l 0				FirstGadget
	dc.l 0				CheckMark
	dc.l FormatName			Title
	dc.l 0				Screen
	dc.l 0				BitMap
	dc.w 200			MinWidth
	dc.w 110			MinHeight
	dc.w 320			MaxWidth
	dc.w 256			MaxHeight
	dc.w WBENCHSCREEN		Type

			*********************************
			* STRUCTURE POUR LA REQ.LIBRARY *
			*********************************
ReqFileStruct
	dc.w REQVERSION			frq_VersionNumber
	dc.l ReqTitle			Title
	dc.l Dir			Dir
	dc.l FileName			File
	dc.l PathName			pathName
	dc.l 0				Window
	dc.w 0				MaxExtendedSelect
	dc.w 0				numlines
	dc.w 0				numcolumns
	dc.w 0				devcolumns
	dc.l FRQINFOGADGETM!FRQLOADINGM|FRQCACHINGM	Flags
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

IntuiTextFileName
	dc.b 1				it_FrontPen
	dc.b 0				BackPen
	dc.b RP_JAM2			DrawMode
	dc.b 0				KludgeFill00
	dc.w 120			LeftEdge
	dc.w 21				TopEdge
	dc.l 0				ITextFont
	dc.l FileName			Itext
	dc.l 0				NextText

IntuiTextStart
	dc.b 1				it_FrontPen
	dc.b 0				BackPen
	dc.b RP_JAM2			DrawMode
	dc.b 0				KludgeFill00
	dc.w 134			LeftEdge
	dc.w 43				TopEdge
	dc.l 0				ITextFont
	dc.l DriveStartStr		Itext
	dc.l 0				NextText

IntuiTextStop
	dc.b 1				it_FrontPen
	dc.b 0				BackPen
	dc.b RP_JAM2			DrawMode
	dc.b 0				KludgeFill00
	dc.w 313			LeftEdge
	dc.w 43				TopEdge
	dc.l 0				ITextFont
	dc.l DriveStopStr		Itext
	dc.l 0				NextText

IntuiTextInfo
	dc.b 3				it_FrontPen
	dc.b 0				BackPen
	dc.b RP_JAM2			DrawMode
	dc.b 0				KludgeFill00
	dc.w 20				LeftEdge
	dc.w 86				TopEdge
	dc.l 0				ITextFont
	dc.l CurrentBlockStr		Itext
	dc.l IntuiTextInfo2		NextText
IntuiTextInfo2
	dc.b 3				it_FrontPen
	dc.b 0				BackPen
	dc.b RP_JAM2			DrawMode
	dc.b 0				KludgeFill00
	dc.w 20				LeftEdge
	dc.w 96				TopEdge
	dc.l 0				ITextFont
	dc.l InstallFromStr		Itext
	dc.l IntuiTextOption		NextText

IntuiTextOption
	dc.b 1				it_FrontPen
	dc.b 0				BackPen
	dc.b RP_JAM2			DrawMode
	dc.b 0				KludgeFill00
	dc.w 120			LeftEdge
	dc.w 65				TopEdge
	dc.l 0				ITextFont
	dc.l InstallFull		Itext
	dc.l IntuiTextFileName		NextText

LongStruct
	dc.l 0				gl_titlebar
	dc.l 0				defaultval
	dc.l 0				minlimit
	dc.l 1759			maxlimit
	dc.l 0				result
	dc.l 0				window
	dc.w REQVERSION			versionnumber
	dc.l 0				flags
	dc.l 0				rfu2

WindowLines
	Relief_White 115,17,364,31		FileName	--- Blanc
	Relief_White 115,39,183,53		Start Block
	Relief_White 296,39,364,53		EndBlock
	Relief_White 115,61,364,75		Option
	Contour_White 14,82,307,106		Info
	Relief_Black 115,17,364,31		FileName	--- Noir
	Relief_Black 115,39,183,53		Start Block
	Relief_Black 296,39,364,53		End Block
	Relief_Black 115,61,364,75		Option
	Contour_Black 14,82,307,106		Info
	dc.l 74,29,80,29			F
	dc.l 18,51,24,51			S
	dc.l 208,51,214,51			E
	dc.l 18,73,24,73			N
	dc.l 26,125,33,125			T
	dc.l 91,125,97,125			O
	dc.l 123,125,129,125			B
	dc.l 211,125,217,125			M
	dc.l 251,125,255,125			I
	dc.l 321,125,327,125			A

BitmapLines
	Relief_White 263,168,395,182
	Relief_White 469,168,503,182
	Relief_Black 263,168,395,182
	Relief_Black 469,168,503,182
	dc.l 52,180,58,180			R
	dc.l 115,180,121,180			W
	dc.l 182,180,188,180			E
	dc.l 420,180,426,180			V

FormatLines
	Contour_Black 9,15,332,27
	Contour_White 9,15,332,27

TextRequestStructure
	dc.l 0					trs_Text
	dc.l 0					Controls
	dc.l 0					Window
	dc.l ReqMiddleText			MiddleText
	dc.l 0					PositiveText
	dc.l 0					NegativeText
	dc.l TextReqTitle			Title
	dc.w $ffff				KeyMask
	dc.w 0					TextColor
	dc.w 0					DetailColor
	dc.w 0					BlockColor
	dc.w REQVERSION				VersionNumber
	dc.w 0					TimeOut
	dc.l 0					AbortMask

TextRequestSure
	dc.l 0					trs_Text
	dc.l 0					Controls
	dc.l 0					Window
	dc.l 0					MiddleText
	dc.l BitmapYes				PositiveText
	dc.l AnswerNO				NegativeText
	dc.l TextReqTitle			Title
	dc.w $ffff				KeyMask
	dc.w 0					TextColor
	dc.w 0					DetailColor
	dc.w 0					BlockColor
	dc.w REQVERSION				VersionNumber
	dc.w 0					TimeOut
	dc.l 0					AbortMask

GetString_Struct
	dc.l EnterNameBar			gs_titlebar
	dc.l DiskName				stringbuffer
	dc.l 0					window
	dc.w 31					stringsize
	dc.w 31					visiblesize
	dc.w REQVERSION				versionnumber
	dc.l 0					flag
	dc.l 0					rfu1
	dc.l 0					rfu2
	dc.l 0					rfu3

ReqTextDir		dc.b "   FileName Is A Dir   ",0
ReqTextOpen		dc.b "    Can't Open File    ",0
ReqTextRead		dc.b "    Can't Read File    ",0
ReqTextWrite		dc.b "Error While Writting On Disk",0
ReqTextExe		dc.b "File Is Not Executable",0
ReqTextDisk		dc.b " No Disk In Drive DF0: ",0
ReqTextProtect		dc.b "Disk In Drive DF0: Is Write Protected",0
ReqTextIncomplete	dc.b "File Is Not Completely Written To Disk",0

ReqTextCheckRead	dc.b "Error While Reading Bootblock",10
			dc.b "CheckSum Hasn't Been Done",0
ReqTextCheckWrite	dc.b "Error While Writing Bootblock",10
			dc.b "CheckSum Hasn't Been Done",0

ReqTextReadBitmapRead	dc.b "Error While Reading Bitmap",0

ReqTextBitmapDisk	dc.b "No Disk In Drive DF0:",10
			dc.b "Bitmap Hasn't Been Written",0
ReqTextBitmapProtect	dc.b "Disk In Drive DF0: Is Write Protected",10
			dc.b "Bitmap Hasn't Been Written",0
ReqTextBitmapRead	dc.b "Error While Reading",10
			dc.b "Bitmap Hasn't Been Written",0
ReqTextBitmapWrite	dc.b "Error While Writing",10
			dc.b "Bitmap Hasn't Been Written",0

ReqTextFormatDisk	dc.b "No Disk In Drive DF0:",10
			dc.b "Disk Hasn't Been Formated",0
ReqTextFormatProtect	dc.b "Disk In Drive DF0: Is Write Protected",10
			dc.b "Disk Hasn't Been Formated",0
ReqTextFormatVerify	dc.b "      Verify Error",10
			dc.b "Disk Hasn't Been Formated",0
ReqTextFormatWrite	dc.b "       Write Error",10
			dc.b "Disk Hasn't Been Formated",0

ReqTextStopSure		dc.b "Abort The Installation ?",10
			dc.b "     Are You Sure ?",0

ReqTextBitmapSure	dc.b "  Write Bitmap To Disk  ",10
			dc.b "     Are You Sure ?",0

ReqTextInstallSure	dc.b "Install File On Disk Blocks",10
			dc.b "      Are You Sure ?",0

ReqTextAbout		dc.b "    -=+  FTB v3.4  +=-",10,10
			dc.b " Copyrighted And Released",10
			dc.b "    In 1993 By Sync of",10
			dc.b "   The Special Brothers",10,10
			dc.b "   If You Find Some Bugs",10
			dc.b "     Please Write to :",10,10
			dc.b "      Pierre Chalamet",10
			dc.b "    5 Rue Du 11 Octobre",10
			dc.b "45140 St Jean De La Ruelle",10
			dc.b "          FRANCE",0
ReqMiddleText		dc.b " Ok! ",0
TextReqTitle		dc.b "FTB v3.4 Request",0
TextReqTitleAbout	dc.b "About",0
InstallFull		dc.b "Install Full File           ",0
InstallRemove		dc.b "Install Only Hunk_Code      ",0
InstallFullCheck	dc.b "Install Full File + CheckSum",0
InstallRemoveCheck	dc.b "Install Hunk_Code + CheckSum",0
BitmapAllocate		dc.b "Allocate Blocks",0
BitmapFree		dc.b "Free Blocks    ",0
BitmapYes		dc.b "Yes",0
BitmapNo		dc.b "No ",0
AnswerNO		dc.b "NO!",0
DriveStartStr		dc.b "0000",0
DriveStopStr		dc.b "1759",0
DriveCurrentStr		dc.b "0000",0
CurrentBlockStr		dc.b "Current Block :",0
InstallFromStr		dc.b "Install From  :        To :",0
FileName		dcb.b FCHARS+1,0
ReqTitle		dc.b "Select A File",0
Dir			dcb.b DSIZE+1,0
PathName		dcb.b DSIZE+FCHARS+2,0
TD_DeviceName		dc.b "trackdisk.device",0
StartLong		dc.b "Start Block",0
StopLong		dc.b "End Block",0
Reply_Port_Name		dc.b "FTB Reply_Port",0
DF0_Name		dc.b "DF0:",0
IconizeName		dc.b "FTB v3.4 Zzzz",0
WindowName		dc.b "File To Block(FTB) v3.4 By Sync/TSB",0
BitmapName		dc.b "Bitmap Editor",0
Text1			dc.b "SELECT FILE",0
Text2			dc.b "START BLOCK",0
Text3			dc.b "END BLOCK",0
Text4			dc.b "NEXT OPTION",0
Text5			dc.b "START",0
Text6			dc.b "STOP",0
Text7			dc.b "BITMAP",0
Text8			dc.b "FORMAT",0
Text9			dc.b "ICONIZE",0
Text10			dc.b "ABOUT",0
BitmapText1		dc.b "READ",0
BitmapText2		dc.b "WRITE",0
BitmapText3		dc.b "EDIT MODE",0
BitmapText4		dc.b "VALID",0
FormatUpper		dc.b "CYLINDER 00 - TRACK 000 - UPPER SIDE - SECTOR 00 - BLOCK 0000"
FormatLower		dc.b "CYLINDER 00 - TRACK 000 - LOWER SIDE - SECTOR 00 - BLOCK 0000"
FormatOut		dc.b "                                                             "
FormatSize=*-FormatOut
Redrawing		dc.b "DRAWING BITMAP"
EnterNameBar		dc.b "Enter Disk Name",0
DiskName		dcb.b 32,0
Formating		dc.b "Formating 00"
Verifying		dc.b "Verify"
Initializing		dc.b "Initializing"
FormatName		dc.b "Disk Formater",0

			************************************
			* MEMOIRE EN CHIP POUR LE POINTEUR *
			************************************
	section Sprite,data_c
Busy_Spr	dc.l 0
		dc.w $0400,$07C0
		dc.w $0000,$07C0
		dc.w $0100,$0380
		dc.w $0000,$07E0
		dc.w $07C0,$1FF8
		dc.w $1FF0,$3FEC
		dc.w $3FF8,$7FDE
		dc.w $3FF8,$7FBE
		dc.w $7FFC,$FF7F
		dc.w $7EFC,$FFFF
		dc.w $7FFC,$FFFF
		dc.w $3FF8,$7FFE
		dc.w $3FF8,$7FFE
		dc.w $1FF0,$3FFC
		dc.w $07C0,$1FF8
		dc.w $0000,$07E0
		dc.l 0
LockPic1	incbin "LockPic1.RAW"
LockPic2	incbin "LockPic2.RAW"

