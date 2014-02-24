;
; $VER: DemOS.s V1.31 (24.10.97)
; by Stelios/Scoopex (c) 1992-97
;
		IFND	system_on
system_on:	equ	0		;1=WB startup+error reports
		ENDC
		IFND	version_on
version_on:	equ	0		;1=include version string
		ENDC
		IFND	caches_on
caches_on:	equ	0		;1=enable caches
		ENDC
		IFND	caches_off
caches_off:	equ	0		;1=disable caches
		ENDC
		IFND	fast_vbr
fast_vbr:	equ	0		;1=move vbr to fastmem
		ENDC
		IFND	ntsc_exit
ntsc_exit:	equ	1		;1=exit if ntsc+ocs else force pal
		ENDC
		IFND	chipset_exit
chipset_exit:	equ	2		;1=exit if <ecs / 2=exit if <aga
		ENDC
		IFND	take_audio
take_audio:	equ	0		;1=allocate audio channels
		ENDC
		IFND	save_sprites
save_sprites:	equ	0		;1=store/restore hardware sprites
		ENDC
		IFND	drives_off
drives_off:	equ	0		;1=turn off drive(s)
		ENDC
		IFND	pause_on
pause_on:	equ	0		;1=rmb for pause
		ENDC
		IFND	blank_on
blank_on:	equ	0		;1=screen blanker
		ENDC
		IFND	mem_check_on
mem_check_on:	equ	0		;1=memory type check
		ENDC
		IFND	mem_64k_on
mem_64k_on:	equ	0		;1=64Kb block alignment
		ENDC
		IFND	mem_clear_on
mem_clear_on:	equ	0		;1=fast built-in memory clearing
		ENDC

WAITBLIT:	MACRO
		tst.b	(a6)
.wbloop\@:	btst	d5,(a6)
		bne.s	.wbloop\@
		ENDM

KILLSYS:	MACRO
		bsr	takesystem
		IFNE	system_on
		bne	startup_error
		ELSE
		bne	ProgFinish
		ENDC
		ENDM

FREESYS:	MACRO
		bsr	freesystem
		bra	ProgFinish
		ENDM

mcnop4tmp:	;must be longword aligned
mcnop4:		MACRO
mcnop4chk:	set	(*-mcnop4tmp)&2
		IFNE	mcnop4chk
		move.l	a0,a0
		ENDC
		ENDM

PAUSE:		MACRO
		IFNE	pause_on
.hold\@:	btst	#2,$16-2(a6)
		beq.s	.hold\@
		ENDC
		ENDM

WBEAM:		MACRO
		lea	4-2(a6),a0
		move.l	#$1ff00,d1
		move.l	#\1<<8,d2
.wbmlp\@:	move.l	(a0),d0
		and.l	d1,d0
		cmp.l	d2,d0
		bne.s	.wbmlp\@
		ENDM

*****************************************

	IFNE	system_on
wb_startup:
	movem.l	d0/a0,-(sp)
	moveq	#0,d7
	sub.l	a1,a1
	move.l	4.w,a6
	jsr	-$126(a6)		;FindTask()
	move.l	d0,a4
	tst.l	$ac(a4)			;pr_CLI
	bne.s	.fromcli
	lea	$5c(a4),a0		;pr_MsgPort
	move.l	a0,-(sp)
	jsr	-$180(a6)		;WaitPort()
	move.l	(sp)+,a0
	jsr	-$174(a6)		;GetMsg()
	move.l	d0,d7
.fromcli:	
	movem.l	(sp)+,d0/a0
	move.l	d7,-(sp)
	bsr.s	ProgStart
	move.l	(sp)+,d7		;message present ?
	beq.s	.exit
	move.l	d0,-(sp)
	move.l	4.w,a6
	jsr	-$84(a6)		;Forbid()
	move.l	d7,a1
	jsr	-$17a(a6)		;ReplyMsg()
	move.l	(sp)+,d0
.exit:	rts
	ELSE
	IFNE	version_on
	bra.s	ProgStart
	ENDC
	ENDC

	IFNE	version_on
	dc.b	"$VER: DemOS V1.31 (24.10.97)",10
	even
	ENDC

