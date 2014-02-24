init_gtmap:
	move.l	d2,d6
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

.w3:	bsr	gt_ps_do_lt_a1
	bsr	calc_const_g

	move.l	d4,d3
	ble.s	.wda2			; unten flach

;	move.l	d2,d7
;	sub	d1,d7			; z23
;	move.l	clip_2nd(pc),d5
;	swap	d1
;	muls	(a6,d5.l*2),d7
;	move.l	d1,a1
;	add.l	d7,d7

	bra	gt_ps_do_lt2
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
	bra	gt_ps_do_lt

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
	bra.s	gt_ps_do_lt
;-
.l132_12:				; links 2 linien
	move.l	d1,d7
	move.l	clip_1st(pc),d5
	sub	d0,d7			; delta z12
	muls	(a6,d5.l*2),d6
	move.l	clip_sum(pc),d5
	muls	(a6,d5.l*2),d7

	bsr.s	gt_ps_do_lt_a1
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

	bra.s	gt_ps_do_lt2

;-------

gt_ps_do_lt_a1:
	swap	d0
	add.l	d6,d6
	add.l	d7,d7
	move.l	d0,a1

	move.l	clip_upli(pc),d5
	beq.s	gt_ps_do_lt
	move.l	d1,-(a7)
	move.l	d2,-(a7)
	move.l	d6,d1
	move.l	d7,d2
	muls.l	d5,d1
	muls.l	d5,d2
	sub.l	d1,d0
	sub.l	d2,a1
	move.l	(a7)+,d2
	bra.s	gt_fpdl

gt_ps_do_lt:
	move.l	d1,-(a7)
gt_fpdl:
	move.l	d0,lix_rex_mx_my+16
	move.l	d6,addvalues+16

	move.l	d6,d1
	mulu.l	d3,d1
	add.l	d1,d0			; d0 = li

	move.l	d7,d1
	mulu.l	d3,d1
	add.l	d1,a1			; a1 = re

	move.l	(a7)+,d1
	rts

gt_ps_do_lt2:
	move.l	d0,lix_rex_mx_my2+16
	move.l	d6,addvalues2+16
	rts

;-----

calc_const_g:
	move.l	a1,d5
	sub.l	d0,d5			; re-li

	divs.l	max_delta_x-2(pc),d5
	asr.l	#8,d5
	move	d5,t3_const_g
	rts
