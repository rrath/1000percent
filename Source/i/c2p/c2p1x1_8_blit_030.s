c2p1x1_8_blit_030:
	lea	thissour(pc),a5
	move.l	(a0)+,(a5)+
	move.l	(a0)+,(a5)+
	move.l	(a0)+,(a5)+
	move.l	(a0)+,(a5)+
	lea	-16(a0),a0

	move.l	c2p_chip_buf(pc),a5
	move.l	-(a5),d5
;	moveq	#xsize/8,d0
	move	xsize_scr,d0
	move.l	-(a5),d4
	move.l	-(a5),d7
	move.l	#$00ff00ff,a2
	mulu	ysize_scr,d0
	move.l	#$0f0f0f0f,a3
	move.l	#$55555555,a4
	move.l	a3,d6

	lea	(a0,d0.l),a6

.c2p_ag	move.l	(a0)+,d0
	move.l	(a0)+,d1
	move.l	(a0)+,d2
	move.l	(a0)+,d3
	move.l	d7,(a5)+
	move.l	d3,d7
	lsr.l	#4,d7
	eor.l	d2,d7
	and.l	d6,d7
	eor.l	d7,d2
	lsl.l	#4,d7
	eor.l	d7,d3
	move.l	d2,d7
	lsr.l	#8,d7
	move.l	d4,(a5)+
	move.l	d1,d4
	lsr.l	#4,d4
	eor.l	d0,d4
	and.l	d6,d4
	eor.l	d4,d0
	lsl.l	#4,d4
	eor.l	d1,d4
	move.l	a2,d6
	eor.l	d0,d7
	and.l	d6,d7
	eor.l	d7,d0
	lsl.l	#8,d7
	move.l	d5,(a5)+
	eor.l	d7,d2
	move.l	d3,d7
	lsr.l	#8,d7
	eor.l	d4,d7
	and.l	d6,d7
	eor.l	d7,d4
	move.l	a4,d1
	move.l	d2,d5
	lsr.l	#1,d5
	eor.l	d0,d5
	and.l	d1,d5
	eor.l	d5,d0
	move.l	d0,(a5)+
	add.l	d5,d5
	eor.l	d2,d5
	lsl.l	#8,d7
	eor.l	d7,d3
	move.l	d3,d7
	lsr.l	#1,d7
	eor.l	d4,d7
	and.l	d1,d7
	eor.l	d7,d4
	add.l	d7,d7
	eor.l	d3,d7
	move.l	(a0)+,d0
	move.l	(a0)+,d1
	move.l	(a0)+,d2
	move.l	(a0)+,d3
	move.l	d7,(a5)+
	move.l	d2,d7
	lsr.l	#8,d7
	eor.l	d0,d7
	and.l	d6,d7
	eor.l	d7,d0
	lsl.l	#8,d7
	eor.l	d7,d2
	move.l	d3,d7
	lsr.l	#8,d7
	eor.l	d1,d7
	move.l	d4,(a5)+
	and.l	d6,d7
	eor.l	d7,d1
	lsl.l	#8,d7
	eor.l	d7,d3
	move.l	a3,d6
	move.l	d1,d4
	lsr.l	#4,d4
	eor.l	d0,d4
	and.l	d6,d4
	eor.l	d4,d0
	lsl.l	#4,d4
	move.l	d5,(a5)+
	eor.l	d1,d4
	move.l	d3,d7
	lsr.l	#4,d7
	eor.l	d2,d7
	and.l	d6,d7
	eor.l	d7,d2
	move.l	a4,d1
	move.l	d2,d5
	lsr.l	#1,d5
	eor.l	d0,d5
	and.l	d1,d5
	eor.l	d5,d0
	move.l	d0,(a5)+
	add.l	d5,d5
	eor.l	d2,d5
	lsl.l	#4,d7
	eor.l	d7,d3
	move.l	d3,d7
	lsr.l	#1,d7
	eor.l	d4,d7
	and.l	d1,d7
	eor.l	d7,d4
	add.l	d7,d7
	eor.l	d3,d7
	cmpa.l	a0,a6
	bgt.w	.c2p_ag
	move.l	d7,(a5)+
	move.l	d4,(a5)+
	move.l	d5,(a5)+

