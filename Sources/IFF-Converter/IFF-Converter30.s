 
*			    IFF-Converter v1.0.30
*			    ~~~~~~~~~~~~~~~~~~~~~
*			(c) 1993-1995 Sync/DreamDealers

	OPT P=68020,O+
	OPT O+,OW-
	OPT NODEBUG,NOLINE,NOHCLN
;;	OPT DEBUG,HCLN
	OUTPUT hd1:X


* Juste quelques includes
* ~~~~~~~~~~~~~~~~~~~~~~~
	incdir "include:"
	include "exec/exec_lib.i"
	include "exec/execbase.i"
	include "exec/types.i"
	include "exec/memory.i"
	include "utility/tagitem.i"
	include "libraries/iffparse_lib.i"
	include "libraries/iffparse.i"
	include "libraries/asl_lib.i"
	include "libraries/asl.i"
	include "libraries/gadtools_lib.i"
	include "libraries/gadtools.i"
	include "dos/dos_lib.i"
	include "dos/dos.i"
	include "dos/dosextens.i"
	include "intuition/intuition_lib.i"
	include "intuition/intuition.i"
	include "intuition/screens.i"
	include "graphics/graphics_lib.i"
	include "graphics/gfx.i"
	include "graphics/modeid.i"
	include "graphics/displayinfo.i"
	include "datatypes/pictureclass.i"
	include "misc/macros.i"

* Quelques EQU
* ~~~~~~~~~~~~
MENU_SIZE=25
BUFFER_SIZE=4096
REALFILENAME_SIZE=120

SAVE_RAW_NORMAL=0
SAVE_RAW_INTERLEAVED=1
SAVE_CHUNKY8=2
SAVE_CHUNKY16=3
SAVE_CHUNKY24=4

CAMG_MASK=~(V_SPRITES!GENLOCK_VIDEO!GENLOCK_AUDIO!V_VP_HIDE)

NO_ERROR	macro
asm_error set asm_error+1
	addq.w #1,Error_Count-db(a5)
	endm

RESET_ERROR	macro
asm_error set 0
	clr.w Error_Count-db(a5)
	endm


* Le point d'entrée du prg
* ~~~~~~~~~~~~~~~~~~~~~~~~
	section infini,code
Main
	bra.s Skip_Version
	dc.b "$VER:"
	dc.b "IFF-Converter v1.0.30  ©1993-1995 Sync/DreamDealers",0

	CNOP 0,4
Skip_Version
	lea db(pc),a5

* Ouverture de toutes les libraries nécessaires
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.l (_SysBase).w,_ExecBase-db(a5)	c'est + rapide en FAST...

* Ouverture de l'intuition.library
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	lea IntuitionName(pc),a1
	moveq #39,d0
	CALL _ExecBase-db(a5),OpenLibrary
	move.l d0,_IntuitionBase-db(a5)
	beq very_grave_error			ouarf...
	RESET_ERROR

* Ouverture de l'asl.library + allocation d'une structure FileRequest
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	lea AslName(pc),a1
	moveq #39,d0
	CALL _ExecBase-db(a5),OpenLibrary
	move.l d0,_AslBase-db(a5)
	beq init_error
	NO_ERROR

	moveq #ASL_FileRequest,d0		alloue une structure pour
	CALL _AslBase-db(a5),AllocAslRequest	un requester de fichiers
	move.l d0,Load_Request-db(a5)
	beq init_error
	NO_ERROR

	moveq #ASL_FileRequest,d0
	CALL AllocAslRequest
	move.l d0,Save_Request-db(a5)
	beq init_error
	NO_ERROR

	moveq #ASL_ScreenModeRequest,d0		alloue une structure pour
	CALL AllocAslRequest			un requester de mode écran
	move.l d0,ScreenMode_Request-db(a5)
	beq init_error
	NO_ERROR

* Ouverture de la gadtools.library
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	lea GadToolsName(pc),a1
	moveq #39,d0
	CALL _ExecBase-db(a5),OpenLibrary
	move.l d0,_GadToolsBase-db(a5)
	beq init_error
	NO_ERROR

* Ouverture de la graphics.library
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	lea GfxName(pc),a1
	moveq #39,d0
	CALL OpenLibrary
	move.l d0,_GfxBase-db(a5)
	beq init_error
	NO_ERROR

* Ouverture de l'iffparse.library + allocation d'une structure IFF
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	lea IFFName(pc),a1
	moveq #39,d0
	CALL OpenLibrary
	move.l d0,_IFFParseBase-db(a5)
	beq init_error
	NO_ERROR

	CALL d0,AllocIFF			allocation d'une structure IFF
	move.l d0,IFF_Handle-db(a5)
	beq init_error
	NO_ERROR

	move.l d0,a0				passe ca par le DOS
	CALL InitIFFasDOS

* Ouverture de la dos.library
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~
	lea DosName(pc),a1
	moveq #39,d0
	CALL _ExecBase-db(a5),OpenLibrary
	move.l d0,_DosBase-db(a5)
	beq init_error
	NO_ERROR

* Ouvre un ecran par defaut
* ~~~~~~~~~~~~~~~~~~~~~~~~~
	bsr Open_Main_Screen
	beq init_error
	NO_ERROR
	sf Init_Flag-db(a5)

	move.l Screen_Handle-db(a5),a0		prend des renseignements
	sub.l a1,a1				sur l'affichage de l'écran
	CALL _GadToolsBase-db(a5),GetVisualInfoA
	move.l d0,Screen_VisualInfo-db(a5)
	beq init_error
	NO_ERROR

	lea IFF_Menus(pc),a0			prépare les menus
	sub.l a1,a1
	CALL CreateMenusA
	move.l d0,IFF_MenuStrip-db(a5)
	beq init_error
	NO_ERROR

	move.l d0,a0				arrangement des menus
	move.l Screen_VisualInfo-db(a5),a1
	lea IFF_Menus_Tags(pc),a2
	CALL LayoutMenusA
	tst.l d0
	beq init_error
	NO_ERROR

	move.l Window_Handle-db(a5),a0		et hop!! installe les menus
	move.l IFF_MenuStrip-db(a5),a1
	CALL _IntuitionBase-db(a5),SetMenuStrip
	tst.l d0
	beq init_error
	NO_ERROR

init_error_count=asm_error

	bsr Display_About			affichage du about
	bsr Save_Screen_Colors

* La boucle principale : attente des messages d'intuition
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
IFF_Messages_Handler
	move.l Window_WaitMask-db(a5),d0	attend un message
	CALL _ExecBase-db(a5),Wait

Window_Event
	move.l Window_UserPort-db(a5),a0	lit le message à l'aide de
	CALL _GadToolsBase-db(a5),GT_GetIMsg	la gadtools
	tst.l d0
	beq.s IFF_Messages_Handler

	pea Window_Event-db(a5)

	move.l d0,a1				cas spécial pour les menus !!!
	move.l im_Class(a1),d0
	cmp.l #IDCMP_MENUVERIFY,d0
	beq Window_MenuVerify

	move.l d0,Msg_Class-db(a5)		va chercher les infos du message
	move.l im_IAddress(a1),Msg_IAddress-db(a5)
	move.w im_Code(a1),Msg_Code-db(a5)
	move.w im_Qualifier(a1),Msg_Qualifier-db(a5)

	move.l Window_Handle-db(a5),a0
	movem.w wd_MouseY(a0),d2/d3
	cmp.w Picture_Width-db(a5),d3
	blt.s .ok0
	move.w Picture_Width-db(a5),d3
	subq.w #1,d3
.ok0	cmp.w #MENU_SIZE,d2
	bge.s .ok1
	moveq #MENU_SIZE,d2
.ok1	move.w Picture_Height-db(a5),d4
	add.w #MENU_SIZE,d4
	cmp.w d4,d2
	blt.s .ok2
	move.w d4,d2
	subq.w #1,d2
.ok2	movem.w d2/d3,Msg_MouseY-db(a5)
	CALL GT_ReplyIMsg

	move.l Msg_Class-db(a5),d0			recherche ce que c'est comme
	cmp.l #IDCMP_RAWKEY,d0			message
	beq.s Check_Window_Key
	cmp.l #IDCMP_MOUSEBUTTONS,d0
	beq.s Check_Window_Buttons
	cmp.l #IDCMP_MOUSEMOVE,d0
	beq Check_Brush
	cmp.l #IDCMP_MENUPICK,d0
	beq Child_Menu
	rts

* Gestion des touches ( IDCMP_RAWKEY )
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Check_Window_Key
	move.w Msg_Code-db(a5),d0			touche HELP appuyée ?
	cmp.w #$5f,d0
	beq Flip_Info_Screen
	rts

* Change les couleurs pour que le menu soit bien visible ( IDCMP_MENUVERIFY )
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Window_MenuVerify
	move.l a1,-(sp)
	bsr Save_Screen_Colors
	move.l (sp)+,a1
	CALL _GadToolsBase-db(a5),GT_ReplyIMsg
	rts

* Gestion des boutons de la souris ( IDCMP_MOUSEBUTTONS )
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Check_Window_Buttons
	move.w Msg_Code-db(a5),d0
	cmp.w #SELECTDOWN,d0
	beq Window_select_down
	cmp.w #SELECTUP,d0
	beq Window_select_up
	rts
Window_select_down
	bsr Clear_Brush_Grid
	move.w Msg_MouseY-db(a5),Grid_Top-db(a5)
	move.w Msg_MouseX-db(a5),Grid_Left-db(a5)
	bsr Clear_Target_Grid
	bsr Draw_Brush_Grid
	bsr Display_Mouse_Info
	rts

Window_select_up
	bsr Draw_Target
	rts

* Gestion des déplacements de la souris ( IDCMP_MOUSEMOVE )
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Check_Brush
	tst.b Target_Flag-db(a5)			on a clické avant ?
	bne Draw_Target

* Dessine une grille pour delimiter la brosse
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Draw_Brush
	movem.w Grid_Top-db(a5),d0/d1
	movem.w Msg_MouseY-db(a5),d2/d3
	movem.w d2/d3,Grid_Bottom-db(a5)
	cmp.w d0,d2
	bge.s .ok1
	exg d0,d2
.ok1	cmp.w d1,d3
	bge.s .ok2
	exg d1,d3
.ok2	cmp.w Brush_Top-db(a5),d0
	bne.s .draw
	cmp.w Brush_Left-db(a5),d1
	bne.s .draw
	cmp.w Brush_Bottom-db(a5),d2
	bne.s .draw
	cmp.w Brush_Right-db(a5),d3
	bne.s .draw
	rts
.draw	bsr Clear_Brush_Grid
	bsr Draw_Brush_Grid
	bra Display_Mouse_Info

* Dessine une cible pour signaler l'emplacement de la souris
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Draw_Target
	bsr Clear_Target_Grid
	bsr Draw_Target_Grid
	bra Display_Mouse_Info

* Gestion des menus ( IDCMP_MENUPICK )
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Child_Menu	
	bsr Restore_Screen_Colors
	move.w Msg_Code-db(a5),d7
Menu_Loop
	cmp.w #MENUNULL,d7			yen a encore ?
	beq.s Menu_Exit

	move.l IFF_MenuStrip-db(a5),a0
	move.w d7,d0
	CALL _IntuitionBase-db(a5),ItemAddress

	move.l d0,-(sp)				saute à la fonction du
	move.l d0,a0				menu
	GTMENUITEM_USERDATA a0,a0
	jsr (a0)

Menu_Skip
	move.l (sp)+,a0
	move.w mi_NextSelect(a0),d7
	bra.s Menu_Loop
Menu_Exit
	rts



* Routines pour changer les couleurs lors des menus et requesters
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Save_Screen_Colors
	move.l Screen_Handle-db(a5),a0
	move.l sc_ViewPort+vp_ColorMap(a0),a0
	lea Save_ColorTab+4-db(a5),a1
	moveq #0,d0
	moveq #4,d1
	cmp.w #2,Screen_Colors-db(a5)
	bne.s .ok
	moveq #2,d1
	clr.l Default_ColorTab+(1+3+3)*4-db(a5)
	clr.l Save_ColorTab+(1+3+3)*4-db(a5)
