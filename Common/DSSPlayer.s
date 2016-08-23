;**************************************************************************
;*
;*   ROUTINE DE RESTITUTION D'UN MODULE DSS
;*   --------------------------------------
;*
;*   Si vous désirez incorporer des Modules DSS dans vos programmes, vous
;*   pouvez utiliser ce listing...
;*
;*   Seules les fonctions de restitution du Module sont présentes dans ce
;*   fichier. Il vous faudra effectuer l'allocation, le chargement et la
;*   libération du Module vous-même (en mémoire CHIP).
;*
;* > Après avoir chargé le Module en mémoire CHIP:
;*
;*   -placez l'adresse du début de la zone mémoire où est placée le Module
;*    dans le pointeur SongPointer (à la fin de ce fichier).
;*   -appelez la fonction InitPlay().
;*
;* > Pour arrêter la restitution, il suffit d'appeler la fonction
;*   RemovePlayer().
;*
;*   Ce programme a été écrit pour l'assembleur de l'Aztec 3.6a.
;*   L'adaptation à un autre assembleur est très simple.
;*
;**************************************************************************

;----- fonctions Amiga ------

_LVOOpenResource        EQU        -498
_LVOAddICRVector        EQU        -6
_LVORemICRVector        EQU        -12

;------- ExecBase ----

SysBase                 EQU     4
PAL                     EQU     50
eb_PowerSupplyFreq      EQU     531

;------- CIAA --------

CIAAPRA         EQU     $bfe001
CIABTALO        EQU     $bfd400
CIABTAHI        EQU     $bfd500
CIABICR         EQU     $bfdd00
CIABCRA         EQU     $bfde00

CIABTBLO        EQU     $bfd600
CIABTBHI        EQU     $bfd700
CIABCRB         EQU     $bfdf00

;------ Song ----------

sng_Tempo       EQU     8
sng_Instr0      EQU     10
sng_Len         EQU     1436
sng_Seq         EQU     1438
sng_Data        EQU     1566

;------ InstrData -----

MAXINSTR        EQU     30
SIZEOF_insdt    EQU     46

instr_Name      EQU     0
instr_Start     EQU     30
instr_Len       EQU     34
instr_RStart    EQU     36
instr_RLen      EQU     40
instr_Vol       EQU     42
instr_Freq      EQU     44

;------- AudioData -

SIZEOF_ad       EQU     24

ad_SampPer      EQU     0
ad_Effet        EQU     2
ad_Info         EQU     3
ad_Volume       EQU     4
ad_SmpAdr       EQU     6
ad_SmpLen       EQU     10
ad_RepAdr       EQU     12
ad_RepLen       EQU     16
ad_ArpPer       EQU     18
ad_DMABit       EQU     20
ad_PitchPer     EQU     22

;------- AudioChips -------

DMACON          EQU     $dff096
DMASET          EQU     $8000

AUD0LCH         EQU     $dff0a0
AUD1LCH         EQU     $dff0b0
AUD2LCH         EQU     $dff0c0
AUD3LCH         EQU     $dff0d0
AUDxLEN         EQU     $4
AUDxPER         EQU     $6
AUDxVOL         EQU     $8
AUDxDAT         EQU     $a
SIZEOF_AUD      EQU     $10

;------ Block ---------

NEXTTRACK       EQU     4
NEXTLINE        EQU     16
BLOCKSIZE       EQU     1024
MAXTRACK        EQU     4

;------- Notes -------

DO2             EQU     1712
SI5             EQU     113
STOP            EQU     $7ff

;------- Effects -----

MASK_EFF        EQU     7
MASK_VAL        EQU     $f

ARPEGGIO        EQU     0
PITCHUP         EQU     1
PITCHDOWN       EQU     2
VOLUME          EQU     3
MASTERVOL       EQU     4
TEMPO           EQU     5
JUMP            EQU     6
FILTER          EQU     7

MAX_VOL         EQU     64
BREAK           EQU     $ff


        CSEG

;------------------ routines à appeler -----------------

; routine d'installation de l'interruption timer et d'initialisation du player
; retourne 0 si installation OK ; 1 si problème

InitPlay:
        movem.l d1-d2/a0-a3/a6,-(sp)
        move.l  SysBase,a6
        lea     CiabName,a1
        moveq   #0,d0
        jsr     _LVOOpenResource(a6)
        move.l  d0,CiabBase
        beq.s   InitPlayError
        cmp.b   #PAL,eb_PowerSupplyFreq(a6)
        beq.s   initsong
        move.w  #2,IsNTSC
