;-------------------------------------------------------------------------

do_scene1:
	IFD	bbox
	lea	t1_bbox_st,a1
	lea	vertex_st_p(pc),a4
	move.l	a1,(a4)

	move	#max_pkt-1,d0
.bbclr:	move.b	#-1,(a1)+
	dbf	d0,.bbclr
	ENDC

	lea	rotangle(pc),a1
	clr.l	(a1)+
	clr	(a1)

	lea	objobjpos(pc),a1
	clr.l	(a1)+
	clr	(a1)

	lea	anim_obj_rout_p(pc),a1
	clr.l	(a1)
	lea	anim_obj_adj_p(pc),a1
	clr.l	(a1)

	lea	st_odl_p(pc),a1
	lea	st_odl(pc),a4
	move.l	a4,(a1)

	lea	objectmp2(pc),a1
	clr.l	(a1)
	lea	objectmp3(pc),a1
	clr.l	(a1)

	lea	scene1_struct(pc),a1
	move.l	s1_p(pc),a4
	move.l	s1_t(pc),a5
	clr.l	(a1)
	lea	scene1_typelist,a3
	clr.l	st_m2-scene1_struct(a1)
	clr.l	t1_m2-scene1_struct(a1)
	clr.l	st_m3-scene1_struct(a1)
	clr.l	t1_m3-scene1_struct(a1)

.b:	move.l	(a0)+,d0
	beq.w	.a

	movem.l	d5-d6/a0-a5,-(a7)
	move.l	d0,a3
	jsr	(a3)
	movem.l	(a7)+,d5-d6/a0-a5

	lea	t1_struct(pc),a2

	move.l	(st_m1-scene1_struct)(a2),d0
	beq.s	.aw1
	move.l	d0,(st_m1-scene1_struct)(a1)
.aw1:	move.l	(st_m2-scene1_struct)(a2),d0
	beq.s	.aw2
	move.l	d0,(st_m2-scene1_struct)(a1)
.aw2:	move.l	(st_c-scene1_struct)(a2),d0
	beq.s	.aw3
	move.l	d0,(st_c-scene1_struct)(a1)
.aw3:	move.l	(st_m3-scene1_struct)(a2),d0
	beq.s	.aw41
	move.l	d0,(st_m3-scene1_struct)(a1)
.aw41:
;-
	move.l	(s1_tl-scene1_struct)(a2),d0
	beq.s	.aw4
	move.l	d0,a6			; objtypelist
	move	2(a2),d1
.ag2:	move	(a6)+,d0
	move	d0,(a3)+
	move.l	(a6)+,(a3)+
	cmp	#t_phong,d0
	beq.s	.aw6
	cmp	#t_texmap,d0
	beq.s	.aw7

	IFD	m_transparent
	cmp	#t_transphong,d0
	beq.s	.aw6
	cmp	#t_transtexmap,d0
	beq.w	.aw7
	ENDC

	IFD	m_bi_tmap
	cmp	#t_bi_phong,d0
	beq.s	.aw6
	cmp	#t_bi_texmap,d0
	beq.s	.aw7
	ENDC

	IFD	m_bi_tmap
	cmp	#t_bi_phong,d0
	beq.s	.aw6
	cmp	#t_bi_texmap,d0
	beq.s	.aw7
	ENDC

	IFD	m_gouraud_tmap
	cmp	#t_gouraud_tmap,d0
	beq.s	.aw7
	ENDC

	IFD	m_phong_tmap
	cmp	#t_phong_tmap,d0
	beq.s	.aw8
	ENDC

	IFD	m_bump
	cmp	#t_bump,d0
	beq.s	.aw8
	ENDC

	IFD	m_bump
	cmp	#t_bump,d0
	beq.s	.aw8
	ENDC

	IFD	m_tbump
	cmp	#t_tbump,d0
	beq.s	.aw9
	ENDC

	IFD	m_flare
	cmp	#t_flare,d0
	beq.s	.aw10
	ENDC

	IFD	m_bboard
	cmp	#t_bboard,d0
	beq.s	.aw10
	ENDC

