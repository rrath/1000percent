	move	fog_min(pc),d7
	move.l	fog_dist(pc),d6

	sub	d7,d0
	sub	d7,d1
	sub	d7,d2

	swap	d0
	swap	d1
	swap	d2

	clr	d0
	clr	d1
	clr	d2

	divs.l	d6,d0			; z1
	divs.l	d6,d1			; z2
	divs.l	d6,d2			; z3

	lea	tfogcmp(pc),a6
	lea	254.w,a4
	clr	(a6)

	subq.l	#1,d0
	subq.l	#1,d1
	subq.l	#1,d2

	cmp.l	a4,d0
	bls.s	.c1
	not	(a6)
	bra.s	.w1
.c1:	cmp.l	a4,d1
	bls.s	.c2
	not	(a6)
	bra.s	.w1
.c2:	cmp.l	a4,d2
	bls.s	.w1
	not	(a6)

.w1:
	addq.l	#1,d0
	addq.l	#1,d1
	addq.l	#1,d2

	tst	(a6)
	bne	.w7
	bsr	init_gtmap
	jmp	(a3)
.w7:

	move.l	d2,d6
	move.l	#255*$10000,a4
	move.l	divtab_p(pc),a6
	sub	d0,d6			; delta z13

	tst.l	ps16_stat(pc)
	beq.w	.l132_12
	bmi.s	.l13_23
					; rechts 2 linien
	move.l	d1,d7
	sub	d0,d7

	move.l	clip_sum(pc),d5

	tst.l	clip_stat(pc)
	beq.s	.w2

	muls	(a6,d5.l*2),d7
	move.l	clip_1st(pc),d5
	muls	(a6,d5.l*2),d6
	bra.s	.w3

.w2:	muls	(a6,d5.l*2),d6
	move.l	clip_1st(pc),d5
	muls	(a6,d5.l*2),d7

.w3:	bsr	fog_ps_do_lt_a1
	bsr	calc_const_g

	move.l	d4,d3
	ble.s	.wda2			; unten flach

	move.l	d2,d7
	sub	d1,d7			; z23
	move.l	clip_2nd(pc),d5
	swap	d1
	muls	(a6,d5.l*2),d7
	move.l	d1,a1
	add.l	d7,d7

	bra	fog_ps_do_lt2
;-
.l13_23:				; oben flach
	move.l	clip_1st(pc),d5

	tst.l	clip_upli(pc)
	bne.s	.wupc
	tst.l	clip_upre(pc)
	bne.s	.wupc

	move.l	d2,d7
	sub	d1,d7			; z23
	muls	(a6,d5.l*2),d6
	muls	(a6,d5.l*2),d7

	swap	d0
	swap	d1
	add.l	d6,d6
	add.l	d7,d7
	move.l	d1,a1
	bsr	calc_const_g
	bra	fog_ps_do_lt

.wda2:	rts

.wupc:	tst.l	ps16_stat+4(pc)
	beq.s	.wl
	
	move.l	d2,d7
	sub	d1,d7			; z23
	muls	(a6,d5.l*2),d7
	move.l	clip_sum(pc),d5
	muls	(a6,d5.l*2),d6
	bra.s	.wr

.wl:	move.l	d1,d6
	move.l	d1,d7

	sub	d2,d6			; z32
	sub	d0,d7			; z12

	muls	(a6,d5.l*2),d6
	move.l	clip_sum(pc),d5
	move.l	d0,d1
	move.l	d2,d0
	muls	(a6,d5.l*2),d7

.wr:	swap	d0
	swap	d1
	add.l	d6,d6
	add.l	d7,d7
	move.l	d1,a1

	move.l	d6,d1
	move.l	d7,d2
	muls.l	clip_upli(pc),d1
	muls.l	clip_upre(pc),d2
	sub.l	d1,d0
	sub.l	d2,a1
	bsr	calc_const_g
	bra.s	fog_ps_do_lt
;-
.l132_12:				; links 2 linien
	move.l	d1,d7
	move.l	clip_1st(pc),d5
	sub	d0,d7			; delta z12
	muls	(a6,d5.l*2),d6
	move.l	clip_sum(pc),d5
	muls	(a6,d5.l*2),d7

	bsr.s	fog_ps_do_lt_a1
	bsr	calc_const_g

	move.l	d1,d6
	move.l	d4,d3
	ble.s	.wda2
	
	sub	d2,d6			; z32
	move.l	clip_2nd(pc),d5
	move.l	d2,d0
	muls	(a6,d5.l*2),d6
	swap	d0
	add.l	d6,d6

	bra.s	fog_ps_do_lt2

;------

tfogcmp:	dc	0

fog_ps_do_lt_a1:
	swap	d0
	add.l	d6,d6
	add.l	d7,d7
	move.l	d0,a1

	move.l	clip_upli(pc),d5
	beq.s	fog_ps_do_lt
	move.l	d1,-(a7)
	move.l	d2,-(a7)
	move.l	d6,d1
	move.l	d7,d2
	muls.l	d5,d1
	muls.l	d5,d2
	sub.l	d1,d0
	sub.l	d2,a1
	move.l	(a7)+,d2
	bra.s	fpdl

fog_ps_do_lt:
	move.l	d1,-(a7)
fpdl:
	move.l	d0,lix_rex_mx_my+16
	move.l	d6,addvalues+16
	move.l	a1,lix_rex_mx_my+20
	move.l	d7,addvalues+20

	move.l	d6,d1
	mulu.l	d3,d1
	add.l	d1,d0			; d0 = li

	move.l	d7,d1
	mulu.l	d3,d1
	add.l	d1,a1			; a1 = re

	move.l	(a7)+,d1
	rts

fog_ps_do_lt2:
	move.l	d0,lix_rex_mx_my2+16
	move.l	d6,addvalues2+16
	move.l	a1,lix_rex_mx_my2+20
	move.l	d7,addvalues2+20
	rts
