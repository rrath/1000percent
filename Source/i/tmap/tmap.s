	move.l	t3_const(pc),d4
	move.l	t3_const+4(pc),d5
	movem.l	lix_rex_mx_my(pc),a1/a3-a5
	move.l	llength(pc),d6
	move.l	addvalues+12(pc),a7

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

	lea	(a0,d0.w),a6

	ror.l	#8,d3			; yy00YYyy
	swap	d2			; xxxx00XX
	move.l	d3,d7
	move	d2,d3			; yy0000XX <-
	move	d7,d2			; xxxxYYyy <-

	move.l	d5,d0
	move.l	d1,d7
	clr	d0
	lsr	#1,d1
	add.l	d0,d3

	moveq	#0,d0
	move	d2,d0
	move.b	d3,d0

	btst	#0,d7
	beq.s	.c

	addx.l	d4,d2
	addx.l	d5,d3
	move.b	(a2,d0.l),(a6)+
	move	d2,d0
	move.b	d3,d0
	bra.s	.c

.a:	addx.l	d4,d2
	addx.l	d5,d3
	move	(a2,d0.l),d7

	move	d2,d0
	move.b	d3,d0
	addx.l	d4,d2
	addx.l	d5,d3
	move.b	(a2,d0.l),d7

	move	d2,d0
	move.b	d3,d0
	move	d7,(a6)+

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
	bmi.s	.q

	movem.l	addvalues2(pc),a1/a3/a4/a7
	not.l	(a6)
	movem.l	a1/a3/a4,addvalues

	movem.l	lix_rex_mx_my2(pc),a1/a3-a5
	bra	.ps256_fill_line
.q:
