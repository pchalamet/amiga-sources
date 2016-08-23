
*				AutoSwitch Amiga/Picasso
*				~~~~~~~~~~~~~~~~~~~~~~~~






* Les options de compilation
* ~~~~~~~~~~~~~~~~~~~~~~~~~~
	OPT O+,OW-
	OPT NODEBUG,NOLINE




* les includes habituels...
* ~~~~~~~~~~~~~~~~~~~~~~~~~
	incdir "include:"
	include "exec/exec_lib.i"
	include "exec/interrupts.i"
	include "dos/dos.i"
	include "libraries/vilintuisup_lib.i"
	include "hardware/custom.i"
	include "hardware/intbits.i"
	include "misc/macros.i"




* Le point d'entrée du programme
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	section ben_euh,code

Main
	lea data_base,a5
	move.l (_SysBase).w,a6
	move.l a6,_ExecBase(a5)			c'est plus rapide en fast !!

	lea VilIntuiSupName(pc),a1		ouvre la vilintuisup.library
	moveq #2,d0
	CALL OpenLibrary
	move.l d0,_VilIntuiBase(a5)
	beq.s .no_vilintuisup

	lea VillageName(pc),a1			ouvre la village.library
	moveq #0,d0
	CALL OpenLibrary
	move.l d0,_VillageBase(a5)
	beq.s .no_village


	lea VblIntStruct(pc),a1			ajoute un server VBL
	moveq #INTB_VERTB,d0
	CALL AddIntServer

	move.l #SIGBREAKF_CTRL_C,d0		attend que ca se passe...
	CALL Wait

	lea VblIntStruct(pc),a1			enlève la vbl
	moveq #INTB_VERTB,d0
	CALL RemIntServer

	move.l _VillageBase(a5),a1		ferme la village.library
	CALL CloseLibrary
.no_village
	move.l _VilIntuiBase(a5),a1		ferme la vilintuisup.library
	CALL CloseLibrary
.no_vilintuisup
	moveq #RETURN_OK,d0
	rts




* La routine a éxécuter pendant la vbl
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*  -->	a1=data_base
SwitchVbl
	move.l _VillageBase(a1),a1		c'est koi le type d'écran ?
	btst #4,$22(a1)
	beq.s .no_amiga
	btst #8,d0
	beq.s .no_amiga
	move.w #$8180,_Custom+dmaconr
	moveq #0,d0
	rts
.no_amiga
	move.w #$0180,_Custom+dmacon
	moveq #0,d0
	rts



* Quelques constantes du programme
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
VblIntStruct
	dcb.l 2,0		ln_succ & ln_pred	
	dc.b NT_INTERRUPT	ln_type
	dc.b 127		ln_pri
	dc.l 0			ln_name
	dc.l data_base		is_data
	dc.l SwitchVbl		is_code

VilIntuiSupName
	dc.b "vilintuisup.library",0
VillageName
	dc.b "village.library",0




* Les datas du programme
* ~~~~~~~~~~~~~~~~~~~~~~
	section mes_datas,bss
	rsreset
DataBase	rs.b 0
_ExecBase	rs.l 1
_VilIntuiBase	rs.l 1
_VillageBase	rs.l 1
DataBase_SIZEOF	rs.b 0


data_base
	ds.b DataBase_SIZEOF
