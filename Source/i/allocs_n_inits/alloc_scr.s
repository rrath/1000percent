; Alloc Mem for Planes and Copperlist, and init the stuff

alloc_scr:
	moveq	#0,d2
	move	xsize_scr(pc),d0
	move	plnr_scr(pc),d2
	move.l	d2,d7

	lsr	#3,d0			; xsize/8
	mulu	ysize_scr(pc),d0	; xsize/8*ysize
	lea	oneplanesize(pc),a0
	move.l	d0,(a0)
	mulu.l	d2,d0			; xsize/8*ysize*plnr = planesize
	lea	planesize(pc),a0
	move.l	d0,(a0)

	move.l	#cliste-clist,d1	; copsize
	moveq	#1,d6
	lsl.l	d7,d6			; Anzahl Farben bei plnr Planes
	move.l	d6,d7
	lsl.l	#3,d6			; *8 ( 4 Bytes cmove low + 4 hi)
	lsr.l	#5,d7			; div32
	lsl.l	#3,d7			; mul8
	bne.s	.al_s1
	moveq	#8,d7

.al_s1:
	add.l	d6,d7

	lea	ccol_size(pc),a0
	move.l	d7,(a0)

	add.l	d7,d1

	tst	half_scr(pc)
	beq.s	.al_scr1
	moveq	#3*4*2,d2		; der halbierte screen mittels
	mulu	ysize_scr(pc),d2	; zeilen verdoppelung strecken
	add.l	d2,d1

.al_scr1:
	lea	copsize(pc),a0
	move.l	d1,(a0)
	lsl.l	#2,d0			; planesize*4
	add.l	d1,d0			; planesize*4+copsize
	addq.l	#8,d0			; planesize*4+copsize+8

	lea	scr_mem_size(pc),a0
	move.l	d0,(a0)
	bsr.w	gen_allocchip
	lea	scr_mem(pc),a0
	move.l	d0,(a0)
	beq.s	as_fail

	lea	chipmemptr(pc),a0
	move.l	d0,(a0)
	
	bsr.s	initptr			; Planeptr&co initialisieren
	bsr.s	build_clist		; Copperlist ins Chipmem kopieren

	moveq	#0,d0
	rts

as_fail:moveq	#1,d0
	rts

;--- Vars&Ptrs related to the Screen

scr_mem_size:	dc.l	0
scr_mem:	dc.l	0

oneplanesize:	dc.l	0	; (xsize/8)*ysize)
planesize:	dc.l	0	; planesize	=	((xsize/8)*ysize*plnr)
copsize:	dc.l	0	; copsize	=	(cliste-clist)

ccol_size:	dc.l	0	; 2^plnr_scr*8+{ if plnr_scr >=32 then
				;               (2^plnr_scr div 32 * 8) else
				;		8

;----------

free_scr:
	move.l	scr_mem(pc),a1
        move.l  scr_mem_size(pc),d0
	bra	gen_free

;------------------

initptr:
	move.l	chipmemptr(pc),d0
	subq.l	#1,d0
c_iag:	addq.l	#1,d0			;do 64bit alignment
	move.l	d0,d1
	and.b	#7,d1
	bne.s	c_iag

	move.l	planesize(pc),d1

	lea	planeptr1(pc),a0
	moveq	#4-1,d7
c_iag2:	move.l	d0,(a0)+
	add.l	d1,d0
	dbf	d7,c_iag2

	lea	clistptr(pc),a0
	move.l	d0,(a0)

	add.l	copsize(pc),d0

	rts


;-------------------------
;--- Copy CList to Chipmem

build_clist:
	move	ysize_scr(pc),d0
	tst	half_scr(pc)
	bne.s	bcnh
	lsr	#1,d0
bcnh:

	lea	cl_1dc+2(pc),a2
	lea	cl_cint(pc),a3
	lea	clistbfe(pc),a4
	move	#$a9,d1			; Y-Bildmitte
	move	#32,(a2)
	move	#$370f,(a3)
	move.l	#$ffdffffe,(a4)

	IFD	ntsc
	tst	ntsc(pc)
	beq.s	.w2
	move	#$8d+4,d1
	clr	(a2)
	move	#$ff0f,(a3)
	move.l	#$01fe0000,(a4)
.w2:	ENDC

	move	d1,d2
	sub	d0,d1
	add	d0,d2
	lsl	#8,d1
	lsl	#8,d2
	move.b	#$81,d1
	move.b	#$c1,d2
	lea	clwinsz+2(pc),a0
	move	d1,(a0)
	move	d2,4(a0)

;-
	move	plnr_scr(pc),d0
	cmp	#8,d0
	bne.s	.bc1
	move	#$211,d0
	bra.s	.bc2
.bc1:	move	d0,d1
	lsl	#8,d0
	lsl	#4,d0
	add	#$201,d0
.bc2:	lea	canzpl(pc),a0
	move	d0,(a0)

	move.l	clistptr(pc),a0
	lea	clist(pc),a1

	move	#(cl_cols-clist)/4-1,d7
.bccp6:	move.l	(a1)+,(a0)+
	dbf	d7,.bccp6

	add.l	ccol_size(pc),a0

	move	#(clistbfe-cl_cols)/4-1,d7
.bccp1:	move.l	(a1)+,(a0)+
	dbf	d7,.bccp1

;	move.l	#$ffdffffe,(a1)

	tst	half_scr(pc)
	beq.s	bccpw

	move.l	#$01fe0000,(a1)

	move	ysize_scr(pc),d7
	subq	#1,d7

	move	#$a9-1,d0		; Y-Bildmitte-1
	IFD	ntsc
	tst	ntsc(pc)
	beq.s	.w
	move	#$8d+4-1,d0
	ENDC
.w:
	sub	ysize_scr(pc),d0
	lsl	#8,d0
	move.b	#$df,d0
	swap	d0
	move	#$fffe,d0
	
;	move.l	#$28dffffe,d0

	moveq	#-xsize/8,d1
	moveq	#0,d2

bccph:	move.l	d0,(a0)+
	add.l	#$01000000,d0
	move	#$0108,(a0)+
	move	d1,(a0)+
	move	#$010a,(a0)+
	move	d1,(a0)+

	move.l	d0,(a0)+
	add.l	#$01000000,d0
	move	#$0108,(a0)+
	move	d2,(a0)+
	move	#$010a,(a0)+
	move	d2,(a0)+
	dbf	d7,bccph

bccpw:	move	#(cliste-clistbfe)/4-1,d7
bccp2:	move.l	(a1)+,(a0)+
	dbf	d7,bccp2

	rts

;------------

clist:
clwinsz:dc.w    $8e,$2981,$90,$29c1,$92,$38,$94,$a0
        dc.w    $100
canzpl:	dc.w	0	;$201+plnr*$1000
	dc.w	$104,0,$1fc,$f,$102,0

	dc.w	$010f,$fffe
planes:	dc.w    $e0,0,$e2,0,$e4,0,$e6,0
        dc.w    $e8,0,$ea,0,$ec,0,$ee,0
	dc.w	$f0,0,$f2,0,$f4,0,$f6,0
	dc.w	$f8,0,$fa,0,$fc,0,$fe,0

	dc.w	$108,0	;(plnr-1)*xsize/8
	dc.w	$10a,0	;(plnr-1)*xsize/8
cl_cols:	; cols

	dc	$106,$20
cl_1dc:	dc	$1dc,32

clistbfe:
	dc.w	$ffdf,$fffe
cl_cint:dc	$370f,$fffe,$9c,$8004
	dc.l	-2,-2
cliste:
