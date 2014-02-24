; 'camera' ist der Ortsvektor, von dem aus das Objekt betrachtet wird.

camera:	dc	0,0,0		; x,y,z Kamera-Position
cmra_yz:dc	0,0,0		; x,y,z (um die Y Axe, in die YZ Ebene hinein)

calc_camera:
	lea	camera(pc),a0

	movem	(a0),d5-d7
	muls	d5,d5
	muls	d6,d6
	muls	d7,d7

	add.l	d6,d5
	add.l	d7,d5

	bsr	do_sqrt
;	asr	#subpixel,d7

	lea	z_add(pc),a2
	add	#auge*2^subpixel,d7
	move	d7,(a2)			; Entfernung vom Kamerapunkt

	lea	rotangle(pc),a1
	move	#$400,d7
	lea	angtab(pc),a2

	move	(a0),d0			; x
	move	4(a0),d1		; z
	bsr.w	do_winkely		; Um die Y Achse
	add	d0,d0
	and	#$1ffe,d0
	move	d0,2(a1)

	bsr.s	c_roty

	movem	cmra_yz+2(pc),d0-d1	; yz
	bsr.s	do_winkelx		; Um die X Achse
	add	d0,d0
	and	#$1ffe,d0
	move	d0,(a1)
	rts

;--- Die Kamera (den Ortsvektor) in die YZ-Ebene drehen, um den Winkel fuer
;    die Rotation um die X-Achse bestimmen zu koennen.

c_roty:
	lea	cmra_yz(pc),a5

	move	2(a1),d6		; Rotation um y
	move.l	sinp(pc),a6		; sinus
	lea	abcdefghi(pc),a4
	lea	$800(a6),a3		; cosinus

	move	(a6,d6.w),d2		;sin(yw)
	move	(a3,d6.w),d3		;cos(yw)

	move	d2,(a4)			; g = cos(yw)
	move	d3,2(a4)		; i=cos(xw)*cos(yw) = cos(yw)
	neg	d2
	move	d3,4(a4)		; a=cos(yw)*cos(zw) = cos(yw)
	move	d2,6(a4)			; c = -sin(yw)

	movem	(a0),d0-d2
	move	d0,d3
	move	d2,d5
	muls	(a4)+,d0		; g
	muls	(a4)+,d2		; i
	muls	(a4)+,d3		; a
	muls	(a4),d5			; c
	add.l	d0,d2
	add.l	d3,d5
	add.l	d2,d2
	add.l	d5,d5
	swap	d2
	swap	d5
	move	d5,(a5)+
	move	d1,(a5)+
	move	d2,(a5)
	rts

;---


;     90
;    \1|2/
;    0\|/3
;  0 --X-- 180 Z+
;    7/|\4
;    /6|5\
;     270
;      Y-
;
; Oktanten 2,3,4,5 koennen gar nicht vorkommen, da vorher schon um die
; Y Achse rotiert wurde. (-> keine pos. Z Koord.)

do_winkelx:
	tst	d0
	bne.s	do_xw1
	tst	d1
	bne.s	do_xw1
	moveq	#0,d0
	rts

do_xw1:	neg	d1

	tst	d0		; Y neg?
	bmi.s	wx_4567

	cmp	d0,d1
	bgt.s	wx_0
				; Oktant 1/2
	mulu	d7,d1
	divu	d0,d1
	move	(a2,d1.w*2),d0
	neg	d0
	add	d7,d0
	rts

wx_0:	mulu	d7,d0		; Oktant 0/3
	divu	d1,d0
	move	(a2,d0.w*2),d0
	rts

wx_23:
	moveq	#0,d0
	rts

wx_4567:
	neg	d0
	
	cmp	d0,d1
	bgt.s	wx_7
				; Oktant 6/5
	mulu	d7,d1
	divu	d0,d1
	move	(a2,d1.w*2),d0
	neg	d0
	add	d7,d0
	bra.s	wx_7w

wx_7:	mulu	d7,d0		; Oktant 7/4
	divu	d1,d0
	move	(a2,d0.w*2),d0
wx_7w:	neg	d0
	add	#$1000,d0
	rts

;---

;     180
;    \4|3/
;    5\|/2
;270 --X-- 90 X+
;    6/|\1
;    /7|0\
;      0
;      Z-

do_winkely:
	tst	d0
	bne.s	do_yw1
	tst	d1
	bne.s	do_yw1
	moveq	#0,d0
	rts

do_yw1:
	neg	d0

	tst	d1		; Z neg oder 0?
	ble.s	wy_0167		; ja? sprung!

	tst	d0		; X neg?
	bmi.s	wy_45

	cmp	d0,d1
	bgt.s	wy_3

	mulu	d7,d1
	divu	d0,d1
	move	(a2,d1.w*2),d0
	add	d7,d0
	rts

wy_3:	mulu	d7,d0
	divu	d1,d0
	move	(a2,d0.w*2),d0
	neg	d0
	add	#$800,d0
	rts

wy_45:	neg	d0
	cmp	d0,d1
	bgt.s	wy_4

	mulu	d7,d1
	divu	d0,d1
	move	(a2,d1.w*2),d0
	neg	d0
	add	#$c00,d0
	rts

wy_4:	mulu	d7,d0
	divu	d1,d0
	move	(a2,d0.w*2),d0
	add	#$800,d0
	rts

wy_0167:neg	d1
	tst	d0		; X neg?
	bmi.s	wy_67

	cmp	d0,d1
	bgt.s	wy_0		; wenn Z >, springen

	mulu	d7,d1		; Oktant 1
	divu	d0,d1
	move	(a2,d1.w*2),d0
	neg	d0
	add	d7,d0
	rts

wy_0:	mulu	d7,d0		; Oktant 0
	divu	d1,d0
	move	(a2,d0.w*2),d0
	rts

wy_67:	neg	d0
	cmp	d0,d1
	bgt.s	wy_7
				; Oktant 6
	mulu	d7,d1
	divu	d0,d1
	move	(a2,d1.w*2),d0
	neg	d0
	add	d7,d0
	bra.s	wy_7w

wy_7:	mulu	d7,d0		; Oktant 7
	divu	d1,d0
	move	(a2,d0.w*2),d0
wy_7w:	neg	d0
	add	#$1000,d0
	rts

angtab:	;incbin	"//incs/angtabdiff"
	include	"i/angtabdiff.i"