.aw9:	move.l	(a6)+,(a3)+
.aw8:	move.l	(a6)+,(a3)+

.aw7:	move.l	(a6)+,(a3)+
	move.l	(a6)+,(a3)+
.aw10:	move.l	(a6)+,(a3)+

.aw6:	dbf	d1,.ag2
	bra.s	.aw5
;-

.aw4:	move.l	st_obj_type(pc),d2
	move.l	st_obj_map(pc),d3
	move	2(a2),d1
.ag1:	move	d2,(a3)+
	move.l	d3,(a3)+
	dbf	d1,.ag1
.aw5:

	move	(a1),d2		; anzahl punkte schon in der szene
	move	(a2),d0		; anzahl punkte des neuen objektes
	move	2(a2),d1	; anzahl flaechen des neuen objektes

;-
	lea	st_odl_p(pc),a2
	move.l	(a2),a6

	move	d0,(a6)+
	move	(a1),d3
	mulu	#6,d3
	move.l	d3,(a6)+

	move	d1,(a6)+
	move	2(a1),d3
	mulu	#6,d3
	move.l	d3,(a6)+

	move.l	a6,(a2)

;-

	add	d0,(a1)		; Neue Anzahl der Vertices
	add	d1,2(a1)	; der Tris
	addq	#1,(a1)
	addq	#1,2(a1)

	move.l	t1_pkt_p(pc),a2
	move.l	t1_tab_p(pc),a6

.c:	move.l	(a2)+,(a4)+	; vertices kopieren
	move	(a2)+,(a4)+
	dbf	d0,.c

.d:	move	(a6)+,d3	; tris kopieren
	add	d2,d3
	move	d3,(a5)+

	move	(a6)+,d3
	add	d2,d3
	move	d3,(a5)+

	move	(a6)+,d3
	add	d2,d3
	move	d3,(a5)+
	dbf	d1,.d

	bra	.b

.a:	subq	#1,(a1)+
	subq	#1,(a1)
	rts

;---

scene1_struct:
	dc.w	0			; Anz. d. Punkte des Objekts
	dc.w	0			; Anz. d. Flaechen des Objekts
s1_p:	dc.l	scene1_pkt		; Pointer auf Punkte d. Objekts
s1_t:	dc.l	scene1_tab		; Pointer auf Vertextabelle d. Obj.
	dc.l	0	;t1_lst		; Pointer auf Liste d. gruppierten Fl.
					; des Objekts fuers Sortieren.

st_j:	dc.l	0	;torus_sort_lst	; Routine fuer lokale Init. d. Obj.
st_c:	dc.l	0
s1_tl:	dc.l	scene1_typelist		; objtypelist
st_m1:	dc.l	0			; Movementdaten des Objekts
st_m2:	dc.l	0
st_m3:	dc.l	0

st_obj_map:	dc.l	0
st_obj_type:	dc.l	0		; nur phong, transphong oder biphong

st_odl_p:	dc.l	st_odl

st_odl:
;	dc	Anz der Vertices-1
;	dc.l	Offset in objectpp
;	dc	Anz der Tris
;	dc.l	Offset in objecttp

	dcb.l	(2+4+2+4)*16,0

;-----------------------------------------------------------------------

;-----------------------
; Spikes um ne LSphere erzeugen
;
; d0 = Anzahl der Spikes um X Achse
; d1 = d1*d0 Spikes
; d2 = Spike Grundflaechenradius
; d3 = Spike hoehe
; d4 = Spikesphereradius
; d7 : bit 0 = 2 Extraspikes an den Polen (0/1=an/aus)
;      bit 1 = um spike_rot_ang rotieren (1)


do_spikes:
	lea	spikes_x_y(pc),a0
	move	d0,(a0)+
	move	d1,(a0)+

	move.l	d7,-(a7)
	moveq	#0,d5
	moveq	#0,d6
	bsr	do_tripyr

;-
	lea	anzpkt(pc),a0
	move	#4-1,(a0)
	move.l	t1_pkt_p(pc),a0
	lea	tg_rotangle+4(pc),a5
	move.l	a0,a1
	move.l	#$00001800,-(a5)
	bsr	tg_rotyx		; Punkte rotieren