*****************************************

setcopper:
;
; > a0.l = copperlist
;
	move.l	a0,$80-2(a6)
	moveq	#$20,d1
	move.l	#$00200020,$9a-2(a6)
.wblp:	move.w	$1e-2(a6),d0
	and.w	d1,d0
	beq.s	.wblp
	move.w	d0,$88-2(a6)
	move.w	#$83c0,$96-2(a6)
	rts

	IFNE	blank_on
blankscreen:
;
; > d0.w = color
;
	movem.l	d2-d3,-(sp)
	moveq	#$20,d1
	move.l	#$00200020,$9a-2(a6)
.wblp:	move.w	$1e-2(a6),d2
	and.w	d1,d2
	beq.s	.wblp
	move.w	#$0180,$96-2(a6)
	move.w	#$8640,$96-2(a6)
	move.w	#$ec00,d3
	moveq	#8-1,d2
.rblp:	move.w	d3,$106-2(a6)
	lea	$180-2(a6),a0
	moveq	#32-1,d1
.rclp:	move.w	d0,(a0)+
	dbf	d1,.rclp
	sub.w	#$2000,d3
	dbf	d2,.rblp
	movem.l	(sp)+,d2-d3
	rts
	ENDC

*****************************************

	IFNE	mem_clear_on
mem_clear:
;
; > a0.l = ptr
; > d0.l = len
;
	movem.l	d2-d7/a2-a5,-(sp)
	add.l	d0,a0
	lsr.l	#1,d0
	bcc.s	.nob
	clr.b	-(a0)
.nob:	lsr.l	#1,d0
	bcc.s	.now
	clr.w	-(a0)
.now:	moveq	#0,d1
	move.l	d0,d7
	lsr.l	#6,d7			;len/256
	beq.s	.nol
	subq.w	#1,d7
	moveq	#0,d2
	moveq	#0,d3
	moveq	#0,d4
	moveq	#0,d5
	moveq	#0,d6
	sub.l	a1,a1
	sub.l	a2,a2
	sub.l	a3,a3
	sub.l	a4,a4
	sub.l	a5,a5
	mcnop4
.cl1:
	rept	5
	movem.l	d1-d6/a1-a5,-(a0)	;clear 5*44+36 = 256 bytes
	endr
	movem.l	d1-d6/a1-a3,-(a0)
	dbf	d7,.cl1
.nol:	and.w	#$3f,d0
	beq.s	.out
	subq.w	#1,d0
.cl2:	move.l	d1,-(a0)
	dbf	d0,.cl2
.out:	movem.l	(sp)+,d2-d7/a2-a5
	rts
	ENDC

	IFNE	mem_check_on
mem_check:
;
; > a1.l = ptr
; < d0.w = zero if ptr in chipram, non-zero otherwise
;
	move.l	a6,-(sp)
	move.l	4.w,a6
	jsr	-$216(a6)		;TypeOfMem()
	move.l	(sp)+,a6
	and.w	#6,d0
	subq.w	#2,d0
	rts
	ENDC

mem_pageptr:	ds.l	1		;buffer
		IFNE	mem_64k_on
mem_tableptr:	ds.l	1		;nodes
		ENDC
mem_listptr:	ds.l	1		;queries

*****************************************

takesystem:
	move.l	4.w,a6
	lea	gfxlib(pc),a1
	jsr	-$198(a6)		;OldOpenLibrary()
	lea	gfxbase(pc),a5
	move.l	d0,(a5)
	bne.s	.gfxlibok
	moveq	#-1,d0			;error, no graphics.library
	rts
.gfxlibok:
	IFNE	save_sprites
	lea	intlib(pc),a1
	jsr	-$198(a6)
	lea	intbase(pc),a0
	move.l	d0,(a0)
	bne.s	.intlibok
	bsr	startup_quit
	moveq	#-5,d0			;error, no intuition.library
	rts