.ok	move.w d1,Default_ColorTab-db(a5)
	move.w d1,Save_ColorTab-db(a5)
	CALL _GfxBase,GetRGB32

	move.l Screen_Handle-db(a5),a0
	lea sc_ViewPort(a0),a0
	lea Default_ColorTab-db(a5),a1
	CALL LoadRGB32
	move.w #4,Default_ColorTab-db(a5)
	move.l #$ffffffff,Default_ColorTab+(1+3+3)*4-db(a5)
	rts

Restore_Screen_Colors
	move.l Screen_Handle-db(a5),a0
	lea sc_ViewPort(a0),a0
	lea Save_ColorTab-db(a5),a1
	CALL _GfxBase-db(a5),LoadRGB32
	rts



* Routine pour l'affichage des grilles et des cibles
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Free_Brush
	bsr Clear_Brush_Grid
	bra Display_Mouse_Info

Clear_Brush_Grid
	tst.b Brush_Flag-db(a5)
	beq.s .no_clear_grid
	sf Brush_Flag-db(a5)
	move.l Window_RastPort-db(a5),a2
	move.l _GfxBase-db(a5),a6
	bsr Draw_Brush_Mask
	clr.l Brush_Top-db(a5)			Brush_Top & Brush_Left
	clr.l Brush_Bottom-db(a5)		Brush_Bottom & Brush_Right
.no_clear_grid
	rts

Draw_Brush_Grid
	st Brush_Flag-db(a5)
	movem.w Grid_Top-db(a5),d0/d1
	movem.w Msg_MouseY-db(a5),d2/d3
	movem.w d2/d3,Grid_Bottom-db(a5)
	cmp.w d0,d2
	bge.s .ok1
	exg d0,d2
.ok1	cmp.w d1,d3
	bge.s .ok2
	exg d1,d3
.ok2	movem.w d0-d3,Brush_Top-db(a5)
	move.l Window_RastPort-db(a5),a2
	move.l _GfxBase-db(a5),a6

Draw_Brush_Mask
	move.w Brush_Left-db(a5),d0		trace les 2 lignes horizontales
	move.w Brush_Top-db(a5),d1
	move.l a2,a1
	CALL Move
	move.w Brush_Right-db(a5),d0
	move.w Brush_Top-db(a5),d1
	move.l a2,a1
	CALL Draw
	move.w Brush_Left-db(a5),d0
	move.w Brush_Bottom-db(a5),d1
	move.l a2,a1
	CALL Move
	move.w Brush_Right-db(a5),d0
	move.w Brush_Bottom-db(a5),d1
	move.l a2,a1
	CALL Draw

	move.w Brush_Right-db(a5),d0		trace toujours le coté droit
	move.w Brush_Top-db(a5),d1
	move.l a2,a1
	CALL Move
	move.w Brush_Right-db(a5),d0
	move.w Brush_Bottom-db(a5),d1
	move.l a2,a1
	CALL Draw

	move.w Brush_Left-db(a5),d2		trace les droites verticales
While_Grid
	cmp.w Brush_Right-db(a5),d2
	bge.s While_End

	move.w d2,d0
	move.w Brush_Top-db(a5),d1
	move.l a2,a1
	CALL Move
	move.w d2,d0
	move.w Brush_Bottom-db(a5),d1
	move.l a1,a1
	CALL Draw
	add.w Grid_Spacing-db(a5),d2
	bra.s While_Grid
While_End
	rts

Clear_Target_Grid
	tst.b Target_Flag-db(a5)
	beq.s .no_clear_previous
	sf Target_Flag-db(a5)
	movem.w Old_MouseY-db(a5),d2-d3
	move.l Window_RastPort-db(a5),a2
	move.l _GfxBase-db(a5),a6
	bsr Draw_Target_Complement
.no_clear_previous
	rts

Draw_Target_Grid
	st Target_Flag-db(a5)
	movem.w Msg_MouseY-db(a5),d2-d3		Msg_MouseY & Msg_MouseX
	movem.w d2-d3,Old_MouseY-db(a5)
	move.l Window_RastPort-db(a5),a2
	move.l _GfxBase-db(a5),a6

Draw_Target_Complement
	move.l a2,a1				trace la droite verticale
	move.w d3,d0
	moveq #MENU_SIZE,d1
	CALL Move
	move.l a2,a1
	move.w d3,d0
	move.w Picture_Height-db(a5),d1
	add.w #MENU_SIZE-1,d1
	CALL Draw

	move.l a2,a1
	moveq #0,d0
	move.w d2,d1
	CALL Move
	move.l a2,a1
	move.w Picture_Width-db(a5),d0
	subq.w #1,d0
	move.w d2,d1
	CALL Draw
Draw_Target_Exit
	rts


* Affiche des coordonnées de la souris + d'autres info
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Display_Mouse_Info
	move.l ChildScreen_Handle-db(a5),d0
	beq .no_display_mouse_info

	move.l ChildScreen_RastPort-db(a5),a2

	move.w Msg_MouseX-db(a5),d0		affiche les coordonnées de
	moveq #4-1,d1				la souris
	lea InfoText0+44-db(a5),a0
	bsr Write_Decimal_Number

	move.w Msg_MouseY-db(a5),d0
	sub.w #MENU_SIZE,d0
	moveq #4-1,d1
	lea InfoText1+44-db(a5),a0
	bsr Write_Decimal_Number

	move.w #20+44*8,d0
	moveq #10,d1
	move.l a2,a1
	CALL _GfxBase-db(a5),Move

	lea InfoText0+44-db(a5),a0
	moveq #4,d0
	move.l a2,a1
	CALL Text

	move.w #20+44*8,d0
	moveq #20,d1
	move.l a2,a1
	CALL _GfxBase-db(a5),Move

	lea InfoText1+44-db(a5),a0
	moveq #4,d0
	move.l a2,a1
	CALL Text

	move.l Window_RastPort-db(a5),a1		affiche la couleur du pixel
	move.w Msg_MouseX-db(a5),d0		qui est sous le pointeur
	move.w Msg_MouseY-db(a5),d1		souris
	CALL ReadPixel
	moveq #4-1,d1
	lea InfoText2+44-db(a5),a0
	bsr Write_Decimal_Number

	move.w #20+44*8,d0
	moveq #30,d1
	move.l a2,a1
	CALL Move

	lea InfoText2+44-db(a5),a0
	moveq #4,d0
	move.l a2,a1
	CALL Text

	tst.b Brush_Flag-db(a5)			euh.. ya une brosse ?
	bne.s .brush

	moveq #0,d0
	moveq #4-1,d1
	lea InfoText0+71-db(a5),a0
	bsr Write_Decimal_Number

	moveq #0,d0
	moveq #4-1,d1
	lea InfoText1+71-db(a5),a0
	bsr Write_Decimal_Number

	moveq #0,d0
	moveq #4-1,d1
	lea InfoText2+71-db(a5),a0
	bsr Write_Decimal_Number
	bra.s .display_brush

.brush
	move.w Brush_Right-db(a5),d0		affiche les datas sur la
	sub.w Brush_Left-db(a5),d0			brosse
	addq.w #1,d0
	moveq #4-1,d1
	lea InfoText0+71-db(a5),a0
	bsr Write_Decimal_Number

	move.w Brush_Right-db(a5),d0
	sub.w Brush_Left-db(a5),d0
	add.w Grid_Spacing-db(a5),d0
	ext.l d0
	divu Grid_Spacing-db(a5),d0
	moveq #4-1,d1
	lea InfoText1+71-db(a5),a0
	bsr Write_Decimal_Number

	move.w Brush_Bottom-db(a5),d0
	sub.w Brush_Top-db(a5),d0
	addq.w #1,d0
	moveq #4-1,d1
	lea InfoText2+71-db(a5),a0
	bsr Write_Decimal_Number

.display_brush
	move.w #20+71*8,d0
	moveq #10,d1
	move.l a2,a1
	CALL _GfxBase-db(a5),Move

	lea InfoText0+71-db(a5),a0
	moveq #4,d0
	move.l a2,a1
	CALL Text

	move.w #20+71*8,d0
	moveq #20,d1
	move.l a2,a1
	CALL Move

	lea InfoText1+71-db(a5),a0
	moveq #4,d0
	move.l a2,a1
	CALL Text
	
	move.w #20+71*8,d0
	moveq #30,d1
	move.l a2,a1
	CALL Move

	lea InfoText2+71-db(a5),a0
	moveq #4,d0
	move.l a2,a1
	CALL Text

.no_display_mouse_info
	rts




* Flip l'affichage de l'écran d'information
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Flip_Info_Screen
	move.l Window_Handle-db(a5),a0
	CALL _IntuitionBase-db(a5),ActivateWindow

	move.l ChildScreen_Handle-db(a5),d0
	beq Open_Info_Screen
	bra Close_Info_Screen	



* Changement de résolution de l'écran en cours
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Change_Resolution
	RESET_ERROR

	bsr Save_Screen_Colors

	move.l ScreenMode_Request-db(a5),a0	propose un ScreenModeRequest
	lea ScreenModeRequest_Tags-db(a5),a1
	CALL _AslBase-db(a5),AslRequest
	tst.l d0
	beq no_select_mode
	NO_ERROR

	bsr Close_Info_Screen

	move.l Window_Handle-db(a5),a0		ferme la fenetre
	CALL _IntuitionBase-db(a5),CloseWindow
	clr.l Window_Handle-db(a5)

	move.l Screen_Handle-db(a5),a0		ferme l'écran
	CALL CloseScreen
	clr.l Screen_Handle-db(a5)

	move.l ScreenMode_Request-db(a5),a0	installe le nouveau DisplayID
	move.l sm_DisplayID(a0),d0
	move.l d0,Tag_Screen_DisplayID-db(a5)

	CALL _GfxBase-db(a5),FindDisplayInfo
	tst.l d0
	beq no_sm
	NO_ERROR

	move.l d0,a0
	lea Screen_DimensionInfo-db(a5),a1
	moveq #dim_SIZEOF,d0
	move.l #DTAG_DIMS,d1
	moveq #0,d2
	CALL GetDisplayInfoData
	tst.l d0
	beq no_sm
	NO_ERROR

	move.w Screen_DimensionInfo+dim_Nominal+ra_MaxX-db(a5),d0
	sub.w Screen_DimensionInfo+dim_Nominal+ra_MinX-db(a5),d0
	move.w d0,OpenScreen_DClip+ra_MaxX-db(a5)
	move.w Screen_DimensionInfo+dim_Nominal+ra_MaxY-db(a5),d0
	sub.w Screen_DimensionInfo+dim_Nominal+ra_MinY-db(a5),d0
	move.w d0,OpenScreen_DClip+ra_MaxY-db(a5)

	sub.l a0,a0				réouvre l'écran
	lea OpenScreen_Tags-db(a5),a1
	CALL _IntuitionBase-db(a5),OpenScreenTagList
	move.l d0,Tag_Window_Screen-db(a5)
	beq no_sm

	sub.l a0,a0				réouvre la fenetre
	lea OpenWindow_Tags-db(a5),a1
	CALL OpenWindowTagList
	move.l d0,Window_Handle-db(a5)
	beq no_sm

	move.l Window_Handle-db(a5),a0		et hop!! installe les menus
	move.l IFF_MenuStrip-db(a5),a1
	CALL _IntuitionBase-db(a5),SetMenuStrip
	tst.l d0
	beq no_sm

	move.l Window_Handle-db(a5),a0			recherche quelques datas
	move.l wd_RPort(a0),Window_RastPort-db(a5)	sur la fenetre
	move.l wd_UserPort(a0),a0
	move.l a0,Window_UserPort-db(a5)
	moveq #0,d0
	move.b MP_SIGBIT(a0),d1
	bset d1,d0
	move.l d0,Window_WaitMask-db(a5)

	move.l Window_RastPort-db(a5),a1
	moveq #RP_COMPLEMENT,d0
	CALL _GfxBase-db(a5),SetDrMd
	
	move.l Window_Handle-db(a5),a0
	move.w wd_MouseY(a0),Msg_MouseY-db(a5)
	move.w wd_MouseX(a0),Msg_MouseX-db(a5)

	move.l Tag_Window_Screen-db(a5),Screen_Handle-db(a5)
	move.l Screen_Handle-db(a5),Tag_ChildScreen_Parent-db(a5)
	move.l Screen_Handle-db(a5),Tag_LoadRequest_Screen-db(a5)
	move.l Screen_Handle-db(a5),Tag_SaveRequest_Screen-db(a5)
	move.l Screen_Handle-db(a5),Tag_ScreenModeRequest_Screen-db(a5)
	move.l #DEFAULT_MONITOR_ID!LORES_KEY,Screen_DisplayID-db(a5)
	move.l Tag_Screen_DisplayID-db(a5),Tag_ScreenModeRequest_DisplayID-db(a5)
	move.l Tag_Screen_DisplayID-db(a5),Screen_DisplayID-db(a5)
	rts

no_select_mode
	bsr Restore_Screen_Colors
	rts

no_sm
	bsr Close_Main_Screen
	bra Open_Main_Screen



* Toutes les gestions des éventuelles erreurs et sortie normale
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
iff_exit_menu
	addq.l #2*4,sp				bouffe le MenuItem + jsr
iff_exit_key
	addq.l #4,sp				bouffe le pea
	move.w #init_error_count,Error_Count-db(a5)
init_error
	cmp.w #init_error_count,Error_Count-db(a5)	erreur ???
	beq.s .no_req

	move.l #Request_InitErrorFormat,EasyRequest_TextFormat-db(a5)
	move.l Window_Handle-db(a5),a0
	lea IFF_EasyRequest-db(a5),a1
	sub.l a2,a2
	lea IFF_EasyRequest_Args-db(a5),a3
	lea Init_ErrorList-db(a5),a4
	move.w Error_Count-db(a5),d0
	move.l (a4,d0.w*4),(a3)
	CALL _IntuitionBase-db(a5),EasyRequestArgs
.no_req

	bsr Close_Main_Screen			ferme l'écran

	move.l IFF_MenuStrip-db(a5),d0		libère les menus
	beq.s .no1
	move.l d0,a0
	CALL _GadToolsBase-db(a5),FreeMenus

.no1	move.l Screen_VisualInfo-db(a5),d0		libère le visual info
	beq.s .no3
	move.l d0,a0
	CALL FreeVisualInfo

.no3	move.l IFF_Handle-db(a5),d0		libère la structure IFF
	beq.s .no4
	move.l d0,a0
	CALL _IFFParseBase-db(a5),FreeIFF

.no4	move.l Save_Request-db(a5),d0		libère le file request
	beq.s .no5
	move.l d0,a0
	CALL _AslBase-db(a5),FreeAslRequest

.no5	move.l Load_Request-db(a5),d0		libère le file request
	beq.s .no6
	move.l d0,a0
	CALL FreeAslRequest

.no6	move.l _DosBase-db(a5),a1			ferme la dos.library
	CALL _ExecBase-db(a5),CloseLibrary

	move.l _IFFParseBase-db(a5),a1		ferme l'iffparse.library
	CALL CloseLibrary

	move.l _GfxBase-db(a5),a1			ferme la graphics.library
	CALL CloseLibrary

	move.l _GadToolsBase-db(a5),a1		ferme la gadtools.library
	CALL CloseLibrary

	move.l _AslBase-db(a5),a1			ferme l'asl.library
	CALL CloseLibrary

	move.l _IntuitionBase-db(a5),a1		ferme l'intuition.library
	CALL CloseLibrary

very_grave_error
	moveq #0,d0
	rts




*********************************************************************************
***************                                                  ****************
*************** CHARGEMENT ET INTIALISATION D'UNE NOUVELLE IMAGE ****************
***************                                                  ****************
*********************************************************************************
Load_New_Picture
	move.l ChildScreen_Handle-db(a5),d0
	sne Info_Flag-db(a5)

	bsr Close_Info_Screen
	bsr Save_Screen_Colors

	move.l Screen_Handle-db(a5),a0
	move.w sc_LeftEdge(a0),Tag_LoadRequest_LeftEdge+2-db(a5)
	neg.w Tag_LoadRequest_LeftEdge+2-db(a5)
	move.w sc_TopEdge(a0),Tag_LoadRequest_TopEdge+2-db(a5)
	neg.w Tag_LoadRequest_TopEdge+2-db(a5)
	add.w #MENU_SIZE,Tag_LoadRequest_TopEdge+2-db(a5)
	move.l Load_Request-db(a5),a0		propose un FileRequest
	lea LoadRequest_Tags-db(a5),a1
	CALL _AslBase-db(a5),AslRequest
	tst.l d0
	beq no_select_file

	RESET_ERROR
	bsr Close_Main_Screen			ferme l'écran et son bastringue

	move.l Load_Request-db(a5),a2		recopie du path pour utiliser
	move.l fr_Drawer(a2),a0			ensuite AddPart()
	lea RealFileName-db(a5),a1
	move.l a1,d1
.dup	move.b (a0)+,(a1)+
	bne.s .dup
	move.l fr_File(a2),d2			fabrication du path + filename
	moveq #REALFILENAME_SIZE,d3		merci la dos.library !
	CALL _DosBase,AddPart
	tst.l d0
	beq no_addpart
	NO_ERROR

	lea RealFileName-db(a5),a0		ouvre le fichier que le user
	move.l a0,d1				veut charger
	move.l #MODE_OLDFILE,d2
	CALL Open
	move.l IFF_Handle-db(a5),a0
	move.l d0,iff_Stream(a0)
	beq no_file
	NO_ERROR

* Init le fichier IFF comme étant un fichier DOS + démarrage du parsing
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.l IFF_Handle-db(a5),a0		démarre le parsing
	moveq #IFFF_READ,d0
	CALL _IFFParseBase-db(a5),OpenIFF
	tst.l d0
	bne no_open_iff
	NO_ERROR

* Déclaration des chunks à chercher
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.l IFF_Handle-db(a5),a0		déclare les chunks à rechercher:
	lea PropChunks_Tags-db(a5),a1		BMHD,CMAP,CAMG
	moveq #3,d0
	CALL PropChunks
	tst.l d0
	bne no_parse

	move.l IFF_Handle-db(a5),a0		déclare le chunk d'arret:
	move.l #ID_ILBM,d0			BODY
	move.l #ID_BODY,d1
	CALL StopChunk
	tst.l d0
	bne no_parse

* Scanne tout le fichier ( IFF ? )
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.l IFF_Handle-db(a5),a0
	moveq #IFFPARSE_SCAN,d0
	CALL ParseIFF
	tst.l d0
	bne no_parse

* Recherche chaque chunk en mémoire
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.l IFF_Handle-db(a5),a0		recherche les chunks:
	move.l #ID_ILBM,d0			CMAP,BMHD,CAMG,BODY
	move.l #ID_CMAP,d1			 ^
	CALL FindProp				 |
	move.l d0,CMAP_Chunk-db(a5)		 +--------- Optionnel

	move.l IFF_Handle-db(a5),a0
	move.l #ID_ILBM,d0
	move.l #ID_BMHD,d1
	CALL FindProp
	move.l d0,BMHD_Chunk-db(a5)
	beq no_parse

	move.l IFF_Handle-db(a5),a0
	move.l #ID_ILBM,d0
	move.l #ID_CAMG,d1
	CALL FindProp
	move.l d0,CAMG_Chunk-db(a5)
	beq no_parse
	NO_ERROR

* Recherche des info sur l'écran et Allocation d'une BitMap
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.l CAMG_Chunk-db(a5),a0
	move.l spr_Data(a0),a0
	move.l (a0),d0
	and.l #CAMG_MASK,d0
	move.l d0,Screen_DisplayID-db(a5)
	CALL _GfxBase-db(a5),FindDisplayInfo
	tst.l d0
	beq no_finddisplayinfo
	NO_ERROR

	move.l d0,a0
	lea Screen_DimensionInfo-db(a5),a1
	moveq #dim_SIZEOF,d0
	move.l #DTAG_DIMS,d1
	moveq #0,d2
	CALL GetDisplayInfoData
	tst.l d0
	beq no_getdisplayinfodata
	NO_ERROR

	move.w Screen_DimensionInfo+dim_Nominal+ra_MaxX-db(a5),d0
	sub.w Screen_DimensionInfo+dim_Nominal+ra_MinX-db(a5),d0
	move.w d0,OpenScreen_DClip+ra_MaxX-db(a5)
	move.w Screen_DimensionInfo+dim_Nominal+ra_MaxY-db(a5),d0
	sub.w Screen_DimensionInfo+dim_Nominal+ra_MinY-db(a5),d0
	move.w d0,OpenScreen_DClip+ra_MaxY-db(a5)

	move.l BMHD_Chunk-db(a5),a0		alloue une Bitmap pour
	move.l spr_Data(a0),a0			l'écran

	move.b bmh_Compression(a0),Crunch_Mode-db(a5)
	move.w bmh_Left(a0),Tag_Screen_Left-db(a5)
	move.w bmh_Top(a0),Tag_Screen_Top-db(a5)

	move.w bmh_Width(a0),d0
	move.w d0,Picture_Width-db(a5)
	cmp.w OpenScreen_DClip+ra_MaxX-db(a5),d0
	bge.s .ok1
	move.w OpenScreen_DClip+ra_MaxX-db(a5),d0
.ok1
	move.w bmh_Height(a0),d1
	move.w d1,Picture_Height-db(a5)
	cmp.w OpenScreen_DClip+ra_MaxY-db(a5),d1
	bge.s .ok2
	move.w OpenScreen_DClip+ra_MaxY-db(a5),d1
.ok2
	add.w #MENU_SIZE,d1
	move.w d0,Tag_Screen_Width-db(a5)
	move.w d0,Screen_Width-db(a5)
	move.w d1,Tag_Screen_Height-db(a5)
	move.w d1,Screen_Height-db(a5)
	moveq #0,d2
	move.b bmh_Depth(a0),d2
	move.w d2,Tag_Screen_Depth-db(a5)
	move.w d2,Screen_Depth-db(a5)
	moveq #BMF_CLEAR!BMF_DISPLAYABLE!BMF_INTERLEAVED,d3
	sub.l a0,a0
	CALL AllocBitMap
	move.l d0,Tag_Screen_BitMap-db(a5)
	move.l d0,Tag_Window_BitMap-db(a5)
	beq no_allocbitmap_screen

* Mise en place de la palette de l'image
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.l CMAP_Chunk-db(a5),d0		euh.. ya une colormap ?
	beq.s skip_palette

	move.l d0,a0
	move.l spr_Size(a0),d0
	move.l spr_Data(a0),a0
	lea ColorTab-db(a5),a1
	move.l d0,d1
	divu #3,d1
	move.w d1,(a1)+				nb de couleurs dans la palette
	move.w d1,Screen_Colors-db(a5)
	clr.w (a1)+				couleur de départ
	subq.w #1,d0				à cause du dbf
Make_ColorTab
	move.b (a0)+,d1				à partir de $XY.b on fabrique
	move.b d1,(a1)+				$XYXYXYXY.l
	move.b d1,(a1)+
	move.b d1,(a1)+
	move.b d1,(a1)+
	dbf d0,Make_ColorTab
	clr.l (a1)+				ATTENTION : un 0 à la fin !!!

* Ouverture de l'écran
* ~~~~~~~~~~~~~~~~~~~~
skip_palette
	move.l CAMG_Chunk-db(a5),a0
	move.l spr_Data(a0),a0
	move.l (a0),d0
	and.l #CAMG_MASK,d0
	move.l d0,Tag_Screen_DisplayID-db(a5)
	move.l #ColorTab,Tag_Screen_ColorTab-db(a5)
	sub.l a0,a0
	lea OpenScreen_Tags-db(a5),a1
	CALL _IntuitionBase-db(a5),OpenScreenTagList
	move.l d0,Tag_Window_Screen-db(a5)
	beq no_openscreen
	NO_ERROR

