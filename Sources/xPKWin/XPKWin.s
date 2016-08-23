						
*		XPKWin v0.0  (c)1994 Pierre "Sync/DreamDealers" Chalamet
*		~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*			Last change : 





* Options de compilation Devpac 3
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	OPT P=68000
	OPT C+,O+,OW-
;;	OPT OW1+,OW6+
;;	OPT NODEBUG,NOLINE
	OPT CHKIMM
	OUTPUT ram:XPKWin

DATA_OFFSET=0


* Les includes de Mr Commodore...
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	incdir "hd1:Include/"
	include "exec/exec_lib.i"
	include "exec/execbase.i"
	include "exec/memory.i"
	include "exec/ports.i"
	include "exec/lists.i"
	include "graphics/graphics_lib.i"
	include "intuition/intuition_lib.i"
	include "intuition/intuition.i"
	include "dos/dos_lib.i"
	include "dos/dos.i"
	include "dos/dosextens.i"
	include "libraries/asl_lib.i"
	include "libraries/asl.i"
	include "libraries/gadtools_lib.i"
	include "libraries/gadtools.i"
	include "workbench/wb_lib.i"
	include "workbench/workbench.i"
	include "workbench/startup.i"
	include "utility/tagitem.i"
	include "libraries/commodities_lib.i"
	include "libraries/commodities.i"
	include "misc/macros.i"


* Quelques EQU
* ~~~~~~~~~~~~
WINDOW_X=460
WINDOW_Y=215

INFO_X=96+15
INFO_Y=10+8
INFO_W=WINDOW_X-(96+15+15)
INFO_H=38

ICON_X=38
ICON_Y=39
ICON_DEPTH=3

EVT_HOTKEY=1


* Hop Hop
* ~~~~~~~
	section WannaBeFame,code
Entry_Point
	bra.s skip_version
	dc.b '$VER: XPKWin v0.0  (c)1994 Pierre "Sync/DreamDealers" Chalamet',0
	even
skip_version
	lea _DataBase(pc),a5

	move.l (_SysBase).w,a6
	move.l a6,_ExecBase(a5)			copie d'ExecBase en FastRam!

	move.l ThisTask(a6),a3			recherche notre propre task

	tst.l pr_CLI(a3)			on démarre du CLI ?
	beq.s from_WB
from_CLI
	clr.b -1(a0,d0.l)
	move.l a0,CLI_Line(a5)
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
	move.l Msg_WB(a5),a1
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


* Installation de la commodity
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	bsr Install_Commodity
	beq no_commodity


* Fabrique la liste des packers
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	bsr Build_Packers_List


* Ouverture de la fonte Topaz 8
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	lea GadgetAttr(pc),a0			ouvre la topaz 8
	CALL _GfxBase(a5),OpenFont
	move.l d0,Win_Font(a5)
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
	move.l d1,App_WaitMask(a1)
	or.l d1,Global_WaitMask(a5)

	tst.b Cx_PopUp(a5)
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
	cmp.l #IDCMP_VANILLAKEY,d0		une touche ?
	beq.s Check_Key
	rts

* une gagdet a été cliqué : on le recherche
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Check_Gadget
	move.l Msg_Gadget(a5),a0
	move.w gg_GadgetID(a0),d0
	beq New_Packer				0
	subq.w #1,d0
	beq New_Efficiency			1
	subq.w #1,d0
	beq New_Password			2
	subq.w #1,d0
	beq New_Selected			3
	subq.w #1,d0
	beq Add_File				4
	subq.w #1,d0
	beq Add_Dir				5
	subq.w #1,d0
	beq Remove				6
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
	cmp.b #"W",d0				Password ?
	beq New_Password_Enter
	cmp.b #"F",d0				Add File ?
	beq Add_File
	cmp.b #"D",d0				Add Dir ?
	beq Add_Dir
	rts


***************************************
* On regarde si ca vient des AppTrucs *
***************************************
Check_for_App
	move.l App_MsgPort(a5),a0
	CALL _ExecBase(a5),GetMsg
	tst.l d0
	beq Check_for_Commodity

	move.l d0,-(sp)
	pea Reply_WB_Msg(pc)

	move.l d0,a0
	tst.l am_NumArgs(a0)			double click sur l'icon ?
	beq Display_Window
	rts

Reply_WB_Msg
	move.l (sp)+,a1
	CALL _ExecBase(a5),ReplyMsg
	bra Check_for_App


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

