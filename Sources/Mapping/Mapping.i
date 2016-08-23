
* 			include pour le mapping
*			~~~~~~~~~~~~~~~~~~~~~~~
*			(c)1995 Sync/DreamDealers


	rsreset
Dot_Struct	rs.w 0
Dot_CoordX	rs.w 1
Dot_CoordY	rs.w 1
Dot_SizeOF	rs.w 0

	rsreset
Line_Struct	rs.w 0
Line_Dot	rs.l 1
Line_Coord	rs.b Dot_SizeOF
Line_SizeOF	rs.w 0

	rsreset
Texture_Struct	rs.w 0
Tex_Texture	rs.l 1
;; suivent ici des structures Dot
Texture_SizeOF	rs.w 0


	rsreset
Face_Struct	rs.w 0
Face_Texture	rs.l 1
Face_Nb_Lines	rs.l 1
;; suivent ici des structures Line
Face_SizeOF	rs.w 0


NEW_FACE macro
DOT_NB set 0
	endm


DEF_LINE	macro
	dc.w \1,\2
DOT_NB set DOT_NB+Dot_SizeOF
	endm

