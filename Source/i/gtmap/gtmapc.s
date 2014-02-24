	moveq	#0,d0
	moveq	#0,d1
	moveq	#0,d2
	move	(a7)+,d0		; z1
	move	(a7)+,d1		; z2
	move	(a7),d2			; z3
	move.l	llength(pc),d3
	move.l	llength2(pc),d4
	move.l	clip_sum(pc),d7
	addq.l	#1,d3
	sub.l	clip_1st(pc),d7
	addq.l	#1,d4
	move.l	d7,clip_2nd

;-
	move.l	g_stack(pc),a7
	bsr	init_gtmap

	lea	gouraudtab,a5
gtmapc_do:
	move.l	t3_const(pc),d4
	move.l	t3_const+4(pc),d5
	move	t3_const_g(pc),a3

.ps256c_fill_line:
	move	lix_rex_mx_my(pc),d0
	move	lix_rex_mx_my+4(pc),d1
	asr	#subpixel,d0
	asr	#subpixel,d1

	cmp	#xsize,d0
	bge	.ps256c_nxtl		; Rechts draussen
	tst	d1
	bmi	.ps256c_nxtl		; Links draussen

	cmp	#xsize,d1
	blt.s	.b
	move	#xsize,d1
.b:
	sub	d0,d1
	ble	.ps256c_nxtl

	move.l	lix_rex_mx_my+16(pc),d6
	move.l	lix_rex_mx_my+8(pc),d2
	lsr.l	#8,d6
	move.l	lix_rex_mx_my+12(pc),d3
	move.l	d6,a4

	tst	d0
	bpl.s	.c
	add	d0,d1

	move.l	d4,a6
	ext.l	d0

	move.l	t3_const_bf(pc),d4
	move.l	a3,d7
	muls.l	d0,d4
	muls.l	d0,d7
	muls.l	t3_const_bf+4(pc),d0
	sub.l	d4,d2
	sub.l	d7,a4
	sub.l	d0,d3
	move.l	a6,d4
	move	a4,d6

	moveq	#0,d0

.c:	ror.l	#8,d3			; yy00YYyy
	swap	d2			; xxxx00XX
	move.l	d3,a6
	move	d2,d3			; yy0000XX <-
	move	a6,d2			; xxxxYYyy <-

	lea	(a0,d0.w),a6

	move.l	d5,d0
	move.l	d1,d7
	clr	d0
	lsr	#1,d1
	add.l	d0,d3

	moveq	#0,d0
	move	d2,d0
	move.b	d3,d0

	btst	#0,d7
	beq.b	.d

	addx.l	d4,d2
	addx.l	d5,d3
	move.b	(a2,d0.l),d6
	move	d2,d0
	add.l	a3,a4
	move.b	(a5,d6.l),d7
	move.b	d3,d0
	move	a4,d6
	move.b	d7,(a6)+
	bra.s	.d

.a:	addx.l	d4,d2
	addx.l	d5,d3
	move.b	(a2,d0.l),d6

	move	d2,d0
	add.l	a3,a4
	move	(a5,d6.l),d7
	move.b	d3,d0
	move	a4,d6
	addx.l	d4,d2
	addx.l	d5,d3
	move.b	(a2,d0.l),d6

	move	d2,d0
	add.l	a3,a4
	move.b	(a5,d6.l),d7
	move.b	d3,d0
	move	a4,d6
	move	d7,(a6)+

.d:	dbf	d1,.a

.ps256c_nxtl:
	movem.l	addvalues(pc),d0-d3/d7
	lea	lix_rex_mx_my(pc),a6
	lea	xsize(a0),a0
	add.l	d0,(a6)+
	add.l	d1,(a6)+
	add.l	d2,(a6)+
	add.l	d3,(a6)+
	add.l	d7,(a6)
	
	subq.l	#1,llength
	bpl.w	.ps256c_fill_line

	lea	llength2(pc),a6
	move.l	(a6),d6
	bmi.s	.q

	movem.l	addvalues2(pc),d0-d3/d7
	not.l	(a6)
	movem.l	d0-d3/d7,addvalues
	movem.l	lix_rex_mx_my2(pc),d0-d3/d7
	move.l	d6,llength
	movem.l	d0-d3/d7,lix_rex_mx_my
	bra	.ps256c_fill_line
.q:
	clr.l	clip_stat
	bra	ps256_nxtfl
