NB_POINT=8*8+6*8
my_object
	dc.w 1000			zoom
	dc.l 0				ExtraInit
	dc.l my_ExtraJump		ExtraJump
	dc.l my_color			ObjectColor
	dc.l my_dots			les points
	dc.l my_elements		les elements
	dc.w SCREEN_WIDTH/2		PosX
	dc.w SCREEN_HEIGHT/2		PosY
	dc.w 0				Alpha
	dc.w 0				Teta
	dc.w 0				Phi
	dc.w 0				BlankLimit


A1=1000
A2=707
B1=600
B2=424
C1=500
C2=353

D1=500
D2=353
E1=300
E2=212
F1=250
F2=176

make_dots macro
	dc.w \1,0,\3
	dc.w \2,-\2,\3
	dc.w 0,-\1,\3
	dc.w -\2,-\2,\3
	dc.w -\1,0,\3
	dc.w -\2,\2,\3
	dc.w 0,\1,\3
	dc.w \2,\2,\3
	endm

my_dots
	dc.w 8*8
	make_dots C1,C2,-1000			etage 0
	make_dots B1,B2,-300			etage 1
	make_dots A1,A2,-200			etage 2
	make_dots A1,A2,0			etage 3
	make_dots A1,A2,0			etage 4
	make_dots A1,A2,200			etage 5
	make_dots B1,B2,300			etage 6
	make_dots C1,C2,1000			etage 7

	make_dots F1,F2,-500			etage 8
	make_dots E1,E2,-150			etage 9
	make_dots D1,D2,-100			etage 10
	make_dots D1,D2,100			etage 11
	make_dots E1,E2,150			etage 12
	make_dots F1,F2,500			etage 13

face	macro
\@
	dc.w TYPE_FACE				face color,p1,p2,etage
	dc.w 0
	dc.w -1,\1
	dc.w 4
	dc.w \2+8*\4,\3+8*\4
	dc.w \3+8*\4,\3+8*\4+8
	dc.w \3+8*\4+8,\2+8*\4+8
	dc.w \2+8*\4+8,\2+8*\4
	endm

circle	macro
	face \1,0,1,\2				circle color,etage
	face \1+1,1,2,\2
	face \1,2,3,\2
	face \1+1,3,4,\2
	face \1,4,5,\2
	face \1+1,5,6,\2
	face \1,6,7,\2
	face \1+1,7,0,\2
	endm	

my_elements
	dc.w 8*6+2
	dc.l _012
	dc.l _013
	dc.l _014
	dc.l _015
	dc.l _016
	dc.l _017
	dc.l _018
	dc.l _019
	dc.l _020
	dc.l _021
	dc.l _022
	dc.l _023
	dc.l _024
	dc.l _025
	dc.l _026
	dc.l _027
	dc.l _028
	dc.l _029
	dc.l _030
	dc.l _031
	dc.l _032
	dc.l _033
	dc.l _034
	dc.l _035
	dc.l _036
	dc.l _037
	dc.l _038
	dc.l _039
	dc.l _040
	dc.l _041
	dc.l _042
	dc.l _043
	dc.l _044
	dc.l _045
	dc.l _046
	dc.l _047
	dc.l _048
	dc.l _049
	dc.l _050
	dc.l _051
	dc.l _052
	dc.l _053
	dc.l _054
	dc.l _055
	dc.l _056
	dc.l _057
	dc.l _058
	dc.l _059
	dc.l top_element1
	dc.l bottom_element1
	dc.l _060
	dc.l _061
	dc.l _062
	dc.l _063
	dc.l _064
	dc.l _065
	dc.l _066
	dc.l _067
	dc.l _068
	dc.l _069
	dc.l _070
	dc.l _071
	dc.l _072
	dc.l _073
	dc.l _074
	dc.l _075
	dc.l _076
	dc.l _077
	dc.l _078
	dc.l _079
	dc.l _080
	dc.l _081
	dc.l _082
	dc.l _083
	dc.l _084
	dc.l _085
	dc.l _086
	dc.l _087
	dc.l _088
	dc.l _089
	dc.l _090
	dc.l _091
	dc.l _092
	dc.l _093
	dc.l _094
	dc.l _095
	dc.l _096
	dc.l _097
	dc.l _098
	dc.l _099
	dc.l top_element2
	dc.l bottom_element2

	circle 1,0
	circle 3,1
	circle 5,2
	circle 5,4
	circle 3,5
	circle 1,6

	circle 1,8
	circle 3,9
	circle 5,10
	circle 3,11
	circle 1,12

top_element1
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,7
	dc.w 8
	dc.w 7,6,6,5,5,4,4,3,3,2,2,1,1,0,0,7
bottom_element1
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,7
	dc.w 8
	dc.w 56,57,57,58,58,59,59,60,60,61,61,62,62,63,63,56

top_element2
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,7
	dc.w 8
	dc.w 71,70,70,69,69,68,68,67,67,66,66,65,65,64,64,71
bottom_element2
	dc.w TYPE_FACE
	dc.w 0
	dc.w -1,7
	dc.w 8
	dc.w 104,105,105,106,106,107,107,108,108,109,109,110,110,111,111,104

my_color
	dc.w $467,$B9A,$58B,$A89,$47A,$978,$369,$A68

