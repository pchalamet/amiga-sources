
*		The Module Converter v5.1   ©1993-1995 Sync/DRD
*		-------------------------------------------------->
*			Last change : 28 Juillet 1995


* Description des differents codages
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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


* Options de compilation Devpac 3
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	OPT P=68000
	opt C+
	OPT O+,OW-,OW1+,OW6+
	opt NODEBUG,NOLINE,NOHCLN


* Les includes de Mr Commodore...
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	incdir "hd1:Include/"
	include "exec/exec_lib.i"
	include "exec/execbase.i"
	include "exec/memory.i"
	include "exec/ports.i"
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
	include "misc/macros.i"

* Structure d'une module SoundTracker 31 instruments
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	rsreset
module_struct	rs.b 0
ms_SongName	rs.b 20
ms_SampName	rs.b 22
ms_SampSize	rs.w 1
ms_SampFine	rs.b 1
ms_SampVol	rs.b 1
ms_SampRepeat	rs.w 1
ms_SampRepLen	rs.w 1
ms_SampSIZEOF	EQU __RS-ms_SampName
ms_SampOthers	rs.b ms_SampSIZEOF*30
ms_Length	rs.b 1
ms_Restart	rs.b 1
ms_Positions	rs.b 128
ms_Mark		rs.b 4
ms_Patterns	rs.b 0

* Structure pour l'allocation des differentes Mark pour l'utilisateur
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	rsreset
Mark_struct	rs.b 0
ma_Next		rs.l 1
ma_Mark		rs.l 1
ma_SIZEOF	rs.b 0

* Ca commence ici !
* ~~~~~~~~~~~~~~~~~
Entry_Point
	bra.s skip_copyright
	dc.b "$VER: TMC v5.1 (28/07/1995) ©1993-1995 Sync of DreamDealers",0
	even
skip_copyright
	lea data_base(pc),a5

	move.l 4.w,a6
	move.l a6,_ExecBase-data_base(a5)	copie d'ExecBase en FastRam!

	move.l ThisTask(a6),a3			recherche notre propre task

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
	CALL _ExecBase(pc),Forbid
	move.l (sp)+,a1
	CALL ReplyMsg				retourne le WB message
	moveq #0,d0
	rts

_main	
;	move.w AttnFlags(a6),d0			68020 au minimum... arf!!!
;	btst #AFB_68020,d0
;	beq no_micropro

	lea DosName(pc),a1			ouvre la dos.library
	moveq #39,d0
	CALL OpenLibrary
	move.l d0,_DosBase-data_base(a5)
	beq no_dos

	lea AslName(pc),a1			ouvre l'asl.library
	moveq #39,d0
	CALL OpenLibrary
	move.l d0,_AslBase-data_base(a5)
	beq no_asl

	lea GfxName(pc),a1			ouvre la graphics.library
	moveq #39,d0
	CALL OpenLibrary
	move.l d0,_GfxBase-data_base(a5)
	beq no_gfx

	lea IntuitionName(pc),a1		ouvre l'intuition.library
	moveq #39,d0
	CALL OpenLibrary
	move.l d0,_IntuitionBase-data_base(a5)
	beq no_intuition

	lea GadToolsName(pc),a1			ouvre la gadtools.library
	moveq #39,d0
	CALL OpenLibrary
	move.l d0,_GadToolsBase-data_base(a5)
	beq no_gadtools

	lea PowerpackerName(pc),a1		ouvre la powerpacker.library
	moveq #0,d0
	CALL OpenLibrary
	move.l d0,_PowerpackerBase-data_base(a5)
	bne.s ok_powerpacker

* Alloue un File Info Block avec la dos.library
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.l #DOS_FIB,d1			si on a échoué à l'ouverture
	moveq #0,d2				de la powerpacker on se
	CALL _DosBase(pc),AllocDosObject	chargera nous même de charger
	move.l d0,TMC_Fib-data_base(a5)		le module en mémoire
	beq no_fib

* On s'occuppe d'ouvrir correctement une fenetre
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
ok_powerpacker
	lea GadgetAttr(pc),a0			ouvre la topaz 8
	CALL _GfxBase(pc),OpenFont
	move.l d0,TMC_Font-data_base(a5)
	beq no_font

	sub.l a0,a0				lock le Wb en PubScreen
	CALL _IntuitionBase(pc),LockPubScreen
	move.l d0,TMC_PubScreen-data_base(a5)
	beq no_pubscreen

	move.l d0,a0				recherche la taille de la
	moveq #0,d0
	move.b sc_WBorTop(a0),d0		barre de la fenetre
	move.l sc_Font(a0),a1
	add.w ta_YSize(a1),d0
	addq.w #1,d0
	move.w d0,TMC_Top-data_base(a5)

	move.w sc_Width(a0),d0			recentre la fenetre à l'écran
	sub.w #400,d0
	lsr.w #1,d0
	move.w d0,WindowTags+14-data_base(a5)

	move.w sc_Height(a0),d0
	sub.w #152,d0
	lsr.w #2,d0
	move.w d0,WindowTags+22-data_base(a5)

	sub.l a1,a1				recherche les informations
	CALL _GadToolsBase(pc),GetVisualInfoA	d'affichage
	move.l d0,TMC_VisualInfo-data_base(a5)
	beq no_visualinfo

	lea TMC_glist(pc),a0			création d'un context pour
	CALL CreateContext			les gadgets de la gadtools

* Creation d'une Checkbox : Optimize Samples
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	lea TMC_NewGadget(pc),a1		init la structure NewGadget
	move.w #15,gng_LeftEdge(a1)		- inchangée avec CreateGagdet -
	move.w TMC_Top(pc),gng_TopEdge(a1)	dixit les RKM !!!
	add.w #8,gng_TopEdge(a1)
	move.w #26,gng_Width(a1)
	move.w #13,gng_Height(a1)
	move.l #OptimizeText,gng_GadgetText(a1)
	move.l #GadgetAttr,gng_TextAttr(a1)
	clr.w gng_GadgetID(a1)			ID=0
	move.l #PLACETEXT_RIGHT,gng_Flags(a1)
	move.l TMC_VisualInfo(pc),gng_VisualInfo(a1)

	move.l d0,a0				création d'une checkbox
	lea CheckBoxTags(pc),a2			Optimize Samples
	move.l #CHECKBOX_KIND,d0
	CALL CreateGadgetA
	move.l d0,SampleGadget-data_base(a5)

* Création d'un Cycle gadget pour choisir la sauvegarde
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	lea TMC_NewGadget(pc),a1
	add.w #20,gng_TopEdge(a1)
	move.w #160,gng_Width(a1)
	clr.l gng_GadgetText(a1)
	addq.w #1,gng_GadgetID(a1)		ID=1

	move.l d0,a0				création d'un cycle gadget
	lea CycleTags(pc),a2			One File Source
	move.l #CYCLE_KIND,d0			Splitted Source
	CALL CreateGadgetA			LoadSeg() Module
	move.l d0,SaveGadget-data_base(a5)

* Création d'une CheckBox : Save SongName
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	lea TMC_NewGadget(pc),a1
	move.w #359,gng_LeftEdge(a1)
	sub.w #20,gng_TopEdge(a1)
	move.w #26,gng_Width(a1)
	move.l #SaveText,gng_GadgetText(a1)
	addq.w #1,gng_GadgetID(a1)		ID=2
	move.l #PLACETEXT_LEFT,gng_Flags(a1)

	move.l d0,a0
	lea CheckBoxTags(pc),a2
	move.l #CHECKBOX_KIND,d0
	CALL CreateGadgetA
	move.l d0,CreateGadget-data_base(a5)

* Création d'un Slider : Averall volume
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	lea TMC_NewGadget(pc),a1
	move.w #285,gng_LeftEdge(a1)
	add.w #20,gng_TopEdge(a1)
	move.w #100,gng_Width(a1)
	move.l #VolumeText,gng_GadgetText(a1)
	addq.w #1,gng_GadgetID(a1)		ID=3

	move.l d0,a0
	lea SliderTags(pc),a2
	move.l #SLIDER_KIND,d0
	CALL CreateGadgetA
	move.l d0,VolumeGadget-data_base(a5)