toto
	pea Check_for_Commodity(pc)		retourne direct là-haut...
	move.l Msg_CxType(a5),d0
	cmp.l #CXM_IEVENT,d0
	beq Check_HotKey
	cmp.l #CXM_COMMAND,d0
	beq Check_Command
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

* L'utilisateur n'a pas de souris.. activation du string gadget PassWord
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
New_Password_Enter
	move.l Gadget_String(a5),a0
	move.l Window_Handle(a5),a1
	sub.l a2,a2
	CALL _IntuitionBase(a5),ActivateGadget
	rts

New_Password
New_Packer
New_Efficiency
New_Selected
Remove
Pack
Unpack
	rts


* Ajout d'un fichier dans la liste à packer/depacker
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Add_File
	move.l File_Requester(a5),a0
	lea FileRequest_Tags(pc),a1
	bsr Replace_Requester
	CALL _AslBase(a5),AslRequest
	rts

* Ajout d'un directory dans la liste à packer/depacker
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Add_Dir
	move.l Dir_Requester(a5),a0
	lea DirRequest_Tags(pc),a1
	bsr Replace_Requester
	CALL _AslBase(a5),AslRequest
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
*                                   ON QUITTE TOUT !
*************************************************************************************************
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
	move.l Win_Font(a5),a1			ferme la fonte topaz
	CALL _GfxBase(a5),CloseFont
no_font
	bsr Remove_Commodity
no_commodity
	move.l _IconBase(a5),a1			ferme l'icon.library
	CALL _ExecBase(a5),CloseLibrary
no_tooltypes
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
	rts



*************************************************************************************************
*                             OUVERTURE DE LA FENETRE DE XPKWIN
* en sortie: Z=1(eq) si ERREUR
*************************************************************************************************
Install_Window
	sub.l a0,a0				lock le Wb en PubScreen
	CALL _IntuitionBase(a5),LockPubScreen
	move.l d0,Win_PubScreen(a5)
	move.l d0,Window_PubScreen-_DataBase(a5)
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
	move.l d0,Win_VisualInfo(a5)
	beq no_visualInfo

* Mise en place des gadgets de la fenetre
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	lea Window_glist(pc),a0			création d'un context pour
	CALL CreateContext			les gadgets de la gadtools

	move.w Win_Top(a5),d7

* Fabrique le ListView Packers
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	lea XPKWin_NewGadget(pc),a1		init la structure NewGadget
	move.w #15,gng_LeftEdge(a1)
	move.w #18,gng_TopEdge(a1)
	add.w d7,gng_TopEdge(a1)
	move.w #80,gng_Width(a1)
	move.w #92,gng_Height(a1)
	move.l #PackerText,gng_GadgetText(a1)
	move.l #GadgetAttr,gng_TextAttr(a1)
	clr.w gng_GadgetID(a1)			ID=0
	move.l #PLACETEXT_ABOVE|NG_HIGHLABEL,gng_Flags(a1)
	move.l Win_VisualInfo(a5),gng_VisualInfo(a1)

	move.l d0,a0				création d'une checkbox
	lea ListView_Tags(pc),a2		Optimize Samples
	move.l #LISTVIEW_KIND,d0
	CALL CreateGadgetA
	move.l d0,Gadget_Packers(a5)

* Fabrique le Slider Efficiency
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	lea XPKWin_NewGadget(pc),a1
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
	lea XPKWin_NewGadget(pc),a1
	move.w #445-200,gng_LeftEdge(a1)
	move.w #96,gng_TopEdge(a1)
	add.w d7,gng_TopEdge(a1)
	move.w #200,gng_Width(a1)
	move.w #14,gng_Height(a1)
	move.w #2,gng_GadgetID(a1)

	move.l d0,a0
	lea String_Tags(pc),a2
	move.l #STRING_KIND,d0
	CALL CreateGadgetA
	move.l d0,Gadget_String(a5)

* Fabrique le ListView Selected
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	lea XPKWin_NewGadget(pc),a1
	move.w #15,gng_LeftEdge(a1)
	move.w #133,gng_TopEdge(a1)
	add.w d7,gng_TopEdge(a1)
	move.w #430,gng_Width(a1)
	move.w #52,gng_Height(a1)
	move.w #3,gng_GadgetID(a1)
	move.l #SelectedText,gng_GadgetText(a1)

	move.l d0,a0
	lea ListView_Tags(pc),a2
	move.l #LISTVIEW_KIND,d0
	CALL CreateGadgetA
	move.l d0,Gadget_Selected(a5)