;-
	lea	tg_rotangle(pc),a5
	lea	4*6(a0),a1
	move.l	#$2000/2,d2
	move	spikes_x_y+2(pc),d3
	addq	#1,d3
	divs	d3,d2		;	move	#($2000/2)/(o21py+1),d2
	move	#-$800,d3
	move	spikes_x_y+2(pc),d1	;	moveq	#o21py-1,d1
	subq	#1,d1
	add	d2,d3
	move.l	#$2000,d5	;	move	#$2000/o21px,d5
	divs	spikes_x_y(pc),d5

.aa:	move	spikes_x_y(pc),d4	;	moveq	#o21px-1,d4
	subq	#1,d4
	moveq	#0,d6

.a:	move	d6,(a5)
	move	d3,2(a5)
	movem.l	d1-d3/a1,-(a7)
	bsr	tg_rotyx
	movem.l	(a7)+,d1-d3/a1
	add	d5,d6
	lea	4*6(a1),a1
	dbf	d4,.a

	add	d2,d3
	dbf	d1,.aa

	lea	t1_struct(pc),a0
	movem	spikes_x_y(pc),d0/d7
	mulu	d0,d7
	lsl	#2,d7
	subq	#1,d7
	move	d7,(a0)+
	move	d7,(a0)
;	move	#4*o21px*o21py-1,(a0)+
;	move	#4*o21px*o21py-1,(a0)

	move.l	t1_tab_p(pc),a0
	lea	4*6(a0),a1

;	move	#o21px*o21py*4-4+8-1,d7
	addq	#4,d7

.b:	movem	(a0)+,d0-d2
	addq.l	#4,d0
	addq.l	#4,d1
	addq.l	#4,d2
	movem	d0-d2,(a1)
	addq.l	#6,a1
	dbf	d7,.b

;-
	move.l	(a7),d0
	btst	#0,d0
	bne.s	.skip

	move	t1_struct(pc),d0
	move.l	t1_pkt_p(pc),a0
	addq	#1,d0
	mulu	#6,d0
	lea	4*6(a0,d0.l),a1

	lea	tg_rotangle(pc),a5
	move.l	#$00000800,(a5)
	move.l	a1,-(a7)
	bsr	tg_rotyx		; Punkte rotieren
	move.l	(a7)+,a1
	lea	4*6(a1),a1
	move.l	#$00001800,(a5)
	bsr	tg_rotyx		; Punkte rotieren
	
	lea	t1_struct(pc),a0
	addq	#8,(a0)+
	addq	#8,(a0)
;-
.skip:

	move.l	t1_pkt_p(pc),a0
	move	t1_struct(pc),d0
	lea	4*6(a0),a1
.q:	move.l	(a1)+,(a0)+
	move	(a1)+,(a0)+
	dbf	d0,.q

	move.l	(a7)+,d7
	btst	#1,d7
	beq.s	.q3

	lea	anzpkt(pc),a0
	move	t1_struct(pc),(a0)
	move.l	t1_pkt_p(pc),a0
	lea	tg_rotangle(pc),a5
	move.l	a0,a1
	move.l	spike_rot_ang(pc),(a5)
	bsr	tg_rotyx		; Punkte rotieren

.q3:	rts

spike_rot_ang:	dc.l	$08000800
spikes_x_y:	dc	0,0

;--------------------------------------------------

sph_do_end:
	bsr.s	sph_bend
	addq.l	#6,a0
	move	d3,(a0)+
	clr.l	(a0)+

	move.l	d0,d4
	mulu	#6,d4
	add.l	d4,a1

	addq.l	#1,d7
	move.l	d0,d4
	move.l	d7,d3
	subq.l	#2,d3
	subq.l	#1,d4
	move.l	d3,d2
	subq.l	#1,d2

	move.l	d3,d5

.a:	move	d7,(a1)+
	move	d3,(a1)+
	move	d2,(a1)+
	subq.l	#1,d3
	subq.l	#1,d2
	dbf	d4,.a
	move	d5,-(a1)
	rts
