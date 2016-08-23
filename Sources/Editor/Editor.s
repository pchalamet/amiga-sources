
	include "libraries/gadtools_lib.i"
	include "libraries/gadtools.i"
	include "intuition/intuition_lib.i"
	include "intuition/gadgetclass.i"
	include "exec/exec_lib.i"
	include "misc/macros.i"


	OPT P=68020
;;	OPT NODEBUG
	OPT HCLN,DEBUG
	OUTPUT hd1:X


main
	lea _DataBase(pc),a5
	move.l (_SysBase).w,a6
	move.l a6,_ExecBase(a5)


* ouverture de la gadtools.library
	lea GadToolsName(pc),a1
	moveq #0,d0
	CALL OpenLibrary
	move.l d0,_GadToolsBase(a5)
	beq no_gadtools

* ouverture de l'intuition.library
	lea IntuitionName(pc),a1
	moveq #0,d0
	CALL OpenLibrary
	move.l d0,_IntuitionBase(a5)
	beq no_intuition

* recherche de l'écran publique par defaut
	sub.l a0,a0
	CALL d0,LockPubScreen
	move.l d0,Def_Screen(a5)
	beq no_def_screen

* recherche le visualinfo de l'écran
	move.l d0,a0
	sub.l a1,a1
	CALL _GadToolsBase(a5),GetVisualInfoA
	move.l d0,Def_VisualInfo(a5)
	beq no_def_visual_info

* fabrication d'un contexte pour les gadgets de la fenetre
	lea My_Glist(pc),a0
	CALL CreateContext

* fabrication d'un scroller
	move.l d0,a0
	lea My_NewGadget(pc),a1
	move.w #15,gng_LeftEdge(a1)
	move.w #20,gng_TopEdge(a1)
	move.w #20,gng_Width(a1)
	move.w #100,gng_Height(a1)
	move.l Def_VisualInfo(a5),gng_VisualInfo(a1)
	lea ScrollerTags(pc),a2
	move.l #SCROLLER_KIND,d0
	CALL CreateGadgetA
	move.l d0,ScrollerGadget(a5)

* fin de la fabrication des gadgets
	tst.l d0
	beq no_gadgets

* ouverture de la fenetre avec les gadgets de la GadTools
	sub.l a0,a0
	lea WindowTags(pc),a1
	CALL _IntuitionBase(a5),OpenWindowTagList
	move.l d0,WindowHandle(a5)
	beq no_window

	move.l d0,a0
	move.l wd_UserPort(a0),a0
	move.l a0,UserPort(a5)
	move.b MP_SIGBIT(a0),d1
	moveq #0,d2
	bset d1,d2
	move.l d2,SigMask(a5)



* retracage des gadgets
	move.l d0,a0
	sub.l a1,a1
	CALL _GadToolsBase(a5),GT_RefreshWindow

Wait_Msg
	move.l SigMask(a5),d0		attend un signal
	CALL _ExecBase(a5),Wait

	move.l UserPort(a5),a0
	CALL _GadToolsBase(a5),GT_GetIMsg
	tst.l d0
	beq.s Wait_Msg

	move.l d0,a1
	move.l im_IAddress(a1),Msg_Gadget(a5)
	move.l im_Class(a1),Msg_Class(a5)
	move.w im_Code(a1),Msg_Code(a5)
	move.w im_Qualifier(a1),Msg_Qualifier(a5)
	CALL GT_ReplyIMsg

	
	move.l Msg_Class(a5),d0
	cmp.l #IDCMP_CLOSEWINDOW,d0		on sort ?
	beq Quit
	cmp.l #IDCMP_GADGETDOWN,d0		un gadget de clické ?
	beq.s Examine_Gadget
	cmp.l #IDCMP_GADGETUP,d0		un gadget de clické ?
	beq.s Examine_Gadget
	cmp.l #IDCMP_VANILLAKEY,d0		une touche ?
	beq.s Examine_Key
	cmp.l #IDCMP_REFRESHWINDOW,d0		faut retracer ?
	beq GadTools_Refresh
	bra Wait_Msg

GadTools_Refresh
	move.l WindowHandle(a5),a0
	CALL _GadToolsBase(a5),GT_BeginRefresh
	move.l WindowHandle(a5),a0
	move.l #TAG_TRUE,d0
	CALL GT_EndRefresh
	bra Wait_Msg

Examine_Gadget
	move.l Msg_Gadget(a5),a0
	* chopper gg_UserData(a0) et sauter à la routine
	bra Wait_Msg

Examine_Key
	bra Wait_Msg


************ SORTIE
Quit
	move.l WindowHandle(a5),a0
	CALL _IntuitionBase(a5),CloseWindow

no_window
no_gadgets
	move.l My_Glist(pc),a0
	CALL _GadToolsBase(a5),FreeGadgets

