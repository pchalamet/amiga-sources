						
*			xPKWin v0.0  ©1994 Sync/DreamDealers
*			~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*			Last change : 




* Rapport de bugs
* ~~~~~~~~~~~~~~~
*
* - Probleme de récuperation des arguments sous WB
*   (Get_ToolTypes/WB_ToolTypes)
*
* - Le Force Pack tourne en rond comme dans le vrai xPK
*   Faire un ExAll dés ke l'on rentre dans le dir ?
*   (Recursive_Work)
*


* A faire
* ~~~~~~~
*
* - Coder le Save Options
*
* - Utiliser la reqtools.library à la place de l'asl.library
*
* - Un port AREXX
*




* Options de compilation Devpac 3
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	OPT P=68000
	OPT C+,O+,OW-
;;	OPT OW1+,OW6+
;;	OPT NODEBUG,NOLINE
	OPT CHKIMM
	OUTPUT hd1:xPKWin
;;	OUTPUT ram:X

DATA_OFFSET=0

XPKWIN_VERSION=0
XPKWIN_REVISION=0
XPKWIN_BETAVERSION=1



* Les includes de Mr Commodore...
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	incdir "hd1:Include/"
	include "exec/exec_lib.i"
	include "exec/execbase.i"
	include "exec/memory.i"
	include "exec/ports.i"
	include "exec/lists.i"
	include "exec/nodes.i"
	include "graphics/graphics_lib.i"
	include "intuition/intuition_lib.i"
	include "intuition/intuition.i"
	include "dos/dos_lib.i"
	include "dos/dos.i"
	include "dos/dosextens.i"
	include "dos/doshunks.i"
	include "libraries/asl_lib.i"
	include "libraries/asl.i"
	include "libraries/gadtools_lib.i"
	include "libraries/gadtools.i"
	include "workbench/wb_lib.i"
	include "workbench/workbench.i"
	include "workbench/startup.i"
	include "workbench/icon_lib.i"
	include "utility/tagitem.i"
	include "libraries/commodities_lib.i"
	include "libraries/commodities.i"
	include "libraries/xpk_lib.i"
	include "libraries/xpk.i"
	include "intuition/gadgetclass.i"
	include "misc/macros.i"


* Quelques EQU
* ~~~~~~~~~~~~
WINDOW_X=460
WINDOW_Y=217

INFO_X=94+15
INFO_Y=10+8
INFO_W=WINDOW_X-(94+15+15)
INFO_H=38

ICON_X=38
ICON_Y=39
ICON_DEPTH=3

EVT_HOTKEY=1




* Hop Hop... Penetration à partir d'ici
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	section WannaBeFame,code
Entry_Point
	bra.s skip_version
	dc.b "$VER: xPKWin v"
	dc.b "0"+XPKWIN_VERSION,"."
	dc.b "0"+XPKWIN_REVISION
	IFD XPKWIN_BETA
	dc.b "ß"
	ENDC
	dc.b " (c)1994 Pierre Chalamet",0
	even
skip_version
	lea _DataBase(pc),a5

	move.l (_SysBase).w,a6
	move.l a6,_ExecBase(a5)			copie d'ExecBase en FastRam!

	move.l ThisTask(a6),a3			recherche notre propre task
	move.l a3,xPKWin_Task(a5)

	tst.l pr_CLI(a3)			on démarre du CLI ?
	beq.s from_WB
from_CLI
	movem.l d0/a0,CLI_Args(a5)
	bra.s _main

from_WB
	lea pr_MsgPort(a3),a0			attend le WB message
	move.l a0,a2
	CALL WaitPort
	move.l a2,a0
	CALL GetMsg				va chercher le WB message
	move.l d0,WB_Msg(a5)
	bsr.s _main
	CALL _ExecBase(a5),Forbid
	move.l WB_Msg(a5),a1
	CALL ReplyMsg				retourne le WB message
	moveq #0,d0
	rts


*************************************************************************************************
*             CA COMMENCE REELLEMENT A PARTIR D'ICI AVEC L'OUVERTURE DES LIBRARIES
*************************************************************************************************
_main	
	lea DosName(pc),a1			ouvre la dos.library
	moveq #39,d0
	CALL OpenLibrary
	move.l d0,_DosBase(a5)
	beq no_dos

	lea AslName(pc),a1			ouvre l'asl.library
	moveq #37,d0
	CALL OpenLibrary
	move.l d0,_AslBase(a5)
	beq no_asl

	lea GfxName(pc),a1			ouvre la graphics.library
	moveq #37,d0
	CALL OpenLibrary
	move.l d0,_GfxBase(a5)
	beq no_gfx

	lea IntuitionName(pc),a1		ouvre l'intuition.library
	moveq #37,d0
	CALL OpenLibrary
	move.l d0,_IntuitionBase(a5)
	beq no_intuition

	lea GadToolsName(pc),a1			ouvre la gadtools.library
	moveq #37,d0
	CALL OpenLibrary
	move.l d0,_GadToolsBase(a5)
	beq no_gadtools

	lea XpkMasterName(pc),a1		ouvre la xpkmaster.library
	moveq #2,d0
	CALL OpenLibrary
	move.l d0,_XpkBase(a5)
	beq no_xpk

	lea WorkbenchName(pc),a1		ouvre la workbench.library
	moveq #37,d0
	CALL OpenLibrary
	move.l d0,_WorkbenchBase(a5)
	beq no_workbench

	lea CommoditiesName(pc),a1		ouvre la commodities.library
	moveq #37,d0
	CALL OpenLibrary
	move.l d0,_CxBase(a5)
	beq no_commodities

	lea IconName(pc),a1			ouvre l'icon.library
	moveq #37,d0
	CALL OpenLibrary
	move.l d0,_IconBase(a5)
	beq no_icon


* recherche les options de démarrage
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	bsr Get_ToolTypes
	beq no_tooltypes


* Recherche le Path du program et on le prend comme path initial pour les Requester
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	CALL _DosBase(a5),GetProgramDir		verifie qu'on n'est pas en resident
	move.l d0,d1				et recherche le path initial pour
	beq no_resident				les requesters
	move.l #Initial_Directory,d2
	move.l #256,d3
	CALL NameFromLock
	tst.l d0
	beq no_resident


* Allocation d'une structure FileInfoBlock
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.l #DOS_FIB,d1
	moveq #0,d2
	CALL _DosBase(a5),AllocDosObject
	move.l d0,Fib(a5)
	beq no_fib


* Installation de la commodity
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	bsr Install_Commodity
	beq no_commodity


* Fabrique la liste des packers
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	bsr Build_Packers_List
	beq no_packerslist


* Ouverture de la fonte Topaz 8
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	lea GadgetAttr(pc),a0			ouvre la topaz 8
	CALL _GfxBase(a5),OpenFont
	move.l d0,Window_Font(a5)
	beq no_font


* Alloue les requesters pour les fichiers et dirs
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.l Window_Handle(a5),FileRequest_Window-_DataBase(a5)
	move.l Window_Handle(a5),DirRequest_Window-_DataBase(a5)

	moveq #ASL_FileRequest,d0
	lea FileRequest_Tags(pc),a0
	CALL _AslBase(a5),AllocAslRequest
	move.l d0,File_Requester(a5)
	beq no_allocrequest1

	moveq #ASL_FileRequest,d0
	lea DirRequest_Tags(pc),a0
	CALL AllocAslRequest
	move.l d0,Dir_Requester(a5)
	beq no_allocrequest2


* Installation des AppTrucs
* ~~~~~~~~~~~~~~~~~~~~~~~~~
	CALL _ExecBase(a5),CreateMsgPort	création d'un MsgPort pour
	move.l d0,App_MsgPort(a5)		les AppTrucs
	beq no_msgport_app

	move.l d0,a1				fabrication du mask pour
	move.b MP_SIGBIT(a1),d0			attendre les messages
	moveq #0,d1
	bset d0,d1
	move.l d1,App_WaitMask(a5)
	or.l d1,Global_WaitMask(a5)

	tst.b Flag_CX_POPUP(a5)
	bne.s .display
	bsr Install_Icon
	bra.s .chk
.display
	bsr Install_Window
.chk	beq no_App



*************************************************************************************************
*                              ATTENTE DES EVENEMENTS DE LA FENETRE
*************************************************************************************************
Wait_Msg
	move.l Global_WaitMask(a5),d0		attend un signal
	CALL _ExecBase(a5),Wait


*****************************************
* On regarde si ca vient de la GadTools *
*****************************************
Check_for_GadTools
	move.l Window_MsgPort(a5),d0
	beq Check_for_App
	move.l d0,a0
	CALL _GadToolsBase(a5),GT_GetIMsg
	tst.l d0
	beq Check_for_App

	move.l d0,a1
	move.l im_IAddress(a1),Msg_Gadget(a5)
	move.l im_Class(a1),Msg_Class(a5)
	move.w im_Code(a1),Msg_Code(a5)
	move.w im_Qualifier(a1),Msg_Qualifier(a5)
	
	CALL GT_ReplyIMsg

	pea Check_for_GadTools(pc)		retour direct là-haut...
	move.l Msg_Class(a5),d0
	cmp.l #IDCMP_CLOSEWINDOW,d0		on ferme la commodity ?
	beq Display_Icon
	cmp.l #IDCMP_GADGETUP,d0		un gadget de clické ?
	beq.s Check_Gadget
	cmp.l #IDCMP_MOUSEMOVE,d0		un slider ?
	beq.s Check_Gadget
	cmp.l #IDCMP_VANILLAKEY,d0		une touche ?
	beq.s Check_Key
	cmp.l #IDCMP_MENUPICK,d0		un menu ?
	beq.s Check_Menu
	rts

* une gagdet a été cliqué : on le recherche
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Check_Gadget
	move.l Msg_Gadget(a5),a0
	move.w gg_GadgetID(a0),d0
	beq New_Packer				0
	subq.w #1,d0
	beq New_Efficiency			1
;	subq.w #1,d0				   On saute le test du New_Password car sinon
;	beq New_Password			2  on n'est pas sur d'avoir le password...
	subq.w #2,d0
	beq New_Selected			3
	subq.w #1,d0
	beq Add_File				4
	subq.w #1,d0
	beq Add_Dir				5
	subq.w #1,d0
	beq Remove_Single			6
	subq.w #1,d0
	beq Pack				7
	subq.w #1,d0
	beq Unpack				8
	rts

* une touche à été enfoncée : on regarde si ca donne une action
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Check_Key
	move.w Msg_Code(a5),d0
	cmp.b #"a",d0				passe en Majuscule
	blt.s .cmp
	cmp.b #"z",d0
	bgt.s .cmp
	sub.b #"a"-"A",d0
.cmp
	cmp.b #"E",d0				Efficiency ?
	beq New_Efficiency_Key
	cmp.b #"W",d0				Password ?
	beq New_Password_Enter
	cmp.b #"F",d0				Add File ?
	beq Add_File
	cmp.b #"D",d0				Add Dir ?
	beq Add_Dir
	cmp.b #"R",d0				Remove ?
	beq Remove_Single
	rts