* Création d'un Button : Convert Module
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	lea TMC_NewGadget(pc),a1
	move.w #45,gng_LeftEdge(a1)
	add.w #20,gng_TopEdge(a1)
	move.w #140,gng_Width(a1)
	move.w #12,gng_Height(a1)
	move.l #ConvertText,gng_GadgetText(a1)
	addq.w #1,gng_GadgetID(a1)		ID=4
	move.l #PLACETEXT_IN,gng_Flags(a1)

	move.l d0,a0				création du gadget "Convert"
	lea ButtonTags(pc),a2
	move.l #BUTTON_KIND,d0
	CALL CreateGadgetA

* Création d'un Button : About
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	lea TMC_NewGadget(pc),a1
	move.w #215,gng_LeftEdge(a1)
	move.l #AboutText,gng_GadgetText(a1)
	addq.w #1,gng_GadgetID(a1)		ID=5

	move.l d0,a0				création du gadget "About"
	lea ButtonTags(pc),a2
	move.l #BUTTON_KIND,d0
	CALL CreateGadgetA

* Création d'un Button : Change Output Directory
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	lea TMC_NewGadget(pc),a1
	move.w #70,gng_LeftEdge(a1)
	add.w #20,gng_TopEdge(a1)
	move.w #260,gng_Width(a1)
	move.l #DirText,gng_GadgetText(a1)
	addq.w #1,gng_GadgetID(a1)		ID=6

	move.l d0,a0				création du gadget "Dir"
	lea ButtonTags(pc),a2
	move.l #BUTTON_KIND,d0
	CALL CreateGadgetA

	tst.l d0				une erreur dans la création
	beq no_gadgets				des gagdets ?

* Ouverture de la fenêtre avec les gadgets de la GadTools
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	sub.l a0,a0				ouvre la fenetre
	lea WindowTags(pc),a1
	move.w TMC_Top(pc),d0
	add.w d0,38(a1)
	CALL _IntuitionBase(pc),OpenWindowTagList
	move.l d0,WindowHandle-data_base(a5)
	move.l d0,TMC_FrTags_Select+4-data_base(a5)
	move.l d0,TMC_FrTags_Dir+4-data_base(a5)
	beq no_window

	move.l d0,a0				retrace les gadgets de la 
	sub.l a1,a1				gadtools
	CALL _GadToolsBase(pc),GT_RefreshWindow

* Tracage d'une BevelBox pour l'encadrement de l'affichage des textes
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.l WindowHandle(pc),a0
	move.l wd_RPort(a0),a0
	lea BevelTags(pc),a1
	move.l TMC_VisualInfo(pc),4(a1)		GT_VisualInfo,(TMC_VisualInfo)
	moveq #20,d0				LeftEdge
	moveq #88,d1				TopEdge
	add.w TMC_Top(pc),d1
	move.w #360,d2				Width
	move.w #52,d3				Height
	CALL DrawBevelBoxA

* Recherche des datas qui sont utiles par la suite
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.l WindowHandle(pc),a0
	move.l wd_RPort(a0),TMC_RastPort-data_base(a5)
	move.l wd_UserPort(a0),a0
	move.l a0,TMC_UserPort-data_base(a5)
	move.b MP_SIGBIT(a0),d0
	moveq #0,d1
	bset d0,d1
	move.l d1,TMC_SigBit-data_base(a5)

* Pas de DOS requester 
* ~~~~~~~~~~~~~~~~~~~~
	move.l _ExecBase(pc),a6			vire les requesters
	move.l ThisTask(a6),a6
	move.l pr_WindowPtr(a6),save_WindowPtr-data_base(a5)
	moveq #-1,d0
	move.l d0,pr_WindowPtr(a6)

* Mise en place d'un fond pour le ScrollText et met en place PenA & PenB
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.l TMC_Font(pc),a0			met la topaz 8 comme font
	move.l TMC_RastPort(pc),a1
	CALL _GfxBase(pc),SetFont

	moveq #3,d0
	move.l TMC_RastPort(pc),a1
	CALL SetAPen

	moveq #22,d0				minX
	moveq #89,d1				minY
	add.w TMC_Top(pc),d1
	move.w #21+356,d2			maxX
	move.w #89+49,d3			maxY
	add.w TMC_Top(pc),d3
	move.l TMC_RastPort(pc),a1
	CALL RectFill

	moveq #2,d0
	move.l TMC_RastPort(pc),a1
	CALL SetAPen

	moveq #3,d0
	move.l TMC_RastPort(pc),a1
	CALL SetBPen

* On essait de transformer la fenetre en AppWindow
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	lea WorkbenchName(pc),a1		ouvre la workbench.library
	moveq #0,d0
	CALL _ExecBase(pc),OpenLibrary
	move.l d0,_WorkbenchBase-data_base(a5)
	beq.s no_workbench

	CALL CreateMsgPort			création d'un MsgPort pour
	move.l d0,TMC_MsgPort-data_base(a5)	l'AppWindow
	beq.s no_msgport

	move.l d0,a1				fabrication du mask pour
	move.b MP_SIGBIT(a1),d0			attendre les messages
	moveq #0,d7				de l'AppWindow
	bset d0,d7				MP_SIGMASK

	moveq #0,d0				id
	moveq #0,d1				userdata
	move.l WindowHandle(pc),a0
	sub.l a2,a2
	CALL _WorkbenchBase(pc),AddAppWindowA
	move.l d0,TMC_AppWindow-data_base(a5)
	bne.s no_workbench			erreur ?
no_appwindow
	move.l TMC_MsgPort(pc),a0		vire le MsgPort
	CALL _ExecBase(pc),DeleteMsgPort
	clr.l TMC_MsgPort-data_base(a5)
no_msgport
	move.l _WorkbenchBase(pc),a1		ferme la workbench.library si
	CALL _ExecBase(pc),CloseLibrary		erreur => on sauve de la
	clr.l _WorkbenchBase-data_base(a5)	mémoire !!
	moveq #0,d7				pas de SigMask
no_workbench
	or.l d7,TMC_SigBit-data_base(a5)

* Chargement des préférences
* ~~~~~~~~~~~~~~~~~~~~~~~~~~
	bsr Load_Prefs				va lire les preferences


* mise en avant de l'écran de TMC
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.l TMC_PubScreen(pc),a0
	CALL _IntuitionBase(pc),ScreenToFront


* Attente d'un évènement au travers de la GadTools
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Wait_Event
	moveq #WaitSize,d0			affiche "TMC waits.."
	lea WaitMsg(pc),a0
	bsr PrintText

Wait_Next
	move.l TMC_SigBit(pc),d0		attend un signal
	CALL _ExecBase(pc),Wait

	move.l TMC_UserPort(pc),a0		ca vient de la GadTools ?
	CALL _GadToolsBase(pc),GT_GetIMsg
	tst.l d0
	beq WB_Event

	move.l d0,a1
	move.l im_IAddress(a1),TMC_Gadget-data_base(a5)
	move.l im_Class(a1),TMC_Class-data_base(a5)
	move.w im_Code(a1),TMC_Code-data_base(a5)
	move.w im_Qualifier(a1),TMC_Qualifier-data_base(a5)
	
	CALL GT_ReplyIMsg

	move.l TMC_Class(pc),d0
	cmp.l #IDCMP_CLOSEWINDOW,d0		on sort ?
	beq Quit
	cmp.l #IDCMP_GADGETDOWN,d0		un gadget de clické ?
	beq.s Check_Which_Gadget
	cmp.l #IDCMP_GADGETUP,d0		un gadget de clické ?
	beq.s Check_Which_Gadget
	cmp.l #IDCMP_VANILLAKEY,d0		une touche ?
	beq.s Check_Which_Key
	cmp.l #IDCMP_MOUSEMOVE,d0		le slider a bougé ?
	beq VolumeOpt_Change_Click
	cmp.l #IDCMP_REFRESHWINDOW,d0		faut retracer ?
	beq Gad_Refresh
	bra.s Wait_Next

Check_Which_Gadget
	move.l TMC_Gadget(pc),a0		*Gadget -ATTENTION!!-
	move.w gg_GadgetID(a0),d0
	beq SampleOpt_Change			ID=0 ?	Sample Opt
	subq.w #1,d0
	beq SaveOpt_Change			ID=1	Split Module
	subq.w #1,d0
	beq CreateOpt_Change			ID=2 ?	Create Directory
	subq.w #2,d0
	beq ConvertModule			ID=4 ?	Convert
	subq.w #1,d0
	beq DisplayAbout			ID=5 ?	About
	subq.w #1,d0
	beq Change_Dir				ID=6 ?	Change Dir
	bra Wait_Next				devrait jamais aller ici...

