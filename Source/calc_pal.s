;	lea	obj4cols(pc),a0
;	lea	obj2cols2(pc),a1
;	moveq	#16,d4
;	move.l	#110,d5
;	bsr	calc_pal
;	rts
;
;obj2cols:
;	DC.B	$01,$11,$00,$00,$04,$01,$00,$B7
;	DC.B	$05,$12,$00,$37,$06,$23,$00,$B7
;	DC.B	$07,$44,$07,$3B,$08,$45,$03,$F7
;	DC.B	$08,$66,$0F,$33,$0A,$77,$0F,$33
;	DC.B	$0C,$89,$03,$73,$0D,$9B,$03,$F3
;	DC.B	$0E,$BC,$03,$37,$0F,$CD,$07,$77
;	DC.B	$0F,$DE,$0F,$BB,$0F,$ED,$07,$3B
;	DC.B	$0F,$FE,$0F,$7B,$0F,$FF,$0F,$FF
;obj4cols:
;	DC.B	$00,$00,$00,$00,$01,$12,$0C,$70
;	DC.B	$02,$22,$08,$1D,$02,$23,$09,$83
;	DC.B	$03,$33,$01,$1E,$04,$34,$08,$EF
;	DC.B	$05,$45,$0F,$AB,$06,$56,$0B,$B3
;	DC.B	$07,$67,$07,$E0,$08,$78,$0A,$D3
;	DC.B	$09,$89,$0F,$CB,$0B,$9B,$03,$E0
;	DC.B	$0C,$BC,$09,$28,$0D,$CD,$01,$41
;	DC.B	$0E,$DD,$09,$0C,$0F,$FF,$0F,$FF
;
;obj3cols:
;	DC.B	$01,$11,$00,$00,$03,$46,$00,$00
;	DC.B	$03,$57,$00,$00,$04,$68,$00,$00
;	DC.B	$05,$78,$00,$00,$06,$89,$00,$00
;	DC.B	$07,$9A,$00,$00,$08,$9A,$00,$00
;	DC.B	$09,$AB,$00,$00,$0A,$BB,$00,$00
;	DC.B	$0B,$CB,$00,$00,$0C,$DC,$00,$00
;	DC.B	$0D,$DC,$00,$00,$0E,$ED,$00,$00
;	DC.B	$0F,$FE,$0F,$F0,$0F,$FF,$0F,$FF
;
;obj2cols2:
;	dcb.l	256,0

; a0 = Pointer auf Source-Colordaten ( dc.w 0RGB,0rgb )
; a1 = Pointer auf Destination-Colordaten
; d4 = Anzahl der Sourcefarben
; d5 = Anzahl der Destinationfarben
; d4<d5
; d5 max 256
; d4 min 3

calc_pal:
	lea	calc_pal_dummy(pc),a6
	movem.l	d4/d5/a0/a1,(a6)

	move.l	d4,d6
	lea	calc_pal_source(pc),a2
	subq.l	#1,d6
	move.l	a2,a3

.a:	moveq	#0,d0
	move	(a0)+,d0
	move	(a0)+,d1
	move.l	d0,d2
	move.l	d1,d3
	and	#$f00,d2
	and	#$f00,d3
	lsr	#4,d2
	lsr	#8,d3
	or	d3,d2
	swap	d2
	move.l	d2,(a2)+

	move.l	d0,d2
	move.l	d1,d3
	and	#$0f0,d2
	and	#$0f0,d3
	lsr	#4,d3
	or	d3,d2
	swap	d2
	move.l	d2,(a2)+

	move.l	d0,d2
	move.l	d1,d3
	and	#$00f,d2
	and	#$00f,d3
	lsl	#4,d2
	or	d3,d2
	swap	d2
	move.l	d2,(a2)+
	dbf	d6,.a

;--

	lea	calc_pal_dest(pc),a4
	moveq	#3-1,d0

.g:	move.l	d0,-(a7)
	move.l	d4,d0
	move.l	d5,d1
	subq.l	#1,d0
	divs	d0,d1
	move.l	a3,a5
	ext.l	d1
	move.l	a4,a2
	addq.l	#1,d1
	move	d1,d7
	mulu	d0,d7
	subq.l	#1,d0

.d:	move.l	(a5),d2
	move.l	3*4(a5),d3
	sub.l	d2,d3
	divs.l	d1,d3
	move.l	d1,d6
	subq.l	#1,d6

.c:	move.l	d2,(a2)+
	add.l	d3,d2
	addq.l	#8,a2
	dbf	d6,.c
	lea	12(a5),a5
	dbf	d0,.d

.f:	addq.l	#4,a3
	addq.l	#4,a4
	move.l	(a7)+,d0
	dbf	d0,.g

;--

	lea	calc_pal_dest(pc),a3
	swap	d7
	moveq	#0,d4
	clr	d7
	moveq	#0,d6
	divs.l	d5,d7

	subq.l	#1,d5

.b:	move	(a3,d4.w),d0
	move.l	d0,d1
	and	#$f0,d0
	and	#$f,d1
	lsl	#4,d0
	lsl	#8,d1
	move	4(a3,d4.w),d2
	move.l	d2,d3
	and	#$f0,d2
	and	#$f,d3
	or	d2,d0
	lsl	#4,d3
	or	d3,d1
	move	8(a3,d4.w),d2
	move.l	d2,d3
	and	#$f0,d2
	and	#$f,d3
	lsr	#4,d2
	or	d3,d1
	or	d2,d0
	move	d0,(a1)+
	move	d1,(a1)+
	add.l	d7,d6
	move.l	d6,d4
	swap	d4
	mulu	#12,d4
	dbf	d5,.b
	rts

calc_pal_dummy:		dc.l	0,0,0,0
calc_pal_source:	dcb.l	256*3,0
calc_pal_dest:		dcb.l	256*3*2,0
