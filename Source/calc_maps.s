
calc_maps:
	move.l	cloud64_p(pc),a0
	bsr.s	_x1_rendercloud

	bsr	do_spheremap1
	bsr	do_furchen_map
	bsr	do_furch_circ
	bsr	do_marble
	bsr	do_spheremap2
	bsr	do_sm_map
	bsr	do_sin_map

	rts

;------------------------------
; a0 = map

corr_map_4_o3o:
	move.l	a0,a1
	sub.l	#256*256,a0
	lea	8*4.w,a3

	move	#256*8-1,d7
.a:	movem.l	(a1)+,d0-d6/a2
	movem.l	d0-d6/a2,(a0)
	add.l	a3,a0
	dbf	d7,.a
		
	rts

;------------------------------;------------------------------
_X1_RenderCloud:

	bsr.w _X1_PoetRND
	and.b #63,d0
	move.b d0,(a0)
	bsr.w _X1_PoetRND
	and.b #63,d0
	move.b d0,128(a0)
	add.l #128*256,a0
	bsr.w _X1_PoetRND
	and.b #63,d0
	move.b d0,(a0)
	bsr.w _X1_PoetRND
	and.b #63,d0
	move.b d0,128(a0)
	sub.l #128*256,a0

	lea .Ands,a3
	move.l #2,a2
	move.l #128,d7
	bsr.b .renderrek
	rts

;---- Delta in d7, Anzahl-Steps in a2
.renderrek:
	moveq #0,d1
	move.w d7,d1
	lsr.w #1,d1		;YYXX
	move.w d1,d4		;d4=Delta/2


	move.w a2,d3		;CountY in d3

	lsl.w #8,d1
.loop:
	move.w a2,d0		;CountX in d0

	move.b d7,d1
	lsr.b #1,d1
.loop2:
	moveq #0,d5
	moveq #0,d6
	
	sub.b d4,d1		;XM
	lsl.w #8,d4
	sub.w d4,d1		;YM
	move.b (a0,d1.l),d5

	add.w d4,d1
	add.w d4,d1		;(XM) YP
	move.b (a0,d1.l),d6
	add.w d6,d5

	add.b d7,d1		;XP (YP)
	move.b (a0,d1.l),d6
	add.w d6,d5
	
	sub.w d4,d1		;(XP) YM
	sub.w d4,d1
	move.b (a0,d1.l),d6
	add.w d6,d5

	add.w d4,d1
	lsr.w #8,d4
	sub.b d4,d1		;X-Y

	sub.w d7,d5
	sub.w d7,d5		;-Delta*2
	move.l d0,-(sp)
	bsr.w _X1_PoetRND
	and.w (a3),d0		;+Rnd(Delta*4)
	add.w d0,d5
	move.l (sp)+,d0
	
	lsr.w #2,d5

	cmp.w #64,d5
	blt.b .noover
	move.w #63,d5
.noover:
	tst.w d5
	bge.b .nounder
	moveq #0,d5
.nounder:

	move.b d5,(a0,d1.l)

	add.b d7,d1	
	sub.w #1,d0
	bne.b .loop2

	lsl.w #8,d7
	add.w d7,d1
	lsr.w #8,d7
	sub.w #1,d3
	bne.b .loop

	;---------------------------- Part2
	move.w a2,d0
	lsl.w #1,d0
	move.w d0,a2

	move.w #0,d1
	move.w a2,d3		;CountY in d3

	lsl.w #8,d1
.zloop:
	move.w a2,d0		;CountX in d0

	move.b #0,d1
.zloop2:
	tst.b (a0,d1.l)
	bne.b .zw

	moveq #0,d5
	moveq #0,d6
	
	sub.b d4,d1		;XM
;	lsl.w #8,d4
;	sub.w d4,d1		;Y0
	move.b (a0,d1.l),d5

	add.b d4,d1
	add.b d4,d1		;XP (Y0)
	move.b (a0,d1.l),d6
	add.w d6,d5

	sub.b d4,d1		;X0 YM
	lsl.w #8,d4
	sub.w d4,d1
	move.b (a0,d1.l),d6
	add.w d6,d5
	
	add.w d4,d1		;(X0) YP
	add.w d4,d1
	move.b (a0,d1.l),d6
	add.w d6,d5

	sub.w d4,d1
	lsr.w #8,d4		;X-Y


	sub.w d7,d5
	sub.w d7,d5		;-Delta*2
	move.l d0,-(sp)
	bsr.w _X1_PoetRND
	and.w (a3),d0		;+Rnd(Delta*4)
	add.w d0,d5
	move.l (sp)+,d0
	
	lsr.w #2,d5

	cmp.w #64,d5
	blt.b .noover2
	move.w #63,d5
.noover2:
;	cmp.w #1,d5
	tst.w d5
	bge.b .nounder2
	moveq #0,d5
.nounder2:

		;Groessenpruefung!
	move.b d5,(a0,d1.l)
.zw:

	add.b d4,d1	
	sub.w #1,d0
	bne.b .zloop2

	lsl.w #8,d4
	add.w d4,d1
	lsr.w #8,d4
	sub.w #1,d3
	bne.b .zloop

	lsr.w #1,d7
	cmp.w #1,d7
	beq.b .ende
	add.w #2,a3
	bsr.w .renderrek
.ende:


	rts

.Ands:
	dc.w $1ff,$ff,$7f,$3f,$1f,$f,7,3,1,1,1,1

;------------------------------
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
	dc.l "anti","byte"

;-------------------------------------------------------------------

do_spheremap2:
	move.l	circle_p(pc),a0
	move.l	cloud64_p(pc),a1
	move.l	circle_p2(pc),a2

	moveq	#-1,d7		; move.l	#256*256-1,d7

.a:	moveq	#0,d0
	moveq	#0,d1
	move.b	(a0)+,d0
	move.b	(a1)+,d1
;	lsr	#1,d1
	add	d0,d1
	lsr	#1,d1
	move.b	d1,(a2)+
	dbf	d7,.a
	rts

;---------------

do_spheremap1:
	IFND	m_gouraud_tmap
	bsr.s	do_calctab
	ENDC

	move.l	origcircle_p(pc),a6
	move	#$ff,d4
	moveq	#-$7f,d5
	bsr.s	do_calccirc

	move.l	origcircle_p(pc),a6
	move.l	circle_p(pc),a0
	move	#256*256/4-1,d0
.a	move.l	(a6)+,(a0)+
	dbf	d0,.a

;	bra	corr_shmp1

corr_shmp1:
	move.l	circle_p(pc),a6
	moveq	#-1,d7		;	move.l	#256*256-1,d7

.a:	move.b	(a6),d0
	cmp.b	#235,d0
	blo.s	.b
	move	#235,d0
.b:	cmp.b	#127,d0
	bhi.s	.c
	move	#127,d0
.c:	sub.b	#126,d0
	move.b	d0,(a6)+

	dbf	d7,.a
	rts

do_calccirc:
	move.l	circtab_p(pc),a0
	move	d4,d7
	move	d5,d0
.a:	move	d4,d6
	move	d5,d1
	move	d0,d2
	muls	d2,d2
.b:	move	d1,d3
	muls	d3,d3
	add.l	d2,d3
	move	(a0,d3.l*2),d3
	not.b	d3
	move.b	d3,(a6)+
	addq	#1,d1
	dbf	d6,.b
	addq	#1,d0
	dbf	d7,.a
	rts	

;---

	IFND	m_gouraud_tmap
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
	ENDC

;--------------------------------------------------------------------

do_furch_circ:
	move.l	furchen_map_p(pc),a0
	move.l	circle_p(pc),a1
	move.l	furch_circ_p(pc),a2

	moveq	#-1,d7		;	move.l	#256*256-1,d7
.a:	moveq	#0,d0
	moveq	#0,d1
	move.b	(a0)+,d0
	move.b	(a1)+,d1
	add	d0,d1
	lsr	#1,d1
	move.b	d1,(a2)+
	dbf	d7,.a
	rts

;--------------------------------------------------------------------

furchen_x	=	256
furchen_y	=	256

do_furchen_map:
	move.l	furchen_map_p(pc),a0
	move	#furchen_x+1,d7
	moveq	#$07,d2
.a:	move.b	d2,(a0)+
	subq	#1,d7
	bne.b	.a
	move	#furchen_x*(furchen_y-1)-1,d7
.b:	mulu.l	#$00006255,d2
	ror.l	#7,d2
	moveq	#$03,d0
	and.l	d2,d0
	subq.l	#1,d0
	move.b	-furchen_x(a0),d1
	add.b	-(furchen_x+1)(a0),d1
	lsr.b	#1,d1
	add.b	d1,d0
	move.b	d0,(a0)+
	subq	#1,d7
	bne.b	.b
	rts

;--------------------------------------------------------------------

do_marble:
	lea	poetrndseed(pc),a0
	move.l	#'neop',(a0)+
	move.l	#'hyte',(a0)
	move.l	cloud64_p2(pc),a0
	bsr.w	_x1_rendercloud

	move.l	sval_p(pc),a0
	move.l	cval_p(pc),a1
	move.l	sinp,a2		; sin
	move	marble_scale(pc),d0
	move	marble_turbulence(pc),d1
	move	d0,d3
	lea	$800(a2),a3		; cos
	moveq	#0,d2
	ext.l	d1
	neg	d3

	move	#256-1,d7
.a:	move.l	d2,d4
	swap	d4
	divs.l	d1,d4
	move.l	d4,d5
.c:	cmp.l	#$6487e,d5		; 2Pi
	blt.s	.b
	sub.l	#$6487e,d5
	bra.s	.c
.b:	mulu.l	#$a2f,d5
	swap	d5
	lsr	#2,d5

	move	(a2,d5*2),d6
	muls	d3,d6
	add.l	d6,d6
	swap	d6
	move.b	d6,(a0)+

	move	(a3,d5*2),d6
	muls	d0,d6
	add.l	d6,d6
	swap	d6
	move.b	d6,(a1)+

	addq.l	#1,d2
	dbf	d7,.a
;--

	move.l	sval_p(pc),a0
	move.l	cval_p(pc),a1
	move.l	cloud64_p2(pc),a2
	move.l	marble_p(pc),a3
	move.l	cloud64_p(pc),a4
	moveq	#0,d2
	moveq	#0,d3
	moveq	#0,d5


	move	#256-1,d7
	moveq	#0,d0		; x

.e:	move	#256-1,d6
	moveq	#0,d1		; y

.d:	move.l	d1,d4
	move.b	d0,d4
	move.b	(a2,d4.l),d5
	move.b	(a0,d5.l),d2	; xx
	move.b	(a1,d5.l),d3	; yy
	add.b	d0,d2
	lsl	#8,d3
	add	d1,d3
	move.b	d2,d3
	move.b	(a4,d3.l),(a3,d4.l)
	add	#$0100,d1
	dbf	d6,.d
	addq.l	#1,d0
	dbf	d7,.e
	rts

marble_scale:		dc	32
marble_turbulence:	dc	120/4/2

;--------------------------------------------------------------------

do_sm_map:
	lea	poetrndseed(pc),a0
	move.l	#'anti',(a0)+
	move.l	#'byte',(a0)

	move.l	sm_map_p(pc),a4
	move.l	a4,a0
	move	#256*256/4-1,d6

.a:	bsr	_x1_poetrnd
	move.l	d0,(a0)+
	dbf	d6,.a

;---
	move.l	a4,a0
	moveq	#5,d2
	move.l	#$100,d3
	move.l	#$ff00,d0
	moveq	#0,d5

.doblur:move.l	a0,a1

.blur4:	moveq	#0,d4
	move.b	(a0,d0.l),d4
	move.b	(a1)+,d5
	add	d5,d4