* Allocation de mémoire pour charger le chunk BODY
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.l IFF_Handle-db(a5),a0		recherche la taille du
	CALL _IFFParseBase-db(a5),CurrentChunk	chunk BODY

	move.l d0,a0
	move.l cn_Size(a0),d0
	move.l d0,Mem_Size-db(a5)
	move.l #MEMF_PUBLIC,d1
	CALL _ExecBase-db(a5),AllocMem
	move.l d0,Mem_Adr-db(a5)
	beq no_allocmem
	NO_ERROR

	move.l IFF_Handle-db(a5),a0
	move.l d0,a1
	CALL _IFFParseBase-db(a5),ReadChunkBytes
	tst.l d0
	bmi no_readchunkbytes
	NO_ERROR

* On se charge ici de mettre le chunk BODY dans les bitplans
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	add.w #MENU_SIZE,Picture_Height-db(a5)		*** arf!!!! ***
	tst.b Crunch_Mode-db(a5)
	beq Body_None
	cmp.b #cmpByteRun1,Crunch_Mode-db(a5)
	bne no_decrunch

* Décrunchage d'une image ByteRun1
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Body_ByteRun1
	move.l Tag_Window_Screen-db(a5),a0		cherche les ptrs videos de
	move.l sc_RastPort+rp_BitMap(a0),a0	l'écran
	move.l Mem_Adr-db(a5),a1
	move.w bm_BytesPerRow(a0),d0		taille réelle d'une ligne écran
	moveq #0,d1
	move.w Picture_Width-db(a5),d1		recherche la largeur d'une
	add.w #15,d1				ligne écran
	lsr.w #4,d1
	add.w d1,d1
	move.w Screen_Depth-db(a5),d2		nombre de bitplans
	subq.w #1,d2
	moveq #MENU_SIZE,d3			on commence à cette ligne
	lea bm_Planes(a0),a0
BR1_Next_Line
	move.l a0,a2
	move.w d2,d4
BR1_Next_Bpl
	move.l (a2)+,a3
	move.w d3,d5				\ calcule l'offset pour
	mulu.w d0,d5				/ arriver à la bonne ligne
	add.l d5,a3
	moveq #0,d5
BR1_Next_Control
	move.b (a1)+,d6				lit un octet de controle
	bmi.s crunched

not_crunched
	ext.w d6
	add.w d6,d5
	addq.w #1,d5
.copy	move.b (a1)+,(a3)+
	dbf d6,.copy
	cmp.w d1,d5
	blt.s BR1_Next_Control
	dbf d4,BR1_Next_Bpl
	addq.w #1,d3
	cmp.w Picture_Height-db(a5),d3
	blt.s BR1_Next_Line
	bra loading_successful

crunched
	cmp.b #$80,d6				octet de padding ?
	beq.s BR1_Next_Control
	neg.b d6
	ext.w d6
	add.w d6,d5
	addq.w #1,d5
	move.b (a1)+,d7
.copy	move.b d7,(a3)+
	dbf d6,.copy
	cmp.w d1,d5
	blt BR1_Next_Control
	dbf d4,BR1_Next_Bpl
	addq.w #1,d3
	cmp.w Picture_Height-db(a5),d3
	blt BR1_Next_Line
	bra.s loading_successful

* Image non crunchée
* ~~~~~~~~~~~~~~~~~~
Body_None
	move.l Tag_Window_Screen-db(a5),a0		cherche les ptrs videos de
	move.l sc_RastPort+rp_BitMap(a0),a0	l'écran
	move.l Mem_Adr-db(a5),a1
	move.w bm_BytesPerRow(a0),d0		taille réelle d'une ligne écran
	moveq #0,d1
	move.w Picture_Width-db(a5),d1		recherche la largeur d'une
	add.w #15,d1				ligne écran
	lsr.w #4,d1
	add.w d1,d1
	subq.w #1,d1
	move.w Screen_Depth-db(a5),d2		nb de bitplans
	subq.w #1,d2
	moveq #MENU_SIZE,d3			on commence à la ligne 0
	lea bm_Planes(a0),a0
.Next_Line
	move.l a0,a2
	move.w d2,d4
	move.w d3,d5				\ calcule l'offset pour arriver
	mulu.w d0,d5				/ à la bonne ligne
.Next_Bpl
	move.l (a2)+,a3				adresse d'un bpl
	add.l d5,a3
	move.w d1,d6
.Put_Data
	move.b (a1)+,(a3)+
	dbf d6,.Put_Data
	dbf d4,.Next_Bpl
	addq.w #1,d3				ligne suivante
	cmp.w Picture_Height-db(a5),d3
	blt.s .Next_Line

loading_successful

* Ouverture d'une fenetre sur l'écran
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.w Tag_Screen_Width-db(a5),Tag_Window_Width-db(a5)
	move.w Tag_Screen_Height-db(a5),Tag_Window_Height-db(a5)	
	sub.l a0,a0
	lea OpenWindow_Tags-db(a5),a1
	CALL _IntuitionBase-db(a5),OpenWindowTagList
	move.l d0,Tag_Window-db(a5)
	beq no_window
	NO_ERROR

	move.l d0,a0				met en place le menu
	move.l IFF_MenuStrip-db(a5),a1
	CALL SetMenuStrip
	tst.l d0
	beq no_window_menustrip
	NO_ERROR

	sub.w #MENU_SIZE,Picture_Height-db(a5)
	move.l Mem_Size-db(a5),d0			libère la mémoire allouée
	move.l Mem_Adr-db(a5),a1
	CALL _ExecBase-db(a5),FreeMem

	move.l IFF_Handle-db(a5),a0		ferme le bidule iff
	CALL _IFFParseBase-db(a5),CloseIFF

	move.l IFF_Handle-db(a5),a0		ferme le fichier iff
	move.l iff_Stream(a0),d1
	CALL _DosBase-db(a5),Close

	move.l Tag_Window-db(a5),Window_Handle-db(a5)
	move.l Tag_Window_Screen-db(a5),Screen_Handle-db(a5)
	move.l Tag_Screen_BitMap-db(a5),BitMap_Handle-db(a5)
	move.l Screen_Handle-db(a5),Tag_ChildScreen_Parent-db(a5)
	move.l Screen_Handle-db(a5),Tag_LoadRequest_Screen-db(a5)
	move.l Screen_Handle-db(a5),Tag_SaveRequest_Screen-db(a5)
	move.l Screen_Handle-db(a5),Tag_ScreenModeRequest_Screen-db(a5)
	move.l Screen_DisplayID-db(a5),Tag_ScreenModeRequest_DisplayID-db(a5)
	move.l Window_Handle-db(a5),a0		recherche quelques datas
	move.l wd_RPort(a0),Window_RastPort-db(a5)
	move.l wd_UserPort(a0),a0
	move.l a0,Window_UserPort-db(a5)
	moveq #0,d0
	move.b MP_SIGBIT(a0),d1
	bset d1,d0
	move.l d0,Window_WaitMask-db(a5)

	move.l Window_RastPort-db(a5),a1
	moveq #RP_COMPLEMENT,d0
	CALL _GfxBase-db(a5),SetDrMd

	sf Brush_Flag-db(a5)
	bsr Draw_Target_Grid

	tst.b Info_Flag-db(a5)
	bne Open_Info_Screen
	rts


no_decrunch
	move.l Tag_Window-db(a5),a0		vire les menus
	CALL _IntuitionBase-db(a5),ClearMenuStrip
no_window_menustrip
	move.l Tag_Window-db(a5),a0		ferme la fenetre
	CALL CloseWindow
no_window
no_readchunkbytes
	move.l Mem_Size-db(a5),d0			libère la mémoire allouée
	move.l Mem_Adr-db(a5),a1
	CALL _ExecBase-db(a5),FreeMem
no_allocmem
	move.l Tag_Window_Screen-db(a5),a0		ferme l'écran
	CALL CloseScreen
no_openscreen
	move.l Tag_Window_BitMap-db(a5),a0		libère la bitmap de la fenetre
	CALL _GfxBase-db(a5),FreeBitMap
no_allocbitmap_window
	move.l Tag_Screen_BitMap-db(a5),a0		libère la bitmap de l'écran
	CALL FreeBitMap
no_allocbitmap_screen
no_getdisplayinfodata
no_finddisplayinfo
no_parse
	move.l IFF_Handle-db(a5),a0
	CALL _IFFParseBase-db(a5),CloseIFF
no_open_iff
	move.l IFF_Handle-db(a5),a0		ferme le fichier
	move.l iff_Stream(a0),d1
	CALL _DosBase-db(a5),Close
no_file
no_addpart
	bsr Open_Main_Screen
	beq iff_exit_menu

	bsr Save_Screen_Colors

	move.l #Request_LoadErrorFormat,EasyRequest_TextFormat-db(a5)
	move.l Window_Handle-db(a5),a0
	lea IFF_EasyRequest-db(a5),a1
	sub.l a2,a2
	lea IFF_EasyRequest_Args-db(a5),a3
	lea Load_ErrorList-db(a5),a4
	move.w Error_Count-db(a5),d0
	move.l (a4,d0.w*4),(a3)
	CALL _IntuitionBase-db(a5),EasyRequestArgs
no_select_file
	bsr Restore_Screen_Colors
	rts	



*********************************************************************************
***************                                                  ****************
***************             SAUVEGARDE D'UNE BROSSE 		 ****************
***************                                                  ****************
*********************************************************************************

Init_Save_Raw_Normal_Picture
	move.w #SAVE_RAW_NORMAL,Save_Method-db(a5)
	bra.s Save_Picture

Init_Save_Raw_Interleaved_Picture
	move.w #SAVE_RAW_INTERLEAVED,Save_Method-db(a5)
	bra.s Save_Picture

Init_Save_Chunky8_Picture
	move.w #SAVE_CHUNKY8,Save_Method-db(a5)

Save_Picture
	clr.w Save_Left-db(a5)
	move.w Picture_Width-db(a5),Save_Right-db(a5)
	subq.w #1,Save_Right-db(a5)
	move.w #MENU_SIZE,Save_Top-db(a5)
	move.w Picture_Height-db(a5),Save_Bottom-db(a5)
	add.w #MENU_SIZE-1,Save_Bottom-db(a5)

	bsr Clear_Brush_Grid
	bsr Clear_Target_Grid
	bsr Save_Screen_Colors
	bra Save_Box



Init_Save_Raw_Normal_Brush
	move.w #SAVE_RAW_NORMAL,Save_Method-db(a5)
	bra.s Save_Brush

Init_Save_Raw_Interleaved_Brush
	move.w #SAVE_RAW_INTERLEAVED,Save_Method-db(a5)
	bra.s Save_Brush

Init_Save_Chunky8_Brush
	move.w #SAVE_CHUNKY8,Save_Method-db(a5)

Save_Brush
	bsr Clear_Brush_Grid
	bsr Clear_Target_Grid
	bsr Save_Screen_Colors

	tst.b Brush_Flag-db(a5)			euh.. ya une brosse au moins ?
	beq no_save_file

	movem.w Brush_Top-db(a5),d0-d3
	movem.w d0-d3,Save_Top-db(a5)


* sauvegarde d'une boite
* ~~~~~~~~~~~~~~~~~~~~~~
Save_Box
	move.l Window_Handle-db(a5),a0		met un pointeur busy
	lea Sleep_Window_Tags(pc),a1
	CALL _IntuitionBase-db(a5),SetWindowPointerA

	move.l ChildScreen_Handle-db(a5),d0
	sne Info_Flag-db(a5)
	bsr Close_Info_Screen

	move.l Screen_Handle-db(a5),a0
	move.w sc_LeftEdge(a0),Tag_SaveRequest_LeftEdge+2-db(a5)
	neg.w Tag_SaveRequest_LeftEdge+2-db(a5)
	move.w sc_TopEdge(a0),Tag_SaveRequest_TopEdge+2-db(a5)
	neg.w Tag_SaveRequest_TopEdge+2-db(a5)
	add.w #MENU_SIZE,Tag_SaveRequest_TopEdge+2-db(a5)
	move.l Save_Request-db(a5),a0		propose un FileRequest
	lea SaveRequest_Tags-db(a5),a1
	CALL _AslBase-db(a5),AslRequest
	tst.l d0
	beq no_save_file

	bsr Restore_Screen_Colors

	move.l Save_Request-db(a5),a2		recopie du path pour utiliser
	move.l fr_Drawer(a2),a0			ensuite AddPart()
	lea RealFileName-db(a5),a1
	move.l a1,d1
