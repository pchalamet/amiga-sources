
*			  Amiga Loader Unit (ALU)
*			  ~~~~~~~~~~~~~~~~~~~~~~~
*			 (c)1994 Sync/DreamDealers
*
*			    ALU Private include


* Structure des datas d'ALU
* ~~~~~~~~~~~~~~~~~~~~~~~~~
	rsreset
Struct_ALU_DataBase	rs.b 0
ALU_Chip_Memory		rs.l 1
ALU_Fast_Memory		rs.l 1
ALU_Micropro		rs.b 1
ALU_Math81		rs.b 1
ALU_Math82		rs.b 1
ALU_Chipset		rs.b 1
ALU_Drives		rs.w 1
ALU_Screen		rs.l 1
ALU_Coplist		rs.l 1
ALU_PrintPos		rs.w 1
ALU_DataBase_SIZEOF	rs.b 0


* Structure Memory Header d'ALU
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	rsreset
Struct_Memory_Header	rs.b 0
mh_Lower		rs.l 1
mh_Upper		rs.l 1
mh_Flags		rs.l 1
mh_Head			rs.l 1			** toujours NULL **
mh_First		rs.l 1
mh_Next			rs.l 1
mh_SIZEOF		rs.l 1


* Structure Memory Chunk d'ALU
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	rsreset
Struct_Memory_Chunk	rs.b 0
mc_Size			rs.l 1
mc_Next			rs.l 1
mc_SIZEOF		rs.b 0

SCREEN_X=640
SCREEN_Y=256
SCREEN_WIDTH=SCREEN_X/8
SCREEN_DEPTH=1

FONT_X=8
FONT_Y=8

