
*------------------------------------*
* Registres hardware du Chip Set AGA *
*------------------------------------*
_CustomBase=$dff000
bltddat=$000
dmaconr=$002
vposr=$004
vhposr=$006
dskdatr=$008
joy0dat=$00a
joy1dat=$00c
clxdat=$00e
adkconr=$010
pot0dat=$012
pot1dat=$014
potinp=$016
serdatr=$018
dskbytr=$01a
intenar=$01c
intreqr=$01e
dskpt=$020
dsklen=$024
dskdat=$026
refptr=$028
vposw=$02a
vhposw=$02c
copcon=$02e
serdat=$030
serper=$032
potgo=$034
joytest=$036
strequ=$038
strvbl=$03a
strhor=$03c
strlong=$03e
bltcon0=$040
bltcon1=$042
bltafwm=$044
bltalwm=$046
bltcpt=$048
bltbpt=$04c
bltapt=$050
bltdpt=$054
bltsize=$058
bltcon0l=$05b				byte access only
bltsizV=$05c
bltsizH=$05e
bltcmod=$060
bltbmod=$062
bltamod=$064
bltdmod=$066
bltcdat=$070
bltbdat=$072
bltadat=$074
deniseid=$07c				$f8=chip aga
dsksync=$07e
cop1lc=$080
cop2lc=$084
copjmp1=$088
copjmp2=$08a
copins=$08c
diwstrt=$08e
diwstop=$090
ddfstrt=$092
ddfstop=$094
dmacon=$096
clxcon=$098
intena=$09a
intreq=$09c
adkcon=$09e
aud0lcH=$0a0
aud0lcL=$0a2
aud0len=$0a4
aud0per=$0a6
aud0vol=$0a8
aud0dat=$0aa
aud1lcH=$0b0
aud1lcL=$0b2
aud1len=$0b4
aud1per=$0b6
aud1vol=$0b8
aud1dat=$0ba
aud2lcH=$0c0
aud2lcL=$0c2
aud2len=$0c4
aud2per=$0c6
aud2vol=$0c8
aud2dat=$0ca
aud3lcH=$0d0
aud3lcL=$0d2
aud3len=$0d4
aud3per=$0d6
aud3vol=$0d8
aud3dat=$0da
bpl1ptH=$e0
bpl1ptL=$e2
bpl2ptH=$e4
bpl2ptL=$e6
bpl3ptH=$e8
bpl3ptL=$ea
bpl4ptH=$ec
bpl4ptL=$ee
bpl5ptH=$f0
bpl5ptL=$f2
bpl6ptH=$f4
bpl6ptL=$f6
bpl7ptH=$f8
bpl7ptL=$fa
bpl8ptH=$fc
bpl8ptL=$fe
bplcon0=$100
bplcon1=$102
bplcon2=$104
bplcon3=$106
bpl1mod=$108
bpl2mod=$10a
bplcon4=$10c
clxcon2=$10e
bpl1dat=$110
bpl2dat=$112
bpl3dat=$114
bpl4dat=$116
bpl5dat=$118
bpl6dat=$11a
bpl7dat=$11c
bpl8dat=$11e
spr0ptH=$120
spr0ptL=$122
spr1ptH=$124
spr1ptL=$126
spr2ptH=$128
spr2ptL=$12a
spr3ptH=$12c
spr3ptL=$12e
spr4ptH=$130
spr4ptL=$132
spr5ptH=$134
spr5ptL=$136
spr6ptH=$138
spr6ptL=$13a
spr7ptH=$13c
spr7ptL=$13e
spr0pos=$140
spr0ctl=$142
spr0data=$144
spr0datb=$146
spr1pos=$148
spr1ctl=$14a
spr1data=$14c
spr1datb=$14e
spr2pos=$150
spr2ctl=$152
spr2data=$154
spr2datb=$156
spr3pos=$158
spr3ctl=$15a
spr3data=$15c
spr3datb=$15e
spr4pos=$160
spr4ctl=$162
spr4data=$164
spr4datb=$166
spr5pos=$168
spr5ctl=$16a
spr5data=$16c
spr5datb=$16e
spr6pos=$170
spr6ctl=$172
spr6data=$174
spr6datb=$176
spr7pos=$178
spr7ctl=$17a
spr7data=$17c
spr7datb=$17e
color00=$180
color01=$182
color02=$184
color03=$186
color04=$188
color05=$18a
color06=$18c
color07=$18e
color08=$190
color09=$192
color10=$194
color11=$196
color12=$198
color13=$19a
color14=$19c
color15=$19e
color16=$1a0
color17=$1a2
color18=$1a4
color19=$1a6
color20=$1a8
color21=$1aa
color22=$1ac
color23=$1ae
color24=$1b0
color25=$1b2
color26=$1b4
color27=$1b6
color28=$1b8
color29=$1ba
color30=$1bc
color31=$1be
htotal=$1c0
hsstop=$1c2
hbstrt=$1c4
hbstop=$1c6
vtotal=$1c8
vsstop=$1ca
vbstrt=$1cc
vbstop=$1ce
sprhstrt=$1d0
sprhstop=$1d2
bplhstrt=$1d4
bplhstop=$1d6
hhposw=$1d8
hhposr=$1da
beamcon0=$1dc
hsstrt=$1de
vsstrt=$1e0
hcenter=$1e2
diwhigh=$1e4
fmode=$1fc