Check_Which_Key
	move.w TMC_Code(pc),d0
	cmp.w #"a",d0				transforme d'abord la lettre
	blt.s .ok				en majuscule histoire de
	cmp.w #"z",d0				pas faire chier...
	bgt.s .ok
	add.w #"A"-"a",d0
.ok
	cmp.w #"Q",d0
	beq Quit
	cmp.w #"O",d0
	beq SampleOpt_Change
	cmp.w #"S",d0
	beq SaveOpt_Change
	cmp.w #"C",d0
	beq CreateOpt_Change
	cmp.w #"V",d0
	beq VolumeOpt_Change_Key
	cmp.w #"M",d0
	beq ConvertModule
	cmp.w #"A",d0
	beq DisplayAbout
	cmp.w #"D",d0
	beq Change_Dir
	bra Wait_Next

Gad_Refresh
	move.l WindowHandle(pc),a0
	CALL _GadToolsBase(pc),GT_BeginRefresh
	move.l WindowHandle(pc),a0
	move.l #TAG_TRUE,d0
	CALL GT_EndRefresh
	bra Wait_Next

* Un icon a été laché dans la fenetre => on convertit le module
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
WB_Event
	move.l TMC_MsgPort(pc),a0		non... donc ca vient du WB !
	CALL _ExecBase(pc),GetMsg
	tst.l d0				ya au moins un Msg ???!!
	beq Wait_Next
	move.l d0,a3				*WbMsg

	move.l sp,save_SP-data_base(a5)		sauve le pointeur de pile

	bsr SleepTMC

	cmp.l #1,am_NumArgs(a3)			on en veut qu'1 seul sinon ya
	bne.s WB_Too_Much			indigestion !!!
	move.l am_ArgList(a3),a4		*WBArg

	move.l wa_Lock(a4),d1			on se fixe sur ce directory
	CALL _DosBase(pc),DupLock		si on peut...
	move.l d0,d1
	beq.s WB_Error_DupLock
	CALL CurrentDir
	move.l d0,d1				libère le lock d'avant
	CALL UnLock

	move.l _PowerpackerBase(pc),d0		la powerpacker est là ?
	bne.s .pp_there

	move.l wa_Name(a4),d1			obtient un lock sur ce fichier
	moveq #ACCESS_READ,d2
	CALL Lock
	move.l d0,InputLock-data_base(a5)
	beq.s WB_Error_Lock

.pp_there
	move.l wa_Name(a4),a0			recopie le filename dans
	lea Buffer(pc),a1			un buffer interne
.dup_filename
	move.b (a0)+,(a1)+
	bne.s .dup_filename

	move.l a3,a1				renvoie le msg à l'envoyeur !!
	CALL _ExecBase(pc),ReplyMsg

	bra.s WB_Branch				on se rebranche sur le reste !!

WB_Too_Much
	moveq #TooMuchSize,d0
	lea TooMuchMsg(pc),a0
	bra.s WB_Error

WB_Error_DupLock
	moveq #DupLockSize,d0
	lea DupLockMsg(pc),a0
	bra.s WB_Error

WB_Error_Lock
	moveq #LockSize,d0
	lea LockMsg(pc),a0

WB_Error
	bsr PrintText
	move.l a3,a1
	CALL _ExecBase(pc),ReplyMsg

	bsr WakeUpTMC
	bra Wait_Event

* Conversion d'un module PT au format TMC
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
ConvertModule
	move.l sp,save_SP-data_base(a5)		sauve le pointeur de pile

	bsr select_module
WB_Branch
	bsr load_file
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

* Gestion de toutes les erreurs possibles dans TMC
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
No_Error
	bra.s ExitSuccess
Error_Powerpacker
	moveq #PowerSize,d0
	lea PowerMsg(pc),a0
	bra.s ExitConvert
Error_Fr
	moveq #FrSize,d0
	lea FrMsg(pc),a0
	bra.s ExitConvert
Error_Lock
	moveq #LockSize,d0
	lea LockMsg(pc),a0
	bra.s ExitConvert
Error_Examine
	moveq #ExamineSize,d0
	lea ExamineMsg(pc),a0
	bra.s ExitConvert
Error_Directory
	moveq #DirectorySize,d0
	lea DirectoryMsg(pc),a0
	bra.s ExitConvert
Error_Mem
	moveq #MemSize,d0
	lea MemMsg(pc),a0
	bra.s ExitConvert
Error_Open
	moveq #OpenSize,d0
	lea OpenMsg(pc),a0
	bra.s ExitConvert
Error_Read
	moveq #ReadSize,d0
	lea ReadMsg(pc),a0
	bra.s ExitConvert
Error_Mark
	moveq #MarkSize,d0
	lea MarkMsg(pc),a0
	bra.s ExitConvert
Error_CreateDir
	moveq #CreateDirSize,d0
	lea CreateDirMsg(pc),a0
	bra.s ExitConvert
Error_Write
	moveq #WriteSize,d0
	lea WriteMsg(pc),a0
ExitConvert
	bsr PrintText
ExitSuccess
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
	move.l Module_Size(pc),d0
	CALL _ExecBase(pc),FreeMem
	clr.l Module_Adr-data_base(a5)

.toto7	move.l TMC_Fr(pc),d0			libère le FileRequest
	beq.s .toto8
	move.l d0,a0
	CALL _AslBase(pc),FreeAslRequest
	clr.l TMC_Fr-data_base(a5)

.toto8	move.l save_SP(pc),sp			restore la pile...

	bsr WakeUpTMC
	bra Wait_Event	

* Selection d'un module puis lecture en mémoire après allocation
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
select_module
	moveq #StartSize,d0			affiche "select..."
	lea StartMsg(pc),a0
	bsr PrintText

	lea TMC_FrSelect_Position(pc),a0
	move.l WindowHandle(pc),a1
	bsr Set_Requester_Position		a0 inchangé

	moveq #ASL_FileRequest,d0		alloue un file request
	lea TMC_FrTags_Select(pc),a0
	CALL _AslBase(pc),AllocAslRequest
	move.l d0,TMC_Fr-data_base(a5)
	beq Error_Fr

	move.l d0,a0				affiche un file req avec
	sub.l a1,a1				l'asl.library
	CALL AslRequest
	tst.l d0
	bne.s UserSelected

	move.l #CancelSize,d0			ben on signal kil a rien fait...
	lea CancelMsg(pc),a0
	bra ExitConvert

UserSelected
	bsr SleepTMC

	move.l TMC_Fr(pc),a4

	move.l fr_Drawer(a4),d1			obtient un lock sur le
	CALL _DosBase(pc),Lock			directory
	move.l d0,d1
	beq Error_Lock

	CALL CurrentDir				on se fixe dessus

	move.l d0,d1				libère le lock sur le
	CALL UnLock				path d'avant

	move.l _PowerpackerBase(pc),d0		la powerpacker est là ?
	bne.s .pp_there

	move.l fr_File(a4),d1			lock sur le fichier
	moveq #ACCESS_READ,d2
	CALL Lock
	move.l d0,InputLock-data_base(a5)
	beq Error_Lock

.pp_there
	move.l fr_File(a4),a0			recopie du nom du fichier
	lea Buffer(pc),a1			dans un buffer interne a TMC
.dup_filename
	move.b (a0)+,(a1)+
	bne.s .dup_filename

	move.l TMC_Fr(pc),a0			libère l'AslRequest alloué
	CALL _AslBase(pc),FreeAslRequest	avant
	clr.l TMC_Fr-data_base(a5)
	rts

load_file
	move.l _PowerpackerBase(pc),d0
	beq.s .pp_not_there

	moveq #LoadMsgSize,d0			affiche "read..."
	lea LoadMsg(pc),a0
	bsr PrintText

	moveq #2,d0				col=DECR_POINTER
	move.l #MEMF_ANY,d1			memtype
	lea Buffer(pc),a0			*name
	lea Module_Adr(pc),a1			&buffer
	lea Module_Size(pc),a2			&len
	lea -1,a3				function ecrypt.. none
	move.l _PowerpackerBase(pc),a6
	jsr -$1e(a6)
	tst.l d0				erreur ?
	beq pp_no_error
	bra Error_Powerpacker