;--

sph_do_beg:
	neg.l	d3
	bsr.s	sph_bend

	move	d3,(a0)+
	clr.l	(a0)+

	moveq	#1,d2
	moveq	#2,d3

	move.l	d0,d4
	subq.l	#1,d4

.a:	move	d7,(a1)+
	move	d2,(a1)+
	move	d3,(a1)+
	addq.l	#1,d2
	addq.l	#1,d3
	dbf	d4,.a
	move	#1,-(a1)
	rts

;--
sph_bend:
	bsr.s	sph_calc_anz
	move.l	d4,d7
	mulu	#6,d4
	move.l	t1_pkt_p(pc),a0
	mulu	#6,d5
	addq.l	#1,d7
	move.l	t1_tab_p(pc),a1
	add.l	d4,a0
	add.l	d5,a1
	rts
;--

sph_calc_anz:
	move.l	d4,d0
	move.l	d6,d1

	move.l	d4,d5
	mulu	d6,d4
	subq.l	#1,d6
	mulu	d6,d5			; anzfl
	add.l	d5,d5
	rts

;------------------

; LSpheregenerator
;
; d3 = radius
; d4 = anzahl punkte um y-achse
; d6 = anzahl ringe+1
; d7 :	bit 0 = innen/aussen (0/1)
;	bit 1 = um sphere_rot_ang rotieren (1)
;	bit 2 = poloeffnung bei x=-radius schliessen (1)
;	bit 3 = poloeffnung bei x=radius schliessen (1)

; bit 3 nur wenn bit 2 ebenfalls 1!

do_lsphere:
	lea	lsphere_param(pc),a0
	movem.l	d3/d4/d6,(a0)

	bsr.s	sph_calc_anz
	movem.l	d4/d5/d7,-(a7)

	addq.l	#2,d6
	neg.l	d3

	move.l	#$800*$10000,d5
	divs.l	d6,d5
	move.l	d5,d4
	subq.l	#2,d6

	move.l	t1_pkt_p(pc),a0
	move.l	t1_tab_p(pc),a1
;	lea	t1_lst(pc),a2
;	lea	t1_d(pc),a3
	lea	tg_xpos(pc),a4

.a:	move.l	d3,d7
	move.l	sinp,a6		; sin
	move.l	d3,d2
	lea	$400*2(a6),a5		; cos
	swap	d4
	muls	(a6,d4.w*2),d2		; y
	muls	(a5,d4.w*2),d7		; x
	swap	d4
	add.l	d2,d2
	add.l	d7,d7
	neg.l	d2
	swap	d2
	move.l	d7,(a4)
	ext.l	d2

	lea	tg_anz1(pc),a6
	movem.l	d0-d3/a0-a3,(a6)
	movem.l	d0-d1/d3-d6/a0-a4,-(a7)
	bsr	bf_t_p1
	movem.l	(a7)+,d0-d1/d3-d6/a0-a4

	move	d0,d7
	mulu	#3*2,d7
	add.l	d7,a0

	add.l	d5,d4
	dbf	d6,.a

	lea	tg_xpos(pc),a0
	clr.l	(a0)
	bsr	torus_vert

	bsr	sph_beg_end

	btst	#0,d7
	beq.s	.qq

	move.l	d1,d2
	move.l	t1_tab_p(pc),a0
	subq.l	#1,d2
.b:	move.l	(a0),d3
	swap	d3
	move.l	d3,(a0)
	addq.l	#6,a0
	dbf	d2,.b


.qq:	btst	#1,d7
	beq.s	.q3

	subq	#1,d0
	lea	anzpkt(pc),a0
	move	d0,(a0)
	move.l	t1_pkt_p(pc),a0
	lea	tg_rotangle(pc),a5
	move.l	a0,a1
	move.l	sphere_rot_ang(pc),(a5)
	bsr	tg_rotyx		; Punkte rotieren


.q3:	movem.l	(a7)+,d0/d1/d7		; anzfl
	rts


sph_beg_end:
	movem.l	4(a7),d0/d1/d7
	btst	#2,d7
	beq.s	.q0

	movem.l	lsphere_param(pc),d3/d4/d6
	bsr	sph_do_beg
	addq.l	#1,0+4(a7)
	add.l	d0,4+4(a7)
	movem.l	4(a7),d0/d1/d7		; anzpkt/anzfl

	btst	#3,d7
	beq.s	.q0

	movem.l	lsphere_param(pc),d3/d4/d6
	bsr	sph_do_end
	addq.l	#1,0+4(a7)
	add.l	d0,4+4(a7)
	movem.l	4(a7),d0/d1/d7		; anzpkt/anzfl

.q0:	rts

lsphere_param:	dc.l	0,0,0
sphere_rot_ang:	dc.l	$08000800

;-----------------------------------------------------------

;-------------------
; Tetraedergenerator
;
; d2 = Radius des Umkreises des Grunddreiecks
; d3 = Hoehe
; d4 = Xpos im Raum
; d5 = Ypos im Raum
; d6 = Zpos im Raum

do_tripyr:
	move.l	t1_pkt_p(pc),a0
;	move.l	t1_tab_p(pc),a1
;	lea	t1_lst(pc),a2
;	lea	t1_d(pc),a3
	lea	tg_xpos(pc),a4
	move	d4,(a4)

	movem.l	d3-d6,-(a7)

	moveq	#3,d0
	moveq	#2,d1
	lea	tg_anz1(pc),a6
	movem.l	d0-d3/a0-a3,(a6)
	bsr	bf_t_p1

	movem.l	(a7)+,d3-d6
	moveq	#3-1,d7
.a:	addq.l	#2,a0
	add	d5,(a0)+
	add	d6,(a0)+
	dbf	d7,.a

	add	d4,d3
	move	d3,(a0)+
	clr.l	(a0)+

	move.l	t1_tab_p(pc),a0
	lea	pyrtab(pc),a1
	moveq	#4*3-1,d7
.b:	move	(a1)+,(a0)+
	dbf	d7,.b

	lea	tg_xpos(pc),a0
	clr.l	(a0)
	rts

pyrtab:	dc	1,2,3
	dc	2,1,4
	dc	3,2,4
	dc	1,3,4

;-------------------------
; Rotationsobjektgenerator
;
; d0 = punkte pro ring
; d1 = anzahl ringe+1
; d4 = xmin
; d5 = xmax
; a4 = pointer auf d1 radien

objx:	lea	tg_xpos(pc),a5
	swap	d4
	swap	d5
	move.l	d4,(a5)
	sub.l	d4,d5
	divs.l	d1,d5

	move.l	t1_pkt_p(pc),a0
	move.l	t1_tab_p(pc),a1
;	lea	t1_lst(pc),a2
;	lea	t1_d(pc),a3
	move.l	d1,d6
	subq.l	#1,d6

do_objx:moveq	#0,d2
	lea	tg_anz1(pc),a6
	move	(a4)+,d2
	movem.l	d0-d3/a0-a3,(a6)
	movem.l	d0-d1/d5-d6/a0-a5,-(a7)
	bsr	bf_t_p1
	movem.l	(a7)+,d0-d1/d5-d6/a0-a5
	move	d0,d4
	mulu	#3*2,d4
	add.l	d5,(a5)
	add.l	d4,a0
	
	dbf	d6,do_objx

	lea	tg_xpos(pc),a0
	clr.l	(a0)
	bra.w	torus_vert

;----------------

; Torus Generator
; d0 = Anzahl der Punkte eines Ringes
; d1 = Anzahl der Segmente des Torus
; d2 = Radius eines Ringes
; d3 = Radius des Torus
; a0 = Mem fuer Punkte
; a1 = Mem fuer Vertices

;test:
;	moveq	#8,d0
;	moveq	#16,d1
;	moveq	#20,d2
;	moveq	#80,d3
;
;	lea	t1_pkt(pc),a0
;	lea	t1_tab,a1
;	lea	t1_lst(pc),a2
;	lea	t1_d(pc),a3
;
;	bsr.s	torus_gen
;	rts

