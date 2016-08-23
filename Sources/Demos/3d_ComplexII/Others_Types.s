	IFNE 0
*--------------------------> STRUCT Line
TYPE_LINE=1
	rsreset
Line			rs.b elmt_SIZEOF
line_Color1		rs.w 1		couleur de la droite en tramée
line_Color2		rs.w 1
line_Mask		rs.w 1		masque de la droite
line_Dot1		rs.w 1		1er point de la droite
line_Dot2		rs.w 1		2ème point de la droite
line_SIZEOF		rs.b 0

*--------------------------> STRUCT Dot
TYPE_DOT=2
	rsreset
Dot			rs.b elmt_SIZEOF
dot_Color		rs.w 1		couleur du point
dot_Dot			rs.w 1		le point
dot_SIZEOF		rs.b 0

*--------------------------> STRUCT Sphere
TYPE_SPHERE=3
	rsreset
Sphere			rs.b elmt_SIZEOF
sph_Color		rs.w 1		couleur de la sphere en tramée
sph_Radius		rs.w 1		rayon de la sphere
sph_Dot			rs.w 1		centre de la sphere
sph_SIZEOF		rs.b 0
	ENDC