* Fabrique le Button Add File
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~
	lea XPKWin_NewGadget(pc),a1
	move.w #15,gng_LeftEdge(a1)
	move.w #195,gng_TopEdge(a1)
	add.w d7,gng_TopEdge(a1)
	move.w #78,gng_Width(a1)
	move.w #12,gng_Height(a1)
	move.w #4,gng_GadgetID(a1)
	move.l #PLACETEXT_IN,gng_Flags(a1)
	move.l #AddFileText,gng_GadgetText(a1)

	move.l d0,a0
	lea Button_Tags(pc),a2
	move.l #BUTTON_KIND,d0
	CALL CreateGadgetA
	move.l d0,Gadget_AddFile(a5)

* Fabrique le Button Add Dir
* ~~~~~~~~~~~~~~~~~~~~~~~~~~
	lea XPKWin_NewGadget(pc),a1
	add.w #85,gng_LeftEdge(a1)
	move.l #AddDirText,gng_GadgetText(a1)
	move.w #5,gng_GadgetID(a1)

	move.l d0,a0
	lea Button_Tags(pc),a2
	move.l #BUTTON_KIND,d0
	CALL CreateGadgetA
	move.l d0,Gadget_AddDir(a5)

* Fabrique le Button Remove
* ~~~~~~~~~~~~~~~~~~~~~~~~~
	lea XPKWin_NewGadget(pc),a1
	add.w #85,gng_LeftEdge(a1)
	move.l #RemoveText,gng_GadgetText(a1)
	move.w #6,gng_GadgetID(a1)

	move.l d0,a0
	lea Button_Tags(pc),a2
	move.l #BUTTON_KIND,d0
	CALL CreateGadgetA
	move.l d0,Gadget_Remove(a5)

* Fabrique le Button Pack
* ~~~~~~~~~~~~~~~~~~~~~~~
	lea XPKWin_NewGadget(pc),a1
	add.w #97,gng_LeftEdge(a1)
	move.l #PackText,gng_GadgetText(a1)
	move.w #7,gng_GadgetID(a1)

	move.l d0,a0
	lea Button_Tags(pc),a2
	move.l #BUTTON_KIND,d0
	CALL CreateGadgetA
	move.l d0,Gadget_Pack(a5)

* Fabrique le Button unpack
* ~~~~~~~~~~~~~~~~~~~~~~~~~
	lea XPKWin_NewGadget(pc),a1
	add.w #85,gng_LeftEdge(a1)
	move.l #UnpackText,gng_GadgetText(a1)
	move.w #8,gng_GadgetID(a1)

	move.l d0,a0
	lea Button_Tags(pc),a2
	move.l #BUTTON_KIND,d0
	CALL CreateGadgetA
	move.l d0,Gadget_Unpack(a5)
	beq no_gadgets				erreur dans les gadgets ?


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
	move.l Win_VisualInfo(a5),4(a1)
	move.l #INFO_X,d0			LeftEdge
	move.l #INFO_Y,d1			TopEdge
	add.w Win_Top(a5),d1
	move.l #INFO_W,d2			Width
	move.l #INFO_H,d3			Height
	CALL DrawBevelBoxA

* Ecrit dans la fenetre ce qu'il faut
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.l Win_Font(a5),a0			met la topaz 8 comme fonte
	move.l Window_RastPort(a5),a2
	move.l a2,a1
	CALL _GfxBase(a5),SetFont

* Affiche "Efficiency"
* ~~~~~~~~~~~~~~~~~~~~
	moveq #1,d0
	move.l a2,a1
	CALL SetAPen

	moveq #111,d0
	moveq #88,d1
	moveq #Efficiency_Size,d2
	lea EfficiencyText(pc),a3
	bsr Display_Text

* Affiche "Password"
* ~~~~~~~~~~~~~~~~~~
	move.w #111,d0
	moveq #105,d1
	moveq #Password_Size,d2
	lea PasswordText(pc),a3
	bsr Display_Text

* Affiche "Description"
* ~~~~~~~~~~~~~~~~~~~~~
	moveq #2,d0
	move.l a2,a1
	CALL SetAPen

	move.w #234,d0
	moveq #11,d1
	moveq #Description_Size,d2
	lea DescriptionText(pc),a3
	bsr Display_Text

* Affiche "Settings"
* ~~~~~~~~~~~~~~~~~~
	move.w #246,d0
	moveq #73,d1
	moveq #Settings_Size,d2
	lea SettingsText(pc),a3
	bsr Display_Text
	