no_createcontext
	move.l Def_VisualInfo(a5),a0
	CALL _GadToolsBase(a5),FreeVisualInfo

no_def_visual_info
	sub.l a0,a0
	move.l Def_Screen(a5),a1
	CALL _IntuitionBase(a5),UnlockPubScreen

no_def_screen
	move.l _IntuitionBase(a5),a1
	CALL _ExecBase(a5),CloseLibrary

no_intuition
	move.l _GadToolsBase(a5),a1
	CALL CloseLibrary

no_gadtools
	moveq #0,d0
	rts




ScrollerTags
	dc.l GTSC_Arrows,10
	dc.l PGA_Freedom,LORIENT_VERT
	dc.l TAG_DONE

My_NewGadget
	dcb.b gng_SIZEOF,0

WindowTags
	dc.l WA_Title,WindowTitle
	dc.l WA_Left,100
	dc.l WA_Top,50
	dc.l WA_Width,400
	dc.l WA_Height,150
	dc.l WA_MinWidth,200
	dc.l WA_MinHeight,100
	dc.l WA_MaxWidth,640
	dc.l WA_MaxHeight,256
	dc.l WA_ScreenTitle,ScreenTitle
	dc.l WA_Activate,TAG_TRUE
	dc.l WA_RMBTrap,TAG_TRUE

	dc.l WA_DragBar,TAG_TRUE
	dc.l WA_DepthGadget,TAG_TRUE
	dc.l WA_CloseGadget,TAG_TRUE
	dc.l WA_SizeGadget,TAG_TRUE
	dc.l WA_SizeBRight,TAG_TRUE
	dc.l WA_SizeBBottom,TAG_TRUE

	dc.l WA_NoCareRefresh,TAG_TRUE
	dc.l WA_IDCMP,IDCMP_CLOSEWINDOW!IDCMP_REFRESHWINDOW!SCROLLERIDCMP
	dc.l WA_Gadgets,mon_gadget
	dc.l TAG_DONE	

mon_gadget
	dc.l 0					egg_NextGadget
	dc.w 150,30				egg_LeftEdge,gg_TopEdge
	dc.w 100,10				egg_Width,gg_Height
	dc.w GFLG_GADGIMAGE|GFLG_GADGHBOX|GFLG_EXTENDED	egg_Flags
	dc.w GACT_IMMEDIATE			egg_Activation
	dc.w GTYP_PROPGADGET			egg_GadgetType
	dc.l mover				egg_GadgetRender
	dc.l 0					egg_SelectRender
	dc.l 0					egg_GadgetText
	dc.l 0					egg_MutualExclude
	dc.l propinfo				egg_SpecialInfo
	dc.w 3					egg_GadgetID
	dc.l 0					egg_UserData
	dc.l 0					egg_MoreFlags
	dc.w 0					egg_BoudsLeftEdge
	dc.w 0					egg_BoundsTopEdge
	dc.w 0					egg_BoundsWidth
	dc.w 0					egg_Boundsheight

mover
	dc.w 0,0
	dc.w 16,6
	dc.w 1
	dc.l moverdata
	dc.b %1,0
	dc.l 0
	
moverdata
	dc.w %0111111111111110
	dc.w %0111111111111110
	dc.w %0111111111111110
	dc.w %0111111111111110
	dc.w %0111111111111110
	dc.w %0111111111111110

propinfo
	dc.w AUTOKNOB|FREEHORIZ|PROPNEWLOOK	pi_Flags
	dc.w 0,0		pi_HorizPot,pi_VertPot
	dc.w $ffff/16		pi_HorizBody
	dc.w 0			pi_VertBody
	dc.w 0			pi_CWidth
	dc.w 0			pi_CHeight
	dc.w 0			pi_HPotRes
	dc.w 0			pi_VPotRes
	dc.w 0			pi_LeftBorder
	dc.w 0			pi_TopBorder


;;My_Glist=*+4
My_Glist
	dc.l 0


	rsreset
DataBase_Struct		rs.b 0
_ExecBase		rs.l 1
_GadToolsBase		rs.l 1
_IntuitionBase		rs.l 1
Def_Screen		rs.l 1
Def_VisualInfo		rs.l 1
WindowHandle		rs.l 1
ScrollerGadget		rs.l 1
UserPort		rs.l 1
SigMask			rs.l 1
Msg_Class		rs.l 1
Msg_Gadget		rs.l 1
Msg_Code		rs.w 1
Msg_Qualifier		rs.w 1
DataBase_SizeOF		rs.b 0

_DataBase
	ds.b DataBase_SizeOF


GadToolsName
	dc.b "gadtools.library",0
IntuitionName
	dc.b "intuition.library",0
WindowTitle
	dc.b "Fenetre essai",0
ScreenTitle
		dc.b "Ecran essai",0
