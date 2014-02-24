	move	max_delta_x(pc),d1
	ble.s	ps256_nxtfl

	move.l	llength(pc),d6
	move.l	ps16_ltt_p(pc),a1

	move.l	#$1d2b0000,d0

	subq.l	#2,a1
	move.l	t3_const(pc),d2		; xxxxYYyy
	lea	smc_end(pc),a3
	move.l	t3_const+4(pc),d7	; yy0000XX
	moveq	#0,d5
	moveq	#0,d3

.ps16_rap:
	move	d5,d0			; yy.yy
	addx.l	d2,d5			; .xxxx|yy.yy
	move.b	d3,d0			; XX.
	move.l	d0,-(a3)
	addx.l	d7,d3			; yy0000XX.

	dbf	d1,.ps16_rap

	move	#xsize,d2
	lea	smc_end(pc),a4

ps_o3o_1:
	movem.l	(a1)+,d0/d1/d3/d5	; d0 li x	; d1 re x
					; d3 li x map	; d5 li y map
;	swap	d0			; li x
;	swap	d1			; re x
;	swap	d3			; xxxx.00XX
;	ror.l	#8,d5			; 00YY.yyyy -> yy00YY.yy

	lsr	#subpixel,d0
	lsr	#subpixel,d1

	lsl.l	#8,d5
	sub	d1,d0			; li-re (neg. laenge)
	bpl.s	.ps256_nxtl

	move.b	d3,d5
	lea	(a0,d1.w),a6
	lea	(a2,d5.w),a3
	
.fux:	jmp	(a4,d0.w*4)

;	dc.l	$4efb0520		; jmp	(pc,d0.w*4,(smc_end).w)
;	dc.w	(smc_end)-(.fux+2)

.ps256_nxtl:
	add	d2,a0
	dbf	d6,ps_o3o_1
	bra.s	ps256_nxtfl
