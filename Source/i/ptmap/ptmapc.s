	move.l	a7,a5
	move.l	llength(pc),d3		; Laenge 1.Stueck -1
	move.l	llength2(pc),d4		; Laenge 2.Stueck -1
	addq.l	#1,d3	
	addq.l	#1,d4
	move.l	clip_sum(pc),d7
	move.l	d3,d5			; d3 = 1. Stueck ; d4 = 2. Stueck
	sub.l	clip_1st(pc),d7
	add.l	d4,d5			; d5 = d3 + d4
	move.l	d7,clip_2nd
;-
	move.l	g_stack(pc),a7
	bsr	init_ptmap

	move.l	12(a5),a7
	move.l	t3_const_g+4+2(pc),d5	; uuuu....
	move.l	t3_const(pc),d4		; xxxxYYyy
	move	t3_const_bf(pc),d5	; uuuu00XX
	move.l	t3_const+4(pc),d1	; yy0000XX
	move	t3_const_g(pc),a3	; 0000VVvv
	move	t3_const_g+4(pc),d1	; yy0000UU
	lea	gouraudtab,a5
	move.l	d1,t3_const_p

.ps256_fill_line:
	move	lix_rex_mx_my(pc),d0
	move	lix_rex_mx_my+4(pc),d7
	asr	#subpixel,d0
	asr	#subpixel,d7

	cmp	#xsize,d0
	bge	.ps256_nxtl		; Rechts draussen
	tst	d7
	bmi	.ps256_nxtl		; Links draussen

	cmp	#xsize,d7
	blt.s	.b
	move	#xsize-1,d7
.b:

	sub	d0,d7
	ble.w	.ps256_nxtl

	move.l	t3_const_p(pc),d1
	move.l	lix_rex_mx_my+8(pc),d2
	move	d7,a1
	move.l	lix_rex_mx_my+16(pc),d6	; map li y 00VVvvvv
	move.l	lix_rex_mx_my+20(pc),d7	; map li x 00UUuuuu
	lsr.l	#8,d6
	move.l	lix_rex_mx_my+12(pc),d3
	move.l	d6,a4

	tst	d0
	bpl.s	.c
	add	d0,a1

	move.l	d4,a6
	move.l	a3,d6
	ext.l	d0
	move.l	t3_const_bf(pc),d4
	muls.l	d0,d4
	muls.l	d0,d6
	sub.l	d4,d2
	move.l	t3_const_g+4(pc),d4
	sub.l	d6,a4
	muls.l	d0,d4
	muls.l	t3_const_bf+4(pc),d0
	sub.l	d4,d7
	sub.l	d0,d3

	move.l	a6,d4
	move.l	a4,d6
	moveq	#0,d0

.c:	lea	(a0,d0.w),a6

	move.l	d2,d0			; 00XXxxxx
	lsl.l	#8,d3			; YYyyyy00
	move	d7,d2			; 00XXuuuu
	move	d3,d7			; 00UUyy00
	move	d0,d3			; YYyyxxxx

	swap	d2			; uuuu00XX
	move.l	d5,d0			; uuuu00XX add
	swap	d7			; yy0000UU
	clr	d0			; uuuu0000 add
	swap	d3			; xxxxYYyy

	add.l	d0,d2

	moveq	#0,d0
	move	d3,d0
	move.b	d7,d6
	move.b	d2,d0

.a:	addx.l	d1,d7			; yy0000UU
	move	(a7,d6.l),d6
	addx.l	d4,d3			; xxxxYYyy
	addx.l	d5,d2			; uuuu00XX
	move.b	(a2,d0.l),d6
	subq.l	#1,a1
	move	d3,d0
	add.l	a3,a4			; 0000VVvv
	move.b	(a5,d6.l),(a6)+
	move	a4,d6
	move.b	d2,d0
	move.b	d7,d6
	tst.l	a1
	bgt.s	.a

.ps256_nxtl:
	movem.l	addvalues(pc),d0-d3/d6-d7
	lea	lix_rex_mx_my(pc),a6
	lea	xsize(a0),a0
	add.l	d0,(a6)+
	add.l	d1,(a6)+
	add.l	d2,(a6)+
	add.l	d3,(a6)+
	add.l	d6,(a6)+
	add.l	d7,(a6)
	
	subq.l	#1,llength
	bpl.w	.ps256_fill_line

	lea	llength2(pc),a6
	move.l	(a6),d6
	bmi.s	.q

	move.l	d6,llength
	movem.l	addvalues2(pc),d0-d3/d6-d7
	not.l	(a6)
	movem.l	d0-d3/d6-d7,addvalues
	movem.l	lix_rex_mx_my2(pc),d0-d3/d6-d7
	movem.l	d0-d3/d6-d7,lix_rex_mx_my
	bra	.ps256_fill_line

.q:	clr.l	clip_stat
	bra	ps256_nxtfl
