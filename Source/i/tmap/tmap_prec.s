	move.l	llength(pc),d6
	move.l	ps16_ltt_p(pc),a1

.ps256_fill_line:
	movem.l	(a1)+,d0-d5		; d0 li x	; d1 re x
					; d2 li x map	; d3 li y map
					; d4 re x map	; d5 re y map

	asr.l	#subpixel,d0
	asr.l	#subpixel,d1

	clr	d1

	swap	d0
	swap	d1

	sub	d0,d1
	ble.s	.ps256_nxtl

	sub.l	d2,d4
	sub.l	d3,d5

	divs.l	d1,d4
	divs.l	d1,d5

	swap	d4			; .xxxx|00xx.
	ror.l	#8,d5			; yy00|yy.yy

	move.l	d4,a4
	move	d5,d4
	move	a4,d5

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
	beq.b	.c

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
	lea	xsize(a0),a0
	dbf	d6,.ps256_fill_line