.dup	move.b (a0)+,(a1)+
	bne.s .dup
	move.l fr_File(a2),d2			fabrication du path + filename
	moveq #REALFILENAME_SIZE,d3		merci la dos.library !
	CALL _DosBase,AddPart
	tst.l d0
	beq error_Save_AddPart

	lea RealFileName-db(a5),a0			ouverture du fichier en
	move.l a0,d1				écriture
	move.l #MODE_NEWFILE,d2
	CALL Open
	move.l d0,File_Handle-db(a5)		c tout bon ?
	beq error_Save_Open

* à partir d'ici on est sur le bon directory et le fichier est ouvert
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.w Save_Method-db(a5),d0		SAVE_RAW_NORMAL
	beq Save_RAW_Normal
	subq.w #1,d0				SAVE_RAW_INTERLEAVED
	beq Save_RAW_Interleaved
	subq.w #1,d0				SAVE_CHUNKY8
	beq Save_Chunky8
;	subq.w #1,d0				SAVE_CHUNKY16
;	beq Save_Chunky16
;	subq.w #1,d0
;	beq Save_Chunky24			SAVE_CHUNKY24
	bra no_save_file


* Sauvegarde d'une brosse au format RAW Normal
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Save_RAW_Normal
	move.l Window_RastPort-db(a5),a2	RastPort de la fenetre
	lea Buffer-db(a5),a3			c'est là kon ecrit en buffer
	move.l #BUFFER_SIZE,d2
	move.l _DosBase-db(a5),a4
	move.l _GfxBase-db(a5),a6

	moveq #0,d6				bitplan qu'on traite
Save_Raw_Normal_Picture
	move.w Save_Top-db(a5),d5
Save_Raw_Normal_Bitplan
	move.w Save_Left-db(a5),d4
Save_Raw_Normal_Line
Return_Flush_Raw_Normal
	moveq #0,d3
	moveq #15,d7				on traite par mots
Save_Raw_Normal_Word
	move.l a2,a1				A1=RastPort
	move.w d4,d0				D0=X
	move.w d5,d1				D1=Y
	CALL ReadPixel

	btst d6,d0				test le bit du bitplan
	beq.s Save_Raw_Normal_Next_Pixel
	bset d7,d3
Save_Raw_Normal_Next_Pixel
	addq.w #1,d4				ya encore des pixels a sauver
	cmp.w Save_Right-db(a5),d4		sur la ligne ?
	bgt Save_Normal_Save_Next_line
	dbf d7,Save_Raw_Normal_Word

	move.w d3,(a3)+				sauve dans le buffer
	subq.l #2,d2
	bne.s Save_Raw_Normal_Line
	bra.s Flush_Raw_Normal_Buffer

* sauvegarde dans le buffer
Save_Normal_Save_Next_line
	move.w d3,(a3)+				sauve dans le buffer
	subq.l #2,d2
	bne.s Save_Normal_Next_Line

	move.l File_Handle-db(a5),d1
	move.l #Buffer,d2
	move.l #BUFFER_SIZE,d3
	exg a4,a6				A6=_DosBase
	CALL Write
	exg a4,a6				A6=_GfxBase
	lea Buffer-db(a5),a3
	move.l d3,d2				BUFFER_SIZE
	cmp.l d0,d3
	beq.s Save_Normal_Next_Line
	exg a4,a6				A6=_DosBase
	bra Raw_Normal_Buffer_Error

Save_Normal_Next_Line
	addq.w #1,d5				ya encore des lignes a sauver
	cmp.w Save_Bottom-db(a5),d5		dans le bitplan ?
	ble Save_Raw_Normal_Bitplan

	addq.w #1,d6				ya encore des bitplans
	cmp.w Screen_Depth-db(a5),d6		a sauver ?
	bne Save_Raw_Normal_Picture

	move.l File_Handle-db(a5),d1		c'est fini... flush le buffer
	move.l #BUFFER_SIZE,d3			et on se casse
	sub.l d2,d3
	move.l #Buffer,d2
	exg a4,a6				A6=_DosBase
	CALL Write
	cmp.l d0,d3
	beq error_Save_no_error
	bra.s Raw_Normal_Buffer_Error

Flush_Raw_Normal_Buffer
	move.l File_Handle-db(a5),d1
	move.l #Buffer,d2
	move.l #BUFFER_SIZE,d3
	exg a4,a6				A6=_DosBase
	CALL Write
	exg a4,a6				A6=_GfxBase
	lea Buffer-db(a5),a3
	move.l d3,d2				BUFFER_SIZE
	cmp.l d0,d3
	beq Return_Flush_Raw_Normal
	exg a4,a6				A6=_DosBase

Raw_Normal_Buffer_Error
	bra error_Save_no_error
	



* Sauvegarde d'une brosse au format RAW Interleaved
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Save_RAW_Interleaved
	move.l Window_RastPort-db(a5),a2	RastPort de la fenetre
	lea Buffer-db(a5),a3			c'est là kon ecrit en buffer
	move.l #BUFFER_SIZE,d2
	move.l _DosBase-db(a5),a4
	move.l _GfxBase-db(a5),a6

	move.w Save_Top-db(a5),d5
Save_Raw_Int_Picture
	moveq #0,d6				bitplan qu'on traite
Save_Raw_Int_Bitplan
	move.w Save_Left-db(a5),d4
Save_Raw_Int_Line
Return_Flush_Raw_Int
	moveq #0,d3
	moveq #15,d7				on traite par mots
Save_Raw_Int_Word
	move.l a2,a1				A1=RastPort
	move.w d4,d0				D0=X
	move.w d5,d1				D1=Y
	CALL ReadPixel

	btst d6,d0				test le bit du bitplan
	beq.s Save_Raw_Int_Next_Pixel
	bset d7,d3
Save_Raw_Int_Next_Pixel
	addq.w #1,d4				ya encore des pixels a sauver
	cmp.w Save_Right-db(a5),d4		sur la ligne ?
	bgt Save_Int_Save_Next_line
	dbf d7,Save_Raw_Int_Word

	move.w d3,(a3)+				sauve dans le buffer
	subq.l #2,d2
	bne.s Save_Raw_Int_Line
	bra.s Flush_Raw_Int_Buffer

* sauvegarde dans le buffer
Save_Int_Save_Next_line
	move.w d3,(a3)+				sauve dans le buffer
	subq.l #2,d2
	bne.s Save_Int_Next_Line

	move.l File_Handle-db(a5),d1
	move.l #Buffer,d2
	move.l #BUFFER_SIZE,d3
	exg a4,a6				A6=_DosBase
	CALL Write
	exg a4,a6				A6=_GfxBase
	lea Buffer-db(a5),a3
	move.l d3,d2				BUFFER_SIZE
	cmp.l d0,d3
	beq.s Save_Int_Next_Line
	exg a4,a6				A6=_DosBase
	bra Raw_Int_Buffer_Error

Save_Int_Next_Line
	addq.w #1,d6				ya encore des bitplans
	cmp.w Screen_Depth-db(a5),d6		a sauver ?
	bne Save_Raw_Int_Bitplan

	addq.w #1,d5				ya encore des lignes a sauver
	cmp.w Save_Bottom-db(a5),d5		dans le bitplan ?
	ble Save_Raw_Int_Picture

	move.l File_Handle-db(a5),d1		c'est fini... flush le buffer
	move.l #BUFFER_SIZE,d3			et on se casse
	sub.l d2,d3
	move.l #Buffer,d2
	exg a4,a6				A6=_DosBase
	CALL Write
	cmp.l d0,d3
	beq error_Save_no_error
	bra.s Raw_Int_Buffer_Error

Flush_Raw_Int_Buffer
	move.l File_Handle-db(a5),d1
	move.l #Buffer,d2
	move.l #BUFFER_SIZE,d3
	exg a4,a6				A6=_DosBase
	CALL Write
	exg a4,a6				A6=_GfxBase
	lea Buffer-db(a5),a3
	move.l d3,d2				BUFFER_SIZE
	cmp.l d0,d3
	beq Return_Flush_Raw_Int
	exg a4,a6				A6=_DosBase

Raw_Int_Buffer_Error
	bra error_Save_no_error




* Sauvegarde d'une brosse au format Chunky8
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Save_Chunky8
	cmp.w #1<<8,Screen_Depth-db(a5)
	bgt error_Chunky_too_much

	move.l Window_RastPort-db(a5),a2		RastPort de la fenetre
	lea Buffer-db(a5),a3			c'est là kon ecrit en buffer
	move.l #BUFFER_SIZE,d2
	move.w Save_Top-db(a5),d5
	move.l _DosBase-db(a5),a4
	move.l _GfxBase-db(a5),a6
loop_Chunky8_all
	move.w Save_Left-db(a5),d4
loop_Chunky8_line
	move.l a2,a1				A1=RastPort
	move.w d4,d0				D0=X
	move.w d5,d1				D1=Y
	CALL ReadPixel
	move.b d0,(a3)+				D0=Offset Couleur
	subq.l #1,d2				on flush le buffer ?
	beq.s Flush_Chunky8_Buffer
Return_Flush_Chunky8
	addq.w #1,d4				point suivant sur la droite
	cmp.w Save_Right-db(a5),d4			c'est la fin ?
	ble.s loop_Chunky8_line
	addq.w #1,d5				ligne suivante vers le bas
	cmp.w Save_Bottom-db(a5),d5		c'est la fin ?
	ble.s loop_Chunky8_all

	move.l File_Handle-db(a5),d1		c'est fini... flush le buffer
	move.l #BUFFER_SIZE,d3			et on se casse
	sub.l d2,d3
	move.l #Buffer,d2
	exg a4,a6				A6=_DosBase
	CALL Write
	cmp.l d0,d3
	beq.s error_Save_no_error
	bra.s Chunky8_Buffer_Error

Flush_Chunky8_Buffer
	move.l File_Handle-db(a5),d1
	move.l #Buffer,d2
	move.l #BUFFER_SIZE,d3
	exg a4,a6				A6=_DosBase
	CALL Write
	exg a4,a6				A6=_GfxBase
	lea Buffer-db(a5),a3
	move.l d3,d2				BUFFER_SIZE
	cmp.l d0,d3
	beq.s Return_Flush_Chunky8
	exg a4,a6				A6=_DosBase

Chunky8_Buffer_Error
	bra error_Save_no_error
	
	

* Sauvegarde d'une brosse au format Chunky16
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Save_Chunky16


* Sauvegarde d'une brosse au format Chunky24
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Save_Chunky24


error_Chunky_too_much
error_Save_no_error
	move.l File_Handle-db(a5),d1
	CALL Close

error_Save_Open
error_Save_AddPart

no_save_file
	bsr Restore_Screen_Colors

	bsr Draw_Target_Grid

	tst.b Brush_Flag-db(a5)
	beq.s .no_brush
	bsr Draw_Brush_Grid
.no_brush

	tst.b Info_Flag-db(a5)
	beq.s .no_info_screen

	bsr Open_Info_Screen

.no_info_screen
	move.l Window_Handle-db(a5),a0		remet le pointeur
	lea WakeUp_Window_Tags(pc),a1
	CALL _IntuitionBase-db(a5),SetWindowPointerA

	rts





*****************************************************************************
*****************                                               *************
*****************          SAUVEGARDE DES PALETTES              *************
*****************                                               *************
*****************************************************************************