* un menu a été selectionné
* ~~~~~~~~~~~~~~~~~~~~~~~~~
Check_Menu
	move.w Msg_Code(a5),d7
Menu_Loop
	cmp.w #MENUNULL,d7			yen a encore ?
	beq.s Menu_Exit

	move.l Window_MenuStrip(a5),a0
	move.w d7,d0
	CALL _IntuitionBase(a5),ItemAddress

	move.l d0,-(sp)				saute à la fonction du
	move.l d0,a0				menu
	GTMENUITEM_USERDATA a0,a0
	jsr (a0)

	move.l (sp)+,a0
	move.w mi_NextSelect(a0),d7
	bra.s Menu_Loop
Menu_Exit
	rts

	


***************************************
* On regarde si ca vient des AppTrucs *
***************************************
Check_for_App
	move.l App_MsgPort(a5),a0
	CALL _ExecBase(a5),GetMsg
	tst.l d0
	beq.s Check_for_Commodity

	move.l d0,-(sp)
	pea Reply_WB_Msg(pc)
	move.l d0,a0
	move.l am_NumArgs(a0),d2		double click sur l'icon ?
	beq Display_Window
	move.l am_ArgList(a0),a2
	bsr Start_Update_Selected
	bsr Add_Selected
	bra Update_Selected

Reply_WB_Msg
	move.l (sp)+,a1
	CALL _ExecBase(a5),ReplyMsg
	bra.s Check_for_App


******************************************
* On regarde si ca vient de la Commodity *
******************************************
Check_for_Commodity
	move.l Commodity_MsgPort(a5),a0
	CALL _ExecBase(a5),GetMsg
	tst.l d0
	beq Wait_Msg

	move.l d0,a2				recherche l'ID du Message
	move.l a2,a0
	CALL _CxBase(a5),CxMsgID
	move.l d0,Msg_CxID(a5)

	move.l a2,a0				recherche le Type du Message
	CALL CxMsgType
	move.l d0,Msg_CxType(a5)

	move.l a2,a0				recherche la Data du Message
	CALL CxMsgData
	move.l d0,Msg_CxData(a5)

	move.l a2,a1
	CALL _ExecBase(a5),ReplyMsg

	pea Check_for_Commodity(pc)		retourne direct là-haut...
	move.l Msg_CxType(a5),d0
	cmp.l #CXM_IEVENT,d0
	beq.s Check_HotKey
	cmp.l #CXM_COMMAND,d0
	beq.s Check_Command
	rts

Check_HotKey
	move.l Msg_CxID(a5),d0			HotKey d'apparition ?
	cmp.l #EVT_HOTKEY,d0
	beq Flip_Window_Icon
	rts

Check_Command
	move.l Msg_CxID(a5),d0
	cmp.l #CXCMD_KILL,d0			on sort ?
	beq Quit
	cmp.l #CXCMD_UNIQUE,d0			l'utilisateur nous a charger une 2ème fois ?
	beq Display_Window
	cmp.l #CXCMD_APPEAR,d0
	beq Display_Window
	cmp.l #CXCMD_DISAPPEAR,d0
	beq Display_Icon
	rts




*************************************************************************************************
*                              LES FONCTIONS DE L'INTERFACE
*************************************************************************************************

* Selection d'un nouveau packer => affiche des infos
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
New_Packer
	move.w Msg_Code(a5),Packer_Number(a5)
	bsr Display_Packer_Info
	bra Display_Packer_Mode


* Changement de l'éfficacité d'un packer
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
New_Efficiency_Key
	tst.b SliderSet_Tags+3*4+3-_DataBase(a5)
	bne.s .disabled

	move.w Current_PackMode(a5),d0
	move.w Msg_Qualifier(a5),d1
	and.w #IEQUALIFIER_LSHIFT!IEQUALIFIER_RSHIFT,d1
	bne.s .decrease
.increase
	addq.w #1,d0
	cmp.w #100,d0
	bgt.s .disabled
	move.w d0,Current_PackMode(a5)
	bra Display_Packer_Mode

.decrease
	subq.w #1,d0
	blt.s .disabled
	move.w d0,Current_PackMode(a5)
	bra Display_Packer_Mode
.disabled
	rts

New_Efficiency
	move.w Msg_Code(a5),Current_PackMode(a5)
	bra Display_Packer_Mode


* L'utilisateur n'a pas de souris.. activation du string gadget PassWord
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
New_Password_Enter
	tst.b StringSet_Tags+4+3-_DataBase(a5)
	bne.s .disabled

	move.l Gadget_String(a5),a0
	move.l Window_Handle(a5),a1
	sub.l a2,a2
	CALL _IntuitionBase(a5),ActivateGadget
.disabled
	rts


* L'utilisateur a choisi un nouveau Selected
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
New_Selected
	move.w Msg_Code(a5),Selected_Number(a5)
	bra Update_Selected
	

* Ajout d'un fichier dans la liste à packer/depacker
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Add_File
	move.l File_Requester(a5),a0		le disablede la fenetre est fait
	lea FileRequestSet_Tags(pc),a1		par AslRequest()
	bsr Replace_Requester
	CALL _AslBase(a5),AslRequest
	tst.l d0
	beq.s .no_add

	move.l File_Requester(a5),a0
	move.l fr_NumArgs(a0),d2
	move.l fr_ArgList(a0),a2
	bsr Start_Update_Selected
	bsr Add_Selected
	bra Update_Selected
.no_add
	rts


* Ajout d'un directory dans la liste à packer/depacker
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Add_Dir
	move.l Dir_Requester(a5),a0		le disable de la fenetre est fait
	lea DirRequestSet_Tags(pc),a1		par AslRequest()
	bsr.s Replace_Requester
	CALL _AslBase(a5),AslRequest
	tst.l d0
	beq.s .no_add

	move.l #LN_SIZE+6+256,d0		alloue de la mémoire pour le Node
	move.l #MEMF_ANY|MEMF_CLEAR,d1
	CALL _ExecBase(a5),AllocMem
	tst.l d0
	beq.s .no_mem
	move.l d0,a3

	bsr Start_Update_Selected

	lea LN_SIZE(a3),a0
	move.l a0,LN_NAME(a3)
	move.l #" DIR",(a0)+
	move.w #": ",(a0)+

	move.l Dir_Requester(a5),a1
	move.l fr_Drawer(a1),a1
.dup	move.b (a1)+,(a0)+
	bne.s .dup

	lea Selected_List(pc),a0		ajoute le node à la liste
	move.l a3,a1
	ADDTAIL

	addq.w #1,Nb_Selected(a5)
	bra Update_Selected
.no_mem
.no_add
	rts


* Repositionnement des requesters
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
* a1=tags requester
Replace_Requester
	move.l Window_Handle(a5),a2
	move.w wd_LeftEdge(a2),6(a1)
	move.w wd_TopEdge(a2),d0
	add.w Win_Top(a5),d0
	move.w d0,14(a1)
	rts


* Package/Dépackage de la liste Selected
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Pack
	st Flag_Work_Pack(a5)
	bra.s do_Work
Unpack
	sf Flag_Work_Pack(a5)
do_Work
	clr.l Pack_Password-_DataBase(a5)
	move.l Current_PackMethod(a5),Pack_Method-_DataBase(a5)
	move.w Current_PackMode(a5),Pack_Mode-_DataBase(a5)

	tst.b StringSet_Tags+4+3-_DataBase(a5)
	bne.s .no_password

	move.l Gadget_String(a5),a0
	move.l gg_SpecialInfo(a0),a0
	move.l si_Buffer(a5),Pack_Password-_DataBase(a5)
.no_password

loop_Pack
	lea Selected_List(pc),a0
	IFEMPTY a0,no_more_pack			yen a encore à packer ?

	SUCC a0,a0				oui => va chercher l'élément et stockage dans a0
	lea LN_SIZE+6(a0),a0			saute le node + la description user

	move.l _DosBase(a5),a6
	bsr.s Recursive_Work

pack_next
	lea Selected_List(pc),a0
	SUCC a0,a1				vire l'élément qui vient juste d'étre traité
	bsr Free_Selected			et affiche ca à l'écran
	bsr Update_Selected
	bra.s loop_Pack

no_more_pack
	rts



*************************************************************************************************
*                  ROUTINE POUR PACKER OU DEPACKER AVEC PRISE EN COMPTE DES OPTIONS
*                       CETTE ROUTINE EST RECURSIVE SI IL Y A DES DIRECTORIES
* en entrée: a0=FileName ou DirName
*            a6=_DosBase
*************************************************************************************************
Recursive_Work
	move.l a0,Examine_InName-_DataBase(a5)	met ça au cas où...
	move.l a0,Pack_InName-_DataBase(a5)
	move.l a0,Unpack_InName-_DataBase(a5)

	move.l a0,d1				essaye d'avoir un lock
	move.l #ACCESS_READ,d2
	CALL Lock
	move.l d0,-(sp)
	beq .no_lock

	move.l d0,d1				examine le lock
	move.l Fib(a5),d2
	CALL Examine
	move.l d2,a0
	tst.l fib_DirEntryType(a0)		c'est un fichier ?
	bmi.s .file

	move.l (sp),d1				on se fixe sur le directory
	CALL CurrentDir
	move.l d0,-(sp)				sauve old_Lock sur la pile

.dir
	move.l 4(sp),d1				examine tous les fichiers du dir
	move.l Fib(a5),d2
	CALL ExNext
	tst.l d0
	beq .no_more

	move.l d2,a0				
	lea fib_FileName(a0),a0
	bsr.s Recursive_Work
	bra.s .dir

.file
	move.l (sp)+,d1				libère le lock sur le fichier
	CALL UnLock

	move.l Examine_InName(pc),a0		fabrication du nom intermédiaire pour
	lea TempName(pc),a1			le package/depackage
.put	move.b (a0)+,(a1)+
	bne.s .put
	move.b #".",-1(a1)
	move.b #"x",(a1)+
	move.b #"p",(a1)+
	move.b #"k",(a1)+
	clr.b (a1)

	lea xPK_Fib(pc),a0			recherche des infos sur le fichier
	lea Examine_Tags(pc),a1
	CALL _XpkBase(a5),XpkExamine
	tst.l d0
	bne .xpk_error

	tst.b Flag_Work_Pack(a5)		on pack ou on dépack ?
	beq.s .unpack

* Package du fichier
* ~~~~~~~~~~~~~~~~~~
.pack
	move.l xPK_Fib+xf_Type(pc),d0		fichier déja packé ?
;;;;	cmp.l #XPKTYPE_UNPACKED,d0		\  XPKTYPE_UNPACKED=0
	bne .skip
*****************************************************************
* NOTE: hehe... meme bug que dans xPK...
*       cad que si on force le pack on tourne en rond
*       Utiliser ExAll ?
*       OPTION DESACTIVEE POUR LE MOMENT
*
*	beq.s .check_info			/
*	tst.b Flag_ForcePack(a5)		voui => on force le package ?
*	beq .skip
*****************************************************************

