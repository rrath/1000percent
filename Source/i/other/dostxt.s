;---------------------------

print_txt:
	move.l	a0,-(a7)

	lea	dosname(pc),a1
	moveq	#0,d0
	move.l	4.w,a6
	jsr	-552(a6)		; openlib
	lea	dosb(pc),a0
	move.l	d0,(a0)
	beq.s	noprint

	move.l	dosb(pc),a6
	jsr	-60(a6)			; output
	lea	outputh(pc),a0
	move.l	d0,(a0)

	move.l	(a7),d2			; buffer
	move.l	d2,a0
	moveq	#0,d3

prts:	addq	#1,d3
	tst.b	(a0)+
	beq.s	prtl
	bra.s	prts

prtl:	subq	#1,d3
	move.l	dosb(pc),a6
	move.l	outputh(pc),d1
	jsr	-48(a6)			; write

	move.l	dosb(pc),a1
	move.l	4.w,a6
	jsr	-414(a6)		; closelib
	
noprint:move.l	(a7)+,a0
	rts

dosb:	dc.l	0
outputh:dc.l	0

dosname:
	dc.b	'dos.library',0
	even

;---------------------------