.intlibok:
	ENDC

	moveq	#1,d1
	IFNE	fast_vbr
	move.l	#$408,d0
	ELSE
	moveq	#4,d0
	lsl.w	#8,d0			;d0.l = $400
	ENDC
	jsr	-$c6(a6)		;AllocMem()
	lea	zeropageptr(pc),a0
	move.l	d0,(a0)+
	bne.s	.zeropageok
	bsr	startup_quit
	moveq	#-2,d0			;error, could not allocate mem
	rts
.zeropageok:
	IFNE	fast_vbr
	addq.l	#8,d0
	and.b	#$f8,d0
	move.l	d0,(a0)+		;vbrptr
	ENDC

	lea	$dff002,a4
	IFNE	chipset_exit-2
	lea	chipsetflag(pc),a0
	clr.b	(a0)
	ENDC
	move.w	$7c-2(a4),d0
	moveq	#127,d7
.rlp:	move.w	$7c-2(a4),d1		;OCS DeniseID gives random info
	cmp.b	d0,d1
	bne.s	.ocs
	dbf	d7,.rlp
	and.b	#$06,d0
	IFEQ	chipset_exit-2		;bits 1-2 cleared = AGA
	beq.s	.chipsetok
	ELSE
	bne.s	.ecs
	addq.b	#2,(a0)
	bra.s	.chipsetok
.ecs:	subq.b	#4,d0			;bit 1 cleared, bit 2 set = ECS
	bne.s	.ocs
	addq.b	#1,(a0)
	IFNE	chipset_exit
	bra.s	.chipsetok
	ENDC
	ENDC
.ocs:
	IFNE	chipset_exit
	bsr	startup_quit
	moveq	#-4,d0			;error, required chipset not found
	rts
	ENDC
.chipsetok:

	IFEQ	chipset_exit
	cmp.w	#36,$14(a6)		;check for Kickstart 2
	blo.s	.oldks
	move.l	(a5),a1
	btst	#2,$cf(a1)		;proper NTSC check
	bne.s	.pal
	bra.s	.ntsc
.oldks:	cmp.w	#50+50<<8,$212(a6)	;alternative NTSC check
	beq.s	.pal
.ntsc:
	IFNE	ntsc_exit
	move.b	chipsetflag(pc),d0	;exit if NTSC+OCS
	bne.s	.pal
	bsr	startup_quit
	moveq	#-3,d0			;error, no pal display found
	rts
	ELSE
	lea	displayflag(pc),a0
	st	(a0)
	ENDC
	ENDC
.pal:
	lea	cputype(pc),a0
	clr.b	(a0)
	move.b	$129(a6),d0
	bpl.s	.no060			;btst #7
	addq.b	#2,(a0)
.no060:	moveq	#4-1,d7
.cpulp:	lsr.b	#1,d0
	bcc.s	.nocpu
	addq.b	#1,(a0)
.nocpu:	dbf	d7,.cpulp

	IFNE	take_audio
	bsr	alloc_audio
	beq.s	.audok
	bsr	startup_quit
	moveq	#-6,d0			;error, couldn't allocate audio
	rts
	ENDC
.audok:
	jsr	-$84(a6)		;Forbid()
	IFNE	save_sprites
	bsr	store_sprites
	ENDC
	move.l	(a5),a6
	lea	oldview(pc),a0
	move.l	$22(a6),(a0)		;save old view
	sub.l	a1,a1
	moveq	#$7f,d0
	bsr	wait_beam
	jsr	-$de(a6)		;LoadView()
	bsr	wait_tof
	jsr	-$1c8(a6)		;OwnBlitter()
	jsr	-$e4(a6)		;WaitBlit()
	IFNE	caches_on!caches_off
	bsr	init_caches
	ENDC

	btst	#6,$1a-2(a4)		;wait for disk dma
	beq.s	.nodiskdma
.waitdiskdma:
	btst	#1,$1f-2(a4)
	beq.s	.waitdiskdma
