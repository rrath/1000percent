init_ytab:
	move	ysize_scr(pc),d0
	mulu	#4,d0
	bsr.w	gen_allocpublic
	beq.s	yt_fail

	lea	ytab_p(pc),a0
	move.l	d0,(a0)

	move.l	d0,a0
	move	ysize_scr(pc),d7
	move	xsize_scr(pc),d1
	subq	#1,d7
	asr	#3,d1			; xsize/8
	mulu	plnr_scr(pc),d1		; xsize/8*plnr

	moveq	#0,d0
iy:	move.l	d0,(a0)+
	add.l	d1,d0
	dbf	d7,iy

	moveq	#0,d0
	rts
yt_fail:
	moveq	#2,d0
	rts

ytab_p:	dc.l	0

;---

free_ytab:
	move.l	ytab_p(pc),a1
	move	ysize_scr(pc),d0
	mulu	#4,d0
	bra.w	gen_free