*--------------------*
* Registres du CIA-A *
*--------------------*
ciaapra=$bfe001
ciaaprb=$bfe101
ciaaddra=$bfe201
ciaaddrb=$bfe301
ciaatalo=$bfe401
ciaatahi=$bfe501
ciaatblo=$bfe601
ciaatbhi=$bfe701
ciaatodlow=$bfe801
ciaatodmid=$bfe901
ciaatodhi=$bfea01
ciaasdr=$bfec01
ciaaicr=$bfed01
ciaacra=$bfee01
ciaacrb=$bfef01

*--------------------*
* Registres du CIA-B *
*--------------------*
ciabpra=$bfd000
ciabprb=$bfd100
ciabddra=$bfd200
ciabddrb=$bfd300
ciabtalo=$bfd400
ciabtahi=$bfd500
ciabtblo=$bfd600
ciabtbhi=$bfd700
ciabtodlow=$bfd800
ciabtodmid=$bfd900
ciabtodhi=$bfda00
ciabsdr=$bfdc00
ciabicr=$bfdd00
ciabcra=$bfde00
ciabcrb=$bfdf00

*---------------------------*
* Offsets de l'exec.library *
*---------------------------*
_ExecBase=4
SetTaskPri=-300
Forbid=-132
Permit=-138
OpenLibrary=-552
CloseLibrary=-414
AllocMem=-198
FreeMem =-210
RawDoFmt=-522
WaitPort=-384
GetMsg=-372
ReplyMsg=-378
PUBLIC=1
CHIP=2
FAST=4
CLEAR=$10000

ThisTask=10
pr_CLI=$ac
pr_MsgPort=$5c

*---------------------------*
* Offsets de la dos.library *
*---------------------------*
Open=-30
Close=-36
Read=-42
Write=-48
Input=-54
Output=-60
Seek=-66
Lock=-84
Unlock=-90
Examine=-102
LoadSeg=-150
Execute=-222

*--------------------------------*
* Offsets de la graphics.library *
*--------------------------------*
WaitTof=-270
OwnBlitter=-456
DisownBlitter=-462
WaitBlit=-228
LoadView=-222

*-------------------------------*
* Offsets de la village.library *
*-------------------------------*
SetAmigaDisplay=-192
SetPicassoDisplay=-198

*-------------*
* EQU debiles *
*-------------*
ON=1
OFF=0

*--------*
* Macros *
*--------*
* KILL_SYSTEM <Supervisor Routine>,DELAY
KILL_SYSTEM	macro
Kill_System
	IFEQ (NARG=1)|(NARG=2)			parametres obligatoires !!
	FAIL Missing parameters !!!
	ENDC
	bra.s .Skip
	dc.b "$VER: ©1995 Sync of DreamDealers"
.GfxName
	dc.b "graphics.library",0
;.VillageName
;	dc.b "village.library",0
	CNOP 0,4

.Skip
	move.l (_ExecBase).w,a6
	move.l ThisTask(a6),a3

	tst.l pr_CLI(a3)
	bne.s .from_CLI
.from_WB
	lea pr_MsgPort(a3),a0
	move.l a0,a2
	CALL WaitPort
	move.l a2,a0
	CALL GetMsg
	move.l d0,-(sp)
	bsr.s .from_CLI
	move.l d0,d7
	CALL (_ExecBase).w,Forbid
	move.l (sp)+,d0
	CALL ReplyMsg
	move.l d7,d0
	rts

.from_CLI
;	move.l a3,a1				baisse notre priorité...
;	moveq #-128,d0
;	CALL SetTaskPri
;
;	lea .VillageName(pc),a1			ouvre la village.library si présente
;	moveq #0,d0
;	CALL (_ExecBase).w,OpenLibrary
;	move.l d0,-(sp)
;	move.l d0,-(sp)
;	beq.s .no_village
;
;	move.l d0,a6
;	btst #4,$22(a6)				display flags de la picasso
;	seq 3(sp)
;	CALL SetAmigaDisplay			passe en mode AMIGA

.no_village
	lea .GfxName(pc),a1			ouvre la graphics.library
	moveq #0,d0
	CALL (_ExecBase).w,OpenLibrary
	tst.l d0				on l'a vraiment eut cette
	bne.s .Gfx				library ?
	moveq #5,d0				on sort avec une erreur
	rts
