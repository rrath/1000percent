	move.l	t3_const(pc),d4
	move.l	t3_const+4(pc),d5
	move.l	addtab_p(pc),a5
	movem.l	lix_rex_mx_my(pc),a1/a3/a4/a7

.ps256c_fill_line:
	move.l	a1,d0
	move.l	a3,d1
	move.l	a4,d2
	move.l	a7,d3

	asr.l	#subpixel,d0
	asr.l	#subpixel,d1

	swap	d0
	swap	d1

	cmp	#xsize,d0
	bge.s	.ps256c_nxtl		; Rechts draussen
	tst	d1
	bmi.s	.ps256c_nxtl		; Links draussen

	cmp	#xsize,d1
	blt.s	.b
	move	#xsize,d1
.b:
	sub	d0,d1
	ble.s	.ps256c_nxtl

	ror.l	#8,d3			; yy00YYyy
	swap	d2			; xxxx00XX
	move.l	d3,a6
	move	d2,d3			; yy0000XX <-
	move	a6,d2			; xxxxYYyy <-

	tst	d0
	bpl.s	.c
	add	d0,d1
	not	d0
.ps16c_fl3:
	addx.l	d4,d2
	addx.l	d5,d3
	dbf	d0,.ps16c_fl3

	moveq	#0,d0

.c:	lea	(a0,d0.w),a6

	moveq	#0,d0
	moveq	#0,d7
	move	d2,d0
	move.b	d3,d0

	lsr	#1,d1
	bcc.b	.d

	move	(a6),d7
	addx.l	d4,d2
	addx.l	d5,d3
	move.b	(a2,d0.l),d7
	move.b	(a5,d7.l),(a6)+
	move	d2,d0
	move.b	d3,d0
	bra.s	.d

.a:	move	(a6),d7
	addx.l	d4,d2
	addx.l	d5,d3
	move.b	(a2,d0.l),d7

	move	d2,d0
	move	(a5,d7.l),d6
	move.b	d3,d0
	move	1(a6),d7
	addx.l	d4,d2
	addx.l	d5,d3
	move.b	(a2,d0.l),d7

	move	d2,d0
	move.b	(a5,d7.l),d6
	move.b	d3,d0
	move	d6,(a6)+

.d:	dbf	d1,.a

.ps256c_nxtl:
	lea	addvalues(pc),a6
	lea	xsize(a0),a0
	add.l	(a6)+,a1
	add.l	(a6)+,a3
	add.l	(a6)+,a4
	add.l	(a6),a7
	subq.l	#1,llength
	bpl	.ps256c_fill_line

	lea	llength2(pc),a6
	move.l	(a6),d6
	bmi	ps256_nxtfl

	movem.l	addvalues2(pc),a1/a3/a4/a7
	not.l	(a6)
	move.l	d6,llength
	movem.l	a1/a3/a4/a7,addvalues

	movem.l	lix_rex_mx_my2(pc),a1/a3/a4/a7
	bra	.ps256c_fill_line