.pp_not_there
	move.l InputLock(pc),d1			Examine le fichier
	move.l TMC_Fib(pc),d2
	CALL _DosBase(pc),Examine
	tst.l d0
	beq Error_Examine

	move.l TMC_Fib(pc),a0
	move.l fib_Size(a0),Module_Size-data_base(a5)
	tst.l fib_DirEntryType(a0)		c'est un dir ?
	bpl Error_Directory

	move.l InputLock(pc),d1			libère le lock sur le fichier
	CALL UnLock
	clr.l InputLock-data_base(a5)

	move.l Module_Size(pc),d0		alloue de la mémoire pour
	moveq #MEMF_ANY,d1			charger le fichier
	CALL _ExecBase(pc),AllocMem
	move.l d0,Module_Adr-data_base(a5)
	beq Error_Mem

	moveq #LoadMsgSize,d0			affiche "read..."
	lea LoadMsg(pc),a0
	bsr PrintText
	
	move.l #Buffer,d1			ouvre le fichier en lecture
	move.l #MODE_OLDFILE,d2
	CALL _DosBase(pc),Open
	move.l d0,ModuleHandle-data_base(a5)
	beq Error_Open

	move.l d0,d1				lit le fichier en entier
	move.l Module_Adr(pc),d2
	move.l Module_Size(pc),d3
	CALL Read
	cmp.l d0,d3
	bne Error_Read

	move.l ModuleHandle(pc),d1		referme le fichier
	CALL Close
	clr.l ModuleHandle-data_base(a5)

pp_no_error
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

* Recherche le nb de patterns qu'il y a dans le module + init des variables
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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

* Conversion des patterns PT au format TMC
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
convert_patterns
	moveq #ConvertSize,d0			signal la conversion des patterns
	lea ConvertMsg(pc),a0
	bsr PrintText

	move.w Nb_Patterns(pc),d0		Nb de patterns -1
	move.l Patterns_Adr(pc),a0
loop_convert_all
	move.w #64*4-1,d1			nb de notes à changer
	move.l a0,a1				a0=source  a1=destination

loop_convert_pattern
	moveq #0,d2
	move.b 2(a0),d2				cherche l'instrument
	lsr.w #4,d2
	move.b (a0),d3
	and.w #$f0,d3
	or.w d3,d2
	lsl.w #6,d2

	move.w (a0),d3
	and.w #$fff,d3				garde que la periode

	lea periodes_table(pc),a2		recherche l'offset de la periode dans
	moveq #0,d4				la table
	moveq #36-1,d5
loop_search_periode	
	cmp.w (a2)+,d3
	bge.s periode_found
	addq.w #1,d4
	dbf d5,loop_search_periode

periode_found
	or.w d4,d2				# du sample + offset periode
	lsl.w #4,d2

	move.b 2(a0),d3				insere la fonction
	and.w #$f,d3
	or.w d3,d2

	move.b d2,1(a1)				met # + offset periode + fonction
	lsr.w #8,d2				on le met en 2 temps car c'est pas
	move.b d2,(a1)				toujours WORD aligned
	move.b 3(a0),2(a1)			met l'info de la fonction

optimize_functions
	tst.b d3
	beq end_FX

*-----------> VIBRATO
	cmp.b #$4,d3				regarde ici pour les vibratos et
	beq.s its_vibrato			les tremolos
	cmp.b #$7,d3
	bne.s no_vibrato
its_vibrato
	move.b 2(a1),d2
	rol.b #4,d2
	move.b d2,2(a1)
	bra end_FX

no_vibrato
*-----------> TONEP + VOLSLIDE , VIBRATO + VOLSLIDE et VOLUME SLIDE
	cmp.b #$5,d3				on précalcule ici les volumes slides
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

*-----------> SET VOLUME
no_volume_slide
	cmp.b #$c,d3				on fait gaffe que le volume
	bne.s no_set_volume			ne dépasse pas $40
	move.b 2(a1),d2
	cmp.b #$40,d2
	ble.s end_FX
	move.b #$40,2(a1)
	bra.s end_FX

no_set_volume
*-----------> POSITION JUMP
	cmp.b #$b,d3
	bne.s no_position_jump
	move.b 2(a1),d2
	add.b d2,d2				on gagne un ADD dans la replay...
	move.b d2,2(a1)
	bra.s end_FX

no_position_jump
*-----------> PATTERN BREAK
	cmp.b #$d,d3				convertit le pattern break du
	bne.s no_pattern_break			decimal à l'hexadecimal
	moveq #0,d2
	move.b 2(a1),d2
	move.w d2,d3
	and.b #$f0,d2
	lsr.w #4,d2
	mulu #10,d2
	and.b #$0f,d3
	add.b d3,d2
	add.b d2,d2				on gagne ADD dans la replay
	move.b d2,2(a1)
	bra.s end_FX

no_pattern_break
*-----------> SPEED
	cmp.b #$f,d3
	bne.s end_FX
	subq.b #1,2(a1)				enleve 1 à la vitesse
	bge.s end_FX
	clr.b 2(a1)
end_FX
	addq.l #4,a0				passe aux notes suivantes
	addq.l #3,a1
	dbf d1,loop_convert_pattern	

	moveq #0,d1				efface la fin du pattern pour pouvoir
	moveq #64-1,d2				l'utiliser comme zone de datas plus tard
clear_end_pattern
	move.l d1,(a1)+
	dbf d2,clear_end_pattern
	dbf d0,loop_convert_all
	rts

* Marquage de toutes les notes utilisées dans la musique
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
match_notes
	move.l Module_Adr(pc),a0		regarde si le restart n'est pas
	move.b ms_Restart(a0),d0		supérieur à Length
	cmp.b ms_Length(a0),d0
	blt.s no_restart_reset
	clr.b ms_Restart(a0)			Ya du ProTracker ds l'air...

	moveq #ResetSize,d0
	lea ResetMsg(pc),a0
	bsr PrintText

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
	addq.b #1,0(a2,d3.w)			pattern utilisé
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
	st 0(a4,d5.w)

	move.b 1(a6),d5				\ va chercher la fonction
	and.b #$0f,d5				/ de la note

	cmp.b #$f,d5				set speed ?
	bne.s not_set_speed

	move.b 2(a6),d5
	bne.s no_commands

* il faut arreter ici la recherche car la vitesse == 0
	subq.w #1,0(a5,d1.w)			on ne passe pas ici !
	bra end_scan

not_set_speed
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
	move.w d0,d1				\ redemarre au début d'un pattern
	moveq #0,d0				/
do_pattern_break
	addq.b #1,0(a3,d2.w)			signale le passage sur cette pos
	addq.w #1,d2				position suivante
	cmp.b ms_Length-ms_Patterns(a0),d2
	blt.s set_branch
	move.b ms_Restart-ms_Patterns(a0),d2
	bra.s set_branch

do_position_jump
	addq.b #1,0(a3,d2.w)			signal le passage sur cette pos
	move.w d6,d2

set_branch
	moveq #0,d3
	move.b 0(a1,d2.w),d3			pattern actuel
	addq.b #1,0(a2,d3.w)			pattern utilisé
	mulu #1024,d3
	lea 0(a0,d3.l),a5			pointeur sur le pattern actuel
	move.w #$ffff,2(a5,d1.w)		signale un branchement sur ces
	bra scan_notes				notes
	
end_scan
	rts

* Réarangement des patterns TMC
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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

* Réarangement des positions TMC
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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

* Réarangement des samples TMC + recherche des finetunes utilisés
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
order_samples
	lea busy_Samples(pc),a0
	clr.b (a0)+				vire le sample 0

	tst.b sample_opt-data_base(a5)		remet tous les samples
	bne.s optimize_sample
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

* Changement des PositionJump & Samples
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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

	moveq #WarningMsgSize,d0		signal que TMC a trouvé une
	lea WarningMsg(pc),a0			commande non supportée
	bsr PrintText
no_Warning_Msg
	rts

* Package des patterns TMC ( blank notes )
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
pack_patterns
	move.l #PackSize,d0
	lea PackMsg(pc),a0
	bsr PrintText

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

* Sauvegarde du module TMC
* ~~~~~~~~~~~~~~~~~~~~~~~~
save_module
	lea data_base(pc),a5

	cmp.l #1,Save_Option-data_base(a5)	0 ou 1 ?
	ble.s save_source_file
	rts					2 ?