.nodiskdma:
	lea	olddmacon(pc),a0
	move.l	#$c0008000,d2
	moveq	#$1c,d0
	bsr	wait_beam
	move.w	(a4),(a0)+		;save dmacon
	move.w	$10-2(a4),(a0)+		;save adkcon
	move.l	$1c-2(a4),(a0)		;save intena & intreq
	move.l	#$7fff3fff,$9a-2(a4)	;kill intena & intreq
	move.w	#$7fff,$9e-2(a4)	;kill adkcon
	move.w	#$7ff,$96-2(a4)		;kill dmacon
	or.l	d2,(a0)
	or.w	d2,-(a0)
	or.w	d2,-(a0)
	and.w	#$87ff,(a0)
	move.w	#$c00,$106-2(a4)	;reset AGA sprites to 140ns res.
	move.w	#0,$1fc-2(a4)
	IFNE	ntsc_exit
	move.w	#32,$1dc-2(a4)		;force PAL
	ENDC
	IFNE	drives_off
	lea	$bfd100,a5
	or.b	#$f8,(a5)
	moveq	#0,d0
	bsr.s	.beam_delay
	and.b	#$87,(a5)
	moveq	#$60,d0
	bsr.s	.beam_delay
	or.b	#$f8,(a5)
	ENDC

	bsr.s	init_vbr
	move.l	a4,a6
	moveq	#0,d0			;everything ok
	rts

	IFNE	drives_off
.beam_delay:
	move.w	6-2(a4),d1
	clr.b	d1
.bmlp:	move.w	6-2(a4),d2		;word access
	clr.b	d2
	cmp.w	d2,d1
	beq.s	.bmlp
	dbf	d0,.beam_delay
	rts
	ENDC

init_vbr:
	moveq	#0,d2
	move.l	4.w,a6
	IFNE	chipset_exit-2
	move.b	cputype(pc),d0		;>= 010 ?
	beq.s	.no010
	ENDC
	lea	read_vbr(pc),a5
	jsr	-$1e(a6)		;Supervisor()
.no010:
	IFNE	fast_vbr
	lea	oldvbr(pc),a0
	move.l	d2,(a0)
	move.l	d2,a0
	move.l	vbrptr(pc),a1
	move.l	a1,d2
	ELSE
	lea	vbrptr(pc),a0
	move.l	d2,(a0)
	move.l	d2,a0
	move.l	zeropageptr(pc),a1
	ENDC
	move.w	#$400/4-1,d7
.clp:	move.l	(a0)+,(a1)+		;save zeropage
	dbf	d7,.clp
do_vbr:
	IFNE	fast_vbr
	IFNE	chipset_exit-2
	move.b	cputype(pc),d0
	beq.s	.no010
	ENDC
	lea	write_vbr(pc),a5
	jsr	-$1e(a6)
	ENDC
.no010:	rts

	cnop	0,4
read_vbr:
	dc.l	$4e7a2801		;movec vbr,d2
	rte

	IFNE	fast_vbr
restore_vbr:
	move.l	oldvbr(pc),d2
	move.l	4.w,a6
	IFNE	chipset_exit-2
	move.b	cputype(pc),d0
	beq.s	.no010
	ENDC
	bra.s	do_vbr
.no010:	
	IFNE	chipset_exit-2
	move.l	d2,a0
	sub.l	a1,a1
	move.w	#$400/4-1,d7
.clp:	move.l	(a0)+,(a1)+
	dbf	d7,.clp
	rts
	ENDC

	cnop	0,4
write_vbr:
	dc.l	$4e7b2801		;movec d2,vbr
	rte
	ENDC

	IFNE	caches_on!caches_off
init_caches:
	moveq	#0,d1
	bsr.s	CacheControl
	lea	oldcache(pc),a0
	move.l	d0,(a0)
	IFEQ	caches_off
	or.w	#$2111,d0		;all caches on
	and.w	#$efff,d0		;except databurst
	ELSE
	moveq	#$40,d0
	lsl.w	#7,d0			;d0.l = $2000
	ENDC
	moveq	#-1,d1

CacheControl:
	move.l	4.w,a6
	IFNE	chipset_exit-2
	cmp.w	#37,$14(a6)		;CacheControl() available ?
	blo.s	.oldks
	ENDC
	IFEQ	caches_off
	tst.b	$129(a6)
	bpl.s	.no060			;skip cache enabling on 060
	rts
	ENDC
.no060:	jmp	-$288(a6)		;CacheControl()

	IFNE	chipset_exit-2
