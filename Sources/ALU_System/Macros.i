*-----------------------> pour l'appelle des libraries
	IFND MISC_MACROS_I
MISC_MACROS_I set 1

CALL	macro
	IFNE NARG=2
	move.l \1,a6
	jsr _LVO\2(a6)
	ELSEIF
	jsr _LVO\1(a6)
	ENDC
	endm

STORE	macro
	IFNE NARG=2
	move.\0 \1,\2
	ELSEIF
	fail Incorrect parameters ( STORE MACRO )
	ENDC
	endm

TAG_TRUE=-1
TAG_FALSE=0
_SysBase=4
_Custom=$dff000
_CiaA=$bfe001
_CiaB=$bfd000

	ENDC