save_source_file
	move.l #WritePath,d1			on se remet sur le Save path
	moveq #ACCESS_READ,d2			car on a du faire un ChangeDir
	CALL _DosBase(pc),Lock			pour se fixer sur le fichier
	move.l d0,d1				avant...
	beq Error_Lock
	CALL CurrentDir
	move.l d0,d1
	CALL UnLock

	tst.b create_opt-data_base(a5)
	beq.s no_create_dir

	move.l Module_Adr(pc),d1		création d'un directory
	CALL CreateDir				portant le nom de la zik
	move.l d0,d1
	beq Error_CreateDir
	CALL CurrentDir				et on se fixe dessus !!

no_create_dir
	moveq #SaveSize,d0
	lea SaveMsg(pc),a0
	bsr PrintText

	move.l #DOS_SongName,d1			ouvre le fichier "Song.s"
	move.l #MODE_NEWFILE,d2
	CALL Open
	move.l d0,SongHandle-data_base(a5)
	beq Error_Open

*----------> ecrit la bannière
	lea Buffer(pc),a0
	lea NamePatch(pc),a1
	moveq #30-1,d0
put_FileName
	move.b (a0)+,d1
	beq.s end_put_FileName
	move.b d1,(a1)+
	dbf d0,put_FileName
	bra.s end_put_FileName2
end_put_FileName
	move.b #" ",(a1)+
	dbf d0,end_put_FileName
end_put_FileName2

	move.l Module_Adr(pc),a0		écrit le nom de la zik
	lea SongPatch(pc),a1
	moveq #20-1,d0
put_SongName
	move.b (a0)+,d1
	beq.s end_put_SongName
	move.b d1,(a1)+
	dbf d0,put_SongName
	bra.s end_put_SongName2
end_put_SongName
	move.b #" ",(a1)+
	dbf d0,end_put_SongName
end_put_SongName2

	moveq #2-1,d0				écrit le volume en pourcent
	move.w Volume(pc),d1
	lea VolumePatch(pc),a0
	bsr write_hex

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
	tst.l Save_Option-data_base(a5)		one file ?
	beq.s do_not_split

do_split
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

	move.l a3,a0				met le nom du sample
	lea Sample_patch0(pc),a1
	moveq #22-1,d0
put_SampName
	move.b (a0)+,d1
	beq.s end_put_SampName
	move.b d1,(a1)+
	dbf d0,put_SampName
	bra.s end_put_SampName2
end_put_SampName
	move.b #" ",(a1)+
	dbf d0,end_put_SampName
end_put_SampName2

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
	bne.s .ok
	moveq #1,d1				euh... c'est = à 0 ?
	moveq #1,d3
.ok
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

* Statistiques sur la conversion
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
display_stats
	lea data_base(pc),a5
	move.l Module_Size(pc),d3
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
	lea Buffer(pc),a3
	CALL _ExecBase(pc),RawDoFmt

	move.l a3,a0				affiche les résultats
	moveq #-1,d0
.strlen
	tst.b (a0)+
	dbeq d0,.strlen
	not.w d0
	move.l a3,a0
	bra PrintText

* Routine pour changer de path en écriture
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Change_Dir
	lea TMC_FrDir_Position(pc),a0
	move.l WindowHandle(pc),a1
	bsr Set_Requester_Position

	moveq #ASL_FileRequest,d0		alloue un file request
	lea TMC_FrTags_Dir(pc),a0
	CALL _AslBase(pc),AllocAslRequest
	move.l d0,TMC_Fr-data_base(a5)
	beq.s CD_Error_AllocAslRequest

	moveq #CDSelectSize,d0			affiche "select dir.."
	lea CDSelectMsg(pc),a0
	bsr PrintText

	move.l TMC_Fr(pc),a0			affiche un file req avec
	sub.l a1,a1				l'asl.library
	CALL _AslBase(pc),AslRequest
	tst.l d0
	beq.s CD_Error_Unselect

	move.l TMC_Fr(pc),a0			on se met sur  le nouveau
	move.l fr_Drawer(a0),d1			directory
	moveq #ACCESS_READ,d2
	CALL _DosBase(pc),Lock
	move.l d0,d1
	beq.s CD_Error_Lock
	CALL CurrentDir
	move.l d0,d1
	CALL UnLock

	move.l TMC_Fr(pc),a0
	move.l fr_Drawer(a0),a0
	lea WritePath(pc),a1
	moveq #99-1,d0
dup_writepath
	move.b (a0)+,(a1)+
	dbeq d0,dup_writepath

	bra.s CD_No_Error

CD_Error_AllocAslRequest
	moveq #FrSize,d0
	lea FrMsg(pc),a0
	bra.s CD_Error
CD_Error_Unselect
	moveq #CDSize,d0
	lea CDMsg(pc),a0
	bra.s CD_Error
CD_Error_Lock
	moveq #LockSize,d0
	lea LockMsg(pc),a0
CD_Error
	bsr PrintText
CD_No_Error
	move.l TMC_Fr(pc),d0
	beq Wait_Event
	move.l d0,a0
	CALL _AslBase(pc),FreeAslRequest
	clr.l TMC_Fr-data_base(a5)
	bra Wait_Event

* Changement du status de l'optimisation samples
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SampleOpt_Change
	move.l SampleGadget(pc),a0
	lea sample_opt(pc),a4
	bsr CheckBox_Change
	bra Wait_Next

* Changement du status du splitage du module TMC
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SaveOpt_Change
	move.l SaveGadget(pc),a0
	move.l Save_Option(pc),d0

	move.w TMC_Qualifier(pc),d1
	and.w #IEQUALIFIER_LSHIFT!IEQUALIFIER_RSHIFT,d1
	bne.s .decrease

.increase
	addq.l #1,d0
	cmp.l #3,d0
	bne.s .change
	moveq #0,d0
	bra.s .change

.decrease
	subq.l #1,d0
	bge.s .change
	moveq #2,d0
.change
	move.l d0,Save_Option-data_base(a5)
	bsr.s Cycle_Change
	bra Wait_Next
	
Cycle_Change
	move.l WindowHandle(pc),a1
	sub.l a2,a2
	lea CycleTags(pc),a3
	CALL _GadToolsBase(pc),GT_SetGadgetAttrsA
	rts

* Changement du status de la sauvegarde suivant le nom de la zik
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
CreateOpt_Change
	move.l CreateGadget(pc),a0
	lea create_opt(pc),a4
	bsr.s CheckBox_Change
	bra Wait_Next

* Modification du volume par souris
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
VolumeOpt_Change_Click
	move.w TMC_Code(pc),Volume-data_base(a5)
	bra Wait_Next

* Modification du volume par clavier
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
VolumeOpt_Change_Key
	move.w TMC_Qualifier(pc),d0
	and.w #IEQUALIFIER_LSHIFT!IEQUALIFIER_RSHIFT,d0
	bne.s .decrease
.increase
	move.w Volume(pc),d0			on est à 100 ?
	cmp.w #100,d0
	beq Wait_Next
	addq.w #1,d0
	move.w d0,Volume-data_base(a5)
	bsr.s Slider_Change
	bra Wait_Next

.decrease
	move.w Volume(pc),d0			on est à 0 ?
	beq Wait_Next
	subq.w #1,d0
	move.w d0,Volume-data_base(a5)
	bsr.s Slider_Change
	bra Wait_Next

Slider_Change
	move.l VolumeGadget(pc),a0
	move.l WindowHandle(pc),a1
	sub.l a2,a2
	lea SliderSetTags(pc),a3
	CALL _GadToolsBase(pc),GT_SetGadgetAttrsA
	rts

* Changement d'état d'une CheckBox de la GadTools
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*	a0=*Gadget
*	a4=*Opt
CheckBox_Change
	move.l WindowHandle(pc),a1
	sub.l a2,a2
	lea CheckBoxSetTag(pc),a3
	move.l #TAG_TRUE,4(a3)
	eor.b #$ff,(a4)
	bne.s .ok
	move.l #TAG_FALSE,4(a3)
.ok
	CALL _GadToolsBase(pc),GT_SetGadgetAttrsA
	rts

* Affichage du About
* ~~~~~~~~~~~~~~~~~~
DisplayAbout
	moveq #AboutMsg0Size,d0
	lea AboutMsg0(pc),a0
	bsr PrintText

	moveq #AboutMsg1Size,d0
	lea AboutMsg1(pc),a0
	bsr PrintText

	moveq #AboutMsg2Size,d0
	lea AboutMsg2(pc),a0
	bsr PrintText

	moveq #AboutMsg0Size,d0
	lea AboutMsg0(pc),a0
	bsr PrintText
	bra Wait_Event