* Sauvegarde de la palette en 12 bits ( octet de poids fort des composantes )
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Save_Palette12
	bsr Save_Palette_Init
	bsr Restore_Screen_Colors

	lea ColorTab+4-db(a5),a0
	move.w Screen_Colors-db(a5),d7
	lea Buffer-db(a5),a1
	bra.s .start
.save
	move.b (a0),d0
	lsl.w #4,d0
	move.b 4(a0),d0
	lsl.w #4,d0
	move.b 8(a0),d0
	lsr.w #4,d0
	and.w #$fff,d0
	move.w d0,(a1)+
	lea 4*3(a0),a0
.start
	dbf d7,.save

	move.l File_Handle-db(a5),d1
	move.l #Buffer,d2
	moveq #0,d3
	move.w Screen_Colors-db(a5),d3
	add.w d3,d3
	CALL _DosBase-db(a5),Write

	move.l File_Handle-db(a5),d1
	CALL Close
	clr.l File_Handle-db(a5)
	rts


* Sauvegarde de la palette en 24 bits ( $00RrGgBb )
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Save_Palette24
	bsr Save_Palette_Init
	bsr Restore_Screen_Colors


	lea ColorTab+4-db(a5),a0
	move.w Screen_Colors-db(a5),d7
	lea Buffer-db(a5),a1			c'est là kon ecrit en buffer
	bra.s .start
.save
	moveq #0,d0
	move.b (a0),d0				le rouge
	lsl.w #8,d0
	move.b 4(a0),d0				le vert
	lsl.l #8,d0
	move.b 8(a0),d0				le bleu
	move.l d0,(a1)+
	lea 4*3(a0),a0
.start
	dbf d7,.save

	move.l File_Handle-db(a5),d1
	move.l #Buffer,d2
	moveq #0,d3
	move.w Screen_Colors-db(a5),d3
	add.w d3,d3
	add.w d3,d3
	CALL _DosBase-db(a5),Write

	move.l File_Handle-db(a5),d1
	CALL Close
	clr.l File_Handle-db(a5)
	rts


* Sauvegarde de la palette en 24 bits entrelardés ( $0RGB0rgb )
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Save_Palette24_Interlaced
	bsr Save_Palette_Init
	bsr Restore_Screen_Colors


	lea ColorTab+4-db(a5),a0
	move.w Screen_Colors-db(a5),d7
	lea Buffer-db(a5),a1			c'est là kon ecrit en buffer
	bra.s .start
.save
	moveq #0,d0
	move.b (a0),d0				d0=$00Rr
	lsl.w #4,d0				d0=$0Rr0
	move.w d0,d1				d1=$0Rr0
	and.w #$f0,d1				d1=$00r0

	move.b 4(a0),d0				d0=$0RGg
	move.b d0,d2				d2=$Gg
	and.b #$f,d2				d2=$0g
	or.b d2,d1				d1=$00rg
	lsl.w #4,d1				d1=$0rg0
	and.w #$ff0,d0				d0=$0RG0

	move.b 8(a0),d2				d2=$Bb
	move.b d2,d3				d3=$Bb
	and.b #$f,d3				d3=$0b
	or.b d3,d1				d1=$0rgb
	lsr.b #4,d2				d2=$0B
	or.b d2,d0				d1=$0RGB

	move.w d0,(a1)+				$0RGB
	move.w d1,(a1)+				$0rgb

	lea 4*3(a0),a0
.start
	dbf d7,.save

	move.l File_Handle-db(a5),d1
	move.l #Buffer,d2
	moveq #0,d3
	move.w Screen_Colors-db(a5),d3
	add.w d3,d3
	add.w d3,d3
	CALL _DosBase-db(a5),Write

	move.l File_Handle-db(a5),d1
	CALL Close
	clr.l File_Handle-db(a5)
	rts




Save_Palette_Init
	move.l Window_Handle-db(a5),a0		met un pointeur busy
	lea Sleep_Window_Tags(pc),a1
	CALL _IntuitionBase-db(a5),SetWindowPointerA

	move.l ChildScreen_Handle-db(a5),d0
	sne Info_Flag-db(a5)
	bsr Close_Info_Screen

	bsr Save_Screen_Colors

	move.l Screen_Handle-db(a5),a0
	move.w sc_LeftEdge(a0),Tag_SaveRequest_LeftEdge+2-db(a5)
	neg.w Tag_SaveRequest_LeftEdge+2-db(a5)
	move.w sc_TopEdge(a0),Tag_SaveRequest_TopEdge+2-db(a5)
	neg.w Tag_SaveRequest_TopEdge+2-db(a5)
	add.w #MENU_SIZE,Tag_SaveRequest_TopEdge+2-db(a5)
	move.l Save_Request-db(a5),a0		propose un FileRequest
	lea SaveRequest_Tags-db(a5),a1
	CALL _AslBase-db(a5),AslRequest
	tst.l d0
	beq error_Save_Palette_no_file

	move.l Save_Request-db(a5),a2		recopie du path pour utiliser
	move.l fr_Drawer(a2),a0			ensuite AddPart()
	lea RealFileName-db(a5),a1
	move.l a1,d1
.dup	move.b (a0)+,(a1)+
	bne.s .dup
	move.l fr_File(a2),d2			fabrication du path + filename
	moveq #REALFILENAME_SIZE,d3		merci la dos.library !
	CALL _DosBase,AddPart
	tst.l d0
	beq error_Save_AddPart

	lea RealFileName-db(a5),a0		ouverture du fichier en
	move.l a0,d1				écriture
	move.l #MODE_NEWFILE,d2
	CALL Open
	move.l d0,File_Handle-db(a5)		c tout bon ?
	beq error_Save_Open
	rts



error_Save_Palette_Open
error_Save_Palette_AddPart
error_Save_Palette_no_file
	bsr Restore_Screen_Colors
	addq.l #4,sp				bouffe l'adr de Save_PaletteX

	tst.b Info_Flag-db(a5)
	beq.s .no_info_Screen

	bsr Open_Info_Screen

.no_info_Screen
	move.l Window_Handle-db(a5),a0		remet le pointeur
	lea WakeUp_Window_Tags(pc),a1
	CALL _IntuitionBase-db(a5),SetWindowPointerA
	rts




*****************************************************************************
*********************                                     *******************
*********************       AFFICHAGE DU ABOUT            *******************
*********************                                     *******************
*****************************************************************************
Display_About
	bsr Save_Screen_Colors

	move.l Window_Handle-db(a5),a0		et un requester !
	lea IFF_EasyRequest(pc),a1
	sub.l a2,a2
	sub.l a3,a3
	CALL _IntuitionBase-db(a5),EasyRequestArgs

	bra Restore_Screen_Colors





*********************************************************************************
***************                                                  ****************
***************           GESTION DE L'ECRAN PRINCIPAL           ****************
***************                                                  ****************
*********************************************************************************
Open_Main_Screen
	move.l #320,d0				alloue une bitmap pour l'écran
	move.l #256,d1
	moveq #2,d2
	moveq #BMF_CLEAR!BMF_DISPLAYABLE!BMF_INTERLEAVED,d3
	sub.l a0,a0
	CALL _GfxBase-db(a5),AllocBitMap
	move.l d0,BitMap_Handle-db(a5)
	move.l d0,Tag_Screen_BitMap-db(a5)
	move.l d0,Tag_Window_BitMap-db(a5)
	beq .error

;	move.l #320,d0				alloue une bitmap pour la fenetre
;	move.l #256,d1
;	move.l #2,d2
;	moveq #BMF_CLEAR!BMF_DISPLAYABLE!BMF_INTERLEAVED,d3
;	sub.l a0,a0
;	CALL AllocBitMap
;	move.l d0,Tag_Window_BitMap-db(a5)
;	beq .error

	sub.l a0,a0				ouvre un écran
	lea OpenScreen_Tags-db(a5),a1
	move.l #DEFAULT_MONITOR_ID!LORES_KEY,Tag_Screen_DisplayID-db(a5)
	clr.w Tag_Screen_Left-db(a5)
	clr.w Tag_Screen_Top-db(a5)
	move.l #Default_ColorTab,Tag_Screen_ColorTab-db(a5)
	move.w #320,Tag_Screen_Width-db(a5)
	move.w #256,Tag_Screen_Height-db(a5)
	move.w #2,Tag_Screen_Depth-db(a5)
	move.w #320,OpenScreen_DClip+ra_MaxX-db(a5)
	move.w #256,OpenScreen_DClip+ra_MaxY-db(a5)
	CALL _IntuitionBase-db(a5),OpenScreenTagList
	move.l d0,Tag_Window_Screen-db(a5)
	move.l d0,Screen_Handle-db(a5)
	beq .error

	sub.l a0,a0				et une fenetre
	lea OpenWindow_Tags-db(a5),a1
	move.w #320,Tag_Window_Width-db(a5)
	move.w #256,Tag_Window_Height-db(a5)
	CALL OpenWindowTagList
	move.l d0,Window_Handle-db(a5)
	beq .error

	tst.b Init_Flag-db(a5)
	bne.s .no_menu
	move.l Window_Handle-db(a5),a0		et hop!! installe les menus
	move.l IFF_MenuStrip-db(a5),a1
	CALL SetMenuStrip
	tst.l d0
	beq .error

.no_menu
	move.l Screen_Handle-db(a5),a0
	lea sc_ViewPort(a0),a0
	lea Default_ColorTab-db(a5),a1
	CALL _GfxBase-db(a5),LoadRGB32

	move.l Window_Handle-db(a5),a0			recherche quelques datas
	move.l wd_RPort(a0),Window_RastPort-db(a5)	sur la fenetre
	move.l wd_UserPort(a0),a0
	move.l a0,Window_UserPort-db(a5)
	moveq #0,d0
	move.b MP_SIGBIT(a0),d1
	bset d1,d0
	move.l d0,Window_WaitMask-db(a5)

	move.l Window_RastPort-db(a5),a1
	moveq #RP_COMPLEMENT,d0
	CALL SetDrMd

* Initialisation des variables du programme
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.l Window_Handle-db(a5),a0
	move.w wd_MouseY(a0),Msg_MouseY-db(a5)
	move.w wd_MouseX(a0),Msg_MouseX-db(a5)

	move.l Tag_Window_Screen-db(a5),Screen_Handle-db(a5)
	move.l Tag_Screen_BitMap-db(a5),BitMap_Handle-db(a5)
	move.l Screen_Handle-db(a5),Tag_ChildScreen_Parent-db(a5)
	move.l Screen_Handle-db(a5),Tag_LoadRequest_Screen-db(a5)
	move.l Screen_Handle-db(a5),Tag_SaveRequest_Screen-db(a5)
	move.l Screen_Handle-db(a5),Tag_ScreenModeRequest_Screen-db(a5)
	move.l #DEFAULT_MONITOR_ID!LORES_KEY,Screen_DisplayID-db(a5)
	move.l Screen_DisplayID-db(a5),Tag_ScreenModeRequest_DisplayID-db(a5)

	move.w #320,Screen_Width-db(a5)
	move.w #256,Screen_Height-db(a5)
	move.w #320,Picture_Width-db(a5)
	move.w #256,Picture_Height-db(a5)
	move.w #2,Screen_Depth-db(a5)
	move.w #4,Screen_Colors-db(a5)

	sf Brush_Flag-db(a5)
	st Target_Flag-db(a5)
	bsr Draw_Target_Grid

	moveq #-1,d0
.error	rts


Close_Main_Screen
	bsr Close_Info_Screen

	move.l Window_Handle-db(a5),d0		vire le menu
	beq.s .no1
	move.l d0,a0
	CALL _IntuitionBase-db(a5),ClearMenuStrip

.no1	move.l Window_Handle-db(a5),d0		ferme la vieille fenetre
	beq.s .no2
	move.l d0,a0
	CALL CloseWindow
	clr.l Window_Handle-db(a5)

.no2	move.l Screen_Handle-db(a5),d0		ferme le vieil ecran
	beq.s .no3
	move.l d0,a0
	CALL CloseScreen
	clr.l Screen_Handle-db(a5)