bf_torus_gen:
	move.l	t1_pkt_p(pc),a0
	move.l	t1_tab_p(pc),a1
	lea	t1_lst(pc),a2
	lea	t1_d(pc),a3

torus_gen:
	lea	tg_anz1(pc),a6
	movem.l	d0-d3/a0-a3,(a6)

	bsr.s	torus_pkt1
	bsr.s	torus_pkt2
	bra	torus_vert
	
bf_torus_gen_pkt:
	move.l	t2_pkt_p(pc),a0
	move.l	t1_tab_p(pc),a1
	lea	t1_lst(pc),a2
	lea	t1_d(pc),a3
torus_gen_pkt:
	lea	tg_anz1(pc),a6
	movem.l	d0-d3/a0-a3,(a6)
	bsr.s	torus_pkt1
	bra.s	torus_pkt2

torus_pkt1:
	move.l	tg_pktp(pc),a0
bf_t_p1:
	move.l	a0,-(a7)

	lea	anzpkt(pc),a5
	clr	(a5)

	lea	tg_rotangle+6(pc),a5
	clr.l	-(a5)
	clr	-(a5)

	moveq	#0,d5
	move.l	#$2000*$10000,d6
	move.l	tg_anz1(pc),d4
	divsl	d4,d6

	move.l	a0,a1
	move	tg_xpos(pc),(a1)+
	clr	(a1)+
	move.l	tg_rad1(pc),d0
	neg.l	d0
	move	d0,(a1)+

	subq.l	#2,d4

tg_ag1:	move.l	(a7),a0
	add.l	d6,d5
	swap	d5
	move	d5,(a5)
	swap	d5
	bsr.s	tg_rotyx
	dbf	d4,tg_ag1

	move.l	(a7)+,a0
	rts

;---
torus_pkt2:
	move.l	tg_anz1(pc),d0
	lea	anzpkt(pc),a0
	subq.l	#1,d0
	move	d0,(a0)

	move.l	tg_pktp(pc),a0
	move.l	tg_rad2(pc),d1
	addq.l	#4,a0
tg_ag3:	sub	d1,(a0)
	addq.l	#6,a0
	dbf	d0,tg_ag3

	clr.l	(a5)

	moveq	#0,d5
	move.l	tg_anz2(pc),d4
	move.l	#$2000*$10000,d6
	divsl	d4,d6

	subq.l	#2,d4

tg_ag2:	move.l	tg_pktp(pc),a0
	add.l	d6,d5
	swap	d5
	move	d5,2(a5)
	swap	d5
	bsr.s	tg_rotyx
	dbf	d4,tg_ag2

	rts

;---
; a0 = source
; a1 = dest

tg_rotyx:
	movem.l	d4-d6/a0/a5,-(a7)
	and.l	#$1ffe1ffe,(a5)
	and	#$1ffe,4(a5)
;	move.l	a1,-(a7)
;
;	move	anzpkt(pc),d4
;.a:	move	(a1),d5
;	lsl	#subpixel,d5
;	move	d5,(a1)+
;
;	move	(a1),d5
;	lsl	#subpixel,d5
;	move	d5,(a1)+
;
;	move	(a1),d5
;	lsl	#subpixel,d5
;	move	d5,4(a1)+
;	dbf	d4,.a

;	move.l	(a7),a1
	jsr	rotyx_
;	move.l	(a7)+,a0
;	move	anzpkt(pc),d4
;tg_rota:
;	move	(a0),d5
;	asr	#subpixel,d5
;	move	d5,(a0)+
;
;	move	(a0),d5
;	asr	#subpixel,d5
;	move	d5,(a0)+
;
;	addq.l	#2,a0
;
;	move	4(a0),d5
;	lsl	#subpixel,d5
;	move	d5,4(a0)
;	addq.l	#6,a0
;
;	dbf	d4,tg_rota

	movem.l	(a7)+,d4-d6/a0/a5
	rts

tg_rotangle:	dc.w	0,0,0

;---

torus_vert:
	move.l	tg_tabp(pc),a0

