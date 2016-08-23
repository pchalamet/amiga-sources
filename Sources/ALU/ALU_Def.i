
*			Amiga Loader Unit (ALU) v1.0
*			~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*			 (c)1994 Sync/DreamDealers


* Structure Memory Header d'ALU
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	rsreset
Struct_Memory_Header	rs.b 0
mh_Lower		rs.l 1
mh_Upper		rs.l 1
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

* EQU pour ALU
* ~~~~~~~~~~~~
ALU_Any=-1
ALU_Chip=0
ALU_Fast=1