.check_info
	tst.b Flag_PackInfo(a5)			on pack les #?.info ?
	beq.s .check_exe
	move.l Examine_InName(pc),a0
.check
	tst.b (a0)+
	bne.s .check
	subq.l #1,a0				un en trop !
	cmp.b #"o",-(a0)
	bne.s .do_pack				regarde si ya .info à la fin
	cmp.b #"f",-(a0)
	bne.s .do_pack
	cmp.b #"n",-(a0)
	bne.s .do_pack
	cmp.b #"i",-(a0)
	bne.s .do_pack
	cmp.b #".",-(a0)
	beq.s .skip

.check_exe
	tst.b Flag_PackExecOnly(a5)		on packe que les executables ?
	beq.s .do_pack

	cmp.l #HUNK_HEADER,xPK_Fib+xf_Head-_DataBase(a5)	regarde si c'est bien un exe
	bne.s .skip
	tst.l xPK_Fib+xf_Head+4-_DataBase(a5)
	bne.s .skip

.do_pack
	lea Pack_Tags(pc),a0
	CALL XpkPack
	tst.l d0
	beq.s .done
	bra.s .xpk_error


* Dépackage du fichier
* ~~~~~~~~~~~~~~~~~~~~
.unpack
	move.l xPK_Fib+xf_Type(pc),d0		si le fichier est déja dépacké alors on le
;;;	cmp.l #XPKTYPE_UNPACKED,d0		dépacke pas
	beq.s .skip
.do_unpack
	lea Unpack_Tags(pc),a0
	CALL XpkUnpack
	tst.l d0
	bne.s .xpk_error

* Le traitement sur le fichier a été fait
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.done
	move.l _DosBase(a5),a6

	tst.b Flag_KeepOriginal(a5)		on garde le fichier original ?
	bne.s .skip

	move.l Examine_InName(pc),d1		efface le vieux fichier
	CALL DeleteFile

	move.l #TempName,d1			renomme le fichier
	move.l Examine_InName(pc),d2
	CALL Rename
	rts

.xpk_error
	bsr Disable_xPKWindow

	move.l Window_Handle(a5),a0
	lea xPKWin_EasyRequest(pc),a1
	move.l #xPKErr_Str,es_TextFormat(a2)
	sub.l a2,a2
	sub.l a3,a3
	CALL _IntuitionBase(a5),EasyRequestArgs

	bsr Enable_xPKWindow
.skip
	move.l #TempName,d1			erreur => efface le fichier template
	CALL _DosBase(a5),DeleteFile
	rts



.no_more
	move.l (sp)+,d1				on se remet sur le dir d'avant
	CALL CurrentDir
	move.l d0,d1				et libère le lock
	CALL UnLock
.no_lock
	addq.l #4,sp				bouffe le lock
	rts





*************************************************************************************************
*                                         MENU PROJECT
*************************************************************************************************

* Affichage du About
* ~~~~~~~~~~~~~~~~~~
Display_About
	bsr Disable_xPKWindow

	move.l Window_Handle(a5),a0
	lea xPKWin_EasyRequest(pc),a1
	move.l #AboutRequest_Str,es_TextFormat(a1)
	sub.l a2,a2
	sub.l a3,a3
	CALL _IntuitionBase(a5),EasyRequestArgs

	bsr Enable_xPKWindow
	rts


* Echange entre la Window et l'Icon
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Flip_Window_Icon
	tst.l AppWindow_Handle(a5)			on affiche quoi ?
	beq.s Display_Window
Display_Icon
	tst.l AppIcon_Handle(a5)			on ouvre pas 2 fois l'Icon...
	bne.s .error
	bsr Install_Icon
	beq.s .error
	bsr Remove_Window
.error	rts

Display_Window
	tst.l AppWindow_Handle(a5)			on ouvre pas 2 fois la Window..
	bne.s .error
	bsr Install_Window
	beq.s .error
	bsr Remove_Icon
.error	rts



*************************************************************************************************
*                                        MENU OPTIONS
*************************************************************************************************

* Changement du flag KeepOriginal
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Toggle_KeepOriginal
	eor.b #$ff,Flag_KeepOriginal(a5)
	rts


* Changement du flag ForcePack
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Toggle_ForcePack
	eor.b #$ff,Flag_ForcePack(a5)
	rts


* Changement du flag PackInfo
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~
Toggle_PackInfo
	eor.b #$ff,Flag_PackInfo(a5)
	rts

* Changement du flag PackExecOnly
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Toggle_PackExecOnly
	eor.b #$ff,Flag_PackExecOnly(a5)
	rts


* Sauvegarde des Options
* ~~~~~~~~~~~~~~~~~~~~~~
Save_Options
	rts




*************************************************************************************************
*                                          MENU TOOLS
*************************************************************************************************

* On vire tous les Selected
* ~~~~~~~~~~~~~~~~~~~~~~~~~
RemoveAll
	bsr Start_Update_Selected
	bsr Remove_Selected
	bra Update_Selected


* On enlève un élément de la liste Selected
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Remove_Single
	lea Selected_List(pc),a0
	IFEMPTY a0,.no_remove

	bsr Start_Update_Selected

	move.w Selected_Number(a5),d0
	move.l a0,a1
.loop
	SUCC a1,a1
	subq.w #1,d0
	bpl.s .loop

	bsr Free_Selected
	bra Update_Selected
.no_remove
	rts


* Vire tous les Files
* ~~~~~~~~~~~~~~~~~~~
Remove_Files
	lea Selected_List(pc),a2
	IFEMPTY a2,.no_remove

	bsr Start_Update_Selected

	move.w Nb_Selected(a5),d2
	move.l a2,a3
.loop
	SUCC a3,a3
.loop_killed
	cmp.l #"FILE",LN_SIZE(a3)
	bne.s .skip
	move.l a2,a0
	move.l a3,a1
	SUCC a3,a3
	bsr Free_Selected
	subq.w #1,d2
	bpl.s .loop_killed
	bra Update_Selected
.skip
	subq.w #1,d2
	bpl.s .loop
	bra Update_Selected
.no_remove
	rts


* Vire tous les Dirs
* ~~~~~~~~~~~~~~~~~~
Remove_Dirs
	lea Selected_List(pc),a2
	IFEMPTY a2,.no_remove

	bsr Start_Update_Selected

	move.w Nb_Selected(a5),d2
	move.l a2,a3
.loop
	SUCC a3,a3
.loop_killed
	cmp.l #" DIR",LN_SIZE(a3)
	bne.s .skip
	move.l a2,a0
	move.l a3,a1
	SUCC a3,a3
	bsr Free_Selected
	subq.w #1,d2
	bpl.s .loop_killed
	bra Update_Selected
.skip
	subq.w #1,d2
	bpl.s .loop
	bra Update_Selected
.no_remove
	rts







*************************************************************************************************
*                                   ON QUITTE TOUT !
*************************************************************************************************
Quit_from_Menu
	addq.l #8,sp				bouffe le "move.l d0,-(sp)" et "jsr (a0)"
Quit
	addq.l #4,sp				normalement ya un pea Check_for_XXX(pc)

no_App
	bsr Remove_Window
	bsr Remove_Icon

	move.l App_WaitMask(a5),d0		vire le mask de l'app
	not.l d0
	and.l d0,Global_WaitMask(a5)

	move.l App_MsgPort(a5),a2
	move.l _ExecBase(a5),a6			repond à tous les messages du port
	bra.s .start				des AppTrucs
.wait_end_msg
	move.l d0,a0
	CALL ReplyMsg
.start	move.l a2,a0
	CALL GetMsg
	tst.l d0
	bne.s .wait_end_msg

	move.l a2,a0				vire le MsgPort des AppTrucs
	CALL DeleteMsgPort

no_msgport_app
	move.l Dir_Requester(a5),a0		libère le requester des dirs
	CALL _AslBase(a5),FreeAslRequest
no_allocrequest2
	move.l File_Requester(a5),a0		libère le requester des fichiers
	CALL FreeAslRequest
no_allocrequest1
	move.l Window_Font(a5),a1		ferme la fonte topaz
	CALL _GfxBase(a5),CloseFont
no_font
	bsr Remove_Packers_List
no_packerslist
	bsr Remove_Commodity
no_commodity
	move.l _IconBase(a5),a1			ferme l'icon.library
	CALL _ExecBase(a5),CloseLibrary
no_fib
no_resident
no_tooltypes
	bsr Remove_Selected
no_icon
	move.l _CxBase(a5),a1			ferme la commodities.library
	CALL CloseLibrary
no_commodities
	move.l _WorkbenchBase(a5),a1		ferme la workbench.library
	CALL CloseLibrary
no_workbench
	move.l _XpkBase(a5),a1			ferme la xpkmaster.library
	CALL CloseLibrary
no_xpk
	move.l _GadToolsBase(a5),a1		ferme la gadtools.library
	CALL CloseLibrary
no_gadtools
	move.l _IntuitionBase(a5),a1		ferme la intuition.library
	CALL CloseLibrary
no_intuition
	move.l _GfxBase(a5),a1			ferme la graphics.library
	CALL CloseLibrary
no_gfx
	move.l _AslBase(a5),a1			ferme l'asl.library
	CALL CloseLibrary
no_asl
	move.l _DosBase(a5),a1			ferme la dos.library
	CALL CloseLibrary
no_dos
	moveq #0,d0
	rts









*************************************************************************************************
*                         FABRICATION DE LA LISTE CHAINEES DES PACKERS
*************************************************************************************************
Build_Packers_List
	lea Packers_List(pc),a0
	NEWLIST a0

	lea xPKWin_PackersListTags(pc),a0
	CALL _XpkBase(a5),XpkQuery
	tst.l d0
	bne.s no_xpkquery_packers

	move.l xPKWin_PackersList+xpl_NumPackers(pc),d2		regarde si ya au moins un
	beq.s no_packers_at_all					packer

	move.l d2,d0
	mulu.w #LN_SIZE+6,d0
	move.l #MEMF_ANY|MEMF_CLEAR,d1
	CALL _ExecBase(a5),AllocMem
	move.l d0,Packers_Nodes(a5)
	beq.s no_packers_allocmem

	move.l d0,a1
	lea xPKWin_PackersList+xpl_Packer(pc),a2
build_all
	lea LN_SIZE(a1),a0
	move.l a0,LN_NAME(a1)			met ca en place pour la GadTools
	move.l (a2)+,(a0)+			recopie le nom du packer
	move.w (a2)+,(a0)

	lea Packers_List(pc),a0
	ADDTAIL					a1 n'est pas détruit

	lea LN_SIZE+6(a1),a1			Node suivant
start_build
	subq.l #1,d2				yen a d'autres ?
	bne.s build_all
	moveq #1,d0
	rts

no_packers_allocmem
no_packers_at_all
no_xpkquery_packers
	moveq #0,d0
	rts
	