t_vert2:
	move.l	tg_anz2(pc),d7
	move.l	d7,d5
	subq.l	#1,d7

	move.l	tg_anz1(pc),d4
	mulu	d4,d5
	moveq	#1,d0

tv_ag1:	move.l	d0,a1

	move.l	d4,d6
	move.l	a1,d3
	subq.l	#1,d6
	add.l	d4,d3

tv_ag2:	move.l	a1,d1
	move.l	a1,d2
	move	d1,(a0)+		; 1pkt

	add.l	d4,d2
	cmp.l	d5,d2
	ble.s	tv_w2
	sub.l	d5,d2

tv_w2:	move	d2,(a0)+		; 2pkt

	addq.l	#1,d1
	cmp.l	d3,d1
	bne.s	tv_w1
	move.l	d0,d1
tv_w1:	move	d1,(a0)+		; 3pkt
;-
	move	d1,(a0)+		; 1pkt
	move	d2,(a0)+		; 2pkt

	add.l	d4,d1
	cmp.l	d5,d1
	ble.s	tv_w3
	sub.l	d5,d1
tv_w3:	move	d1,(a0)+		; 3pkt

	addq.l	#1,a1
	dbf	d6,tv_ag2

	add.l	d4,d0
	dbf	d7,tv_ag1
	rts

;---

;torus_sort_lst:
;	move.l	tg_lstp(pc),a2
;	move.l	a2,a0
;
;	move	#1,(a0)+
;	move	tg_anz2+2(pc),(a0)+
;
;	moveq	#0,d0
;	move.l	tg_anz2(pc),d7	; Anz. Ringe
;	subq.l	#1,d7
;	move.l	tg_dp(pc),a1
;
;	move.l	tg_anz1(pc),d1
;	move.l	d1,d6
;	add.l	d6,d6		; Pro Ring gibts tg_anz1*2 Flaechen
;	subq.l	#1,d6
;	mulu	#6,d1
;
;	move.l	g_liste_p(pc),a4	; zaehlen beginnt bei g_liste
;	move.l	objtab_p,a5	; und bei objtab das gleiche
;	move.l	g_l_element_l,d3
;
;tsl_a1:	move	d6,d5
;	move.l	a1,a3
;	sub.l	a2,a3
;	move	a3,(a0)+
;	move	d5,(a1)+
;	move	d0,(a0)+
;	add.l	d1,d0
;tsl_a2:	move.l	a5,(a1)+
;	move.l	a4,(a1)+
;	addq.l	#8,a5
;	add.l	d3,a4
;	dbf	d5,tsl_a2
;	dbf	d7,tsl_a1
;
;	rts

;---

tg_anz1:dc.l	0
tg_anz2:dc.l	0
tg_rad1:dc.l	0
tg_rad2:dc.l	0
tg_pktp:dc.l	0
tg_tabp:dc.l	0
tg_lstp:dc.l	0
tg_dp:	dc.l	0

tg_xpos:	dc.l	0

;-------------------------------------------------

max_ring	=	8	;16
max_seg		=	16	;32

max_pkt		=	spoints1	; max_ring*max_seg*4*2
max_fl		=	sflanz1		; max_ring*max_seg*4*2*2

t1_struct:
	dc.w	0			; Anz. d. Punkte des Objekts
	dc.w	0			; Anz. d. Flaechen des Objekts
t1_pkt_p:dc.l	t1_pkt			; Pointer auf Punkte d. Objekts
t1_tab_p:dc.l	t1_tab			; Pointer auf Vertextabelle d. Obj.
	dc.l	0	;t1_lst		; Pointer auf Liste d. gruppierten Fl.
					; des Objekts fuers Sortieren.

	dc.l	0	;torus_sort_lst	; Routine fuer lokale Init. d. Obj.
	dc.l	obj2cols2
t1_tl:	dc.l	0			; objtypelist
t1_m1:	dc.l	0			; Movementdaten des Objekts
t1_m2:	dc.l	0	;obj2m2
t1_m3:	dc.l	0

t1_lst:
t1_d:

t2_pkt_p:	dc.l	t2_pkt
t1_tl_p:	dc.l	t1_typelist

;--------------------------------------------------------------------------

