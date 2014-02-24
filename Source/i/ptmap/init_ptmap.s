	move	(a5),d0			; x1
	move	2(a5),d1		; y1

	move	8(a5),d4		; x3
	move	8+2(a5),d5		; y3

	sub	d0,d4			; delta x13
	sub	d1,d5			; delta y13

	move.l	divtab_p(pc),a6

	tst.l	ps16_stat(pc)
	beq.s	.l132_12
	bmi.w	.l13_23
					; rechts 2 linien
	move	4(a5),d2
	move	4+2(a5),d3

	move.l	clip_sum(pc),d6

	sub	d0,d2			; delta x12
	sub	d1,d3			; delta y12

	tst.l	clip_stat(pc)
	beq.s	.w2

	muls	(a6,d6.l*2),d2		; li
	muls	(a6,d6.l*2),d3
	move.l	clip_1st(pc),d6
	muls	(a6,d6.l*2),d4		; re
	muls	(a6,d6.l*2),d5
	bra.s	.w3

.w2:	muls	(a6,d6.l*2),d4		; li
	muls	(a6,d6.l*2),d5
	move.l	clip_1st(pc),d6
	muls	(a6,d6.l*2),d2		; re
	muls	(a6,d6.l*2),d3

.w3:	bsr.w	pt_ps_do_lt_a1
	bsr.w	calc_const_p

	move.l	llength2(pc),d6
	bge	pt_ps_do_lt2
.wda2:	rts				; unten flach
;-
.l132_12:				; links 2 linien
	move	4(a5),d2
	move	4+2(a5),d3

	move.l	clip_sum(pc),d6

	sub	d0,d2			; delta x12
	sub	d1,d3			; delta y12

	muls	(a6,d6.l*2),d2		; re
	muls	(a6,d6.l*2),d3
	move.l	clip_1st(pc),d6
	muls	(a6,d6.l*2),d4		; li
	muls	(a6,d6.l*2),d5

	bsr.w	pt_ps_do_lt_a1
	bsr.w	calc_const_p

	move.l	llength2(pc),d6
	blt.s	.wda2
	
	move.l	clip_2nd(pc),d6
	move	4(a5),d4
	move	4+2(a5),d5
	move	8(a5),d0
	move	8+2(a5),d1
	
	sub	d0,d4			; delta x32
	sub	d1,d5			; delta y32

	swap	d0
	swap	d1

	muls	(a6,d6.l*2),d4		; re
	muls	(a6,d6.l*2),d5

	clr	d0
	clr	d1

	add.l	d4,d4
	add.l	d5,d5
	bra.w	pt_ps_do_lt2

.l13_23:				; oben flach
	move.l	clip_1st(pc),d6

	tst.l	clip_upli(pc)
	bne.s	.wupc
	tst.l	clip_upre(pc)
	bne.s	.wupc

	move	4(a5),d7

	move	8(a5),d2		; x3
	move	8+2(a5),d3		; y3

	sub	d7,d2			; delta x23
	sub	4+2(a5),d3		; delta y23

	muls	(a6,d6.l*2),d2
	muls	(a6,d6.l*2),d3

	swap	d7
	swap	d0
	swap	d1
	clr	d7
	clr	d0
	clr	d1
	move.l	d7,a1
	move	4+2(a5),d7
	swap	d7
	muls	(a6,d6.l*2),d4
	clr	d7
	muls	(a6,d6.l*2),d5
	move.l	d7,a3

	bsr.w	calc_const_p
	bra.w	pt_ps_do_lt

.wupc:	tst.l	ps16_stat+4(pc)
	beq.s	.wl

	move	4(a5),d7

	move	8(a5),d2		; x3
	move	8+2(a5),d3		; y3

	sub	d7,d2			; delta x23
	sub	4+2(a5),d3		; delta y23
	swap	d7

	muls	(a6,d6.l*2),d2
	muls	(a6,d6.l*2),d3
	move.l	clip_sum(pc),d6
	clr	d7
	muls	(a6,d6.l*2),d4
	muls	(a6,d6.l*2),d5
	move.l	d7,a1
	move	4+2(a5),d7
	swap	d7
	clr	d7
	move.l	d7,a3
	bra.s	.wr