*************************************************************************************************
*                         LIBERATION DE LA LISTE CHAINEES DES PACKERS
*************************************************************************************************
Remove_Packers_List
	move.l Packers_Nodes(a5),a1
	move.l xPKWin_PackersList+xpl_NumPackers(pc),d0
	mulu.w #LN_SIZE+6,d0
	CALL _ExecBase(a5),FreeMem
	rts


*************************************************************************************************
*                             OUVERTURE DE LA FENETRE DE xPKWin
* en sortie: Z=1(eq) si ERREUR
*************************************************************************************************
Install_Window
	sub.l a0,a0				lock le Wb en PubScreen
	CALL _IntuitionBase(a5),LockPubScreen
	move.l d0,Window_PubScreen(a5)
	move.l d0,Window_Screen-_DataBase(a5)
	beq no_pubscreen

	move.l d0,a0				recherche la taille de la
	moveq #0,d0
	move.b sc_WBorTop(a0),d0		barre de la fenetre
	move.l sc_Font(a0),a1
	add.w ta_YSize(a1),d0
	addq.w #1,d0
	move.w d0,Win_Top(a5)
	move.w #WINDOW_Y,Window_Height-_DataBase(a5)
	add.w d0,Window_Height-_DataBase(a5)

	move.w sc_Width(a0),d0			recentre la fenetre à l'écran
	sub.w #WINDOW_X,d0
	lsr.w #1,d0
	move.w d0,Window_Left-_DataBase(a5)

	move.w sc_Height(a0),d0
	sub.w #WINDOW_Y,d0
	lsr.w #2,d0
	move.w d0,Window_Top-_DataBase(a5)

	sub.l a1,a1				recherche les informations
	CALL _GadToolsBase(a5),GetVisualInfoA	d'affichage
	move.l d0,Window_VisualInfo(a5)
	beq no_visualInfo

* Mise en place des gadgets de la fenetre
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	lea Window_glist(pc),a0			création d'un context pour
	CALL CreateContext			les gadgets de la gadtools

	move.w Win_Top(a5),d7

* Fabrique le ListView Packers
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	lea xPKWin_NewGadget(pc),a1		init la structure NewGadget
	move.w #15,gng_LeftEdge(a1)
	move.w #18,gng_TopEdge(a1)
	add.w d7,gng_TopEdge(a1)
	move.w #80,gng_Width(a1)
	move.w #110,gng_Height(a1)
	move.l #Packer_Str,gng_GadgetText(a1)
	move.l #GadgetAttr,gng_TextAttr(a1)
	clr.w gng_GadgetID(a1)			ID=0
	move.l #PLACETEXT_ABOVE|NG_HIGHLABEL,gng_Flags(a1)
	move.l Window_VisualInfo(a5),gng_VisualInfo(a1)

	move.l d0,a0				création d'une checkbox
	lea ListViewPackers_Tags(pc),a2		Optimize Samples
	move.w Packer_Number(a5),6(a2)
	move.w Packer_Number(a5),3*4+2(a2)
	move.l #LISTVIEW_KIND,d0
	CALL CreateGadgetA
	move.l d0,Gadget_Packers(a5)

* Fabrique le Slider Efficiency
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	lea xPKWin_NewGadget(pc),a1
	move.w #445-108,gng_LeftEdge(a1)
	move.w #80,gng_TopEdge(a1)
	add.w d7,gng_TopEdge(a1)
	move.w #108,gng_Width(a1)
	move.w #12,gng_Height(a1)
	clr.l gng_GadgetText(a1)
	move.w #1,gng_GadgetID(a1)

	move.l d0,a0
	lea Slider_Tags(pc),a2
	move.l #SLIDER_KIND,d0
	CALL CreateGadgetA
	move.l d0,Gadget_Slider(a5)

* Fabrique le Text-Entry Password
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	lea xPKWin_NewGadget(pc),a1
	move.w #445-208,gng_LeftEdge(a1)
	move.w #96,gng_TopEdge(a1)
	add.w d7,gng_TopEdge(a1)
	move.w #208,gng_Width(a1)
	move.w #14,gng_Height(a1)
	move.w #2,gng_GadgetID(a1)

	move.l d0,a0
	lea String_Tags(pc),a2
	move.l #STRING_KIND,d0
	CALL CreateGadgetA
	move.l d0,Gadget_String(a5)

* Fabrique le ListView Selected
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	lea xPKWin_NewGadget(pc),a1
	move.w #15,gng_LeftEdge(a1)
	move.w #133,gng_TopEdge(a1)
	add.w d7,gng_TopEdge(a1)
	move.w #430,gng_Width(a1)
	move.w #60,gng_Height(a1)
	move.w #3,gng_GadgetID(a1)
	move.l #Selected_Str,gng_GadgetText(a1)

	move.l d0,a0
	lea ListViewSelected_Tags(pc),a2
	move.l #LISTVIEW_KIND,d0
	CALL CreateGadgetA
	move.l d0,Gadget_Selected(a5)

* Fabrique le Button Add File
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~
	lea xPKWin_NewGadget(pc),a1
	move.w #15,gng_LeftEdge(a1)
	move.w #197,gng_TopEdge(a1)
	add.w d7,gng_TopEdge(a1)
	move.w #78,gng_Width(a1)
	move.w #12,gng_Height(a1)
	move.w #4,gng_GadgetID(a1)
	move.l #PLACETEXT_IN,gng_Flags(a1)
	move.l #AddFile_Str,gng_GadgetText(a1)

	move.l d0,a0
	lea Button_Tags(pc),a2
	move.l #BUTTON_KIND,d0
	CALL CreateGadgetA
	move.l d0,Gadget_AddFile(a5)

* Fabrique le Button Add Dir
* ~~~~~~~~~~~~~~~~~~~~~~~~~~
	lea xPKWin_NewGadget(pc),a1
	add.w #85,gng_LeftEdge(a1)
	move.l #AddDir_Str,gng_GadgetText(a1)
	move.w #5,gng_GadgetID(a1)

	move.l d0,a0
	lea Button_Tags(pc),a2
	move.l #BUTTON_KIND,d0
	CALL CreateGadgetA
	move.l d0,Gadget_AddDir(a5)

* Fabrique le Button Remove
* ~~~~~~~~~~~~~~~~~~~~~~~~~
	lea xPKWin_NewGadget(pc),a1
	add.w #85,gng_LeftEdge(a1)
	move.l #Remove_Str,gng_GadgetText(a1)
	move.w #6,gng_GadgetID(a1)

	move.l d0,a0
	lea Button_Tags(pc),a2
	move.l #BUTTON_KIND,d0
	CALL CreateGadgetA
	move.l d0,Gadget_Remove(a5)

* Fabrique le Button Pack
* ~~~~~~~~~~~~~~~~~~~~~~~
	lea xPKWin_NewGadget(pc),a1
	add.w #97,gng_LeftEdge(a1)
	move.l #Pack_Str,gng_GadgetText(a1)
	move.w #7,gng_GadgetID(a1)

	move.l d0,a0
	lea Button_Tags(pc),a2
	move.l #BUTTON_KIND,d0
	CALL CreateGadgetA
	move.l d0,Gadget_Pack(a5)

* Fabrique le Button unpack
* ~~~~~~~~~~~~~~~~~~~~~~~~~
	lea xPKWin_NewGadget(pc),a1
	add.w #85,gng_LeftEdge(a1)
	move.l #Unpack_Str,gng_GadgetText(a1)
	move.w #8,gng_GadgetID(a1)

	move.l d0,a0
	lea Button_Tags(pc),a2
	move.l #BUTTON_KIND,d0
	CALL CreateGadgetA
	move.l d0,Gadget_Unpack(a5)
	beq no_gadgets				erreur dans les gadgets ?

* Fabrication du titre de la fenetre avec CX_POPKEY
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	lea WindowTitleFormat(pc),a0
	lea CX_POPKEY_Ptr(pc),a1
	lea Putch(pc),a2
	lea WindowTitle(pc),a3
	CALL _ExecBase(a5),RawDoFmt

* Ouvre la fenetre principale
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~
	sub.l a0,a0				ouvre la fenetre principale
	lea Window_Tags(pc),a1
	CALL _IntuitionBase(a5),OpenWindowTagList
	move.l d0,Window_Handle(a5)
	beq no_openwindow

	move.l d0,a0				retrace les gadgets de la 
	sub.l a1,a1				gadtools
	CALL _GadToolsBase(a5),GT_RefreshWindow

* Recherche des datas qui sont utiles par la suite
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.l Window_Handle(a5),a0
	move.l wd_RPort(a0),Window_RastPort(a5)
	move.l wd_UserPort(a0),a0
	move.l a0,Window_MsgPort(a5)
	move.b MP_SIGBIT(a0),d0
	moveq #0,d1
	bset d0,d1
	move.l d1,Window_WaitMask(a5)

* Trace un zolie BevelBox pour la Description
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.l Window_Handle(a5),a0
	move.l wd_RPort(a0),a0
	lea BevelTags(pc),a1
	move.l Window_VisualInfo(a5),4(a1)
	move.l #INFO_X,d0			LeftEdge
	move.l #INFO_Y,d1			TopEdge
	add.w Win_Top(a5),d1
	move.l #INFO_W,d2			Width
	move.l #INFO_H,d3			Height
	CALL DrawBevelBoxA

* Ecrit dans la fenetre ce qu'il faut
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.l Window_Font(a5),a0		met la topaz 8 comme fonte
	move.l Window_RastPort(a5),a2
	move.l a2,a1
	CALL _GfxBase(a5),SetFont

* Affiche "Efficiency"
* ~~~~~~~~~~~~~~~~~~~~
	moveq #1,d0
	move.l a2,a1
	CALL SetAPen

	moveq #109,d0
	moveq #88,d1
	moveq #Efficiency_Size,d2
	lea Efficiency_Text(pc),a3
	bsr Display_Text

* Affiche "Password"
* ~~~~~~~~~~~~~~~~~~
	move.w #109,d0
	moveq #105,d1
	moveq #Password_Size,d2
	lea Password_Text(pc),a3
	bsr Display_Text

* Affiche "Description"
* ~~~~~~~~~~~~~~~~~~~~~
	moveq #2,d0
	move.l a2,a1
	CALL SetAPen

	move.w #234,d0
	moveq #11,d1
	moveq #Description_Size,d2
	lea Description_Text(pc),a3
	bsr Display_Text

* Affiche "Settings"
* ~~~~~~~~~~~~~~~~~~
	move.w #246,d0
	moveq #73,d1
	moveq #Settings_Size,d2
	lea Settings_Text(pc),a3
	bsr Display_Text
	
* Affiche les Underlines des "Efficiency" et "Password"
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	moveq #1,d0
	moveq #2,d1
	moveq #RP_JAM1,d2
	move.l a2,a1
	CALL SetABPenDrMd

	moveq #109,d0
	moveq #88,d1
	moveq #1,d2
	lea UnderLine_Text(pc),a3
	bsr Display_Text

	move.w #109+4*8,d0
	moveq #105,d1
	moveq #1,d2
	lea UnderLine_Text(pc),a3
	bsr Display_Text

	bsr Display_Packer_Info
	bsr Display_Packer_Mode

* Mise en place du menu
* ~~~~~~~~~~~~~~~~~~~~~
	lea xPKWin_Menus(pc),a0			prépare les menus
	sub.l a1,a1
	CALL _GadToolsBase(a5),CreateMenusA
	move.l d0,Window_MenuStrip(a5)
	beq no_createmenu

	move.l d0,a0				arrangement des menus
	move.l Window_VisualInfo(a5),a1
	lea Menus_Tags(pc),a2
	CALL LayoutMenusA
	tst.l d0
	beq.s no_layoutmenu

	move.l Window_Handle(a5),a0		et hop!! installe les menus
	move.l Window_MenuStrip(a5),a1
	CALL _IntuitionBase(a5),SetMenuStrip
	tst.l d0
	beq.s no_setmenustrip

* On essait de transformer la fenetre en AppWindow
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	moveq #0,d0				id
	moveq #0,d1				userdata
	move.l Window_Handle(a5),a0
	move.l App_MsgPort(a5),a1		MsgPort
	sub.l a2,a2
	CALL _WorkbenchBase(a5),AddAppWindowA
	move.l d0,AppWindow_Handle(a5)
	beq.s no_appwindow			erreur ?

	move.l Window_WaitMask(a5),d0		installe le mask de la fenetre
	or.l d0,Global_WaitMask(a5)

* Met l'écran de xPKWin devant tous les autres
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.l Window_PubScreen(a5),a0
	CALL _IntuitionBase(a5),ScreenToFront

	moveq #1,d0
	rts


*************************************************************************************************
*                              FERMETURE DE LA FENETRE DE xPKWin
*************************************************************************************************
Remove_Window
	move.l AppWindow_Handle(a5),d0
	beq.s no_closewindow

	move.l Window_WaitMask(a5),d1		vire le bit de mask de la fenetre
	not.l d1				du mask global
	and.l d1,Global_WaitMask(a5)

	move.l d0,a0				enlève l'AppWindow
	CALL _WorkbenchBase(a5),RemoveAppWindow
no_appwindow
	move.l Window_Handle(a5),a0		vire le menu
	CALL _IntuitionBase(a5),ClearMenuStrip
no_setmenustrip
no_layoutmenu
	move.l Window_MenuStrip(a5),a0		libère les menus
	CALL _GadToolsBase(a5),FreeMenus
no_createmenu
	move.l Window_Handle(a5),a0		ferme la fenetre
	CALL _IntuitionBase(a5),CloseWindow
no_openwindow
	move.l Window_glist(pc),a0		vire les gadgets
	CALL _GadToolsBase(a5),FreeGadgets
no_gadgets
no_createcontext
	move.l Window_VisualInfo(a5),a0		libère le VisualInfo sur l'écran publique
	CALL FreeVisualInfo
no_visualInfo
	sub.l a0,a0				libère l'écran publique
	move.l Window_PubScreen(a5),a1
	CALL _IntuitionBase(a5),UnlockPubScreen
no_pubscreen
	clr.l Window_RastPort(a5)
	clr.l Window_Handle(a5)
	clr.l Window_MsgPort(a5)
	clr.l AppWindow_Handle(a5)
	st Flag_Preserve_PackMode(a5)
no_closewindow
	rts



*************************************************************************************************
*                          INSTALLE L'ICON DE xPKWin SUR L'ECRAN DU WB
* en sortie: Z=1(eq) si ERREUR
*************************************************************************************************
Install_Icon
	moveq #0,d0
	moveq #0,d1
	lea Commodity_Name(pc),a0
	move.l App_MsgPort(a5),a1
	sub.l a2,a2
	lea xPKWin_Icon(pc),a3
	sub.l a4,a4
	CALL _WorkbenchBase(a5),AddAppIconA
	move.l d0,AppIcon_Handle(a5)
	rts


*************************************************************************************************
*                            VIRE L'ICON DE xPKWin DE L'ECRAN DU WB
*************************************************************************************************
Remove_Icon
	move.l AppIcon_Handle(a5),d0
	beq.s .no_remove

	move.l d0,a0
	CALL _WorkbenchBase(a5),RemoveAppIcon
	clr.l AppIcon_Handle(a5)
.no_remove
	rts



*************************************************************************************************
*                                MISE EN PLACE DE LA COMMODITY
* en sortie: Z=1(eq) si ERREUR
*************************************************************************************************
Install_Commodity
	CALL _ExecBase(a5),CreateMsgPort	création d'un MsgPort pour
	move.l d0,Commodity_MsgPort(a5)		le Sender et le Broker de la commodity
	beq no_msgport_commodity

	move.l d0,a1				fabrication du mask pour
	move.b MP_SIGBIT(a1),d0			attendre les messages
	moveq #0,d1				de la commodity
	bset d0,d1
	move.l d1,Commodity_WaitMask(a5)

	lea xPKWin_NewBroker(pc),a0		fabrication d'un Broker
	move.l Commodity_MsgPort(a5),nb_Port(a0)
	moveq #0,d0
	CALL _CxBase(a5),CxBroker
	move.l d0,Commodity_Broker(a5)
	beq no_broker

	move.l #CX_FILTER,d0			fabrication d'un Filter
	lea xPKWin_POPKEY(pc),a0
	sub.l a1,a1
	CALL CreateCxObj
	move.l d0,Commodity_Filter(a5)
	beq.s no_filter

	move.l Commodity_Broker(a5),a0		attache le Filter au broker
	move.l d0,a1
	CALL AttachCxObj

	move.l #CX_SEND,d0			fabrication d'un Sender
	move.l Commodity_MsgPort(a5),a0
	lea EVT_HOTKEY,a1
	CALL CreateCxObj
	move.l d0,Commodity_Sender(a5)
	beq.s no_sender

	move.l Commodity_Filter(a5),a0		attache le Sender au Filter
	move.l d0,a1
	CALL AttachCxObj

	move.l #CX_TRANSLATE,d0			fabrication d'un Translate "Trou Noir"
	sub.l a0,a0
	sub.l a1,a1
	CALL CreateCxObj
	move.l d0,Commodity_Translate(a5)
	beq.s no_translate

	move.l Commodity_Filter(a5),a0		attache le Translate au Filter
	move.l d0,a1
	CALL AttachCxObj

	move.l Commodity_Filter(a5),a0		regarde si yaurait pas une erreur par
	CALL CxObjError				hasard...
	tst.l d0
	bne.s no_cxobjerror

	move.l Commodity_Broker(a5),a0		hop hop.. va y ma petite commodity !!
	moveq #1,d0
	CALL ActivateCxObj

	move.l Commodity_WaitMask(a5),d0
	or.l d0,Global_WaitMask(a5)
	rts

*************************************************************************************************
*                                   ENLEVE LA COMMODITY
*************************************************************************************************
Remove_Commodity
	tst.l Commodity_MsgPort(a5)
	beq.s no_remove_commodity

	move.l Commodity_WaitMask(a5),d0	vire le bit de mask de la commodity
	not.l d0				du mask global
	and.l d0,Global_WaitMask(a5)

no_cxobjerror
no_translate
no_sender
no_filter
	move.l Commodity_Broker(a5),a0		stop la commodity
	moveq #0,d0
	CALL _CxBase(a5),ActivateCxObj

	move.l Commodity_Broker(a5),a0		vire tous les objets Cx
	CALL DeleteCxObjAll
no_broker
	move.l Commodity_MsgPort(a5),a2
	move.l _ExecBase(a5),a6			repond à tous les messages en attente
	bra.s .start				dans le port de l'ex-commodity
.wait_end_msg
	move.l d0,a0
	CALL ReplyMsg
.start	move.l a2,a0
	CALL GetMsg
	tst.l d0
	bne.s .wait_end_msg

	move.l a2,a0				vire le MsgPort de la commodity
	CALL DeleteMsgPort
	
	clr.l Commodity_MsgPort(a5)
no_msgport_commodity
no_remove_commodity
	rts




*************************************************************************************************
*                             RECHERCHE LES OPTIONS DE DEMARRAGE
*************************************************************************************************
Get_ToolTypes
	lea Selected_List(pc),a0
	NEWLIST a0

	tst.l CLI_Line(a5)
	beq.s WB_ToolTypes

CLI_ToolTypes

* Peut-etre un parsing de la ligne de CLI un de ces jours ? heu..
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	moveq #1,d0
	rts


WB_ToolTypes
	move.l WB_Msg(a5),a2
	move.l sm_ArgList(a2),a2		recherche le WBArg de notre programme
	move.l sm_NumArgs(a2),d2

	move.l wa_Lock(a2),d1			on se place sur le directory
	CALL _DosBase(a5),CurrentDir
	move.l d0,d7

	move.l wa_Name(a2),a0
	CALL _IconBase(a5),GetDiskObject
	tst.l d0
	beq.s no_getdiskobject

	move.l d0,a3
	move.l do_ToolTypes(a3),a4

* Recherche des ToolTypes
* ~~~~~~~~~~~~~~~~~~~~~~~
	st Flag_CX_POPUP(a5)
	move.l a4,a0				recherche CX_POPUP
	lea CX_POPUP_Str(pc),a1
	CALL FindToolType
	tst.l d0
	beq.s .no_cxpopup
	move.l d0,a0
	lea YES_Str(pc),a1
	CALL MatchToolValue
	tst.l d0
	sne Flag_CX_POPUP(a5)

.no_cxpopup
	move.l a4,a0				recherche CX_POPKEY
	lea CX_POPKEY_Str(pc),a1
	CALL FindToolType
	tst.l d0
	beq.s .no_cxpopkey
	move.l d0,a0
	lea xPKWin_POPKEY(pc),a1
.dup	move.b (a0)+,(a1)+
	bne.s .dup

.no_cxpopkey
	move.l a3,a0
	CALL FreeDiskObject

	move.l d7,d1
	CALL _DosBase(a5),CurrentDir

***************************************
* BUG: La becane plante lors de la récuperation
*      des arguments sous workbench...
*
*	subq.l #1,d2				\  becoz ya notre programme en premier
*	lea wa_SIZEOF(a2),a2			/
*	bsr Add_Selected
***************************************

	moveq #1,d0
	rts

no_getdiskobject
	move.l d7,d1
	CALL _DosBase(a5),CurrentDir
	moveq #0,d0
	rts



*************************************************************************************************
*                    AJOUTE DES FICHIERS OU DES DIR DANS LA LIST DES SELECTED
* en entrée: a2=WbArgs
*            d2=NumArgs
*************************************************************************************************
Loop_Add_Selected
	move.l d2,d6

* Alloue de la mémoire pour stocker le nom du fichier ou dir
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.l #LN_SIZE+6+256,d0		alloue de la mémoire pour le Node
	move.l #MEMF_ANY|MEMF_CLEAR,d1
	CALL _ExecBase(a5),AllocMem
	tst.l d0
	beq .no_mem
	move.l d0,a3

* Demande le nom logique du chemin
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.l wa_Lock(a2),d1
	beq.s .error
	move.l d0,d2
	add.l #LN_SIZE+6,d2
	move.l #256,d3
	CALL _DosBase(a5),NameFromLock
	tst.l d0
	beq.s .error

* Init la structure pour la gadtools ( LISTVIEW_KIND ) + écrit des info
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	lea LN_SIZE(a3),a0
	move.l a0,LN_NAME(a3)
	move.l wa_Name(a2),d0
	beq.s .dir
	move.l d0,a1
	tst.b (a1)
	beq.s .dir
.file
	move.l #"FILE",(a0)+
	move.w #": ",(a0)+

	move.l a0,d1				rajoute le nom du fichier à la fin du
	move.l wa_Name(a2),d2			directory
	move.l #256,d3
	CALL AddPart
	tst.l d0
	bne.s .insert				erreur ?

* Une erreur => libère la mémoire
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.error
	move.l a3,a1				retourne la mémoire au systeme
	move.l #LN_SIZE+6+256,d0
	CALL _ExecBase(a5),FreeMem
	bra.s .no_mem
.dir
	move.l #" DIR",(a0)+
	move.w #": ",(a0)

* Ici tout est Ok => Link le node dans la liste
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.insert
	lea Selected_List(pc),a0		ajoute le node à la liste
	move.l a3,a1
	ADDTAIL

	addq.w #1,Nb_Selected(a5)

* Passe au suivant si yen a encore
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.no_mem
	lea wa_SIZEOF(a2),a2
	move.l d6,d2
Add_Selected
	subq.l #1,d2
	bpl Loop_Add_Selected

no_more_selected
	rts


*************************************************************************************************
*                 LIBERE TOUS LES FICHIERS ET DIRS QUI SONT DANS LA LISTE SELECTED
*************************************************************************************************
Remove_Selected
	lea Selected_List(pc),a0		While (yen a encore dans la liste) do
	IFEMPTY a0,no_more_free_selected
	SUCC a0,a1
	bsr.s Free_Selected
	bra.s Remove_Selected
no_more_free_selected
	rts	


*************************************************************************************************
*                           LIBERE UN NODE DE LA LISTE SELECTED
* en entrée: a0=Selected_List
*            a1=*Node
*     Selected_Number et Nb_Selected sont mis à jour
*     d0-d1/a0-a1/a6 destroyed
*************************************************************************************************
Free_Selected
	move.w Selected_Number(a5),d0
	addq.w #1,d0
	cmp.w Nb_Selected(a5),d0
	bne.s .skip
	subq.w #1,Selected_Number(a5)
	bge.s .skip
	clr.w Selected_Number(a5)
.skip
	subq.w #1,Nb_Selected(a5)

	move.l a1,d0
	REMOVE
	move.l d0,a1
	move.l #LN_SIZE+6+256,d0
	CALL _ExecBase(a5),FreeMem
	rts


*************************************************************************************************
*               REAFFICHAGE DE LA LISTE SELECTED APRES MODIFICATION DE LA LISTE
*************************************************************************************************
Start_Update_Selected
	movem.l d0-d1/a0-a3/a6,-(sp)

	move.l Gadget_Selected(a5),a0
	move.l Window_Handle(a5),d0
	beq.s .no_update
	move.l d0,a1
	sub.l a2,a2
	lea ListViewSelectedSet_Tags(pc),a3
	move.w Selected_Number(a5),6(a3)
	move.l #-1,3*4(a3)
	CALL _GadToolsBase(a5),GT_SetGadgetAttrsA
.no_update
	movem.l (sp)+,d0-d1/a0-a3/a6
	rts


Update_Selected
	move.l Gadget_Selected(a5),a0
	move.l Window_Handle(a5),d0
	beq.s .no_update
	move.l d0,a1
	sub.l a2,a2
	lea ListViewSelectedSet_Tags(pc),a3
	move.w Selected_Number(a5),6(a3)
	move.l #Selected_List,3*4(a3)
	CALL _GadToolsBase(a5),GT_SetGadgetAttrsA
.no_update
	rts



*************************************************************************************************
*                                AFFICHE LES INFOS SUR UN PACKER
*************************************************************************************************
Display_Packer_Info
	moveq #0,d0
	move.l Window_RastPort(a5),a2
	move.l a2,a1
	CALL _GfxBase(a5),SetAPen

	move.w #INFO_X+2,d0			Efface le rectangle d'info
	move.w #INFO_Y+1,d1
	add.w Win_Top(a5),d1
	move.w #INFO_X+INFO_W-3,d2
	move.w #INFO_Y+INFO_H-2,d3
	add.w Win_Top(a5),d3
	move.l a2,a1
	CALL RectFill

	moveq #1,d0
	move.l a2,a1
	CALL SetAPen

	move.l #INFO_X+4,d0			Ecrit le nom du packer
	move.l #INFO_Y+3+8,d1
	add.w Win_Top(a5),d1
	move.l a2,a1
	CALL Move

	lea xPKWin_PackerInfoTags(pc),a0	recherche la description du packer
	move.w Packer_Number(a5),d0
	mulu.w #LN_SIZE+6,d0
	add.l #LN_SIZE,d0
	add.l Packers_Nodes(a5),d0
	move.l d0,4(a0)	
	CALL _XpkBase(a5),XpkQuery
	tst.l d0
	bne no_xpkquery_info

	lea xPKWin_PackerInfo+xpi_LongName(pc),a0
	move.l a0,a1
	moveq #~0,d0
.strlen	tst.b (a1)+
	dbeq d0,.strlen
	not.w d0
	move.l a2,a1
	CALL _GfxBase(a5),Text

	move.l #INFO_X+4,d0			Ecrit la description du packer
	move.l #INFO_Y+2+8+3+8,d1		1ère ligne
	add.w Win_Top(a5),d1
	move.l a2,a1
	CALL Move

	lea xPKWin_PackerInfo+xpi_Description(pc),a0
	move.l a0,a1
	moveq #0,d0
.search_all1
	move.w d0,d1
.search1
	move.b (a1)+,d2
	beq.s .zero1
	cmp.b #" ",d2
	bne.s .no_space1
	move.w d1,d0
.no_space1
	addq.w #1,d1
	cmp.w #42,d1
	bne.s .search1
	bra.s .disp1
.zero1
	move.w d1,d0
	lea (a0,d0.w),a3
	bra.s .skip1
.disp1
	lea 1(a0,d0.w),a3
.skip1
	move.l a2,a1
	CALL Text

	move.l #INFO_X+4,d0			Ecrit la description du packer
	move.l #INFO_Y+3+8+2+8+2+8,d1		2ème ligne
	add.w Win_Top(a5),d1
	move.l a2,a1
	CALL Move

	move.l a3,a0
	move.l a0,a1
	move.l a0,a1
	moveq #0,d0
.search_all2
	move.w d0,d1
.search2
	move.b (a1)+,d2
	beq.s .zero2
	cmp.b #" ",d2
	bne.s .no_space2
	move.w d1,d0
.no_space2
	addq.w #1,d1
	cmp.w #42,d1
	bne.s .search2
	bra.s .disp2
.zero2
	move.w d1,d0
.disp2
	move.l a2,a1
	CALL Text

* Regarde si le PassWord est autorisé
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.l xPKWin_PackerInfo+xpi_Flags(pc),d0
	and.l #XPKIF_ENCRYPTION|XPKIF_NEEDPASSWD,d0
	seq StringSet_Tags+4+3-_DataBase(a5)

	move.l Gadget_String(a5),a0
	move.l Window_Handle(a5),a1
	sub.l a2,a2
	lea StringSet_Tags(pc),a3
	CALL _GadToolsBase(a5),GT_SetGadgetAttrsA

* regarde si plusieurs modes existent
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.l xPKWin_PackerInfo+xpi_Flags(pc),d0
	and.l #XPKIF_MODES,d0
	seq SliderSet_Tags+3*4+3-_DataBase(a5)
	
* Met en place le packer et le DefMode pour XpkQuery
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.l xPKWin_PackerInfoTags+4(pc),Current_PackMethod(a5)
	tst.b Flag_Preserve_PackMode(a5)
	bne.s .preserve
	move.w xPKWin_PackerInfo+xpi_DefMode(pc),Current_PackMode(a5)
.preserve
	rts

no_xpkquery_info
	lea NoInfoOnPacker_Text(pc),a0
	move.l a2,a1
	moveq #NoInfoOnPacker_Size,d0
	CALL _GfxBase(a5),Text

	sf StringSet_Tags+4+3-_DataBase(a5)
	move.l Gadget_String(a5),a0
	move.l Window_Handle(a5),a1
	sub.l a2,a2
	lea StringSet_Tags(pc),a3
	CALL _GadToolsBase(a5),GT_SetGadgetAttrsA
	rts



*************************************************************************************************
*                                    AFFICHAGE DU MODE DE COMPACTAGE
*************************************************************************************************
Display_Packer_Mode
	moveq #0,d0
	move.l Window_RastPort(a5),a2
	move.l a2,a1
	CALL _GfxBase(a5),SetAPen

	move.w #109+12*8,d0			efface l'ancien Mode Info
	move.w #81,d1
	add.w Win_Top(a5),d1
	move.w #109+12*8+8*8,d2
	move.w #89,d3
	add.w Win_Top(a5),d3
	move.l a2,a1
	CALL RectFill

	moveq #1,d0				écrit maintenant le nom du packer
	move.l Window_RastPort(a5),a2
	move.l a2,a1
	CALL SetAPen

	move.w #109+12*8,d0
	moveq #88,d1
	add.w Win_Top(a5),d1
	move.l a2,a1
	CALL Move

	lea xPKWin_PackerModeTags(pc),a0	recherche des infos sur le mode
	move.l Current_PackMethod(a5),4(a0)
	move.w Current_PackMode(a5),3*4+2(a0)
	CALL _XpkBase(a5),XpkQuery
	tst.l d0
	bne.s .no_query

	lea xPKWin_PackerMode+xm_Description(pc),a0
	move.l a0,a1
	moveq #~0,d0
.strlen	tst.b (a1)+
	dbeq d0,.strlen
	not.w d0
	move.l a2,a1
	CALL _GfxBase(a5),Text

	move.l Gadget_Slider(a5),a0		met en marche ou non le slider
	move.w Current_PackMode(a5),Slider_Level-_DataBase(a5)
	move.l Window_Handle(a5),a1
	sub.l a2,a2
	lea SliderSet_Tags(pc),a3
	CALL _GadToolsBase(a5),GT_SetGadgetAttrsA
	rts

.no_query
	lea NoInfoOnMode_Text(pc),a0		bou.. une erreur !
	move.l a2,a1
	moveq #NoInfoOnMode_Size,d0
	CALL _GfxBase(a5),Text
	rts



*************************************************************************************************
*                                      ROUTINES UTILES
*************************************************************************************************

* Affichage de text
* ~~~~~~~~~~~~~~~~~
*   -->	d0=PosX
*	d1=PosY
*	d2=Nb Chars
*	a2=Window_RastPort
*	a3=*char à afficher
*	a5=_DataBase
*	a6=_GfxBase
Display_Text
	add.w Win_Top(a5),d1
	move.l a2,a1
	CALL Move

	move.l a3,a0
	move.l a2,a1
	move.w d2,d0
	CALL Text
	rts	


* Pour RawDoFmt d'exec
* ~~~~~~~~~~~~~~~~~~~~
Putch
	move.b d0,(a3)+
	rts


* Routine qui met la fenetre de TMC en Stand By
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Disable_xPKWindow
	move.l Window_Handle(a5),a0		met un pointeur busy
	lea BusyPtr_Tags(pc),a1
	st 4+3(a1)
	CALL _IntuitionBase(a5),SetWindowPointerA

	lea UnvisibleReq(pc),a0			met un request
	CALL InitRequester

	lea UnvisibleReq(pc),a0
	move.l Window_Handle(a5),a1
	CALL Request
	rts

* Routine qui réveille la fenetre de TMC
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Enable_xPKWindow
	lea UnvisibleReq(pc),a0			vire le request
	move.l Window_Handle(a5),a1
	CALL _IntuitionBase(a5),EndRequest

	move.l Window_Handle(a5),a0		remet le pointeur normal
	lea BusyPtr_Tags(pc),a1
	sf 4+3(a1)
	CALL SetWindowPointerA
	rts




*************************************************************************************************
*                                TOUTES LES TAGS POUR xPKWin
*************************************************************************************************

Window_Tags
	dc.l WA_Title,WindowTitle
	dc.l WA_ScreenTitle,ScreenTitle
Window_Left=*+6
	dc.l WA_Left,0
Window_Top=*+6
	dc.l WA_Top,0
	dc.l WA_Width,WINDOW_X
Window_Height=*+6
	dc.l WA_Height,WINDOW_Y
	dc.l WA_DragBar,TAG_TRUE
	dc.l WA_DepthGadget,TAG_TRUE
	dc.l WA_CloseGadget,TAG_TRUE
	dc.l WA_Activate,TAG_TRUE
	dc.l WA_Flags,WFLG_NEWLOOKMENUS
	dc.l WA_IDCMP,IDCMP_VANILLAKEY!IDCMP_MENUPICK!IDCMP_CLOSEWINDOW!IDCMP_REFRESHWINDOW!LISTVIEWIDCMP!SLIDERIDCMP!STRINGIDCMP!BUTTONIDCMP
Window_glist=*+4
	dc.l WA_Gadgets,0
Window_Screen=*+4
	dc.l WA_PubScreen,0
	dc.l TAG_DONE	


BevelTags
Bevel_VisualInfo=*+4
	dc.l GT_VisualInfo,0
	dc.l GTBB_Recessed,TAG_TRUE
	dc.l TAG_DONE
	

ListViewPackers_Tags
	dc.l GTLV_Selected,0
	dc.l GTLV_Top,0
	dc.l GTLV_ShowSelected,0
	dc.l LAYOUTA_Spacing,1
	dc.l GTLV_Labels,Packers_List
	dc.l TAG_DONE


ListViewSelected_Tags
	dc.l GTLV_Top,0
	dc.l GTLV_ShowSelected,0
	dc.l LAYOUTA_Spacing,1
ListViewSelectedSet_Tags
	dc.l GTLV_Selected,0
	dc.l GTLV_Labels,0
	dc.l TAG_DONE


Slider_Tags
	dc.l GTSL_Max,100
	dc.l GTSL_LevelFormat,LevelFormat_Str
	dc.l GTSL_MaxLevelLen,4
SliderSet_Tags
Slider_Level=*+6
	dc.l GTSL_Level,100
	dc.l GA_Disabled,0
	dc.l TAG_DONE


String_Tags
	dc.l GTST_MaxChars,31
	dc.l TAG_DONE

StringSet_Tags
	dc.l GA_Disabled,0
	dc.l TAG_DONE

Button_Tags
	dc.l GT_Underscore,'_'
	dc.l TAG_DONE


FileRequest_Tags
	dc.l ASLFR_InitialDrawer,Initial_Directory
	dc.l ASLFR_DoPatterns,TAG_TRUE
	dc.l ASLFR_DoMultiSelect,TAG_TRUE
FileRequestSet_Tags
	dc.l ASLFR_InitialLeftEdge,0
	dc.l ASLFR_InitialTopEdge,0
	dc.l ASLFR_InitialWidth,WINDOW_X
	dc.l ASLFR_InitialHeight,WINDOW_Y
FileRequest_Window=*+4
	dc.l ASLFR_Window,0
	dc.l ASLFR_SleepWindow,TAG_TRUE
	dc.l TAG_DONE



DirRequest_Tags
	dc.l ASLFR_InitialDrawer,Initial_Directory
	dc.l ASLFR_DrawersOnly,TAG_TRUE
DirRequestSet_Tags
	dc.l ASLFR_InitialLeftEdge,0
	dc.l ASLFR_InitialTopEdge,0
	dc.l ASLFR_InitialWidth,WINDOW_X
	dc.l ASLFR_InitialHeight,WINDOW_Y
DirRequest_Window=*+4
	dc.l ASLFR_Window,0
	dc.l ASLFR_SleepWindow,TAG_TRUE
	dc.l TAG_DONE


xPKWin_PackersListTags
	dc.l XPK_PackersQuery,xPKWin_PackersList
	dc.l TAG_DONE


xPKWin_PackerInfoTags
	dc.l XPK_PackMethod,0
	dc.l XPK_PackerQuery,xPKWin_PackerInfo
	dc.l TAG_DONE


xPKWin_PackerModeTags
	dc.l XPK_PackMethod,0
	dc.l XPK_PackMode,0
	dc.l XPK_ModeQuery,xPKWin_PackerMode
	dc.l TAG_DONE


Menus_Tags
	dc.l GTMN_NewLookMenus,TAG_TRUE
	dc.l TAG_DONE


BusyPtr_Tags
	dc.l WA_BusyPointer,0
	dc.l TAG_DONE


Examine_Tags
Examine_InName=*+4
	dc.l XPK_InName,0
	dc.l XPK_GetError,xPKErr_Str
	dc.l TAG_DONE
	

Pack_Tags
Pack_InName=*+4
	dc.l XPK_InName,0
	dc.l XPK_OutName,TempName
Pack_Method=*+4
	dc.l XPK_PackMethod,0
Pack_Mode=*+6
	dc.l XPK_PackMode,0
Pack_Password=*+4
	dc.l XPK_Password,0
	dc.l XPK_GetError,xPKErr_Str
	dc.l TAG_DONE


Unpack_Tags
Unpack_InName=*+4
	dc.l XPK_InName,0
	dc.l XPK_OutName,TempName
Unpack_Password=*+4
	dc.l XPK_Password,0
	dc.l XPK_GetError,xPKErr_Str
	dc.l TAG_DONE



*************************************************************************************************
*                              QUELQUES STRUCTURES POUR xPKWin
*************************************************************************************************

xPKWin_Menus

* Menu Project
* ~~~~~~~~~~~~
	dc.b NM_TITLE,0
	dc.l Project_Str,0
	dc.w 0
	dc.l 0,0

	dc.b NM_ITEM,0
	dc.l About_Str,About_Key
	dc.w 0
	dc.l 0,Display_About

	dc.b NM_ITEM,0
	dc.l NM_BARLABEL,0
	dc.w 0
	dc.l 0,0

	dc.b NM_ITEM,0
	dc.l Hide_Str,Hide_Key
	dc.w 0
	dc.l 0,Display_Icon

	dc.b NM_ITEM,0
	dc.l NM_BARLABEL,0
	dc.w 0
	dc.l 0,0

	dc.b NM_ITEM,0
	dc.l Quit_Str,Quit_Key
	dc.w 0
	dc.l 0,Quit_from_Menu

* Menu Tools
* ~~~~~~~~~~
	dc.b NM_TITLE,0
	dc.l Tools_Str,0
	dc.w 0
	dc.l 0,0

	dc.b NM_ITEM,0
	dc.l RemoveFiles_Str,RemoveFiles_Key
	dc.w 0
	dc.l 0,Remove_Files

	dc.b NM_ITEM,0
	dc.l RemoveDirs_Str,RemoveDirs_Key
	dc.w 0
	dc.l 0,Remove_Dirs

	dc.b NM_ITEM,0
	dc.l RemoveAll_Str,RemoveAll_Key
	dc.w 0
	dc.l 0,RemoveAll

* Menu Options
* ~~~~~~~~~~~~
	dc.b NM_TITLE,0
	dc.l Options_Str,0
	dc.w 0
	dc.l 0,0

	dc.b NM_ITEM,0
	dc.l KeepOriginal_Str,KeepOriginal_Key
	dc.w CHECKIT|MENUTOGGLE
	dc.l 0,Toggle_KeepOriginal

	dc.b NM_ITEM,0
	dc.l ForcePack_Str,ForcePack_Key
	dc.w CHECKIT|MENUTOGGLE
	dc.l 0,Toggle_ForcePack

	dc.b NM_ITEM,0
	dc.l PackInfo_Str,PackInfo_Key
	dc.w CHECKIT|MENUTOGGLE
	dc.l 0,Toggle_PackInfo

	dc.b NM_ITEM,0
	dc.l PackExecOnly_Str,PackExecOnly_Key
	dc.w CHECKIT|MENUTOGGLE
	dc.l 0,Toggle_PackExecOnly

	dc.b NM_ITEM,0
	dc.l NM_BARLABEL,0
	dc.w 0
	dc.l 0,0

	dc.b NM_ITEM,0
	dc.l SaveOptions_Str,SaveOptions_Key
	dc.w 0
	dc.l 0,Save_Options

	dc.b NM_END,0
	dc.l 0,0
	dc.w 0
	dc.l 0,0

CX_POPKEY_Ptr	dc.l xPKWin_POPKEY


xPKWin_PackersList
	ds.b xpl_SIZEOF


xPKWin_PackerInfo
	ds.b xpi_SIZEOF


xPKWin_PackerMode
	ds.b xm_SIZEOF


xPKWin_Icon
	dc.w 0			do_Magic
	dc.w 0			do_Version
	dc.l 0				gg_NextGadget
	dc.w 0				gg_LeftEdge
	dc.w 0				gg_TopEdge
	dc.w ICON_X			gg_Width
	dc.w ICON_Y			gg_Height
	dc.w GFLG_GADGHIMAGE		gg_Flags
	dc.w 0				gg_Activation
	dc.w 0				gg_GadgetType
	dc.l Icon_Render1		gg_GadgetRender
	dc.l Icon_Render2		gg_SelectRender
	dc.l 0				gg_GadgetText
	dc.l 0				gg_MutualExclude
	dc.l 0				gg_SpecialInfo
	dc.w 0				gg_SpecialID
	dc.l 0				gg_UserData
	dc.b 0			do_Type
	dc.b 0			do_PAD_BYTE
	dc.l 0			do_DefaultTool
	dc.l 0			do_ToolTypes
	dc.l NO_ICON_POSITION	do_CurrentX
	dc.l NO_ICON_POSITION	do_CurrentY
	dc.l 0			do_DrawerData
	dc.l 0			do_ToolWindow
	dc.l 0			do_StackSize

Icon_Render1
	dc.w 0			ig_LeftEdge
	dc.w 0			ig_TopEdge
	dc.w ICON_X		ig_Width
	dc.w ICON_Y		ig_Height
	dc.w ICON_DEPTH		ig_Depth
	dc.l Icon_Data1		ig_ImageData
	dc.b (1<<ICON_DEPTH)-1	ig_PlanePick
	dc.b 0			ig_PlaneOnOff
	dc.l 0			ig_NextImage

Icon_Render2
	dc.w 0			ig_LeftEdge
	dc.w 0			ig_TopEdge
	dc.w ICON_X		ig_Width
	dc.w ICON_Y		ig_Height
	dc.w ICON_DEPTH		ig_Depth
	dc.l Icon_Data2		ig_ImageData
	dc.b (1<<ICON_DEPTH)-1	ig_PlanePick
	dc.b 0			ig_PlaneOnOff
	dc.l 0			ig_NextImage


xPKWin_NewBroker
	dc.b NB_VERSION,0
	dc.l Commodity_Name
	dc.l Commodity_Title
	dc.l Commodity_Descr
	dc.w NBU_NOTIFY|NBU_UNIQUE
	dc.w COF_SHOW_HIDE
	dc.b 0,0
	dc.l 0
	dc.w 0


Packers_List
	ds.b LH_SIZE


Selected_List
	ds.b LH_SIZE


GadgetAttr
	dc.l TopazName
	dc.w 8
	dc.b FS_NORMAL
	dc.b FPF_ROMFONT


xPKWin_NewGadget
	ds.b gng_SIZEOF


xPKWin_EasyRequest
	dc.l es_SIZEOF
	dc.l 0
	dc.l EasyRequest_RequestName
	dc.l 0
	dc.l EasyRequest_GadFormat

UnvisibleReq
	ds.b rq_SIZEOF

xPK_Fib
	ds.b xf_SIZEOF



*************************************************************************************************
*                                TOUS LES CHARS PORU xPKWin
*************************************************************************************************

TopazName		dc.b "topaz.font",0
DosName			dc.b "dos.library",0
AslName			dc.b "asl.library",0
GfxName			dc.b "graphics.library",0
IntuitionName		dc.b "intuition.library",0
GadToolsName		dc.b "gadtools.library",0
XpkMasterName		dc.b "xpkmaster.library",0
WorkbenchName		dc.b "workbench.library",0
CommoditiesName		dc.b "commodities.library",0
IconName		dc.b "icon.library",0

Commodity_Name		dc.b "xPKWin",0
Commodity_Title		dc.b "xPKWin v"
			dc.b "0"+XPKWIN_VERSION,"."
			dc.b "0"+XPKWIN_REVISION
			IFD XPKWIN_BETA
			dc.b "ß"
			ENDC
			dc.b " ©1994 Pierre Chalamet",0
Commodity_Descr		dc.b "This is the Workbench version of XPK",0
xPKWin_POPKEY		dc.b "alt w",0
			ds.b 128-(*-xPKWin_POPKEY)

ScreenTitle		dc.b "xPKWin v"
			dc.b "0"+XPKWIN_VERSION,"."
			dc.b "0"+XPKWIN_REVISION
			IFD XPKWIN_BETA
			dc.b "ß"
			ENDC
			dc.b " Coded and Copyrighted in 1994 by Sync/DreamDealers",0
WindowTitleFormat	dc.b "xPKWin v"
			dc.b "0"+XPKWIN_VERSION,"."
			dc.b "0"+XPKWIN_REVISION
			IFD XPKWIN_BETA
			dc.b "ß"
			ENDC
			dc.b ": Hotkey = <%s>",0
WindowTitle		ds.b 128

Packer_Str		dc.b "Packers",0
Selected_Str		dc.b "Selected Files And Directories",0
AddFile_Str		dc.b "Add _File",0
AddDir_Str		dc.b "Add _Dir",0
Remove_Str		dc.b "_Remove",0
Pack_Str		dc.b "_Pack",0
Unpack_Str		dc.b "_Unpack",0
LevelFormat_Str		dc.b "%3ld%%",0

CX_POPUP_Str		dc.b "CX_POPUP",0
CX_POPKEY_Str		dc.b "CX_POPKEY",0
YES_Str			dc.b "Yes",0

Project_Str		dc.b "Project",0
About_Str		dc.b "About...",0
About_Key		dc.b "A",0
Hide_Str		dc.b "Hide",0
Hide_Key		dc.b "H",0
Quit_Str		dc.b "Quit",0
Quit_Key		dc.b "Q",0

Tools_Str		dc.b "Tools",0
RemoveFiles_Str		dc.b "Remove All Files",0
RemoveFiles_Key		dc.b "F",0
RemoveDirs_Str		dc.b "Remove All Directories",0
RemoveDirs_Key		dc.b "D",0
RemoveAll_Str		dc.b "Remove All Selected",0
RemoveAll_Key		dc.b "R",0

Options_Str		dc.b "Options",0
PackInfo_Str		dc.b "Pack #?.info",0
PackInfo_Key		dc.b "I",0
KeepOriginal_Str	dc.b "Keep Original",0
KeepOriginal_Key	dc.b "O",0
ForcePack_Str		dc.b "Force Packing",0
ForcePack_Key		dc.b "P",0
PackExecOnly_Str	dc.b "Pack Executables Only",0
PackExecOnly_Key	dc.b "E",0
SaveOptions_Str		dc.b "Save Options",0
SaveOptions_Key		dc.b "S",0

Description_Text	dc.b "Description"
Description_Size=*-Description_Text
Settings_Text		dc.b "Settings"
Settings_Size=*-Settings_Text
Efficiency_Text		dc.b "Efficiency:"
Efficiency_Size=*-Efficiency_Text
Password_Text		dc.b "PassWord:"
Password_Size=*-Password_Text
UnderLine_Text		dc.b "_"
NoInfoOnPacker_Text	dc.b "Can't get informations for this packer."
NoInfoOnPacker_Size=*-NoInfoOnPacker_Text
NoInfoOnMode_Text	dc.b "Can't get mode name"
NoInfoOnMode_Size=*-NoInfoOnMode_Text

EasyRequest_RequestName	dc.b "xPKWin Requester",0
AboutRequest_Str	dc.b "  xPKWin v"
			dc.b "0"+XPKWIN_VERSION,"."
			dc.b "0"+XPKWIN_REVISION
			IFD XPKWIN_BETA
			dc.b "ß"
			ENDC
			dc.b " ©1994 Pierre Chalamet",10
			dc.b 10
			dc.b "     You can contact me for bugs",10
			dc.b "     reports or improvements at:",10
			dc.b "          Pierre Chalamet",10
			dc.b "        5 Rue du 11 Octobre",10
			dc.b "     45140 St Jean de la Ruelle",10
			dc.b "              France",10
			dc.b 10
			dc.b "This program mat be freely distributed",10
			dc.b "    for non profit purposes only.",0

xPKErr_Str		ds.b XPKERRMSGSIZE

EasyRequest_GadFormat	dc.b "Ok",0

TempName		ds.b 256+4
Initial_Directory	ds.b 256


*************************************************************************************************
*                             TOUTES LES VARIABLES DE xPKWin
*************************************************************************************************

	CNOP 0,4
	rsset -DATA_OFFSET
DataBase_struct		rs.b 0
_ExecBase		rs.l 1
_DosBase		rs.l 1
_AslBase		rs.l 1
_GfxBase		rs.l 1
_IntuitionBase		rs.l 1
_GadToolsBase		rs.l 1
_XpkBase		rs.l 1
_WorkbenchBase		rs.l 1
_CxBase			rs.l 1
_IconBase		rs.l 1

xPKWin_Task		rs.l 1
CLI_Args		rs.l 0
CLI_Size		rs.l 1
CLI_Line		rs.l 1
WB_Msg			rs.l 1
Packers_Nodes		rs.l 1

Msg_Gadget		rs.l 1
Msg_Class		rs.l 1
Msg_Code		rs.w 1
Msg_Qualifier		rs.w 1
Msg_CxID		rs.l 1
Msg_CxType		rs.l 1
Msg_CxData		rs.l 1

Fib			rs.l 1
File_Requester		rs.l 1
Dir_Requester		rs.l 1

Gadget_Packers		rs.l 1
Gadget_Slider		rs.l 1
Gadget_String		rs.l 1
Gadget_Selected		rs.l 1
Gadget_AddFile		rs.l 1
Gadget_AddDir		rs.l 1
Gadget_Remove		rs.l 1
Gadget_Pack		rs.l 1
Gadget_Unpack		rs.l 1

Global_WaitMask		rs.l 1

Window_Font		rs.l 1
Window_PubScreen	rs.l 1
Window_VisualInfo	rs.l 1
Window_Handle		rs.l 1
Window_RastPort		rs.l 1
Window_MsgPort		rs.l 1
Window_WaitMask		rs.l 1
Window_MenuStrip	rs.l 1

App_MsgPort		rs.l 1
App_WaitMask		rs.l 1
AppWindow_Handle	rs.l 1
AppIcon_Handle		rs.l 1

Commodity_MsgPort	rs.l 1
Commodity_WaitMask	rs.l 1
Commodity_Broker	rs.l 1
Commodity_Filter	rs.l 1
Commodity_Sender	rs.l 1
Commodity_Translate	rs.l 1

Current_PackMethod	rs.l 1
Current_PackMode	rs.w 1
Packer_Number		rs.w 1
Selected_Number		rs.w 1
Nb_Selected		rs.w 1

Win_Top			rs.w 1

Flag_Preserve_PackMode	rs.b 1
Flag_Work_Pack		rs.b 1
Flag_CX_POPUP		rs.b 1
Flag_CX_PRIORITY	rs.b 1
Flag_PackInfo		rs.b 1
Flag_ForcePack		rs.b 1
Flag_KeepOriginal	rs.b 1
Flag_PackExecOnly	rs.b 1
DataBase_SIZEOF=__RS-DataBase_struct

_DataBase=*+DATA_OFFSET
	ds.b DataBase_SIZEOF


*************************************************************************************************
*                       UNE SECTION EN CHIP POUR STOCKER L'IMAGE DE L'ICON
*************************************************************************************************

	section Images,data_c
Icon_Data1
	incbin "Icon1.RAW"

Icon_Data2
	incbin "Icon2.RAW"



* end of file
