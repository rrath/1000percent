; d0.w	chunkyx [chunky-pixels]
; d1.w	chunkyy [chunky-pixels]
; d2.w	(scroffsx) [screen-pixels]
; d3.w	scroffsy [screen-pixels]
; d4.w	(rowlen) [bytes] -- offset between one row and the next in a bpl
; d5.l	bplsize [bytes] -- offset between one row in one bpl and the next bpl

c2p1x1_8_c5_040_init
	move.l	d3,-(sp)
	mulu.w	d0,d3
	lsr.l	#3,d3
	move.l	d3,c2p1x1_8_c5_040_scroffs
	mulu.w	d0,d1
	move.l	d1,c2p1x1_8_c5_040_pixels
	move.l	d5,c2p1x1_8_c5_040_bplsize
	move.l	(sp)+,d3
	rts

; a0	c2pscreen
; a1	bitplanes

c2p1x1_8_c5_040
	movem.l	d2-d7/a2-a6,-(sp)

	move.l	c2p1x1_8_c5_040_bplsize(pc),a3
	add.l	c2p1x1_8_c5_040_scroffs(pc),a1
	lea	(a1,a3.l*8),a1
	sub.l	a3,a1

	move.l	c2p1x1_8_c5_040_pixels(pc),a4
	tst.l	a4
	beq.w	.none
	add.l	a0,a4

	move.l	(a0)+,d0
	move.l	(a0)+,d1
	move.l	(a0)+,d2
	move.l	(a0)+,d3
	move.l	(a0)+,d4
	move.l	(a0)+,d5
	move.l	(a0)+,d6
	move.l	(a0)+,a2

	swap	d4
	swap	d5
	eor.w	d0,d4
	eor.w	d1,d5
	eor.w	d4,d0
	eor.w	d5,d1
	eor.w	d0,d4
	eor.w	d1,d5
	swap	d4
	swap	d5

	move.l	d4,d7
	lsr.l	#2,d7
	eor.l	d0,d7
	and.l	#$33333333,d7
	eor.l	d7,d0
	lsl.l	#2,d7
	eor.l	d7,d4
	move.l	d5,d7
	lsr.l	#2,d7
	eor.l	d1,d7
	and.l	#$33333333,d7
	eor.l	d7,d1
	lsl.l	#2,d7
	eor.l	d7,d5

	exg	d5,a2

	swap	d6
	swap	d5
	eor.w	d2,d6
	eor.w	d3,d5
	eor.w	d6,d2
	eor.w	d5,d3
	eor.w	d2,d6
	eor.w	d3,d5
	swap	d6
	swap	d5

	move.l	d6,d7
	lsr.l	#2,d7
	eor.l	d2,d7
	and.l	#$33333333,d7
	eor.l	d7,d2
	lsl.l	#2,d7
	eor.l	d7,d6
	move.l	d5,d7
	lsr.l	#2,d7
	eor.l	d3,d7
	and.l	#$33333333,d7
	eor.l	d7,d3
	lsl.l	#2,d7
	eor.l	d7,d5

	move.l	d1,d7
	lsr.l	#4,d7
	eor.l	d0,d7
	and.l	#$0f0f0f0f,d7
	eor.l	d7,d0
	lsl.l	#4,d7
	eor.l	d7,d1
	move.l	d3,d7
	lsr.l	#4,d7
	eor.l	d2,d7
	and.l	#$0f0f0f0f,d7
	eor.l	d7,d2
	lsl.l	#4,d7
	eor.l	d7,d3
	bra.w	.start
.x
	move.l	(a0)+,d0
	move.l	(a0)+,d1
	move.l	(a0)+,d2
	move.l	(a0)+,d3
	move.l	(a0)+,d4
	move.l	(a0)+,d5
	move.l	(a0)+,d6
	tst.l	(a0)

	move.l	d7,(a1)
	swap	d4
	swap	d5
	sub.l	a3,a1
	eor.w	d0,d4
	eor.w	d1,d5
	eor.w	d4,d0
	eor.w	d5,d1
	eor.w	d0,d4
	eor.w	d1,d5
	swap	d4
	swap	d5

	move.l	d4,d7
	lsr.l	#2,d7
	eor.l	d0,d7
	and.l	#$33333333,d7
	eor.l	d7,d0
	lsl.l	#2,d7
	eor.l	d7,d4
	move.l	d5,d7
	lsr.l	#2,d7
	move.l	a2,(a1)
	eor.l	d1,d7
	sub.l	a3,a1
	and.l	#$33333333,d7
	eor.l	d7,d1
	lsl.l	#2,d7
	eor.l	d7,d5
	move.l	d5,a2
	move.l	(a0)+,d5

	swap	d6
	swap	d5
	eor.w	d2,d6
	eor.w	d3,d5
	eor.w	d6,d2
	eor.w	d5,d3
	eor.w	d2,d6
	eor.w	d3,d5
	swap	d6
	swap	d5

	move.l	d6,d7
	lsr.l	#2,d7
	eor.l	d2,d7
	move.l	a5,(a1)
	and.l	#$33333333,d7
	sub.l	a3,a1
	eor.l	d7,d2
	lsl.l	#2,d7
	eor.l	d7,d6
	move.l	d5,d7
	lsr.l	#2,d7
	eor.l	d3,d7
	and.l	#$33333333,d7
	eor.l	d7,d3
	lsl.l	#2,d7
	eor.l	d7,d5

	move.l	d1,d7
	lsr.l	#4,d7
	eor.l	d0,d7
	and.l	#$0f0f0f0f,d7
	eor.l	d7,d0
	lsl.l	#4,d7
	eor.l	d7,d1
	move.l	d3,d7
	move.l	a6,(a1)+
	lsr.l	#4,d7
	lea	(a1,a3.l*8),a1
	eor.l	d2,d7
	sub.l	a3,a1
	and.l	#$0f0f0f0f,d7
	eor.l	d7,d2
	lsl.l	#4,d7
	eor.l	d7,d3