initsong:
        bsr.s   InitSampleAdr
        bsr.s   InitSamples
        bsr.s   InitInterrupt
        tst.l   d0
        beq.s   EndInitPlay
InitPlayError:
        moveq   #1,d0
EndInitPlay:
        movem.l (sp)+,d1-d2/a0-a3/a6
        rts

; routine de fin d'interruption

RemovePlayer:
        movem.l d0-d1/a0-a1/a6,-(sp)
        bsr.s   DisablePlayer
        move.l  CiabBase,a6
        lea     TimerInt,a1
        moveq   #1,d0
        jsr     _LVORemICRVector(a6)
        bclr    #1,CIAAPRA
        movem.l (sp)+,d0-d1/a0-a1/a6
        rts

;-------------- routines internes -----------------

InitInterrupt:
        bsr.s   EnablePlayer
        move.l  CiabBase,a6
        lea     TimerInt,a1
        moveq   #1,d0
        jsr     _LVOAddICRVector(a6)
        tst.l   d0
        bne.s   InitInterruptEnd
        move.b  CIABCRB,d0
        and.b   #%10000000,d0
        or.b    #1,d0
        move.b  d0,CIABCRB
        move.b  #$82,CIABICR
        lea     TimerTable,a0
        move.w  IsNTSC,d0
        move.b  1(a0,d0),CIABTBLO
        move.b  (a0,d0),CIABTBHI
        moveq   #0,d0
InitInterruptEnd:
        rts

InitSampleAdr:
        move.l  SongPointer,a1
        lea     sng_Len(a1),a0
        move.w  (a0)+,d0                ; d0 = songlen
        subq.w  #1,d0
        moveq   #0,d1
        move.l  d1,d2
SeekLastBlockLoop:
        move.b  (a0)+,d2
        cmp.b   d2,d1
        bhi.s   NotLastBlock
        move.b  d2,d1
NotLastBlock:
        dbra    d0,SeekLastBlockLoop
        addq.w  #1,d1
        moveq   #10,d0
        lsl.l   d0,d1                   ; d1 = taille block
        lea     sng_Data(a1),a0
        add.l   d1,a0                   ; a0 -> premier sample
        lea     sng_Instr0(a1),a2       ; a2 -> premier instr
        lea     SampleAdrTable,a3
        moveq   #MAXINSTR,d0
InitAdrLoop:
        moveq   #0,d1
        move.w  instr_Len(a2),d1        ; len ?
        beq.s   InitNextAdr
InitThisAdr:
        move.l  a0,(a3)
        moveq   #0,d2
        cmp.w   #1,instr_RLen(a2)       ; rlen
        beq.s   GetSampleSize
        move.w  instr_RLen(a2),d2
        add.l   d2,d1
GetSampleSize:
        add.l   d1,d1
        bclr    #0,instr_Start+3(a2)    ; aligner instr_Start sur mot
        add.l   instr_Start(a2),d1      ; Start
        add.l   d1,a0                   ; a0 -> nextsample
InitNextAdr:
        addq.l  #4,a3
        add.l   #SIZEOF_insdt,a2
        dbra    d0,InitAdrLoop
        rts

InitSamples:
        lea     SampleAdrTable,a0
        moveq   #MAXINSTR,d0
InitSamplesLoop:
        move.l  (a0)+,d1
        beq.s   InitSamplesLoopEnd
        move.l  d1,a1
        moveq   #3,d2
Clear4Bytes:
        clr.b   (a1)+
        dbra    d2,Clear4Bytes
InitSamplesLoopEnd:
        dbra    d0,InitSamplesLoop
        rts


DisablePlayer:
        clr.w   AUD0LCH+AUDxVOL
        clr.w   AUD1LCH+AUDxVOL
        clr.w   AUD2LCH+AUDxVOL
        clr.w   AUD3LCH+AUDxVOL
        move.w  #$0f,DMACON
        rts

EnablePlayer:
        clr.w   AUD0LCH+AUDxVOL
        clr.w   AUD1LCH+AUDxVOL
        clr.w   AUD2LCH+AUDxVOL
        clr.w   AUD3LCH+AUDxVOL
        rts

TimerIntRoutine:
        movem.l d1-d7/a0-a6,-(sp)
        bsr.s   PlayRoutine
        movem.l (sp)+,d1-d7/a0-a6
        moveq   #0,d0
        rts

PlayRoutine:
        move.l  SongPointer,a6
        move.w  8(a6),d0
        addq.w  #1,PlayTimer
        cmp.w   PlayTimer,d0            ; tempo == playtimer ?
        bne.s   PlayEffects             ; non, jouer effects
        clr.w   PlayTimer               ; oui, remettre timer à zero
        bra.s   PlaySound               ; jouer note