.wl:	swap	d0
	swap	d1
	clr	d0
	clr	d1
	move.l	d0,a1
	move.l	d1,a3

	move	8(a5),d0
	move	8+2(a5),d1

	move	4(a5),d4
	move	4+2(a5),d5
	move.l	d4,d2
	move.l	d5,d3

	sub	d0,d4
	sub	d1,d5
	sub	(a5),d2
	sub	2(a5),d3

	muls	(a6,d6.l*2),d4
	muls	(a6,d6.l*2),d5
	move.l	clip_sum(pc),d6
	muls	(a6,d6.l*2),d2
	muls	(a6,d6.l*2),d3

.wr:	swap	d0
	swap	d1
	clr	d0
	clr	d1

	add.l	d4,d4			; li
	add.l	d5,d5
	add.l	d2,d2			; re
	add.l	d3,d3

	move.l	d4,d6
	move.l	d5,d7
	muls.l	clip_upli(pc),d6
	muls.l	clip_upli(pc),d7
	sub.l	d6,d0
	sub.l	d7,d1

	move.l	d2,d6
	move.l	d3,d7
	muls.l	clip_upre(pc),d6
	muls.l	clip_upre(pc),d7
	sub.l	d6,a1
	sub.l	d7,a3
	bsr.w	calc_const_p

	move.l	llength(pc),d6
	addq.l	#1,d6
	bra.s	pt_pdl2


;-------

pt_ps_do_lt_a1:
	move.l	llength(pc),d6
	swap	d0
	swap	d1
	clr	d0
	clr	d1
	move.l	d0,a1
	move.l	d1,a3
	addq.l	#1,d6

	move.l	clip_upli(pc),d7
	beq.s	pt_ps_do_lt
	add.l	d4,d4			; li
	add.l	d5,d5
	add.l	d2,d2			; re
	add.l	d3,d3
	move.l	d6,-(a7)

	move.l	d4,d6
	muls.l	d7,d6
	sub.l	d6,d0
	move.l	d5,d6
	muls.l	d7,d6
	sub.l	d6,d1

	move.l	d2,d6
	muls.l	d7,d6
	sub.l	d6,a1
	move.l	d3,d6
	muls.l	d7,d6
	sub.l	d6,a3
	
	move.l	(a7)+,d6
	bra.s	pt_pdl2

pt_ps_do_lt:
	add.l	d4,d4			; li
	add.l	d5,d5
	add.l	d2,d2			; re
	add.l	d3,d3
pt_pdl2:
	move.l	d1,lix_rex_mx_my+16	; V
	move.l	d0,lix_rex_mx_my+20	; U

	move.l	d5,addvalues+16
	move.l	d4,addvalues+20

	move.l	d4,d7
	muls.l	d6,d7
	add.l	d7,d0			; d0 = U li

	move.l	d5,d7
	muls.l	d6,d7
	add.l	d7,d1			; d1 = V li


	move.l	d2,d7
	muls.l	d6,d7
	add.l	d7,a1			; a1 = U re

	move.l	d3,d7
	muls.l	d6,d7
	add.l	d7,a3			; a3 = V re

	rts

pt_ps_do_lt2:
	move.l	d1,lix_rex_mx_my2+16
	move.l	d0,lix_rex_mx_my2+20
	move.l	d5,addvalues2+16
	move.l	d4,addvalues2+20
	rts

;-----

calc_const_p:
	move.l	a3,d7
	move.l	a1,d6
	sub.l	d1,d7			; re V - li V
	sub.l	d0,d6			; re U - li U

	divs.l	max_delta_x-2(pc),d7
	divs.l	max_delta_x-2(pc),d6
	asr.l	#8,d7
	move.l	d6,t3_const_g+4
	move	d7,t3_const_g
	rts