.oldks:	moveq	#0,d3			;taken from KS3.0
	move.w	$128(a6),d4
	btst	#1,d4
	beq.s	.no020
	and.l	d1,d0
	or.w	#$808,d0
	not.l	d1
	lea	.cache_exception(pc),a5
	jsr	-$1e(a6)		;Supervisor()
.no020:	move.l	d3,d0
	rts

	cnop	0,4
.cache_exception:
	or.w	#$700,sr
	dc.l	$4e7a2002		;movec cacr,d2
	btst	#3,d4
	beq.s	.no040a
	swap	d2
	ror.w	#8,d2
	rol.l	#1,d2
.no040a:move.l	d2,d3
	and.l	d1,d2
	or.l	d0,d2
	btst	#3,d4
	beq.s	.no040b
	ror.l	#1,d2
	rol.w	#8,d2
	swap	d2
	and.l	#$80008000,d2
	nop
	dc.w	$f4f8			;cpusha bc
.no040b:nop
	dc.l	$4e7b2002		;movec d2,cacr
	nop
	rte
	ENDC

restore_caches:
	move.l	oldcache(pc),d0
	moveq	#-1,d1
	bra.s	CacheControl
	ENDC

wait_beam:
	move.l	4-2(a4),d1
	lsr.l	#8,d1
	and.w	#$01ff,d1
	cmp.w	d0,d1
	bne.s	wait_beam
	rts

freesystem:
	lea	$dff002,a4
	move.l	#$7fff3fff,$9a-2(a4)	;kill intena & intreq
	move.w	#$7fff,$9e-2(a4)	;kill adkcon
	tst.b	(a4)
.wblt:	btst	#6,(a4)
	bne.s	.wblt
	moveq	#$1c,d0
	bsr.s	wait_beam
	move.w	#$7ff,$96-2(a4)		;kill dmacon

	IFNE	fast_vbr
	bsr	restore_vbr
	ELSE
	move.l	zeropageptr(pc),a0
	move.l	vbrptr(pc),a1
	move.w	#$400/4-1,d7
.clp:	move.l	(a0)+,(a1)+
	dbf	d7,.clp
	ENDC

	lea	olddmacon(pc),a0
	move.w	(a0)+,$96-2(a4)		;restore dmacon bits
	move.w	(a0)+,$9e-2(a4)		;restore adkcon bits
	move.l	(a0),$9a-2(a4)		;restore intena & intreq bits

	IFNE	caches_on!caches_off
	bsr.s	restore_caches
	ENDC
	move.l	gfxbase(pc),a6
	sub.l	a1,a1			;reset view
	jsr	-$de(a6)		;LoadView()
	move.l	$26(a6),$80-2(a4)	;restore system copperlist
	move.l	$32(a6),$84-2(a4)
	move.w	d0,$88-2(a4)
	IFNE	save_sprites
	bsr.s	restore_sprites
	ENDC
	move.l	oldview(pc),a1		;old WorkBench view
	jsr	-$de(a6)		;LoadView()
	bsr.s	wait_tof
	IFNE	save_sprites
	move.w	#$11,$10c-2(a4)		;correct sprite palette
	ENDC
	jsr	-$1ce(a6)		;DisownBlitter()

	bsr.s	startup_quit
	jmp	-$8a(a6)		;Permit()

wait_tof:
	jsr	-$10e(a6)		;WaitTOF()
	jmp	-$10e(a6)		;twice

startup_quit:
	move.l	4.w,a6
	lea	gfxbase(pc),a2
	move.l	(a2),d0
	beq.s	.nogfxbase
	clr.l	(a2)
	move.l	d0,a1
	jsr	-$19e(a6)		;CloseLibrary()
.nogfxbase:
	IFNE	save_sprites
	addq.l	#4,a2			;intbase
	move.l	(a2),d0
	beq.s	.nointbase
	clr.l	(a2)
	move.l	d0,a1
	jsr	-$19e(a6)
.nointbase:
	ENDC
	lea	zeropageptr(pc),a2
	move.l	(a2),d0
	beq.s	.nozeropage
	clr.l	(a2)
	move.l	d0,a1
	IFNE	fast_vbr
	move.l	#$408,d0
	ELSE
	moveq	#4,d0
	lsl.w	#8,d0			;d0.l = $400
	ENDC
	jsr	-$d2(a6)		;FreeMem()
.nozeropage:
	IFNE	take_audio
	bra.s	free_audio
	ELSE
	rts
	ENDC

	IFNE	save_sprites
restore_sprites:
	move.l	wbscreen(pc),d0
	beq.s	.nowb

	move.l	d0,a0
	move.l	$30(a0),a0
	lea	spr_taglist(pc),a1
	jsr	-$2c4(a6)		;VideoControl()
	move.l	intbase(pc),a6
	move.l	wbscreen(pc),a0
	jsr	-$17a(a6)		;MakeScreen()
	move.l	wbscreen(pc),a1
	sub.l	a0,a0
	jsr	-$204(a6)		;UnlockPubScreen()
	jsr	-$186(a6)		;RethinkDisplay()

.nowb:	move.l	gfxbase(pc),a6
	bra.s	wait_tof

store_sprites:
	IFNE	chipset_exit-2
	moveq	#2,d0
	cmp.b	chipsetflag(pc),d0
	bne.s	.exit
	ENDC

	move.l	intbase(pc),a6
	lea	wbstring(pc),a0
	jsr	-$1fe(a6)		;LockPubScreen()
	lea	wbscreen(pc),a0
	move.l	d0,(a0)
	beq.s	.exit

	move.l	d0,a0
	move.l	$30(a0),a0		;sc_ViewPort+vp_ColorMap
	lea	spr_taglist+2(pc),a1
	move.w	#$32,(a1)+		;spriteresn_get
	clr.l	(a1)
	subq.l	#4,a1
	move.l	gfxbase(pc),a6
	jmp	-$2c4(a6)		;VideoControl()

.exit:	rts
	ENDC

	IFNE	take_audio
free_audio:
	move.b	audioflag(pc),d0
	beq.s	aud_nosignal
	lea	aud_ioreq(pc),a1
	jsr	-$1c2(a6)		;CloseDevice()
aud_nodevice:
	lea	aud_msgport(pc),a1
	jsr	-$168(a6)		;RemPort()
aud_noport:
	moveq	#0,d0
	move.b	aud_signal(pc),d0
	jsr	-$150(a6)		;FreeSignal()
aud_nosignal:
	moveq	#-1,d0
	rts

alloc_audio:
	lea	audioflag(pc),a2
	sf	(a2)
	lea	aud_msgptr(pc),a0
	lea	aud_msgport(pc),a1
	move.l	a1,(a0)
	lea	aud_mapptr(pc),a0
	lea	aud_map(pc),a1
	move.l	a1,(a0)

	sub.l	a1,a1
	jsr	-$126(a6)		;FindTask()
	lea	aud_task(pc),a0
	move.l	d0,(a0)

	moveq	#-1,d0
	jsr	-$14a(a6)		;AllocSignal()
	lea	aud_signal(pc),a0
	move.b	d0,(a0)
	bmi.s	aud_nosignal
	lea	aud_msgport(pc),a1
	jsr	-$162(a6)		;AddPort()
	tst.l	d0
	beq.s	aud_noport

	lea	austring(pc),a0
	moveq	#0,d0			;unit
	moveq	#0,d1			;flags
	lea	aud_ioreq(pc),a1
	jsr	-$1bc(a6)		;OpenDevice()
	tst.l	d0
	bne.s	aud_nodevice

	st	(a2)
	moveq	#0,d0
	rts
	ENDC

olddmacon:	ds.w	1
oldadkcon:	ds.w	1
oldintena:	ds.l	1
zeropageptr:	ds.l	1
vbrptr:		ds.l	1
		IFNE	fast_vbr
oldvbr:		ds.l	1
		ENDC
oldview:	ds.l	1
		IFNE	caches_on!caches_off
oldcache:	ds.l	1
		ENDC
gfxbase:	ds.l	1
		IFNE	save_sprites
