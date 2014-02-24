;---------- Here comes Flame`s text about b-splines --------------
;
;I'll mark 'power' with '^'
;
;x(t) = (-1/6 * t^3 + 1/2 * t^2 -1/2*t + 1/6) * P(i-1) +
;       (1/2 * t^3 - t^2 + 2/3) * P(i) +
;       (-1/2 * t^3 + 1/2 * t^2 + 1/2 * t + 1/6) * P(i+1) +
;       (1/6 * t^3) * P(i+2)
;
;x(t) is value we get (& use) for 1 axis ... if we want 2d we use x(t) and y(t) .
;..
;P(x) is a control point coordinate. t slides from 0.0 to 1.0
;When t has slided from 0.0 to 1.0 then you add i with 1.
;i is 0 in the beginning ... P(0) is *SECOND* control point in splinedata ..
;so ... if you use t step of .25 you get only 4 vals/ control point --> rough ...
;if you use more, U get finer curve ...
;
;PRETABLE the P(x) coeffs ... and get the formula look like this:
;
;x(t) = TABLE_1(t) * P(i-1) +
;       TABLE_2(t) * P(i) +
;       TABLE_3(t) * P(i+1) +
;       TABLE_4(t) * P(i+2)
;
;so it is 4 muls / axis -->
;12 muls for 3d and 8 muls for 2d....
;
;Jani "Flame / Pygmy Projects" Vaarala
;
;

; 0.0 = 0
; 1.0 = $ffff

	move	#$7fff,d7

	moveq	#0,d1			; 0.0

pre_t_tab_ag:
	move.l	d1,d2

	mulu	d2,d2
	clr	d2
	swap	d2
	
	move.l	d2,d3
	mulu	d1,d3
	clr	d3
	swap	d3
					; d1=t  ; d2=t^2  ; d3=t^3

;-- x(t) = (-t^3 + 3*t^2 - 3*t + 1)/6 * P(i-1) +

	move.l	d1,d4
	add.l	d4,d4
	add.l	d1,d4			; 3*t

	move.l	d2,d5
	add.l	d5,d5
	add.l	d2,d5			; 3*t^2

	sub.l	d4,d5			; 3*t^2 - 3*t
	add.l	#$ffff,d5		;             + 1

	sub.l	d3,d5			; -t^3 + 3*t^2 -3*t + 1
	divs	#6*2,d5

	move	d5,(a0)+

;-- (3*t^3 - 6*t^2 + 4)/6 * P(i) +

	move.l	d3,d4
	add.l	d4,d4
	add.l	d3,d4			; 3*t^3

	move.l	d2,d5
	add.l	d5,d5
	add.l	d2,d5
	add.l	d5,d5			; 6*t^2

	sub.l	d5,d4			; 6*t^2 - 3*t^3

	add.l	#$ffff*4,d4		;		+4
	divs	#6*2,d4

	move	d4,(a0)+

;-- (-3*t^3 + 3*t^2 + 3*t + 1)/6 * P(i+1) +

	move.l	d3,d4
	add.l	d4,d4
	add.l	d3,d4

	move.l	d2,d5
	add.l	d5,d5
	add.l	d2,d5

	sub.l	d4,d5			; 3*t^2 - 3*t^3

	move.l	d1,d4
	add.l	d4,d4
	add.l	d1,d4

	add.l	d4,d5			;		 + 3*t

	add.l	#$ffff,d5
	divs	#6*2,d5

	move	d5,(a0)+

;-- (t^3)/6 * P(i+2)

	divs	#6*2,d3

	move	d3,(a0)+

	addq	#2,d1

	dbf	d7,pre_t_tab_ag
	rts
