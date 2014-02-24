patchmmu:
	move.l	4.w,a6
	tst.b	(296+1,a6) ; Test for 060 (bit 7)
	bmi.b	.has_060p
	moveq	#60,d0		;)
	rts


.has_060p
	lea	(.gettcr,pc),a5
	jsr	-$1e(a6)
	btst	#15,d0		; E - Enable
	bne.b	.mmu_enabled
	moveq	#20,d0		; 68060.library not loaded... (run SetPatch)
	rts

.mmu_enabled
	btst	#14,d0		; P - Page Size
	beq.b	.has4k		; Must have 4k page size
	moveq	#20,d0
	rts

.has4k	;call	Disable		; no others messing around, please...
	jsr	-120(a6)

	lea	(.geturp,pc),a5
;	call	Supervisor
	jsr	-$1e(a6)
	move.l	d0,a0		; a0=array of 128 root-level table descriptors, 32mb each

	move.l	(a0),d0
	and.w	#$FE00,d0
	move.l	d0,a4		; a4=array of 128 pointer table descriptors, 256k each

	moveq	#8-1,d3		; Patch all page desciptors of first 8 table
.mloop	move.l	(a4)+,d0	; descriptors (8*256k=2m=size of chipmem)
	bsr.b	.patch
	dbf	d3,.mloop


	lea	(.flush,pc),a5	; flush ATC & caches
;	call	Supervisor
	jsr	-$1e(a6)
;	call	CacheClearU	; flush caches with OS too (just to be sure:)
	jsr	-$27c(a6)		;ClearCacheU
;	call	Enable		; and back...
	jsr	-126(a6)

	moveq	#0,d0		; all ok!
	rts

.patch	and.w	#$FE00,d0
	move.l	d0,a0		; a0=array of 64 page descriptors
	moveq	#64-1,d1
.ploop	move.l	(a0),d2
	move.l	d2,d0
	and.b	#%11,d0		; get PDT
	beq.b	.next		; 00=invalid
	cmp.b	#%10,d0		; 10=indirect
	beq.b	.next

	; ok this is really it:

	or.b	#%1100000,d2	; set cm (bits 5&6) to 11 (Cache-Inhibited, Imprecise exception model)
	move.l	d2,(a0)

.next	addq.l	#4,a0
	dbf	d1,.ploop
	rts

.gettcr	dc.l	$4e7a0003	;movec	tc,d0
	nop
	rte

.geturp	dc.l	$4e7a0806	;movec	urp,d0
	nop
	rte

.flush	dc.w	$F518	; PFLUSHA	flush the address translation cache
	dc.w	$F4F8	; CPUSHA BC	flush the caches into memory
	dc.w	$F4D8	; INVA  BC	invalidate the data and inst caches
 	nop
	rte
