; Kochanek-Bartels spline (subtype of Hermit) used in 3DS4
;
; P(t) = (t^3 t^2 t 1) M (P1x P4x R1x R4x)
;
;     (  2 -2  1  1 )
; M = ( -3  3 -2 -1 )
;     (  0  0  1  0 )
;     (  1  0  0  0 )
;
; P1 and P4 are end points of a spline segment while R1 and R4 are their
; respective tangent vectors (derivatives)
;
;----
;
; P(t) = ( 2t^3 - 3t^2 + 1) * P1x +
;	 (-2t^3 + 3t^2    ) * P4x +
;	 (  t^3 - 2t^2 + t) * R1x +
;	 (  t^3 -  t^2    ) * R4x
;

; 0.0 = 0
; 1.0 = $ffff

; Rundungsfehler ab $7fa6 !!!

	move.l	a0,a1
	move	#$7fff,d7
	moveq	#0,d1			; 0.0

.pre_t_tab_ag:
	move.l	d1,d2

	mulu	d2,d2
	clr	d2
	swap	d2
	
	move.l	d2,d3
	mulu	d1,d3
	clr	d3
	swap	d3
					; d1=t  ; d2=t^2  ; d3=t^3

; P(t) = ( 2t^3 - 3t^2 + 1) * P1x +
	move.l	d3,d6
	add.l	d6,d6			; 2t^3

	move.l	d2,d5
	mulu	#3,d5			; 3t^2

	sub.l	d5,d6
	add.l	#$ffff,d6
	asr.l	#1,d6
	move	d6,(a0)+

;	 (-2t^3 + 3t^2    ) * P4x +
	move.l	d3,d6
	add.l	d6,d6			; 2t^3

	move.l	d2,d5
	mulu	#3,d5			; 3t^2

	sub.l	d6,d5
	asr.l	#1,d5
	move	d5,(a0)+

;	 (  t^3 - 2t^2 + t) * R1x +
	move.l	d2,d5
	add.l	d5,d5			; 2t^2

	move.l	d3,d6
	add.l	d1,d6

	sub.l	d5,d6
	asr.l	#1,d6
	move	d6,(a0)+

;	 (  t^3 -  t^2    ) * R4x
	sub.l	d2,d3
	asr.l	#1,d3
	move	d3,(a0)+

	addq	#2,d1

	dbf	d7,.pre_t_tab_ag

	add.l	#$7fa6*4*2,a1			; Fehler glattbuegeln
	moveq	#$100-$a6-1,d7
.corr	move.l	#$7fff,(a1)+
	addq.l	#4,a1
	dbf	d7,.corr
	rts