* Sortie de TMC : on libère tout et on ferme tout
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Quit
	move.l _WorkbenchBase(pc),d0		ferme la workbench si présente
	beq.s no_workbench_exit

	move.l _ExecBase(pc),a6			attend que le port ne soit
	bra.s .start				plus encombré par des Msgs
.wait_end_msg
	move.l d0,a0
	CALL ReplyMsg
.start	move.l TMC_MsgPort(pc),a0
	CALL GetMsg
	tst.l d0
	bne.s .wait_end_msg

	move.l TMC_MsgPort(pc),a0		enlève le port
	CALL DeleteMsgPort

	move.l TMC_AppWindow(pc),a0		enlève l'AppWindow
	CALL _WorkbenchBase(pc),RemoveAppWindow
	
	move.l a6,a1				ferme le workbench
	CALL _ExecBase(pc),CloseLibrary

no_workbench_exit
	move.l _ExecBase(pc),a6			remet les requesters
	move.l ThisTask(a6),a6
	move.l save_WindowPtr(pc),pr_WindowPtr(a6)

	bsr Free_Mark

	move.l CLI_Dir(pc),d1			libère le Lock sur le path write
	CALL _DosBase(pc),CurrentDir
	move.l d0,d1
	CALL UnLock

	move.l WindowHandle(pc),a0		ferme la fenetre
	CALL _IntuitionBase(pc),CloseWindow
no_window
no_gadgets
	move.l TMC_glist(pc),a0			vire les gadgets
	CALL _GadToolsBase(pc),FreeGadgets
no_createcontext
	move.l TMC_VisualInfo(pc),a0		libère le VisualInfo
	CALL FreeVisualInfo
no_visualinfo
	sub.l a0,a0				libère le Public Screen (WB)
	move.l TMC_PubScreen(pc),a1
	CALL _IntuitionBase(pc),UnlockPubScreen
no_pubscreen
	move.l TMC_Font(pc),a1			ferme la topaz80
	CALL _GfxBase(pc),CloseFont
no_font
	move.l _PowerpackerBase(pc),d0		ferme la powerpacker si présente
	beq.s no_powerpacker
	move.l d0,a1
	CALL _ExecBase(pc),CloseLibrary
	bra.s no_fib
no_powerpacker
	move.l #DOS_FIB,d1			libère le File Info Block
	move.l TMC_Fib(pc),d2
	CALL _DosBase(pc),FreeDosObject
no_fib
	move.l _GadToolsBase(pc),a1		ferme la gadtools
	CALL _ExecBase(pc),CloseLibrary
no_gadtools
	move.l _IntuitionBase(pc),a1		ferme l'intuition
	CALL CloseLibrary
no_intuition
	move.l _GfxBase(pc),a1			ferme la graphics
	CALL CloseLibrary
no_gfx
	move.l _AslBase(pc),a1			ferme l'asl
	CALL CloseLibrary
no_asl
	move.l _DosBase(pc),a1			ferme la dos.library
	CALL CloseLibrary
no_dos
;no_micropro
	moveq #RETURN_OK,d0			on sort pénard!! jamais
	rts					d'erreur...

* Chargement du fichier de préférences
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Load_Prefs
	move.l #DOS_Prefs,d1			ouvre le fichier de preferences
	move.l #MODE_OLDFILE,d2
	CALL _DosBase(pc),Open
	move.l d0,PrefsHandle-data_base(a5)
	beq.s End_Prefs

	moveq #PrefsSize,d0			signal la lecture du fichier
	lea PrefsMsg(pc),a0			de preferences
	bsr PrintText

read_pref_line
	addq.w #1,Prefs_Line-data_base(a5)	incrémente le # de ligne
	tst.w Prefs_EOF-data_base(a5)		on est à la fin du fichier ?
	beq.s End_Prefs
	moveq #100-1,d4				100 chars maximum !!
	lea Buffer(pc),a3
read_pref_char
	move.l PrefsHandle(pc),d1		lit un char jusqu'a temps de
	move.l a3,d2				trouver un CR ou une erreur
	moveq #1,d3
	CALL Read
	move.w d0,Prefs_EOF-data_base(a5)	sauve ca en temps que flag
	beq.s pref_line_read			fin du fichier
	bmi Reset_Prefs				erreur ?
	cmp.b #10,(a3)				on est à la fin de la ligne ?
	beq.s pref_line_read			oui !!
	addq.l #1,a3
	dbf d4,read_pref_char
	bra Reset_Prefs				ouarf  trop long !!!

pref_line_read
	clr.b (a3)				met un zero en fin de ligne

	cmp.l #Buffer,a3			fait gaffe aux lignes vides
	beq.s read_pref_line
	lea OptionsTable(pc),a0			pointe la table des options
check_next_option
	lea Buffer(pc),a1			pointe le début de la ligne
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
	eor.b #$ff,sample_opt-data_base(a5)	inverse les bits histoire
	eor.b #$ff,create_opt-data_base(a5)	kils ne se fassent pas inverser après...

	move.l SampleGadget(pc),a0		retrace les gadgets
	lea sample_opt(pc),a4
	bsr CheckBox_Change

	move.l CreateGadget(pc),a0
	lea create_opt(pc),a4
	bsr CheckBox_Change

	move.l SaveGadget(pc),a0
	bsr Cycle_Change

	bra Slider_Change

Reset_Prefs
	st sample_opt-data_base(a5)
	sf create_opt-data_base(a5)
	clr.l Save_Option-data_base(a5)
	move.w #100,Volume-data_base(a5)
	
	lea ReadPath(pc),a0			efface les paths
	lea WritePath(pc),a1
	move.w #100-1,d0
loop_clear_path
	clr.b (a0)+
	clr.b (a1)+
	dbf d0,loop_clear_path
	bsr Free_Mark

	lea PatternMaskShow(pc),a0		efface les masks et met #?
	moveq #100-1,d0				à la place
loop_clear_filter
	clr.b (a0)+
	dbf d0,loop_clear_filter
	move.w #"#?",PatternMaskShow-data_base(a5)

	lea PrefsErrorStr(pc),a0		affiche le # de ligne ou
	lea Prefs_Line(pc),a1			ca a planté
	lea Putch(pc),a2
	lea Buffer(pc),a3
	CALL _ExecBase(pc),RawDoFmt

	moveq #-1,d0				affiche l'erreur
	move.l a3,a0
.strlen
	tst.b (a0)+
	dbeq d0,.strlen
	not.w d0
	move.l a3,a0
	bsr PrintText
	move.l _DosBase(pc),a6
	bra End_Prefs

* Fonction qui lit un path
* ~~~~~~~~~~~~~~~~~~~~~~~~
ReadPathFunction
	move.l (a0),a0				va chercher l'adresse du buffer
put_path
	move.b (a1)+,(a0)+			recopie le path
	bne.s put_path
	bra read_pref_line

* Fonction qui lit une mark
* ~~~~~~~~~~~~~~~~~~~~~~~~~
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
	CALL _ExecBase(pc),AllocMem
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
	
* Fonction pour lire un mask
* ~~~~~~~~~~~~~~~~~~~~~~~~~~
ReadMaskFunction
	move.l (a0),a0
	moveq #30-1,d0
read_mask
	move.b (a1)+,(a0)+
	beq read_pref_line
	dbf d0,read_mask
	bra Reset_Prefs

* Fonction qui autorise l'optimisation des samples
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SampleOnFunction
	st sample_opt-data_base(a5)
	bra read_pref_line

* Fonction qui interdit l'optimisation des samples
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SampleOffFunction
	sf sample_opt-data_base(a5)
	bra read_pref_line

* Fonction qui choisit un fichier de sortie unique
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
OneFileModFunction
	clr.l Save_Option-data_base(a5)
	bra read_pref_line

* Fonction qui choisit le splitage du module TMC
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SplitModFunction
	move.l #1,Save_Option-data_base(a5)
	bra read_pref_line

* Fonction qui choisit le loadseg() module
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
LoadSegModFunction
	move.l #2,Save_Option-data_base(a5)
	bra read_pref_line

* Fonction qui autorise la sauvegarde suivant le nom de la zik
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
CreateOnFunction
	st create_opt-data_base(a5)
	bra read_pref_line

* Fonction qui interdit la sauvegarde suivant le nom de la zik
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
CreateOffFunction
	sf create_opt-data_base(a5)
	bra read_pref_line

* Fonction qui lit un volume de 3 digits maximum
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
VolumeFunction
	moveq #0,d0				Volume
	moveq #0,d1				scratch
	moveq #3-1,d2				3 chiffres maximum !!!
.read
	move.b (a1)+,d1				lit un char
	beq.s .end				c'est la fin ?
	sub.b #"0",d1				on fait bien gaffe que ce
	blt Reset_Prefs				soit un chiffre...
	cmp.b #9,d1
	bgt Reset_Prefs
	mulu #10,d0				digit suivant
	add.w d1,d0
	dbf d2,.read
	tst.b (a1)				ya un 0 final ?
	bne Reset_Prefs
.end
	cmp.w #3-1,d2
	beq Reset_Prefs
	cmp.w #100,d0				fo pas ke ca depasse 100 !!
	bgt Reset_Prefs
	move.w d0,Volume-data_base(a5)
	bra read_pref_line
	
* Routine qui libère toutes les marks que l'utilisateur a entrées
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Free_Mark
	move.l Mark_Adr(pc),d3
	move.l _ExecBase(pc),a6
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

* Routine qui écrit un nombre en hexadécimal
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*   ->	d0=Nb de digit-1
*	d1=Nb à convertir
*	a0=Adresse d'écriture du nombre hexadécimal
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

Putch
	move.b d0,(a3)+
	rts

* Routine qui écrit dans le Scroll Text
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*	a0=*Text
*	d0=Size
PrintText
	movem.l d0/a0/a5/a6,-(sp)

	lea data_base(pc),a5
	move.l _GfxBase(pc),a6

	cmp.w #6,ScrollTextLine-data_base(a5)
	bne.s .no_scroll

	moveq #0,d0				dX
	moveq #8,d1				dY
	moveq #22,d2				minX
	moveq #90,d3				minY
	add.w TMC_Top(pc),d3
	move.w #21+356,d4			maxX
	move.w #89+49,d5			maxY
	add.w TMC_Top(pc),d5
	move.l TMC_RastPort(pc),a1
	CALL ScrollRaster

	subq.w #1,ScrollTextLine-data_base(a5)

.no_scroll
	move.w #356,d0				on se positionne au milieu
	move.w 2(sp),d1				de la ligne du bas
	lsl.w #3,d1				mulu #3,d1
	sub.w d1,d0
	lsr.w #1,d0
	add.w #21,d0
	move.w ScrollTextLine(pc),d1
	mulu #8,d1
	add.w #89+7,d1
	add.w TMC_Top(pc),d1
	move.l TMC_RastPort(pc),a1
	CALL Move

	addq.w #1,ScrollTextLine-data_base(a5)

	movem.l (sp)+,d0/a0/a5			écrit le texte
	move.l TMC_RastPort(pc),a1
	CALL Text
	move.l (sp)+,a6
	rts

* Routine qui met la fenetre de TMC en Stand By
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SleepTMC
	move.l WindowHandle(pc),a0		met un pointeur busy
	lea BusyTrueTags(pc),a1
	CALL _IntuitionBase(pc),SetWindowPointerA

	lea UnvisibleReq(pc),a0			met un request
	CALL InitRequester

	lea UnvisibleReq(pc),a0
	move.l WindowHandle(pc),a1
	CALL Request
	rts

* Routine qui réveille la fenetre de TMC
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
WakeUpTMC
	lea UnvisibleReq(pc),a0			vire le request
	move.l WindowHandle(pc),a1
	CALL _IntuitionBase(pc),EndRequest

	move.l WindowHandle(pc),a0		met un pointeur busy
	lea BusyFalseTags(pc),a1
	CALL SetWindowPointerA
	rts

* Routine pour positionner un requester de l'asl en fonction de la fenetre
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*	a0=Request Tags
*	a1=Window Handle
Set_Requester_Position
	move.w wd_LeftEdge(a1),4+2(a0)
	move.w wd_TopEdge(a1),d0
	add.w TMC_Top(pc),d0
	move.w d0,4+4+4+2(a0)
	rts



* Toutes les datas de TMC
* ~~~~~~~~~~~~~~~~~~~~~~~
data_base

periodes_table
	dc.w 856,808,762,720,678,640,604,570,538,508,480,453
	dc.w 428,404,381,360,339,320,302,285,269,254,240,226
	dc.w 214,202,190,180,170,160,151,143,135,127,120,113

TMC_FrTags_Select
	dc.l ASLFR_Window,0
	dc.l ASLFR_SleepWindow,TAG_TRUE
	dc.l ASLFR_TitleText,ReqSelect
	dc.l ASLFR_InitialDrawer,ReadPath		Path initial
	dc.l ASLFR_DoPatterns,TAG_TRUE			gadget pattern
TMC_FrSelect_Position
	dc.l ASLFR_InitialLeftEdge,0
	dc.l ASLFR_InitialTopEdge,0
	dc.l ASLFR_InitialWidth,400
	dc.l ASLFR_InitialHeight,180
	dc.l ASLFR_InitialPattern,PatternMaskShow	Pattern filtering
	dc.l TAG_DONE

TMC_FrTags_Dir
	dc.l ASLFR_Window,0
	dc.l ASLFR_SleepWindow,TAG_TRUE
	dc.l ASLFR_TitleText,ReqDir
	dc.l ASLFR_InitialDrawer,WritePath
	dc.l ASLFR_DoSaveMode,TAG_TRUE
	dc.l ASLFR_DrawersOnly,TAG_TRUE
TMC_FrDir_Position
	dc.l ASLFR_InitialLeftEdge,0
	dc.l ASLFR_InitialTopEdge,0
	dc.l ASLFR_InitialWidth,400
	dc.l ASLFR_InitialHeight,180
	dc.l TAG_DONE

*****************************************************
SelectTags
WindowHandle=*+4
	dc.l ASLFR_Window,0
	dc.l ASLFR_SleepWindow,TAG_TRUE
	dc.l TAG_DONE
*****************************************************
CheckBoxTags
	dc.l GT_Underscore,'_'
CheckBoxSetTag
	dc.l GTCB_Checked,TAG_TRUE
	dc.l TAG_DONE
*****************************************************
CycleTags
	dc.l GTCY_Labels,CycleStringsPtr
Save_Option=*+4
	dc.l GTCY_Active,0
	dc.l TAG_DONE
*****************************************************
SliderTags
	dc.l GT_Underscore,'_'
	dc.l GTSL_Max,100
	dc.l GTSL_LevelFormat,LevelFormatStr
	dc.l GTSL_MaxLevelLen,4
SliderSetTags
Volume=*+6
	dc.l GTSL_Level,100
	dc.l TAG_DONE
*****************************************************
ButtonTags
	dc.l GT_Underscore,'_'
	dc.l TAG_DONE
*****************************************************
WindowTags
	dc.l WA_Title,WindowText
	dc.l WA_Left,100
	dc.l WA_Top,50
	dc.l WA_Width,400
	dc.l WA_Height,152
	dc.l WA_ScreenTitle,ScreenText
	dc.l WA_DragBar,TAG_TRUE
	dc.l WA_DepthGadget,TAG_TRUE
	dc.l WA_CloseGadget,TAG_TRUE
	dc.l WA_Activate,TAG_TRUE
	dc.l WA_RMBTrap,TAG_TRUE
	dc.l WA_IDCMP,IDCMP_VANILLAKEY!IDCMP_CLOSEWINDOW!IDCMP_REFRESHWINDOW!CHECKBOXIDCMP!BUTTONIDCMP!SLIDERIDCMP
TMC_glist=*+4
	dc.l WA_Gadgets,0
TMC_PubScreen
	dc.l WA_PubScreen,0
	dc.l TAG_DONE	
*****************************************************
BevelTags
	dc.l GT_VisualInfo,0
	dc.l GTBB_Recessed,TAG_TRUE
	dc.l TAG_DONE
*****************************************************
BusyTrueTags
	dc.l WA_BusyPointer,TAG_TRUE
	dc.l TAG_DONE
*****************************************************
BusyFalseTags
	dc.l WA_BusyPointer,TAG_FALSE
	dc.l TAG_DONE



TMC_NewGadget	dcb.b gng_SIZEOF,0

GadgetAttr
	dc.l TopazName
	dc.w 8
	dc.b FS_NORMAL
	dc.b FPF_ROMFONT

UnvisibleReq	ds.b rq_SIZEOF

