	move.l	t3_const_bf(pc),d4
	move.l	t3_const_bf+4(pc),d5

	lsl.l	#8,d4			; XXxxxx00
	lsr.l	#8,d5			; 0000YYyy

	move.l	llength(pc),d6
	move.l	addvalues+12(pc),a7

	move	d5,d4			; XXxxYYyy

	movem.l	lix_rex_mx_my(pc),a1/a3/a4/a5
	moveq	#0,d5

.ps256_fill_line:
	move.l	a1,d0			; li x
	move.l	a3,d1			; re x
	move.l	a4,d2
	move.l	a5,d3

	lsr.l	#subpixel,d0
	lsr.l	#subpixel,d1

	swap	d0
	swap	d1

	sub	d0,d1
	ble.s	.ps256_nxtl

	lsl.l	#8,d2			; XXxxxx00
	lsr.l	#8,d3			; 0000YYyy

	lea	(a0,d0.w),a6

	move	d3,d2			; XXxxYYyy

	moveq	#0,d0

	move.l	d2,d3
	move	d2,d0
	rol.l	#8,d3
	add.l	d4,d2
	move.b	d3,d0
	move.b	(a2,d0.l),d7
	move.l	d2,d3
	move	d2,d0

	lsr	#1,d1
	bcc.b	.c2

	move.b	d7,(a6)+

	move.l	d2,d3
	move	d2,d0
	rol.l	#8,d3
	add.l	d4,d2
		add.l	d4,d2
	move.b	d3,d0
	move.b	(a2,d0.l),d7

	move.l	d2,d3
	move	d2,d0
	bra.s	.c

.a:	rol.l	#8,d3
	add.l	d4,d2
	move.b	d3,d0
	add.l	d4,d2
	moveq	#0,d3
	move.b	(a2,d0.l),d5

	move.b	d7,d3
	add.l	d5,d3
	lsl.l	#8,d7
	lsr.l	#1,d3
	move.b	d3,d7

	move.l	d2,d3
	move	d2,d0
	move	d7,(a6)+

	move.b	d5,d7

.c:	dbf	d1,.a

.ps256_nxtl:
	lea	addvalues(pc),a6
	lea	xsize(a0),a0
	add.l	(a6)+,a1
	add.l	(a6)+,a3
	add.l	(a6),a4
	add.l	a7,a5
	dbf	d6,.ps256_fill_line

	lea	llength2(pc),a6
	move.l	(a6),d6
	bmi	ps256_nxtfl

	movem.l	addvalues2(pc),a1/a3/a4/a7
	not.l	(a6)
	movem.l	a1/a3/a4,addvalues

	movem.l	lix_rex_mx_my2(pc),a1/a3/a4/a5
	bra	.ps256_fill_line

.c2:	add.l	d4,d2
	dbf	d1,.a
	bra.s	.ps256_nxtl