.a:	tst	blit_st
	bne.s	.a

	lea	$dff002,a6
	wblit

	move	ysize_scr,d0
	lea	blit_pass_pt(pc),a5
	move	xsize_scr,d7
	lsr	#4,d7
	mulu	d7,d0
	lea	blit_pass_tab(pc),a4
	swap	d0
	move.l	a4,(a5)
	addq.l	#1,d0
	lea	blit_l(pc),a5
	lea	thisdest(pc),a4
	move.l	d0,(a5)


	move.l	c2p_chip_buf(pc),d0
	move.l	c2p_chip_buf+4(pc),c2p_chip_buf
	move.l	d0,c2p_chip_buf+4

	move.l	a1,(a4)

	move.l	a1,$54-2(a6)
	move.l	#$000e000e,$62-2(a6)
	clr.w	$0066-2(a6)
	move.w	#$cccc,$70-2(a6)
	moveq	#-1,d7
	addq.l	#6,d0
	move.l	d7,$44-2(a6)
	move.l	d0,$4c-2(a6)
	addi.l	#$0000000e,d0
	move.l	d0,$50-2(a6)
	move.l	#$ede40000,$40-2(a6)
	move.l	blit_l(pc),$5c-2(a6)
	rts

blit_l:		dc.l	0
thisdest:	dc.l	0
thissour:	dcb.b	16,0

blit_pass_tab:	dc.l	b1,b2,b3,b4,b5,b6,b7,0
blit_pass_pt:	dc.l	0

blit_st:	dc.w	0

b1:	move.l	c2p_chip_buf+4(pc),d0
	addi.l	#$0000000a,d0
	move.l	d0,$4c-2(a6)
	addi.l	#$0000000e,d0
	move.l	d0,$50-2(a6)
	move.l	blit_l(pc),$5c-2(a6)
	rts	

b2:	move.l	c2p_chip_buf+4(pc),d0
	addq.l	#4,d0
	move.l	d0,$50-2(a6)
	addq.l	#2,d0
	move.l	d0,$4c-2(a6)
	move.l	#$0de42000,$40-2(a6)
	move.l	blit_l(pc),$5c-2(a6)
	rts	

b3:	move.l	c2p_chip_buf+4(pc),d0
	addq.l	#8,d0
	move.l	d0,$50-2(a6)
	addq.l	#2,d0
	move.l	d0,$4c-2(a6)
	move.l	blit_l(pc),$5c-2(a6)
	rts	

b4:	move.l	c2p_chip_buf+4(pc),d0
	addi.l	#$0000000e,d0
	move.l	d0,$4c-2(a6)
	addi.l	#$0000000e,d0
	move.l	d0,$50-2(a6)
	move.l	#$ede40000,$40-2(a6)
	move.l	blit_l(pc),$5c-2(a6)
	rts	

b5:	move.l	c2p_chip_buf+4(pc),d0
	addq.l	#2,d0
	move.l	d0,$4c-2(a6)
	addi.l	#$0000000e,d0
	move.l	d0,$50-2(a6)
	move.l	blit_l(pc),$5c-2(a6)
	rts

b6:	move.l	c2p_chip_buf+4(pc),d0
	addi.l	#$0000000c,d0
	move.l	d0,$50-2(a6)
	addq.l	#2,d0
	move.l	d0,$4c-2(a6)
	move.l	#$0de42000,$40-2(a6)
	move.l	blit_l(pc),$5c-2(a6)
	rts	

b7:	move.l	c2p_chip_buf+4(pc),d0
	move.l	d0,$50-2(a6)
	addq.l	#2,d0
	move.l	d0,$4c-2(a6)
	move.l	blit_l(pc),$5c-2(a6)

	movem.l	d0-d5/a3/a4,-(a7)
	move.l	thisdest(pc),a3
	lea	thissour(pc),a4
	moveq	#0,d0
	moveq	#0,d1
	moveq	#0,d2
	moveq	#0,d3

	moveq	#16-1,d5

.gaga	move.b	(a4)+,d4
	roxr.b	#1,d4
	roxl	#1,d0
	roxr.b	#1,d4
	roxl	#1,d1

	roxr.b	#3,d4
	roxl	#1,d2

	roxr.b	#1,d4
	roxl	#1,d3
	dbf	d5,.gaga

	move.l	oneplanesize,d4
	move	d0,(a3)
	add.l	d4,a3
	move	d1,(a3)
	add.l	d4,a3
	add.l	d4,a3
	add.l	d4,a3
	move	d2,(a3)
	add.l	d4,a3
	move	d3,(a3)

	movem.l	(a7)+,d0-d5/a3/a4
	rts	

c2p_chip_buf:	dc.l	ax,ay	;dc.l	0,0