intbase:	ds.l	1
spr_taglist:	dc.l	$80000000
spr_res:	ds.l  	3
wbscreen:	ds.l	1
		ENDC
		IFNE	take_audio
aud_ioreq:	ds.l	2
		dc.b	5,127
		ds.l	1
aud_msgptr:	ds.l	5
aud_mapptr:	dc.l	0,1
		ds.w	13
aud_msgport:	ds.l	2
		dc.b	4,0
		ds.l	1
		ds.b	1
aud_signal:	ds.b	1
aud_task:	ds.w	9
aud_map:	dc.b	15
audioflag:	ds.b	1
austring:	dc.b	'audio.device',0
		ENDC
		IFNE	save_sprites
wbstring:	dc.b	'Workbench',0
intlib:		dc.b	'intuition.library',0
		ENDC
gfxlib:		dc.b	'graphics.library',0
		IFNE	chipset_exit-2
chipsetflag:	ds.b	1		;0=ocs, 1=ecs, 2=aga
		ENDC
		IFEQ	ntsc_exit!chipset_exit
displayflag:	ds.b	1		;0=pal, -1=ntsc
		ENDC
cputype:	ds.b	1		;x value of 680x0
		even

*****************************************

	IFNE	system_on
	IFNE	take_audio
	dc.l	noaudio_msg
	ELSE
	dc.l	0
	ENDC
	dc.l	0
	IFNE	chipset_exit
	dc.l	nochipset_msg
	ELSE
	dc.l	0
	ENDC
	IFNE	ntsc_exit
	IFEQ	chipset_exit
	dc.l	nopal_msg
	ELSE
	dc.l	0
	ENDC
	ELSE
	dc.l	0
	ENDC
	dc.l	nofreemem_msg
	dc.l	0
message_ptrs:

memory_error:
	moveq	#-2,d0
startup_error:
	asl.w	#2,d0
	lea	msgptr(pc),a0
	move.l	message_ptrs(pc,d0.w),(a0)
	beq.s	.out
	lea	doslib(pc),a1
	jsr	-$198(a6)		;OldOpenLibrary()
	tst.l	d0
	beq.s	.out
	move.l	d0,a6
	lea	consolname(pc),a0
	move.l	a0,d1
	move.l	#1005,d2
	jsr	-$1e(a6)		;Open()
	tst.l	d0
	beq.s	.noc
	move.l	d0,a5
	lea	error_msg(pc),a0
	bsr.s	.pr
	move.l	msgptr(pc),a0
	bsr.s	.pr
	lea	exit_msg(pc),a0
	bsr.s	.pr
	moveq.l	#1,d3
	move.l	a5,d1
	lea	inbuff(pc),a1
	move.l	a1,d2
	jsr	-$2a(a6)		;Read()
	move.l	a5,d1
	jsr	-$24(a6)		;Close()
.noc:	move.l	a6,a1
	move.l	4.w,a6
	jsr	-$19e(a6)		;CloseLibrary()
.out:	bra	ProgFinish
.pr:	move.l	a5,d1
	move.l	a0,d2
	moveq	#-1,d3
.lp:	addq.l	#1,d3
	tst.b	(a0)+
	bne.s	.lp
	jmp	-$30(a6)		;Write()

inbuff:		ds.l	2
msgptr:		ds.l	1
doslib:		dc.b	'dos.library',0
consolname:	dc.b	'CON:64/96/512/54/ /CLOSE',0
error_msg:	dc.b	10,"*** Error: ",0
exit_msg:	dc.b	"!",10,10,"[Press RETURN key to exit.] ",0
nofreemem_msg:	dc.b	"not enough available memory",0
		IFNE	ntsc_exit
		IFEQ	chipset_exit
nopal_msg:	dc.b	"PAL display needed",0
		ENDC
		ENDC
		IFNE	chipset_exit
nochipset_msg:
		IFEQ	chipset_exit-1
 		dc.b	"ECS chipset needed",0
		ELSE
 		dc.b	"AGA chipset needed",0
	 	ENDC
 		ENDC
		IFNE	take_audio
noaudio_msg:	dc.b	"unable to allocate audio.device",0
		ENDC
	 	even
	ENDC