.Gfx
	move.l d0,a6

	IFNE NARG=2				ya un 2ème parametre ?
	IFNE \2					c'est egal à 0 ?
	move.l #\2-1,d7				non => execute le DELAY
.delay	CALL WaitTof
	dbf d7,.delay
	ENDC
	ELSEIF
	moveq #2*50-1,d7			pas de 2ème parametre => 2 sec
.delay	CALL WaitTof				d'attente
	dbf d7,.delay
	ENDC

	CALL OwnBlitter				monopolise le blitter
	CALL WaitBlit

	lea _CustomBase,a5			sauve intena/dmacon
	move.w intenar(a5),-(sp)
	or.w #$c000,(sp)
	move.l #$7fff7fff,intena(a5)
	move.w dmaconr(a5),-(sp)
	or.w #$8200,(sp)
	move.w #$7fff,dmacon(a5)
	move.w adkconr(a5),-(sp)		sauve adkcon
	or.w #$8000,(sp)

	move.w potinp(a5),-(sp)			configure les ports comme ils
	move.w #$ff00,potgo(a5)			devraient l'être
	move.b ciaapra,-(sp)
	move.b ciaaddra,-(sp)
	move.b #$3,ciaaddra

	move.l $68.w,-(sp)			sauve quelques vecteurs
	move.l $6c.w,-(sp)
	move.l $78.w,-(sp)
	move.l $80.w,-(sp)

	lea spr0pos(a5),a0			vire les sprites
	moveq #16-1,d0
.clear	clr.l (a0)+
	dbf d0,.clear

	movem.l a5/a6,-(sp)			saute à la routine passée comme
	lea \1(pc),a0				paramètre de KILL_SYSTEM
	move.l a0,$80.w
	trap #0					passage en mode superviseur

	movem.l (sp)+,a5/a6

	move.w #$7fff,dmacon(a5)
	move.l #$7fff7fff,intena(a5)

	CALL WaitBlit				libère le blitter
	CALL DisownBlitter

	move.l (sp)+,$80.w			remet tout comme c'était avant
	move.l (sp)+,$78.w
	move.l (sp)+,$6c.w
	move.l (sp)+,$68.w

	move.b (sp)+,ciaaddra
	move.b (sp)+,ciaapra
	move.w (sp)+,potgo(a5)

	move.w (sp)+,adkcon(a5)
	move.w (sp)+,dmacon(a5)
	move.w (sp)+,intena(a5)

	move.l $26(a6),cop1lc(a5)		remet les coplists
	move.l $32(a6),cop2lc(a5)
	clr.w copjmp1(a5)

	move.l a6,a1				ferme la graphics.library
	CALL (_ExecBase).w,CloseLibrary

;	move.l (sp)+,d0				display flag + villagebase
;	move.l (sp)+,d1
;	beq.s .no_picasso
;	move.l d1,a6
;	tst.b d0
;	beq.s .no_restore_picasso
;	CALL SetPicassoDisplay			passe en mode PICASSO
;.no_restore_picasso
;	move.l a6,a1				ferme la village.library
;	CALL (_ExecBase).w,CloseLibrary
;.no_picasso
	endm

RESTORE_SYSTEM	macro
	rte
	endm

WAIT_BLITTER	macro
.wait_blitter\@
	btst #6,dmaconr(a6)
	bne.s .wait_blitter\@
	endm

WAIT_VHSPOS	macro
.wait_beam\@
	move.l vposr(a6),d0
	and.l #$1ff00,d0
	IFEQ NARG
	cmp.l #$12700,d0
	ELSEIF
	cmp.l #\1,d0
	ENDC
	bne.s .wait_beam\@
	endm

CALL	macro
	IFNE NARG=2
	move.l \1,a6
	jsr \2(a6)
	ELSEIF
	jsr \1(a6)
	ENDC
	endm

WAIT_LMB_DOWN	macro
.lmb_down\@
	btst #6,ciaapra
	bne.s .lmb_down\@
	endm

WAIT_LMB_UP	macro
.lmb_up\@
	btst #6,ciaapra
	beq.s .lmb_up\@
	endm

WAIT_RMB_DOWN	macro
.rmb_down\@
	btst #2,potinp(a6)
	bne.s .rmb_down\@
	endm

WAIT_RMB_UP	macro
.rmb_up\@
	btst #2,potinp(a6)
	beq.s .rmb_up\@
	endm

VBL_SIZE	macro
	btst #2,potinp(a6)
	bne.s .no_color\@
	clr.w bplcon3(a6)
	move.w #\2,\1(a6)
.no_color\@
	endm

SAVE_REGS	macro
	movem.l d0-d7/a0-a6,-(sp)
	endm

RESTORE_REGS	macro
	movem.l (sp)+,d0-d7/a0-a6
	endm

SET_OPTS	macro
	OPT P=68020
	OPT O+,OW-,OW1+,OW6+
	OPT NODEBUG,NOLINE,NOHCLN
	endm