;
;;;
;;
;;

	move.b	(a1),d5
	add	d5,d4

	move.b	1(a1),d5
	add	d5,d4

	move.b	(a0,d3.l),d5
	add	d5,d4
	move.b	1(a0,d3.l),d5
	add	d5,d4

	add.w	#$100,d3
	move.b	(a0,d3.l),d5
	add	d5,d4
	move.b	1(a0,d3.l),d5
	add	d5,d4
	sub.w	#$100,d3

	addq.w	#1,d0
	addq.w	#1,d3

	lsr	#3,d4
	move.b	d4,(a1)

	dbf	d6,.blur4
	move.b	d4,(a0)
	dbf	d2,.doblur


	moveq	#$7f,d1
.u:	move.b	(a4),d0
	lsl.b	#2,d0
	bpl.b	.v
	eor	d1,d0
.v:	and.b	d1,d0
	lsr.b	#1,d0
	move.b	d0,(a4)+
	dbf	d6,.u
	rts

;--------------------------------------------------------------------

do_sin_map:
	lea	sin_map_sin,a1
	move.l	sinp,a0
	move.l	a1,a2

	move	#256-1,d7
.i:	move	(a0),d0
	asr	#5,d0
	move	d0,(a1)+
	lea	32(a0),a0
	dbf	d7,.i
;---

	move.l	sin_map_p(pc),a1

	moveq	#0,d0
	moveq	#0,d1
	moveq	#0,d2
	moveq	#0,d3

        move   #256-1,d7
.outer:
        move.w  #256-1,d6
.inner:
        move.w  (a2,d0.w*2),d5
        add.w   (a2,d1.w*2),d5
        add.w   (a2,d2.w*2),d5
        add.w   (a2,d3.w*2),d5

        asr.w   #7,d5
        and.w   #63,d5
	sub	#32,d5
	bmi.s	.w
	eor	#$1f,d5
.w:	add	#32,d5
	move.b  d5,(a1)+

        addq    #1,d0
        addq    #3,d1
        addq    #7,d2
        addq    #5,d3

        move.w  #255,d5
        and.w   d5,d0
        and.w   d5,d1
        and.w   d5,d2
        and.w   d5,d3

        dbra    d6,.inner

	add.w   #256*2-2,d0
        add.w   #256*2+4,d1
        add.w   #256*2-1,d2
        add.w   #256*2+2,d3

        move.w  #255,d5
        and.w   d5,d0
        and.w   d5,d1
        and.w   d5,d2
        and.w   d5,d3

        dbra    d7,.outer
	rts

;--------------------------------------------------------------------

cloud64_p:	dc.l	_x1_chunkycloud64

circtab_p:	dc.l	circtab
origcircle_p:	dc.l	origcircle
circle_p:	dc.l	circle
circle_p2:	dc.l	circle2

furchen_map_p:	dc.l	furchen_map
furch_circ_p:	dc.l	furch_circ

cloud64_p2:	dc.l	cloud642
marble_p:	dc.l	marble
sval_p:		dc.l	sval
cval_p:		dc.l	cval
sm_map_p:	dc.l	sm_map
sin_map_p:	dc.l	sin_map

;-------------------------------------------------------------------

	section bss,bss

;---

_X1_ChunkyCloud64:	ds.b	256*256	; [0-63]

;---

		IFEQ	m_gouraud_tmap_v|m_phong_tmap_v
circtab:	ds	363*363
		ENDC

origcircle:	ds.b	256*256		; [0-255]
circle:		ds.b	256*256		; [0-109]
circle2:	ds.b	256*256		; [0-84]

;---

furchen_map:	ds.b	furchen_x*furchen_y	; [0-81]
furch_circ:	ds.b	256*256		; [0-78]

;---

cloud642:	ds.b	256*256
marble:		ds.b	256*256

;---

sval:		ds.b	256
cval:		ds.b	256

;---

sm_map:		ds.b	256*256		; [0-63]

;---

sin_map_sin:	ds	256
sin_map:	ds.b	256*256		; [0-31;32-63]