* Affiche les Underlines des "Efficiency" et "Password"
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	moveq #1,d0
	moveq #2,d1
	moveq #RP_JAM1,d2
	move.l a2,a1
	CALL SetABPenDrMd

	moveq #111,d0
	moveq #88,d1
	moveq #EfficiencyUnder_Size,d2
	lea EfficiencyUnderText(pc),a3
	bsr Display_Text

	move.w #111,d0
	moveq #105,d1
	moveq #PasswordUnder_Size,d2
	lea PasswordUnderText(pc),a3
	bsr Display_Text

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
	rts


*************************************************************************************************
*                              FERMETURE DE LA FENETRE DE XPKWIN
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
	move.l Window_Handle(a5),a0		ferme la fenetre
	CALL _IntuitionBase(a5),CloseWindow
no_openwindow
	move.l Window_glist(pc),a0		vire les gadgets
	CALL _GadToolsBase(a5),FreeGadgets
no_gadgets
no_createcontext
	move.l Win_VisualInfo(a5),a0		libère le VisualInfo sur l'écran publique
	CALL FreeVisualInfo
no_visualInfo
	sub.l a0,a0				libère l'écran publique
	move.l Win_PubScreen(a5),a1
	CALL _IntuitionBase(a5),UnlockPubScreen
no_pubscreen
	clr.l Window_MsgPort(a5)
	clr.l AppWindow_Handle(a5)
no_closewindow
	rts



*************************************************************************************************
*                          INSTALLE L'ICON DE XPKWIN SUR L'ECRAN DU WB
* en sortie: Z=1(eq) si ERREUR
*************************************************************************************************
Install_Icon
	moveq #0,d0
	moveq #0,d1
	lea Commodity_Name(pc),a0
	move.l App_MsgPort(a5),a1
	sub.l a2,a2
	lea XPKWin_Icon(pc),a3
	sub.l a4,a4
	CALL _WorkbenchBase(a5),AddAppIconA
	move.l d0,AppIcon_Handle(a5)
	rts


*************************************************************************************************
*                            VIRE L'ICON DE XPKWIN DE L'ECRAN DU WB
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

	lea XPKWin_NewBroker(pc),a0		fabrication d'un Broker
	move.l Commodity_MsgPort(a5),nb_Port(a0)
	moveq #0,d0
	CALL _CxBase(a5),CxBroker
	move.l d0,Commodity_Broker(a5)
	beq no_broker

	move.l #CX_FILTER,d0			fabrication d'un Filter
	lea XPKWin_Filter(pc),a0
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
	bne no_cxobjerror

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
	tst.l CLI_Line(a5)
	beq WB_ToolTypes

CLI_ToolTypes
	moveq #1,d0
	rts


WB_ToolTypes
	move.l WB_Msg(a5),a2
	move.l sm_ArgList(a2),a2		recherche le WBArg de notre programme

	move.l wa_Lock(a5),d1			on se place sur le directory
	CALL _DosBase(a5),CurrentDir
	move.l d0,d7

	move.l wa_Name(a5),a0
	CALL _IconBase(a5),GetDiskObject
	tst.l d0
	beq no_getdiskobject

	move.l d0,a2
	move.l do_ToolTypes(a2),a3

* Recherche des ToolTypes
* ~~~~~~~~~~~~~~~~~~~~~~~
	st Flag_CX_POPUP(a5)
	move.l a3,a0				recherche CX_POPUP
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
	move.l #
	move.l a3,a0				recherche CX_POPKEY
	lea CX_POPKEY_Str(pc),a1
	CALL FindToolType
	tst.l d0
	



no_getdiskobject
	move.l d7,d1
	CALL _DosBase(a5),CurrentDir
	moveq #0,d0
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




*************************************************************************************************
*                                TOUTES LES DATAS DE XPKWIN
*************************************************************************************************
XPKWin_Icon
	dc.w 0			do_Magic
	dc.w 0			do_Version
	dc.l 0				gg_NExtGadget
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

Icon_Data1
	incbin "Icon1.RAW"

Icon_Data2
	incbin "Icon2.RAW"



XPKWin_NewBroker
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
	dcb.b LH_SIZE,0

GadgetAttr
	dc.l TopazName
	dc.w 8
	dc.b FS_NORMAL
	dc.b FPF_ROMFONT

XPKWin_NewGadget
	dcb.b gng_SIZEOF,0


Window_Tags
	dc.l WA_Title,WindowTitle
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
	dc.l WA_RMBTrap,TAG_TRUE
	dc.l WA_IDCMP,IDCMP_VANILLAKEY!IDCMP_CLOSEWINDOW!IDCMP_REFRESHWINDOW!LISTVIEWIDCMP!SLIDERIDCMP!STRINGIDCMP!BUTTONIDCMP
