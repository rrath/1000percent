calc_normals:
	lea	z_nv_act(pc),a1

	move.l	normal_st_p(pc),a4
	move.l	normal_zv_p(pc),a0
;	move.l	objectpp(pc),a2		; original Punkte d. Objekts
	move.l	koordxyz_sp_p(pc),a2	; original Punkte mit Subpixel
	move	anzpkt(pc),d7

	clr.l	(a1)			; Nummer des zu bearbeitenden Punktes
	

do_n_z_ag:
	tst.b	(a4)+
	bne	z_nv_skip
	move.l	a4,-(a7)
	move.l	d7,-(a7)

	lea	z_nvanz(pc),a1
	move	anzfl(pc),d7
	clr.l	(a1)
	lea	z_nv_x(pc),a3
	move.l	objvert6_p(pc),a1

	clr.l	(a3)+			; z_nv_x
	clr.l	(a3)+			; z_nv_y
	clr.l	(a3)+			; z_nv_z


z_nv_ag2:
	move.l	z_nv_act(pc),d0
z_nv_ag1:				; Kommt Pkt in dieser Flaeche vor?
	move.l	a1,a3
	cmp	(a3)+,d0
	beq.s	z_nv_w1
	cmp	(a3)+,d0
	beq.s	z_nv_w1
	cmp	(a3)+,d0
	beq.s	z_nv_w1

	addq.l	#6,a1			; nope
	dbf	d7,z_nv_ag1		; naexter Vertex
	bra.s	z_nv_done

z_nv_w1:				; yup, daher den NV d. Fl. berechnen
	move.l	d7,-(a7)

	bsr.w	nv_do

	move.l	#$8000,d1
.c:	cmp.l	d1,d6
	blt.s	.a
.d:	asr.l	#1,d6			; Ist groesser als $8000
	asr.l	#1,d5			; kleinerer parallelvektor
	asr.l	#1,d7
	bra.s	.c
.a:	cmp.l	d1,d5
	bge.s	.d
	cmp.l	d1,d7
	bge.s	.d

z_nv_n1:
	neg.l	d1
.c:	cmp.l	d1,d6
	bge.s	.a
.d:	asr.l	#1,d6			; Ist groesser als $8000
	asr.l	#1,d5			; kleinerer parallelvektor
	asr.l	#1,d7
	bra.s	.c
.a:	cmp.l	d1,d5
	blt.s	.d
	cmp.l	d1,d7
	blt.s	.d

.f:	movem.l	d5-d7,-(a7)
	muls	d6,d6			; cx	Normalvektor
	muls	d5,d5			; cy
	muls	d7,d7			; cz
	add.l	d5,d6
	add.l	d7,d6
	cmp.l	#((nor_laenge-2)*(nor_laenge-2))*$10000/16,d6	; |laenge|^2
	blt.s	.e
	movem.l	(a7)+,d5-d7
	asr.l	#1,d6			; kleinerer Parallelvektor
	asr.l	#1,d5
	asr.l	#1,d7
	bra.s	.f

.e:	movem.l	(a7)+,d5-d7
	

	bsr.w	normalize_n

	lea	z_nv_x(pc),a6
	add.l	d6,(a6)+		; z_nv_x
	add.l	d5,(a6)+		; z_nv_y
	add.l	d7,(a6)+		; z_nv_z
	addq.l	#1,(a6)+		; z_nvanz

	move.l	(a7)+,d7
	dbf	d7,z_nv_ag2

z_nv_done:
	move.l	z_nv_x(pc),d6
	move.l	z_nv_y(pc),d5
	move.l	z_nv_z(pc),d7
	move.l	z_nvanz(pc),d0
	bne.s	z_nv_w2
					; Punkt, der zu keiner Flaeche gehoert!
	moveq	#100,d6			; => irgendwelche dummy werte
	moveq	#100,d5
	moveq	#100,d7
	bra.s	z_nv_w3

z_nv_w2:
	divs	d0,d6			; Dividiert durch die Anzahl der
	divs	d0,d5			; beteiligten Flaechen
	divs	d0,d7

z_nv_w3:
	bsr.w	normalize_n

	move.l	z_nv_act(pc),d0
	add	(a2,d0.l),d6		; Richtungsvektor+Ortvektor X
	add	2(a2,d0.l),d5		; Richtungsvektor+Ortvektor Y
	add	4(a2,d0.l),d7		; Richtungsvektor+Ortvektor Z

	exg	d5,d6
	movem	d5-d7,(a0)

	move.l	(a7)+,d7
	move.l	(a7)+,a4

z_nv_skip:
	addq.l	#6,a0

	lea	z_nv_act(pc),a3
	addq.l	#6,(a3)			; naexter Punkt
	dbf	d7,do_n_z_ag

	rts

z_nv_act:	dc.l	0

z_nv_x:	dc.l	0
z_nv_y:	dc.l	0
z_nv_z:	dc.l	0
z_nvanz:	dc.l	0

;-----
; Normalvektor der Flaeche berechnen

nv_do:	move	(a1)+,d6
	movem	(a2,d6.w),d0/d1/d2
	move	(a1)+,d6
	movem	(a2,d6.w),d3/d4/d5

	sub	d3,d0			; ax - Erster Richtungsvektor
	sub	d4,d1			; ay
	sub	d5,d2			; az

	move	(a1)+,d6
	movem	(a2,d6.w),a3/a4/a5

	sub	a3,d3			; bx - Zweiter Richtungsvektor
	sub	a4,d4			; by
	sub	a5,d5			; bz

	move	d4,d7			; by - Kreuzprodukt=Normalvektor
	move	d5,d6			; bz
	muls	d1,d5			; ay*bz
	muls	d2,d4			; az*by
	sub.l	d4,d5			; cx=(ay*bz)-(az*by)
	exg	d5,d6			; d6=cx, d5=bz
	muls	d0,d5			; ax*bz
	muls	d3,d2			; bx*az
	sub.l	d2,d5			; (ax*bz)-(az*bx)
	neg.l	d5			; d5=cy
	muls	d0,d7			; ax*by
	muls	d3,d1			; bx*ay
	sub.l	d1,d7			; d7=cz=(ax*by)-(ay*bx)
	rts

;--- Vektor auf Laenge normalisieren

normalize_n:
	movem	d5-d7,-(a7)

	muls	d6,d6			; cx	Normalvektor
	muls	d5,d5			; cy
	muls	d7,d7			; cz
	add.l	d5,d6
	add.l	d7,d6

	moveq	#0,d1
					; Auf |laenge|=128 normalisieren
					; (x*r)^2+(y*r)^2+(z*r)^2
					; |laenge|^2=r^2*(x^2+y^2+z^2)
nlize_2:cmp.l	#nor_laenge*nor_laenge,d6
	bgt.s	nlize_1

	tst.l	d6
	bne.s	.a
	moveq	#1,d6

.a:	lsl.l	#2,d6			; *8
	addq.l	#1,d1
	bra.s	nlize_2

nlize_1:
	move.l	#((nor_laenge-2)*(nor_laenge-2))*$10000,d0	; |laenge|^2
	divs.l	d6,d0			; (128*128)/(x^2+y^2+z^2)=r^2

	move.l	d0,d5
	cmp.l	#$ffff,d5
	bgt.s	z_nv_9
					; <1
	swap	d5
	bsr.w	do_sqrt
	move.l	d7,d0
	bra.s	z_nv_10

z_nv_9:	clr	d5			; Nachkommateil loeschen und
	swap	d5			; nur Vorkommateil radizieren
	bsr.w	do_sqrt

	swap	d7
	move.l	d7,d0

z_nv_10:movem	(a7)+,d5-d7

	lsl.l	d1,d6
	lsl.l	d1,d5
	lsl.l	d1,d7

	muls.l	d0,d6
	muls.l	d0,d5
	muls.l	d0,d7
	swap	d6
	swap	d5
	swap	d7
	ext.l	d6
	ext.l	d5
	ext.l	d7
	rts
