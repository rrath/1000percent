do_sort:				; Shellsort
	move.l	koordxyz_p(pc),a4	; auf die erste Z-koord zeigen
	lea	indexend(pc),a5
	addq.l	#4,a4

sh_sort:
	move.l	datendp(pc),a2	; Ende der Tabelle
	move.l	datenp(pc),a0	; Datenfeld

	move.l	(a1),d6
	moveq	#1,d7
	sub.l	d6,a2

sort:	cmp.l	a0,a2
	ble.s	sort3
	lea	(a0,d6.l),a3	; Index dazu
	move.l	(a3),d5		; Pointer holen
	move.l	(a0),d4
	move	(a4,d5.w),d2	; Element holen
	cmp	(a4,d4.w),d2
	ble.s	sort2
	move.l	d4,(a3)		; Pointer swappen
	move.l	d5,(a0)
	moveq	#0,d7

sort2:	addq.l	#4,a0		; naexter Pointer
	bra.s	sort

sort3:	tst.l	d7		; Element geswappt?
	beq.s	sh_sort
	addq.l	#4,a1		; nope, naexter Index
	cmp.l	a5,a1		; fertig?
	bne.s	sh_sort
	rts

	cnop	0,4

index:
	dc.l	1093*4,364*4,121*4,40*4,13*4
	dc.l	4*4,1*4
indexend:
