	move	4(a7),d4			; xwidth
	move	6(a7),d5			; ywidth

	move	8(a7),d0			; x1
	move	10(a7),d1			; y1

	move	8+4(a7),d2			; x4
	move	10+4(a7),d3			; y4

	asr	#subpixel,d0
	asr	#subpixel,d2

	cmp	#xsize,d0
	bge	ps256_nxtfl		; Rechts draussen
	tst	d2
	bmi	ps256_nxtfl		; Links draussen
	cmp	ysize_scr(pc),d1
	bge	ps256_nxtfl		; Unten draussen
	tst	d3
	bmi	ps256_nxtfl		; Oben draussen

	add.l	([ytab_p.w,pc],d1.w*4),a0	; d1 y

	moveq	#0,d7
	cmp	#xsize,d2
	blt.s	.w
	move.l	d2,d7
	sub	#xsize-1,d7
.w:
	moveq	#0,d6
	cmp	ysize_scr(pc),d3
	blt.s	.w2
	move.l	d3,d6
	sub	ysize_scr(pc),d6
	addq.l	#1,d6
.w2:

	sub	d0,d2				; delta x
	ble	ps256_nxtfl
	sub	d1,d3				; delta y
	ble	ps256_nxtfl

	move.l	(12+2)*4(a7),a2

	muls	(a5,d2.w*2),d4
	muls	(a5,d3.w*2),d5
	sub.l	a5,a5
	add.l	d4,d4
	add.l	d5,d5

	sub	d7,d2
	sub	d6,d3

	tst	d1
	bpl.s	.w4
	add	d1,d3
	neg	d1
	move.l	ps16_sbuf(pc),a0
	ext.l	d1
	muls.l	d5,d1
	bra.s	.w5
.w4:	moveq	#0,d1
.w5:
	tst	d0
	bpl.s	.w3
	add	d0,d2
	neg	d0
	move.l	d4,d7
	ext.l	d0
	muls.l	d0,d7
	moveq	#0,d0
	move.l	d7,a5
.w3:	add	d0,a0

	move.l	d5,a6
	moveq	#0,d5

.a	move.l	d1,d7
	move.l	d2,d6
	swap	d7

	mulu	4(a7),d7
	move.l	a0,a4
	lea	(a2,d7.l),a3
	move.l	a5,d7

.ag	move.l	d7,d0
	swap	d0
	add.l	d4,d7
	move.b	(a3,d0.w),d5
	beq.s	.wx
	move.b	d5,(a4)
.wx	addq.l	#1,a4
;	dbf	d6,.ag
	subq	#1,d6
	bpl.s	.ag

	add.l	a6,d1
	lea	xsize(a0),a0	
;	dbf	d3,.a
	subq	#1,d3
	bpl.s	.a

	bra	ps256_nxtfl
