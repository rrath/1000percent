
	bsr.w	do_calctab

	move	#64,nth_fact

	moveq	#60-1,d7
	lea	nth_map,a5
	moveq	#0,d5
	bsr.s	do_nth

	move.l	#'scx!',poetrndseed
	move.l	#'byte',poetrndseed+4
	move	#0,nth_fact
	moveq	#60-1,d7
	lea	nth_map2,a5
	moveq	#1,d5
	bsr.s	do_nth

;	moveq	#40-1,d7
;	lea	nth_map3,a5
;	moveq	#2,d5
;	bsr.s	do_nth2
;
;	moveq	#40-1,d7
;	lea	nth_map4,a5
;	moveq	#3,d5
;	bsr.s	do_nth2

	lea	nth_map,a0
	lea	nth_map2,a1
	lea	nth_map3,a2
	lea	nth_map4,a3

	lea	nth_map1,a4
	moveq	#-1,d7
cp
	moveq	#0,d0
	moveq	#0,d1
	moveq	#0,d2

	move.b	(a0)+,d0
	move.b	(a1)+,d1
	move.b	(a2)+,d2
	move.b	(a3)+,d3

;	add	d2,d2
;	sub	d1,d2
;	sub	d0,d2
	cmp.b	#128,d0
	blt.s	.a
	sub	#128,d0
	add	#128,d1
	
.a:	sub	d0,d1

	move.b	d1,(a4)+
	dbf	d7,cp
	rts


;----------------------

nth_rnd:bsr	_X1_PoetRND
	and	#$ff,d0
	move	d0,(a1)+
	rts


nthmax	=	256

; d5 = n-th (n=0..3)
; d7 = Anzahl der Rndpunkte - 1
; a5 = ptr auf map

nth_fact:	dc	0

do_nth:	move.l	d7,d6
	lea	nth_coords,a1

.a:	bsr.s	nth_rnd
	bsr.s	nth_rnd
	bsr.s	nth_rnd
	and	#3,d0
	muls	nth_fact(pc),d0
	move	d0,-2(a1)
	dbf	d6,.a
;-
do_nth2:
	move.l	circtab_p(pc),a0

	sub.l	a2,a2
	sub.l	a3,a3

.w1:
	lea	nth_coords,a4
	move.l	a2,d0
	move.l	a3,d1
	move	#$7fff,d4
	move	d7,d6

	lea	nth_1_4(pc),a6
	move	#$7fff,d2
	move	d2,2(a6)
	move	d2,2+4(a6)
	move	d2,2+4*2(a6)
	move	d2,2+4*3(a6)

.w2:	move	(a4)+,d2
	move	(a4)+,d3
	move	(a4)+,d4
	bsr.s	.chk
	dbf	d6,.w2

	move.b	nth_1_4+1(pc,d5.w*4),d4
	move.b	nth_1_4+3(pc,d5.w*4),(a5)
	add.b	d4,(a5)+

	addq.l	#1,a2
	cmp	#256,a2
	bne.s	.w1
	addq.l	#1,a3
	sub.l	a2,a2
	cmp	#256,a3
	bne.s	.w1
	rts

; d0/d1 = x1/y1
; d2/d3 = x2/y2
; <- d3 = distance
.chk:	sub	d0,d2
	sub	d1,d3
	muls	d2,d2
	muls	d3,d3
	add.l	d2,d3
	move	(a0,d3.l*2),d3

	pea	(a0)
	move.l	a6,a0
	lea	16-4(a6),a1

.s2w:	cmp	2(a0),d3
	bgt.s	.s1
.s1w:	cmp.l	a0,a1
	beq.s	.s2
	move.l	-4(a1),(a1)
	subq.l	#4,a1
	bra.s	.s1w
.s2:	move	d4,(a0)
	move	d3,2(a0)
	bra.s	.sq
.s1:	cmp.l	a0,a1
	beq.s	.sq
	addq.l	#4,a0
	bra.s	.s2w

.sq:
	move.l	(a7)+,a0
	rts

nth_1_4:	dcb	2*4,0		; coloffset, distance

;---------------------

do_calctab:
	move.l	circtab_p(pc),a0
	add.l	#363*363*2,a0
	move	#363-1,d0
.a:	move	d0,d1
	add	d1,d1
.b:	move	d0,-(a0)
	dbf	d1,.b
	dbf	d0,.a
	rts


circtab_p:	dc.l	circtab


_X1_PoetRND:
	movem.l	d1/a0,-(sp)
	lea	PoetRNDSeed(pc),a0
	movem.l	(a0),d0/d1
	eor.l	d1,d0
	ror.l	#3,d0
	rol	#2,d1
	swap	d1
	ror	#1,d1
	add	d0,d1
	movem.l	d0/d1,(a0)
	movem.l	(sp)+,d1/a0
	rts
PoetRNDSeed:
	dc.l "scx!","byte"

;---
circtab:	ds	363*363

;---

nth_coords:	ds	nthmax*3

nth_map:	dcb.b	256*256,0
nth_map2:	dcb.b	256*256,0
nth_map3:	dcb.b	256*256,0
nth_map4:	dcb.b	256*256,0

nth_map1:	dcb.b	256*256,0