my_ExtraJump
	moveq #4,d0
	moveq #-6,d1
	moveq #-8,d2
	lea my_object(pc),a0
	bsr Incrize_Angles

	tst.w timer-data_base(a5)
	beq.s execute_routine
	subq.w #1,timer-data_base(a5)
	rts
execute_routine
	move.l routine(pc),a0
	jmp (a0)

expand_init
	move.w #40,execute_timer-data_base(a5)
	move.w #8*8+6*8,my_dots-data_base(a5)	intègre les points de l'objet 2
	move.w #8*6+2+8*5+2,my_elements-data_base(a5)	et ses elements
	move.l #expand,routine-data_base(a5)

	lea my_elements+2(pc),a0		l'objet1 VRAIMENT visible
	moveq #8*6+2-1,d0			sous tous les angles
loop_make_reverse
	move.l (a0)+,a1
	move.w face_back_color(a1),face_front_color(a1)
	dbf d0,loop_make_reverse

expand
	lea my_dots+2+4(pc),a0			explose l'objet 1
	moveq #8*4-1,d0
	moveq #50,d1
loop_sub
	sub.w d1,(a0)
	addq.l #3*2,a0
	dbf d0,loop_sub

	moveq #8*4-1,d0
loop_add
	add.w d1,(a0)
	addq.l #3*2,a0
	dbf d0,loop_add

	subq.w #1,execute_timer-data_base(a5)
	beq.s end_expand
	rts
end_expand
	move.l #zoom_init,routine-data_base(a5)
	rts

zoom_init
	move.w #20,execute_timer-data_base(a5)	fait croite que l'objet 1 est
	move.w #2000,my_object-data_base(a5)	l'objet 2

	lea my_dots+2+4(pc),a0
	move.w #8*8,-6(a0)
	lea save_dots(pc),a1			restore les Z de l'objet 1
	moveq #8*8-1,d0
loop_restore_dots
	move.w (a1)+,(a0)
	addq.l #3*2,a0
	dbf d0,loop_restore_dots

	lea my_elements(pc),a0
	move.w #8*6+2,(a0)+
	lea save_elements(pc),a1
	moveq #8*6+2+8*5+2-1,d0			remet en ordre les elements
loop_restore_elements
	move.l (a1)+,(a0)+
	dbf d0,loop_restore_elements

	lea my_elements+2(pc),a0		rend certaine face non visibles
	moveq #8*6+2-1,d0			sous certains angles
	moveq #-1,d1
loop_make_no_reverse
	move.l (a0)+,a1
	move.w d1,face_front_color(a1)
	dbf d0,loop_make_no_reverse

	move.l #zoom_routine,routine-data_base(a5)
zoom_routine
	sub.w #50,my_object-data_base(a5)	zoom sur l'objet 1
	subq.w #1,execute_timer-data_base(a5)
	beq.s end_zoom
	rts
end_zoom
	move.w #60,timer-data_base(a5)
	move.l #expand_init,routine-data_base(a5)
	rts

execute_timer	dc.w 0
timer		dc.w 50
routine		dc.l expand_init

save_dots
	dcb.w 8,-1000
	dcb.w 8,-300
	dcb.w 8,-200
	dcb.w 16,0
	dcb.w 8,200
	dcb.w 8,300
	dcb.w 8,1000

save_elements
	dc.l _012
	dc.l _013
	dc.l _014
	dc.l _015
	dc.l _016
	dc.l _017
	dc.l _018
	dc.l _019
	dc.l _020
	dc.l _021
	dc.l _022
	dc.l _023
	dc.l _024
	dc.l _025
	dc.l _026
	dc.l _027
	dc.l _028
	dc.l _029
	dc.l _030
	dc.l _031
	dc.l _032
	dc.l _033
	dc.l _034
	dc.l _035
	dc.l _036
	dc.l _037
	dc.l _038
	dc.l _039
	dc.l _040
	dc.l _041
	dc.l _042
	dc.l _043
	dc.l _044
	dc.l _045
	dc.l _046
	dc.l _047
	dc.l _048
	dc.l _049
	dc.l _050
	dc.l _051
	dc.l _052
	dc.l _053
	dc.l _054
	dc.l _055
	dc.l _056
	dc.l _057
	dc.l _058
	dc.l _059
	dc.l top_element1
	dc.l bottom_element1
	dc.l _060
	dc.l _061
	dc.l _062
	dc.l _063
	dc.l _064
	dc.l _065
	dc.l _066
	dc.l _067
	dc.l _068
	dc.l _069
	dc.l _070
	dc.l _071
	dc.l _072
	dc.l _073
	dc.l _074
	dc.l _075
	dc.l _076
	dc.l _077
	dc.l _078
	dc.l _079
	dc.l _080
	dc.l _081
	dc.l _082
	dc.l _083
	dc.l _084
	dc.l _085
	dc.l _086
	dc.l _087
	dc.l _088
	dc.l _089
	dc.l _090
	dc.l _091
	dc.l _092
	dc.l _093
	dc.l _094
	dc.l _095
	dc.l _096
	dc.l _097
	dc.l _098
	dc.l _099
	dc.l top_element2
	dc.l bottom_element2