.start
	move.l	d2,d7
	lsr.l	#8,d7
	eor.l	d0,d7
	and.l	#$00ff00ff,d7
	eor.l	d7,d0
	lsl.l	#8,d7
	eor.l	d7,d2
	move.l	d2,d7
	lsr.l	#1,d7
	eor.l	d0,d7
	and.l	#$55555555,d7
	eor.l	d7,d0
	move.l	d0,(a1)
	add.l	d7,d7
	sub.l	a3,a1
	eor.l	d7,d2
; d0,d2 done				; d0 = bpl7, d2 = bpl6
	move.l	a2,d0

	move.l	d0,d7
	lsr.l	#4,d7
	eor.l	d4,d7
	and.l	#$0f0f0f0f,d7
	eor.l	d7,d4
	lsl.l	#4,d7
	eor.l	d7,d0
	move.l	d5,d7
	lsr.l	#4,d7
	eor.l	d6,d7
	and.l	#$0f0f0f0f,d7
	eor.l	d7,d6
	lsl.l	#4,d7
	eor.l	d7,d5

	move.l	d6,d7
	move.l	d2,(a1)
	lsr.l	#8,d7
	sub.l	a3,a1
	eor.l	d4,d7
	and.l	#$00ff00ff,d7
	eor.l	d7,d4
	lsl.l	#8,d7
	eor.l	d7,d6
	move.l	d6,d7
	lsr.l	#1,d7
	eor.l	d4,d7
	and.l	#$55555555,d7
	eor.l	d7,d4
	add.l	d7,d7
	eor.l	d7,d6
; d4,d6 done				; d4 = bpl5, d6 = bpl4

	move.l	d3,d7
	lsr.l	#8,d7
	eor.l	d1,d7
	move.l	d4,(a1)
	and.l	#$00ff00ff,d7
	sub.l	a3,a1
	eor.l	d7,d1
	lsl.l	#8,d7
	eor.l	d7,d3
	move.l	d3,d7
	lsr.l	#1,d7
	eor.l	d1,d7
	and.l	#$55555555,d7
	eor.l	d7,d1
	add.l	d7,d7
	eor.l	d7,d3
; d1,d3 done				; d1 = bpl3, d3 = bpl2

	move.l	d5,d7
	lsr.l	#8,d7
	eor.l	d0,d7
	and.l	#$00ff00ff,d7
	eor.l	d7,d0
	lsl.l	#8,d7
	move.l	d6,(a1)
	eor.l	d7,d5
	sub.l	a3,a1
	move.l	d5,d7
	lsr.l	#1,d7
	eor.l	d0,d7
	and.l	#$55555555,d7
	eor.l	d7,d0
	add.l	d7,d7
	eor.l	d7,d5
; d0,d5 done				; d0 = bpl1, d5 = bpl0
	move.l	d1,d7
	move.l	d3,a2
	move.l	d0,a5
	move.l	d5,a6

	cmp.l	a0,a4
	bne	.x

	move.l	d7,(a1)
	sub.l	a3,a1
	move.l	a2,(a1)
	sub.l	a3,a1
	move.l	a5,(a1)
	sub.l	a3,a1
	move.l	a6,(a1)+
	lea	(a1,a3.l*8),a1
	sub.l	a3,a1

.none	movem.l	(sp)+,d2-d7/a2-a6
	rts

	cnop	0,4

c2p1x1_8_c5_040_bplsize:	dc.l	0
c2p1x1_8_c5_040_scroffs:	dc.l	0
c2p1x1_8_c5_040_pixels:		dc.l	0
