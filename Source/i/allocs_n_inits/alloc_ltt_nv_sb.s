; Normalvektoren(2d), Screenbuffer und Edgetable allokieren

alloc_ltt_nv_sb:
	bsr.w	ps16_alloc_ltt		; Platz fuer Linientracetabelle reserv.
	bne.s	ps16_no_pub_mem
	bsr.s	nvekxy_alloc
	bne.s	ps16_npm0
	bsr.s	ps16_sb_alloc
	beq.s	ps16_npm1

ps16_na_w1:
	moveq	#0,d0
	rts

ps16_npm1:
	bsr.s	nvekxy_free
ps16_npm0:
	bsr.w	ps16_ltt_free
ps16_no_pub_mem:
	moveq	#-1,d0
	rts

;----

; Platz fuer Phong/Env Koords (2d) allokieren.

nvekxy_p:	dc.l	0

nvekxy_size:	dc.l	0

nvekxy_alloc:
	moveq	#0,d0
	move	anzpkt(pc),d0
	addq.l	#1,d0
	lsl.l	#4,d0			; Vom Normalvek nur x.w,y.w benoetigt
	lea	nvekxy_size(pc),a0
	move.l	d0,(a0)
	bsr	gen_allocpublic
	beq.s	ps16_failed
	lea	nvekxy_p(pc),a0
	move.l	d0,(a0)
	moveq	#0,d0
	rts

nvekxy_free:
	move.l	nvekxy_p(pc),a1
	move.l	nvekxy_size(pc),d0
	bra	gen_free

ps16_failed:
	moveq	#-1,d0
	rts

;-----
; Screenbuffer allokieren.

ps16_sb_alloc:
	move	xsize_scr(pc),d0
	lsr	#3,d0			; xsize/8
	mulu	ysize_scr(pc),d0	; xsize/8*ysize
	lsl.l	#3,d0			; xsize/8*ysize*8

	lea	ps16_sbuf_size(pc),a0
	move.l	d0,(a0)

	bsr	gen_allocpublic
	beq.s	.ps16_sb_f
	lea	ps16_sbuf(pc),a0
	move.l	d0,(a0)
.ps16_sb_f:
	tst.l	d0
	rts

ps16_sb_free:
	move.l	ps16_sbuf_size(pc),d0
	move.l	ps16_sbuf(pc),a1
	bra	gen_free

ps16_sbuf:	dc.l	0
ps16_sbuf_size:	dc.l	0

;-----
; Platz fuer Linetracetab allokieren.

ps16_alloc_ltt:
	move	ysize_scr(pc),d0

	IFD	precision
;		mulu	#6*4*2,d0		; 6.l pro Zeile * 2 (li&re)
		mulu	#6*4,d0			; 6.l pro Zeile (li&re)
	ELSE
;	mulu	#4*4*2,d0		; 4.l pro Zeile * 2 (li&re)
	mulu	#4*4,d0			; 4.l pro Zeile (li&re)
	ENDC
	
	lea	ps16_ltt_size(pc),a0
	move.l	d0,(a0)
	bsr	gen_allocpublic
	beq	ps16_failed

	lea	ps16_ltt_p(pc),a0
	move.l	d0,(a0)

	moveq	#0,d0
	rts

ps16_ltt_free:
	move.l	ps16_ltt_p(pc),a1
	move.l	ps16_ltt_size(pc),d0
	bra	gen_free
;--

		cnop	0,4

ps16_ltt_size:	dc.l	0
ps16_ltt_p:	dc.l	0		; Ptr auf folgende Struktur
					; (ysize_scr mal)...

;		dc.l	0			; li x
;		dc.l	0			; re x
;		dc.l	0			; li x map
;		dc.l	0			; li y map
;		IFD	precision
;		dc.l	0			; re x map
;		dc.l	0			; re y map
;		ENDC