PlayEffects:
        lea     ChannelData0,a0
        lea     AUD0LCH,a1
        moveq   #MAXTRACK-1,d3          ; 4 pistes
PlayEffLoop:
        move.w  (a0),d0
        and.w   #$7ff,d0
        cmp.w   #STOP,d0                ; note == STOP ?
        beq.s   PlayEffLoopEnd
        tst.b   ad_Info(a0)             ; valeur effet == 0 ?
        beq.s   PlayEffLoopEnd
        bsr.s   MakeEffects
PlayEffLoopEnd:
        add.l   #SIZEOF_ad,a0           ; a0 -> channeldata suivant
        add.w   #SIZEOF_AUD,a1          ; a1 -> audio reg suivant
        dbra    d3,PlayEffLoop
        rts

MakeEffects:
        move.b  ad_Effet(a0),d0
        beq.s   EffArpeggio
        cmp.b   #PITCHUP,d0
        beq.s   EffPitchUp
        cmp.b   #PITCHDOWN,d0
        beq.s   EffPitchDown
        rts

EffArpeggio:
        moveq   #0,d0
        move.w  PlayTimer,d0
        cmp.w   #1,d0
        beq.s   EffArpOne
        cmp.w   #2,d0
        beq.s   EffArpTwo
        cmp.w   #3,d0
        beq.s   EffArpThree
        cmp.w   #4,d0
        beq.s   EffArpTwo
        cmp.w   #5,d0
        beq.s   EffArpOne
        rts

EffArpOne:
        move.b  ad_Info(a0),d0
        lsr.b   #4,d0                   ; d0 = nibble haut value
        bra.s   EffArpSeek
EffArpTwo:
        move.b  ad_Info(a0),d0
        and.b   #MASK_VAL,d0            ; d0 = nibble bas value
        bra.s   EffArpSeek
EffArpThree:
        move.w  ad_ArpPer(a0),d2        ; d2 = période normale
        bra.s   EffArpFound
EffArpSeek:
        add.w   d0,d0                   ; d0 = offset notetable
        move.w  ad_ArpPer(a0),d1        ; d1 = période normale
        lea     NoteTable,a2
EffArpLoop:
        move.w  (a2,d0.w),d2            ; d2 = nouvelle période
        cmp.w   (a2)+,d1                ; (a2) == période normale ?
        bne.s   EffArpLoop
EffArpFound:
        move.w  d2,AUDxPER(a1)
        rts

EffPitchUp:
        moveq   #0,d0
        move.b  ad_Info(a0),d0          ; d0 = valeur effet
        sub.w   d0,ad_PitchPer(a0)
        cmp.w   #SI5,ad_PitchPer(a0)    ; inf. à plus petite période ?
        bpl.s   EffPitchOK
        move.w  #SI5,ad_PitchPer(a0)
        bra.s   EffPitchOK
EffPitchDown:
        moveq   #0,d0
        move.b  ad_Info(a0),d0
        add.w   d0,ad_PitchPer(a0)
        cmp.w   #DO2,ad_PitchPer(a0)    ; sup. à plus grande période ?
        bmi.s   EffPitchOK
        move.w  #DO2,ad_PitchPer(a0)
EffPitchOK:
        move.w  ad_PitchPer(a0),AUDxPER(a1)
        rts

PlaySound:
        lea     sng_Data(a6),a0
        lea     sng_Seq(a6),a1
        move.w  CurrentPos,d0
        move.w  d0,NewPosJump
        moveq   #0,d1
        move.b  0(a1,d0.w),d1           ; d1 = numéro block
        moveq   #10,d0
        lsl.l   d0,d1
        add.l   OffsetBlock,d1          ; d1 = offset dans block data
        clr.w   AudioDMA

        lea     AUD0LCH,a3
        lea     ChannelData0,a4
        moveq   #MAXTRACK-1,d7          ; 4 pistes
PlayLoop:
        bsr.s   PlayInstr
        add.w   #SIZEOF_AUD,a3
        add.l   #SIZEOF_ad,a4
        dbra    d7,PlayLoop

        move.w  AudioDMA,d0             ; démarrage audio DMA
        or.w    #DMASET,d0
        move.w  d0,DMACON

        move.b  CIABCRA,d1              ; boucle attente
        move.b  d1,d0
        and.b   #%11000000,d0
        or.b    #%00001000,d0
        move.b  d0,CIABCRA
        move.b  #$2f,CIABTALO
        move.b  #1,CIABTAHI