CycleStringsPtr	dc.l Cycle0
		dc.l Cycle1
		dc.l Cycle2
		dc.l 0

InputLock	dc.l 0
ModuleHandle	dc.l 0
SongHandle	dc.l 0
PatternHandle	dc.l 0
SampleHandle	dc.l 0
PrefsHandle	dc.l 0
Module_Adr	dc.l 0
Module_Size	dc.l 0
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

_ExecBase	dc.l 0
_DosBase	dc.l 0
_AslBase	dc.l 0
_GfxBase	dc.l 0
_IntuitionBase	dc.l 0
_GadToolsBase	dc.l 0
_WorkbenchBase	dc.l 0
_PowerpackerBase	dc.l 0
SampleGadget	dc.l 0
CreateGadget	dc.l 0
SaveGadget	dc.l 0
VolumeGadget	dc.l 0
TMC_Top		dc.l 0
TMC_Font	dc.l 0
TMC_Fr		dc.l 0
TMC_VisualInfo	dc.l 0
TMC_RastPort	dc.l 0
TMC_UserPort	dc.l 0
TMC_SigBit	dc.l 0
TMC_Gadget	dc.l 0
TMC_Class	dc.l 0
TMC_Code	dc.w 0
TMC_Qualifier	dc.w 0
TMC_AppWindow	dc.l 0
TMC_MsgPort	dc.l 0
TMC_Fib		dc.l 0
save_SP		dc.l 0
save_WindowPtr	dc.l 0
CLI_Dir		dc.l 0
Prefs_Line	dc.w 0
Prefs_EOF	dc.w $ffff
ImpPattern	dc.w 0
ImpPosition	dc.w 0
ImpVoice	dc.w 0
ScrollTextLine	dc.w 0
KeyBuffer	dc.b 0
NotImp		dc.b 0
sample_opt	dc.b $ff
create_opt	dc.b $00
		even
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

MaskShowOpt	dc.l SampleOnOpt
		dc.b "MASKSHOW=",0
		even
		dc.l ReadMaskFunction
		dc.l PatternMaskShow

SampleOnOpt	dc.l SampleOffOpt
		dc.b "OPTSAMPLES ON",0
		even
		dc.l SampleOnFunction

SampleOffOpt	dc.l OneFileModOpt
		dc.b "OPTSAMPLES OFF",0
		even
		dc.l SampleOffFunction

OneFileModOpt	dc.l SplitModOpt
		dc.b "ONEFILEMOD",0
		even
		dc.l OneFileModFunction

SplitModOpt	dc.l LoadSegModOpt
		dc.b "SPLITMOD",0
		even
		dc.l SplitModFunction

LoadSegModOpt	dc.l CreateOnOpt
		dc.b "LOADSEGMOD",0
		even
		dc.l LoadSegModFunction

CreateOnOpt	dc.l CreateOffOpt
		dc.b "SONGNAMESAVE ON",0
		even
		dc.l CreateOnFunction

CreateOffOpt	dc.l VolumeOpt
		dc.b "SONGNAMESAVE OFF",0
		even
		dc.l CreateOffFunction

VolumeOpt	dc.l 0
		dc.b "VOLUME=",0
		even
		dc.l VolumeFunction

DosName		dc.b "dos.library",0
AslName		dc.b "asl.library",0
GfxName		dc.b "graphics.library",0
IntuitionName	dc.b "intuition.library",0
GadToolsName	dc.b "gadtools.library",0
WorkbenchName	dc.b "workbench.library",0
PowerpackerName	dc.b "powerpacker.library",0
TopazName	dc.b "topaz.font",0

ScreenText	dc.b "The Module Converter (TMC) v5.1   (c)1993 Sync/DreamDealers",0
WindowText	dc.b "The Module Converter (TMC) v5.1",0
OptimizeText	dc.b "_Optimize Samples",0
SaveText	dc.b "_Create Directory",0
SplitText	dc.b "_Split Module",0
VolumeText	dc.b "_Volume:    ",0
ConvertText	dc.b "Convert _Module",0
AboutText	dc.b "_About",0
DirText		dc.b "Change Output _Directory",0

SuccessStr	dc.b "Module Size : %ld   Gain : %ld(%d%%)",0
PrefsErrorStr	dc.b ">> Preferences file error on line %d <<",0
LevelFormatStr	dc.b "%3ld%%",0

Cycle0		dc.b "One File Module",0
Cycle1		dc.b "Split Module",0
Cycle2		dc.b "LoadSeg() Module",0

* Tous les messages d'erreurs
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~
CancelMsg	dc.b ">> No module selected <<"
CancelSize=*-CancelMsg
FrMsg		dc.b ">> AllocAslRequest() error <<"
FrSize=*-FrMsg
LockMsg		dc.b ">> Lock() error <<"
LockSize=*-LockMsg
ExamineMsg	dc.b ">> Examine() error <<"
ExamineSize=*-ExamineMsg
DirectoryMsg	dc.b ">> FileName is a directory <<"
DirectorySize=*-DirectoryMsg
MemMsg		dc.b ">> AllocMem() error <<"
MemSize=*-MemMsg
OpenMsg		dc.b ">> Open() error <<"
OpenSize=*-OpenMsg
ReadMsg		dc.b ">> Read() error <<"
ReadSize=*-ReadMsg
MarkMsg		dc.b ">> FileName is not a module <<"
MarkSize=*-MarkMsg
WriteMsg	dc.b ">> Write() error <<"
WriteSize=*-MarkMsg
TooMuchMsg	dc.b ">> Blurp... Indigestion!! <<"
TooMuchSize=*-TooMuchMsg
DupLockMsg	dc.b ">> DupLock() error <<"
DupLockSize=*-DupLockMsg
CreateDirMsg	dc.b ">> CreateDir() error <<"
CreateDirSize=*-CreateDirMsg
PowerMsg	dc.b ">> ppLoadData() error <<"
PowerSize=*-PowerMsg
CDMsg		dc.b ">> No path selected <<"
CDSize=*-CDMsg

* Tous les messages d'informations
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
WaitMsg		dc.b "- TMC is ready for your next choice -"
WaitSize=*-WaitMsg
PrefsMsg	dc.b "Reading preferences file..."
PrefsSize=*-PrefsMsg
StartMsg	dc.b "Select a module..."
StartSize=*-StartMsg
LoadMsg		dc.b "Reading file..."
LoadMsgSize=*-LoadMsg
ConvertMsg	dc.b "Converting patterns..."
ConvertSize=*-ConvertMsg
ResetMsg	dc.b "!! Warning : Restart zero'ed !!"
ResetSize=*-ResetMsg
WarningMsg	dc.b "!! Warning : Unimplemented function found !!"
WarningMsgSize=*-WarningMsg
PackMsg		dc.b "Packing patterns..."
PackSize=*-PackMsg
SaveMsg		dc.b "Saving module..."
SaveSize=*-SaveMsg
AboutMsg0	dc.b "-----------------------"
AboutMsg0Size=*-AboutMsg0
AboutMsg1	dc.b "The Module Converter v5.1"
AboutMsg1Size=*-AboutMsg1
AboutMsg2	dc.b "Copyright 1993-1995 Sync/DreamDealers"
AboutMsg2Size=*-AboutMsg2
CDSelectMsg	dc.b "select a path..."
CDSelectSize=*-CDSelectMsg

ReqSelect	dc.b "Select A Module",0
ReqDir		dc.b "Select A New Directory",0

Banner		dc.b 10
		dc.b "***************************************************************************",10
		dc.b "* Source-Song Generated With  TMC v5.1  (c)1993-1995 Sync of DreamDealers *",10
		dc.b "* From Module : "
NamePatch	dc.b "                                                          *",10
		dc.b "* SongName    : "
SongPatch	dc.b "                                                          *",10
		dc.b "***************************************************************************",10
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
		dc.b 9,"CNOP 0,4",10
		dc.b "mt_global_volume",10
		dc.b 9,"dc.w $00"
VolumePatch	dc.b ",$0",10,"mt_restart",10
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

Sample_Msg	dc.b 10
		dc.b "***************************************",10
		dc.b "* Sample Name : "
Sample_patch0	dc.b "                      *",10
		dc.b "***************************************",10
		dc.b "mt_sample00"
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

Buffer		dcb.b 100
ReadPath	dcb.b 100,0
WritePath	dcb.b 100,0
PatternMaskShow	dcb.b 100,0
