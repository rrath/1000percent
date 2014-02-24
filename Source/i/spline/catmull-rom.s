; Catmull-Rom Spline
;
; goes through Controlpoints
;
; P(t)=	(1 t t^2 t^3) M (P[i-1] P[i] P[i+1] P[i+2])
;
;	  (  0  2  0  0 )
; M = 0.5 ( -1  0  1  0 )
;	  (  2 -5  4 -1 )
;	  ( -1  3 -3  1 )
;
;----
;
; P(t)=	(-t^3 + 2 * t^2 - t) / 2 * P[i-1] +
;	((3 * t^3 - 5 * t^2) / 2 + 1) * P[i] +
;	(-3 * t^3 + 4 * t^2 + t) / 2 * P[i+1] +
;	(t^3 - t^2 ) / 2 * P[i+2]

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

; P(t)=	(-t^3 + 2 * t^2 - t) / 2 * P[i-1] +

	move.l	d2,d4
	add.l	d4,d4		; 2*t^2

	move.l	d3,d5
	neg.l	d5
	sub.l	d1,d5		; -t^3-t

	add.l	d4,d5		; -t^3-t+2*t^2
	asr.l	#2,d5		; /2

	move	d5,(a0)+

;	((3 * t^3 - 5 * t^2) / 2 + 1) * P[i] +

	move.l	d3,d4
	move.l	d2,d5
	mulu	#3,d4
	mulu	#5,d5
	sub.l	d5,d4
	asr.l	#1,d4
	add.l	#$ffff,d4
	asr.l	#1,d4
	move	d4,(a0)+

;	(-3 * t^3 + 4 * t^2 + t) / 2 * P[i+1] +

	move.l	d3,d4
	move.l	d2,d5
	mulu	#3,d4
	mulu	#4,d5
	neg.l	d4
	add.l	d1,d5
	add.l	d4,d5
	asr.l	#2,d5
	move	d5,(a0)+

;	(t^3 - t^2 ) / 2 * P[i+2]

	sub.l	d2,d3
	asr.l	#2,d3
	move	d3,(a0)+

	addq	#2,d1

	dbf	d7,.pre_t_tab_ag

	add.l	#$7fa6*4*2+4,a1			; Fehler glattbuegeln
	moveq	#$100-$a6-1,d7
.corr	move	#$7fff,(a1)+
	addq.l	#6,a1
	dbf	d7,.corr
	rts
