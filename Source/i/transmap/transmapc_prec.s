	move.l	addtab_p(pc),a5
	lea	xsize_scr(pc),a3
	move.l	ps16_ltt_p(pc),a1

.ps256c_fill_line:
	movem.l	(a1)+,d0-d5		; d0 li x	; d1 re x
					; d2 li x map	; d3 li y map
					; d4 re x map	; d5 re y map
	asr.l	#subpixel,d1
	asr.l	#subpixel,d0

	clr	d1
	swap	d0
	swap	d1

	cmp	(a3),d0
	bge	.ps256c_nxtl		; Rechts draussen
	tst	d1
	bmi	.ps256c_nxtl		; Links draussen

	move.l	d1,d7

	sub	d0,d1
	ble	.ps256c_nxtl

	sub.l	d2,d4
	sub.l	d3,d5

	divs.l	d1,d4
	divs.l	d1,d5

	tst	d0
	bpl.s	.c
	add	d0,d1

	move.l	d4,a4
	ext.l	d0
	neg.l	d0
	muls.l	d0,d4
	muls.l	d5,d0

	add.l	d4,d2
	add.l	d0,d3
	move.l	a4,d4

	moveq	#0,d0

.c:	swap	d4			; .xxxx|00xx.
	ror.l	#8,d5			; yy00|yy.yy
	move.l	d4,a4
	move	d5,d4
	move	a4,d5

	ror.l	#8,d3			; yy00YYyy
	swap	d2			; xxxx00XX
	move.l	d3,a4
	move	d2,d3			; yy0000XX <-
	move	a4,d2			; xxxxYYyy <-

	cmp	(a3),d7
	blt.s	.b
	sub	(a3),d7
	sub	d7,d1
.b:
	
	lea	(a0,d0.w),a6

	move.l	d5,d0
	move.l	d1,d6
	clr	d0
	lsr	#1,d1
	add.l	d0,d3

	moveq	#0,d0
	moveq	#0,d7
	move	d2,d0
	move.b	d3,d0

	btst	#0,d6
	beq.b	.d

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
	lea	xsize(a0),a0
	subq.l	#1,llength
	bpl	.ps256c_fill_line

	bra	ps256_nxtfl