PlayDelay1:
        btst.b  #0,CIABCRA
        bne.s   PlayDelay1
        move.b  d1,CIABCRA
        move.b  #%00000001,CIABICR

        lea     ChannelData0,a0         ; mise en place nouvelle valeur dans
        lea     AUD0LCH,a1              ; registres audio
        moveq   #MAXTRACK-1,d0
SetNewValue:
        move.l  ad_RepAdr(a0),(a1)
        move.w  ad_RepLen(a0),AUDxLEN(a1)
        add.l   #SIZEOF_ad,a0
        add.w   #SIZEOF_AUD,a1
        dbra    d0,SetNewValue
        cmp.l   #BLOCKSIZE-NEXTLINE,OffsetBlock  ; fin de block ?
        bne.s   ChangePosition
        clr.w	BreakStatus
        bra.s	ChangePosition
NoChangePosition:
        add.l   #NEXTLINE,OffsetBlock   ; modif. offsetblock
        tst.w   BreakStatus             ; jump ou break ?
        beq.s   PlaySoundEnd
        clr.w   BreakStatus
ChangePosition:
        clr.l   OffsetBlock             ; offset block = 0
        move.w  NewPosJump,CurrentPos
        addq.w  #1,CurrentPos           ; nouvelle position
        move.w  sng_Len(a6),d0
        move.w  CurrentPos,d1
        cmp.w   d0,d1                   ; fin de chanson ?
        bne.s   PlaySoundEnd
        clr.w   CurrentPos              ; position = 0
PlaySoundEnd:
        rts

PlayInstr:
        lea     sng_Instr0(a6),a2
        move.l  (a0,d1.l),ad_SampPer(a4)
        addq.l  #NEXTTRACK,d1
        moveq   #0,d0
        move.b  ad_SampPer(a4),d0
        lsr.b   #3,d0                   ; d0 = numéro instr
        tst.b   d0                      ; d0 == 0 ?
        beq.s   NoSampleChange

        lea     SampleAdrTable,a5
        subq.b  #1,d0
        move.l  d0,d3
        lsl.w   #2,d0                   ; d0 = offset table adr sample
        mulu    #SIZEOF_insdt,d3
        add.l   #instr_Start,d3
        add.l   d3,a2                   ; a2 -> Start InstrData
        move.l  (a5,d0.w),d4
        add.l   (a2)+,d4                ; Start
        move.l  d4,ad_SmpAdr(a4)
        beq.s   NoSampleChange
        move.w  (a2)+,ad_SmpLen(a4)     ; Len
        move.l  (a2)+,d5                ; RStart
        move.w  (a2)+,d2                ; RLen
        bne.s   SetRepeat
        moveq   #1,d2
        moveq   #0,d5
SetRepeat:
        move.w  d2,ad_RepLen(a4)
        add.l   ad_SmpAdr(a4),d5
        move.l  d5,ad_RepAdr(a4)
        move.w  (a2),ad_Volume(a4)      ; Volume
NoSampleChange:
        move.w  ad_SampPer(a4),d6
        and.w   #$7ff,d6                ; note == 0 ?
        beq.s   TestEffects
        move.w  d6,ad_ArpPer(a4)
        move.w  ad_DMABit(a4),d0
        move.w  d0,DMACON               ; coupe DMA audio pour cette piste

        move.b  CIABCRA,d2              ; boucle attente
        move.b  d2,d3
        and.b   #%11000000,d3
        or.b    #%00001000,d3
        move.b  d3,CIABCRA
        move.b  #$2f,CIABTALO
        move.b  #1,CIABTAHI
PlayDelay2:
        btst.b  #0,CIABCRA
        bne.s   PlayDelay2
        move.b  d2,CIABCRA
        move.b  #%00000001,CIABICR

        cmp.w   #STOP,d6                ; note == 'OFF' ?
        bne.s   SetPlayRegs
        clr.w   AUDxVOL(a3)             ; couper volume audio
        or.w    d0,AudioDMA
        rts

SetPlayRegs:
        move.l  ad_SmpAdr(a4),(a3)      ; adr sample == NULL ?
        beq.s   TestEffects
        move.w  ad_SmpLen(a4),AUDxLEN(a3)
        move.w  d6,AUDxPER(a3)
        or.w    d0,AudioDMA
        move.w  d6,ad_PitchPer(a4)
TestEffects:
        move.b  ad_Effet(a4),d0         ; d0 = effect
        bsr.s   EffVolume
        tst.b   d0
        beq.s   TestEffectsEnd
        cmp.b   #FILTER,d0
        beq.s   EffFilter
        cmp.b   #MASTERVOL,d0
        beq.s   EffMaster
        cmp.b   #TEMPO,d0
        beq.s   EffSpeed
        cmp.b   #JUMP,d0
        beq.s   EffJump
TestEffectsEnd:
        rts

EffVolume:                              ; modifier volume
        cmp.w   #VOLUME,d0
        bne.s   UseInstrVol
        moveq   #0,d2
        move.b  ad_Info(a4),d2          ; d0 = nouveau volume
        bra.s   SetInstrVol
UseInstrVol:
        tst.w   d6
        beq.s   EffVolumeEnd
        move.w  ad_Volume(a4),d2
SetInstrVol:
        sub.w   MasterVolume,d2         ; nouveau volume - master >= 0
        bge.s   SetVolumeReg
        moveq   #0,d2                   ; nouveau volume = 0
SetVolumeReg:
        move.w  d2,AUDxVOL(a3)          ; nouveau volume dans regs
EffVolumeEnd:
        rts

EffMaster:                              ; modifier master volume
        moveq   #MAX_VOL,d2
        move.b  ad_Info(a4),d0
        sub.b   d0,d2
        blt.s   EffMasterEnd
        move.b  d2,MasterVolume+1
EffMasterEnd:
        rts

EffSpeed:                               ; modifier tempo
        move.b  ad_Info(a4),d0
        beq.s   EffSpeedEnd
        clr.w   PlayTimer
        move.b  d0,sng_Tempo+1(a6)
EffSpeedEnd:
        rts

EffJump:                                ; jump ou break
        move.w  #1,BreakStatus
        move.b  ad_Info(a4),d0
        cmp.b   #BREAK,d0
        beq.s   EffBreak
        subq.b  #2,d0
        ext.w   d0
        move.w  d0,NewPosJump
        rts
EffBreak:
        move.w  CurrentPos,NewPosJump
        rts

EffFilter:                              ; filter on/off
        move.b  ad_Info(a4),d0
        bne.s   SetFilter
        bset    #1,CIAAPRA
        rts
SetFilter:
        bclr    #1,CIAAPRA
        rts

        DSEG

CiabBase:       dc.l    0
IsNTSC:         dc.w    0

CiabName:       dc.b    'ciab.resource',0
TimerIntName:   dc.b    'DSS Tracker Player',0
                cnop    0,2

TimerInt:
        dc.l  0                 ; Interrupt.is_Node.ln_Succ
        dc.l  0                 ; Interrupt.is_Node.ln_Pred
        dc.b  2                 ; Interrupt.is_Node.ln_Type = NT_INTERRUPT
        dc.b  -10               ; Interrupt.is_Node.ln_Pri
        dc.l  TimerIntName      ; Interrupt.is_Node.ln_Name
        dc.l  0                 ; Interrupt.is_Data
        dc.l  TimerIntRoutine   ; Interrupt.is_Code


PlayOn:         dc.w    0
PlayTimer:      dc.w    0
CurrentPos:     dc.w    0
OffsetBlock:    dc.l    0
AudioDMA:       dc.w    0
MasterVolume:   dc.w    0
BreakStatus:    dc.w    0
NewPosJump:     dc.w    0

ChannelData0:
        dc.w    0               ; Période               0
        dc.w    0               ; Sample+Info           2
        dc.w    0               ; Volume                4
        dc.l    0               ; Adr. Sample           6
        dc.w    0               ; Long. Sample         10
        dc.l    0               ; Adr. Répét.          12
        dc.w    0               ; Long. Répét.         16
        dc.w    0               ; Période Shazam       18
        dc.w    1               ; DMA bit              20
        dc.w    0               ; période Pitch        22
ChannelData1:
        ds.w    10
        dc.w    2
        dc.w    0
ChannelData2:
        ds.w    10
        dc.w    4
        dc.w    0
ChannelData3:
        ds.w    10
        dc.w    8
        dc.w    0

        dc.w    1712
NoteTable:
        dc.w    1712,1616,1524,1440,1356,1280,1208,1140,1076,1016,960,906
        dc.w    856,808,762,720,678,640,604,570,538,508,480,453
        dc.w    428,404,381,360,339,320,302,285,269,254,240,226
        dc.w    214,202,190,180,170,160,151,143,135,127,120,113
        dc.w    113,113,113,113,113,113,113,113,113,113,113,113
        dc.w    113,113,113,113,113,113,113,113,113,113,113,113
        dc.w    113,113,113,113,113,113

SampleAdrTable: ds.l    31

TimerTable:     dc.w    14187,14318

SongPointer:    dc.l    0               ; adresse du module en mémoire CHIP

