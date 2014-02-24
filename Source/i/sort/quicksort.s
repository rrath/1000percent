do_sort:
	move.l	koordxyz_p(pc),a4	; auf die erste Z-koord zeigen
	move.l	datendp(pc),a1	; Ende der Tabelle
	move.l	datenp(pc),a0	; Datenfeld
	addq.l	#4,a4
	subq.l	#4,a1

; Quicksort
; a0 = links array
; a1 = rechts array

quicksort:
					; a0 i	; a1 j	; a2 l	; a3 r
	move.l	a1,d4
	move.l	a0,a2
	sub.l	a0,d4
	move.l	a1,a3

	lsr.l	#3,d4
	move.l	(a0,d4.l*4),d4
	move	(a4,d4.w),d4

.while1:
	move.l	(a0)+,d5
	cmp	(a4,d5.w),d4
	blt.s	.while1
	subq.l	#4,a0

	addq.l	#4,a1
.while2:
	move.l	-(a1),d6
	cmp	(a4,d6.w),d4
	bgt.s	.while2

.if:	cmp.l	a0,a1
	blt.s	.until

	move.l	d6,(a0)+
	move.l	d5,(a1)
	subq.l	#4,a1

.until:	cmp.l	a0,a1
	bge.s	.while1

	cmp.l	a1,a2
	bge.s	.w1

	move.l	a0,-(a7)
	move.l	a3,-(a7)
	move.l	a2,a0
	bsr.s	quicksort
	move.l	(a7)+,a3
	move.l	(a7)+,a0

.w1:	cmp.l	a0,a3
	ble.s	.w2

	move.l	a3,a1
	bra.s	quicksort

.w2:	rts