Window_glist=*+4
	dc.l WA_Gadgets,0
Window_PubScreen=*+4
	dc.l WA_PubScreen,0
	dc.l TAG_DONE	


BevelTags
Bevel_VisualInfo=*+4
	dc.l GT_VisualInfo,0
	dc.l GTBB_Recessed,TAG_TRUE
	dc.l TAG_DONE
	
ListView_Tags
	dc.l GTLV_Labels,Packers_List
	dc.l GTLV_Top,0
	dc.l TAG_DONE

Slider_Tags
	dc.l GTSL_Max,100
	dc.l GTSL_LevelFormat,LevelFormatStr
	dc.l GTSL_MaxLevelLen,4
SliderSet_Tags
Slider_Level=*+6
	dc.l GTSL_Level,100
	dc.l TAG_DONE


String_Tags
	dc.l GTST_MaxChars,31
	dc.l TAG_DONE

Button_Tags
	dc.l GT_Underscore,'_'
	dc.l TAG_DONE

FileRequest_Tags
	dc.l ASLFR_InitialLeftEdge,0
	dc.l ASLFR_InitialTopEdge,0
	dc.l ASLFR_InitialWidth,WINDOW_X
	dc.l ASLFR_InitialHeight,WINDOW_Y
FileRequest_Window=*+4
	dc.l ASLFR_Window,0
	dc.l ASLFR_SleepWindow,TAG_TRUE
	dc.l ASLFR_DoPatterns,TAG_TRUE
	dc.l ASLFR_DoMultiSelect,TAG_TRUE
	dc.l TAG_DONE

DirRequest_Tags
	dc.l ASLFR_InitialLeftEdge,0
	dc.l ASLFR_InitialTopEdge,0
	dc.l ASLFR_InitialWidth,WINDOW_X
	dc.l ASLFR_InitialHeight,WINDOW_Y
DirRequest_Window=*+4
	dc.l ASLFR_Window,0
	dc.l ASLFR_SleepWindow,TAG_TRUE
	dc.l ASLFR_DrawersOnly,TAG_TRUE
	dc.l TAG_DONE
	

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

Commodity_Name		dc.b "XPKWin",0
Commodity_Title		dc.b "XPKWin v0.0 ©1994 Pierre Chalamet",0
Commodity_Descr		dc.b "This is the Workbench version of XPK",0
Default_CX_POPKEY	dc.b "alt w",0

WindowTitle		dc.b "XPKWin v0.0: Hotkey = <alt w>",0
PackerText		dc.b "Packers",0
DescriptionText		dc.b "Description"
Description_Size=*-DescriptionText
SettingsText		dc.b "Settings"
Settings_Size=*-SettingsText
EfficiencyText		dc.b "Efficiency:"
Efficiency_Size=*-EfficiencyText
EfficiencyUnderText	dc.b "_"
EfficiencyUnder_Size=*-EfficiencyUnderText
PasswordText		dc.b "PassWord:"
Password_Size=*-PasswordText
PasswordUnderText	dc.b "    _"
PasswordUnder_Size=*-PasswordUnderText
SelectedText		dc.b "Selected Files And Directories",0
AddFileText		dc.b "Add _File",0
AddDirText		dc.b "Add _Dir",0
RemoveText		dc.b "_Remove",0
PackText		dc.b "_Pack",0
UnpackText		dc.b "_Unpack",0
LevelFormatStr		dc.b "%3ld%%",0


	CNOP 0,4
DataBase_struct		rs.b -DATA_OFFSET
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

CLI_Line		rs.l 1
WB_Msg			rs.l 1

Msg_Gadget		rs.l 1
Msg_Class		rs.l 1
Msg_Code		rs.w 1
Msg_Qualifier		rs.w 1
Msg_CxID		rs.l 1
Msg_CxType		rs.l 1
Msg_CxData		rs.l 1

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

Win_Font		rs.l 1
Win_PubScreen		rs.l 1
Win_VisualInfo		rs.l 1
Window_Handle		rs.l 1
Window_RastPort		rs.l 1
Window_MsgPort		rs.l 1
Window_WaitMask		rs.l 1

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

Win_Top			rs.w 1



Cx_PopUp		rs.b 1
Cx_Priority		rs.b 1
DataBase_SIZEOF=__RS-DataBase_struct

_DataBase=*+DATA_OFFSET
	ds.b DataBase_SIZEOF




* end of file