.no3	move.l Tag_Window_BitMap-db(a5),d0		ferme le vieux bitmap de la fenetre
	beq.s .no4
	move.l d0,a0
	CALL _GfxBase-db(a5),FreeBitMap
	clr.l Tag_Window_BitMap-db(a5)

.no4
;	move.l Tag_Screen_BitMap-db(a5),d0		ferme le vieux bitmap de l'écran
;	beq.s .no5
;	move.l d0,a0
;	CALL _GfxBase-db(a5),FreeBitMap
	clr.l BitMap_Handle-db(a5)

.no5	rts


*********************************************************************************
***************                                                  ****************
***************         GESTION DE L'ECRAN D'INFORMATION         ****************
***************                                                  ****************
*********************************************************************************
Open_Info_Screen
	move.l ChildScreen_Handle-db(a5),d0	ouvre un écran
	bne .exit

	move.w OpenScreen_DClip+ra_MinY-db(a5),OpenChildScreen_DClip+ra_MinY-db(a5)
	move.w OpenScreen_DClip+ra_MaxY-db(a5),OpenChildScreen_DClip+ra_MaxY-db(a5)
	move.w OpenScreen_DClip+ra_MaxY-db(a5),d0

	move.l Screen_Handle-db(a5),Tag_ChildScreen_Parent-db(a5)
	sub.l a0,a0
	lea OpenChildScreen_Tags-db(a5),a1
	CALL _IntuitionBase-db(a5),OpenScreenTagList
	move.l d0,ChildScreen_Handle-db(a5)
	beq .exit
	add.l #sc_RastPort,d0
	move.l d0,ChildScreen_RastPort-db(a5)

	lea InfoText0+17-db(a5),a0
	move.w Picture_Width-db(a5),d0
	moveq #4-1,d1
	bsr Write_Decimal_Number

	lea InfoText1+17-db(a5),a0
	move.w Picture_Height-db(a5),d0
	moveq #4-1,d1
	bsr Write_Decimal_Number

	lea InfoText2+17-db(a5),a0
	move.w Screen_Depth-db(a5),d0
	moveq #1-1,d1
	bsr Write_Decimal_Number

	lea InfoText3+17-db(a5),a0
	move.w Screen_Colors-db(a5),d0
	moveq #3-1,d1
	bsr Write_Decimal_Number

	move.l ChildScreen_RastPort-db(a5),a2
	move.l a2,a1
	moveq #1,d0
	moveq #0,d1
	moveq #RP_JAM2,d2
	CALL _GfxBase-db(a5),SetABPenDrMd

	move.l a2,a1
	moveq #20,d0
	moveq #10,d1
	CALL _GfxBase-db(a5),Move
	lea InfoText0-db(a5),a0
	move.l a2,a1
	moveq #InfoText0_SIZE,d0
	CALL Text

	move.l a2,a1
	moveq #20,d0
	moveq #20,d1
	CALL Move
	lea InfoText1-db(a5),a0
	move.l a2,a1
	moveq #InfoText1_SIZE,d0
	CALL Text

	move.l a2,a1
	moveq #20,d0
	moveq #30,d1
	CALL Move
	lea InfoText2-db(a5),a0
	move.l a2,a1
	moveq #InfoText2_SIZE,d0
	CALL Text

	move.l a2,a1
	moveq #20,d0
	moveq #40,d1
	CALL Move
	lea InfoText3-db(a5),a0
	move.l a2,a1
	moveq #InfoText3_SIZE,d0
	CALL Text

	bsr Display_Mouse_Info

	moveq #-1,d0
.exit	rts

Close_Info_Screen
	move.l ChildScreen_Handle-db(a5),d0	ferme l'écran
	beq.s .exit
	move.l d0,a0
	CALL _IntuitionBase-db(a5),CloseScreen
	clr.l ChildScreen_Handle-db(a5)
.exit	rts



* Conversion d'un nombre en décimal de gauche à droite
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*  -->	d0=nb
*	d1=nb de digit-1
*	a0=string
Write_Decimal_Number
	ext.l d0
	move.l a0,a1				efface d'abord
	move.w d1,d2
	moveq #" ",d3
.clear	move.b d3,(a1)+
	dbf d2,.clear

	lea tab_rang-db(a5),a1
	move.l d1,d2
	add.w d2,d2				\ table de LONG
	add.w d2,d2				/
	sub.l d2,a1
	sf d3
rang	move.l (a1)+,d4
	moveq.l #$d0,d2
soust	sub.l d4,d0
	dbmi d2,soust
	cmp.b #-"0",d2
	bne.s .write
	tst.w d1
	beq.s .write
	tst.b d3
	beq.s .skip
.write	st d3
	neg.b d2
	move.b d2,(a0)+
.skip	add.l d4,d0
	dbf d1,rang
	rts
	
	dc.l 1000000000
	dc.l 100000000
	dc.l 10000000
	dc.l 1000000
	dc.l 100000
	dc.l 10000
	dc.l 1000
	dc.l 100
	dc.l 10
tab_rang
	dc.l 1


	
* Toutes les datas
* ~~~~~~~~~~~~~~~~
	CNOP 0,4
db:
_ExecBase		dc.l 0
_AslBase		dc.l 0
_GadToolsBase		dc.l 0
_IntuitionBase		dc.l 0
_GfxBase		dc.l 0
_IFFParseBase		dc.l 0
_DosBase		dc.l 0
IFF_Handle		dc.l 0
File_Handle		dc.l 0
Load_Request		dc.l 0
Save_Request		dc.l 0
ScreenMode_Request	dc.l 0

CMAP_Chunk		dc.l 0
BMHD_Chunk		dc.l 0
CAMG_Chunk		dc.l 0
BODY_Chunk		dc.l 0
Mem_Size		dc.l 0
Mem_Adr			dc.l 0

Screen_Handle		dc.l 0
Screen_VisualInfo	dc.l 0
Window_Handle		dc.l 0
BitMap_Handle		dc.l 0
Window_WaitMask		dc.l 0
Window_RastPort		dc.l 0
Window_UserPort		dc.l 0

ChildScreen_Handle	dc.l 0
ChildScreen_RastPort	dc.l 0

IFF_MenuStrip		dc.l 0
Msg_Class		dc.l 0
Msg_IAddress		dc.l 0
Msg_Code		dc.w 0
Msg_Qualifier		dc.w 0
Msg_MouseY		dc.w 0
Msg_MouseX		dc.w 0

Screen_DimensionInfo	dcb.b dim_SIZEOF
Screen_Width		dc.w 320
Screen_Height		dc.w 256-MENU_SIZE
Screen_Depth		dc.w 2
Screen_Colors		dc.w 4
Screen_DisplayID	dc.l 0

Picture_Width		dc.w 320
Picture_Height		dc.w 256-MENU_SIZE

Error_Count		dc.w 0

Old_MouseY		dc.w 0
Old_MouseX		dc.w 0

Grid_Top		dc.w 0
Grid_Left		dc.w 0
Grid_Bottom		dc.w 0
Grid_Right		dc.w 0
Grid_Spacing		dc.w 16

Brush_Top		dc.w 0
Brush_Left		dc.w 0
Brush_Bottom		dc.w 0
Brush_Right		dc.w 0

Save_Method		dc.w 0
Save_Top		dc.w 0
Save_Left		dc.w 0
Save_Bottom		dc.w 0
Save_Right		dc.w 0

Buffer_Pos		dc.w 0

Crunch_Mode		dc.b 0
Brush_Flag		dc.b 0
Target_Flag		dc.b 0
Info_Flag		dc.b 0
Init_Flag		dc.b $ff
			even

* Tags pour endormir/reveiller le pointeur d'une fenetre
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Sleep_Window_Tags
	dc.l WA_BusyPointer,TAG_TRUE
	dc.l TAG_DONE

WakeUp_Window_Tags
	dc.l WA_BusyPointer,TAG_FALSE
	dc.l TAG_DONE

* Tags pour scanner un fichier IFF
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
PropChunks_Tags
	dc.l ID_ILBM,ID_CMAP
	dc.l ID_ILBM,ID_BMHD
	dc.l ID_ILBM,ID_CAMG

* Tags pour l'ouverture d'un ecran
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
OpenScreen_Tags
Tag_Screen_BitMap=*+4
	dc.l SA_BitMap,0
Tag_Screen_DisplayID=*+4
	dc.l SA_DisplayID,0
Tag_Screen_Left=*+6
	dc.l SA_Left,0
Tag_Screen_Top=*+6
	dc.l SA_Top,0
Tag_Screen_Width=*+6
	dc.l SA_Width,0
Tag_Screen_Height=*+6
	dc.l SA_Height,0
Tag_Screen_Depth=*+6
	dc.l SA_Depth,0
	dc.l SA_Font,ScreenFont
Tag_Screen_ColorTab=*+4
	dc.l SA_Colors32,0
	dc.l SA_Pens,ScreenPens
	dc.l SA_AutoScroll,TAG_TRUE
	dc.l SA_DClip,OpenScreen_DClip
	dc.l SA_Title,ScreenTitle
	dc.l TAG_DONE

OpenScreen_DClip
	dc.w 0,0
	dc.w 0,0

ScreenPens
	dc.w ~0

ScreenFont
	dc.l TopazName
	dc.w 8
	dc.b FS_NORMAL
	dc.b FPF_ROMFONT

ColorTab
	dc.w 4,0
	dc.l $aaaaaaaa,$aaaaaaaa,$aaaaaaaa
	dc.l $00000000,$00000000,$00000000
	dc.l $ffffffff,$ffffffff,$ffffffff
	dc.l $66666666,$88888888,$bbbbbbbb
	dc.l 0
	dcb.l 252*3

Default_ColorTab
	dc.w 4,0
	dc.l $aaaaaaaa,$aaaaaaaa,$aaaaaaaa
	dc.l $00000000,$00000000,$00000000
	dc.l $ffffffff,$ffffffff,$ffffffff
	dc.l $66666666,$88888888,$bbbbbbbb
	dc.l 0

Save_ColorTab
	dc.w 0,0
	dc.l 0,0,0,0
	dc.l 0,0,0,0
	dc.l 0,0,0,0
	dc.l 0,0,0,0
	dc.l 0

OpenWindow_Tags
	dc.l WA_Left,0
	dc.l WA_Top,0
Tag_Window_Width=*+6
	dc.l WA_Width,0
Tag_Window_Height=*+6
	dc.l WA_Height,0
Tag_Window_Screen=*+4
	dc.l WA_CustomScreen,0
Tag_Window_BitMap=*+4
	dc.l WA_SuperBitMap,0
	dc.l WA_Flags,WFLG_BACKDROP!WFLG_BORDERLESS!WFLG_ACTIVATE!WFLG_REPORTMOUSE!WFLG_NEWLOOKMENUS!WFLG_SUPER_BITMAP
	dc.l WA_IDCMP,IDCMP_MOUSEMOVE!IDCMP_MOUSEBUTTONS!IDCMP_RAWKEY!IDCMP_MENUPICK!IDCMP_MENUVERIFY!IDCMP_INTUITICKS
	dc.l TAG_DONE	
Tag_Window
	dc.l 0

OpenChildScreen_Tags
Tag_ChildScreen_Parent=*+4
	dc.l SA_Parent,0
	dc.l SA_DisplayID,DEFAULT_MONITOR_ID|HIRES_KEY
	dc.l SA_Top,220
	dc.l SA_Depth,1
	dc.l SA_Width,640
	dc.l SA_Height,45
	dc.l SA_Colors32,ChildScreenColors
	dc.l SA_Pens,ScreenPens
	dc.l SA_Font,ScreenFont
	dc.l SA_DClip,OpenChildScreen_DClip
	dc.l SA_Title,ChildScreenTitle
	dc.l SA_Quiet,TAG_TRUE
	dc.l TAG_DONE

OpenChildScreen_DClip
	dc.w 0,0
	dc.w 639,0

ChildScreenColors
	dc.w 2,0
	dc.l $ffffffff,$ffffffff,$ffffffff
	dc.l $00000000,$00000000,$00000000
	dc.l 0

LoadRequest_Tags
Tag_LoadRequest_Screen=*+4
	dc.l ASLFR_Screen,0
Tag_LoadRequest_LeftEdge=*+4
	dc.l ASLFR_InitialLeftEdge,0
Tag_LoadRequest_TopEdge=*+4
	dc.l ASLFR_InitialTopEdge,0
	dc.l ASLFR_InitialWidth,320
	dc.l ASLFR_InitialHeight,256-MENU_SIZE
	dc.l ASLFR_DoPatterns,TAG_TRUE
	dc.l TAG_DONE

SaveRequest_Tags
Tag_SaveRequest_Screen=*+4
	dc.l ASLFR_Screen,0
Tag_SaveRequest_LeftEdge=*+4
	dc.l ASLFR_InitialLeftEdge,0
Tag_SaveRequest_TopEdge=*+4
	dc.l ASLFR_InitialTopEdge,0
	dc.l ASLFR_InitialWidth,320
	dc.l ASLFR_InitialHeight,256-MENU_SIZE
	dc.l ASLFR_DoSaveMode,TAG_TRUE
	dc.l ASLFR_DoPatterns,TAG_TRUE
	dc.l TAG_DONE

ScreenModeRequest_Tags
Tag_ScreenModeRequest_Screen=*+4
	dc.l ASLSM_Screen,0
Tag_ScreenModeRequest_DisplayID=*+4
	dc.l ASLSM_InitialDisplayID,0
	dc.l ASLSM_InitialLeftEdge,0
	dc.l ASLSM_InitialTopEdge,MENU_SIZE
	dc.l ASLSM_InitialWidth,320
	dc.l ASLSM_InitialHeight,256-MENU_SIZE
	dc.l TAG_DONE

IFF_Menus_Tags
	dc.l GTMN_NewLookMenus,TAG_TRUE
	dc.l TAG_DONE

IFF_Menus
	dc.b NM_TITLE,0
	dc.l ProjectStr,0
	dc.w 0
	dc.l 0,0

	dc.b NM_ITEM,0
	dc.l LoadStr,LoadKey
	dc.w 0
	dc.l 0,Load_New_Picture

	dc.b NM_ITEM,0
	dc.l NM_BARLABEL,0
	dc.w 0
	dc.l 0,0

	dc.b NM_ITEM,0
	dc.l SavePicStr,0
	dc.w 0
	dc.l 0,0
	
	dc.b NM_SUB,0
	dc.l RawNormalPicStr,0
	dc.w 0
	dc.l 0,Init_Save_Raw_Normal_Picture

	dc.b NM_SUB,0
	dc.l RawInterleavedPicStr,0
	dc.w 0
	dc.l 0,Init_Save_Raw_Interleaved_Picture

	dc.b NM_SUB,0
	dc.l Chunky8PicStr,0
	dc.w 0
	dc.l 0,Init_Save_Chunky8_Picture

	dc.b NM_SUB,0
	dc.l Chunky16PicStr,0
	dc.w NM_ITEMDISABLED
	dc.l 0,0

	dc.b NM_SUB,0
	dc.l Chunky24PicStr,0
	dc.w NM_ITEMDISABLED
	dc.l 0,0

	dc.b NM_ITEM,0
	dc.l SaveBrushStr,0
	dc.w 0
	dc.l 0,0
	
	dc.b NM_SUB,0
	dc.l RawNormalBrushStr,0
	dc.w 0
	dc.l 0,Init_Save_Raw_Normal_Brush

	dc.b NM_SUB,0
	dc.l RawInterleavedBrushStr,0
	dc.w 0
	dc.l 0,Init_Save_Raw_Interleaved_Brush

	dc.b NM_SUB,0
	dc.l Chunky8BrushStr,0
	dc.w 0
	dc.l 0,Init_Save_Chunky8_Brush

	dc.b NM_SUB,0
	dc.l Chunky16BrushStr,0
	dc.w NM_ITEMDISABLED
	dc.l 0,0

	dc.b NM_SUB,0
	dc.l Chunky24BrushStr,0
	dc.w NM_ITEMDISABLED
	dc.l 0,0

	dc.b NM_ITEM,0
	dc.l SavePaletteStr,0
	dc.w 0
	dc.l 0,0

	dc.b NM_SUB,0
	dc.l Palette12Str,0
	dc.w 0
	dc.l 0,Save_Palette12

	dc.b NM_SUB,0
	dc.l Palette24Str,0
	dc.w 0
	dc.l 0,Save_Palette24

	dc.b NM_SUB,0
	dc.l Palette24IStr,0
	dc.w 0
	dc.l 0,Save_Palette24_Interlaced

	dc.b NM_ITEM,0
	dc.l NM_BARLABEL,0
	dc.w 0
	dc.l 0,0

	dc.b NM_ITEM,0
	dc.l AboutStr,0
	dc.w 0
	dc.l 0,Display_About

	dc.b NM_ITEM,0
	dc.l NM_BARLABEL,0
	dc.w 0
	dc.l 0,0

	dc.b NM_ITEM,0
	dc.l ExitStr,ExitKey
	dc.w 0
	dc.l 0,iff_exit_menu

	dc.b NM_TITLE
	dc.l ToolBoxStr,0
	dc.w 0
	dc.l 0,0

	dc.b NM_ITEM,0
	dc.l FreeBrushStr,FreeBrushKey
	dc.w 0
	dc.l 0,Free_Brush

	dc.b NM_ITEM,0
	dc.l FlipInfoStr,0
	dc.w 0
	dc.l 0,Flip_Info_Screen

	dc.b NM_ITEM,0
	dc.l ChangeResStr,ChangeResKey
	dc.w NM_ITEMDISABLED
	dc.l 0,Change_Resolution

	dc.b NM_END,0
	dc.l 0,0
	dc.w 0
	dc.l 0,0

IFF_EasyRequest
	dc.l es_SIZEOF
	dc.l 0
	dc.l EasyRequest_RequestName
EasyRequest_TextFormat
	dc.l Request_Welcome
	dc.l EasyRequest_GadFormat

IFF_EasyRequest_Args
	dc.l 0

Init_ErrorList
	dc.l Request_OpenAsl
	dc.l Request_AllocAsl
	dc.l Request_AllocAsl
	dc.l Request_AllocAsl
	dc.l Request_OpenGadTools
	dc.l Request_OpenGraphics
	dc.l Request_OpenIFFParse
	dc.l Request_AllocIFF
	dc.l Request_OpenDos
	dc.l Request_OpenScreen
	dc.l Request_GetVisualInfo
	dc.l Request_CreateMenuA
	dc.l Request_LayoutMenuA
	dc.l Request_SetMenuStrip

Load_ErrorList
	dc.l Request_AddPart
	dc.l Request_Open
	dc.l Request_OpenIFF
	dc.l Request_NotIFF
	dc.l Request_DisplayInfo
	dc.l Request_GetDisplay
	dc.l Request_NoMemory
	dc.l Request_OpenScreen
	dc.l Request_OpenWindow
	dc.l Request_SetMenuStrip
	dc.l Request_NoMemory
	dc.l Request_Load
	dc.l Request_Decrunch

* Buffer pour l'écriture des fichiers
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Buffer
	dcb.b BUFFER_SIZE,0

* Buffer pour la création des path + filename avec AddPart()
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
RealFileName
	dcb.b REALFILENAME_SIZE,0

* Des chaines de charactères
* ~~~~~~~~~~~~~~~~~~~~~~~~~~
AslName			dc.b "asl.library",0
GadToolsName		dc.b "gadtools.library",0
IntuitionName		dc.b "intuition.library",0
GfxName			dc.b "graphics.library",0
IFFName			dc.b "iffparse.library",0
DosName			dc.b "dos.library",0
TopazName		dc.b "topaz.font",0
EasyRequest_RequestName	dc.b "IFF-Converter Request",0
EasyRequest_GadFormat	dc.b "Meuh!",0
ScreenTitle		dc.b "IFF-Converter v1.0.30",0
ChildScreenTitle	dc.b "IFF-Converter Control Screen",0

Request_Welcome		dc.b "IFF-Converter v1.0.30",10
			dc.b "©1993-1995 Sync/DreamDealers",10
			dc.b 10
			dc.b "Have Fun With It !",0

Request_InitErrorFormat	dc.b "Init Error: %s",0
Request_OpenAsl		dc.b "Can't Open asl.library",0
Request_AllocAsl	dc.b "Can't AllocAslRequest()",0
Request_OpenGadTools	dc.b "Can't Open gadtools.library",0
Request_OpenGraphics	dc.b "Can't Open graphics.library",0
Request_OpenIFFParse	dc.b "Can't Open IFFParse.library",0
Request_AllocIFF	dc.b "Can't AllocIFF()",0
Request_OpenDos		dc.b "Can't Open dos.library",0
Request_OpenScreen	dc.b "Can't OpenScreen()",0
Request_GetVisualInfo	dc.b "Can't GetVisualInfoA()",0
Request_CreateMenuA	dc.b "Can't CreateMenuA",0
Request_LayoutMenuA	dc.b "Can't LayoutMenuA",0
Request_SetMenuStrip	dc.b "Can't SetMenuStrip()",0

Request_LoadErrorFormat	dc.b "Loading Error: %s",0
Request_AddPart
Request_Open
Request_OpenIFF		dc.b "Can't Open Input File",0
Request_NotIFF		dc.b "Not An IFF File",0
Request_DisplayInfo
Request_GetDisplay	dc.b "Unknown Display Mode",0
Request_NoMemory	dc.b "Not Enough Memory",0
Request_OpenWindow	dc.b "Can't OpenWindow()",0
Request_Load		dc.b "Can't Read() File",0
Request_Decrunch	dc.b "Unknown IFF-Crunch Mode",0

InfoText0		dc.b "Picture Width....xxxx        MouseX.........xxxx        Brush Width....xxxx"
InfoText0_SIZE=*-InfoText0
InfoText1		dc.b "Picture Height...xxxx        MouseY.........xxxx        Brush SizeX....xxxx"
InfoText1_SIZE=*-InfoText1
InfoText2		dc.b "Bitplans.........x           Pixel Color....xxx         Brush Height...xxxx"
InfoText2_SIZE=*-InfoText2 
InfoText3		dc.b "Colors...........xxx         Grid Spacing...xxxx"
InfoText3_SIZE=*-InfoText3

ProjectStr		dc.b "Project",0

LoadStr			dc.b "Load Picture...",0
LoadKey			dc.b "L",0

SavePicStr		dc.b "Save Picture",0
RawNormalPicStr		dc.b "as Raw",0
RawInterleavedPicStr	dc.b "as Raw Interleaved",0
Chunky8PicStr		dc.b "as 8 Bits Chunky",0
Chunky16PicStr		dc.b "as 16 Bits Chunky",0
Chunky24PicStr		dc.b "as 24 Bits Chunky",0

SaveBrushStr		dc.b "Save Brush",0
RawNormalBrushStr	dc.b "As Raw",0
RawInterleavedBrushStr	dc.b "As Raw Interleaved",0
Chunky8BrushStr		dc.b "as 8 Bits Chunky",0
Chunky16BrushStr	dc.b "as 16 Bits Chunky",0
Chunky24BrushStr	dc.b "as 24 Bits Chunky",0

SavePaletteStr		dc.b "Save Palette",0
Palette12Str		dc.b "As RAW 12 Bits",0
Palette24Str		dc.b "As RAW 24 Bits",0
Palette24IStr		dc.b "As RAW 24 Bits Interlaced",0

AboutStr		dc.b "About",0

ExitStr			dc.b "Exit",0
ExitKey			dc.b "Q",0

ToolBoxStr		dc.b "ToolBox",0

FreeBrushStr		dc.b "Free Brush",0
FreeBrushKey		dc.b "F",0

FlipInfoStr		dc.b "Toggle InfoScreen",0

ChangeResStr		dc.b "Change Resolution",0
ChangeResKey		dc.b "C",0
