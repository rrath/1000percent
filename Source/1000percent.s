	incdir	sources:scoopex/antibyte/sign/zero-g8/
	
* 3D Engine
* by
* Antibyte/SCOOPEX
*
* last modified: 23.11.98
*
* featuring:
*
* Quadruple Buffering, QuickSort, Shellsort
* optional Group-Sort (doesn't work with Viewing Sphere)
* Hermit, Catmull-Rom, B-Splines
* Subpixel
* Texture-Mapping/Phong/Env-Shading (uses optional smc-mapping on o2o/o3o)
* Transparent Phong/Mapping
* Fog (depthshaded phong/mapping)
* Gouraud shaded Texture-Mapping/Env
* Phong shaded Texture-Mapping
* Bump-Mapping
* Textured Bump-Mapping
* Flares
* Billboards
* Pseudo Bilinear Mapping (half the memreads) -> crap!
* Separate c2p 256 colors (1x1) for o2o/o3o and o4o/o6o
* Viewing Sphere
* Object/Material/Keyframing 3ds4 conversion output support
* (3dsrdr.exe->conv2tl.exe->splines.exe)
*
* Auf Grund der 'sort_list_p2' koennen maximal 8191 Flaechen verwendet werden
* (da ein offset*8 als word gespeichert wird, und $ffff/8=8191 ist)
* Bei 'bbox' stimmt group-sort nicht.
*
* Source has to be used with Asm-One.

; flags der Statemachine (nur vor obj_init veraendern):
;
; smc.b			<> 0:	kein Smc-mapping auf o3o
; half_scr.w 		<> 0:	1x2
; ysize_.w		    :	Hoehe (max. yysize)
; ntsc.w		<> 0:	NTSC mode verwenden
; fog_st.w		<> 0:	Lin. Farbinterpolation bei Mapping zwischen
;				fog_min und fog_max
; bbox_st.w 		<> 0:	Vertices und Tris auf Bounding-Box ueberpruefen
;				(bbxmin, bbxmax, bbymin, usw. setzen)

; Jederzeit veraenderbar:
;
; fl_4_sort_st.w 	<> 0:	Zmin jedes Tris fuer Sortierung bestimmen
; clear_st.w 		<> 0:	Screen-Buffer wird nicht geloescht
; fog_min.w		    :	Vordere Grenze
; fog_max.w		    :	Hintere Grenze des Fogs (dahinter unsichtbar)
; bsphereradius.l	    :	Bei Radius der Boundingsphere (bei bsphere)
;[bbxmin.w, bbxmax.w	    :	Ausmasze der Boundingbox
; bbymin.w, bbymax.w
; bbzmin.w, bbzmin.w]

; 0 = ok
; 1 = Dynamic Chip memory allocation failed
; 2 = Dynamic Public memory allocation failed
; 3 = Internal Error.

llerp		=	8

subpixel	=	2

xsize		=	320
yysize		=	192

auge		=	-300
zmin		=	-230

; IFD

speedychip		; Chipmemory DataCache set to NOCACHE
dostxt			; Textroutine fuer Cliwindow

;b_spline		; B-Spline fuer Camerapath verwenden
bbox			; Bounding-Box verwenden (d.h. Testen aller
			; Vertices und taggen der Tris)
bsphere			; Boundingsphere statt Box
;precision		; Bei PS256 werden zwei divs.l pro Zeile fuer hoehere
			; Prezision verwendet (statt der Konstante) und selbige
			; routine auch auf o2o/o3o ausgefuehrt (also kein
			; 1inst/pixel bei PS256!). Gilt nur fuer tmap&transmap!
;leftadd		; add-loop anstatt muls bei linkem clipping.
			; (nur bei tmap und transmap) x-flag nicht vorbereitet!
;shellsort		; Shellsort anstatt Quicksort
;negdivtab		; negative divisoren


;timeout		; 500 Durchlaeufe jedes Objekts. d0 liefert Anz. Frames
;debug			; No Systemshutdown

intro			; vertices/normale doppelt, anim_obj

;_3ds			; behandlung von 3ds reader/conv2tl output

m_transparent		; Transparentes Mapping
	IFND	precision
m_fog			; Mapping mit linearer Farbinterpolation
;m_bi_map		; Pseudo Bilineares Mapping
m_gouraud_tmap		; Gouraudshaded Tmap/Env
m_phong_tmap		; Phongshaded Tmap
m_bump			; Bumpmapping
;m_tbump			; Textured Bumpmapping
m_flare			; Flare
;m_bboard		; Billboard
	ENDC

;---------------------------------------------------------------------
; Internal definitions
	IFD	m_fog
	IFND	m_gouraud_tmap
m_gouraud_tmap		; wenn m_fog definiert ist, dann musz auch
	ENDC		; m_gouraud_tmap definiert sein
	ENDC
;---
	IFD	m_transparent
m_transparent_v		=	1
	ELSE
m_transparent_v		=	0
	ENDC
;-
	IFD	m_fog
m_fog_v	=	1
	ELSE
m_fog_v	=	0
	ENDC
;-
	IFD	m_gouraud_tmap
m_gouraud_tmap_v	=	1
	ELSE
m_gouraud_tmap_v	=	0
	ENDC
;-
	IFD	m_phong_tmap
m_phong_tmap_v		=	1
	ELSE
m_phong_tmap_v		=	0
	ENDC
;-
	IFD	m_bump
m_bump_v		=	1
	ELSE
m_bump_v		=	0
	ENDC
;-
	IFD	m_tbump
m_tbump_v		=	1
	ELSE
m_tbump_v		=	0
	ENDC
;---
	IFD	m_flare
m_flare_v		=	1
	ELSE
m_flare_v		=	0
	ENDC
;---
	IFD	m_bboard
m_bboard_v		=	1
	ELSE
m_bboard_v		=	0
	ENDC
;---
	IFNE	m_gouraud_tmap_v|m_phong_tmap_v|m_bump_v|m_tbump_v
em_clip			; clipping werte fuer "2.pass" aufheben
	ENDC
;---------------------------------------------------------------------

AllocMem        =	-$c6
FreeMem         =	-$d2

WBLIT:	MACRO
	tst.b   (a6)
.wbloop\@:
	btst    #6,(a6)
	bne.s   .wbloop\@
	ENDM

;---------------------------------------------------------------------

	jmp	progstart(pc)

;------------------------------------------

obj42m:
	dc	0,	0*4,300*4,-800*4
	dc	0,	0*4,300*4,-800*4
	dc	100,	-600*4,400*4,-800*4
	dc	200,	-400*4,500*4,0
	dc	300,	0,300*4,1000*4
	dc	400,	800*4,300*4,0
	dc	500,	600*4,300*4,-600*4
	dc	600,	0*4,300*4,-800*4
	dc	700,	-200*4,100*4,200*4
	dc	800,	-400*4,200*4,600*4
	dc	900,	100*4,350*4,400*4
	dc	1000,	400*4,300*4,-200*4
	dc	1100,	1000*4,600*4,-400*4
	dc	1200,	0*4,800*4,200*4
	dc	1300,	-600*4,800*4,300*4
	dc	1400,	-1000*4,400*4,0*4
	dc	1400,	-1000*4,400*4,0*4
	dc	1400,	-1000*4,400*4,0*4
	dc	1400,	-1000*4,400*4,0*4
	dc	-1

obj42m2:
	dc	0,	0,0,0
	dc	0,	0,0,0
	dc	200,	0,0,0
	dc	400,	0,200*4,0
	dc	600,	0,300*4,0
	dc	600,	0,300*4,0
	dc	600,	0,300*4,0
	dc	600,	0,300*4,0
	dc	-1

obj42m3:
	dc	0,	0
	dc	0,	0
	dc	400,	$300
	dc	800,	-$400
	dc	1000,	0
	dc	1000,	0
	dc	1000,	0
	dc	1000,	0
	dc	-1

;-------

o42_1m:
	dc	0,	-800*4,100*4,0
	dc	0,	-800*4,100*4,0
	dc	150,	-400*4,100*4,0
	dc	200,	-400*4,100*4,0
	dc	400,	-200*4,150*4,0
	dc	400,	-200*4,150*4,0
	dc	400,	-200*4,150*4,0
	dc	400,	-200*4,150*4,0
	dc	-1

o42_1r:
	dc	0,	0,0,0
	dc	0,	0,0,0
	dc	200,	0,0,0
	dc	400,	0,0,$a00
	dc	400,	0,0,$a00
	dc	400,	0,0,$a00
	dc	400,	0,0,$a00
	dc	-1


o42_2m:
	dc	0,	0,100*4,-800*4
	dc	0,	0,100*4,-800*4
	dc	150,	0,100*4,-400*4
	dc	200,	0,100*4,-400*4
	dc	400,	0,150*4,-200*4
	dc	400,	0,150*4,-200*4
	dc	400,	0,150*4,-200*4
	dc	400,	0,150*4,-200*4
	dc	-1
	

o42_2r:
	dc	0,	0,$800,0
	dc	0,	0,$800,0
	dc	200,	0,$800,0
	dc	400,	$a00,$800,0
	dc	400,	$a00,$800,0
	dc	400,	$a00,$800,0
	dc	400,	$a00,$800,0
	dc	-1

o42_3m:
	dc	0,	800*4,100*4,0
	dc	0,	800*4,100*4,0
	dc	150,	400*4,100*4,0
	dc	200,	400*4,100*4,0
	dc	400,	200*4,150*4,0
	dc	400,	200*4,150*4,0
	dc	400,	200*4,150*4,0
	dc	400,	200*4,150*4,0
	dc	-1

o42_3r:
	dc	0,	0,$1000,0
	dc	0,	0,$1000,0
	dc	200,	0,$1000,0
	dc	400,	0,$1000,-$a00
	dc	400,	0,$1000,-$a00
	dc	400,	0,$1000,-$a00
	dc	400,	0,$1000,-$a00
	dc	-1

o42_4m:
	dc	0,	0,100*4,800*4
	dc	0,	0,100*4,800*4
	dc	150,	0,100*4,400*4
	dc	200,	0,100*4,400*4
	dc	400,	0,150*4,200*4
	dc	400,	0,150*4,200*4
	dc	400,	0,150*4,200*4
	dc	400,	0,150*4,200*4
	dc	-1

o42_4r:
	dc	0,	0,$1800,0
	dc	0,	0,$1800,0
	dc	200,	0,$1800,0
	dc	400,	-$a00,$1800,0
	dc	400,	-$a00,$1800,0
	dc	400,	-$a00,$1800,0
	dc	400,	-$a00,$1800,0
	dc	-1

o42_5m:
	dc	0,	0,800*4,0
	dc	0,	0,800*4,0
	dc	380,	0,800*4,0
	dc	400,	0,600*4,0
	dc	500,	0,300*4,0
	dc	500,	0,300*4,0
	dc	500,	0,300*4,0
	dc	500,	0,300*4,0
	dc	-1

o42_5r:
	dc	0,	0,0,0
	dc	0,	0,0,0
	dc	400,	0,0,0
	dc	500,	0,$1000,0
	dc	600,	$800,$1000,$800
	dc	700,	$1000,$800,$1800
	dc	800,	$1800,0,$2000
	dc	900,	$2000,-$800,$2800
	dc	1000,	$2400,-$c00,$2400
	dc	1100,	$2a00,0,$1200
	dc	1200,	$3000,$800,$1a00
	dc	1300,	$3600,$d00,$2000
	dc	1400,	$3e00,$1400,$2600
	dc	1400,	$3e00,$1400,$2600
	dc	1400,	$3e00,$1400,$2600
	dc	1400,	$3e00,$1400,$2600
	dc	-1

;----------------------

o1010_1m:
	dc	0,	-50*4,-50*4,-600*4
	dc	0,	-50*4,-50*4,-600*4
	dc	200,	0*4,0*4,-200*4
	dc	250,	80*4,60*4,-150*4
	dc	600,	80*4,60*4,-150*4
	dc	625,	0*4,40*4,-250*4
	dc	1650,	0*4,40*4,-250*4
	dc	2650,	0*4,40*4,-250*4
	dc	3650,	0*4,40*4,-250*4
	dc	-1

o1010_1r:
o1010_3r:
	dc	0,	0,0,-$100
	dc	0,	0,0,-$100
	dc	250,	0,0,-$100
	dc	350,	0,0,$100
	dc	450,	0,0,-$100
	dc	550,	0,0,$100
	dc	650,	0,0,-$100
	dc	750,	0,0,$100
	dc	850,	0,0,-$100
	dc	3050,	0,0,0
	dc	4050,	0,0,0
	dc	5050,	0,0,0
	dc	-1
;-

o1010_2m:
	dc	0,	-50*4,-70*4,-600*4
	dc	0,	-50*4,-70*4,-600*4
	dc	250,	0*4,0*4,-200*4
	dc	300,	80*4,20*4,-150*4
	dc	625,	80*4,20*4,-150*4
	dc	650,	0*4,10*4,-250*4
	dc	1700,	0*4,10*4,-250*4
	dc	2700,	0*4,10*4,-250*4
	dc	3700,	0*4,10*4,-250*4
	dc	-1


o1010_3m:
	dc	0,	-30*4,-90*4,-600*4
	dc	0,	-30*4,-90*4,-600*4
	dc	300,	0*4,0*4,-200*4
	dc	350,	80*4,-20*4,-150*4
	dc	650,	80*4,-20*4,-150*4
	dc	675,	0*4,-20*4,-250*4
	dc	1675,	0*4,-20*4,-250*4
	dc	2675,	0*4,-20*4,-250*4
	dc	3675,	0*4,-20*4,-250*4
	dc	-1


o1010_4m:
	dc	0,	30*4,-110*4,-600*4
	dc	0,	30*4,-110*4,-600*4
	dc	350,	0*4,0*4,-200*4
	dc	400,	80*4,-60*4,-150*4
	dc	675,	80*4,-60*4,-150*4
	dc	700,	0*4,-50*4,-250*4
	dc	1700,	0*4,-50*4,-250*4
	dc	2700,	0*4,-50*4,-250*4
	dc	3700,	0*4,-50*4,-250*4
	dc	-1

;-
o1010_5m:
	dc	0,	50*4,-50*4,-600*4
	dc	0,	50*4,-50*4,-600*4
	dc	100,	0*4,0*4,-200*4
	dc	200,	-50*4,30*4,-350*4
	dc	400,	-50*4,30*4,-300*4
	dc	500,	-50*4,0*4,-300*4
	dc	600,	-50*4,-50*4,-300*4
	dc	700,	-50*4,-80*4,-450*4
	dc	800,	-80*4,-80*4,-650*4
	dc	1000,	-140*4,-80*4,-800*4
	dc	2000,	-140*4,-80*4,-800*4
	dc	3000,	-140*4,-80*4,-800*4
	dc	4000,	-140*4,-80*4,-800*4
	dc	-1

o1010_5r:
	dc	0,	0,0,0
	dc	0,	0,0,0
	dc	200,	0,0,$200
	dc	300,	0,0,-$200
	dc	400,	0,0,$200
	dc	500,	0,0,-$200
	dc	600,	0,0,$200
	dc	700,	0,0,-$200
	dc	800,	0,0,-$200
	dc	2800,	0,0,$200
	dc	3800,	0,0,-$200
	dc	4800,	0,0,$200
	dc	-1
;-

o1010_2r:
o1010_4r:
	dc	0,	0,0,$100
	dc	0,	0,0,$100
	dc	250,	0,0,$100
	dc	350,	0,0,-$100
	dc	450,	0,0,$100
	dc	550,	0,0,-$100
	dc	650,	0,0,$100
	dc	750,	0,0,-$100
	dc	850,	0,0,$100
	dc	4050,	0,0,00
	dc	5050,	0,0,00
	dc	6050,	0,0,00
	dc	-1

;------------------------

o144m:
	dc	0,	0,0,-1000*4
	dc	0,	0,0,-1000*4
	dc	0,	0,0,-1000*4
	dc	0,	0,0,-1000*4
	dc	0,	0,0,-1000*4
	dc	-1

o144_o1:
	dc	0,	0,0,-500*4
	dc	0,	0,0,-500*4
	dc	50,	0,0,-800*4
	dc	50*2,	0,0,-500*4
	dc	50*3,	0,0,-850*4
	dc	50*4,	0,0,-500*4
	dc	50*5,	0,0,-800*4
	dc	50*6,	0,0,-500*4
	dc	50*7,	0,0,-850*4
	dc	50*8,	0,0,-500*4
	dc	50*9,	0,0,-800*4
	dc	50*10,	0,0,-500*4
	dc	50*11,	0,0,-850*4
	dc	50*12,	0,0,-500*4
	dc	50*13,	0,0,-800*4
	dc	50*14,	0,0,-500*4
	dc	50*14,	0,0,-500*4
	dc	50*14,	0,0,-500*4
	dc	50*14,	0,0,-500*4
	dc	-1

;-------------------------

o14_o1:
	dc	0,	0*4,-4000*4,0
	dc	0,	0*4,-4000*4,0
	dc	1050,	0*4,-4000*4,0
	dc	1051,	0,-1000*4,0
	dc	1100,	0,0,0
	dc	1150,	0,1000*4,0
	dc	1200,	0,2000*4,0
	dc	1500,	0,2000*4,0
	dc	1700,	0,500*4,0
	dc	1900,	0,-1000*4,0
	dc	1900,	0,-1000*4,0
	dc	1900,	0,-1000*4,0
	dc	1900,	0,-1000*4,0
	dc	-1

o14_o1r:
	dc	0,	0,0,0
	dc	0,	0,0,0
	dc	1050,	0,0,0
	dc	1200,	0,$4000,0
	dc	1500,	0,$4000,0
	dc	1700,	0,$5800,0
	dc	1900,	0,$7000,0
	dc	1900,	0,$7000,0
	dc	1900,	0,$7000,0
	dc	1900,	0,$7000,0
	dc	-1

obj1000m:
	dc	0,	0,0*4,300*4
	dc	0,	0,0*4,300*4
	dc	150,	0,200*4,1000*4
	dc	300,	0,400*4,2000*4
	dc	550,	2200*4,600*4,0
	dc	750,	400*4,200*4,-600*4
	dc	900,	-200*4,200*4,-1400*4
	dc	1000,	-400*4,400*4,-2000*4
	dc	1050,	0,500*4,-600*4
	dc	1100,	0,300*4,-700*4
	dc	1125,	0,500*4,-700*4
	dc	1300,	00*4,500*4,-800*4
	dc	1500,	2400*4,1200*4,0
	dc	1700,	0,400*4,1500*4
	dc	1900,	-1500*4,400*4,0
	dc	2100,	0,400*4,-1500*4
	dc	2100,	0,400*4,-1500*4
	dc	2100,	0,400*4,-1500*4
	dc	2100,	0,400*4,-1500*4
	dc	-1

obj1000m2:
	dc	0,	0,100*4,1000*4
	dc	0,	0,100*4,1000*4
	dc	200,	1000*4,100*4,0*4
	dc	300,	0,200*4,0
	dc	500,	0,200*4,0
	dc	750,	0,300*4,0
	dc	900,	0,100*4,0
	dc	1000,	0,200*4,0
	dc	1050,	0,0,-100*4
	dc	1100,	0,0,0
	dc	1125,	0,500*4,0
	dc	1300,	0,500*4,0
	dc	1500,	-400*4,-100*4,0
	dc	1700,	100*4,0*4,0
	dc	1900,	0,0,0
	dc	2100,	0,0,0
	dc	2100,	0,0,0
	dc	2100,	0,0,0
	dc	2100,	0,0,0
	dc	-1

obj1000m3:
	dc	0,	0
	dc	0,	0
	dc	300,	0
	dc	550,	$200
	dc	750,	0
	dc	900,	-$200
	dc	1000,	0
;	dc	1050,	0
	dc	1100,	0	;-$80
	dc	1300,	-$100
	dc	1500,	$300
	dc	1700,	0
	dc	1900,	-$100
	dc	2100,	-$200
	dc	2100,	-$200
	dc	2100,	-$200
	dc	2100,	-$200
	dc	-1

;----------------------

obj1004m:
	dc	0,	0,0*4,400*4
	dc	0,	0,0*4,400*4
	dc	100,	0,0*4,1100*4
	dc	200,	0,200*4,500*4
	dc	300,	0,400*4,400*4
	dc	400,	0,400*4,300*4
	dc	500,	0,300*4,300*4
	dc	600,	0,300*4,300*4
	dc	700,	0,300*4,300*4
	dc	800,	0,300*4,300*4
	dc	800,	0,300*4,300*4
	dc	800,	0,300*4,300*4
	dc	800,	0,300*4,300*4
	dc	-1

obj1004m2:
	dc	0,	0,0,0
	dc	0,	0,0,0
	dc	200,	-100*4,0,0
	dc	400,	0,0,0
	dc	600,	0,50*4,0
	dc	700,	0,0,0
	dc	700,	0,0,0
	dc	700,	0,0,0
	dc	700,	0,0,0
	dc	700,	0,0,0
	dc	-1

obj1004m3:
	dc	0,	0
	dc	0,	0
	dc	100,	$400
	dc	200,	$800
	dc	300,	$c00
	dc	400,	$1000
	dc	500,	$1400
	dc	600,	$1800
	dc	700,	$1c00
	dc	800,	$2000
	dc	800,	$2000
	dc	800,	$2000
	dc	800,	$2000
	dc	-1

;----------------------

o1018_1m:
	dc	0,	100*4,100*4,-300*4
	dc	0,	100*4,100*4,-300*4
	dc	100,	-25*4,17*4,-100*4
	dc	150,	-25*4,17*4,-300*4
	dc	200,	-25*4,17*4,-100*4
	dc	250,	-25*4,17*4,-300*4
	dc	300,	-25*4,17*4,-100*4
	dc	350,	-25*4,17*4,-300*4
	dc	400,	-25*4,17*4,-100*4
	dc	450,	-25*4,17*4,-400*4
	dc	500,	-25*4,17*4,100*4
	dc	550,	-25*4,17*4,-400*4
	dc	600,	-25*4,17*4,-100*4
	dc	650,	-25*4,17*4,-300*4
	dc	700,	-25*4,17*4,-100*4
	dc	750,	-25*4,17*4,-300*4
	dc	800,	-25*4,17*4,-100*4
	dc	800,	-25*4,17*4,-100*4
	dc	800,	-25*4,17*4,-100*4
	dc	800,	-25*4,17*4,-100*4
	dc	-1

o1018_2m:
	dc	0,	-200*4,-75*4,-100*4
	dc	0,	-200*4,-75*4,-100*4
	dc	100,	25*4,-17*4,0
	dc	175,	25*4,-17*4,-200*4
	dc	225,	25*4,-17*4,-100*4
	dc	275,	25*4,-17*4,-200*4
	dc	325,	25*4,-17*4,-100*4
	dc	375,	25*4,-17*4,-200*4
	dc	425,	25*4,-17*4,-100*4
	dc	475,	25*4,-17*4,-300*4
	dc	525,	25*4,-17*4,100*4
	dc	575,	25*4,-17*4,-200*4
	dc	625,	25*4,-17*4,-100*4
	dc	675,	25*4,-17*4,-200*4
	dc	725,	25*4,-17*4,-100*4
	dc	775,	25*4,-17*4,-200*4
	dc	825,	25*4,-17*4,-100*4
	dc	875,	25*4,-17*4,-200*4
	dc	875,	25*4,-17*4,-200*4
	dc	875,	25*4,-17*4,-200*4
	dc	875,	25*4,-17*4,-200*4
	dc	-1

o1018_3m:
	dc	0,	200*4,-100*4,-200*4
	dc	0,	200*4,-100*4,-200*4
	dc	100,	75*4,-50*4,0
	dc	200,	75*4,-50*4,-200*4
	dc	250,	75*4,-50*4,-100*4
	dc	300,	75*4,-50*4,-200*4
	dc	350,	75*4,-50*4,-100*4
	dc	400,	75*4,-50*4,-200*4
	dc	450,	75*4,-50*4,-100*4
	dc	500,	75*4,-50*4,-300*4
	dc	550,	75*4,-50*4,100*4
	dc	600,	75*4,-50*4,-200*4
	dc	650,	75*4,-50*4,-100*4
	dc	700,	75*4,-50*4,-200*4
	dc	750,	75*4,-50*4,-100*4
	dc	800,	75*4,-50*4,-200*4
	dc	850,	75*4,-50*4,-100*4
	dc	850,	75*4,-50*4,-100*4
	dc	850,	75*4,-50*4,-100*4
	dc	850,	75*4,-50*4,-100*4
	dc	-1

o1018_4m:
	dc	0,	-75*4,50*4,-300*4
	dc	0,	-75*4,50*4,-300*4
	dc	100,	-75*4,50*4,0
	dc	200,	-75*4,50*4,-300*4
	dc	300,	-75*4,50*4,0*4
	dc	400,	-75*4,50*4,-300*4
	dc	500,	-75*4,50*4,0*4
	dc	600,	-75*4,50*4,-300*4
	dc	700,	-75*4,50*4,0*4
	dc	800,	-75*4,50*4,-300*4
	dc	900,	-75*4,50*4,-300*4
	dc	900,	-75*4,50*4,-300*4
	dc	900,	-75*4,50*4,-300*4
	dc	900,	-75*4,50*4,-300*4
	dc	-1
	
o1018_1r:
o1018_2r:
o1018_3r:
o1018_4r:
	dc	0,	0,0,0
	dc	0,	0,0,0
	dc	0,	0,0,0
	dc	0,	0,0,0
	dc	0,	0,0,0
	
;----------------------

obj20m3:
	dc	0,	-$200
	dc	0,	-$200
	dc	200,	0
	dc	1400,	0
	dc	1550,	$100
	dc	1700,	0
	dc	1700,	0
	dc	1700,	0
	dc	1700,	0
	dc	1700,	0
	dc	-1
	
obj20m2:
	dc	0,	0,80*4,0
	dc	0,	0,80*4,0
	dc	400,	0,80*4,0
	dc	600,	0,500*4,0
	dc	800,	0,350*4,0
	dc	1200,	0,350*4,0
	dc	1500,	0,-100*4,0
	dc	1600,	0,-200*4,0
	dc	1800,	0,-300*4,0
	dc	2000,	0,0,0
	dc	2000,	0,0,0
	dc	2000,	0,0,0
	dc	2000,	0,0,0
	dc	-1

obj20m:
	dc	0,	-300*4,0,-300*4
	dc	0,	-300*4,0,-300*4
	dc	200,	0,0,-500*4
	dc	400,	0,0,-500*4
	dc	600,	0,-300*4,-150*4
	dc	800,	300*4,200*4,-650*4
	dc	950,	600*4,150*4,0*4
	dc	1200,	-500*4,100*4,150*4
	dc	1400,	-600*4,300*4,300*4
	dc	1550,	0,300*4,900*4
	dc	1650,	400*4,350*4,700*4
	dc	1800,	1100*4,400*4,0
	dc	1900,	800*4,500*4,-500*4
	dc	2000,	400*4,600*4,-700*4
	dc	2200,	0*4,500*4,-1100*4
	dc	2400,	-800*4,400*4,-400*4
	dc	2400,	-800*4,400*4,-400*4
	dc	2400,	-800*4,400*4,-400*4
	dc	2400,	-800*4,400*4,-400*4
	dc	-1

;---------

o20_o1:
	dc	0,	200*4,-450*4,0*4
	dc	0,	200*4,-450*4,0*4
	dc	1400,	200*4,-450*4,0*4
	dc	1500,	0*4,-450*4,-200*4
	dc	1600,	-200*4,-450*4,0
	dc	1700,	0,-450*4,200*4
	dc	1800,	200*4,-450*4,0*4
	dc	1900,	200*4,-450*4,-300*4
	dc	2000,	0*4,-450*4,-300*4
	dc	2000,	0*4,-450*4,-300*4
	dc	2000,	0*4,-450*4,-300*4
	dc	2000,	0*4,-450*4,-300*4
	dc	-1

o20_o1r:
	dc	0,	0,0+$1000,0
	dc	0,	0,0+$1000,0
	dc	1400,	0,-$800+$1000,0
	dc	1500,	0,-$1000+$1000,0
	dc	1600,	0,-$1800+$1000,0
	dc	1700,	0,-$2000+$1000,0
	dc	1800,	0,-$2800+$1000,0
	dc	1900,	0,-$2800+$1000,0
	dc	2000,	0,-$2800+$1000,0
	dc	2000,	0,-$2800+$1000,0
	dc	2000,	0,-$2800+$1000,0
	dc	2000,	0,-$2800+$1000,0
	dc	-1

;---

o20_o2:
	dc	0,	0*4,-450*4,-200*4
	dc	0,	0*4,-450*4,-200*4
	dc	1400,	0*4,-450*4,-200*4
	dc	1500,	-200*4,-450*4,0*4
	dc	1600,	0*4,-450*4,200*4
	dc	1700,	200*4,-450*4,0*4
	dc	1800,	0*4,-450*4,-200*4
	dc	1900,	-300*4,-450*4,-200*4
	dc	2000,	-300*4,-450*4,0*4
	dc	2000,	-300*4,-450*4,0*4
	dc	2000,	-300*4,-450*4,0*4
	dc	2000,	-300*4,-450*4,0*4
	dc	-1

o20_o2r:
	dc	0,	0,-$800+$2800,0
	dc	0,	0,-$800+$2800,0
	dc	1400,	0,-$800+$2800,0
	dc	1500,	0,-$1000+$2800,0
	dc	1600,	0,-$1800+$2800,0
	dc	1700,	0,-$2000+$2800,0
	dc	1800,	0,-$2800+$2800,0
	dc	1900,	0,-$2800+$2800,0
	dc	2000,	0,-$2800+$2800,0
	dc	2000,	0,-$2800+$2800,0
	dc	2000,	0,-$2800+$2800,0
	dc	2000,	0,-$2800+$2800,0
	dc	-1

;---

o20_o3:
	dc	0,	-200*4,-450*4,00*4
	dc	0,	-200*4,-450*4,00*4
	dc	1400,	-200*4,-450*4,00*4
	dc	1500,	0*4,-450*4,200*4
	dc	1600,	200*4,-450*4,0*4
	dc	1700,	0*4,-450*4,-200*4
	dc	1800,	-200*4,-450*4,0*4
	dc	1900,	-200*4,-450*4,300*4
	dc	2000,	0*4,-450*4,300*4
	dc	2000,	0*4,-450*4,300*4
	dc	2000,	0*4,-450*4,300*4
	dc	2000,	0*4,-450*4,300*4
	dc	-1

o20_o3r:
	dc	0,	0,0+$2000,0
	dc	0,	0,0+$2000,0
	dc	1400,	0,-$800+$2000,0
	dc	1500,	0,-$1000+$2000,0
	dc	1600,	0,-$1800+$2000,0
	dc	1700,	0,-$2000+$2000,0
	dc	1800,	0,-$2800+$2000,0
	dc	1900,	0,-$2800+$2000,0
	dc	2000,	0,-$2800+$2000,0
	dc	2000,	0,-$2800+$2000,0
	dc	2000,	0,-$2800+$2000,0
	dc	2000,	0,-$2800+$2000,0
	dc	-1

;---

o20_o4:
	dc	0,	500*4,500*4,0
	dc	0,	500*4,500*4,0
	dc	100,	500*4,300*4,0
	dc	200,	200*4,100*4,500*4
	dc	300,	-100*4,0*4,0*4
	dc	400,	-300*4,-100*4,-500*4
	dc	1399,	-300*4,-100*4,-500*4
	dc	1400,	-450*4,-100*4,-500*4
	dc	1500,	200*4,0*4,-500*4
	dc	1650,	600*4,100*4,0
	dc	1800,	400*4,200*4,200*4
	dc	2000,	-200*4,250*4,0
	dc	2200,	-100*4,250*4,-100*4
	dc	2400,	0*4,250*4,-100*4
	dc	2400,	0*4,250*4,-100*4
	dc	2400,	0*4,250*4,-100*4
	dc	2400,	0*4,250*4,-100*4
	dc	-1

o20_o4r:
	dc	0,	0,$1000,$400
	dc	0,	0,$1000,$400
	dc	200,	0,$1000,$100
	dc	300,	0,$1400,$300
	dc	400,	0,$1800,$600
	dc	1399,	0,$1800,$600
	dc	1400,	0,$2000,0
	dc	1500,	0,$2400,$100
	dc	1650,	0,$2800,$200
	dc	1800,	0,$3000,$200
	dc	2000,	0,$4000,-$200
	dc	2200,	0,$4000,-$200
	dc	2400,	0,$3800,-$200
	dc	2400,	0,$3800,-$200
	dc	2400,	0,$3800,-$200
	dc	2400,	0,$3800,-$200
	dc	-1

;---------------------------------------

o1028_1m:
	dc	0,	-200*4,80*4,-200*4
	dc	0,	-200*4,80*4,-200*4
	dc	125,	-80*4,70*4,-80*4
	dc	125,	-80*4,70*4,-80*4
	dc	125,	-80*4,70*4,-80*4
	dc	125,	-80*4,70*4,-80*4
	dc	125,	-80*4,70*4,-80*4

o1028_2m:
	dc	0,	-200*4,40*4,-200*4
	dc	0,	-200*4,40*4,-200*4
	dc	150,	-40*4,40*4,-100*4
	dc	212,	-40*4,40*4,-70*4
	dc	275,	-40*4,40*4,-170*4
	dc	350,	-40*4,40*4,-70*4
	dc	425,	-40*4,40*4,-170*4
	dc	500,	-40*4,40*4,-70*4
	dc	575,	-40*4,40*4,-170*4
	dc	575,	-40*4,40*4,-170*4
	dc	575,	-40*4,40*4,-170*4
	dc	575,	-40*4,40*4,-170*4

o1028_3m:
	dc	0,	0*4,0,500*4
	dc	0,	0*4,0,500*4
	dc	175,	0,0,-200*4
	dc	250,	0,0,-300*4
	dc	325,	0,0,-200*4
	dc	400,	0,0,-300*4
	dc	475,	0,0,-200*4
	dc	550,	0,0,-300*4
	dc	550,	0,0,-300*4
	dc	550,	0,0,-300*4
	dc	550,	0,0,-300*4

o1028_4m:
	dc	0,	200*4,-40*4,-200*4
	dc	0,	200*4,-40*4,-200*4
	dc	200,	50*4,-40*4,-130*4
	dc	200,	50*4,-40*4,-130*4
	dc	200,	50*4,-40*4,-130*4
	dc	200,	50*4,-40*4,-130*4

o1028_5m:
	dc	0,	-100*4,100*4,-250*4
	dc	0,	-100*4,100*4,-250*4
	dc	100,	-100*4,100*4,-120*4
	dc	100,	-100*4,100*4,-120*4
	dc	100,	-100*4,100*4,-120*4
	dc	100,	-100*4,100*4,-120*4
	

o1028_6m:
	dc	0,	200*4,-80*4,-200*4
	dc	0,	200*4,-80*4,-200*4
	dc	225,	60*4,-50*4,-180*4
	dc	225,	60*4,-50*4,-180*4
	dc	225,	60*4,-50*4,-180*4
	dc	225,	60*4,-50*4,-180*4

o1028_1r:
o1028_2r:
o1028_3r:
o1028_4r:
o1028_5r:
o1028_6r:
	dc	0,	0,0,0
	dc	0,	0,0,0
	dc	0,	0,0,0
	dc	0,	0,0,0
	dc	0,	0,0,0

;---------------------------------------

	IFD	speedychip
	include	"i/other/patchmmu.s"
	ENDC

	IFD	dostxt
	include	"i/other/dostxt.s"
	ENDC

;--- Let's go!!

progstart:
	subq	#1,d0
ppp:	cmp.b	#'0',(a0)+
	bne.s	ps_1

	lea	half_scr(pc),a1
	move	#1,(a1)
ps_1:	dbf	d0,ppp
;--

	IFD	dostxt
	lea	endtxt,a0
	bsr.w	print_txt
	ENDC

	IFD	speedychip
	bsr	patchmmu
	ENDC

	bsr	init			; Take System & Init Vektor-engine
	bne.w	quit

	lea	smc(pc),a0
	move.b	#-1,(a0)

	clr	$dff106
	clr	$dff180

	jsr	init_maps

;-
	jsr	deetsay
	lea	a_corr,a0
	lea	a,a1
	moveq	#$100/4-1,d7
.gc	move.l	(a0)+,(a1)+
	dbf	d7,.gc

	lea	b_corr,a0
	lea	b,a1
	moveq	#240/4-1,d7
.gc2	move.l	(a0)+,(a1)+
	dbf	d7,.gc2

	clr	a
	clr	b
	clr	c
	clr	d
	clr	e
	clr	f
	clr	g
	clr	h
	clr	i
	clr	j
	clr	k
	clr	l
	clr	m
	clr	ac_a
	clr	ac_b
	clr	ac_c
	clr	ac_d
	clr	ac_e
	clr	ac_f
	clr	ac_g
	clr	ac_h

;-
	move.l	vbrptr(pc),tp_vbr
	move.l	#module,tp_data
	move.l	#samples,tp_samples
	jsr	tp_init
;	bne.s	e_re

	bsr.w	do_stuff
	bne.s	e_re2

	nop

e_re2:	jsr	tp_end

e_re:	bsr.w	restore			; Restore System

quit:	move.l	e_status(pc),d0

	IFD	dostxt
	cmp.l	#-1,d0
	beq.s	qquit

	tst.l	d0
	beq.s	qquit

	lea	nomem,a0
	bra.w	print_txt

qquit:
	ENDC

 IFD	timeout
 move.l	aaaa(pc),d0
 ENDC
	moveq	#0,d0
	rts

;-----------------------
;--- DO_STUFF

do_stuff:
	lea	$dff002,a6
	move	#$7fff,$9a-2(a6)
	move	#$c060,$9a-2(a6)

	move	#$7de0,$96-2(a6)
	move.l	#blackcl,$80-2(a6)
	clr	$88-2(a6)
	move	#$83c0,$96-2(a6)

;	bra.w	.eee
;---
	lea	obj_inits(pc),a0
	bsr.w	do_scene
	bne.w	e_exit
;-
	lea	obj_inits6(pc),a0
	bsr.w	do_scene
	bne.w	e_exit
	lea	copy_clear_st(pc),a0
	clr	(a0)
;-
	jsr	do_tunsphere
	bne	e_exit
;-
	lea	obj_inits2(pc),a0
	bsr.w	do_scene
	bne.w	e_exit
;-
	lea	obj_inits7(pc),a0
	bsr.w	do_scene
	bne.w	e_exit
;-
	lea	obj_inits3(pc),a0
	bsr.w	do_scene
	bne.w	e_exit
	lea	fog_st(pc),a0
	clr	(a0)
;-
;	lea	obj_inits4(pc),a0
;	bsr.w	do_scene
;	bne.w	e_exit
;-
	move	#1,blur_st
	lea	obj_inits8(pc),a0
	bsr.w	do_scene
	bne.w	e_exit
	clr	blur_st
;-
	move	#2,blur_st
	lea	obj_inits11(pc),a0
	bsr.w	do_scene
	bne.w	e_exit
	clr	blur_st

;-
.eee:
	jsr	tp_end

	move	#75,d1
	bsr	waits

	move	#$4000,$dff09a
	move.l	#module2,tp_data
	jsr	tp_init

	lea	abs_fr_cnt(pc),a0
	clr.l	(a0)

	lea	obj_inits9(pc),a0
	bsr.w	do_scene
	bne.w	e_exit
;-
	lea	obj_inits5(pc),a0
	bsr.w	do_scene
	bne.w	e_exit
;-
	move	#1,fsph
	move	#xk,x
	move	#yk,y
	move	#$4e71,calcnormals\.no_op
	move.l	4.w,a6
	jsr	-$27c(a6)		;ClearCacheU
	jsr	do_tunsphere
	bne.s	e_exit
;---
	jsr	tp_end

	move	#75,d1
	bsr	waits

	move	#$4000,$dff09a
	move.l	#module3,tp_data
	jsr	tp_init

	lea	abs_fr_cnt(pc),a0
	clr.l	(a0)

	lea	ysize_(pc),a0
	move	#120,(a0)
	lea	obj_inits10(pc),a0
	bsr.w	do_scene
	bne.w	e_exit
;---

	moveq	#0,d0
	rts

;---

do_scene:
	jsr	do_scene1

	lea	scene1_struct,a0
;	lea	t1_struct(pc),a0
	bsr	init_obj		; Nvektoren&Objekttabellen setup
	bne.b	e_exit
	bsr	do_obj_main
	bne.s	e_exit
	moveq	#0,d0
	rts
;---

e_exit:
	lea	e_status(pc),a0
	move.l	d0,(a0)
	rts

;-----------------
; Init Cop1lc&Dma; move Object

do_obj_main:
	bsr	swop
	jsr	ps256_clear(pc)

.a:	lea	time_p(pc),a0
	move.l	(a0),a1
	lea	abs_fr_cnt(pc),a2
	move.l	(a1),d0
	cmp.l	(a2),d0
	bgt.s	.a

	addq.l	#4,(a0)
;-
	lea	$dff002,a6
	move.l	clistptr(pc),$80-2(a6)
	move	#$e000,$9a-2(a6)
;	clr	$88-2(a6)
;	move	#$7de0,$96-2(a6)
;	move	#$83c0,$96-2(a6)
	clr	irq_cnt

 IFD	timeout
 clr.l	abs_fr_cnt
 move.l	#500,xxxx
 ENDC

main0:	lea	$dff002,a6
	bsr.w	main

	btst	#6,$bfe001
	beq.s	mainex

	lea	time_p(pc),a0
	move.l	(a0),a1
	lea	abs_fr_cnt(pc),a2
	move.l	(a1),d0
	cmp.l	(a2),d0
	bgt.s	main0

	addq.l	#4,(a0)

me:
.a:	tst	blit_st
	bne.s	.a

	lea	$dff002,a6
	wblit

	move.l	#blackcl,$80-2(a6)
	bsr.w	waitr
	bsr.s	waitr

	IFD	_3ds
	lea	_3ds_st(pc),a0
	clr	(a0)
	ENDC
	
	bsr	free_obj
	moveq	#0,d0
	rts

	IFD	timeout
aaaa:	dc.l	0
xxxx:	dc.l	0
	ENDC

;-------

mainex:
	bsr.s	me
	moveq	#-1,d0
	rts

;-------

wait0	=	0
wait01	=	12*50-20

wait1	=	12*50+25-20
wait11	=	58*50

wait2	=	58*50+25
wait21	=	83*50+25

;-----

wait3	=	0
wait31	=	150*50

;-----

wait4	=	0
wait41	=	10*50

wait5	=	11*50-10
wait51	=	34*50-25

wait6	=	34*50
wait61	=	49*50-25+10

wait7	=	49*50+10
wait71	=	87*50

wait8	=	88*50-25
wait81	=	103*50-25

wait9	=	103*50
wait91	=	119*50-25

waita	=	119*50
waita1	=	134*50-25

waitb	=	134*50-10
waitb1	=	161*50

;-----

time_p:	dc.l	times
times:
	dc.l	wait4,wait41
	dc.l	wait5,wait51
	dc.l	wait6,wait61
	dc.l	wait7,wait71
	dc.l	wait8,wait81
	dc.l	wait9,wait91
	dc.l	waita,waita1
	dc.l	waitb,waitb1
	dc.l	wait0,wait01
	dc.l	wait1,wait11
	dc.l	wait2,wait21
	dc.l	wait3,wait31
	dc.l	$8000

;-------

waits:	bsr.s	waitr
	dbf	d1,waits
	rts

;-------

waitr:	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#$12f00,d0
	bne.s	waitr
.w:	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#$12f00,d0
	beq.s	.w
	rts


;-----------------------
;--- INIT

o4o:	dc.b	0		; $ff, wenn >= 68040
smc:	dc.b	0		; wenn 0, dann tmap030
	even

init:
	lea	phong_map-256*256,a0
	lea	phong_map+256*256,a1
	move	#256*256/4-1,d7
	moveq	#-1,d0
.ha	move.l	d0,(a0)+
	move.l	d0,(a1)+
	dbf	d7,.ha

	IFD	m_transparent
;	bsr	init_addtab
	moveq	#0,d0
	move	#255,d1
	move	d1,d2
	moveq	#0,d5
	move	#255,a6
	moveq	#0,d6
	bsr	trans_limes3
	ENDC

	IFD	m_fog
	moveq	#0,d0
	moveq	#84,d1
	bsr	init_fogtab
	moveq	#85,d0
	move	#255,d1
	bsr	init_fogtab
	ENDC

	IFNE	m_gouraud_tmap_v|m_phong_tmap_v
	bsr	init_circtab
	ENDC
	IFD	m_gouraud_tmap
	bsr	init_gouraud_map
	ENDC
	IFD	m_phong_tmap
	bsr	init_phong_map
	ENDC

	bsr	init_divtab		; Divisionstabelle fuer muls 1/x
	bsr	init_angtab		; Delta unpacking

	bsr	init_sin		; Sinustabelle aufbauen
	bne.b	e_failed_tmp		; kein Speicher fuer temp. 40kb tab

	move.l	4.w,a6
	moveq	#%1000,d0
	lea	o4o(pc),a0
	and	296(a6),d0
	sne	(a0)			; $ff wenn >= 68o4o

	lea	smc(pc),a1
	move.b	(a0),(a1)


	IFND	debug
	bsr	takesystem		; System-Shutdown
	bne.b	e_startuperror		; Error!

	move.l	vbrptr(pc),a2
	lea	irq_3(pc),a0
	lea	trap0(pc),a1
	move.l	$6c(a2),(a0)
	move.l	$80(a2),(a1)
	move.l	#irq3,$6c(a2)		; Framezaehler
	ENDC

	bsr	pre_spline_t_tab	; P(x) coeffs pretablen
	IFD	_3ds
	bsr	pre_spline_t_tab_3ds
	ENDC

	moveq	#0,d0
	rts

;-

e_failed_tmp:
	lea	e_status(pc),a0
	moveq	#2,d0			; No Public
	move.l	d0,(a0)
	rts

e_startuperror:
	lea	e_status(pc),a0
	moveq	#3,d0
	move.l	d0,(a0)
	rts

;-----------------------
;--- RESTORE

restore:
	IFND	debug
	move.l	vbrptr(pc),a2
	move.l	trap0(pc),$80(a2)
	move.l	irq_3(pc),$6c(a2)
	bsr	freesystem
	ENDC

	move.l	e_status(pc),d0
	rts

e_status:	dc.l	0

;------------

trap0:		dc.l	0
irq_3:		dc.l	0
irq_cnt:	dc.w	0
abs_fr_cnt:	dc.l	0


irq3:	movem.l	d0/a6,-(a7)
	lea	$dff002,a6
	move	$1e-2(a6),d0
	and	$1c-2(a6),d0
	btst	#6,d0
	bne.s	irq3_blit
	move	#$20,$009c-2(a6)
	move	#$20,$009c-2(a6)

	lea	irq_cnt(pc),a6
	addq	#1,(a6)
	lea	abs_fr_cnt(pc),a6
	addq.l	#1,(a6)

irq3_q:	movem.l	(a7)+,d0/a6
	tst	$dff002
	tst	$dff01e
	nop
	rte

;-

irq3_blit:
	move	#$40,$9c-2(a6)
	move	#$40,$9c-2(a6)

	tst.b	o4o(pc)
	bne.s	irq3_q

	movem.l	a0/a1/a2,-(a7)

	lea	blit_pass_pt,a0
	move	#1,blit_st
	move.l	(a0),d0
	beq.s	.irq3_b
	move.l	d0,a1
	move.l	(a1)+,d0
	beq.s	.irq3_c
	move.l	d0,a2
	jsr	(a2)
	move.l	a1,(a0)

.irq3_b:
	movem.l	(a7)+,a0/a1/a2

	bra.s	irq3_q

.irq3_c:
	clr	blit_st
	bra.s	.irq3_b

;----------

main:	move	$1e-2(a6),d0		; Wait for Soft-bit in INTREQR
	and	#4,d0
	beq.s	main
	move	#4,$9c-2(a6)		; Clear the bit

	IFD	intro
	bsr	anim_obj
	ENDC

	bsr	ps256_clear

	IFD	_3ds
	tst	_3ds_st(pc)
	beq.s	.d
	bsr	do_3ds_trk
	bsr	do_3ds_cam
	bra.s	.c
.d:	ENDC
	bsr	do_cam
.c:	IFD	bbox
	bsr	chk_bbox
	ENDC

	lea	rotangle(pc),a5
	bsr	rotxyz			; Punkte rotieren
	bsr	ddcalc			; Punkte projezieren

	bsr	zclip
	bsr	skeitp

	bsr	fl_4_sort
	bsr	sort_fl			; Group-Sort der Flaechen

	lea	rotangle(pc),a5
	bsr	rot_xy_p		; Normal'orts'vektoren berechnen
	bsr	map_pkts

	tst.b	o4o(pc)
	bne.s	.a
	lea	t0_off(pc),a0
	move.l	vbrptr(pc),a1
	move.l	a0,$80(a1)
	trap	#$0
.a:
	bsr	ps256_fill

	tst.b	o4o(pc)
	bne.s	.bx
	lea	t0_on(pc),a0
	move.l	vbrptr(pc),a1
	move.l	a0,$80(a1)
	trap	#$0
.bx:

	pea	adj_movement(pc)
	pea	swop(pc)
	jmp	c2p_1x1

;---

t0_off:	movec	cacr,d0
	move	#$a111,d0
	movec	d0,cacr
	rte

t0_on:	movec	cacr,d0
	move	#$b111,d0
	movec	d0,cacr
	rte

;---------


chipmemptr:	ds.l	1
planeptr1:	ds.l	4	; Zeichnen, Loeschen, Warten, Zeigen
clistptr:	ds.l	1

;--- Globals

ysize_:		dc	yysize	; Screenhoehe (virtuell)
ysize_scr:	dc	0	; Screenhoehe (physikalisch)
xsize_scr:	dc	xsize,0	; Screenbreite (2. Wort musz 0 bleiben!)
plnr_scr:	dc	0	; Anzahl der Planes

half_scr:	dc	0	; <> 0 -> Screenhoehe halbieren
ntsc:		dc	0	; <> 0 -> NTSC mode

fl_4_sort_st:	dc	0	; <> 0 -> Zmin jedes Tris bestimmen
clear_st:	dc	0	; <> 0 -> Buffer wird nicht geloescht

	IFD	m_fog
fog_st:		dc	0	; <> 0 -> Lin. Farbinterpolation bei Mapping
fog_min:	dc	50*2^subpixel	; zwischen fog_min und fog_max
fog_max:	dc	150*2^subpixel
	ENDC

	IFD	bbox
bbox_st:	dc	0	; <> 0 -> Vertices und Tris auf Bounding-Box
				;	  ueberpruefen
	IFD	bsphere
bbrad:		dc.l	(1500*4)^2	; max. 16384^2 (wg. 2^14)
	ELSE
bbxmin:		dc	0	; Vergleichswerte fuer Bounding-Box
bbxmax:		dc	0
bbymin:		dc	0
bbymax:		dc	0
bbzmin:		dc	0
bbzmax:		dc	0
	ENDC
	ENDC

g_l_element_l:	dc	0	; In order to access g_l_element as .l
g_l_element:	dc	0	; Groesse eines G-List Elements!

;-------------------------------

gen_allocchip:
	move.l  4.w,a6
        move.l  #$10002,d1              ; type of mem=chip,cleared
        jsr     AllocMem(a6)
	tst.l	d0
	rts
;----------

gen_allocpublic:
	move.l  4.w,a6
        moveq	#1,d1              	; type of mem=public
        jsr     AllocMem(a6)
	tst.l	d0
	rts
gen_free:
	move.l	4.w,a6
        jmp     FreeMem(a6)

;--------------------

	IFNE	m_transparent_v|m_flare_v
;init_addtab:
;	move.l	addtab_p(pc),a0
;
;	move	#256-1,d6
;	moveq	#0,d1
;
;.b:	move	#256-1,d7
;	moveq	#0,d0
;
;.a:	move.l	d0,d2
;	add.l	d1,d2
;.c:	move.b	d2,(a0)+
;	addq.l	#1,d0
;	dbf	d7,.a
;	addq.l	#1,d1
;	dbf	d6,.b
;	rts

addtab_p:	dc.l	addtab

;---
; Hintergrundfarbe
; d0 = untere grenze
; d1 = (einschlieszlich) obere grenze
;
; Vordergrundfarbe
; d5 = untere grenze
; a6 = (einschlieszlich) obere grenze
;
; d2 = overflow value
; d6 = offset value

trans_limes:
	moveq	#0,d5
	move	#255,a6
	moveq	#0,d6

trans_limes2:
	move.l	addtab_p(pc),a0

	moveq	#0,d3
	move	d0,d3
	sub	d0,d1
	lsl	#8,d3
	add.l	d3,a0

	sub	d5,a6
	add	d5,a0
	moveq	#0,d0
	moveq	#0,d5

.b:	move	a6,d7
	move.l	a0,a1
	move	d5,d4
.a:	move	d0,d3
	add	d4,d3
	addq.l	#1,d4
	asr	#1,d3
	cmp	d2,d3
	blo.s	.c
	move.b	d2,(a1)
	add.b	d6,(a1)+
	bra.s	.d
.c:	move.b	d3,(a1)
	add.b	d6,(a1)+
.d:	dbf	d7,.a
	addq	#1,d0
	lea	256(a0),a0
	dbf	d1,.b
	rts

trans_limes3:
	move.l	addtab_p(pc),a0

	sub	d0,d2

	moveq	#0,d3
	move	d0,d3
	sub	d0,d1
	lsl	#8,d3
	add.l	d3,a0

	sub	d5,a6
	add	d5,a0
	moveq	#0,d0
	moveq	#0,d5

.b:	move	a6,d7
	move.l	a0,a1
	move	d5,d4
.a:	move	d0,d3
	add	d4,d3
	addq.l	#1,d4
	cmp	d2,d3
	blo.s	.c
	move.b	d2,(a1)
	add.b	d6,(a1)+
	bra.s	.d
.c:	move.b	d3,(a1)
	add.b	d6,(a1)+
.d:	dbf	d7,.a
	addq	#1,d0
	lea	256(a0),a0
	dbf	d1,.b
	rts

	ENDC

;--------------------

	IFD	m_fog
init_fogtab:
	move.l	fogtab_p(pc),a0
	move.l	#256,d7
	sub.l	a1,a1
	bra.s	init_gtab_ei

fogtab_p:	dc.l	fogtab
	ENDC

;---

	IFNE	m_gouraud_tmap_v|m_phong_tmap_v|m_tbump_v
; d0 = untere grenze
; d1 = obere grenze (einschliesslich)

init_gttab:
	move.l	gouraudtab_p(pc),a0
	move.l	#128,d7
	lea	128*$100,a1
	move.l	d0,-(a7)
	move.l	d1,-(a7)
	bsr.s	init_gtab_ei
	move.l	(a7)+,d1
	move.l	(a7)+,d0

	move	d1,d2
	sub	d0,d1

.b:	move	d2,d4
	move	d0,d3
	sub	d0,d4
	swap	d3
	swap	d4
	clr	d3
	clr	d4
	divu.l	d7,d4

	move	d7,d5
	move.l	a1,d6
	subq	#1,d5
.a:	sub	#$100,d6
	swap	d3
	move.b	d0,d6
	move.b	d3,(a0,d6.l)
	swap	d3
	add.l	d4,d3
	dbf	d5,.a

	addq	#1,d0
	dbf	d1,.b
	rts
;-
init_gtab_ei:
	move	d0,d2

	sub	d0,d1

.b:	move	d0,d4
	move	d0,d3
	sub	d2,d4
	swap	d3
	swap	d4
	clr	d3
	clr	d4
	divu.l	d7,d4

	move	d7,d5
	move.l	a1,d6
	subq	#1,d5
.a:	swap	d3
	move.b	d0,d6
	move.b	d3,(a0,d6.l)
	swap	d3
	add	#$100,d6
	sub.l	d4,d3
	dbf	d5,.a

	addq	#1,d0
	dbf	d1,.b

	rts

gouraudtab_p:	dc.l	gouraudtab
	ENDC

;--------------------

	IFNE	m_gouraud_tmap_v|m_phong_tmap_v
init_circtab:
	lea	circtab,a0
	add.l	#363*363*2,a0
	move	#363-1,d0
.a:	move	d0,d1
	add	d1,d1
.b:	move	d0,-(a0)
	dbf	d1,.b
	dbf	d0,.a
	rts

;---

init_circ_map:
	move	#$ff,d4
	moveq	#-$7f,d5
	lea	circtab,a0
	move	d4,d7
	move	d5,d0
.aa:	move	d4,d6
	move	d5,d1
	move	d0,d2
	muls	d2,d2
.ba:	move	d1,d3
	muls	d3,d3
	add.l	d2,d3
	move	(a0,d3.l*2),d3
	and	#$ff,d3
;	not.b	d3
	add	d3,d3
	sub	a1,d3
	bpl.s	.da
	moveq	#0,d3
.da:	cmp	#241,d3
	blt.s	.ca
	move	#240,d3
.ca:	move.b	d3,(a6)+
	addq	#1,d1
	dbf	d6,.ba
	addq	#1,d0
	dbf	d7,.aa
	rts
	ENDC

;--------------------

	IFD	m_gouraud_tmap
init_gouraud_map:
	lea	gouraud_map,a6
	sub.l	a1,a1
	bra.s	init_circ_map
	ENDC

;--------------------

	IFD	m_phong_tmap
init_phong_map:
	lea	phong_map,a6
	lea	40.w,a1
	bra.s	init_circ_map
	ENDC

;--------------------
; a0 = heightmap
; a1 = bumptab

	IFNE	m_bump_v|m_tbump_v
bump2d:	moveq	#-1,d7
b2d_ag:	moveq	#0,d0
	moveq	#0,d1
	moveq	#0,d2
	moveq	#0,d3
	moveq	#0,d4
	move.b	-1(a0),d0
	move.b	-(256+1)(a0),d1
	move.b	-(256)(a0),d2
	add.w	d2,d0
	add.w	d1,d0
	move.b	(256-1)(a0),d1
	move.b	256(a0),d2
	move.b	(256+1)(a0),d3
	add.w	d3,d1
	add.w	d2,d1
	move.b	-(256-1)(a0),d2
	move.b	1(a0),d4
	add.w	d4,d2
	add.w	d3,d2
	move.w	d0,d3
	sub.w	d2,d0
	sub.w	d1,d3
	ext.l	d0
	ext.l	d3
	sub.l	d3,d0
	asl.l	#8,d3
	add.l	d0,d3
	move	d3,(a1)+
	addq.l	#1,a0
	dbf	d7,b2d_ag
	rts	
	ENDC

;--------------------

init_angtab:
	lea	angtab+2(pc),a0
	move	#$802/2-2,d7
	moveq	#0,d0
iang1:	add	(a0),d0
	move	d0,(a0)+
	dbf	d7,iang1
	rts

;--------------------

init_divtab:
	move.l	divtab_p(pc),a1

	IFD	negdivtab
	move	#2^g_range-1,d7
	move.l	a1,a0

	moveq	#-1,d1
	move.l	#$7fff,d2
g_id:	move.l	d2,d0
	divs	d1,d0
	subq	#1,d1
	move	d0,-(a0)
	dbf	d7,g_id
	ENDC

	move	#2^g_range-2,d7
	moveq	#1,d1
	move.l	#$7fff,d2
	clr	(a1)+
g_id2:	move.l	d2,d0
	divs	d1,d0
	addq	#1,d1
	move	d0,(a1)+
	dbf	d7,g_id2
	rts

;--- Calc Sinuswave (size $2800 using a temporary $e000 sized one)

sinp:	dc.l	sinvalues

is_bt:	dc.l	0
is_sv:	dc.l	0

init_sin:
        move.l  #$800*4*2+$a000,d0
	bsr.w	gen_allocpublic
	beq.s	is_failed

	lea	is_bt(pc),a0
        move.l	d0,(a0)
	add.l	#$800*4*2,d0
	lea	is_sv(pc),a0
	move.l	d0,(a0)
	
	bsr	do_bf_sin
	bsr.s	do_is

	move.l	is_sv(pc),a0
	move.l	sinp(pc),a1
	move	#$2800/2-1,d0
is_5:	move	(a0),(a1)+
	addq.l	#4*2,a0
	dbf	d0,is_5

	move.l	is_bt(pc),a1
        move.l  #$800*4*2+$a000,d0
	bsr.w	gen_free
	moveq	#0,d0
	rts
is_failed:
	moveq	#-1,d0
	rts

is_2:	move.w	d0,d1
	swap	d0
	lea	0(a1,d0.w*2),a2
	lsr.w	#5,d1
	lea	0(a0,d1.w*8),a3
	move.w	(a2)+,d0
	muls	(a3)+,d0
	move.w	(a2)+,d1
	muls	(a3)+,d1
	add.l	d1,d0
	move.w	(a2)+,d1
	muls	(a3)+,d1
	add.l	d1,d0
	move.w	(a2)+,d1
	muls	(a3)+,d1
	add.l	d1,d0
	add.l	d0,d0
	swap	d0
	rts

do_is:	move.l	is_bt(pc),a0
	lea	istab(pc),a1
	move.l	is_sv(pc),a4
	moveq	#0,d7

is_1:	move.l	d7,d0
	bsr.s	is_2
	add.w	d0,d0
	bvc.s	is_3
	move.w	#$7fff,d0
is_3:	move.w	d0,(a4)+
	add.l	#$80,d7
	cmp.l	#$80000,d7
	bne.s	is_1
	move.l	a4,a0
	lea	$4000(a0),a1
	move.l	a1,a2
	lea	$4000(a1),a3
	move.w	#$fff,d0
is_4:	move.w	-(a4),d1
	move.w	d1,(a0)+
	move.w	d1,-(a3)
	neg.w	d1
	move.w	d1,-(a1)
	move.w	d1,(a2)+
	dbra	d0,is_4
	rts

istab:	dc.w	$f36f,1
	dc.w	$c91,$18a6
	dc.w	$23ca,$2d8c
	dc.w	$358f,$3b83
	dc.w	$3f2d,$406a
	dc.w	$3f2d

do_bf_sin:
	move.l	is_bt(pc),a0
	moveq	#0,d7
bf_sin1:
	moveq	#1,d0
	swap	d0
	move.l	d0,d2
	moveq	#4,d1
	move	d1,d0
	swap	d1
	moveq	#0,d3
	move	d7,d4
	move	d7,d5
	mulu	d5,d5
	swap	d5
	move	d5,d6
	mulu	d7,d6
	swap	d6
	mulu	#3,d4
	sub.l	d4,d0
	add.l	d4,d2
	mulu	#3,d5
	add.l	d5,d0
	add.l	d5,d2
	sub.l	d5,d1
	sub.l	d5,d1
	mulu	#1,d6
	sub.l	d6,d0
	add.l	d6,d3
	mulu	#3,d6
	add.l	d6,d1
	sub.l	d6,d2
	moveq	#12,d4
	divu	d4,d0
	divu	d4,d1
	divu	d4,d2
	divu	d4,d3
	movem	d0-d3,(a0)
	addq.l	#8,a0
	add	#$20,d7
	bcc.s	bf_sin1
	rts

;---
	IFD	_3ds
do_3ds_trk:
	move.l	objecttrk(pc),d0
	beq.w	.q
	move.l	d0,a0

.w:	tst.l	(a0)+
	bmi.w	.q

	move.l	(a0)+,a1
	move.l	2+4(a0),d0
	addq.l	#2,a1
	lea	objpos(pc),a4
	bsr	do_spline_3ds
	pea	(a0)

	move.l	2+4+4+2(a0),d0
	move.l	normal_st_p(pc),a5
	move.l	objectpp(pc),a2
	move.l	normal_zv2_p(pc),a6
	add.l	d0,a5

	add.l	d0,d0			; *2
	move.l	koordxyz_sp_p(pc),a1
	move.l	d0,d1
	add.l	d0,d0			; *4
	move	2+4+4(a0),d7
	add.l	d1,d0			; *6
	move.l	2+4+4+2+4(a0),d2
	lea	2+4+4+2+12(a0),a3
	move.l	normal_zv_p(pc),a0

	add.l	d0,a2
	add.l	d0,a1
	add.l	d0,a6
	add.l	d0,a0

	tst.l	d2
	beq.w	.t

.ag	move	(a2)+,d0
	move	(a2)+,d2
	move	(a2)+,d1

	move.l	d0,d3
	move.l	d1,d4
	move.l	d2,d5
	muls	(a3),d3
	muls	2*2(a3),d4
	muls	4*2(a3),d5
	add.l	d3,d4
	add.l	d5,d4
	add.l	d4,d4
	move.l	d0,d3
	swap	d4
	move.l	d2,d5
	add	(a4),d4

	move	d4,(a1)

	move.l	d1,d4
	muls	6*2(a3),d3
	muls	(6+2)*2(a3),d4
	muls	(6+4)*2(a3),d5
	add.l	d3,d4
	add.l	d5,d4
	add.l	d4,d4
	swap	d4
	add	4(a4),d4
	move	d4,4(a1)

	muls	(6+6)*2(a3),d0
	muls	(6+6+2)*2(a3),d1
	muls	(6+6+4)*2(a3),d2
	add.l	d0,d1
	add.l	d2,d1
	add.l	d1,d1
	swap	d1
	add	2(a4),d1
	move	d1,2(a1)

	addq.l	#6,a1

	tst.b	(a5)+
	bne.s	.non

	move	(a6)+,d0
	move	(a6)+,d2
	move	(a6)+,d1

	move.l	d0,d3
	move.l	d1,d4
	move.l	d2,d5
	muls	(a3),d3
	muls	2*2(a3),d4
	muls	4*2(a3),d5
	add.l	d3,d4
	add.l	d5,d4
	subq.l	#6,a6
	add.l	d4,d4
	move.l	d0,d3
	swap	d4
	move.l	d2,d5
	add	(a4),d4

	move	d4,(a0)

	move.l	d1,d4
	muls	6*2(a3),d3
	muls	(6+2)*2(a3),d4
	muls	(6+4)*2(a3),d5
	add.l	d3,d4
	add.l	d5,d4
	add.l	d4,d4
	swap	d4
	add	4(a4),d4
	move	d4,4(a0)

	muls	(6+6)*2(a3),d0
	muls	(6+6+2)*2(a3),d1
	muls	(6+6+4)*2(a3),d2
	add.l	d0,d1
	add.l	d2,d1
	add.l	d1,d1
	swap	d1
	add	2(a4),d1
	move	d1,2(a0)

.non:	addq.l	#6,a6
	addq.l	#6,a0
	dbf	d7,.ag

.we:	move.l	(a7)+,a0
	lea	2+4+4+2+4+8+9*2*4(a0),a0
	bra.w	.w

.t:	movem	(a4),d3-d5
.tw:	movem	(a2)+,d0-d2
	add	d3,d0
	add	d4,d1
	add	d5,d2
	move	d0,(a1)+
	move	d1,(a1)+
	move	d2,(a1)+

	tst.b	(a5)+
	bne.s	.non2

	movem	(a6),d0-d2
	add	d3,d0
	add	d4,d1
	add	d5,d2
	move	d0,(a0)
	move	d1,2(a0)
	move	d2,4(a0)

.non2:	addq.l	#6,a6
	addq.l	#6,a0
	dbf	d7,.tw
	bra.s	.we
.q:	rts

;---

do_3ds_cam:
	move.l	pointsp2(pc),a1
	lea	objpos(pc),a4
	addq.l	#2,a1
	move.l	a4,a5
	move.l	slidetoff(pc),d0
	bsr	do_spline_3ds

	move.l	pointsp(pc),a1
	lea	camera(pc),a4
	addq.l	#2,a1
	move.l	slideoff(pc),d0
	bsr	do_spline_3ds

	move	(a4)+,d0
	move	(a4)+,d1
	move	(a4),d2
	sub	(a5)+,d0
	sub	(a5)+,d1
	sub	(a5),d2

	move	d2,(a4)
	move	d1,-(a4)
	move	d0,-(a4)

	bra	calc_camera		; winkel + entfernung berechnen.
	ENDC

;--- Adjust movement according to how many frames have passed

adj_movement:

	IFD	intro
	move.l	anim_obj_adj_p(pc),d0
	beq.s	.a
	move.l	d0,a0
	jsr	(a0)
.a:	ENDC

	IFD	_3ds
	tst	_3ds_st(pc)
	beq.s	.c
	bsr.s	_3ds_camera
	bra.s	.w
.c:	ENDC
	bsr.w	am_camera

.w:	subq	#1,irq_cnt
	bgt.s	adj_movement
	rts
;---

	IFD	_3ds
_3ds_camera:
	lea	keyf_cnt(pc),a0
	lea	slide(pc),a1

	subq	#1,(a0)
	bpl.s	.a

	move	keyf_e(pc),(a0)
	bra	init_keyf

.a	lea	pointsp(pc),a0
	lea	slideadd(pc),a2
	lea	slideoff(pc),a3

	subq	#1,(a1)
	bne.s	.c

	pea	.d(pc)
	bra	get_next_key

.c	move.l	(a2),d0
	add.l	d0,(a3)
.d	
;-
	lea	slidet(pc),a1
	lea	pointsp2(pc),a0
	lea	slidetadd(pc),a2
	lea	slidetoff(pc),a3

	subq	#1,(a1)
	bne.s	.ct

	pea	.dt(pc)
	bra	get_next_key

.ct	move.l	(a2),d0
	add.l	d0,(a3)
.dt:
;-
	move.l	objecttrk(pc),d0
	beq.s	.q
	move.l	d0,a0

.w:	tst.l	(a0)+
	bmi.s	.q

	lea	4(a0),a1
	lea	4+2(a0),a2
	lea	4+2+4(a0),a3

	subq	#1,(a1)
	bne.s	.ctt

	pea	.dtt(pc)
	bra	get_next_key

.ctt:	move.l	(a2),d0
	add.l	d0,(a3)

.dtt:	lea	llerpcnt(pc),a1
	lea	4+2+4+4+2+4+4+4(a0),a0
	subq	#1,(a1)
	beq.s	.nll

	lea	9*4(a0),a1
	moveq	#9-1,d7
.w2:	move.l	(a1)+,d0
	add.l	d0,(a0)+
	dbf	d7,.w2
	move.l	a1,a0
	bra.s	.w

.nll:	add.l	#3*3*2,-(a0)
	move	#llerp,(a1)
	bsr.w	get_next_llerp
	lea	4+9*2*4(a0),a0
	bra.s	.w
;-
.q:	rts
	ENDC

;---

get_nk:
	move.l	(a0),a5
	tst	(a5,d1.l*4)
	bpl.s	.a
	move	#1,(a1)
	rts
.a:	add.l	d1,(a0)
get_k:	move.l	(a0),a5
	moveq	#0,d0
	move	(a5,d1.l*2),d0
	sub	(a5,d1.l),d0

	move.l	divtab_p(pc),a5
	move	d0,(a1)

	move	(a5,d0.w*2),d0
	clr.l	(a3)
	lsl.l	#3,d0
	move.l	d0,(a2)
	rts

;---

am_camera:
	lea	slide(pc),a1
	lea	pointsp(pc),a0
	lea	slideadd(pc),a2
	lea	slideoff(pc),a3
	moveq	#8,d1

	subq	#1,(a1)
	bne.s	.c

	move.l	(a0),a5
	tst	(a5,d1.l*4)
	bpl.s	.w4
	bra	init_keyf

.w4:	pea	.d(pc)
	bra	get_nk

.c	move.l	(a2),d0
	add.l	d0,(a3)
.d	
;-
	lea	slidet(pc),a1
	lea	pointsp2(pc),a0
	lea	slidetadd(pc),a2
	lea	slidetoff(pc),a3
	tst.l	(a0)
	beq.s	.dt

	subq	#1,(a1)
	bne.s	.ct

	pea	.dt(pc)
	bra	get_nk

.ct	move.l	(a2),d0
	add.l	d0,(a3)
.dt:
;-
	lea	slidez(pc),a1
	lea	pointsp3(pc),a0
	lea	slidezadd(pc),a2
	lea	slidezoff(pc),a3
	tst.l	(a0)
	beq.s	.dt2
	moveq	#4,d1

	subq	#1,(a1)
	bne.s	.ct2

	pea	.dt2(pc)
	bra	get_nk

.ct2	move.l	(a2),d0
	add.l	d0,(a3)
.dt2:
;-
	rts

;---

do_cam:
	tst.l	objectmp3(pc)
	beq.s	.c

	move.l	pointsp3(pc),a1
	lea	rotangle+4(pc),a4
	addq.l	#2,a1
	move.l	slidezoff(pc),d0
	bsr	do_spline1_3
	and	#$1ffe,(a4)
.c:

	move.l	pointsp2(pc),a1
	lea	objpos(pc),a4
	addq.l	#2,a1
	move.l	a4,a5

	tst.l	objectmp2(pc)
	bne.s	.a
	clr.l	(a4)+
	clr	(a4)
	bra.s	.aa

.a:	move.l	slidetoff(pc),d0
	bsr	do_spline
.aa:
	move.l	pointsp(pc),a1
	lea	camera(pc),a4
	addq.l	#2,a1
	move.l	slideoff(pc),d0
	bsr	do_spline

	move	(a4)+,d0
	move	(a4)+,d1
	move	(a4),d2
	sub	(a5)+,d0
	sub	(a5)+,d1
	sub	(a5),d2

	move	d2,(a4)
	move	d1,-(a4)
	move	d0,-(a4)

	bra	calc_camera		; winkel + entfernung berechnen.

;--- Do quadruple Buffering

swop:	lea	planeptr1(pc),a0
	movem.l	(a0),d0-d3
	movem.l	d1-d3,(a0)
	move.l	d0,12(a0)

	move.l	clistptr(pc),a0
	move	plnr_scr(pc),d7

	lea	planes-clist+2(a0),a0

	moveq	#xsize/8,d1
	subq.l	#1,d7

	mulu	ysize_scr(pc),d1

	move.l	#$1ff00,d2
sw_1:	move.l	$dff004,d6
	and.l	d2,d6
	tst.l	d6			; Zeile 0?
	beq.s	sw_1
sw_2:	move.l	$dff004,d6
	and.l	d2,d6
	cmp.l	#$00100,d6		; Zeile 1?
	beq.s	sw_2

swapag:	move	d0,4(a0)
	swap	d0
	move	d0,(a0)
	swap	d0
	addq.l	#8,a0
	add.l	d1,d0
	dbf	d7,swapag

	IFD	debug
	move.l	clistptr(pc),$dff080
	ENDC
	rts

;-------------------------------------------------------

	include	"i/other/my_demOS.s"

;----------------------------------------------------------------

;objstruct:
;	dc.w	rpoints-1		; Anz. d. Punkte des Objekts
;	dc.w	flanz-1			; Anz. d. Flaechen des Objekts
;	dc.l	objpkt			; Pointer auf Punkte d. Objekts
;	dc.l	objtab			; Pointer auf Vertextabelle d. Obj.
;	dc.l	objlst			; Pointer auf Liste d. gruppierten Fl.
;					; des Objekts fuers Sortieren.
;	dc.l	objinit			; Routine fuer lokale Init. d. Obj.
;	dc.l	objcols			; Farben des Objekts
;	dc.l	objtypelist		; Pointerliste der Tris auf Texturen
;					; bei NULL standardmap von map_p
;	dc.l	objm			; Movementdaten der Kamera
;	dc.l	0			; bei '0' -> Blick gen Ursprung (0,0,0)
;					; sonst ptr auf Movementdaten d. Kamera
;	dc.l	0			; ptr auf Spline fuer Z-Rotation

; Wenn Normale verwendet werden, dann muss der type <= t_n_lim sein.
; Wenn Edges to Mem gescannt werden, muss der type >= t_em_lim sein.
; Wenn Edges to Mem gescannt und Normale verwendet werden, muss der
; type >= t_emn_lim sein.

; Bei m_fog wird folgendes ggf. durch t_fogmap ersetzt:
; t_phong, t_texmap, t_phong030, t_texmap030

					IFD	m_fog
t_fog		=	$10	; Offset fuer Jumptable
					ENDC
t_n_lim		=	2
t_em_lim	=	13
t_emn_lim	=	14

	IFD	m_bi_map
t_bi_phong	=	0
	ENDC

	IFD	m_transparent
t_transphong	=	1
	ENDC

t_phong		=	t_n_lim
t_texmap	=	t_n_lim+1
					IFD	m_transparent
t_transtexmap	=	t_n_lim+2
					ENDC
					IFD	m_bi_map
t_bi_texmap	=	t_n_lim+3
					ENDC
					IFD	m_gouraud_tmap
t_gouraud_tmap	=	t_n_lim+4
t_gouraud_env	=	t_n_lim+5
					ENDC

					IFD	m_phong_tmap
t_phong_tmap	=	t_n_lim+6
					ENDC

					IFD	m_bump
t_bump		=	t_n_lim+7
					ENDC

					IFD	m_tbump
t_tbump		=	t_n_lim+8
					ENDC

					IFD	m_flare
t_flare		=	t_n_lim+9
					ENDC

					IFD	m_bboard
t_bboard		=	t_n_lim+10
					ENDC
					
t_texmap030	=	t_em_lim
t_phong030	=	t_emn_lim


;objtypelist:				; Eigenschaften der Tris
;	dc	t_bi_phong		; Typ 0 = Pseudobilinears Phong
;	dc.l	texture
;
;	dc	t_transphong		; Typ 1 = Transparent Phong/Env
;	dc.l	texture
;
;	dc	t_phong			; Typ 2 = Phong/Env
;	dc.l	texture
;
;	dc	t_texmap		; Typ 3 = Lineares Mapping
;	dc.l	texture
;	dc	x1,y1
;	dc	x2,y2
;	dc	x3,y3
;
;	dc	t_transtexmap		; Typ 4 = Transparent Texturemapping
;					; (rest wie t_texmap)
;
;	dc	t_bi_texmap		; Typ 5 = Pseudobilinear
;					; (rest wie t_texmap)
;
;	dc	t_gouraud_tmap		; Typ 6 = Gouraudshaded Texturemapping
;					; (rest wie t_texmap)
;
;	dc	t_gouraud_env		; Typ 7 = Gouraudshaded Envmapping
;	dc.l	texture
;
;	dc	t_phong_tmap		; Typ 8 = Phongshaded Texturemapping
;	dc.l	texture
;	dc	x1,y1
;	dc	x2,y2
;	dc	x3,y3
;	dc.l	phongtexture
;
;	dc	t_bump			; Typ 9 = Bumpmapping
;	dc.l	bumptexture
;	dc	x1,y1
;	dc	x2,y2
;	dc	x3,y3
;	dc.l	phongtexture
;
;	dc	t_tbump			; Typ 10 = Textured Bumpmapping
;	dc.l	bumptexture
;	dc	x1,y1
;	dc	x2,y2
;	dc	x3,y3
;	dc.l	phongtexture		; muss 64k davor und danach -1 sein!
;	dc.l	texture
;
;	dc	t_flare			; Typ 11 = Flare
;	dc.l	flaremap
;	dc	xwidth,ywidth
;
;	dc	t_bboard		; Typ 12 = Billboard
;	dc.l	billboardmap
;	dc	xwidth,ywidth
;
;
;(	dc	t_texmap030		; Typ 13 = Lineares Mapping) INTERN!
;
;(	dc	t_phong030		; Typ 14 = Phong/Env) INTERN!

;--- Init 3d-Object related structures!

map_p:	dc.l	0

	IFD	_3ds
_3ds_st:	dc	0	; <> 0 -> 3ds output spezifische Annahmen
keyf_e:		dc	0	; Anzahl der Frames-1
keyf_cnt:	dc	0

init_obj_3ds:
	lea	_3ds_st(pc),a2
	move	#1,(a2)
	move	d0,keyf_e-_3ds_st(a2)
	move	d0,keyf_cnt-_3ds_st(a2)
	bsr	init_typel
	ENDC
init_obj:
	lea	rotangle+4(pc),a1
	clr	(a1)

	lea	anzpkt(pc),a1
	move	(a0)+,(a1)		; Anz. d. Punkte des Objekts -1
	move	(a0)+,anzfl-anzpkt(a1)	; Anz. d. Flaechen des Objekts -1
	move.l	(a0)+,objectpp-anzpkt(a1); Pointer auf Punkte d. Objekts
	move.l	(a0)+,objecttp-anzpkt(a1); Pointer auf Vertextabelle d. Obj.
	move.l	(a0)+,objectlp-anzpkt(a1); Pointer auf Liste d. gruppierten Fl.
					; des Objekts fuers Sortieren.
	move.l	(a0)+,objectip-anzpkt(a1); Routine fuer lokale Init. d. Obj.
	move.l	(a0)+,objectcp-anzpkt(a1); Farben des Objekts
	move.l	(a0)+,objecttexp-anzpkt(a1)	; Pointerlist auf Texturen
	move.l	(a0)+,objectmp-anzpkt(a1); Movementdaten der Kamera
	move.l	(a0)+,objectmp2-anzpkt(a1)	; Movementdaten des Obj.
	move.l	(a0)+,objectmp3-anzpkt(a1)	; Movementdaten der Z-Axis
	IFD	_3ds
	tst	_3ds_st(pc)
	beq.s	.w
	move.l	(a0)+,objecttrk-anzpkt(a1)
.w:	ENDC
	bsr	init_keyf

	lea	ysize_scr(pc),a0
	move	ysize_(pc),(a0)
	tst	half_scr(pc)
	beq.s	io_nh
	lsr	(a0)

io_nh:
	lea	g_l_element(pc),a5
	move	#g_element,(a5)
	lea	plnr_scr(pc),a5
	move	#8,(a5)

	bsr	alloc_ltt_nv_sb		; Edgetable, Normals(2d), Screenbuffer
	bne	no_pub_mem		; allokieren

	bsr	init_ytab		; ytab mit line*xsize_scr initen
	bne.w	no_pub_mem

	bsr	alloc_scr		; Allocate mem for Planes+CList
	bne.s	no_chip_mem

	bsr	alloc_g_liste		; Allocate mem for G-List
	bne.s	no_pub_mem2

	bsr.w	alloc_obj_struct	; Allocate mem for Obj-structures
	bne.s	no_pub_mem3

	lea	objectip(pc),a0
	tst.l	(a0)			; Lokale Objektinitialisation?
	beq.s	no_obinit
	move.l	(a0),a0
	jsr	(a0)

no_obinit:
	lea	pointsp(pc),a5
	move.l	objectmp(pc),(a5)	; Spline-Controllpoints (camera)
	lea	pointsp2(pc),a5
	move.l	objectmp2(pc),(a5)	; Spline-Controllpoints (objpos)
	lea	pointsp3(pc),a5
	move.l	objectmp3(pc),(a5)	; Spline-Controllpoints (Z-Axis)

	bsr	cp_vert_sp		; Vertices ggf. mit Subpixel duplizieren
	bsr	build_obj_cols		; Farben d. Objs in die CList eintragen
	bsr	build_obj_tab		; Objecttab erstellen (sicht.w+vertex)
	bsr	build_objvert6		; objvert6 (vertices*6) erstellen
	bsr	build_lists		; Texturepointer in g_liste schreiben
	bsr	init_normal_st		; Normal_st liste initialisieren
	IFD	bbox
	bsr	default_vertex_st
	ENDC
	bsr	calc_normals		; Normalvektoren berechnen
	bsr	do_backup_pkts		; Vertices & Normale duplizieren
	jsr	init_c2p_o4o

	lea	group_sort(pc),a0
	tst.l	objectlp(pc)
	sne	(a0)
	bne.s	.no_a_sort
	bsr	alloc_sort_list
	bne.s	no_pub_mem4

.no_a_sort:
	moveq	#0,d0
	rts

group_sort:	dc.b	0		; 0=Kein Groupsort
		even

;---

no_chip_mem:
	bsr.s	free_o0
	moveq	#1,d0
	rts

no_pub_mem4:
	bsr.s	free_o4
	bra.s	no_pub_mem
no_pub_mem3:
	bsr.s	free_o3
	bra.s	no_pub_mem
no_pub_mem2:
	bsr.s	free_o2
no_pub_mem:
	moveq	#2,d0
	rts

free_o4:bsr	free_sort_list
free_o3:bsr	free_g_liste
free_o2:bsr	free_scr
free_o0:bra	free_ytab


;--- Free Object and Screen related Allocs.

free_obj:
	bsr	ps16_sb_free
	bsr	nvekxy_free
	bsr	ps16_ltt_free

free_obj3:
	tst.b	group_sort(pc)
	bne.s	free_obj2
	bsr	free_sort_list	

free_obj2:
	bsr	free_obj_struct		; Release Mem for Objtabs
	bsr	free_g_liste
	bsr	free_scr
	bra	free_ytab

;-----------------------------------------------------------
;--- Alloc Mem for Planes and Copperlist, and init the stuff

	include	"i/allocs_n_inits/alloc_scr.s"

;----------------------------------------------------
;--- ytab mit scanlinenummer*xsize_scr initialisieren

	include	"i/allocs_n_inits/init_ytab.s"

;--------------------------------

alloc_sort_list:
	move	anzfl(pc),d0
	addq	#1,d0
	mulu	#4+4+8,d0		; Fl.Anzahl*(4+4+8)
	move.l	d0,sort_list_size
	bsr.w	gen_allocpublic
	beq.s	sl_fail

	move.l	d0,sort_list_p
	move	anzfl(pc),d1
	addq	#1,d1
	mulu	#4,d1			; Fl.Anzahl*4
	add.l	d1,d0
	move.l	d0,sort_list_p2
	add.l	d1,d0
	move.l	d0,sort_list_gl_p	; Flanz*(4+4)

	move.l	sort_list_p2(pc),a0
	moveq	#0,d0
	move.l	objvert6_p(pc),a1
	move	anzfl(pc),d7
a_sl1:	move	d0,(a0)+
	addq.l	#8,d0
	move	(a1),d1
	addq.l	#6,a1
	move	d1,(a0)+	
	dbf	d7,a_sl1

	move.l	sort_list_gl_p(pc),a0
	move.l	objtab_p(pc),d2
	move.l	g_liste_p(pc),d0
	move.l	g_l_element_l(pc),d1
	move	anzfl(pc),d7
a_sl2:	move.l	d2,(a0)+
	addq.l	#8,d2
	move.l	d0,(a0)+
	add.l	d1,d0
	dbf	d7,a_sl2

	moveq	#0,d0
	rts
sl_fail:
	moveq	#2,d0
	rts

sort_list_p:	dc.l	0
sort_list_p2:	dc.l	0

sort_list_gl_p:	dc.l	0

sort_list_size:	dc.l	0

;---

free_sort_list:
	move.l	sort_list_p(pc),a1
	move.l	sort_list_size(pc),d0
	bra	gen_free

;----------------------

	IFD	bbox

chk_bbox:
	tst	bbox_st(pc)
	beq.s	.q

	IFD	bsphere
	move.l	vertex_st_p(pc),a1
	move.l	koordxyz_sp_p(pc),a0
	move	anzpkt(pc),d7
	movem	objpos(pc),d3-d5
	move.l	bbrad(pc),d6

.b:	movem	(a0)+,d0-d2
	sub	d3,d0
	sub	d4,d1
	sub	d5,d2

	muls	d0,d0			; laenge^2 = x^2+y^2+z^2
	muls	d1,d1
	muls	d2,d2
	add.l	d0,d1
	add.l	d2,d1

	moveq	#-1,d0
	cmp.l	d1,d6
	bhi.s	.nvis2
	moveq	#0,d0

.nvis2:	move.b	d0,(a1)+
	dbf	d7,.b
	ENDC

;---
	move.l	vertex_st_p(pc),a1
	moveq	#1,d4
	move.l	objtab_p(pc),a0
	move	anzfl(pc),d7

.a:	movem	2(a0),d0-d2
	lsr	#2,d0
	lsr	#2,d1
	lsr	#2,d2

	move.b	(a1,d0.w),d3
	beq.s	.nvis
	move.b	(a1,d1.w),d3
	beq.s	.nvis
	move.b	(a1,d2.w),d3
	beq.s	.nvis

	move	d4,(a0)
	addq.l	#8,a0
	dbf	d7,.a
.q:	rts

.nvis:	clr	(a0)
	addq.l	#8,a0
	dbf	d7,.a
	rts



default_vertex_st:
	move.l	vertex_st_p(pc),a0
	move	anzpkt(pc),d7
	moveq	#-1,d0

.a:	move.b	d0,(a0)+
	dbf	d7,.a
	rts
	ENDC
	
;----------------------

	IFD	_3ds
init_typel:
	move	2(a0),d7
	move.l	24(a0),a2		; objtypelist
	tst.l	a2
	beq.s	.q

.a:	move	(a2),d0
	move.l	2(a2),d1
	move.l	(a1,d1.l*4),2(a2)
	add	i_tl_a(pc,d0.w*2),a2
	dbf	d7,.a
.q:	rts

i_tl_a:	dc	6,6,6,6+12,6+12,6+12,6+12,6,6+12+4,6+12+4,6+12+8,6+4,6+4
	ENDC

;----------------------

init_normal_st:
	move.l	normal_st_p(pc),a0
	move	anzpkt(pc),d7
	moveq	#-1,d0
	move.l	a0,a1

.a:	move.b	d0,(a0)+
	dbf	d7,.a

;--
	move.l	g_liste_p(pc),a0
	move	anzfl(pc),d7
	move.l	objtab_p(pc),a2
	move.l	g_l_element_l(pc),d6
	lea	(1+12)*4+2(a0),a0

.b:	movem	(a2)+,d0-d3
	lsr.l	#2,d1			; Die *4 werte auf *1 reduzieren
	lsr.l	#2,d2
	lsr.l	#2,d3

	cmp	#t_phong030,(a0)
	beq.s	.d
	cmp	#t_phong,(a0)
	beq.s	.d
	IFD	m_transparent
	cmp	#t_transphong,(a0)
	beq.s	.d
	ENDC
	IFD	m_bi_map
	cmp	#t_bi_phong,(a0)
	beq.s	.d
	ENDC
	IFD	m_gouraud_tmap
	cmp	#t_gouraud_tmap,(a0)
	beq.s	.d
	cmp	#t_gouraud_env,(a0)
	beq.s	.d
	ENDC
	IFD	m_phong_tmap
	cmp	#t_phong_tmap,(a0)
	beq.s	.d
	ENDC
	IFD	m_bump
	cmp	#t_bump,(a0)
	beq.w	.d
	ENDC
	IFD	m_tbump
	cmp	#t_tbump,(a0)
	bne.s	.c
	ENDC

.d:	clr.b	(a1,d1.l)
	clr.b	(a1,d2.l)
	clr.b	(a1,d3.l)
.c:
	add.l	d6,a0
	dbf	d7,.b
	rts

;----------------------

build_lists:
	move.l	g_liste_p(pc),a0
	move	anzfl(pc),d7
	move.l	g_l_element_l(pc),d1
	lea	(1+12)*4(a0),a0
	move.l	objecttexp(pc),d0
	beq.w	.b

	move.l	d0,a1
	move.l	tri2map_p(pc),a2

.c:	move	(a1)+,d2

	ext.l	d2
	move.l	d2,(a0)			; Facetype

;-
	IFND	precision
	tst.b	smc(pc)
	bne.s	.n2
	cmp	#t_phong,d2
	bne.s	.n1
	move.l	#t_phong030,(a0)
.n1:	cmp	#t_texmap,d2
	bne.s	.n2
	move.l	#t_texmap030,(a0)
.n2:	ENDC
;-
	move.l	(a1)+,4(a0)		; Texture

	cmp	#t_phong,d2
	beq.s	.phong

	IFD	m_transparent
	cmp	#t_transphong,d2
	beq.s	.phong
	cmp	#t_transtexmap,d2
	beq.s	.tmap
	ENDC

	IFD	m_bi_map
	cmp	#t_bi_phong,d2
	beq.s	.phong
	cmp	#t_bi_texmap,d2
	beq.s	.tmap
	ENDC

	IFD	m_gouraud_tmap
	cmp	#t_gouraud_env,d2
	beq.s	.phong
	cmp	#t_gouraud_tmap,d2
	beq.s	.tmap
	ENDC

	IFD	m_phong_tmap
	cmp	#t_phong_tmap,d2
	beq.s	.tmap2
	ENDC

	IFD	m_bump
	cmp	#t_bump,d2
	beq.s	.tmap2
	ENDC

	IFD	m_tbump
	cmp	#t_tbump,d2
	beq.s	.tmap3
	ENDC

	IFD	m_flare
	cmp	#t_flare,d2
	beq.s	.fl
	ENDC

	IFD	m_bboard
	cmp	#t_bboard,d2
	beq.s	.fl
	ENDC

;	cmp	#t_texmap,d2
;	beq.s	.tmap

.tmap:	move.l	(a1)+,(a2)+
	move.l	(a1)+,(a2)+
	move.l	(a1)+,(a2)+
	lea	g_tri2map_element-12(a2),a2
	bra.s	.as

	IFNE	m_flare_v|m_bboard_v
.fl:	move.l	(a1)+,-12*4(a0)
	ENDC
.phong:	lea	g_tri2map_element(a2),a2
.as:	add.l	d1,a0
	dbf	d7,.c
	rts

;--
	IFNE	m_phong_tmap_v|m_bump_v
.tmap2:
	move.l	(a1)+,(a2)+
	move.l	(a1)+,(a2)+
	move.l	(a1)+,(a2)+
	move.l	(a1)+,20(a0)		; phongtexture
	lea	g_tri2map_element-12(a2),a2
	bra.s	.as
	ENDC
;--
	IFD	m_tbump
.tmap3:
	move.l	(a1)+,(a2)+
	move.l	(a1)+,(a2)+
	move.l	(a1)+,(a2)+
	move.l	(a1)+,20(a0)		; phongtexture
	move.l	(a1)+,24(a0)		; phongtexture
	lea	g_tri2map_element-12(a2),a2
	bra.s	.as
	ENDC
;--

.b:	moveq	#t_phong,d2
	move.l	map_p(pc),d0
.a:	move.l	d2,(a0)
	move.l	d0,4(a0)
	add.l	d1,a0
	dbf	d7,.a
	rts

;------------------------------------------------

alloc_g_liste:
	moveq	#0,d0
	move	anzfl(pc),d0
	addq.l	#1,d0
	mulu	g_l_element(pc),d0

	lea	g_liste_size(pc),a0
	move.l	d0,(a0)
	bsr.w	gen_allocpublic
	lea	g_liste_mem(pc),a0
	move.l	d0,(a0)
	beq.s	agl_fail

	lea	g_liste_p(pc),a0
	move.l	d0,(a0)

	moveq	#0,d0
	rts

agl_fail:
	moveq	#2,d0
	rts

g_liste_size:	dc.l	0
g_liste_mem:	dc.l	0

free_g_liste:
	move.l	g_liste_mem(pc),a1
        move.l  g_liste_size(pc),d0
	bra.w	gen_free

;----------------------

alloc_obj_struct:
	lea	pktcols_p(pc),a0

	moveq	#0,d2
	moveq	#0,d3
	move	anzpkt(pc),d2
	move	anzfl(pc),d3
	addq.l	#1,d2
	addq.l	#1,d3
	move.l	d2,d4			; anzpkt
	move.l	d3,d5			; anzfl
	add.l	d4,d4
	add.l	d5,d5
	move.l	d4,a4			; anzpkt*2
	move.l	d5,a5			; anzfl*2
	move.l	d4,a2
	move.l	d5,a3
	add.l	a2,a2			; anzpkt*4
	add.l	a3,a3			; anzfl*4
	mulu	#3,d4			; anzpkt*6
	mulu	#3,d5			; anzfl*6
	move.l	a2,d6
	move.l	a3,d7
	add.l	d6,d6			; anzpkt*8
	add.l	d7,d7			; anzfl*8

	moveq	#0,d0

	clr.l	pktcols_p-pktcols_p(a0)
	add.l	a2,d0				; maxpoints*4

	move.l	d0,objtab_p-pktcols_p(a0)
	add.l	d7,d0				; g_maxfl*8 (*(1+3)*2)

	move.l	d0,flg_lp_p-pktcols_p(a0)
	add.l	a3,d0				; g_maxfl*4

	move.l	d0,koordxy_p-pktcols_p(a0)
	add.l	a2,d0				; maxpoints*2*2

	move.l	d0,koordxyz_p-pktcols_p(a0)
	add.l	d4,d0				; maxpoints*3*2

	move.l	d0,koordxyz_sp_p-pktcols_p(a0)
	add.l	d4,d0				; maxpoints*3*2

	move.l	d0,normal_zv_p-pktcols_p(a0)
	add.l	d4,d0				; maxpoints*3*2

	move.l	d0,flcoloff_p-pktcols_p(a0)
	add.l	d5,d0				; g_maxfl*3*2
	
	move.l	d0,objvert6_p-pktcols_p(a0)
	add.l	d5,d0				; g_maxfl*3*2

	move.l	d0,objvert6_p2-pktcols_p(a0)
	add.l	d5,d0				; g_maxfl*3*2

	move.l	d0,tri2map_p-pktcols_p(a0)
	move.l	d3,d1
	mulu	#g_tri2map_element,d1
	add.l	d1,d0

	move.l	d0,koordxyz2_p-pktcols_p(a0)
	add.l	d4,d0				; maxpoints*3*2

	move.l	d0,normal_zv2_p-pktcols_p(a0)
	add.l	d4,d0				; maxpoints*3*2

; Zum Schluss wegen alignment (weil bytes allokiert werden)
	move.l	d0,normal_st_p-pktcols_p(a0)
	add.l	d2,d0				; maxpoints

	IFD	bbox
	move.l	d0,vertex_st_p-pktcols_p(a0)
	add.l	d2,d0				; maxpoints
	ENDC

	move.l	d0,obj_mem_size
	bsr.w	gen_allocpublic
	move.l	d0,obj_mem
	beq.s	aos_fail

	lea	pktcols_p(pc),a0
	add.l	d0,pktcols_p-pktcols_p(a0)
	add.l	d0,objtab_p-pktcols_p(a0)
	add.l	d0,flg_lp_p-pktcols_p(a0)
	add.l	d0,koordxy_p-pktcols_p(a0)
	add.l	d0,koordxyz_p-pktcols_p(a0)
	add.l	d0,koordxyz_sp_p-pktcols_p(a0)
	add.l	d0,normal_zv_p-pktcols_p(a0)
	add.l	d0,flcoloff_p-pktcols_p(a0)
	add.l	d0,objvert6_p-pktcols_p(a0)
	add.l	d0,objvert6_p2-pktcols_p(a0)
	add.l	d0,tri2map_p-pktcols_p(a0)
	add.l	d0,koordxyz2_p-pktcols_p(a0)
	add.l	d0,normal_zv2_p-pktcols_p(a0)

	add.l	d0,normal_st_p-pktcols_p(a0)
	IFD	bbox
	add.l	d0,vertex_st_p-pktcols_p(a0)
	ENDC

	moveq	#0,d0
	rts

aos_fail:
	moveq	#2,d0
	rts

obj_mem_size:	dc.l	0
obj_mem:	dc.l	0

free_obj_struct:
	move.l	obj_mem(pc),a1
        move.l  obj_mem_size(pc),d0
	bra	gen_free

;----------------------

; Normalvektoren(2d), Screenbuffer und Edgetable allokieren

	include	"i/allocs_n_inits/alloc_ltt_nv_sb.s"

;---------------------------------------------------------------------

build_obj_cols:
	move.l	clistptr(pc),a1
	move.l	objectcp(pc),a0

	lea	cl_cols-clist(a1),a1

	moveq	#0,d7
	move	plnr_scr(pc),d7
boc_ei:
	moveq	#1,d6
	lsl.l	d7,d6			; Anzahl Farben bei plnr Planes

	lea	32*4+4.w,a5

	cmp	#32,d6
	bge.s	.boc1

	move.l	d6,d7
	lsl.l	#2,d7
	addq.l	#4,d7
	move.l	d7,a5

.boc1:	move.l	#$01060000,d1
.boc3:	move	#$0180,d2

.boc:	bset	#9,d1
	move.l	d1,(a1,a5.l)
	bclr	#9,d1
	move.l	d1,(a1)+

.boc2:
	move	d2,(a1,a5.l)
	move	2(a0),2(a1,a5.l)
	move	d2,(a1)+
	move	(a0),(a1)+

	addq.l	#2,d2
	addq.l	#4,a0

	subq.l	#1,d6
	beq.s	.boc_q

	move.l	d6,d0
	and	#%11111,d0
	bne.s	.boc2

	add	#$2000,d1
	add.l	a5,a1

	bra.s	.boc3

.boc_q:	rts

;-------------

build_objvert6:				; Verbindungstabelle mit *6 aufbauen
	move.l	objecttp(pc),a0
	move.l	objvert6_p(pc),a1
	move.l	objvert6_p2(pc),a2
	move	anzfl(pc),d7
	moveq	#6,d6

bovag:	movem	(a0)+,d0-d2		; 3 Punkte sind eine Flaeche
	subq	#1,d0			; -1 (damit die zaehlung bei 0
	subq	#1,d1			;     beginnt)
	subq	#1,d2
	mulu	d6,d0			; *6 (x.w+y.w+z.w)
	mulu	d6,d1
	mulu	d6,d2
	movem	d0-d2,(a1)
	movem	d0-d2,(a2)
	addq.l	#6,a1
	addq.l	#6,a2
	dbf	d7,bovag
	rts

;------------

cp_vert_sp:
	move.l	objectpp(pc),a0
	move.l	koordxyz_sp_p(pc),a1
	move	anzpkt(pc),d7
.a:	movem	(a0)+,d0-d2
	IFD	_3ds
	tst	_3ds_st(pc)		; 3ds output schon mit subpixel!
	bne.s	.c
	ENDC
;	lsl	#subpixel,d0
;	lsl	#subpixel,d1
;	lsl	#subpixel,d2
.c:	move	d0,(a1)+
	move	d1,(a1)+
	move	d2,(a1)+
	dbf	d7,.a
	rts

;----------

do_backup_pkts:
	move	anzpkt(pc),d7
	move.l	koordxyz_sp_p(pc),a0
	move.l	koordxyz2_p(pc),a1
	move.l	normal_zv_p(pc),a2
	move.l	normal_zv2_p(pc),a3

.a:	move.l	(a0)+,(a1)+
	move	(a0)+,(a1)+
	move.l	(a2)+,(a3)+
	move	(a2)+,(a3)+
	dbf	d7,.a
	rts

;----------------------

build_obj_tab:				; Verbindungstabelle*4 mit sichtbar.w
	move.l	objecttp(pc),a0
	move.l	objtab_p(pc),a1
	move	anzfl(pc),d7

botag:	clr	(a1)+
	movem	(a0)+,d0-d2		; 3 Punkte sind eine Flaeche
	subq.l	#1,d0			; -1 (damit die zaehlung bei 0
	subq.l	#1,d1			;     beginnt)
	subq.l	#1,d2
	lsl.l	#2,d0			; *4 (x.w+y.w)
	lsl.l	#2,d1
	lsl.l	#2,d2
	movem	d0-d2,(a1)
	addq.l	#6,a1
	dbf	d7,botag
	rts

;----------------------
; Berechnet Normalvektoren in den (durch normal_st legitimierten) Vertices
; durch arithmetisches Mittel der beteiligten Flaechen.

nor_laenge	=	128

	include	"i/geometry/calc_normals.s"

;---
;-> d5 = Radikant
;<- d7 = Ergebnis

do_sqrt:
	moveq	#15,d3
	move.l	#$40000000,d7
	move.l	d5,d2
	clr.w	d2
	swap	d2
bocracine:
	swap	d7
	sub.l	d7,d2
	bcc.s	calcrac
	add.l	d7,d2
	swap	d7
	add.w	d7,d7
sqrt_2:	add.w	d5,d5
	addx.l	d2,d2
	add.w	d5,d5
	addx.l	d2,d2
	dbf	d3,bocracine
	and.l	#$ffff,d7
	rts
calcrac:
	swap	d7
	add.w	d7,d7
	addq.w	#1,d7
	bra.s	sqrt_2

;do_sqrt:
;	moveq	#0,d7
;	moveq	#16,d2
;wurzel:	subq.b	#1,d2
;	bmi.s	sqrt_ready
;	bset	d2,d7
;	move	d7,d3
;	mulu	d3,d3
;	cmp.l	d3,d5
;	beq.s	sqrt_ready
;	bhi.s	wurzel
;	bclr	d2,d7
;	bra.s	wurzel
;sqrt_ready:
;	rts

;--------------------------------------------------

;---- XY Koords der Map fuer PS in g_liste eintragen

map_pkts:
	IFNE	m_flare_v|m_bboard_v
	lea	flare_dum(pc),a0
	move	ysize_scr(pc),d0
	moveq	#subpixel,d3
	tst	half_scr(pc)
	beq.s	.a
	moveq	#subpixel+1,d3
.a	lsr	#1,d0
	move	d3,(a0)+
	move	d0,(a0)
	ENDC

	lea	g_stack(pc),a0
	move.l	a7,(a0)

	move.l	g_liste_p(pc),a1
	move.l	flcoloff_p(pc),a0
	lea	12(a1),a1

	IFD	m_gouraud_tmap
	lea	gouraud_map,a7
	moveq	#0,d6
	ENDC

	move.l	nvekxy_p(pc),a2
	move.l	objtab_p(pc),a3
	move.l	tri2map_p(pc),a5

	move	anzfl(pc),d7

ppag:	tst	(a3)
	bpl.s	ppnix			; unsichtbar oder draussen
					; teilweise oder ganz drinnen
	move.l	(1+12)*4-12(a1),d3
	movem	(a0)+,d0-d2

	IFD	m_fog
	move.l	d3,d4
	and	#t_fog-1,d3
	ENDC

	move.l	a1,a4
	jmp	([(map_pkts_jt).w,pc,d3.l*4])

;----

mp_t_n_lim:
	IFD	m_fog
	cmp	#t_fog,d4
	blt.s	.d

	lea	(1+12+2)*4-12(a1),a6
	move.l	(a6,d0.l*2),d3		; rearrange depth-values
	move.l	(a6,d1.l*2),d4
	move.l	(a6,d2.l*2),d5

	move.l	d3,(a6)+
	move.l	d4,(a6)+
	move.l	d5,(a6)

	move	2(a3,d0.l),d0		; get offset of normals
	move	2(a3,d1.l),d1
	move	2(a3,d2.l),d2
.d:	ENDC

mp_nfenv:
	move.l	(a2,d0.l),d3		; 1111
	move.l	(a2,d1.l),d0		; 2222
	move.l	(a2,d2.l),d1		; 3333

mp_store:
	move.l	d3,(a4)+		; 1
	move.l	d1,(a4)+		; 3
	addq.l	#8,a4
	move.l	d3,(a4)+		; 1
	move.l	d0,(a4)+		; 2
	addq.l	#8,a4
	move.l	d0,(a4)+		; 2
	move.l	d1,(a4)			; 3

ppnix:	add	g_l_element(pc),a1
	addq.l	#8,a3
	lea	g_tri2map_element(a5),a5
	dbf	d7,ppag
	move.l	g_stack(pc),a7
	rts
;-
	IFNE	m_flare_v|m_bboard_v
mp_flare:
	moveq	#0,d0
	move.l	koordxy_p(pc),a6
	move	2(a3),d0
	move.l	(a6,d0.l),d1

	move.l	d0,d2
	lsr.l	#1,d0
	move.l	koordxyz_p(pc),a6
	add.l	d2,d0
	move.l	d1,-4(a4)

	move	#auge*2^subpixel,d6

	movem	(a6,d0.l),d0-d2
	move	-6(a4),d5
	move	-8(a4),d4
	lsl	#subpixel,d5
	lsl	#subpixel,d4
	move	flare_dum(pc),d3
	add	d4,d0
	add	z_add(pc),d2
	sub	d5,d1
	cmp	#zmin*2^subpixel,d2
	ble.s	.a
	muls	d6,d0		;d3 = Px*Auge
	sub	d6,d2		;d5 = Pz-Auge
	muls	d6,d1		;d4 = Py*Auge
	divs	d2,d0		;d3 = Px*Auge/(Pz-Auge)
	divs	d2,d1		;d4 = Py*Auge/(Pz-Auge)
	neg	d0		;d3 = -d3

	asr	d3,d1

	add	#(xsize*2^subpixel)/2,d0	;d3 = 160-Px*Auge/(Pz-Auge)
	add	flare_dum+2(pc),d1

	move.l	d0,d4		; x zentrieren
	sub	-4(a4),d4
	lsr	#1,d4
	sub	d4,-4(a4)
	sub	d4,d0

.a:	move	d0,(a4)+
	move	d1,(a4)

	bra.w	ppnix

flare_dum:	dc	0,0
	ENDC
;-
mp_tex:
	IFD	m_fog
	cmp	#t_fog,d4
	blt.s	.c

	lea	(1+12+2)*4-12(a1),a6
	move.l	(a6,d0.l*2),d3		; rearrange depth-values
	move.l	(a6,d1.l*2),d4
	move.l	(a6,d2.l*2),d5
	
	move.l	d3,(a6)+
	move.l	d4,(a6)+
	move.l	d5,(a6)
.c:
	ENDC
mp_nftex:
	move.l	(a5,d0.l*2),d3		; 1111
	move.l	(a5,d1.l*2),d0		; 2222
	move.l	(a5,d2.l*2),d1		; 3333
	bra.w	mp_store

;----
	IFD	m_gouraud_tmap
mp_g_t:
	lea	(1+12+2)*4-12(a1),a6

	move	2(a3,d0.l),d3		; get normals
	move	2(a3,d1.l),d4
	moveq	#0,d5
	move.l	(a2,d3.w),d3		; 1111 -00xx00yy
	move.l	(a2,d4.w),d4		; 2222

	move	d3,d5			; 00yy
	swap	d3			; 00xx
	lsl	#8,d5			; yy00
	move.b	d3,d5			; yyxx
	move.b	(a7,d5.l),d6
	move	d4,d5
	swap	d4
	move	d6,(a6)+
	lsl	#8,d5

	move	2(a3,d2.l),d3
	move.b	d4,d5
	move.l	(a2,d3.w),d3		; 3333
	move.b	(a7,d5.l),d6
	move	d3,d5
	swap	d3
	lsl	#8,d5
	move	d6,(a6)+
	move.b	d3,d5
	move.b	(a7,d5.l),d6

	move	d6,(a6)
	
	bra.s	mp_nftex

mp_g_e:
	lea	(1+12+2)*4-12(a1),a6

	move	2(a3,d0.l),d3		; get normals
	move	2(a3,d1.l),d4
	moveq	#0,d5
	move.l	(a2,d3.w),d3		; 1111 -00xx00yy
	move.l	(a2,d4.w),d4		; 2222

	move	d3,d5			; 00yy
	swap	d3			; 00xx
	lsl	#8,d5			; yy00
	move.b	d3,d5			; yyxx
	move.b	(a7,d5.l),d6
	move	d4,d5
	swap	d4
	move	d6,(a6)+
	lsl	#8,d5

	move	2(a3,d2.l),d3
	move.b	d4,d5
	move.l	(a2,d3.w),d3		; 3333
	move.b	(a7,d5.l),d6
	move	d3,d5
	swap	d3
	lsl	#8,d5
	move	d6,(a6)+
	move.b	d3,d5
	move.b	(a7,d5.l),d6

	move	2(a3,d0.l),d0
	move	2(a3,d1.l),d1
	move	d6,(a6)
	move	2(a3,d2.l),d2
	bra.w	mp_nfenv
	ENDC
;----
	IFNE	m_phong_tmap_v|m_bump_v|m_tbump_v
mp_p_t:
	lea	(1+12+2)*4-12(a1),a6

	move	2(a3,d0.l),d3		; get normals
	move	2(a3,d1.l),d4
	move	2(a3,d2.l),d5
	move.l	(a2,d3.w),d3		; 1111 -00xx00yy
	move.l	(a2,d4.w),d4		; 2222
	move.l	(a2,d5.w),d5		; 3333

	move.l	d3,(a6)+
	move.l	d4,(a6)+
	move.l	d5,(a6)
	
	bra	mp_nftex
	ENDC
;----
	cnop	0,4

map_pkts_jt:
		IFD	m_bi_map
		dc.l	mp_t_n_lim
		ELSE
		dc.l	0
		ENDC
;-
		IFD	m_transparent
		dc.l	mp_t_n_lim
		ELSE
		dc.l	0
		ENDC
;-
		dc.l	mp_t_n_lim		; t_phong
;-
		dc.l	mp_tex			; t_texmap
;-
		IFD	m_transparent
		dc.l	mp_nftex		; t_transtexmap
		ELSE
		dc.l	0
		ENDC
;-
		IFD	m_bi_map
		dc.l	mp_nftex
		ELSE
		dc.l	0
		ENDC
;-
		IFD	m_gouraud_tmap
		dc.l	mp_g_t			; t_gouraud_tmap
		dc.l	mp_g_e			; t_gouraud_env
		ELSE
		dc.l	0
		dc.l	0
		ENDC
;-
		IFD	m_phong_tmap
		dc.l	mp_p_t
		ELSE
		dc.l	0
		ENDC
;-
		IFD	m_bump
		dc.l	mp_p_t
		ELSE
		dc.l	0
		ENDC
;-
		IFD	m_tbump
		dc.l	mp_p_t
		ELSE
		dc.l	0
		ENDC
;-
		IFD	m_flare
		dc.l	mp_flare
		ELSE
		dc.l	0
		ENDC
;-
		IFD	m_bboard
		dc.l	mp_flare
		ELSE
		dc.l	0
		ENDC
;-
		IFND	precision
		dc.l	mp_tex			; t_texmap030
		ELSE
		dc.l	0
		ENDC
;-
		IFND	precision
		dc.l	mp_t_n_lim		; t_phong030
		ELSE
		dc.l	0
		ENDC
;-



;----------------------------------------------------------
; Zmax jedes Tris vor Sortierung bestimmen
; a0 = pkt
; a1 = tab
; d0 = flanz

fl_4_sort:
	tst	fl_4_sort_st(pc)
	bne.s	.w
	rts

.w:	move.l	koordxyz_p(pc),a0
	move.l	objvert6_p2(pc),a1
	move.l	objtab_p(pc),a5
	move	anzfl(pc),d0

.a:	tst	(a5)
	bpl.s	.x

	movem	(a1),d1-d3

	move	4(a0,d1.l),d4
	move	4(a0,d2.l),d5
	move	4(a0,d3.l),d6

	cmp	d4,d5
	bge.s	.b
	cmp	d4,d6
	bge.s	.d
	bra.s	.x

.b:	cmp	d6,d5
	bge.s	.c

.d:				; d6 am groessten
	exg	d1,d3		; d6/d5/d4
	exg	d2,d3		; d6/d4/d5
	bra.s	.q

.c:				; d5 am groessten
	exg	d1,d2		; d5/d4/d6
	exg	d2,d3		; d5/d6/d4

.q:	movem	d1-d3,(a1)
.x:	addq.l	#6,a1
	addq.l	#8,a5
	dbf	d0,.a

;-------
	move.l	objvert6_p2(pc),a2

	move	anzfl(pc),d7
	move.l	sort_list_p2(pc),a4
	move.l	sort_list_gl_p(pc),a1
	move.l	objtab_p(pc),a5

.sort_3:
	move.l	(a4),d0
	move.l	d0,d1
	swap	d0
	move.l	(a1,d0.w),a3
	tst	(a3)
	bpl.s	.sort_2
					; sichtbar und innerhalb des Screens.
	sub.l	a5,a3
	move.l	a3,d3
	lsr.l	#3,d3			; /8
	add.l	d3,d3
	move.l	d3,d7
	add.l	d3,d3
	add.l	d7,d3

	move	(a2,d3.w),d1

	move.l	d1,(a4)

.sort_2:addq.l	#4,a4
	dbf	d0,.sort_3

	rts

;-----------------------------

; Sortiert nur die sichtbaren und innerhalb des Screens befindlichen Flaechen
; unter ausnutzung der sortierung der vorhergehenden sortierung durch pointer.

no_fl_sort:
	rts

sort_fl:
	tst.l	g_flanz(pc)
	beq.s	no_fl_sort

	tst.b	group_sort(pc)
	bne.w	sort_gfl

;---
	move	anzfl(pc),d0
	move.l	sort_list_p2(pc),a4
	move.l	d0,d7
	move.l	sort_list_p(pc),a6
	addq.l	#1,d0
	move.l	a6,a0
	move.l	sort_list_gl_p(pc),a1

	lea	(a0,d0.w*4),a5
sort_3:	move.l	(a4)+,d0
	move.l	d0,d1			; flnr*8|vert6
	swap	d0
;	dc.l	$4a710111		; tst	([a0,d0.w])
	move.l	(a1,d0.w),a3		; objtab
	tst	(a3)			; sichtbar.w
	bpl.s	sort_2
					; sichtbar und innerhalb des Screens.
	move.l	d1,(a0)+		; (die alten flaechen wieder verwenden
	dbf	d7,sort_3		; um eine gewisse 'vorsortiertheit'
	bra.s	sort_4			; der pointer zu nutzen)

					; die (neuen) sichtbaren flaechen
					; werden in der gleichen Reihenfolge
					; wie die alten nach sort_list_p
					; kopiert

sort_2:	move.l	d1,-(a5)
	dbf	d7,sort_3

sort_4:
	move.l	g_flanz(pc),d0
	bra.s	sort_1

;---
; Aufbau der g_liste fuer GroupSort Objekte

gs_after:
	move.l	objectlp(pc),a0
	move.l	flg_lp_p(pc),a1
	move.l	a0,a3
	move.l	(a3)+,d7
	move.l	objtab_p(pc),a2
	subq.l	#1,d7			; Anzahl der Flaechengruppen

sortfl2:move.l	a0,a4
	add	(a3),a4			; auf neue Flaechengruppe zeigen
	addq.l	#4,a3			; naexter Flaechengruppenpointer
	move	(a4)+,d6		; Anzahl der Flaechen in dieser Gruppe
sortfl1:movem.l	(a4)+,a5/a6		; objtab&g_liste holen
	tst	(a5)			; Flaeche darzustellen?
	bpl.s	no_s_fl			; bei positiv nicht darstellen
	move.l	a6,(a1)+		; ja, dazu Pointer im Array speichern
no_s_fl:dbf	d6,sortfl1
	dbf	d7,sortfl2
	rts

no_sort:				; Unsortierte Flaechen in flg_lp
	move.l	g_liste_p(pc),a0	; eintragen
	move.l	flg_lp_p(pc),a1
	move.l	objtab_p(pc),a2
	move	anzfl(pc),d7
	move	g_l_element(pc),d6

no_sag:	tst	(a2)
	bpl.s	no_s_fl2
	move.l	a0,(a1)+
no_s_fl2:
	add	d6,a0
	addq.l	#8,a2
	dbf	d7,no_sag
	rts
;---

sort_gfl:
	move.l	objectlp(pc),a6
	tst	(a6)+			; ueberhaupt sortieren?
	beq	no_sort

	move	(a6)+,d0		; Anzahl der zu sortierenden Elemente
sort_1:	move.l	a6,datenp		; Anfang der Tabelle
	lea	(a6,d0.w*4),a5
	move.l	a5,datendp		; Ende der Tabelle

	cmp	#1,d0
	beq.s	d_sort_a

	IFD	shellsort
	lsl	#2,d0			; *4
	lea	index(pc),a1		; Indexfeld

d_index:cmp	2(a1),d0
	bgt.s	d_sort
	addq.l	#4,a1
	bra.s	d_index
	ENDC

d_sort:	bsr.s	do_sort			; sortieren (nach Z)

d_sort_a:
	tst.b	group_sort(pc)
	bne.s	gs_after

	move.l	sort_list_p(pc),a6	; die pointer fuers naexte mal merken
	move.l	sort_list_p2(pc),a5
	move	anzfl(pc),d7
	move.l	a6,a0

sort_5:	move.l	(a6)+,(a5)+
	dbf	d7,sort_5		; ""

	move.l	sort_list_gl_p(pc),a2
	move.l	g_flanz(pc),d7
	move.l	flg_lp_p(pc),a1
	subq.l	#1,d7

sort_6:	move	(a0),d0
	addq.l	#4,a0
	move.l	4(a2,d0.w),(a1)+
	dbf	d7,sort_6

	rts

;--

	IFND	shellsort
	include	"i/sort/quicksort.s"
	ELSE
	include	"i/sort/shellsort.s"
	ENDC

	cnop	0,4

datenp:	dc.l	0		; Datenfeld
datendp:dc.l	0		; Ende der Datenfeldtabelle

;-------------------------------------------------

zclip:
	move.l	koordxyz_p(pc),a0
	move	#zmin*2^subpixel+1,d6
	move.l	objvert6_p(pc),a1
	addq.l	#4,a0
	sub	z_add(pc),d6
	move.l	objtab_p(pc),a2

	move	anzfl(pc),d7

	IFD	bbox
	tst	bbox_st(pc)
	bne.s	zclip_bb
	ENDC

	IFD	m_fog
	tst	fog_st(pc)
	bne.s	zfogclip
	ENDC

	moveq	#-1,d5

.a:	move.l	(a1),d0
	cmp	(a0,d0.w),d6
	bgt.s	.c
	swap	d0
	move	4(a1),d1
	cmp	(a0,d0.w),d6
	bgt.s	.c
	cmp	(a0,d1.w),d6
	ble.s	.bx
	
.c:	clr	(a2)
	addq.l	#8,a2
	addq.l	#6,a1
	dbf	d7,.a
	rts

.bx:	move	d5,(a2)
	addq.l	#8,a2
	addq.l	#6,a1
	dbf	d7,.a
	rts
;---

	IFD	bbox
zclip_bb:
	IFD	m_fog
	tst	fog_st(pc)
	bne.w	zfogclip_bb
	ENDC

	moveq	#-1,d5

.a:	tst	(a2)
	beq.s	.d
	move.l	(a1),d0
	cmp	(a0,d0.w),d6
	bgt.s	.c
	swap	d0
	move	4(a1),d1
	cmp	(a0,d0.w),d6
	bgt.s	.c
	cmp	(a0,d1.w),d6
	ble.s	.bx
	
.c:	clr	(a2)
.d:	addq.l	#8,a2
	addq.l	#6,a1
	dbf	d7,.a
	rts

.bx:	move	d5,(a2)
	addq.l	#8,a2
	addq.l	#6,a1
	dbf	d7,.a
	rts

	rts
	ENDC

	IFD	m_fog

; Wenn Tri groesser als fog_max, dann ist es unabhaengig vom typ unsichtbar.

zfogclip:
	move.l	g_liste_p(pc),a3
	lea	(1+12)*4(a3),a3
	move	z_add(pc),a4
	move.l	a7,g_stack

	add	a4,d6

.a:	move.l	(a1),d0
	move	(a0,d0.w),d3
	swap	d0
	move	4(a1),d1
	move	(a0,d0.w),d2
	move	(a0,d1.w),d4

	add	a4,d2
	add	a4,d3
	add	a4,d4

	move.l	d2,a5
	move.l	d3,a6
	move.l	d4,a7

	cmp	d2,d3
	ble.s	.c1		; wenn d3 kleiner-gleich, dann sprung
	cmp	d2,d4
	ble.s	.c2
	bra.s	.c_z		; d2 am kleinsten

.c1:	cmp	d3,d4
	ble.s	.c2
	exg	d2,d3		; d3 am kleinsten
	bra.s	.c_z

.c2:	exg	d2,d4		; d4 am kleinsten

.c_z:	cmp	d2,d6		; Hinterm Auge?
	bgt.s	.bx

	cmp	d3,d4
	ble.s	.c3
	move.l	d4,d3
.c3:				; d3 am groessten
	cmp	fog_min(pc),d3	; Tri vor dem Fog?
	blt.s	.d

.c4:	cmp	fog_max(pc),d2	; Tri hinter dem Fog?
	bgt.s	.bx

	or.l	#t_fog,(a3)
	movem.l	a5-a7,8(a3)
	bra.s	.e

.d:	and.l	#t_fog-1,(a3)
.e:	move	#-1,(a2)
	addq.l	#8,a2
	addq.l	#6,a1
	add	g_l_element(pc),a3
	dbf	d7,.a
	move.l	g_stack(pc),a7
	rts

.bx:	clr	(a2)
	addq.l	#8,a2
	addq.l	#6,a1
	add	g_l_element(pc),a3
	dbf	d7,.a
	move.l	g_stack(pc),a7
	rts

;---
	IFD	bbox
zfogclip_bb:
	move.l	g_liste_p(pc),a3
	lea	(1+12)*4(a3),a3
	move	z_add(pc),a4
	move.l	a7,g_stack

	add	a4,d6

.a:	tst	(a2)
	beq.s	.bx2
	move.l	(a1),d0
	move	(a0,d0.w),d3
	swap	d0
	move	4(a1),d1
	move	(a0,d0.w),d2
	move	(a0,d1.w),d4

	add	a4,d2
	add	a4,d3
	add	a4,d4

	move.l	d2,a5
	move.l	d3,a6
	move.l	d4,a7

	cmp	d2,d3
	ble.s	.c1		; wenn d3 kleiner-gleich, dann sprung
	cmp	d2,d4
	ble.s	.c2
	bra.s	.c_z		; d2 am kleinsten

.c1:	cmp	d3,d4
	ble.s	.c2
	exg	d2,d3		; d3 am kleinsten
	bra.s	.c_z

.c2:	exg	d2,d4		; d4 am kleinsten

.c_z:	cmp	d2,d6		; Hinterm Auge?
	bgt.s	.bx

	cmp	d3,d4
	ble.s	.c3
	move.l	d4,d3
.c3:				; d3 am groessten
	cmp	fog_min(pc),d3	; Tri vor dem Fog?
	blt.s	.d

.c4:	cmp	fog_max(pc),d2	; Tri hinter dem Fog?
	bgt.s	.bx

	or.l	#t_fog,(a3)
	movem.l	a5-a7,8(a3)
	bra.s	.e

.d:	and.l	#t_fog-1,(a3)
.e:	move	#-1,(a2)
	addq.l	#8,a2
	addq.l	#6,a1
	add	g_l_element(pc),a3
	dbf	d7,.a
	move.l	g_stack(pc),a7
	rts

.bx:	clr	(a2)
.bx2:	addq.l	#8,a2
	addq.l	#6,a1
	add	g_l_element(pc),a3
	dbf	d7,.a
	move.l	g_stack(pc),a7
	rts
	ENDC
	ENDC

;-------------------------------------------------

sicht_stack:	dc.l	0

skeitp:	lea	sicht_stack(pc),a0
	move.l	a7,(a0)

	lea	g_flanz(pc),a0
	clr.l	(a0)			; Anz. d. Fl. = 0

	move.l	objtab_p(pc),a0
	move	anzfl(pc),d7

	move.l	koordxy_p(pc),a2
	move.l	g_liste_p(pc),a3
	move.l	flcoloff_p(pc),a7

sicht4:	tst	(a0)			; zclip&bbox unsichtbar?
	beq	nicht_sicht4

	movem	2(a0),a4-a6		; offset (2d) fuer punkte holen
	move.l	(1+12)*4(a3),d1
	move.l	(a2,a4.l),d0		; punkte holen	(xxxxyyyy)
	move.l	(a2,a5.l),d2
	move.l	(a2,a6.l),d4

	IFD	m_bboard
	cmp	#t_bboard,d1
	beq.w	sicht4f
	ENDC

	IFD	m_flare
	cmp	#t_flare,d1
	beq.w	sicht4f
	ENDC

	IFD	m_fog
	cmp	#t_fog,d1
	bge.s	.c
	ENDC

	cmp	#t_emn_lim,d1
	bge.s	.b

	cmp	#t_n_lim,d1
	ble.s	.b

.c:	lea	0.w,a4
	lea	2.w,a5
	lea	4.w,a6

.b:	move.l	d0,a1
	move.l	d2,d6

	move	d0,d1
	move	d2,d3
	move.l	d4,d5
	swap	d0		; x ins lower word
	swap	d2		;      --''--
	swap	d4		;      --''--

	sub	d2,d0		;x1-x2
	sub	d3,d1		;y1-y2
	sub	d4,d2		;x2-x3
	sub	d5,d3		;y2-y3
	muls	d1,d2		;y1-y2 * x2-x3
	muls	d0,d3		;x1-x2 * y2-y3
	clr	(a0)		; sichtbar.w = 0
	sub.l	d2,d3
	bmi.w	nicht_sicht4

	move.l	a1,d1
				; y1=d1(a4) y2=d6(a5) y3=d5(a6)
	cmp	d1,d6
	bgt.s	s416g
	bne.s	s416k
	cmp.l	d1,d6		; d1.w=d6.w
	bgt.s	s416g

s416k:	cmp	d6,d5		; d6<d1	(weiter links)
	bgt.s	s465g
	bne.s	s465k
	cmp.l	d6,d5		; d6.w=d5.w
	bgt.s	s465g
				; d5<d6
s465k:				; d5 am kleinsten
	exg	d1,d5		; y3 y2 y1
	exg	a4,a6

;	exg	d5,d6		; y3 y1 y2
;	exg	a6,a5
;	bra.s	s415g

	bra.s	s465kg

s465g:				; d6 am kleinsten
	exg	d1,d6		; y2 y1 y3
	exg	a4,a5
s465kg:	exg	d6,d5		; y2 y3 y1
	exg	a5,a6
	bra.s	s415g

s416g:	cmp	d1,d5
	bgt.s	s415g
	bne.s	s465k
	cmp.l	d1,d5
	blt.s	s465k

s415g:				; d1 am kleinsten
	
;	cmp	#ysize,d1		; kleinstes y > y size?
	cmp	ysize_scr(pc),d1	; kleinstes y > y size?
	bge.w	sicht_ausser4

	move	d5,d0		; ermittle ymax
	cmp	d5,d6
	blt.s	s4wd1
	move	d6,d0
s4wd1:	tst	d0		; d0=ymax <= 0
	ble.s	sicht_ausser4

	move.l	d1,d2		; ermittle xmax
	cmp.l	d1,d5
	blt.s	s4wd2
	move.l	d5,d2
s4wd2:	cmp.l	d6,d2
	bgt.s	s4wd3
	move.l	d6,d2
s4wd3:	tst.l	d2		; d2.l=xmax < 0
	bmi.s	sicht_ausser4

	move.l	#(xsize*2^subpixel)*$10000,d4
	move.l	d1,d3		; ermittle xmin
	cmp.l	d1,d5
	bgt.s	s4wd4
	move.l	d5,d3
s4wd4:	cmp.l	d6,d3
	blt.s	s4wd5
	move.l	d6,d3
s4wd5:	cmp.l	d4,d3		; d3.l=xmin
	bge.s	sicht_ausser4

	sub.l	a1,a1
	tst	d1		; ymin	
	bpl.s	s4wd6
	addq.l	#1,a1
s4wd6:	cmp	ysize_scr(pc),d0	; ymax
;	cmp	#ysize,d0	; ymax
	blt.s	s4wd7
	addq.l	#1,a1
s4wd7:	tst.l	d3		; xmin
	bpl.s	s4wd8
	addq.l	#1,a1
s4wd8:	cmp.l	d4,d2		; xmax
	blt.s	s4wd9
	addq.l	#1,a1
s4wd9:

	move.l	a1,(a3)+		; flaeche vollstaendig drinnen?
	move.l	d1,(a3)+		; linke linie
	move.l	d5,(a3)+
	addq.l	#8,a3			; map pkt 1&3
	move.l	d1,(a3)+		; rechte linie
	move.l	d6,(a3)+
	addq.l	#8,a3			; map pkt1&2
	move.l	d6,(a3)+		; 3. linie
	move.l	d5,(a3)+

	movem	a4-a6,(a7)		; coloroffsets
;	addq.l	#8,a3			; map pkt 2&3
	lea	(g_element-(1+10)*4)(a3),a3
sicht4n:addq.l	#1,g_flanz		; g_flanz
	addq.l	#3*2,a7

;	subq	#1,(a0)			; sichtbar.w = -1
	move	#-1,(a0)
	addq.l	#8,a0
	dbf	d7,sicht4
	bra.s	sichtq4

	IFNE	m_flare_v|m_bboard_v
sicht4f:add	#g_element,a3
	bra.s	sicht4n
	ENDC

sicht_ausser4:
	addq	#1,(a0)			; sichtbar.w = 1
nicht_sicht4:
	addq.l	#8,a0
	add	g_l_element(pc),a3
	dbf	d7,sicht4

sichtq4:
	move.l	sicht_stack(pc),a7
	rts

;--------------------------------------------------------
; Rotiere Normalvektoren fuer PS

rot_xy_p:
	move.l	normal_zv_p(pc),a0
	move.l	nvekxy_p(pc),a1

	lea	abcdefghi(pc),a5	; schon korrekt initialisiert durch
					; vorhergehende vertexrotation

	move.l	koordxyz_p(pc),a2
	move	anzpkt(pc),d7
	move.l	normal_st_p(pc),a3

	IFD	bbox
	move.l	vertex_st_p(pc),a6
	ENDC

	tst.l	objectmp2(pc)
	bne.s	turnNVxy_m2

turnNVxy:
	IFD	bbox
	tst.b	(a6)+
	beq.s	.n
	ENDC

	tst.b	(a3)+
	bne.s	.a

	movem	(a0)+,d0-d2
	move.l	a5,a4
;	asl.l	#subpixel,d0
;	asl.l	#subpixel,d1
;	asl.l	#subpixel,d2
	move.l	d0,d3
	move.l	d1,d4
	move.l	d2,d5
	muls	(a4)+,d3
	muls	(a4)+,d4
	muls	(a4)+,d5
	add.l	d3,d4
	add.l	d4,d5
	add.l	d5,d5
	swap	d5
	sub	(a2)+,d5
;	asr	#subpixel,d5
	add	#nor_laenge,d5
	move	d5,(a1)+

	muls	(a4)+,d0
	muls	(a4)+,d1
	muls	(a4)+,d2
	add.l	d0,d1
	add.l	d1,d2
	add.l	d2,d2
	swap	d2
	sub	(a2)+,d2
;	asr	#subpixel,d2
	addq.l	#2,a2
	add	#nor_laenge,d2
	move	d2,(a1)+

	dbf	d7,turnNVxy
	rts

	IFD	bbox
.n:	addq.l	#1,a3
	ENDC
.a:
	addq.l	#6,a0
	addq.l	#6,a2
	addq.l	#4,a1
	dbf	d7,turnNVxy
	rts

;---

turnNVxy_m2:
	move.l	a7,g_stack

	IFD	bbox
	movem	objpos(pc),d6/a7
	ELSE
	movem	objpos(pc),d6/a6/a7
	ENDC

.a:	IFD	bbox
	tst.b	(a6)+
	beq.s	.n
	ENDC

	tst.b	(a3)+
	bne.s	.b

	movem	(a0)+,d0-d2
	move.l	a5,a4
	sub	d6,d0

	IFD	bbox
	sub	a7,d1
	sub	objpos+4(pc),d2
	ELSE
	sub	a6,d1
	sub	a7,d2
	ENDC

;	asl.l	#subpixel,d0
;	asl.l	#subpixel,d1
;	asl.l	#subpixel,d2
	move.l	d0,d3
	move.l	d1,d4
	move.l	d2,d5
	muls	(a4)+,d3
	muls	(a4)+,d4
	muls	(a4)+,d5
	add.l	d3,d4
	add.l	d4,d5
	add.l	d5,d5
	swap	d5
	sub	(a2)+,d5
;	asr	#subpixel,d5
	add	#nor_laenge,d5
	move	d5,(a1)+

	muls	(a4)+,d0
	muls	(a4)+,d1
	muls	(a4)+,d2
	add.l	d0,d1
	add.l	d1,d2
	add.l	d2,d2
	swap	d2
	sub	(a2)+,d2
;	asr	#subpixel,d2
	addq.l	#2,a2
	add	#nor_laenge,d2
	move	d2,(a1)+

	dbf	d7,.a

	move.l	g_stack(pc),a7
	rts

	IFD	bbox
.n:	addq.l	#1,a3
	ENDC
.b:
	addq.l	#6,a0
	addq.l	#6,a2
	addq.l	#4,a1
	dbf	d7,.a
	move.l	g_stack(pc),a7
	rts

;--------------------------------------------------------
	IFD	intro

anim_obj:
	move.l	anim_obj_rout_p(pc),d0
	beq.s	.q
	move.l	d0,a0
	jmp	(a0)
.q:	rts

;--------
; a5 = rotangle
; d7 = anzpkt
; a0 = quelle
; a1 = ziel

rot_p_n:
	move.l	normal_zv2_p(pc),a0
	move.l	normal_zv_p(pc),a1
	bra.s	rot_p

rot_p_k:
	move.l	koordxyz2_p(pc),a0
	move.l	koordxyz_sp_p(pc),a1
rot_p:	add.l	d0,a0
	add.l	d0,a1

rot_p_0:move.l	d7,-(a7)
	bsr	pre_yx
	move.l	(a7)+,d7

	movem	objobjpos(pc),d6/a2/a3

.rot:	movem	(a0)+,d0-d2
	move.l	a5,a4
	move.l	d0,d3
	move.l	d1,d4
	move.l	d2,d5
	muls	(a4)+,d3
	muls	(a4)+,d4
	muls	(a4)+,d5
	add.l	d3,d4
	move.l	d0,d3
	add.l	d4,d5
	move.l	d1,d4
	add.l	d5,d5
	swap	d5
	add	d6,d5
	move	d5,(a1)+

	move.l	d2,d5
	muls	(a4)+,d3
	muls	(a4)+,d4
	muls	(a4)+,d5
	add.l	d3,d4
	add.l	d4,d5
	add.l	d5,d5
	swap	d5
	add	a2,d5
	move	d5,(a1)+

	muls	(a4)+,d0
	muls	(a4)+,d1
	muls	(a4)+,d2
	add.l	d0,d1
	add.l	d1,d2
	add.l	d2,d2
	swap	d2
	add	a3,d2
	move	d2,(a1)+
	dbf	d7,.rot
	rts

;---
; a1 = slide
; a0 = ptr auf Splinekeys
; a2 = slideadd
; a3 = slideoffset

adj_t_spline:
	moveq	#8,d1

	subq	#1,(a1)
	bne.s	.c
	bra	get_nk

.c	move.l	(a2),d0
	add.l	d0,(a3)
	rts


	ENDC
;--------------------------------------------------------

objpos:	dc.w	0,0,0		; Auf diese Koordinaten blickt die Kamera hin.

;--------------------------------------------------------
; RotXYZ
;
; Parameter: a0 = object (x.w,y.w,z.w)
;	     a1 = Zieltabelle fuer rotierte Daten (x.w,y.w,z.w)
;	     a5 = Rotationswinkel (x,y,z) <= $7fe


abcdefghi:	dc.w	0,0,0,0,0,0,0,0,0
;			a b c d e f g h i
;			0 2 4 6 8 a c e 10

rotxyz:
	pea	(a5)
	bsr.s	rotyx
	move.l	(a7)+,a5
	rts

;--- um die y-achse

rotyx:
	move.l	koordxyz_sp_p(pc),a0
	move.l	koordxyz_p(pc),a1

rotyx_:
	bsr.w	pre_yx

	move	anzpkt(pc),d7

	IFD	bbox
	move.l	vertex_st_p(pc),a6
	ENDC

	tst.l	objectmp2(pc)
	bne.s	turnya_m2

.rot:	IFD	bbox
	tst.b	(a6)+
	beq.s	.n
	ENDC

	movem	(a0)+,d0-d2
	move.l	a5,a4
	move.l	d0,d3
	move.l	d1,d4
	move.l	d2,d5
	muls	(a4)+,d3
	muls	(a4)+,d4
	muls	(a4)+,d5
	add.l	d3,d4
	move.l	d0,d3
	add.l	d4,d5
	move.l	d1,d4
	add.l	d5,d5
	swap	d5
	move	d5,(a1)+

	move.l	d2,d5
	muls	(a4)+,d3
	muls	(a4)+,d4
	muls	(a4)+,d5
	add.l	d3,d4
	add.l	d4,d5
	add.l	d5,d5
	swap	d5
	move	d5,(a1)+

	muls	(a4)+,d0
	muls	(a4)+,d1
	muls	(a4)+,d2
	add.l	d0,d1
	add.l	d1,d2
	add.l	d2,d2
	swap	d2
;	asr	#subpixel,d2
	move	d2,(a1)+
	dbf	d7,.rot
	rts

	IFD	bbox
.n:	addq.l	#6,a0
	addq.l	#6,a1
	dbf	d7,.rot
	rts
	ENDC
;---

turnya_m2:
	movem	objpos(pc),d6/a2/a3
	
.rot:	IFD	bbox
	tst.b	(a6)+
	beq.s	.n
	ENDC

	movem	(a0)+,d0-d2
	move.l	a5,a4
	sub	d6,d0
	sub	a2,d1
	sub	a3,d2

;	asl.l	#subpixel,d0
;	asl.l	#subpixel,d1
;	asl.l	#subpixel,d2
	move.l	d0,d3
	move.l	d1,d4
	move.l	d2,d5
	muls	(a4)+,d3
	muls	(a4)+,d4
	muls	(a4)+,d5
	add.l	d3,d4
	move.l	d0,d3
	add.l	d4,d5
	move.l	d1,d4
	add.l	d5,d5
	swap	d5
	move	d5,(a1)+

	move.l	d2,d5
	muls	(a4)+,d3
	muls	(a4)+,d4
	muls	(a4)+,d5
	add.l	d3,d4
	add.l	d4,d5
	add.l	d5,d5
	swap	d5
	move	d5,(a1)+

	muls	(a4)+,d0
	muls	(a4)+,d1
	muls	(a4)+,d2
	add.l	d0,d1
	add.l	d1,d2
	add.l	d2,d2
	swap	d2
;	asr	#subpixel,d2
	move	d2,(a1)+
	dbf	d7,.rot
	rts

	IFD	bbox
.n:	addq.l	#6,a0
	addq.l	#6,a1
	dbf	d7,.rot
	rts
	ENDC

;---

; a	b	c	d	e	f	g	h	i
; 0	2	4	6	8	$a	$c	$e	$10

pre_yx:
	movem	(a5),d5-d7
	move.l	sinp(pc),a2
	lea	abcdefghi(pc),a5
	lea	$800(a2),a3

	neg	d5
	neg	d6
	and	#$1ffe,d5
	and	#$1ffe,d6

	move	(a2,d5.w),d0		;sin(xw)
	move	(a3,d5.w),d1		;cos(xw)

	move	(a2,d6.w),d2		;sin(yw)
	move	(a3,d6.w),d3		;cos(yw)

	move	(a2,d7.w),d4		;sin(zw)
	move	(a3,d7.w),d5		;cos(zw)

	move.l	d2,d6
	muls	d4,d6
	add.l	d6,d6
	swap	d6
	move.l	d0,d7
	muls	d3,d7
	add.l	d7,d7
	swap	d7
	muls	d5,d7
	add.l	d7,d7
	swap	d7
	sub	d7,d6
	move	d6,$a(a5)		; f=sin(yw)*sin(zw)*-sin(xw)*cos(yw)*
					; cos(zw)

	move.l	d0,d6
	muls	d5,d6
	add.l	d6,d6
	swap	d6
	muls	d2,d6
	add.l	d6,d6
	swap	d6
	move.l	d4,d7
	muls	d3,d7
	add.l	d7,d7
	swap	d7
	add	d7,d6
	move	d6,6(a5)		; d=sin(xw)*cos(zw)*sin(yw)+sin(zw)*
					; cos(yw)

	move.l	d5,d6
	muls	d2,d6
	add.l	d6,d6
	swap	d6
	move.l	d0,d7
	muls	d4,d7
	add.l	d7,d7
	swap	d7
	muls	d3,d7
	add.l	d7,d7
	swap	d7
	add	d7,d6
	move	d6,4(a5)		; c=cos(zw)*sin(yw)+sin(xw)*sin(zw)*
					; cos(yw)

	move.l	d0,d6
	muls	d4,d6
	add.l	d6,d6
	swap	d6
	muls	d2,d6
	add.l	d6,d6
	swap	d6
	move.l	d5,d7
	muls	d3,d7
	add.l	d7,d7
	swap	d7
	sub	d6,d7
	move	d7,(a5)			; a=-sin(xw)*sin(zw)*sin(yw)+
					; cos(zw)*cos(yw)

	move.l	d4,d6
	neg	d6
	muls	d1,d6
	add.l	d6,d6
	swap	d6
	move	d6,2(a5)		; b=-sin(zw)*cos(xw)

	move.l	d1,d6
	muls	d5,d6
	add.l	d6,d6
	swap	d6
	move	d6,8(a5)		; e=cos(zw)*cos(xw)

	move	d0,$e(a5)		; h=sin(xw)

	move.l	d1,d6
	muls	d3,d6
	add.l	d6,d6
	swap	d6
	move	d6,$10(a5)		; i=cos(xw)*cos(yw)

	neg	d1
	muls	d2,d1
	add.l	d1,d1
	swap	d1
	move	d1,$c(a5)		; g=-cos(xw)*sin(yw)
	rts


;---------------------------------------------------------------

pre_spline_t_tab:
	move.l	t_tab_p(pc),a0
	IFD	b_spline
	include	"i/spline/b-spline.s"
	ELSE
	include	"i/spline/catmull-rom.s"
	ENDC
t_tab_p:	dc.l	t_tab

;---

	IFD	_3ds
pre_spline_t_tab_3ds:
	move.l	t_tab_p_3ds(pc),a0
	include	"i/spline/hermit.s"

t_tab_p_3ds:	dc.l	t_tab_3ds
	ENDC

;--------------------------------------------------------------
; 'camera' ist der Ortsvektor, von dem aus das Objekt betrachtet wird.
; camera:	dc.w	0,0,0		; x,y,z Kamera-Position

	include	"i/geometry/calc_camera.s"

;-------------------

init_keyf:
	IFD	_3ds
	tst	_3ds_st(pc)
	bne.s	.w3
	ENDC

	lea	pointsp(pc),a0
	lea	slide(pc),a1
	lea	slideadd(pc),a2
	lea	slideoff(pc),a3
	move.l	objectmp(pc),(a0)
	moveq	#8,d1
	bsr	get_k

	lea	pointsp2(pc),a0
	lea	slidet(pc),a1
	lea	slidetadd(pc),a2
	lea	slidetoff(pc),a3
	move.l	objectmp2(pc),(a0)
	tst.l	(a0)
	beq.s	.h1
	bsr	get_k

.h1:	lea	pointsp3(pc),a0
	lea	slidez(pc),a1
	lea	slidezadd(pc),a2
	lea	slidezoff(pc),a3
	move.l	objectmp3(pc),(a0)
	tst.l	(a0)
	beq.s	.h2
	moveq	#4,d1
	bra	get_k
.h2:	rts
;-
	IFD	_3ds
.w3:	move.l	objecttrk(pc),d0
	beq.s	.a

	lea	llerpcnt(pc),a1
	move.l	d0,a0
	move	#llerp,(a1)

.w:	move.l	(a0)+,d0
	bmi.s	.a
	lea	4(a0),a1
	lea	4+2(a0),a2
	lea	4+2+4(a0),a3
	move.l	d0,(a0)
	bsr.s	get_key
	lea	4+2+8+2+4(a0),a0
	move.l	(a0)+,(a0)
	tst.l	(a0)
	beq.s	.w2
	bsr.s	get_next_llerp
.w2:	lea	4+9*2*4(a0),a0
	bra.s	.w
.a:

	lea	pointsp(pc),a0
	lea	slide(pc),a1
	lea	slideadd(pc),a2
	lea	slideoff(pc),a3
	move.l	objectmp(pc),(a0)
	bsr.s	get_key

	lea	pointsp2(pc),a0
	lea	slidet(pc),a1
	lea	slidetadd(pc),a2
	lea	slidetoff(pc),a3
	move.l	objectmp2(pc),(a0)
	bra.s	get_key

;---

get_next_key:
	move.l	(a0),a5
	tst	(12*2+2)*2(a5)
	bpl.s	.a
	move	#1,(a1)
	rts
.a:	add.l	#12*2+2,(a0)

get_key:
	move.l	(a0),a5
	moveq	#0,d0
	move	12*2+2(a5),d0
	sub	(a5),d0

	move.l	divtab_p(pc),a5
	move	d0,(a1)

	move	(a5,d0.w*2),d0
	clr.l	(a3)
	lsl.l	#3,d0
	move.l	d0,(a2)
	rts

;---

get_next_llerp:
	move.l	(a0),a1
	lea	4(a0),a3
	lea	9*2(a1),a2
	lea	9*4(a3),a4

	moveq	#9-1,d7
.a:	moveq	#0,d0
	moveq	#0,d1
	move	(a1)+,d0
	move	(a2)+,d1
	swap	d0
	swap	d1
	move.l	d0,(a3)+
	sub.l	d0,d1
	asr.l	#3,d1
	move.l	d1,(a4)+
	dbf	d7,.a
	rts

;---

do_spline_3ds:
	move.l	t_tab_p_3ds(pc),a2

	moveq	#3-1,d7
	add.l	d0,a2

.ag:	move.l	a2,a3
	move	(a1)+,d0
	move	(a1)+,d1
	move	(a1)+,d2
	move	(a1)+,d3

	muls	(a3)+,d0
	muls	(a3)+,d1
	muls	(a3)+,d2
	muls	(a3),d3
	add.l	d1,d0
	add.l	d2,d3
	add.l	d3,d0
	add.l	d0,d0
	swap	d0
	move	d0,(a4)+
	dbf	d7,.ag

	subq.l	#6,a4
	rts
	ENDC

;---

do_spline1_3:
	move.l	t_tab_p(pc),a2
	add.l	d0,a2

	move	(a1),d0
	move	4(a1),d1
	move	8(a1),d2
	move	12(a1),d3

	muls	(a2)+,d0
	muls	(a2)+,d1
	muls	(a2)+,d2
	muls	(a2),d3
	add.l	d1,d0
	add.l	d2,d3
	add.l	d3,d0
	add.l	d0,d0
	swap	d0
	move	d0,(a4)
	rts

;---

do_spline:
	move.l	t_tab_p(pc),a2

	moveq	#3-1,d7
	add.l	d0,a2

.ag:	move	6+2(a1),d1
	move	(6+2)*2(a1),d2
	move	(6+2)*3(a1),d3
	move	(a1)+,d0
	move.l	a2,a3

	muls	(a3)+,d0
	muls	(a3)+,d1
	muls	(a3)+,d2
	muls	(a3),d3
	add.l	d1,d0
	add.l	d2,d3
	add.l	d3,d0
	add.l	d0,d0
	swap	d0
	move	d0,(a4)+
	dbf	d7,.ag

	subq.l	#6,a4
	rts


slide:	dc	0
slidet:	dc	0
slidez:	dc	0

	cnop	0,4

pointsp:	dc.l	0	; camera
pointsp2:	dc.l	0	; objpos
pointsp3:	dc.l	0	; Z-Axis

slideoff:	dc.l	0
slidetoff:	dc.l	0
slidezoff:	dc.l	0
slideadd:	dc.l	0
slidetadd:	dc.l	0
slidezadd:	dc.l	0
	IFD	_3ds
llerpcnt:	dc	0
	ENDC

;-------------------------------------------------------

anim_obj_rout_p:	dc.l	0
anim_obj_adj_p:	dc.l	0

rotangle:	dc.w	0,0,0
objobjpos:	dc	0,0,0


ddcalc:
	move	anzpkt(pc),d6

	move.l	koordxyz_p(pc),a0
	move.l	koordxy_p(pc),a1

	move	ysize_scr(pc),d5
	move	#(xsize*2^subpixel)/2,d4
	lsr	#1,d5

	lea	(zmin*2^subpixel).w,a3

	moveq	#subpixel,d3
;	moveq	#0,d3

	move	z_add(pc),a2

	move	#auge*2^subpixel,d7	;d0 = Auge

	IFD	bbox
	move.l	vertex_st_p(pc),a6
	ENDC

	tst	half_scr(pc)
	beq.s	persp2

	moveq	#subpixel+1,d3
;	moveq	#1,d3

persp2:	IFD	bbox
	tst.b	(a6)+
	beq.s	.n
	ENDC
	movem	(a0)+,d0-d2
	add	a2,d2
	cmp	a3,d2
	ble.s	.a
	muls	d7,d0		;d3 = Px*Auge
	sub	d7,d2		;d5 = Pz-Auge
	muls	d7,d1		;d4 = Py*Auge
	divs	d2,d0		;d3 = Px*Auge/(Pz-Auge)
	divs	d2,d1		;d4 = Py*Auge/(Pz-Auge)
	neg	d0		;d3 = -d3

;	asr	#subpixel,d0
	asr	d3,d1

	add	d4,d0		;d3 = 160-Px*Auge/(Pz-Auge)
	add	d5,d1
	move	d0,(a1)+
	move	d1,(a1)+
	dbra	d6,persp2
	rts

.n:	addq.l	#6,a0
.a:	addq.l	#4,a1
	dbra	d6,persp2
	rts

z_add:	dc.w	$180

;-------------------

		cnop	0,4

anzpkt:		dc.w	0		; Anzahl der Punkte des Objekts
anzfl:		dc.w	0		; Anzahl der Flaechen des Objekts
objectpp:	dc.l	0		; Pointer auf Vertices des Objekts
objecttp:	dc.l	0		; Pointer auf Tris des Objects
objectlp:	dc.l	0		; Pointer auf Liste von zusaetzl. Infos
objectip:	dc.l	0		; Pointer auf lokale Init-routine d. O.
objectcp:	dc.l	0		; Pointer auf Farben des Objekts
objecttexp:	dc.l	0		; Pointer auf Texturenpointerliste
objectmp:	dc.l	0		; Pointer auf Movementdaten d. Kamera
objectmp2:	dc.l	0		; Pointer auf Movementdaten d. Objects
objectmp3:	dc.l	0		; Pointer auf Movementdaten um Z-Axis
	IFD	_3ds
objecttrk:	dc.l	0		; Pointer auf Trackinvlist
	ENDC

pktcols_p:	dc.l	0
objtab_p:	dc.l	0
flg_lp_p:	dc.l	0
koordxy_p:	dc.l	0
koordxyz_p:	dc.l	0
koordxyz_sp_p:	dc.l	0		; Originaldaten in Subpixel
normal_zv_p:	dc.l	0
normal_st_p:	dc.l	0
	IFD	bbox
vertex_st_p:	dc.l	0
	ENDC
flcoloff_p:	dc.l	0
objvert6_p:	dc.l	0
objvert6_p2:	dc.l	0
tri2map_p:	dc.l	0
koordxyz2_p:	dc.l	0
normal_zv2_p:	dc.l	0

;--------------------------------------------------------------------------
; Phong/Env256

copy_clear2:
	move	ysize_scr(pc),d7
	move.l	ps16_sbuf(pc),a0
	lea	10*4.w,a5
	subq.l	#1,d7

	sub.l	a6,a6
	tst	half_scr(pc)
	beq.s	.a

	lea	320.w,a6

.a:	bra.s	copy_clear\.a

;-----------------------------------

copy_clear_st:	dc	0
x_bg_off:	dc.w	0
y_bg_off:	dc.w	0

copy_clear:
	lea	x_bg_off(pc),a2

	move.l	rotangle(pc),d0
	lsr	#3,d0
	move	d0,(a2)
	swap	d0
	lsr	#3,d0
	move	d0,2(a2)

	and.l	#$00ff00ff,(a2)

	move	ysize_scr(pc),d7
	move	(a2),d0
	move	2(a2),d1

.r:	lea	dummymap3-256*256,a1
	move.l	ps16_sbuf(pc),a0
	mulu	#256*3,d1
	lea	10*4.w,a5
	subq.l	#1,d7
	add	d0,a1
	add.l	d1,a1

	lea	(256*3-320).w,a6
	tst	half_scr(pc)
	beq.s	.a

	lea	(256*3*2-320).w,a6

.a:	movem.l	(a1)+,d0-d6/a2-a4
	movem.l	d0-d6/a2-a4,(a0)
	add.l	a5,a0
	movem.l	(a1)+,d0-d6/a2-a4
	movem.l	d0-d6/a2-a4,(a0)
	add.l	a5,a0
	movem.l	(a1)+,d0-d6/a2-a4
	movem.l	d0-d6/a2-a4,(a0)
	add.l	a5,a0
	movem.l	(a1)+,d0-d6/a2-a4
	movem.l	d0-d6/a2-a4,(a0)
	add.l	a5,a0
	movem.l	(a1)+,d0-d6/a2-a4
	movem.l	d0-d6/a2-a4,(a0)
	add.l	a5,a0
	movem.l	(a1)+,d0-d6/a2-a4
	movem.l	d0-d6/a2-a4,(a0)
	add.l	a5,a0
	movem.l	(a1)+,d0-d6/a2-a4
	movem.l	d0-d6/a2-a4,(a0)
	add.l	a5,a0
	movem.l	(a1)+,d0-d6/a2-a4
	movem.l	d0-d6/a2-a4,(a0)
	add.l	a5,a0
	add.l	a6,a1
	dbf	d7,.a
	rts


ps256_clear:
	tst	clear_st(pc)
	beq.s	.a
	rts

.a:	tst	copy_clear_st(pc)
	bne	copy_clear

	lea	g_stack(pc),a0
	moveq	#0,d0
	moveq	#0,d1
	move.l	a7,(a0)
	moveq	#0,d2
	moveq	#0,d3
	move.l	ps16_sbuf(pc),a0
	moveq	#0,d4
	move.l	d0,a1
	move.l	ps16_sbuf_size(pc),d7
	move.l	d0,a2
	move.l	d0,a3
	add.l	d7,a0
	move.l	d0,a4
	move.l	d0,a5
	divu	#14*4*8,d7
	move.l	d0,a6
	move.l	d0,a7
	swap	d7
	moveq	#0,d5
	lsr	#2,d7
	moveq	#0,d6
	subq	#1,d7
	bmi.b	.wx
.ps16_sbcb:
	move.l	d0,-(a0)
	dbf	d7,.ps16_sbcb
.wx:	swap	d7

	subq.l	#1,d7
.ps16_sbc:
	movem.l	d0-d6/a1-a7,-(a0)
	movem.l	d0-d6/a1-a7,-(a0)
	movem.l	d0-d6/a1-a7,-(a0)
	movem.l	d0-d6/a1-a7,-(a0)
	movem.l	d0-d6/a1-a7,-(a0)
	movem.l	d0-d6/a1-a7,-(a0)
	movem.l	d0-d6/a1-a7,-(a0)
	movem.l	d0-d6/a1-a7,-(a0)
	dbf	d7,.ps16_sbc

	move.l	g_stack(pc),a7
	rts

;---------------------------------------------------------------------

	IFD	m_fog
update_fog:
	moveq	#0,d1
	move	fog_max(pc),d1
	lea	fog_dist(pc),a0
	sub	fog_min(pc),d1

	lsl.l	#8,d1			; div 256

	move.l	d1,(a0)

	rts
	ENDC

;---------------------------------------------------------------------

no_ps256fill:	rts

ps256_fill:
	tst.l	g_flanz(pc)		; ueberhaupt ne Flaeche sichtbar?
	beq.s	no_ps256fill

	IFD	m_fog
	tst	fog_st(pc)
	beq.s	.a
	bsr.s	update_fog
.a:	ENDC

	move.l	a7,g_stack

	move.l	flg_lp_p(pc),g_flp
	
ps256_neufl:
	move.l	g_flp(pc),a0
	move.l	(a0),a7			; g_liste richtig setzen
	addq.l	#4,g_flp

	lea	ps16_stat(pc),a6
	move.l	ps16_sbuf(pc),a0
	lea	(1+12)*4(a7),a3
	move.l	divtab_p(pc),a5

	IFD	m_bboard
	cmp.l	#t_bboard,(a3)
	beq	tbboard
	ENDC

	IFD	m_flare
	cmp.l	#t_flare,(a3)
	beq	tflare
	ENDC

	clr.l	(a6)
	lea	ps16_g_p(pc),a2
	clr.l	4(a6)

	move.l	a3,(a2)

	tst.l	(a7)+
	bne	ps256c_fill

	movem	(a7)+,d0-d2/d7
	sub.l	d1,d7			; delta y
	beq	ps256_nxtfl		; die Flaeche is' ne Linie.
	sub.l	d0,d2			; delta x
	swap	d0			; li x
	muls	(a5,d7.l*2),d2		; dx/dy
	add.l	d2,d2			; li x add
	add.l	([ytab_p.w,pc],d1.l*4),a0	; d1 y
	move.l	d2,a2			; li x add

	movem	(a7)+,d1-d4
	sub.l	d1,d3
	sub.l	d2,d4
	swap	d1
	muls	(a5,d7.l*2),d3
	swap	d2
	muls	(a5,d7.l*2),d4
	add.l	d3,d3			; li x map add
	add.l	d4,d4			; li y map add
	move.l	d1,a3			; li x map
	move.l	d2,a4			; li y map
	move.l	d3,a1
	move.l	d4,ps16_helfi

	movem	(a7)+,d1-d4		; rechts
	sub.l	d2,d4			; delta y
	bne.s	.ps16_wd1
	addq.l	#8,a7			; Naexte Fl. (Mapteil skippen)
	movem	(a7)+,d1-d4
	sub.l	d2,d4			; delta y

	subq.l	#8,(a6)			; ps16_stat

.ps16_wd1:
	sub.l	d1,d3			; delta x
	swap	d1			; re x
	muls	(a5,d4.l*2),d3
	add.l	d3,d3			; re x add

;- li oder re kuerzer?

	cmp.l	d4,d7
	blt.s	.ps16_ligr

	addq.l	#1,(a6)			; ps16_stat	; li laenger od. gleich
	move.l	d4,d7

.ps16_ligr:

	move.l	d4,a6

	movem	(a7)+,d2/d4/d5/d6
	sub.l	d2,d5
	sub.l	d4,d6
	swap	d4
	exg	d4,a6
	muls	(a5,d4.l*2),d5
	swap	d2			; re x map
	muls	(a5,d4.l*2),d6
	add.l	d5,d5			; re x map add
	add.l	d6,d6			; re y map add
	move.l	a6,d4			; re y map

	move.l	ps16_helfi(pc),a5
	exg	d3,a3
	exg	d5,a4

; d0 li x	; a2 li x add
; d3 li x map	; a1 li x map add
; d5 li y map	; a5 li y map add
; d1 re x	; a3 re x add
; d2 re x map	; a4 re x map add	; keine verwendung bei precision=0
; d4 re y map	; d6 re y map add	; keine verwendung bei precision=0

	move.l	a7,ps16_helfi
	move.l	g_stack(pc),a7

	IFND	precision
	tst	ps16_stat(pc)
	bpl.s	.psc2
	bsr	calc_const
.psc2:	ENDC

	bsr	ps_do_lt

	IFND	precision
	tst	ps16_stat(pc)
	bmi.s	.psc
	bsr	calc_const
.psc:	ENDC

	move.l	ps16_helfi(pc),a7

	tst.l	ps16_stat(pc)
	bmi.s	.ps16_wda
	beq.s	.ps16_liku

	IFD	precision
		lea	ps16_regs(pc),a3
		move.l	divtab_p(pc),a4
		move.l	d5,(a3)

		move.l	d3,a3

		movem	(a7)+,d1-d3/d7		; rechts
		sub.l	d2,d7			; delta y
		beq.s	.ps16_wda
		sub.l	d1,d3			; delta x
		swap	d1
		muls	(a4,d7.l*2),d3
		add.l	d3,d3

		movem	(a7),d2/d4/d5/d6
		exg	d3,a3
		sub.l	d2,d5
		sub.l	d4,d6
		swap	d2
		muls	(a4,d7.l*2),d5
		swap	d4
		muls	(a4,d7.l*2),d6
		add.l	d5,d5
		add.l	d6,d6

		move.l	d5,a4
		move.l	ps16_regs(pc),d5

	ELSE
	movem	(a7)+,d1-d2/d6/d7	; rechts
	sub.l	d2,d7			; delta y
	beq.s	.ps16_wda
	sub.l	d1,d6			; delta x
	move.l	divtab_p(pc),a4
	swap	d1
	muls	(a4,d7.l*2),d6
	add.l	d6,d6
	move.l	d6,a3
	ENDC
	
	bra.s	.ps16_lt2

.ps16_liku:
	IFND	precision
	move.l	d1,d6
	ELSE
		lea	ps16_regs(pc),a1
		move.l	d1,(a1)+
		move.l	d2,(a1)
	ENDC

	movem	(a7)+,d0-d2/d7
	exg	d1,d7
	exg	d0,d2
	move.l	divtab_p(pc),a5
	sub.l	d1,d7			; delta y
;	beq.s	.ps16_wda		; bei gleichheit waeres es re
	sub.l	d0,d2			; delta x
	muls	(a5,d7.l*2),d2		; dx/dy
	swap	d0			; li x
	add.l	d2,d2			; li x add
	move.l	d2,a2			; li x add

	movem	(a7),d1-d3/d5
	sub.l	d3,d1
	sub.l	d5,d2
	swap	d3			; li x map
	muls	(a5,d7.l*2),d1
	swap	d5			; li y map
	muls	(a5,d7.l*2),d2
	add.l	d1,d1
	add.l	d2,d2

	move.l	d1,a1			; li x map add
	move.l	d2,a5			; li y map add

	IFND	precision
	move.l	d6,d1
	ELSE
		movem.l	ps16_regs(pc),d1/d2
	ENDC

.ps16_lt2:
	move.l	g_stack(pc),a7
	bsr	ps_do_lt2

.ps16_wda:
	move.l	ps16_g_p(pc),a7

	move.l	(a7)+,d0
	move.l	(a7)+,a2
	jmp	([(fill_jt).w,pc,d0.l*4])

;--------------------------------------------

tmap:
	IFND	precision
	include	"i/tmap/tmap.s"
	ELSE
	include	"i/tmap/tmap_prec.s"
	ENDC	

ps256_nxtfl:
	lea	g_flanz(pc),a0
	subq.l	#1,(a0)
	bne.w	ps256_neufl

	move.l	g_stack(pc),a7
	rts

;---------------------------------

	IFND	precision
tmap030:
	include	"i/tmap/tmap030.s"

tmapc030:
	include	"i/tmap/tmap030c.s"
	ENDC

;------------------------

ps256c_fill:
	movem	(a7)+,d0-d2/d7
	tst.l	d7
	bgt.s	.ps16c_nnl

	movem	8+16(a7),d0-d2/d7	; Linie vollstaendig oberhalb
	subq.l	#8,(a6)			; ps16_stat
	exg	d0,d2
	exg	d1,d7

.ps16c_nnl:
	move.l	d7,d6

	sub.l	d1,d7			; delta y
	beq	ps256_nxtfl		; die Flaeche is' ne Linie.
	sub.l	d0,d2			; delta x
	swap	d0			; li x
	muls	(a5,d7.l*2),d2		; dx/dy
	lea	ps16_regs(pc),a2
	add.l	d2,d2			; li x add
	move.l	d1,(a2)
	add.l	([ytab_p.w,pc],d1.l*4),a0	; d1 y
	move.l	d2,a2
	IFD	em_clip
	move.l	d7,clip_1st
	move.l	d7,clip_sum
	clr.l	clip_upli
	clr.l	clip_upre
	ENDC

	tst.l	(a6)
	beq.s	.ps16c_nnl2
	movem	8+16+8(a7),d1-d4
	exg	d1,d3
	exg	d2,d4
	bra.s	.ps16c_nnl3

.ps16c_nnl2:
	movem	(a7),d1-d4
.ps16c_nnl3:
	sub.l	d1,d3
	sub.l	d2,d4
	swap	d1
	muls	(a5,d7.l*2),d3
	swap	d2
	addq.l	#8,a7
	muls	(a5,d7.l*2),d4
	add.l	d3,d3
	add.l	d4,d4

	sub	ysize_scr(pc),d6
	ble.s	.ps16c_cy3		;Kein unteres y clipping noetig
	sub	d6,d7
.ps16c_cy3:

	move.l	d1,a3			; li x map
	move.l	ps16_regs(pc),d1
	move.l	d2,a4			; li y map

	tst.l	d1
	bpl.s	.ps16c_cy1		; Kein oberes y clipping noetig
	move.l	a2,d6			; Schrittweite x
	add.l	d1,d7			; Anzahl Schritte korrigieren.
	muls.l	d1,d6
	IFD	em_clip
	move.l	d1,clip_upli
	ENDC
	sub.l	d6,d0		; x korrigieren. ('sub', weil d1 negativ ist.)
	move.l	d3,d6			; Schrittweite x map
	muls.l	d1,d6
	move.l	ps16_sbuf(pc),a0
	sub.l	d6,a3			; x map korrigieren.
	move.l	d4,d6			; Schrittweite y map
	muls.l	d1,d6
	sub.l	d6,a4			; y map korrigieren.
.ps16c_cy1:

	move.l	d3,a1			; li x map add
	move.l	d4,ps16_helfi		; li y map add

	movem	(a7)+,d1-d4		; rechts
	tst.l	d4
	bgt.s	.ps16c_nnl4
					; Linie vollstaendig drueber
	movem	8(a7),d1-d4
	subq.l	#8,(a6)			; ps16_stat
	subq.l	#1,4(a6)		; ps16_stat+4
.ps16c_nnl4:
	move.l	d4,d5
	sub.l	d2,d4			; delta y
	bne.s	.ps16c_wd1

	movem	8(a7),d1-d4		; Naexte Fl. (Mapteil skippen)
	move.l	d4,d5
	subq.l	#8,(a6)			; ps16_stat
	sub.l	d2,d4			; delta y
	subq.l	#1,4(a6)		; ps16_stat+4

.ps16c_wd1:
	sub.l	d1,d3			; delta x
	move.l	d2,ps16_regs
	swap	d1			; re x
	muls	(a5,d4.l*2),d3
	move.l	d4,d6
	add.l	d3,d3			; re x add
	IFD	em_clip
	cmp.l	clip_1st(pc),d4
	bgt.s	.nl
	move.l	d4,clip_1st
	clr.l	clip_stat
	bra.s	.nr
.nl:	move.l	d4,clip_sum
	move	#1,clip_stat+2
.nr:	ENDC

;- li oder re kuerzer?

	sub	ysize_scr(pc),d5
	ble.s	.ps16c_cy4		;Kein unteres y clipping noetig
	sub	d5,d4
.ps16c_cy4:

	move.l	d4,llength
	move.l	d6,a6

	tst.l	ps16_stat(pc)
	bpl.s	.ps16c_wda2
	tst.l	ps16_stat+4(pc)
	beq.s	.ps16c_wda2
	movem	8+8(a7),d2/d4/d5/d6
	bra.s	.ps16c_wda3
.ps16c_wda2:
	movem	(a7)+,d2/d4/d5/d6
.ps16c_wda3:
	sub.l	d2,d5
	sub.l	d4,d6
	swap	d4			; re y map
	exg	d4,a6
	muls	(a5,d4.l*2),d5
	swap	d2			; re x map
	muls	(a5,d4.l*2),d6
	lea	ps16_regs(pc),a5
	add.l	d5,d5			; re x map add
	move.l	d0,4(a5)
	add.l	d6,d6			; re x map add
	move.l	(a5)+,d0

	exg	d3,a3
	exg	d5,a4

	move.l	llength(pc),d4

	tst.l	d0
	bpl.s	.ps16c_cy2		; Kein oberes y clipping noetig
	move.l	d3,4(a5)
	move.l	a3,d3			; Schrittweite x
	add.l	d0,d4			; Anzahl Schritte korrigieren.
	muls.l	d0,d3
	IFD	em_clip
	move.l	d0,clip_upre
	ENDC
	sub.l	d3,d1		; x korrigieren. ('sub', weil d1 negativ ist.)
	move.l	a4,d3			; Schrittweite x map
	muls.l	d0,d3
	sub.l	d3,d2			; x map korrigieren.
	move.l	d6,d3			; Schrittweite y map
	muls.l	d0,d3
	sub.l	d3,a6			; y map korrigieren.
	move.l	4(a5),d3
.ps16c_cy2:
	move.l	(a5),d0

	cmp.l	d4,d7
	blt.s	.ps16c_ligr

	addq.l	#1,ps16_stat			; li laenger od. gleich
	move.l	d4,d7

.ps16c_ligr:
	move.l	ps16_helfi(pc),a5
	move.l	a6,d4

; d0 li x	; a2 li x add
; d3 li x map	; a1 li x map add
; d5 li y map	; a5 li y map add
; d1 re x	; a3 re x add
; d2 re x map	; a4 re x map add		; kein bedarf bei
; d4 re y map	; d6 re y map add		; precision = 0

	move.l	ps16_ltt_p(pc),a6
	move.l	a7,ps16_helfi
	move.l	g_stack(pc),a7

	IFND	precision
	tst	ps16_stat(pc)
	bpl.s	.psc2
	bsr	calc_const
.psc2:	ENDC

	bsr	ps_do_lt

	IFND	precision
	tst	ps16_stat(pc)
	bmi.s	.psc
	bsr	calc_const
.psc:	ENDC

	move.l	ps16_helfi(pc),a7

	tst.l	ps16_stat(pc)
	bmi	.ps16c_wda
	beq.s	.ps16c_liku

	IFD	precision
		lea	ps16_regs(pc),a3
		move.l	divtab_p(pc),a4
		move.l	d0,(a3)+
		move.l	d5,(a3)
		move.l	d3,a3

		movem	(a7)+,d1-d3/d7		; rechts
		move.l	d7,d0
		cmp	ysize_scr(pc),d2
		bge	.ps16c_wda

		sub.l	d2,d7			; delta y
		beq	.ps16c_wda
		sub.l	d1,d3			; delta x
		swap	d1
		muls	(a4,d7.l*2),d3
		add.l	d3,d3
	
		movem	(a7)+,d2/d4/d5/d6
		exg	d3,a3
		sub.l	d2,d5
		sub.l	d4,d6
		swap	d2
		muls	(a4,d7.l*2),d5
		swap	d4
		muls	(a4,d7.l*2),d6
		add.l	d5,d5
		add.l	d6,d6

		sub	ysize_scr(pc),d0
		ble.s	.ps16c_cy5
		sub	d0,d7
.ps16c_cy5:
		move.l	d5,a4
		movem.l	ps16_regs(pc),d0/d5
	ELSE

	move.l	divtab_p(pc),a4
	movem	(a7)+,d1-d2/d6/d7		; rechts
	move.l	d7,d4
	cmp	ysize_scr(pc),d2
	bge.s	.ps16c_wda

	sub.l	d2,d7			; delta y
	beq.s	.ps16c_wda
	sub.l	d1,d6			; delta x
	swap	d1
	muls	(a4,d7.l*2),d6
	add.l	d6,d6
	addq.l	#2*4,a7
	move.l	d6,a3

	sub	ysize_scr(pc),d4
	ble.s	.ps16c_cy5
	sub	d4,d7
.ps16c_cy5:
	ENDC

	bra.s	.ps16c_lt2
;-
.ps16c_liku:
	IFND	precision
	move.l	d1,d6
	ELSE
		lea	ps16_regs(pc),a1
		move.l	d1,(a1)+
		move.l	d2,(a1)
	ENDC

	movem	(a7)+,d0-d2/d7
	exg	d0,d2
	exg	d1,d7
	move.l	divtab_p(pc),a5
	move.l	d7,a1
	cmp	ysize_scr(pc),d1
	bge.s	.ps16c_wda
	sub.l	d1,d7			; delta y
;	beq.s	.ps16_wda		; bei gleichheit waeres es re
	sub.l	d0,d2			; delta x
	muls	(a5,d7.l*2),d2		; dx/dy
	swap	d0			; li x
	add.l	d2,d2			; li x add
	move.l	d2,a2			; li x add

	movem	(a7)+,d1-d3/d5
	sub.l	d3,d1
	sub.l	d5,d2
	swap	d3
	muls	(a5,d7.l*2),d1
	swap	d5			; li y map
	muls	(a5,d7.l*2),d2
	add.l	d1,d1
	exg	a1,d7
	add.l	d2,d2

	sub	ysize_scr(pc),d7
	ble.s	.ps16c_cy6
	sub	d7,a1
.ps16c_cy6:
	move.l	a1,d7

	move.l	d1,a1			; li x map add
	move.l	d2,a5			; li y map add

	IFND	precision
	move.l	d6,d1
	ELSE
		movem.l	ps16_regs(pc),d1/d2
	ENDC

.ps16c_lt2:
	move.l	g_stack(pc),a7
	bsr	ps_do_lt2

.ps16c_wda:
	move.l	ps16_g_p(pc),a7

	move.l	(a7)+,d0
	move.l	(a7)+,a2
	jmp	([(fill_c_jt).w,pc,d0.l*4])

;--------------------------------------------

tmapc:	IFND	leftadd
		IFND	precision
		include	"i/tmap/tmapc.s"
		ELSE
		include	"i/tmap/tmapc_prec.s"
		ENDC	
	ELSE
		IFND	precision
		include	"i/tmap/tmapc_leftadd.s"
		ELSE
		include	"i/tmap/tmapc_prec_leftadd.s"
		ENDC	
	ENDC

;--------------------------------------------

	IFD	m_bi_map
bimap:	include	"i/bimap/bimap.s"
bimapc:	include	"i/bimap/bimapc.s"
	ENDC

;--------------------------------------------

	IFD	m_transparent
transmap:
	IFND	precision
	include	"i/transmap/transmap.s"
	ELSE
	include	"i/transmap/transmap_prec.s"
	ENDC	

transmapc:
	IFND	leftadd
		IFND	precision
		include	"i/transmap/transmapc.s"
		ELSE
		include	"i/transmap/transmapc_prec.s"
		ENDC	
	ELSE
		IFND	precision
		include	"i/transmap/transmapc_leftadd.s"
		ELSE
		include	"i/transmap/transmapc_prec_leftadd.s"
		ENDC	
	ENDC
	ENDC

;--------------------------------------------

	IFD	m_gouraud_tmap
gtmap:	include	"i/gtmap/gtmap.s"
gtmapc:	include	"i/gtmap/gtmapc.s"

	include	"i/gtmap/init_gtmap.s"
	ENDC

;--------------------------------------------

	IFD	m_fog
tfogmap:include	"i/fog/tfogmap.s"
tfogmapc:
	include	"i/fog/tfogmapc.s"
init_fog:
	include	"i/fog/init_fog.s"
	ENDC

;--------------------------------------------

	IFD	m_phong_tmap
ptmap:	include	"i/ptmap/ptmap.s"
ptmapc:	include	"i/ptmap/ptmapc.s"
	ENDC

;--------------------------------------------

	IFNE	m_phong_tmap_v|m_bump_v|m_tbump_v
init_ptmap:
	include	"i/ptmap/init_ptmap.s"
	ENDC

;--------------------------------------------

	IFD	m_bump
bumpmap:;include	"i/bumpmap/bumpmap.s"
bumpmapc:
	;include	"i/bumpmap/bumpmapc.s"
	ENDC

;--------------------------------------------

	IFD	m_tbump
tbumpmap:
	include	"i/tbumpmap/tbumpmap.s"
tbumpmapc:
	include	"i/tbumpmap/tbumpmapc.s"
	ENDC
	
;--------------------------------------------

	IFD	m_flare
tflare:
	include	"i/flares/tflare.s"
	ENDC

;--------------------------------------------

	IFD	m_bboard
tbboard:
	include	"i/flares/tbboard.s"
	ENDC

;----------------------------------------------------------------------

	cnop	0,4

;-
fill_jt:
		IFD	m_bi_map
		dc.l	bimap
		ELSE
		dc.l	0
		ENDC
;-
		IFD	m_transparent
		dc.l	transmap		; t_transphong
		ELSE
		dc.l	0
		ENDC
;-
		dc.l	tmap			; t_phong
;-
		dc.l	tmap			; t_texmap
;-
		IFD	m_transparent
		dc.l	transmap		; t_transtexmap
		ELSE
		dc.l	0
		ENDC
;-
		IFD	m_bi_map
		dc.l	bimap
		ELSE
		dc.l	0
		ENDC
;-
		IFD	m_gouraud_tmap
		dc.l	gtmap			; t_gouraud_tmap
		dc.l	gtmap			; t_gouraud_env
		ELSE
		dc.l	0
		dc.l	0
		ENDC
;-
		IFD	m_phong_tmap
		dc.l	ptmap
		ELSE
		dc.l	0
		ENDC
;-
		IFD	m_bump
		dc.l	bumpmap
		ELSE
		dc.l	0
		ENDC
;-
		IFD	m_tbump
		dc.l	tbumpmap
		ELSE
		dc.l	0
		ENDC
;-
		dc.l	0			; t_flare
		dc.l	0			; t_bboard
;-
		IFND	precision
		dc.l	tmap030			; t_texmap030
		ELSE
		dc.l	0
		ENDC
;-
		IFND	precision
		dc.l	tmap030			; t_phong030
		ELSE
		dc.l	0
		ENDC
;-
	IFD	m_fog
fill_jt_e:	dcb.l	$10-(fill_jt_e-fill_jt)/4,0
;-
		IFD	m_bi_map
		dc.l	bimap
		ELSE
		dc.l	0
		ENDC
;-
		IFD	m_transparent
		dc.l	transmap		; t_transphong
		ELSE
		dc.l	0
		ENDC
;-
		dc.l	tfogmap			; t_phong
;-
		dc.l	tfogmap			; t_texmap
;-
		IFD	m_transparent
		dc.l	transmap		; t_transtexmap
		ELSE
		dc.l	0
		ENDC
;-
		IFD	m_bi_map
		dc.l	bimap
		ELSE
		dc.l	0
		ENDC
;-
		IFD	m_gouraud_tmap
		dc.l	gtmap			; t_gouraud_tmap
		dc.l	gtmap			; t_gouraud_env
		ELSE
		dc.l	0
		dc.l	0
		ENDC
;-
		IFD	m_phong_tmap
		dc.l	ptmap
		ELSE
		dc.l	0
		ENDC
;-
		IFD	m_bump
		dc.l	bumpmap
		ELSE
		dc.l	0
		ENDC
;-
		IFD	m_tbump
		dc.l	tbumpmap
		ELSE
		dc.l	0
		ENDC
;-
		dc.l	0			; t_flare
		dc.l	0			; t_bboard
;-
		IFND	precision
		dc.l	tfogmap			; t_texmap030
		ELSE
		dc.l	0
		ENDC
;-
		IFND	precision
		dc.l	tfogmap			; t_phong030
		ELSE
		dc.l	0
		ENDC
;-
	ENDC

;---------------------------------------------

fill_c_jt:	IFD	m_bi_map
		dc.l	bimapc
		ELSE
		dc.l	0
		ENDC
;-
		IFD	m_transparent
		dc.l	transmapc
		ELSE
		dc.l	0
		ENDC
;-
		dc.l	tmapc			; t_phong
;-
		dc.l	tmapc			; t_texmap
;-
		IFD	m_transparent
		dc.l	transmapc
		ELSE
		dc.l	0
		ENDC
;-
		IFD	m_bi_map
		dc.l	bimapc
		ELSE
		dc.l	0
		ENDC
;-
		IFD	m_gouraud_tmap
		dc.l	gtmapc			; t_gouraud_tmap
		dc.l	gtmapc			; t_gouraud_env
		ELSE
		dc.l	0
		dc.l	0
		ENDC
;-
		IFD	m_phong_tmap
		dc.l	ptmapc
		ELSE
		dc.l	0
		ENDC
;-
		IFD	m_bump
		dc.l	bumpmapc
		ELSE
		dc.l	0
		ENDC
;-
		IFD	m_tbump
		dc.l	tbumpmapc
		ELSE
		dc.l	0
		ENDC
;-
		dc.l	0			; t_flare
		dc.l	0			; t_bboard
;-
		IFND	precision
		dc.l	tmapc030		; t_texmap030
		ELSE
		dc.l	0
		ENDC
;-
		IFND	precision
		dc.l	tmapc030		; t_phong030
		ELSE
		dc.l	0
		ENDC
;-
	IFD	m_fog
		dcb.l	$10-(fill_jt_e-fill_jt)/4,0
;-
		IFD	m_bi_map
		dc.l	bimapc
		ELSE
		dc.l	0
		ENDC
;-
		IFD	m_transparent
		dc.l	transmapc
		ELSE
		dc.l	0
		ENDC
;-
		dc.l	tfogmapc		; t_phong
;-
		dc.l	tfogmapc		; t_texmap
;-
		IFD	m_transparent
		dc.l	transmapc
		ELSE
		dc.l	0
		ENDC
;-
		IFD	m_bi_map
		dc.l	bimapc
		ELSE
		dc.l	0
		ENDC
;-
		IFD	m_gouraud_tmap
		dc.l	gtmapc			; t_gouraud_tmap
		dc.l	gtmapc			; t_gouraud_env
		ELSE
		dc.l	0
		dc.l	0
		ENDC
;-
		IFD	m_phong_tmap
		dc.l	ptmapc
		ELSE
		dc.l	0
		ENDC
;-
		IFD	m_bump
		dc.l	bumpmapc
		ELSE
		dc.l	0
		ENDC
;-
		IFD	m_tbump
		dc.l	tbumpmapc
		ELSE
		dc.l	0
		ENDC
;-
		dc.l	0			; t_flare
		dc.l	0			; t_bboard
;-
		IFND	precision
		dc.l	tfogmapc		; t_texmap030
		ELSE
		dc.l	0
		ENDC
;-
		IFND	precision
		dc.l	tfogmapc		; t_phong030
		ELSE
		dc.l	0
		ENDC
;-
	ENDC

;----------------------------

ps16_g_p:	dc.l	0		; Ptr auf facetype des aktuellen
					; g_liste elements

; ohne clipping
; links 2 linien	; rechts 2 linien	; oben flach	; unten flach
; 0,0			; 1,0			; -7,0		; 1,0
;
; mit clipping
; 0,0			; 1,0			; -8,0 (li)	; 1,0
;			;			; -8,-1 (re)	;
;
ps16_stat:	dc.l	0,0		;

ps16_helfi:	dc.l	0
ps16_regs:	dc.l	0,0,0

lix_rex_mx_my:	dc.l	0,0,0,0, 0,0
addvalues:	dc.l	0,0,0,0, 0,0
llength:	dc.l	0

lix_rex_mx_my2:	dc.l	0,0,0,0, 0,0
addvalues2:	dc.l	0,0,0,0, 0,0
llength2:	dc.l	0

	IFD	m_fog
fog_dist:	dc.l	0
	ENDC

	IFD	em_clip
clip_1st:	dc.l	0
clip_2nd:	dc.l	0
clip_sum:	dc.l	0
clip_upli:	dc.l	0
clip_upre:	dc.l	0
clip_stat:	dc.l	0		; 1 = re laenger
		ENDC

;---

ps_do_lt:
	IFND	precision
	move.l	ps16_g_p(pc),a6
	move.l	#-1,llength2
	cmp.l	#t_em_lim,(a6)
	bge.s	.edge2mem

.noedge2mem:
	lea	lix_rex_mx_my(pc),a6
	movem.l	d0-d1/d3/d5,(a6)
	lea	addvalues(pc),a6
	move.l	a2,(a6)+
	move.l	a3,(a6)+
	move.l	a1,(a6)+
	move.l	a5,(a6)

	exg	d0,a2
	exg	d1,a3
	exg	d3,a1
	exg	d5,a5

	muls.l	d7,d0
	muls.l	d7,d1
	muls.l	d7,d3
	muls.l	d7,d5

	add.l	d0,a2
	add.l	d1,a3
	add.l	d3,a1
	add.l	d5,a5

	exg	d0,a2
	exg	d1,a3
	exg	d3,a1
	exg	d5,a5

	exg	a4,d2
	muls.l	d7,d6
	muls.l	d7,d2

	lea	llength(pc),a6
	subq.l	#1,d7

	add.l	d2,a4			; a4 re x map add
	move.l	d7,(a6)
	add.l	d6,d4			; d6 re y map add
	lea	addvalues(pc),a6
	exg	d2,a4


	move.l	(a6)+,a2
	move.l	(a6)+,a3
	move.l	(a6)+,a1
	move.l	(a6),a5


	rts

;---

.edge2mem:
	IFD	m_fog
	cmp.l	#t_fog,(a6)
	bge.s	.noedge2mem
	ENDC

	exg	a4,d2
	muls.l	d7,d6
	muls.l	d7,d2

	subq.l	#1,d7
	move.l	ps16_ltt_p(pc),a6
	move.l	d7,llength

.do_lt2:move.l	d0,(a6)+		; d0 li x
	add.l	a2,d0			; a2 li x add
	move.l	d1,(a6)+		; d1 re x
	add.l	a3,d1			; a3 re x add
	move.l	d3,(a6)+		; d3 li x map
	add.l	a1,d3			; a1 li x map add
	move.l	d5,(a6)+		; d5 li y map
	add.l	a5,d5			; a5 li y map add

	dbf	d7,.do_lt2

	add.l	d2,a4			; a4 re x map add
	add.l	d6,d4			; d6 re y map add
	exg	d2,a4
	rts

	ELSE

		subq.l	#1,d7
		move.l	ps16_ltt_p(pc),a6
		move.l	d7,llength

.do_lt2:	move.l	d0,(a6)+		; d0 li x
		add.l	a2,d0			; a2 li x add
		move.l	d1,(a6)+		; d1 re x
		add.l	a3,d1			; a3 re x add
		move.l	d3,(a6)+		; d3 li x map
		add.l	a1,d3			; a1 li x map add
		move.l	d5,(a6)+		; d5 li y map
		add.l	a5,d5			; a5 li y map add

		move.l	d2,(a6)+
		add.l	a4,d2
		move.l	d4,(a6)+
		add.l	d6,d4

		dbf	d7,.do_lt2
		rts
	ENDC

;---------

ps_do_lt2:
	IFND	precision
	move.l	ps16_g_p(pc),a4
	cmp.l	#t_em_lim,(a4)
	bge.s	.edge2mem

.noedge2mem:
	lea	lix_rex_mx_my2(pc),a6
	movem.l	d0-d1/d3/d5,(a6)
	lea	addvalues2(pc),a6
	subq.l	#1,d7
	move.l	a2,(a6)+
	move.l	a3,(a6)+
	move.l	a1,(a6)+
	move.l	a5,(a6)

	move.l	d7,llength2
	rts

;---

.edge2mem:
	IFD	m_fog
	cmp.l	#t_fog,(a4)
	bge.s	.noedge2mem
	ENDC

	add.l	d7,llength
	move.l	d7,llength2
	subq.l	#1,d7

.do_lt2:move.l	d0,(a6)+		; d0 li x
	add.l	a2,d0			; a2 li x add
	move.l	d1,(a6)+		; d1 re x
	add.l	a3,d1			; a3 re x add
	move.l	d3,(a6)+		; d3 li x map
	add.l	a1,d3			; a1 li x map add
	move.l	d5,(a6)+		; d5 li y map
	add.l	a5,d5			; a5 li y map add

	dbf	d7,.do_lt2
	rts

	ELSE

		add.l	d7,llength
		subq.l	#1,d7

.do_lt2:	move.l	d0,(a6)+		; d0 li x
		add.l	a2,d0			; a2 li x add
		move.l	d1,(a6)+		; d1 re x
		add.l	a3,d1			; a3 re x add
		move.l	d3,(a6)+		; d3 li x map
		add.l	a1,d3			; a1 li x map add
		move.l	d5,(a6)+		; d5 li y map
		add.l	a5,d5			; a5 li y map add

		move.l	d2,(a6)+
		add.l	a4,d2
		move.l	d4,(a6)+
		add.l	d6,d4

		dbf	d7,.do_lt2
		rts
	ENDC

;---

	IFND	precision
calc_const:
	movem.l	d1/d2/d4/a2,-(a7)
	lea	max_delta_x(pc),a2
	sub.l	d0,d1			; delta x
	sub.l	d3,d2			; Delta(re x map - li x map)
	clr	d1
	sub.l	d5,d4			; Delta(re y map - li y map)
	swap	d1
	asr	#subpixel,d1
	bne.s	.a
	moveq	#1,d1
.a:	move	d1,(a2)+
	divs.l	d1,d2
	divs.l	d1,d4

	move.l	d2,(a2)+		; 00XXxxxx
	move.l	d4,(a2)+		; 00YYyyyy

	swap	d2			; .xxxx|00xx.
	ror.l	#8,d4			; yy00|yy.yy
	move.l	d2,d1
	move	d4,d2
	move	d1,d4

	move.l	d2,(a2)+		; xxxxYYyy
	move.l	d4,(a2)			; yy0000XX
	movem.l	(a7)+,d1/d2/d4/a2
	rts

	cnop	0,4
;-- Don't change order
	dc	0			; Musz 0 sein!
max_delta_x:	dc.w	0		; Maximales DeltaX in dem 3-eck
t3_const_bf:
	dc.l	0,0
t3_const:
	dc.l	0,0			; /deltax konstant
t3_const_g:
	dc.l	0,0
t3_const_p:
	dc.l	0
	ENDC
;--

;------------------------------------------------------------------

g_range		=	(16-1)		; bits, wertebereich 2^g_range*2 (+/-)

	cnop	0,4
g_liste_p:	dc.l	0
g_flp:	dc.l	0			; Zeiger auf Flaechenpointerarray
g_flanz:dc.l	0			; Anzahl d. zu zeichnenden Flaechen
g_stack:dc.l	0			; Zwischspeicher fuer SP

divtab_p:	dc.l	divtab

;--------------------------------------------------------------------

;; Von der Struktur (sichtbarkeitswort, gefolgt von den 3 Verbindungen)
;; sind folgende Routinen abhaenging: 'sichtbarkeit', 'do_normal_z',
;; 'do_vertoff', 'lightpkts', 'phongpkts'
;
;objtab:		dcb.w	g_maxfl*(1+3),0	; Objecttabelle (sichtbar.w, 3vertices)
;					; sichtbar.w 0=unsichtbar
;					; 1=sichtbar+ausserhalb d. Screens
;					; -1=sichtbar&innerhalb d. Screens
;					; Die '1' werden fuer die lightsource
;					; benoetigt, waehrend nur die '-1'
;					; Flaechen gezeichnet werden muessen.
;
;flg_lp:	dcb.l	g_maxfl,0	; (sortierte) Pointer auf g_liste
;texture_p:	dcb.l	g_maxfl,0	; Pointer auf Texturen der Meshes
;koordxy:	dcb	maxpoints*2,0	; Punkte 2d projeziert
;koordxyz:	dcb	maxpoints*3,0	; Punkte 3d rotiert
;normal_zv:	dcb	maxpoints*3,0	; Normal'orts'vektor
;normal_st:	dcb	maxpoints,0	; Statusliste ob Vertex Normale hat
;vertex_st:	dcb	maxpoints,0	; Statusliste ob Vertex in BBox ist
;flcoloff:	dcb	g_maxfl*3,0	; Offsettabelle fuer pktcols
;objvert6:	dcb	g_maxfl*3,0	; Vertex Punktoffset*6
;tri2map:
;	dcb.l	g_maxfl*g_tri2map_element,0
					; 
;g_liste:				; Alle Flaechen werden entsprechend
;	dcb.l	g_maxfl*(1+12+3+6),0	; objtab eingetragen, aber nur die
;					; sichtbaren sind gueltig!

	IFD	m_tbump
g_element	=	(1+12+2+3+1+1)*4
	ELSE
	IFNE	m_phong_tmap_v|m_bump_v
g_element	=	(1+12+2+3+1)*4
	ELSE
	IFD	m_gouraud_tmap
g_element	=	(1+12+2+3)*4
	ELSE
g_element	=	(1+12+2)*4
	ENDC
	ENDC
	ENDC

;Ein Element der g_liste
;	dc.l	0			; Flaeche vollstaendig drinnen?
;
;	dc.w	160,00		; Pkt1	; Hoechster Punkt / flare xwidth,ywidth
;	dc.w	160,160			; Pkt3	; links / flare x1,y1
;	dc.w	0,0			; Mappkt1 / flare x2,y2
;	dc.w	0,255			; Mappkt3
;
;	dc.w	160,0			; Pkt1
;	dc.w	240,80			; Pkt2	; rechts
;	dc.w	0,0			; Mappkt1
;	dc.w	255,255			; Mappkt2
;
;	dc.w	240,80			; Pkt2
;	dc.w	160,160			; Pkt3
;	dc.w	255,255			; Mappkt2
;	dc.w	0,255			; Mappkt3
;
;	dc.l	facetype
;	dc.l	texture/phong
;
;	dc	x1,y1			; Bumppkt1 oder Z-Pkt1
;	dc	x2,y2			; Bumppkt2 oder Z-Pkt2
;	dc	x3,y3			; Bumppkt3 oder Z-Pkt3
;
;	dc.l	phong/bump
; (	dc.l	texture )		; bei m_tbump

g_tri2map_element	=	3*4

;Ein Element der tri2map liste
;
;	dc	x1,y1			; korrespondierende Punkte in der Map
;	dc	x2,y2
;	dc	x3,y3

;--------------------------------------------------------------------------

rotmove_obj_n:
	move.l	d0,-(a7)
	bsr.s	rotmove_obj

	lea	st_odl(pc),a0
	lea	objangle(pc),a5
	add.l	(a7)+,a0
	move	(a0)+,d7
	move.l	(a0)+,d0
	bra	rot_p_n

;----------------------------

rotmove_obj:
	move.l	d0,-(a7)
	move.l	a2,-(a7)
	move.l	a4,-(a7)

	lea	objobjpos(pc),a4
	addq.l	#2,a1
	move.l	(a3),d0
	bsr	do_spline

	move.l	(a7)+,a3
	move.l	(a7)+,a1
	lea	objangle(pc),a4
	move.l	a1,d0
	beq.s	.a
	addq.l	#2,a1
	move.l	(a3),d0
	bsr	do_spline
	and.l	#$1ffe1ffe,(a4)+
	and	#$1ffe,(a4)
	bra.s	.w
.a:	clr.l	(a4)+
	clr	(a4)
.w:

	lea	st_odl(pc),a0
	lea	objangle(pc),a5
	add.l	(a7)+,a0
	move	(a0)+,d7
	move.l	(a0)+,d0
	bra	rot_p_k

objangle:	dc	0,0,0

;------------------------------------

obj_inits:
	dc.l	obj144,obj21,obj1002,obj1003,0
obj_inits2:
	dc.l	obj1000,obj1001,obj14,0
obj_inits3:
	dc.l	obj1004,0
;obj_inits4:
;	dc.l	obj17,0
obj_inits5:
	dc.l	obj20,obj22,obj43,obj1005,obj1006,obj23,obj43,obj43,obj50,obj51,0
obj_inits6:
	dc.l	obj24,obj24_2,obj25,obj1024,0
obj_inits7:
	dc.l	obj1010,obj1011,obj1011,obj1011,obj1011,0
obj_inits8:
	dc.l	obj1018,obj1011,obj1011,obj1011,0
obj_inits9:
	dc.l	obj1028,obj1011,obj1011,obj1011,obj1011,obj1011,0
obj_inits10:
	dc.l	obj1444,obj21,obj1011,0
obj_inits11:
	dc.l	obj42,obj50,obj51,obj50,obj51,obj50,obj51,obj50,obj51,obj26,0

ncalc_pal:
	jmp	calc_pal

;------------------------------------------

obj1010m:
	dc	0,	0,0,-500*4
	dc	0,	0,0,-500*4
	dc	4000,	0,0,-500*4
	dc	8000,	0,0,-500*4
	dc	12000,	0,0,-500*4
	dc	-1

;-------------

o1010_prep_txt:
	move.l	dummymap2_p(pc),a2
	lea	cscrs(pc),a0
	move.l	a2,(a0)
	bsr.w	clr_64k

	move.l	dummymap1_p(pc),a2
	lea	cscrs+4(pc),a0
	move.l	a2,(a0)
	bsr.w	clr_64k
;-
	lea	addtxt(pc),a0
	moveq	#2-1,d0
	move	#96-1,(a0)

.h1	move.l	d0,-(a7)

	move	#(30*0+10)*256+10,a0
	lea	txt1(pc),a1
	bsr.s	ptd3

	move	#(30*1+10)*256+10,a0
	lea	txt2(pc),a1
	bsr.s	ptd3

	move	#(30*2+10)*256+10,a0
	lea	txt3(pc),a1
	bsr.s	ptd3

	move	#(30*3+10)*256+10,a0
	lea	txt4(pc),a1
	bsr.s	ptd3

	move.l	#(30*4+10)*256+10,a0
	lea	txt1000(pc),a1
	bsr.s	ptd3

	bsr	smooth
	lea	cscrs(pc),a0
	move.l	(a0),d0
	move.l	4(a0),(a0)
	move.l	d0,4(a0)
	move.l	(a7)+,d0
	dbf	d0,.h1

	rts

ptd3:	add.l	cscrs+4(pc),a0
	bra	printtxt

;----------------------

xb	=	512

init_2dbump:
	move.l	dummymap0_p(pc),a6
	move.l	origcircle_p,a0
	moveq	#0,d0
	move	#256-1,d5
.sch4	move	#256-1,d7
.sch2	move.b	(a0)+,d0
	sub	#128,d0
	bpl.s	.a
	moveq	#0,d0
.a	move.b	d0,(a6)+
	move.b	d0,(a6)+
	dbf	d7,.sch2
	lea	-512(a6),a5
	moveq	#512/4-1,d6
.sch3	move.l	(a5)+,(a6)+
	dbf	d6,.sch3
	dbf	d5,.sch4
;-
	move.l	map2d_p(pc),a0
	move.l	marble_p,a1
;	move	#yysize-1,d7
	move	#224-1,d7

.ar3	move	#256-1,d6
.ar	move.b	(a1)+,d0
	add.b	d0,d0
	add.b	d0,d0
	move.b	d0,256(a0)
	move.b	d0,(a0)+
	dbf	d6,.ar
	lea	256(a0),a0
	dbf	d7,.ar3
;-
	bra.s	bump2d2

;---------
map2d_p:
	dc.l	map2d
;---

bump2d2:
	move.l	map2d_p(pc),a0
;	lea	bumptab,a1
	move.l	dummymap3_p(pc),a1
;	move.l	#xb*yysize,d7
	move.l	#xb*224,d7
	moveq	#$00,d5
	moveq	#$00,d6
.b2d_ag:
	moveq	#$00,d0
	moveq	#$00,d1
	moveq	#$00,d2
	moveq	#$00,d3
	moveq	#$00,d4
	move.b	-1(a0),d0
	move.b	-(xb+1)(a0),d1
	move.b	-(xb)(a0),d2
	add.w	d2,d0
	add.w	d1,d0
	move.b	(xb-1)(a0),d1
	move.b	xb(a0),d2
	move.b	(xb+1)(a0),d3
	add.w	d3,d1
	add.w	d2,d1
	move.b	-(xb-1)(a0),d2
	move.b	1(a0),d4
	add.w	d4,d2
	add.w	d3,d2
	move.w	d0,d3
	sub.w	d2,d0
	sub.w	d1,d3
	add.w	d5,d0
	add.w	d6,d3
	ext.l	d0
	ext.l	d3
	sub.l	d3,d0
	asl.l	#8,d3
	add.l	d0,d3
	move.l	d3,(a1)+
	addq.w	#1,a0
	addq.w	#1,d5
	cmp.w	#$00ff,d5
	blt.b	.b2d_s
	moveq	#$00,d5
	addq.w	#1,d6
.b2d_s:	subq.l	#1,d7
	bne.s	.b2d_ag
	rts	

;----------------------

anim1010:
	lea	dummymap0+(xb*(xb-yysize)/2+(xb-xsize)/2),a0

	move	c_xy(pc),d0
	move	c_xy+2(pc),d1
	add	d0,a0
	muls	#xb,d1
	move.l	ps16_sbuf(pc),a1
	add.l	d1,a0
	
	add	#xsize,a1
	move	ysize_scr(pc),d6
	move.l	dummymap3_p(pc),a2
;	lea	xb*4/2(a2),a2

	move	c_xy+2(pc),d1
	neg	d1
	asr	#3,d1
	add	#16,d1
	mulu	#xb*4,d1
	add.l	d1,a2

	and	#$fffc,d0
	sub	d0,a2

	lea	((xb-xsize)*4).w,a4
	lea	xb*4(a2),a2
	subq	#3,d6
	tst	half_scr(pc)
	beq.s	.b
	lea	xb*4(a4),a4
.b:	move	#xsize/4-1,d7
.a:	movem.l	(a2)+,d0-d3
	move.b	$00(a0,d0.l),(a1)+
	move.b	$00(a0,d1.l),(a1)+
	move.b	$00(a0,d2.l),(a1)+
	move.b	$00(a0,d3.l),(a1)+
	dbf	d7,.a
	add.l	a4,a2
	dbf	d6,.b

;---
	move.l	ps16_sbuf(pc),a0
	move	#xsize/4-1,d7
	move	ysize_scr(pc),d6
.hc	clr.l	(a0)+
	dbf	d7,.hc

	subq	#2+1,d6
.hc2	clr.b	(a0)
	clr.b	xsize-1(a0)
	lea	xsize(a0),a0
	dbf	d6,.hc2

	move	#xsize/4-1,d7
.hc3:	clr.l	(a0)+
	dbf	d7,.hc3
;---
	move.l	sinp(pc),a0
	lea	c_offxy(pc),a3

	move	c_radxy(pc),d2
	move	(a3),d0
	move	c_radxy+2(pc),d3
	move	2(a3),d1

	muls	(a0,d0.w*2),d2
	muls	(a0,d1.w*2),d3
	swap	d2
	swap	d3

	lea	c_xy(pc),a0
	move	d2,(a0)+
	move	d3,(a0)+
;---
	moveq	#5-1,d7
	bra	ak_101

;---

c_radxy:	dc	160,127
c_offxy:	dc	0,$800
c_xy:	dc	0,0

;----

adj_anim1010:
	lea	slide201(pc),a1
	moveq	#10-1,d7
	bsr	adj_okeys

	lea	c_offxy(pc),a3

	add	#28,(a3)
	add	#42/2,2(a3)
	and	#$fff,(a3)
	and	#$fff,2(a3)

	bra.w	fade2_n_fro

;---

fade2_n_fro:
	tst	.dir(pc)
	bne.s	.go

	lea	fade_step(pc),a0
	subq	#1,(a0)
	bmi.s	.q2
	move.l	clistptr(pc),a0
	lea	cl_cols-clist(a0),a0
	bra	fade_do
.q2:	lea	.dir(pc),a0
	move	#1,(a0)

	move	fade_amount(pc),d7
	lea	fade_add(pc),a0
	subq	#1,d7
	lea	fade_step(pc),a6
.n	neg.l	(a0)+
	neg.l	(a0)+
	neg.l	(a0)+
	dbf	d7,.n
	move	.step(pc),(a6)
.q3:	rts

.go:	lea	.w144(pc),a0
	subq	#1,(a0)
	bpl.s	.q3

	lea	fade_step(pc),a0
	subq	#1,(a0)
	bmi.s	.q3
	move.l	clistptr(pc),a0
	lea	cl_cols-clist(a0),a0
	bra	fade_do

;--
.dir	dc	0
.w144	dc	13*50
.step:	dc	150

;----------------------

o1010x	=	150*4/2
o1010y	=	25*4/2

obj1010:
	bsr	o1010_prep_txt
;----
	bsr	init_2dbump
;----
	lea	pointsp201(pc),a0
	lea	o1010_1m(pc),a1
	move.l	a1,(a0)
	lea	o1010_1r(pc),a1
	move.l	a1,14*1(a0)

	lea	o1010_2m(pc),a1
	move.l	a1,14*2(a0)
	lea	o1010_2r(pc),a1
	move.l	a1,14*3(a0)

	lea	o1010_3m(pc),a1
	move.l	a1,14*4(a0)
	lea	o1010_3r(pc),a1
	move.l	a1,14*5(a0)

	lea	o1010_4m(pc),a1
	move.l	a1,14*6(a0)
	lea	o1010_4r(pc),a1
	move.l	a1,14*7(a0)

	lea	o1010_5m(pc),a1
	move.l	a1,14*8(a0)
	lea	o1010_5r(pc),a1
	move.l	a1,14*9(a0)

	lea	slide201(pc),a1
	moveq	#10-1,d7
	bsr	init_okeys

;----
	lea	fl_4_sort_st(pc),a0
	clr	(a0)
	lea	clear_st(pc),a0
	move	#1,(a0)

	lea	bbox_st(pc),a0
	clr	(a0)

	lea	t1_m1(pc),a0
	lea	obj1010m(pc),a1
	move.l	a1,(a0)

	lea	t1_m2(pc),a0
	clr.l	(a0)

	lea	t1_m3(pc),a0
	clr.l	(a0)

	lea	anim_obj_rout_p(pc),a0
	lea	anim1010(pc),a1
	move.l	a1,(a0)
	lea	anim_obj_adj_p(pc),a0
	lea	adj_anim1010(pc),a1
	move.l	a1,(a0)

;---
	moveq	#0,d0
	move.l	#0+127,d1
	moveq	#0,d5
	lea	(0+127).w,a6
;	moveq	#0,d6
	move.l	#128,d6
	move.l	d1,d2
	bsr	trans_limes2

	move.l	#128,d0
	move.l	#128+127,d1
	moveq	#0,d5
	lea	(0+127).w,a6
	move.l	#128,d6
	move.l	d1,d2
	bsr	trans_limes2

	move.l	addtab_p(pc),a0
	moveq	#0,d0
	move	#256-1,d7
.l	move.b	d0,(a0)
	lea	256(a0),a0
	addq	#1,d0
	dbf	d7,.l

;---
	lea	graulind(pc),a0
;	lea	gruengrau(pc),a0
	lea	colsl(pc),a1
	moveq	#10,d4
	move.l	#127+1,d5
	bsr	ncalc_pal

	lea	rostgrau(pc),a0
	lea	colsl+128*4(pc),a1
	moveq	#16,d4
	move.l	#127+1,d5
	bsr	ncalc_pal

;---
	lea	obj2cols2(pc),a0
	move	#256-1,d7
.chc	clr.l	(a0)+
	dbf	d7,.chc

	lea	fade_amount(pc),a6
	move	#256,(a6)
	lea	fade_step(pc),a6
	move	#100,(a6)

	lea	obj2cols2(pc),a0
	lea	colsl(pc),a1
	bsr	fade_init

	lea	fade2_n_fro\.dir(pc),a0
	clr	(a0)+
	move	#11*50,(a0)+
	move	#100,(a0)
;---
	lea	t1_struct(pc),a0
	move	#4-1,(a0)+
	move	#2-1,(a0)

	move.l	t1_pkt_p(pc),a0
	move	#o1010x,d0
	move	#o1010y,d1
	moveq	#0,d2
	moveq	#0,d7
	bsr.w	o_tri

	move.l	t1_tab_p(pc),a0
	move.l	a0,a1
	move.l	#$10004,(a0)+
	move.l	#$30001,(a0)+
	move.l	#$30002,(a0)+

	move.l	t1_tl_p(pc),a1
	lea	t1_tl(pc),a0
	move.l	a1,(a0)

	move	#t_transtexmap,a0
	move.l	dummymap1_p(pc),a6

	moveq	#10,d2
	moveq	#34,d3
	lea	156.w,a2
	lea	8.w,a3
	bra	do_143_132

;-----------

o1011_xp:	dc.l	o1011_x

o1011_x:
		dc	112*4/2,25*4/2
		dc	10,64,120,39

		dc	127*4/2,25*4/2
		dc	10,255-163,138,255-187

		dc	94*4/2,25*4/2
		dc	10,255-132,102,255-155

		dc	88*4/2,25*4/2
		dc	14,255-101,103,255-128
;- obj1018
		dc	200*4/2,25*4/2
		dc	11,255-192,209,255-216

		dc	93*4/2,25*4/2
		dc	11,255-164,103,255-186

		dc	88*4/2,25*4/2
		dc	14,255-101,103,255-128
;- obj1028
		dc	72*4/2,25*4/2
		dc	15,255-192,84,255-217

		dc	163*4/2,25*4/2
		dc	12,255-162,174,255-187

		dc	98*4/2,25*4/2
		dc	17,255-132,113,255-157

		dc	88*4/2,25*4/2
		dc	14,255-101,103,255-128

		dc	76*4/2,25*4/2
		dc	12,255-73,85,255-96
;- obj1444
		dc	122*3/2,25*3/2
		dc	11,255-224,132,255-246


obj1011:
	lea	t1_struct(pc),a0
	move	#4-1,(a0)+
	move	#2-1,(a0)

	move.l	t1_pkt_p(pc),a0
;	move	#o1010x,d0
;	move	#o1010y,d1
	lea	o1011_xp(pc),a2
	move.l	(a2),a1
	move	(a1)+,d0
	move	(a1)+,d1
	move.l	a1,(a2)
	moveq	#0,d2
	moveq	#0,d7
	bsr.w	o_tri

	move.l	t1_tab_p(pc),a0
	move.l	a0,a1
	move.l	#$10004,(a0)+
	move.l	#$30001,(a0)+
	move.l	#$30002,(a0)+

	move.l	t1_tl_p(pc),a1
	lea	t1_tl(pc),a0
	move.l	a1,(a0)

	move	#t_transtexmap,a0
	move.l	dummymap1_p(pc),a6

	lea	o1011_xp(pc),a4
	move.l	(a4),a5
	move	(a5)+,d2
	move	(a5)+,d3
	move	(a5)+,a2
	move	(a5)+,a3
	move.l	a5,(a4)

;	moveq	#10,d2
;	moveq	#34,d3
;	lea	156.w,a2
;	lea	8.w,a3
	bra	do_143_132

;------------------------------------------

o1028_prep_txt:
	move.l	dummymap2_p(pc),a2
	lea	cscrs(pc),a0
	move.l	a2,(a0)
	bsr.w	clr_64k

	move.l	dummymap1_p(pc),a2
	lea	cscrs+4(pc),a0
	move.l	a2,(a0)
	bsr.w	clr_64k
;-
	lea	addtxt(pc),a0
	moveq	#2-1,d0
	move	#63-1,(a0)

.h1	move.l	d0,-(a7)

	move	#(30*0+10)*256+10,a0
	lea	txt7(pc),a1
	bsr.s	.ptd3

	move	#(30*1+10)*256+10,a0
	lea	txt8(pc),a1
	bsr.s	.ptd3

	move	#(30*2+10)*256+10,a0
	lea	txt9(pc),a1
	bsr.s	.ptd3

	move.l	#(30*4+10)*256+10,a0
	lea	txt1000(pc),a1
	bsr.s	.ptd3

	move.l	#(30*3+10)*256+10,a0
	lea	txt10(pc),a1
	bsr.s	.ptd3

	move.l	#(30*5+10)*256+10,a0
	lea	txt11(pc),a1
	bsr.s	.ptd3

	bsr	smooth
	lea	cscrs(pc),a0
	move.l	(a0),d0
	move.l	4(a0),(a0)
	move.l	d0,4(a0)
	move.l	(a7)+,d0
	dbf	d0,.h1

	rts

.ptd3:	bra	ptd3

;----------------------------------

o1018_prep_txt:
	move.l	dummymap2_p(pc),a2
	lea	cscrs(pc),a0
	move.l	a2,(a0)
	bsr.w	clr_64k

	move.l	dummymap1_p(pc),a2
	lea	cscrs+4(pc),a0
	move.l	a2,(a0)
	bsr.w	clr_64k
;-
	lea	addtxt(pc),a0
	moveq	#2-1,d0
	move	#127-1,(a0)

.h1	move.l	d0,-(a7)

	move	#(30*0+10)*256+10,a0
	lea	txt0(pc),a1
	bsr.s	.ptd3

	move	#(30*1+10)*256+10,a0
	lea	txt5(pc),a1
	bsr.s	.ptd3

	move	#(30*2+10)*256+10,a0
	lea	txt6(pc),a1
	bsr.s	.ptd3

	move.l	#(30*4+10)*256+10,a0
	lea	txt1000(pc),a1
	bsr.s	.ptd3

	bsr	smooth
	lea	cscrs(pc),a0
	move.l	(a0),d0
	move.l	4(a0),(a0)
	move.l	d0,4(a0)
	move.l	(a7)+,d0
	dbf	d0,.h1

	rts

.ptd3:	bra	ptd3

;--------------

anim1018:
	jsr	op_fetch
;---
	moveq	#4-1,d7

ak_101:	lea	pointsp201(pc),a5
	lea	slideoff201(pc),a3
	lea	pointsp202(pc),a6
	lea	slideoff202(pc),a4
	moveq	#12*0,d0

.hq	movem.l	d0/d7/a3-a6,-(a7)
	move.l	(a5),a1
	move.l	(a6),a2
	bsr.w	rotmove_obj
	movem.l	(a7)+,d0/d7/a3-a6
	moveq	#14*2,d1
	add	#12,d0
	add.l	d1,a3
	add.l	d1,a4
	add.l	d1,a5
	add.l	d1,a6
	dbf	d7,.hq

	rts

;---

adj_anim1018:
		add.l	#op_RotoSpeed,op_Rot
		cmp.l	#[256*256],op_Rot
		bne.s	.NotRotMax
		clr.l	op_Rot

.NotRotMax:	addq.l	#op_ZoomSpeed,op_Zoom
		cmp.l	#[256*256],op_Zoom
		bne.s	.NotZoomMax
		clr.l	op_Zoom

.NotZoomMax:

	lea	slide201(pc),a1
	moveq	#8-1,d7
	bra	adj_okeys

;--------------

obj1018:
	move.l	dummymap5_p(pc),a2
	bsr.w	clr_64k
;----
	bsr	o1018_prep_txt
;----
	jsr	do_optunnel
;----
	lea	pointsp201(pc),a0
	lea	o1018_1m(pc),a1
	move.l	a1,(a0)
	lea	o1018_1r(pc),a1
	move.l	a1,14*1(a0)

	lea	o1018_2m(pc),a1
	move.l	a1,14*2(a0)
	lea	o1018_2r(pc),a1
	move.l	a1,14*3(a0)

	lea	o1018_3m(pc),a1
	move.l	a1,14*4(a0)
	lea	o1018_3r(pc),a1
	move.l	a1,14*5(a0)

	lea	o1018_4m(pc),a1
	move.l	a1,14*6(a0)
	lea	o1018_4r(pc),a1
	move.l	a1,14*7(a0)

	lea	slide201(pc),a1
	moveq	#8-1,d7
	bsr	init_okeys
;----

	lea	fl_4_sort_st(pc),a0
	clr	(a0)
	lea	clear_st(pc),a0
	move	#1,(a0)

	lea	bbox_st(pc),a0
	clr	(a0)

	lea	t1_m1(pc),a0
	lea	obj1010m(pc),a1
	move.l	a1,(a0)

	lea	t1_m2(pc),a0
	clr.l	(a0)

	lea	t1_m3(pc),a0
	clr.l	(a0)

	lea	anim_obj_rout_p(pc),a0
	lea	anim1018(pc),a1
	move.l	a1,(a0)
	lea	anim_obj_adj_p(pc),a0
	lea	adj_anim1018(pc),a1
	move.l	a1,(a0)
;---
	lea	gruengrau(pc),a0
	lea	obj2cols2(pc),a1
	moveq	#14,d4
	move.l	#127+1,d5
	bsr	ncalc_pal

;-
	moveq	#0,d0
	move.l	#0+127,d1
	moveq	#0,d5
	lea	(0+127).w,a6
	moveq	#0,d6
	move.l	d1,d2
	bsr	trans_limes2

	move.l	addtab_p(pc),a0
	move	#256-1,d7
	moveq	#0,d0
.el	move.b	d0,(a0)
	lea	256(a0),a0
	addq.l	#1,d0
	dbf	d7,.el

;---
	lea	t1_struct(pc),a0
	move	#4-1,(a0)+
	move	#2-1,(a0)

	move.l	t1_pkt_p(pc),a0
	move	#128*4/2,d0
	move	#25*4/2,d1
	moveq	#0,d2
	moveq	#0,d7
	bsr.w	o_tri

	move.l	t1_tab_p(pc),a0
	move.l	a0,a1
	move.l	#$10004,(a0)+
	move.l	#$30001,(a0)+
	move.l	#$30002,(a0)+

	move.l	t1_tl_p(pc),a1
	lea	t1_tl(pc),a0
	move.l	a1,(a0)

	move	#t_transtexmap,a0
	move.l	dummymap1_p(pc),a6

	moveq	#11,d2
	moveq	#256-222,d3
	lea	137.w,a2
	lea	(256-247).w,a3
	bra	do_143_132

;--------------

anim1028:	move.l	#Cos,a0
		move.l	#Texture,a1
		move.l	#StretchBuffer,a2
		move.w	#256-1,d7
		move.w	DeformSpeed(pc),d0
.v:		move.w	#179-1,d6
		move.w	(a0,d0.w),d1
		add.w	#32,d1
.h:		move.b	(a1,d1.w),d2
		move.b	d2,(a2)+		;kan måske tiles
		addq.l	#1,d1
		dbra	d6,.h
		add.l	#256,a1
		add.l	#256-179,a2
		add.w	#32,d0
		and.w	#2046,d0
		dbra	d7,.v


		move.l	#StretchBuffer,a0
		jsr	op_fetch2

;---
	moveq	#6-1,d7
	bra	ak_101


DeformSpeed:	dc.w	0

;--------

adj_anim1028:	lea	deformspeed(pc),a0
		add.w	#20,(a0)
		and.w	#2046,(a0)

	lea	.cnt(pc),a0
	subq	#1,(a0)
	bpl.s	.w
	bsr	fade2_n_fro
.w

	lea	slide201(pc),a1
	moveq	#12-1,d7
	bra	adj_okeys

.cnt	dc	5*50+25

;--------

obj1028:
	bsr	o1028_prep_txt
;----
	lea	Cos,a0
	move	#31*2,d1
	jsr	ts_sc

	lea	marble_p,a0
	move.l	(a0),-(a7)
	move.l	dummymap5_p(pc),a1
	move.l	a1,(a0)
	move.l	cloud64_p,a0
	moveq	#-1,d7
.hk	move.b	(a0)+,d0
	cmp.b	#31,d0
	bgt.s	.hk2
	eor.b	#$1f,d0
.hk2	move.b	d0,(a1)+
	dbf	d7,.hk

	clr	op_perspective
	move.l	#1,op_tx
	move.l	#1,op_tz
	clr	op_dx
	move	#95,op_dy
	jsr	do_optunnel

	lea	marble_p,a0
	move.l	(a7)+,(a0)
;----
	lea	pointsp201(pc),a0
	lea	o1028_1m(pc),a1
	move.l	a1,(a0)
	lea	o1028_1r(pc),a1
	move.l	a1,14*1(a0)

	lea	o1028_2m(pc),a1
	move.l	a1,14*2(a0)
	lea	o1028_2r(pc),a1
	move.l	a1,14*3(a0)

	lea	o1028_3m(pc),a1
	move.l	a1,14*4(a0)
	lea	o1028_3r(pc),a1
	move.l	a1,14*5(a0)

	lea	o1028_4m(pc),a1
	move.l	a1,14*6(a0)
	lea	o1028_4r(pc),a1
	move.l	a1,14*7(a0)

	lea	o1028_5m(pc),a1
	move.l	a1,14*8(a0)
	lea	o1028_5r(pc),a1
	move.l	a1,14*9(a0)

	lea	o1028_6m(pc),a1
	move.l	a1,14*10(a0)
	lea	o1028_6r(pc),a1
	move.l	a1,14*11(a0)

	lea	slide201(pc),a1
	moveq	#12-1,d7
	bsr	init_okeys
;----

	lea	fl_4_sort_st(pc),a0
	clr	(a0)
	lea	clear_st(pc),a0
	move	#1,(a0)

	lea	bbox_st(pc),a0
	clr	(a0)

	lea	t1_m1(pc),a0
	lea	obj1010m(pc),a1
	move.l	a1,(a0)

	lea	t1_m2(pc),a0
	clr.l	(a0)

	lea	t1_m3(pc),a0
	clr.l	(a0)

	lea	anim_obj_rout_p(pc),a0
	lea	anim1028(pc),a1
	move.l	a1,(a0)
	lea	anim_obj_adj_p(pc),a0
	lea	adj_anim1028(pc),a1
	move.l	a1,(a0)
;---
	lea	rostgrau(pc),a0
	lea	colsl(pc),a1
	moveq	#14,d4
	moveq	#63+1,d5
	bsr	ncalc_pal

	lea	graulind(pc),a0
	lea	colsl+64*4(pc),a1
	moveq	#14,d4
	moveq	#63+1,d5
	bsr	ncalc_pal

	lea	rostgrau(pc),a0
	lea	obj2cols2+128*4(pc),a1
	moveq	#14,d4
	moveq	#63+1,d5
	bsr	ncalc_pal

	lea	graulind(pc),a0
	lea	obj2cols2+192*4(pc),a1
	moveq	#14,d4
	moveq	#63+1,d5
	bsr	ncalc_pal

	lea	obj2cols2(pc),a1
	move	#128-1,d7
.ht	clr.l	(a1)+
	dbf	d7,.ht
	move	#128-1,d7
	lea	colsl+128*4(pc),a0
.ht2	move.l	(a1)+,(a0)+
	dbf	d7,.ht2

;-
	lea	fade_amount(pc),a6
	move	#256,(a6)
	lea	fade_step(pc),a6
	move	#100,(a6)

	lea	obj2cols2(pc),a0
	lea	colsl(pc),a1
	bsr	fade_init

	lea	fade2_n_fro\.dir(pc),a0
	clr	(a0)+
	move	#31*50,(a0)+
	move	#100,(a0)
;-
	moveq	#0,d0
	moveq	#0+63,d1
	moveq	#0,d5
	lea	(0+63).w,a6
	move.l	#128,d6
	move.l	d1,d2
	bsr	trans_limes2

	move.l	#128,d0
	move.l	#128+63,d1
	moveq	#0,d5
	lea	(0+63).w,a6
	move.l	#128,d6
	move.l	d1,d2
	bsr	trans_limes2

	moveq	#64,d0
	moveq	#64+63,d1
	moveq	#0,d5
	lea	(0+63).w,a6
	move.l	#128+64,d6
	move.l	d1,d2
	bsr	trans_limes2

	move.l	#128+64,d0
	move.l	#128+64+63,d1
	moveq	#0,d5
	lea	(0+63).w,a6
	move.l	#128+64,d6
	move.l	d1,d2
	bsr	trans_limes2

	move.l	addtab_p(pc),a0
	move	#256-1,d7
	moveq	#0,d0
.el	move.b	d0,(a0)
	lea	256(a0),a0
	addq.l	#1,d0
	dbf	d7,.el

;---
	lea	t1_struct(pc),a0
	move	#4-1,(a0)+
	move	#2-1,(a0)

	move.l	t1_pkt_p(pc),a0
	move	#92*4/2,d0
	move	#25*4/2,d1
	moveq	#0,d2
	moveq	#0,d7
	bsr.w	o_tri

	move.l	t1_tab_p(pc),a0
	move.l	a0,a1
	move.l	#$10004,(a0)+
	move.l	#$30001,(a0)+
	move.l	#$30002,(a0)+

	move.l	t1_tl_p(pc),a1
	lea	t1_tl(pc),a0
	move.l	a1,(a0)

	move	#t_transtexmap,a0
	move.l	dummymap1_p(pc),a6

	moveq	#11,d2
	moveq	#256-222,d3
	lea	101.w,a2
	lea	(256-247).w,a3
	bra	do_143_132

;----------------------------

_x1_poetrnd2:
	jmp	_x1_poetrnd

o1024	=	200		; Anzahl flares

obj1024:
	lea	t1_struct(pc),a0
	move	#o1024-1,(a0)+
	move	#o1024-1,(a0)

	move.l	t1_pkt_p(pc),a0
	move	#o1024-1,d7
.h1
	bsr	_x1_poetrnd2
	and	#$7ff,d0
	sub	#$400,d0
	lsl	#2,d0
	move	d0,(a0)+

	bsr	_x1_poetrnd2
	and	#$7ff,d0
	sub	#$400,d0
	lsl	#2,d0
	move	d0,(a0)+

	bsr	_x1_poetrnd2
	and	#$7ff,d0
	sub	#$400,d0
	lsl	#2,d0
	move	d0,(a0)+
	
	dbf	d7,.h1

	move	#o1024-1,d7
	bsr.w	o_flare_tab

	move.l	t1_tl_p(pc),a1
	lea	t1_tl(pc),a0
	move	#o1024-1,d7
	move.l	a1,(a0)

.h3	move	#t_flare,(a1)+
	move.l	#rflare,(a1)+
	move	#62,(a1)+
	move	#62,(a1)+
	subq	#1,d7
	bmi.s	.h4

	move	#t_flare,(a1)+
	move.l	#rflare2,(a1)+
	move	#64,(a1)+
	move	#64,(a1)+
	dbf	d7,.h3	
.h4
;---
	moveq	#64,d0
	move.l	#64+79,d1
	move.l	d1,d2
	moveq	#0,d5
	lea	(0+31).w,a6
	moveq	#64,d6
	bsr	trans_limes3

	move.l	#64+80,d0
	move.l	#64+80+79,d1
	move.l	d1,d2
	moveq	#0,d5
	lea	(0+31).w,a6
	move.l	d0,d6
	bsr	trans_limes3

	moveq	#0,d0
	moveq	#0+63,d1
	moveq	#0,d5
	lea	(0+31).w,a6
	moveq	#0,d6
	moveq	#0+63,d2
	bra	trans_limes3

;----------------------

obj23:
	lea	st_obj_map(pc),a0
	move.l	dummymap3_p(pc),(a0)

	lea	st_obj_type(pc),a0
	move.l	#t_phong,(a0)
	lea	t1_tl(pc),a0
	clr.l	(a0)

	lea	t1_struct(pc),a0
	move	#4*16-1,(a0)+
	move	#4*16*2-1,(a0)+

	moveq	#4,d0
	moveq	#16,d1
	moveq	#24+20,d2
	move.l	#80+30+100,d3
	
	bsr.w	bf_torus_gen

	moveq	#4,d0
	moveq	#16,d1
	moveq	#10+10,d2
	move.l	#50+30+100,d3
	bsr.w	bf_torus_gen_pkt

	lea	t1_pkt+4*6,a0
	lea	t2_pkt+4*6,a1
	moveq	#8-1,d7
	moveq	#4*6,d2
o7_1:	moveq	#4-1,d6
o7_2:	move	(a1)+,(a0)
	add	#20,(a0)+
	move	(a1)+,(a0)+
	move	(a1)+,(a0)+
	dbf	d6,o7_2
	add.l	d2,a1
	add.l	d2,a0
	dbf	d7,o7_1

	lea	anzpkt(pc),a0
	move	#4*16-1,(a0)
	lea	tg_rotangle+4(pc),a5
	move.l	t1_pkt_p(pc),a0
	move.l	#$8000000,-(a5)
	move.l	a0,a1
	bsr.w	tg_rotyx		; Punkte rotieren
	
;	move	t1_struct(pc),d0
;	move.l	t1_pkt_p(pc),a0
;.a:	add	#360*4,2(a0)
;	addq.l	#6,a0
;	dbf	d0,.a
;
	rts

;------------------------------------------

obj25:
	lea	t1_struct(pc),a0
	move	#3*16-1,(a0)+
	move	#3*16*2-1,(a0)+

	moveq	#3,d0
	moveq	#16,d1
	move.l	#44*4,d2
	move.l	#210*4,d3
	
	bsr.w	bf_torus_gen

	move.l	t1_pkt_p(pc),a0
	move	t1_struct(pc),d7
	addq.l	#2,a0
.hc	move	(a0),d0
	asr	#3,d0
	move	d0,(a0)
	addq.l	#6,a0
	dbf	d7,.hc
;--
	move.l	t1_tl_p(pc),a1
	lea	t1_tl(pc),a0
	move.l	a1,(a0)

	move	#t_transtexmap,a0
;	lea	t_texmap,a0
;	lea	t_gouraud_tmap.w,a0
	move.l	dummymap2_p(pc),a6

	move	t1_struct+2(pc),d7
	move.l	t1_pkt_p(pc),a2
	move.l	t1_tab_p(pc),a3

.ag	move	a0,(a1)+
	move.l	a6,(a1)+

	moveq	#3-1,d6
.ag2	move	(a3)+,d0
	subq	#1,d0
	mulu	#6,d0
	move	(a2,d0.l),d1
	asr	#4,d1
	add	#128,d1
	move	d1,(a1)+
	move	4(a2,d0.l),d1
	asr	#4,d1
	add	#128,d1
	move	d1,(a1)+
	dbf	d6,.ag2
	dbf	d7,.ag
;--
	lea	anzpkt(pc),a0
	move	t1_struct(pc),(a0)
	lea	tg_rotangle(pc),a5
	move.l	t1_pkt_p(pc),a0
	clr.l	(a5)
	move	#$0400,4(a5)
	move.l	a0,a1
	bsr.w	tg_rotyx		; Punkte rotieren
	
;	move	t1_struct(pc),d0
;	move.l	t1_pkt_p(pc),a0
;.a:	add	#360*4,2(a0)
;	addq.l	#6,a0
;	dbf	d0,.a
;
	rts

;------------------------------------------

obj24_2:
	move.l	#50*4,d3
	moveq	#o24py,d4
	moveq	#o24px+1,d6
	moveq	#%1110,d7
	bsr	do_lsphere

	move.l	dummymap0_p(pc),a6
	bsr	o24_ei

	move.l	t1_pkt_p(pc),a0
	move	t1_struct(pc),d7
.hc	add	#400*4,(a0)
	addq.l	#6,a0
	dbf	d7,.hc
	rts

;--------------

anim24:
	lea	objobjpos(pc),a0
	clr.l	(a0)+
	clr	(a0)

	lea	ang24(pc),a5
	lea	st_odl+0*12(pc),a0
	move	(a0)+,d7
	move.l	(a0)+,d0
	bsr	rot_p_k

	lea	ang24_2(pc),a5
	lea	st_odl+1*12(pc),a0
	move	(a0)+,d7
	move.l	(a0)+,d0
	bra	rot_p_k

;---

adj_anim24:
	lea	ang24+2(pc),a0
	lea	ang24_2+2(pc),a1
	add	#-12,(a0)
	add	#12,(a1)
	and	#$1ffe,(a0)
	and	#$1ffe,(a1)
	rts


ang24:	dc	0,$2000-$400,0
ang24_2:dc	0,$1000-$400,0

;---------

obj24m:
	dc	0,	-400*4,0,-400*4
	dc	0,	-400*4,0,-400*4
	dc	200,	-450*4,30*4,-450*4
	dc	201,	0,0,-2600*4
	dc	300,	0,-500*4,-1500*4
	dc	400,	200*4,-500*4,00*4
	dc	500,	200*4,-500*4,1500*4
	dc	600,	1000*4,300*4,0
	dc	700,	0,-100*4,-700*4
	dc	770,	0,0*4,-800*4
	dc	855,	0,0*4,-600*4
	dc	940,	0,150*4,-450*4
	dc	1025,	0,0,-600*4
	dc	1100,	-500*4,-400*4,0*4
	dc	1150,	-500*4,-400*4,600*4
	dc	1200,	-400*4,-300*4,900*4
	dc	1200,	-400*4,-300*4,900*4
	dc	1200,	-400*4,-300*4,900*4
	dc	1200,	-400*4,-300*4,900*4
	dc	-1

obj24m2:
	dc	0,	100*4,0,0
	dc	0,	100*4,0,0
	dc	200,	100*4,0,0
	dc	201,	0,0,0
	dc	700,	0,0,0
	dc	770,	0,0,-400*4
	dc	855,	-200*4,0,-200*4
	dc	940,	0*4,0,-400*4
	dc	1025,	200*4,0,-200*4
	dc	1100,	400*4,0,0
	dc	1200,	0*4,0,200*4
	dc	1200,	0*4,0,200*4
	dc	1200,	0*4,0,200*4
	dc	1200,	0*4,0,200*4
	dc	-1

;--------


o24py	=	8
o24px	=	6

o24anz:	dc	0

obj24:
	lea	fl_4_sort_st(pc),a0
	clr	(a0)
	lea	clear_st(pc),a0
	clr	(a0)

	lea	copy_clear_st(pc),a0
	move	#1,(a0)
;----
	move.l	cloud64_p,a0
	lea	dummymap3-256*256,a1
	move.l	a1,a2
	add.l	#256*256*3,a2

	move	#256-1,d6
.mm4:	moveq	#256/4-1,d7
.mm5:	move.l	(a0)+,d0
	lsr.l	#1,d0
	and.l	#$7f7f7f7f,d0
;	add.l	#$7b7b7b7b,d0
	move.l	d0,256(a1)
	move.l	d0,512(a1)
	move.l	d0,(a1)+
	move.l	d0,256(a2)
	move.l	d0,512(a2)
	move.l	d0,(a2)+
	dbf	d7,.mm5
	lea	512(a1),a1
	lea	512(a2),a2
	dbf	d6,.mm4
;----
	lea	flare1,a0
	lea	rflare2,a2

	moveq	#32-1,d6
.h5	moveq	#32-1,d7
.h4	move.b	(a0)+,d0
	add.b	d0,d0
;	add.b	#64,d0
	move.b	d0,64(a2)
	move.b	d0,(a2)+
	move.b	d0,64(a2)
	move.b	d0,(a2)+
	dbf	d7,.h4
	lea	64(a2),a2
	dbf	d6,.h5

;-
	bsr.w	smooth64_64

	lea	rflare3,a0
	move	#64*64-1,d7
.ha	add.b	#64,(a0)+
	dbf	d7,.ha
;------

	lea	bbox_st(pc),a0
	clr	(a0)

	lea	t1_m1(pc),a0
	lea	obj24m(pc),a1
	move.l	a1,(a0)

	lea	t1_m2(pc),a0
	lea	obj24m2(pc),a1
	move.l	a1,(a0)

	lea	t1_m3(pc),a0
	clr.l	(a0)

	lea	anim_obj_rout_p(pc),a0
	lea	anim24(pc),a1
	move.l	a1,(a0)
	lea	anim_obj_adj_p(pc),a0
	lea	adj_anim24(pc),a1
	move.l	a1,(a0)

;---
	moveq	#0,d0
	move.l	#0+63,d1
	move.l	#215,d5
	lea	(215+40).w,a6
	moveq	#63,d2
	moveq	#0,d6
	bsr	trans_limes2

	moveq	#64,d0
	move.l	#64+79,d1
	move.l	#215,d5
	lea	(215+40).w,a6
	move.l	d1,d2
	moveq	#64,d6
	bsr	trans_limes2

	move.l	#64+80,d0
	move.l	#64+80+63,d1
	move.l	#215,d5
	lea	(215+40).w,a6
	move.l	d1,d2
	move.l	d0,d6
	bsr	trans_limes2


;---
	move.l	dummymap2_p(pc),a0
	move.l	furchen_map_p,a1
	move	#256*256/4-1,d7
.hx	move.l	(a1)+,d0
	lsr.l	#1,d0
	and.l	#$7f7f7f7f,d0
	add.l	#$d7d7d7d7,d0
	move.l	d0,(a0)+
	dbf	d7,.hx
;---
	move.l	dummymap_p(pc),a0
;	move.l	furchen_map_p(pc),a1
	move.l	marble_p,a1
	bsr	cp_64k

;	move.l	marble_p(pc),a0
	move.l	furchen_map_p,a0
;	move.l	sm_map_p(pc),a0
	lea	bmap,a1
	bsr	bump2d
	bsr	corr_bmap

	moveq	#0,d0
	moveq	#64,d1
	bsr	init_gttab

	move.l	dummymap_p(pc),a0
	lea	gouraud_map,a1
	bsr	bump_tex

	move.l	dummymap_p(pc),a0
	move	#256*256/4-1,d7
.d	move.l	(a0),d0
	add.l	#$40404040,d0
	move.l	d0,(a0)+
	dbf	d7,.d
;---
	move.l	dummymap0_p(pc),a0
	move.l	furchen_map_p,a1
	move	#256*256/4-1,d7
.hq	move.l	(a1)+,d0
	lsr.l	#1,d0
	and.l	#$7f7f7f7f,d0
	move.l	d0,(a0)+
	dbf	d7,.hq

	move.l	marble_p(pc),a0
	lea	bmap,a1
	bsr	bump2d
	bsr	corr_bmap

	moveq	#0,d0
	moveq	#64,d1
	bsr	init_gttab

	move.l	dummymap0_p(pc),a0
	lea	gouraud_map,a1
	bsr	bump_tex

	move.l	dummymap0_p(pc),a0
	move	#256*256/4-1,d7
.dx	move.l	(a0),d0
	add.l	#$90909090,d0
	move.l	d0,(a0)+
	dbf	d7,.dx
;---
	lea	stahlblau(pc),a0
	lea	obj2cols2(pc),a1
	moveq	#3,d4
	moveq	#31+1,d5
	bsr	ncalc_pal

	lea	stahlblau+2*4(pc),a0
	lea	obj2cols2+32*4(pc),a1
	moveq	#10,d4
	moveq	#31+1,d5
	bsr	ncalc_pal

	lea	beige(pc),a0
	lea	obj2cols2+64*4(pc),a1
	moveq	#14,d4
	moveq	#79+1,d5
	bsr	ncalc_pal

	lea	rostgrau(pc),a0
	lea	obj2cols2+144*4(pc),a1
	moveq	#18,d4
	moveq	#79+1,d5
	bsr	ncalc_pal

;---

	move.l	#150*4,d3
	moveq	#o24py,d4
	moveq	#o24px+1,d6
	moveq	#%1110,d7
	bsr	do_lsphere

	move.l	dummymap_p(pc),a6
o24_ei:	lea	t_texmap.w,a0

	lea	t1_struct(pc),a1
	subq.l	#1,d0
	subq.l	#1,d1
	move	d0,(a1)+
	move	d1,(a1)
	lea	o24anz(pc),a1
	move	d0,(a1)

	move.l	t1_tl_p(pc),a1
	lea	t1_tl(pc),a2
	move.l	a1,(a2)

;	move.l	furch_circ_p(pc),a6

	lea	(256/(o24py)).w,a4
	lea	((256-12)/(o24px+2)).w,a5
	moveq	#6,d0
	add	a5,d0

.c:	moveq	#(o24px)-1,d6

.b:	moveq	#o24py-1,d7
	moveq	#0,d2		; xl
	move.l	d0,d3		; yo
	lea	(a4,d2.l),a2	; xr
	lea	(a5,d3.l),a3	; yu
	exg	d2,a2
	exg	d3,a3

.a:	bsr.w	.o2
	bsr.w	.o1

	add.l	a4,d2
	add.l	a4,a2
	dbf	d7,.a
	add.l	a5,d0
	dbf	d6,.b

;---
	moveq	#6,d0
	move	#o24py-1,d1
	moveq	#0,d2		; xl
	move.l	d0,d3		; yo
	lea	(a4,d2.l),a2	; xr
	lea	(a5,d3.l),a3	; yu
	exg	d2,a2
	exg	d3,a3
.ag:	bsr.w	.o1
	add.l	a4,d2
	add.l	a4,a2
	dbf	d1,.ag
;--
	move	#((256-12)/(o24px+2))*7+4,d0
	move	#o24py-1,d1
	moveq	#0,d2		; xl
	move.l	d0,d3		; yo
	lea	(a4,d2.l),a2	; xr
	lea	(a5,d3.l),a3	; yu
.ag2:	bsr.s	.o1

	add.l	a4,d2
	add.l	a4,a2
	dbf	d1,.ag2

	move.l	a1,a2
	lea	-(6*2+6)*3+6(a2),a1
	lea	-(6*2+6)*(3+4)+6(a2),a3
	bsr.s	.ex

	lea	-(6*2+6)*2+6(a2),a1
	lea	-(6*2+6)*8+6(a2),a3
	bsr.s	.ex

	lea	-(6*2+6)*4+6(a2),a1
	lea	-(6*2+6)*6+6(a2),a3
;	bsr.s	.ex

;--
.ex:	movem.l	(a1),d0-d2
	movem.l	(a3),d3-d5
	movem.l	d0-d2,(a3)
	movem.l	d3-d5,(a1)
	rts
;--

.o1:	move	a0,(a1)+
	move.l	a6,(a1)+

	move	d2,(a1)+	; xr
	move	a3,(a1)+	; yo

	move	a2,(a1)+	; xl
	move	d3,(a1)+	; yu

	move	d2,(a1)+	; xr
	move	d3,(a1)+	; yu
	rts

.o2:	move	a0,(a1)+
	move.l	a6,(a1)+

	move	a2,(a1)+	; xl
	move	a3,(a1)+	; yo

	move	a2,(a1)+	; xl
	move	d3,(a1)+	; yu
	
	move	d2,(a1)+	; xr
	move	a3,(a1)+	; yo

	rts

;----------------------------

o511	=	8
o512	=	6

obj51:
	moveq	#o511,d0		; d0 = punkte pro ring
	moveq	#o512+1,d1		; d1 = anzahl ringe+1
	move.l	#0*4,d4		; d4 = xmin
	move.l	#500*4,d5		; d5 = xmax
	lea	o51r(pc),a4	; a4 = pointer auf d1 radien
	bsr	objx

	lea	t1_struct(pc),a0
	move	#o511*(o512+1)-1,(a0)+
	move	#o511*o512*2-1,(a0)

;	move	t1_struct(pc),d7
;	move.l	t1_pkt_p(pc),a0
;.t	add	#80*4,(a0)
;	addq.l	#6,a0
;	dbf	d7,.t
;-

	move.l	t1_tl_p(pc),a1
	lea	t1_tl(pc),a0
	move.l	a1,(a0)

	lea	(t_transtexmap).w,a0
	move.l	dummymap0_p(pc),a6

	moveq	#o512-1,d6
	sub.l	a2,a2
	move	#256/o512,d2
	exg	a2,d2

.c:	moveq	#o511-1,d7
	moveq	#0,d3
	lea	(256/o511).w,a3

.b:	bsr	helfi
	add	#256/o511,d3
	add	#256/o511,a3
	cmp	#1,d7
	bne.s	.d
	move	#255,a3

.d:	dbf	d7,.b
;	move	(a5)+,d2
;	move	(a5),a2
	add	#256/o512,d2
	add	#256/o512,a2

	dbf	d6,.c

;---
	move.l	t1_tl_p(pc),a0
	move	t1_struct+2(pc),d7
	addq.l	#6,a0

.f	movem.l	(a0),d0-d1
	move.l	d1,(a0)+
	move.l	d0,(a0)
	lea	18-4(a0),a0
	dbf	d7,.f

;---
	rts

o51r:	dc	50,80,110,140
	dc	170,200,230
;	dc	208,230

; 1	2     3     4
; a2/d3 d2/d3 a2/a3 d2/a3
helfi:
	move	a0,(a1)+
	move.l	a6,(a1)+

	move	a2,(a1)+		; 124
	move	d3,(a1)+

	move	d2,(a1)+
	move	d3,(a1)+

	move	d2,(a1)+
	move	a3,(a1)+

	move	a0,(a1)+
	move.l	a6,(a1)+

	move	a2,(a1)+		; 132
	move	d3,(a1)+

	move	d2,(a1)+
	move	a3,(a1)+

	move	a2,(a1)+
	move	a3,(a1)+

	rts

;----------------------------

o501	=	4
o502	=	3

obj50:
	moveq	#o501,d0		; d0 = punkte pro ring
	moveq	#o502+1,d1		; d1 = anzahl ringe+1
	move.l	#-80*4,d4		; d4 = xmin
	move.l	#80*4,d5		; d5 = xmax
	lea	o50r(pc),a4	; a4 = pointer auf d1 radien
	bsr	objx

	lea	t1_struct(pc),a0
	move	#o501*(o502+1)-1,(a0)+
	move	#o501*o502*2-1,(a0)

	lea	st_obj_map(pc),a0
;	move.l	circle_p2(pc),(a0)
	move.l	dummymap3_p(pc),(a0)

	lea	st_obj_type(pc),a0
	move.l	#t_phong,(a0)
	lea	t1_tl(pc),a0
	clr.l	(a0)
;-
	move.l	t1_pkt_p(pc),a0
	lea	o501*(o502-1)*6(a0),a0
	lea	o501*6(a0),a1

	moveq	#o501-1,d7
.a	move	(a0),(a1)
	addq.l	#6,a0
	addq.l	#6,a1
	dbf	d7,.a
	rts

o50r:	dc	1,16*4,20*4,1

;----------------------------

o431	=	4
o432	=	5

obj43:
	moveq	#o431,d0		; d0 = punkte pro ring
	moveq	#o432+1,d1		; d1 = anzahl ringe+1
	move.l	#-80*4,d4		; d4 = xmin
	move.l	#80*4,d5		; d5 = xmax
	lea	o43r(pc),a4	; a4 = pointer auf d1 radien
	bsr	objx

	lea	t1_struct(pc),a0
	move	#o431*(o432+1)-1,(a0)+
	move	#o431*o432*2-1,(a0)

	lea	st_obj_map(pc),a0
;	move.l	circle_p2(pc),(a0)
	move.l	dummymap3_p(pc),(a0)

	lea	st_obj_type(pc),a0
	move.l	#t_phong,(a0)
	lea	t1_tl(pc),a0
	clr.l	(a0)
;-
	move.l	t1_pkt_p(pc),a0
	lea	4(a0),a2
	lea	o431*(o432-1)*6(a0),a0
	lea	o431*6(a0),a1

	moveq	#o431-1,d7
.a	move	(a0),(a1)
	addq.l	#6,a0
	addq.l	#6,a1
	dbf	d7,.a

	move	#o431*(o432+1)-1,d7
.h	move	(a2),d0
	asr	#1,d0
	move	d0,(a2)
	addq.l	#6,a2
	dbf	d7,.h
	rts

o43r:	dc	1*4,26*4,20*4,5*4
	dc	26*4,1*4

;----------------------------------------

anim20:
	move.l	pointsp201(pc),a1
	lea	slideoff201(pc),a3
	move.l	pointsp201r(pc),a2
	lea	slideoff201r(pc),a4
	moveq	#12*2,d0
	bsr.w	rotmove_obj_n

	move.l	pointsp202(pc),a1
	lea	slideoff202(pc),a3
	move.l	pointsp202r(pc),a2
	lea	slideoff202r(pc),a4
	moveq	#12*6,d0
	bsr.w	rotmove_obj_n

	move.l	pointsp203(pc),a1
	lea	slideoff203(pc),a3
	move.l	pointsp203r(pc),a2
	lea	slideoff203r(pc),a4
	moveq	#12*7,d0
	bsr.w	rotmove_obj_n

	move.l	pointsp204(pc),a1
	lea	slideoff204(pc),a3
	move.l	pointsp204r(pc),a2
	lea	slideoff204r(pc),a4
	moveq	#12*8,d0
	bsr.w	rotmove_obj_n

	move.l	pointsp204(pc),a1
	lea	slideoff204(pc),a3
	move.l	pointsp204r(pc),a2
	lea	slideoff204r(pc),a4
	moveq	#12*9,d0
	bsr.w	rotmove_obj

;---
	lea	st_odl+1*12(pc),a0
	move.l	koordxyz2_p(pc),a2
	move.l	koordxyz_sp_p(pc),a1
	move	(a0)+,d7
	move.l	(a0)+,d0
	addq.l	#2,a2
	addq.l	#2,a1
	add.l	d0,a2
	add.l	d0,a1

	move.l	sinp(pc),a3
	move	off20(pc),d5
	moveq	#o22d+1-1,d4

.h2	move	d5,d0
	moveq	#o22d+1-1,d7
.h1	move	#60*4*2,d6
	muls	(a3,d0.w),d6
	add	#32*18*2,d0
	swap	d6
	add	(a2),d6
	and	#$1ffe,d0
	move	d6,(a1)
	addq.l	#6,a2
	addq.l	#6,a1
	dbf	d7,.h1
	add	#32*26,d5
	and	#$1ffe,d5
	dbf	d4,.h2
;---
	lea	objobjpos(pc),a0
	clr	(a0)+
	move	#360*4,(a0)+
	clr	(a0)

	lea	ang23(pc),a5
	lea	st_odl+5*12(pc),a0
	move	(a0)+,d7
	move.l	(a0)+,d0
	bsr	rot_p_k

	lea	ang23(pc),a5
	lea	st_odl+5*12(pc),a0
	move	(a0)+,d7
	move.l	(a0)+,d0
	bsr	rot_p_n

;---
	lea	objobjpos(pc),a0
	clr.l	(a0)

	lea	ang1005(pc),a5
	lea	st_odl+3*12(pc),a0
	move	(a0)+,d7
	move.l	(a0)+,d0
	bsr	rot_p_k

	lea	ang1006(pc),a5
	lea	st_odl+4*12(pc),a0
	move	(a0)+,d7
	move.l	(a0)+,d0
	bra	rot_p_k

;-
off20:	dc	0
;-
ang1005:	dc	0,0,0
ang1006:	dc	0,0,0
ang23:	dc	0,0,0
;-------

slide201:	dc	0
pointsp201:	dc.l	0
slideadd201:	dc.l	0
slideoff201:	dc.l	0

slide202:	dc	0
pointsp202:	dc.l	0
slideadd202:	dc.l	0
slideoff202:	dc.l	0
slide203:	dc	0
pointsp203:	dc.l	0
slideadd203:	dc.l	0
slideoff203:	dc.l	0
slide201r:	dc	0
pointsp201r:	dc.l	0
slideadd201r:	dc.l	0
slideoff201r:	dc.l	0
slide202r:	dc	0
pointsp202r:	dc.l	0
slideadd202r:	dc.l	0
slideoff202r:	dc.l	0
slide203r:	dc	0
pointsp203r:	dc.l	0
slideadd203r:	dc.l	0
slideoff203r:	dc.l	0

slide204:	dc	0
pointsp204:	dc.l	0
slideadd204:	dc.l	0
slideoff204:	dc.l	0

slide204r:	dc	0
pointsp204r:	dc.l	0
slideadd204r:	dc.l	0
slideoff204r:	dc.l	0

		rept	4
		dc	0
		dc.l	0,0,0
		endr
;-------

adj_okeys:
.hk	lea	2(a1),a0
;	lea	pointsp201(pc),a0
;	lea	slideadd201(pc),a2
;	lea	slideoff201(pc),a3
	lea	2+4(a1),a2
	lea	2+4+4(a1),a3
	bsr	adj_t_spline
	lea	2+4+4+4(a1),a1
	dbf	d7,.hk
	rts
;-------

adj_anim20:
	lea	slide201(pc),a1
	moveq	#8-1,d7
	bsr.s	adj_okeys

;---

	move	#$1ffe,d7
	lea	off20(pc),a0
	lea	ang1005+2(pc),a1
	lea	ang1006+2(pc),a2
	lea	ang23(pc),a3
	add	#32,(a0)
	sub	#20,(a1)
	add	#16,(a2)

	add.l	#$000efff0,(a3)+
	add	#24,(a3)

	and	d7,(a0)
	and	d7,(a1)
	and	d7,(a2)

	and	d7,(a3)
	and	d7,-(a3)
	and	d7,-(a3)
	rts

;------------------------------------

init_okeys:
	moveq	#8,d1

.hk	lea	2(a1),a0
;	lea	pointsp201(pc),a0
;	lea	slideadd201(pc),a2
;	lea	slideoff201(pc),a3
	lea	2+4(a1),a2
	lea	2+4+4(a1),a3
	bsr	get_k
	lea	2+4+4+4(a1),a1
	dbf	d7,.hk
	rts

;---------

lichtkegelmap0:
	move.l	dummymap0_p(pc),a0
	move.l	furchen_map_p(pc),a1
	add.l	#$10000,a0
	move	#256-1,d6
.hi	move.l	a1,a2
	move	#256-1,d7
.hh	move.b	(a2),d0
	lsr.b	#1,d0
	subq.b	#8,d0
	bpl.s	.hj
	moveq	#0,d0
.hj	add.b	#$40,d0
	move.b	d0,-(a0)
	lea	256(a2),a2
	dbf	d7,.hh
	addq.l	#1,a1
	dbf	d6,.hi
	rts

;----------

o20x	=	800*4
o20y	=	800*4
o20z	=	800*4

o20d	=	4		; anzahl der unterteilungen

obj20:
	lea	pointsp201(pc),a0
	lea	o20_o1(pc),a1
	move.l	a1,(a0)
	lea	o20_o2(pc),a1
	move.l	a1,14*1(a0)
	lea	o20_o3(pc),a1
	move.l	a1,14*2(a0)

	lea	o20_o1r(pc),a1
	move.l	a1,14*3(a0)
	lea	o20_o2r(pc),a1
	move.l	a1,14*4(a0)
	lea	o20_o3r(pc),a1
	move.l	a1,14*5(a0)

	lea	o20_o4(pc),a1
	move.l	a1,14*6(a0)
	lea	o20_o4r(pc),a1
	move.l	a1,14*7(a0)

	lea	slide201(pc),a1
	moveq	#8-1,d7
	bsr.w	init_okeys

;-----------
	lea	fl_4_sort_st(pc),a0
	move	#1,(a0)
	lea	clear_st(pc),a0
	move	#1,(a0)

	lea	t1_m1(pc),a0
	lea	obj20m(pc),a1
	move.l	a1,(a0)

	lea	t1_m2(pc),a0
	lea	obj20m2(pc),a1
	move.l	a1,(a0)

	lea	t1_m3(pc),a0
	lea	obj20m3(pc),a1
	move.l	a1,(a0)

;-
	lea	anim_obj_rout_p(pc),a0
	lea	anim20(pc),a1
	move.l	a1,(a0)
	lea	anim_obj_adj_p(pc),a0
	lea	adj_anim20(pc),a1
	move.l	a1,(a0)

;---
	move.l	dummymap_p(pc),a0
	move.l	marble_p(pc),a1
	bsr	cp_64k
;----
	move.l	sm_map_p(pc),a0
	lea	bmap,a1
	bsr	bump2d
	bsr	corr_bmap

	moveq	#0,d0
	moveq	#0+64,d1
	bsr	init_gttab

	move.l	dummymap_p(pc),a0
	bsr	bump_tex_pm

;---
	move.l	dummymap2_p(pc),a0
	move.l	marble_p(pc),a1
	bsr	cp_64k

	move.l	marble_p(pc),a0
	lea	bmap,a1
	bsr	bump2d
	bsr	corr_bmap

	move.l	dummymap3_p(pc),a0
	move.l	#$80808080,d0
	bsr	do_bmap_x
	move.l	dummymap3_p(pc),a0
	move.l	origcircle_p(pc),a1
	bsr	cp_64k

	move.l	dummymap2_p(pc),a0
	move.l	dummymap3_p(pc),a1
	bsr	bump_tex

	move.l	dummymap2_p(pc),a0
	move.l	a0,a1
	move.l	#$80808080,d1
	bsr	cp_add
;-
	move.l	dummymap4_p(pc),a0
	move.l	cloud64_p(pc),a1
	bsr	cp_64k

	move.l	dummymap4_p(pc),a0
	move.l	dummymap3_p(pc),a1
	bsr	bump_tex
;-
	move.l	dummymap5_p(pc),a0
	move.l	sin_map_p(pc),a1
;	bsr	cp_64k
	moveq	#-1,d7
.cx	move.b	(a1)+,d0
	cmp.b	#32,d0
	blt.s	.cx1
	sub.b	#32,d0
.cx1:	add.b	#16,d0
	move.b	d0,(a0)+
	dbf	d7,.cx

	move.l	dummymap5_p(pc),a0
	move.l	dummymap3_p(pc),a1
	bsr	bump_tex
;---
	move.l	circle_p2(pc),a0
	move.l	dummymap3_p(pc),a1
	move	#256*256/4-1,d7
.cx3	move.l	(a0)+,d0
	lsr.l	#1,d0
	and.l	#$7f7f7f7f,d0
	add.l	#$c0c0c0c0,d0
	move.l	d0,(a1)+
	dbf	d7,.cx3
;---

	bsr	lichtkegelmap0
;---
	lea	milgruen(pc),a0
	lea	obj2cols2(pc),a1
	moveq	#14,d4
	moveq	#63+1,d5
	bsr	ncalc_pal

	lea	gruengrau(pc),a0
	lea	obj2cols2+128*4(pc),a1
	moveq	#16,d4
	moveq	#63+1,d5
	bsr	ncalc_pal

	lea	beige(pc),a0
	lea	obj2cols2+192*4(pc),a1
	moveq	#15,d4
	moveq	#63+1,d5
	bsr	ncalc_pal

	lea	stahlblau(pc),a0
	lea	obj2cols2+64*4(pc),a1
	moveq	#12,d4
	moveq	#63+1,d5
	bsr	ncalc_pal
;---
	move.l	t1_pkt_p(pc),a0
	move	#o20x*2/o20d,d3
	move	#o20y*2/o20d,d4
	move	#o20z*2/o20d,d5

	move	#o20y,d1
	move	#o20z,d2
	moveq	#o20d+1-1,d6
.b:	move	#-o20x,d0
	moveq	#o20d-1,d7
.a:	movem	d0-d2,(a0)
	add	d3,d0
	addq.l	#6,a0
	dbf	d7,.a
	movem	d0-d2,(a0)
	addq.l	#6,a0
	sub	d4,d1
	dbf	d6,.b

o20_1:	move	#-o20y,d1
	move	#o20z,d2
	moveq	#o20d+1-1,d6
.b:	move	#-o20x,d0
	moveq	#o20d-1,d7
.a:	movem	d0-d2,(a0)
	add	d3,d0
	addq.l	#6,a0
	dbf	d7,.a
	movem	d0-d2,(a0)
	addq.l	#6,a0
	sub	d5,d2
	dbf	d6,.b

o20_2:	move	#o20z,d2
	move	#-o20x,d0
	moveq	#o20d+1-1,d6
.b:	move	#o20y,d1
	moveq	#o20d-1,d7
.a:	movem	d0-d2,(a0)
	sub	d4,d1
	addq.l	#6,a0
	dbf	d7,.a
	movem	d0-d2,(a0)
	addq.l	#6,a0
	sub	d5,d2
	dbf	d6,.b

	move.l	t1_tab_p(pc),a0
	moveq	#1,d0
	moveq	#o20d-1,d1
	bsr.w	o20_1side

	move.l	#(o20d+1)^2+1,d0
	bsr.w	o20_1side

	move.l	#(o20d+1)^2*2+1,d0
	bsr.w	o20_1side

;--
	move.l	t1_pkt_p(pc),a0
	moveq	#o20d+1-1,d7
	lea	(o20d)*6(a0),a0
	
.cxy1:	move	#o20x,(a0)
	lea	(o20d+1)*6(a0),a0
	dbf	d7,.cxy1
	lea	(-(o20d+1)*6-(o20d)*6)+2(a0),a0
	moveq	#o20d+1-1,d7
.cxy2:	move	#-o20y,(a0)
	addq.l	#6,a0
	dbf	d7,.cxy2

;--

	move.l	t1_pkt_p(pc),a0
	moveq	#o20d+1-1,d7
	lea	(o20d+1)^2*6+(o20d)*6(a0),a0
	
.cxz1:	move	#o20x,(a0)
	lea	(o20d+1)*6(a0),a0
	dbf	d7,.cxz1
	lea	(-(o20d+1)*6-(o20d)*6)+4(a0),a0
	moveq	#o20d+1-1,d7
.cxz2:	move	#-o20z,(a0)
	addq.l	#6,a0
	dbf	d7,.cxz2

;--
	move.l	t1_pkt_p(pc),a0
	moveq	#o20d+1-1,d7
	lea	(o20d+1)^2*2*6+(o20d)*6+2(a0),a0
	
.cyz1:	move	#-o20y,(a0)
	lea	(o20d+1)*6(a0),a0
	dbf	d7,.cyz1
	lea	(-(o20d+1)*6-(o20d)*6)+4(a0),a0
	moveq	#o20d+1-1,d7
.cyz2:	move	#-o20z,(a0)
	addq.l	#6,a0
	dbf	d7,.cyz2

;--
	move.l	t1_pkt_p(pc),a0
	lea	((o20d+1)^2*6)(a0),a1
	lea	((o20d+1)^2*6)-((o20d+1)*6)(a0),a0
	moveq	#(o20d+1)*3-1,d7

.co1:	move	(a0)+,(a1)+
	dbf	d7,.co1
;--

	move.l	t1_pkt_p(pc),a0
	lea	((o20d+1)^2*3*6)(a0),a1

	move.l	#(o20d+1)^2-1,d7
.x:	move.l	(a0)+,(a1)+
	move	(a0)+,d0
	neg	d0
	move	d0,(a1)+
	dbf	d7,.x

	move.l	#(o20d+1)^2-1,d7
.x1:	move	(a0)+,(a1)+
	move	(a0)+,d0
	neg	d0
	move	d0,(a1)+
	move	(a0)+,(a1)+
	dbf	d7,.x1

	move.l	#(o20d+1)^2-1,d7
.x2:	move	(a0)+,d0
	neg	d0
	move	d0,(a1)+
	move.l	(a0)+,(a1)+
	dbf	d7,.x2

	move.l	t1_tab_p(pc),a0
	move	#(o20d)^2*2*3-1,d7
	move	#(o20d+1)^2*3,d0
	lea	((o20d)^2*2*3*6)(a0),a1
.x3:	movem	(a0)+,d1-d3
	add	d0,d1
	add	d0,d2
	add	d0,d3
	move	d2,(a1)+
	move	d1,(a1)+
	move	d3,(a1)+
	dbf	d7,.x3

;--

o20rest:
	move.l	t1_tl_p(pc),a1
	lea	t1_tl(pc),a0
	move.l	a1,(a0)

	lea	t_texmap.w,a0
;	move.l	furchen_map_p(pc),a6
;	move.l	marble_p(pc),a6
	move.l	dummymap5_p(pc),a6
;	move.l	cloud64_p(pc),d5
	move.l	dummymap4_p(pc),d5

	lea	((256)/(o20d)).w,a4
	lea	((256-6)/(o20d)).w,a5
	moveq	#4,d0

.c:	moveq	#(o20d)-1,d6

.b:	moveq	#(o20d)-1,d7
	moveq	#0,d2		; xl
	move.l	d0,d3		; yo
	lea	(a4,d2.l),a2	; xr
	lea	(a5,d3.l),a3	; yu

.a:
	bsr	do_124_234
	exg	d5,a6

	add.l	a4,d2
	add.l	a4,a2
	dbf	d7,.a
	exg	d5,a6
	add.l	a5,d0
	dbf	d6,.b

	move.l	t1_tl_p(pc),a0
	move	#(o20d^2)*18*5/2-1,d7
	lea	((o20d^2)*2*3*18)+6(a0),a2
.gr:	move.l	(a0)+,(a1)+
	dbf	d7,.gr

	move	#(o20d^2)*3*2-1,d7
.gr2:	movem.l	(a2),d0-d1
	move.l	d1,(a2)+
	move.l	d0,(a2)
	lea	18-4(a2),a2
	dbf	d7,.gr2


	lea	t1_struct(pc),a0
	move	#(o20d+1)^2*6-1,(a0)+
	move	#o20d^2*6*2-1,(a0)
;--
	move.l	dummymap2_p(pc),a1
	lea	18*o20d^2*2*4.w,a0
	bsr.s	.h9

	lea	18*o20d^2*2*0.w,a0
	moveq	#o20d^2-1,d7
	bsr.s	.h10

	lea	18*o20d^2*2*3.w,a0
	moveq	#o20d^2-1,d7
	bsr.s	.h10

	lea	18*o20d^2*2*2.w,a0
	bsr.s	.h12
	lea	18*o20d^2*2*5.w,a0
	bsr.s	.h12

;	move.l	sm_map_p(pc),a1
	move.l	dummymap_p(pc),a1
	lea	18*o20d^2*2*1.w,a0
;	bsr.s	.h9

.h9:	moveq	#o20d^2*2-1,d7
.h10:	add.l	t1_tl_p(pc),a0
	
.h8	move.l	a1,2(a0)
	lea	18(a0),a0
	dbf	d7,.h8
	rts

.h12:	add.l	t1_tl_p(pc),a0
	move.l	a0,a2
	moveq	#2-1,d6
.h13:	move.l	a2,a0
	moveq	#o20d-1,d7
.h11:	move.l	a1,2(a0)
	move.l	a1,2+18(a0)
	lea	18*o20d*2(a0),a0
	dbf	d7,.h11
	lea	18*2(a2),a2
	dbf	d6,.h13
	rts

;---

o20_1side:
	move	d0,d3
	add	d1,d3
	addq	#2,d3
;	add	#o20d+1,d3

	move.l	d1,d7
.t2:	move.l	d1,d2

.t1:	move	d0,(a0)+
	addq	#1,d0
	move	d0,(a0)+
	move	d3,(a0)+

	move	d0,(a0)+
	move	d3,2(a0)
	addq	#1,d3
	move	d3,(a0)+
	addq.l	#2,a0
	dbf	d2,.t1

	addq	#1,d0
	addq	#1,d3
	dbf	d7,.t2
	rts


;-------------------------------

o22x	=	700*4
o22y	=	260*4
o22z	=	700*4

o22d	=	8		; anzahl der unterteilungen

obj22:
	move.l	t1_pkt_p(pc),a0
	move	#o22x*2/o22d,d3
	move	#o22z*2/o22d,d5

o22_1:	move	#-o22y,d1
	move	#o22z,d2
	moveq	#o22d+1-1,d6
.b:	move	#-o22x,d0
	moveq	#o22d-1,d7
.a:	movem	d0-d2,(a0)
	add	d3,d0
	addq.l	#6,a0
	dbf	d7,.a
	movem	d0-d2,(a0)
	sub	d5,d2
	addq.l	#6,a0
	dbf	d6,.b

	move.l	t1_tab_p(pc),a0
	moveq	#1,d0
	moveq	#o22d-1,d1
	bsr.w	o20_1side

;--
	moveq	#0,d0
	moveq	#63,d1
	move.l	d1,d2
	moveq	#0,d5
	move	#63,a6
	moveq	#64,d6
	bsr	trans_limes2

	moveq	#64,d0
	moveq	#64+63,d1
	move.l	d1,d2
	moveq	#0,d5
	move	#63,a6
	moveq	#64,d6
	bsr	trans_limes2

	move.l	#192,d0
	move.l	#192+63,d1
	moveq	#63,d2
	moveq	#0,d5
	move	#63,a6
	moveq	#64,d6
	bsr	trans_limes2
;--

o22rest:
	move.l	t1_tl_p(pc),a1
	lea	t1_tl(pc),a0
	move.l	a1,(a0)

	lea	t_transtexmap,a0
;	lea	t_texmap,a0
;	move.l	dummymap_p(pc),d5
	move.l	marble_p(pc),d5
	move.l	d5,a6

	lea	((256)/(o22d)).w,a4
	lea	((256-6)/(o22d)).w,a5
	moveq	#2,d0

.c:	moveq	#(o22d)-1,d6

.b:	moveq	#(o22d)-1,d7
	moveq	#0,d2		; xl
	move.l	d0,d3		; yo
	lea	(a4,d2.l),a2	; xr
	lea	(a5,d3.l),a3	; yu

.a:
	bsr	do_124_234
	exg	d5,a6

	add.l	a4,d2
	add.l	a4,a2
	dbf	d7,.a
	exg	d5,a6
	add.l	a5,d0
	dbf	d6,.b

;---

	lea	t1_struct(pc),a0
	move	#(o22d+1)^2*1-1,(a0)+
	move	#o22d^2*1*2-1,(a0)
	rts

;---------------------------------------


;obj17m:
;	dc	0*128,0,0,100*4
;	dc	0*128,0,0,200*4
;	dc	1*128,0,-1000*4,300*4
;	dc	2*128,0,-1500*4,200*4
;
;	dc	3*128,200*4,0,600*4
;	dc	4*128,800*4,0,0
;	dc	5*128,400*4,-100*4,-200*4
;	dc	6*128,-400*4,400*4,-400*4
;
;	dc	7*128,-200*4,300*4,0
;	dc	8*128,400*4,700*4,-1200*4
;	dc	9*128,-400*4,500*4,-800*4
;	dc	10*128,-1000*4,-100*4,0
;
;	dc	11*128,-600*4,-600*4,600*4
;	dc	12*128,200*4,-600*4,800*4
;	dc	13*128,200*4,-800*4,800*4
;
;	dc	14*128,200*4,-800*4,800*4
;	dc	15*128,200*4,-800*4,800*4
;	dc	16*128,200*4,-800*4,800*4
;	dc	17*128,200*4,-800*4,800*4
;
;	dc	-1
;
;obj17m2:
;	dc	0*128,0,2000,0
;	dc	0*128,0,2000,0
;	dc	1*128,0,1000,0
;	dc	2*128,0,500,0
;
;	dc	3*128,-50*7/5*4,50*7/5*4,-300*7/5*4
;	dc	4*128,-50*7/5*4,50*7/5*4,-300*7/5*4
;	dc	5*128,-210*7/5*4,10*7/5*4,240*7/5*4
;	dc	6*128,260*7/5*4,50*7/5*4,50*7/5*4
;
;	dc	7*128,260*7/5*4,50*7/5*4,50*7/5*4
;	dc	8*128,0,0,0
;	dc	9*128,0,0,0
;	dc	10*128,500,0,-500
;
;	dc	11*128,500,-200,-500
;	dc	12*128,0,-600,-800
;	dc	13*128,0,-600,-800
;
;	dc	14*128,0,-800,-800
;	dc	15*128,0,-800,-800
;	dc	16*128,0,-800,-800
;	dc	17*128,0,-800,-800
;
;	dc	-1
;
;obj17m3:
;	dc	0*128,0
;	dc	0*128,0
;	dc	1*128,$280
;	dc	2*128,0
;
;	dc	3*128,-$380
;	dc	4*128,0
;	dc	5*128,$300
;	dc	6*128,$300
;
;	dc	7*128,-$300
;	dc	8*128,-$180
;	dc	9*128,0
;	dc	10*128,$200
;
;	dc	11*128,0
;	dc	12*128,-$100
;	dc	13*128,-$200
;
;	dc	14*128,$200
;	dc	15*128,$200
;	dc	16*128,$200
;	dc	17*128,$200
;
;	dc	-1
;
;o17py	=	16
;o17px	=	6
;
;obj17:
;	lea	fl_4_sort_st(pc),a0
;	clr	(a0)
;	lea	clear_st(pc),a0
;	move	#1,(a0)
;
;	lea	t1_m1(pc),a0
;	lea	obj17m(pc),a1
;	move.l	a1,(a0)
;
;	lea	t1_m2(pc),a0
;	lea	obj17m2(pc),a1
;	move.l	a1,(a0)
;
;	lea	t1_m3(pc),a0
;	lea	obj17m3(pc),a1
;	move.l	a1,(a0)
;
;;---
;	move.l	#800*2^subpixel,d3
;	moveq	#o17py,d4
;	moveq	#o17px+1,d6
;	moveq	#%1111,d7
;	bsr	do_lsphere
;
;	lea	fuck17(pc),a0
;	move	d1,(a0)
;
;	lea	t1_struct(pc),a0
;	subq.l	#1,d0
;	subq.l	#1,d1
;	move	d0,(a0)+
;	move	d1,(a0)
;
;	move.l	t1_tl_p(pc),a1
;	lea	t1_tl(pc),a0
;	move.l	a1,(a0)
;
;	lea	t_texmap.w,a0
;;	move.l	dummymap_p(pc),a6
;	move.l	marble_p(pc),a6
;
;	moveq	#2-1,d4
;
;	lea	(256/(o17py/2)).w,a4
;	lea	((256-6)/(o17px)).w,a5
;	moveq	#4,d0
;
;.c:	moveq	#(o17px/2)-1,d6
;
;.b:	moveq	#o17py-1,d7
;	moveq	#0,d2		; xl
;	move.l	d0,d3		; yo
;	lea	(a4,d2.l),a2	; xr
;	lea	(a5,d3.l),a3	; yu
;	exg	d2,a2
;	exg	d3,a3
;
;.a:	move	a0,(a1)+
;	move.l	a6,(a1)+
;
;	move	a2,(a1)+
;	move	d3,(a1)+
;
;	move	a2,(a1)+
;	move	a3,(a1)+
;
;	move	d2,(a1)+
;	move	a3,(a1)+
;
;	move	a0,(a1)+
;	move.l	a6,(a1)+
;
;	move	a2,(a1)+
;	move	d3,(a1)+
;
;	move	d2,(a1)+
;	move	a3,(a1)+
;
;	move	d2,(a1)+
;	move	d3,(a1)+
;
;	add.l	a4,d2
;	add.l	a4,a2
;	dbf	d7,.a
;	add.l	a5,d0
;	dbf	d6,.b
;
;;	exg	a5,d0
;;	neg.l	d0
;;	exg	a5,d0
;	dbf	d4,.c
;
;;---
;	move	#o17py*2-1,d1
;
;.ag:	move	a0,(a1)+
;	move.l	a6,(a1)+
;
;	move	#0,(a1)+
;	move	#8,(a1)+
;
;	move	#0,(a1)+
;	move	#4,(a1)+
;
;	move	#4,(a1)+
;	move	#4,(a1)+
;
;	dbf	d1,.ag
;	rts
;fuck17:	dc	0

;------------------------------------

zierrahmen:
	move	(a5),d2
	move	8*2(a5),d3
	subq	#1,d2
	subq	#1,d3
	mulu	#6,d2
	mulu	#6,d3
	move	(a4,d3.l),a2
	move	2(a4,d3.l),a3

	move	2(a4,d2.l),d3
	move	(a4,d2.l),d2

	add	#(o1004x1+o1004x2)*o1004xa/2/2,d2
	add	#(o1004x1+o1004x2)*o1004xa/2/2,a2
	add	#(o1004x1+o1004x2)*o1004ya/2/2,d3
	add	#(o1004x1+o1004x2)*o1004ya/2/2,a3
	asr	#3,d2
	asr	#3,d3
	exg	d2,a2
	exg	d3,a3
	asr	#3,d2
	asr	#3,d3
	exg	d2,a2
	exg	d3,a3

	
	lea	3*2*2(a5),a5
	bra	do_124_234
;---

anim1004:
	move.l	dummymap_p(pc),a1
	move	ysize_scr(pc),d7
	move.l	ps16_sbuf(pc),a0
	subq	#1,d7
	tst	half_scr(pc)
	beq.s	.b
	lsr	#1,d7
.b:	moveq	#xsize/2/4-1,d6
.a:	move	(a0),d0
	move.b	2(a0),d0
	addq.l	#4,a0
	swap	d0
	move.l	(a1),d1
	move	(a0),d0
	move.b	2(a0),d0
	and.l	#$3f3f3f3f,d1
	and.l	#$3f3f3f3f,d0
	addq.l	#4,a0
	add.l	d1,d0
	lsr.l	#1,d0
	and.l	#$7f7f7f7f,d0
	add.l	#$40404040,d0
	move.l	d0,(a1)+
	dbf	d6,.a
	lea	256-160(a1),a1
	lea	xsize(a0),a0
	dbf	d7,.b
	rts

;---

adj_anim1004:
	lea	.cnt(pc),a0
	subq	#1,(a0)
	bpl.s	.q

	lea	fog_min(pc),a0
	lea	fog_max(pc),a1
	cmp	#100*4,(a0)
	blt.s	.q
	sub	#8*4,(a0)
	sub	#8*4,(a1)

.q	rts

.cnt:	dc	200+275

;-------

obj1004j:
	lea	clear_st(pc),a0
	move	(a0),d0
	move.l	d0,-(a7)
	clr	(a0)
	bsr	ps256_clear
	move.l	(a7)+,d0
	lea	clear_st(pc),a0
	move	d0,(a0)

	lea	st_j(pc),a0
	clr.l	(a0)
	rts

;-----

o1004xa	=	8*2
o1004ya	=	8*2
o1004x1	=	200*4
o1004x2	=	100*4

obj1004:
	lea	fl_4_sort_st(pc),a0
	clr	(a0)
	lea	clear_st(pc),a0
	move	#1,(a0)
;-
	lea	fog_st(pc),a0
	move	#1,(a0)
	lea	fog_min(pc),a0
	move	#1300*4,(a0)
	lea	fog_max(pc),a0
	move	#1800*4,(a0)

	moveq	#0,d0
	moveq	#63,d1
	bsr	init_fogtab

	moveq	#64,d0
	moveq	#64+63,d1
	bsr	init_fogtab
;-

	lea	bbox_st,a0
	clr	(a0)

	lea	st_j(pc),a0
	lea	obj1004j(pc),a1
	move.l	a1,(a0)

	lea	t1_m1(pc),a0
	move.l	#obj1004m,(a0)

	lea	t1_m2(pc),a0
	move.l	#obj1004m2,(a0)

	lea	t1_m3(pc),a0
	move.l	#obj1004m3,(a0)

	lea	anim_obj_rout_p(pc),a0
	lea	anim1004(pc),a1
	move.l	a1,(a0)
	lea	anim_obj_adj_p(pc),a0
	lea	adj_anim1004(pc),a1
	move.l	a1,(a0)

;----
	move.l	dummymap_p(pc),a2
	bsr	clr_64k

	move.l	dummymap2_p(pc),a0
	move.l	marble_p(pc),a1
	bsr	cp_64k
;----
	move.l	furchen_map_p(pc),a0
	lea	bmap,a1
	bsr	bump2d
	bsr	corr_bmap

	moveq	#0,d0
	moveq	#0+64,d1
	bsr	init_gttab

	move.l	dummymap2_p(pc),a0
	bsr	bump_tex_pm
;----
	lea	rostgrau(pc),a0
	lea	obj2cols2(pc),a1
	moveq	#14,d4
	moveq	#63+1,d5
	bsr	ncalc_pal

	lea	milgruen(pc),a0
	lea	obj2cols2+64*4(pc),a1
	moveq	#12,d4
	moveq	#63+1,d5
	bsr	ncalc_pal
;-
	lea	t1_struct(pc),a0
	move	#o1004xa*o1004ya-1,(a0)+
	move	#(o1004xa-1)*(o1004ya-1)*2-1,(a0)

	move.l	t1_pkt_p(pc),a0
	move	#o1004x1,d3
	move	#o1004x2,d4
	
	move	#-(o1004x1+o1004x2)*o1004ya/2/2,d1
	moveq	#o1004ya-1,d6

.h2:	move	#-(o1004x1+o1004x2)*o1004xa/2/2,d0
	moveq	#o1004xa/2-1,d7

.h1:	move	d0,(a0)+
	move	d1,(a0)+
	clr	(a0)+
	add	#o1004x1,d0

	move	d0,(a0)+
	move	d1,(a0)+
	clr	(a0)+
	add	#o1004x2,d0
	dbf	d7,.h1
	add	d3,d1
	exg	d3,d4
	dbf	d6,.h2
;-
	move.l	t1_tab_p(pc),a0
	moveq	#1,d0
	bsr.w	o22_1side


o1004rest:
	move.l	t1_tl_p(pc),a1
	lea	t1_tl(pc),a0
	move.l	a1,(a0)

	move.l	t1_pkt_p(pc),a4
	move.l	t1_tab_p(pc),a5

	lea	t_texmap.w,a0

	moveq	#(o1004ya-1)-1,d7
.aa:	moveq	#(o1004xa-1)-1,d6
.a:	move.l	dummymap_p(pc),a6
;	move.l	cloud64_p(pc),d5
	move.l	dummymap2_p(pc),d5
	moveq	#1,d2		; xl
	moveq	#1,d3		; yo
	lea	158.w,a2	; xr
	move	ysize_scr(pc),d0
	lsr	#1,d0
	subq	#2,d0
	move	d0,a3		; yu

	bsr	do_124_234
	lea	3*2*2(a5),a5
	exg	d5,a6

	subq	#1,d6
	bmi.s	.w

	bsr.w	zierrahmen

	dbf	d6,.a
.w:
	subq	#1,d7
	bmi.s	.w2

	moveq	#(o1004xa-1)-1,d6
	move.l	cloud64_p(pc),d5
.h1	bsr	zierrahmen
	dbf	d6,.h1

	dbf	d7,.aa
.w2:
;-
	rts

;-
o22_1side:
	move	d0,d3
	add	#o1004xa,d3

	moveq	#o1004ya-2,d7
.t2:	moveq	#o1004xa-2,d2

.t1:	move	d0,(a0)+
	addq	#1,d0
	move	d0,(a0)+
	move	d3,(a0)+

	move	d0,(a0)+
	move	d3,2(a0)
	addq	#1,d3
	move	d3,(a0)+
	addq.l	#2,a0
	dbf	d2,.t1

	addq	#1,d0
	addq	#1,d3
	dbf	d7,.t2
	rts
;-

do_124_234:
	move	a0,(a1)+
	move.l	a6,(a1)+

	move	d2,(a1)+
	move	d3,(a1)+

	move	a2,(a1)+
	move	d3,(a1)+

	move	d2,(a1)+
	move	a3,(a1)+

	move	a0,(a1)+
	move.l	a6,(a1)+

	move	a2,(a1)+
	move	d3,(a1)+

	move	a2,(a1)+
	move	a3,(a1)+

	move	d2,(a1)+
	move	a3,(a1)+
	rts
;--

;----------------------------

anim1000:
	move.l	pointsp201(pc),a1
	lea	slideoff201(pc),a3
	move.l	pointsp202(pc),a2
	lea	slideoff202(pc),a4
	moveq	#12*2,d0
	bra	rotmove_obj_n

;-----

adj_anim1000:
	lea	slide201(pc),a1
	moveq	#2-1,d7
	bsr	adj_okeys
;-
	lea	st_odl+1*12(pc),a0
	move.l	koordxyz_sp_p(pc),a1
	move	(a0)+,d7
	addq.l	#2,a1
	move.l	(a0)+,d0
	add.l	d0,a1

	lea	.cnt2(pc),a6
	subq	#1,(a6)
	bgt.s	.h4
	beq.s	.cp

.fl	cmp	#o1000y+150*4,(a1)
	blt.s	.fl2
	sub	#12*4,(a1)
.fl2	addq.l	#6,a1
	dbf	d7,.fl
	rts

;-
.cp	lea	o1001o,a0
	subq.l	#2,a1
	move	#o1001-1,d7
.cp1	move.l	(a0)+,(a1)+
	move	(a0)+,(a1)+
	dbf	d7,.cp1
	rts

;-
.h4:	lea	.cnt(pc),a6
	subq	#1,(a6)
	bmi.s	.h2

.h1	move	(a1),d0
	add	#8*4+$380*4,d0
	and	#$1fff,d0
	sub	#$380*4,d0
	move	d0,(a1)
	addq.l	#6,a1
	dbf	d7,.h1
	rts
;-
.h2:	move	(a1),d0
	cmp	#$1fff-$280*4,d0
	bgt.s	.h3
	add	#8*4,d0
	move	d0,(a1)
.h3:	addq.l	#6,a1
	dbf	d7,.h2
	rts
;-

.cnt:	dc	17*50-25
.cnt2:	dc	24*50

;-------------

o1005	=	12

obj1005:
	lea	t1_struct(pc),a0
	move	#o1005-1,(a0)+
	move	#o1005-1,(a0)

;-
	move.l	t1_pkt_p(pc),a0
	clr	(a0)
	move	#400*4,2(a0)
	move	#-200*4,4(a0)

	lea	anzpkt(pc),a1
	clr	(a1)

	moveq	#o1005-1-1,d6
	move	#$2000/o1005,d5
	lea	6(a0),a1

.a:	lea	tg_rotangle(pc),a5
	clr	(a5)
	move	d5,2(a5)
	clr	4(a5)
	move.l	a1,-(a7)
	bsr	tg_rotyx		; Punkte rotieren
	move.l	(a7)+,a1
	lea	6(a1),a1
	add	#$2000/o1005,d5
	and	#$1ffe,d5
	dbf	d6,.a
	
	moveq	#o1005-1,d7
	bsr.w	o_flare_tab

;-
	move.l	t1_tl_p(pc),a1
	lea	t1_tl(pc),a0
	move	#o1005-1,d7
	move.l	a1,(a0)


.h3	move	#t_flare,(a1)+
	move.l	#rflare3,(a1)+
	move	#64,(a1)+
	move	#64,(a1)+
	dbf	d7,.h3	
;-
	moveq	#0,d0
	moveq	#0+63,d1
	moveq	#64,d5
	lea	(64+63).w,a6
	moveq	#63,d2
	moveq	#0,d6
	bsr	trans_limes3

	move.l	#128,d0
	move.l	#128+63,d1
	moveq	#64,d5
	lea	(64+63).w,a6
;	move.l	#128+63,d2
	move.l	d1,d2
;	move.l	#128,d6
	move.l	d0,d6
	bsr	trans_limes3

	move.l	#192,d0
	move.l	#192+63,d1
	moveq	#64,d5
	lea	(64+63).w,a6
;	move.l	#128+63,d2
	move.l	d1,d2
;	move.l	#128,d6
	move.l	d0,d6
	bsr	trans_limes3

	moveq	#64,d0
	moveq	#64+63,d1
	moveq	#64,d5
	lea	(64+63).w,a6
	moveq	#64+63,d2
	moveq	#64,d6
	bra	trans_limes3


yysize_c3	=	64
xsize_c3	=	64

fls:	dc.l	rflare3,rflare2

smooth64_64:
	lea	fls(pc),a2
	movem.l	(a2),a0-a1
	move.l	a1,(a2)+
	move.l	a0,(a2)

	lea	xsize_c3+1(a0),a0
	lea	xsize_c3+1(a1),a1
	move	#yysize_c3-2-1,d7
	moveq	#0,d1

.w	move	#xsize_c3-2-1,d6

.v	moveq	#0,d0
	move.b	-xsize_c3-1(a1),d0
	move.b	-xsize_c3(a1),d1
	add	d1,d0
	move.b	-xsize_c3+1(a1),d1
	add	d1,d0

	move.b	-1(a1),d1
	add	d1,d0
	move.b	1(a1),d1
	add	d1,d0

	move.b	xsize_c3-1(a1),d1
	add	d1,d0
	move.b	xsize_c3(a1),d1
	add	d1,d0
	move.b	xsize_c3+1(a1),d1
	add	d1,d0

	lsr	#3,d0
	addq.l	#1,a1
	move.b	d0,(a0)+
	dbf	d6,.v

	addq.l	#2,a1
	addq.l	#2,a0
	dbf	d7,.w


	rts

;-------------

o1006	=	8

obj1006:
	lea	t1_struct(pc),a0
	move	#o1006-1,(a0)+
	move	#o1006-1,(a0)

;-
	move.l	t1_pkt_p(pc),a0
	clr	(a0)
	move	#400*4,2(a0)
	move	#-100*4,4(a0)

	lea	anzpkt(pc),a1
	clr	(a1)

	moveq	#o1006-1-1,d6
	move	#$2000/o1006,d5
	lea	6(a0),a1

.a:	lea	tg_rotangle(pc),a5
	clr	(a5)
	move	d5,2(a5)
	clr	4(a5)
	move.l	a1,-(a7)
	bsr	tg_rotyx		; Punkte rotieren
	move.l	(a7)+,a1
	lea	6(a1),a1
	add	#$2000/o1006,d5
	and	#$1ffe,d5
	dbf	d6,.a
	
	moveq	#o1006-1,d7
	bsr.w	o_flare_tab

;-
	move.l	t1_tl_p(pc),a1
	lea	t1_tl(pc),a0
	move	#o1006-1,d7
	move.l	a1,(a0)

	lea	rflare3,a2

.h3	move	#t_flare,(a1)+
	move.l	a2,(a1)+
	move	#64,(a1)+
	move	#64,(a1)+
	dbf	d7,.h3	

	rts

;-------------

o1001	=	200		; Anzahl flares

obj1001:
	lea	t1_struct(pc),a0
	move	#o1001-1,(a0)+
	move	#o1001-1,(a0)

	move.l	t1_pkt_p(pc),a0
	move	#o1001-1,d7
.h1
	bsr	_x1_poetrnd
	and	#$7ff,d0
	sub	#$400,d0
	move	d0,(a0)+

	bsr	_x1_poetrnd
	and	#$1fff,d0
	sub	#$fff,d0
	move	d0,(a0)+

	bsr	_x1_poetrnd
	and	#$7ff,d0
	sub	#$400,d0
	move	d0,(a0)+
	
	dbf	d7,.h1

	move	#o1001-1,d7
	bsr.s	o_flare_tab

	move.l	t1_tl_p(pc),a1
	lea	t1_tl(pc),a0
	move	#o1001-1,d7
	move.l	a1,(a0)

.h3	move	#t_flare,(a1)+
	move.l	#rflare,(a1)+
	move	#62,(a1)+
	move	#62,(a1)+
	dbf	d7,.h3	

;---
	moveq	#0,d0
	moveq	#0+63,d1
	moveq	#0+63,d2
	moveq	#0,d5
	lea	(0+31).w,a6
	moveq	#0,d6
	bsr	trans_limes3

	moveq	#64,d0
	moveq	#64+63,d1
	moveq	#64+63,d2
	moveq	#0,d5
	lea	(0+31).w,a6
	moveq	#64,d6
	bsr	trans_limes3

	move.l	#128,d0
	move.l	#128+63,d1
	move.l	d1,d2
	moveq	#0,d5
	lea	(0+31).w,a6
;	move.l	#128,d6
	move.l	d0,d6
	bsr	trans_limes3

	move.l	#192,d0
	move.l	#192+63,d1
	move.l	d1,d2
	moveq	#0,d5
	lea	(0+31).w,a6
	move.l	d0,d6
	bra	trans_limes3

;----

o_flare_tab:
	move.l	t1_tab_p(pc),a0
	moveq	#1,d0
	
.h2	move	d0,(a0)+
	move	d0,(a0)+
	move	d0,(a0)+
	addq	#1,d0
	dbf	d7,.h2
	rts

;----------------------------

bump_tex_pm:
	lea	phong_map,a1
bump_tex:
	lea	gouraudtab,a6
	lea	bmap,a2
	
	moveq	#-1,d7
	moveq	#0,d0
	moveq	#0,d6
	
.a	move.l	d0,a5
	add	(a2)+,a5		; bumpmap
	move	(a1,a5.l),d6		; phong_map
	move.b	(a0),d6			; texture
	move.b	(a6,d6.l),d6
	addq.l	#1,d0
	move.b	d6,(a0)+
	dbf	d7,.a
	rts

;---------------

corr_bmap:
	lea	bmap,a0
	lea	256*2(a0),a1
	move	#256-1,d7
.wix3:	move	(a1)+,(a0)+
	dbf	d7,.wix3

	lea	bmap+(256*254*2),a1
	lea	256*2(a1),a0
	move	#256-1,d7
.wix4:	move	(a1)+,(a0)+
	dbf	d7,.wix4
	rts

;----------------

shade_dn:
	move.l	#$ff00,d0
shade_dn2:
	move.l	fogtab_p(pc),a1
.gg	move	#256-1,d7
.g	move.b	(a0),d0
	move.b	(a1,d0.l),(a0)+
	dbf	d7,.g
	sub	d4,d0
	dbf	d6,.gg
	rts

;----------

do_h1000:
.hc3	moveq	#256/4-1,d6
.hc2	move.l	d0,(a0)+
	dbf	d6,.hc2
	sub.l	d1,d0
	dbf	d7,.hc3
	rts

;-----

do_bmap_1:
	moveq	#-1,d0
do_bmap_x:
	move.l	a0,a1
	sub.l	#256*256,a0
	add.l	#256*256,a1
	move	#256*256/4-1,d7
.hc1	move.l	d0,(a0)+
	move.l	d0,(a1)+
	dbf	d7,.hc1
	rts

;----------------------------

;o1000r	=	1000*4		; Radius
o1000rs	=	16		; Segmente/umfang
o1000rr	=	10		; Unterteilungen von r
o1000y	=	-200*4
o1000w	=	3		; anzahl wandsegmente innen bzw. aussen
o1000wa	=	700*4		; hoehe eines wandsegmentes

o1000radtab:
	dc	0,0,0

	dc	2000*4,1500*4
	dc	1050*4,650*4
	dc	400*4

	dc	0,0,0

;----

chk_b:	cmp	#400*4,(a1)
	bgt.s	.a
	cmp	#-400*4,(a1)
	blt.s	.a
	tst	(a1)
	bpl.s	.hc
	sub	#400*4,(a1)
	bra.s	.a
.hc	add	#400*4,(a1)
.a	rts

;----

obj1000:
	lea	pointsp201(pc),a0
	move.l	#o14_o1,(a0)
	move.l	#o14_o1r,14*1(a0)

	lea	slide201(pc),a1
	moveq	#2-1,d7
	bsr	init_okeys

;---
	lea	poetrndseed(pc),a0
	move.l	#'anti',(a0)+
	move.l	#'byte',(a0)

	lea	o1001o,a0
	move	#o1001-1,d7
.hx1
	bsr	_x1_poetrnd
	moveq	#0,d2
	divs.l	#3200*4,d2:d0
	sub	#3200*4/2,d2
	move	d2,(a0)+

	bsr	_x1_poetrnd
	and	#$1fff,d0
;	sub	#$1000,d0
	add	#o1000y+50*4+2000*4,d0
	move	d0,(a0)+

	bsr	_x1_poetrnd
	moveq	#0,d2
	divs.l	#3200*4,d2:d0
	sub	#3200*4/2,d2
	move	d2,(a0)+

	cmp	#400*4,-6(a0)
	bgt.s	.hx2
	cmp	#-400*4,-6(a0)
	blt.s	.hx2
	cmp	#400*4,-2(a0)
	bgt.s	.hx2
	cmp	#-400*4,-2(a0)
	blt.s	.hx2
	lea	-6(a0),a1
	bsr	chk_b
	lea	-2(a0),a1
	bsr	chk_b

.hx2	dbf	d7,.hx1

;---

	lea	fl_4_sort_st(pc),a0
	move	#1,(a0)
	lea	clear_st(pc),a0
	move	#1,(a0)

	lea	bbox_st(pc),a0
	move	#1,(a0)
	lea	bbrad(pc),a0
	move.l	#(2700*4)^2,(a0)
	

	lea	t1_m1(pc),a0
	move.l	#obj1000m,(a0)

	lea	t1_m2(pc),a0
	move.l	#obj1000m2,(a0)

	lea	t1_m3(pc),a0
	move.l	#obj1000m3,(a0)

;-

	lea	anim_obj_rout_p(pc),a0
	lea	anim1000(pc),a1
	move.l	a1,(a0)
	lea	anim_obj_adj_p(pc),a0
	lea	adj_anim1000(pc),a1
	move.l	a1,(a0)

;-----
	move.l	dummymap4_p(pc),a1
	move.l	circle_p2(pc),a0
	move	#256*256/4-1,d7
.hq	move.l	(a0)+,d0
	lsr.l	#1,d0
	and.l	#$7f7f7f7f,d0
	add.l	#$c0c0c0c0,d0
	move.l	d0,(a1)+
	dbf	d7,.hq

;-----
	move.l	sin_map_p(pc),a0
	move.l	dummymap_p(pc),a1
	moveq	#-1,d7
.hr	move.b	(a0)+,d0
	cmp.b	#32,d0
	blt.s	.hs
	add	#32,d0
.hs	move.b	d0,(a1)+
	dbf	d7,.hr
;-
	move.l	marble_p(pc),a0
	move.l	dummymap2_p(pc),a1
	moveq	#-1,d7
.ht	move.b	(a0)+,d0
	lsr.b	#1,d0
	add.b	#128,d0
	move.b	d0,(a1)+
	dbf	d7,.ht

;-----
	move.l	marble_p(pc),a0
	lea	bmap,a1
	bsr	bump2d
	bsr	corr_bmap

	move.l	#128,d0
	move.l	#128+48,d1
	bsr	init_gttab

	move.l	dummymap2_p(pc),a0
	bsr	bump_tex_pm
;---
	move.l	dummymap3_p(pc),a0
	bsr	do_bmap_1

	move.l	#$c0c0c0c0,d0
	move	#256-(256-$c0)-1,d7
	move.l	#$01010101,d1
	bsr	do_h1000
	moveq	#256-$c0-1,d7
	neg.l	d1
	bsr	do_h1000

	moveq	#0,d0
	moveq	#0+31,d1
	bsr	init_gttab
	moveq	#64,d0
	moveq	#64+31,d1
	bsr	init_gttab

	move.l	dummymap_p(pc),a0
	move.l	dummymap3_p(pc),a1
	bsr	bump_tex

;-----

	moveq	#0,d0
	moveq	#63,d1
	bsr	init_fogtab
	moveq	#64,d0
	moveq	#127,d1
	bsr	init_fogtab
	move.l	#128,d0
	move.l	#128+63,d1
	bsr	init_fogtab

	move.l	dummymap_p(pc),a0
	move	#$1000,d4
	moveq	#16-1,d6
	bsr	shade_dn

	move.l	dummymap2_p(pc),a0
	add.l	#256*256-32*256,a0
	move	#-$1000/2,d4
	moveq	#0,d0
	moveq	#16*2-1,d6
	bsr	shade_dn2

	move.l	dummymap_p(pc),a0
	add.l	#256*256-128*256,a0
	move	#-$300,d4
	moveq	#0,d0
	moveq	#64*2-1,d6
	bsr	shade_dn2

	move.l	dummymap2_p(pc),a0
	moveq	#-1,d7
.hc1	move.b	(a0)+,d0
	cmp.b	#128,d0
	bne.s	.hc2
	clr.b	-1(a0)
.hc2	dbf	d7,.hc1
;-----
	lea	rostgrau(pc),a0
	lea	obj2cols2(pc),a1
	moveq	#18,d4
	moveq	#63+1,d5
	bsr	ncalc_pal

	lea	graulind(pc),a0
	lea	obj2cols2+64*4(pc),a1
	moveq	#16,d4
	moveq	#63+1,d5
	bsr	ncalc_pal

	lea	beige(pc),a0
	lea	obj2cols2+128*4(pc),a1
	moveq	#15,d4
	moveq	#63+1,d5
	bsr	ncalc_pal

	lea	gruengrau(pc),a0
	lea	obj2cols2+192*4(pc),a1
	moveq	#15,d4
	moveq	#63+1,d5
	bsr	ncalc_pal

;-
	lea	t1_struct(pc),a0
	move	#o1000rs*(o1000rr+1)-1,(a0)+
	move	#o1000rs*o1000rr*2-1,(a0)

	lea	anzpkt(pc),a0
	clr	(a0)

	moveq	#o1000rr,d0
;	move.l	#o1000r*$10000,d1
	move.l	t1_pkt_p(pc),a1
;	move.l	d1,d2
;	divs.l	#o1000rr+1,d2

	lea	o1000radtab(pc),a6

.aa:	move	(a6)+,d1
	movem.l	d0-d3/a6,-(a7)

	move.l	t2_pkt_p(pc),a0
	clr	(a0)+
	move	#o1000y,(a0)+
	move	d1,(a0)

	move.l	#$20000000,d4
	moveq	#o1000rs-1,d6
	divs.l	#o1000rs,d4
	moveq	#0,d5

.a:	move.l	t2_pkt_p(pc),a0
	lea	tg_rotangle(pc),a5
	swap	d5
	move	d5,2(a5)
	swap	d5
	clr	(a5)
	clr	4(a5)
	move.l	a1,-(a7)
	bsr	tg_rotyx		; Punkte rotieren
	move.l	(a7)+,a1
	addq.l	#6,a1
	add.l	d4,d5
	dbf	d6,.a

	movem.l	(a7)+,d0-d3/a6
;	sub.l	d2,d1
	dbf	d0,.aa
;-
	move.l	t1_tab_p(pc),a1
	moveq	#o1000rr-1,d6
	moveq	#1,d0
.e:	move.l	d0,d2
	moveq	#o1000rs-2,d7
.c	move	d0,(a1)+		; 143
	move.l	d0,d1
	add	#o1000rs,d1
	move	d1,(a1)+
	addq	#1,d1
	move	d1,(a1)+

	move	d0,(a1)+		; 132
	move	d1,(a1)+
	addq	#1,d0
	move	d0,(a1)+

	dbf	d7,.c

	move	d0,(a1)+
	move.l	d0,d1
	add	#o1000rs,d1
	move	d1,(a1)+
	move.l	d2,d1
	add	#o1000rs,d1
	move	d1,(a1)+

	move	d0,(a1)+
	move	d1,(a1)+
	move	d2,(a1)+
	
	addq	#1,d0
	dbf	d6,.e
;-
o1000rest:
	move.l	t1_tl_p(pc),a1
	lea	t1_tl(pc),a0
	move.l	a1,(a0)

	lea	t_texmap.w,a0
;	move.l	cloud64_p(pc),d5
	move.l	dummymap2_p(pc),d5

	lea	((256)/(o1000rs)*4).w,a4
	lea	((256-8)/(o1000w)).w,a5
	moveq	#4,d0

	moveq	#(o1000w)-1,d6
	bsr.s	.b

	lea	((256)/(o1000rs)).w,a4
	lea	((256-8)/(o1000rr-o1000w)).w,a5
	moveq	#4,d0

	move.l	dummymap_p(pc),d5
	moveq	#(o1000rr-o1000w)-1,d6
	bsr.s	.b

;---
	move.l	t1_pkt_p(pc),a0
	lea	o1000w*o1000rs*6(a0),a1
	move	#o1000y+o1000w*o1000wa,d0
	bsr.s	.j2

	move	t1_struct(pc),d0
	move.l	t1_pkt_p(pc),a0
	addq	#1,d0
	mulu	#6,d0
	lea	-o1000w*o1000rs*6(a0),a0
	add.l	d0,a0
	lea	-o1000rs*6(a0),a1
	move	#o1000y-o1000wa,d0


.j2	moveq	#o1000w-1,d6

.j	move.l	a1,a2
	moveq	#o1000rs-1,d7

.j1	move	(a2)+,(a0)+
	move	d0,(a0)+
	addq	#2,a2
	move	(a2)+,(a0)+
	dbf	d7,.j1

	add	#-o1000wa,d0
	dbf	d6,.j
	rts

;--
.b:	move.l	d5,a6

	moveq	#(o1000rs)-1,d7
	moveq	#4,d2		; xl
	move.l	d0,d3		; yo	
	lea	(a4,d2.l),a2	; xr
	lea	(a5,d3.l),a3	; yu	

.a:	bsr	do_143_132
	exg	d5,a6

	add.l	a4,d2
	add.l	a4,a2
	dbf	d7,.a
	exg	d5,a6
	add.l	a5,d0
	dbf	d6,.b
	rts
;----

do_143_132:
	move	a0,(a1)+
	move.l	a6,(a1)+

	move	d2,(a1)+
	move	d3,(a1)+

	move	d2,(a1)+
	move	a3,(a1)+

	move	a2,(a1)+
	move	a3,(a1)+

	move	a0,(a1)+
	move.l	a6,(a1)+

	move	d2,(a1)+
	move	d3,(a1)+

	move	a2,(a1)+
	move	a3,(a1)+

	move	a2,(a1)+
	move	d3,(a1)+
	rts

;-------------------
; Pentagram

o14r1p	dc.l	6
o14r2p	dc.l	12

obj14:	tst.b	o4o
	bne.s	.no3o
	lea	o14r1p+2(pc),a0
	move	#4,(a0)

.no3o:	lea	st_obj_map(pc),a0
;	move.l	cloud64_p(pc),(a0)
	move.l	dummymap4_p(pc),(a0)
	lea	st_obj_type(pc),a0
	move.l	#t_phong,(a0)
	lea	t1_tl(pc),a0
	clr.l	(a0)

;--
	move.l	o14r1p(pc),d0
	mulu	o14r2p+2(pc),d0
	add	#20,d0
	move	d0,d1
	add	d1,d1
	subq	#1,d0

	subq	#1,d1
	lea	t1_struct(pc),a0
	move	d0,(a0)+
	move	d1,(a0)+
		
	move.l	o14r1p(pc),d0
	move.l	o14r2p(pc),d1
	move.l	#20*4,d2
	move.l	#114*4,d3
	
	bsr	bf_torus_gen

	move.l	o14r1p(pc),d0
	mulu	o14r2p+2(pc),d0
	subq	#1,d0
	lea	anzpkt(pc),a0
	move	d0,(a0)
	move.l	t1_pkt_p(pc),a0
	lea	tg_rotangle(pc),a5
	move.l	a0,a1
	move.l	#$08000000,(a5)
	clr	4(a5)
	bsr	tg_rotyx		; Punkte rotieren

	move.l	t1_pkt_p(pc),a0
	move.l	o14r1p(pc),d0
	mulu	o14r2p+2(pc),d0
	mulu	#6,d0
	add	d0,a0
	lea	sternpkt(pc),a1
	moveq	#20*3-1,d7
o14_1:	move.b	(a1)+,d0
	ext	d0
	lsl	#subpixel,d0
	move	d0,(a0)+
	dbf	d7,o14_1

	move.l	t1_tab_p(pc),a0
	move.l	o14r1p(pc),d0
	mulu	o14r2p+2(pc),d0
	move.l	d0,d1
	mulu	#12,d0
	add	d0,a0
	lea	sterntab(pc),a1
	moveq	#40*3-1,d7
o14_2:	moveq	#0,d0
	move.b	(a1)+,d0
	add	d1,d0
	move	d0,(a0)+
	dbf	d7,o14_2

	rts

;-----------------------------------

;Stern
sto	=	 0	; o14r1*o14r2

sterntab:
 dc.b sto+1,sto+2,sto+3
 dc.b sto+11,sto+13,sto+12
 dc.b sto+3,sto+13,sto+11
 dc.b sto+1,sto+3,sto+11
 dc.b sto+1,sto+12,sto+2
 dc.b sto+11,sto+12,sto+1
 dc.b sto+2,sto+12,sto+13
 dc.b sto+3,sto+2,sto+13

 dc.b sto+4,sto+5,sto+2
 dc.b sto+14,sto+12,sto+15
 dc.b sto+2,sto+5,sto+15
 dc.b sto+15,sto+12,sto+2
 dc.b sto+2,sto+12,sto+14
 dc.b sto+4,sto+2,sto+14
 dc.b sto+5,sto+4,sto+14
 dc.b sto+14,sto+15,sto+5

 dc.b sto+6,sto+7,sto+5
 dc.b sto+15,sto+17,sto+16
 dc.b sto+5,sto+7,sto+17
 dc.b sto+17,sto+15,sto+5
 dc.b sto+6,sto+5,sto+15
 dc.b sto+15,sto+16,sto+6
 dc.b sto+7,sto+6,sto+16
 dc.b sto+16,sto+17,sto+7
 
 dc.b sto+8,sto+9,sto+7
 dc.b sto+18,sto+17,sto+19
 dc.b sto+7,sto+9,sto+19
 dc.b sto+19,sto+17,sto+7
 dc.b sto+9,sto+8,sto+18
 dc.b sto+18,sto+19,sto+9
 dc.b sto+8,sto+7,sto+17
 dc.b sto+17,sto+18,sto+8

 dc.b sto+10,sto+3,sto+9
 dc.b sto+20,sto+19,sto+13
 dc.b sto+10,sto+9,sto+19
 dc.b sto+19,sto+20,sto+10
 dc.b sto+9,sto+3,sto+13
 dc.b sto+13,sto+19,sto+9
 dc.b sto+3,sto+10,sto+20
 dc.b sto+20,sto+13,sto+3


; Stern
st= 15
sternpkt:
 dc.b 114-160,191-128,-st
 dc.b 159-160,159-128,-st
 dc.b 131-160,137-128,-st
 dc.b 205-160,191-128,-st
 dc.b 188-160,137-128,-st
 dc.b 234-160,104-128,-st
 dc.b 178-160,104-128,-st
 dc.b 159-160,50-128,-st
 dc.b 142-160,104-128,-st
 dc.b 85-160,104-128,-st

 dc.b 114-160,191-128,st
 dc.b 159-160,159-128,st
 dc.b 131-160,137-128,st
 dc.b 205-160,191-128,st
 dc.b 188-160,137-128,st
 dc.b 234-160,104-128,st
 dc.b 178-160,104-128,st
 dc.b 159-160,50-128,st
 dc.b 142-160,104-128,st
 dc.b 85-160,104-128,st

;---------------------------------------

o144_prep_txt:
	move.l	dummymap3_p(pc),a2
	bsr.w	clr_64k

	move.l	dummymap2_p(pc),a2
	bsr.w	clr_64k

	move.l	dummymap_p(pc),a2
	bsr.w	clr_64k

;-
	move.l	dummymap3_p(pc),a0
	lea	txt1000(pc),a1
	bsr	printtxt

	move.l	dummymap3_p(pc),a0
	move.l	a0,a1
	add.l	#128*256+20,a1
	move.l	a1,a2
	move.l	a1,a4

	moveq	#22-1,d0
.h6:	moveq	#22*5-1,d1
.h5:	move.b	(a0),(a1)+
	move.b	(a0)+,(a1)+
	dbf	d1,.h5
	lea	256-22*5*2+256(a1),a1
	lea	256-22*5(a0),a0
	dbf	d0,.h6

	lea	256(a2),a3
	moveq	#22-1,d0
.h8:	moveq	#22*5-1,d1
.h7:	move	(a2)+,(a3)+
	dbf	d1,.h7
	lea	256-22*5*2+256(a2),a2
	lea	256-22*5*2+256(a3),a3
	dbf	d0,.h8

	move.l	dummymap_p(pc),a0
	add.l	#156*256-10,a0
	moveq	#22*2-1,d0
.h10:	moveq	#256/4-1,d7
.h9:	move.l	(a4)+,(a0)+
	dbf	d7,.h9
	dbf	d0,.h10
;-
	moveq	#2-1,d0
.h1:	move.l	d0,-(a7)
	moveq	#5-1,d7
	lea	txt100(pc),a1
	lea	(4*256+2).w,a0
	move.b	#'1',(a1)
.a	movem.l	d7/a0/a1/a3,-(a7)

	add.l	cscrs+4(pc),a0

	bsr	printtxt
	movem.l	(a7),d7/a0/a1/a3
	addq.b	#1,(a1)
	lea	128(a0),a0

	add.l	cscrs+4(pc),a0
	bsr	printtxt

	movem.l	(a7)+,d7/a0/a1/a3
	addq.b	#1,(a1)
	lea	256*30(a0),a0

	dbf	d7,.a

	bsr	smooth
	lea	cscrs(pc),a0
	move.l	(a0),d0
	move.l	4(a0),(a0)
	move.l	d0,4(a0)
	move.l	(a7)+,d0
	dbf	d0,.h1

;-
	rts

;--

clr_64k:move	#256*256/16-1,d0
.a	clr.l	(a2)+
	clr.l	(a2)+
	clr.l	(a2)+
	clr.l	(a2)+
	dbf	d0,.a
	rts
;------------------------

o_tri:	move	d0,d3
	move	d1,d4
	neg	d3
	neg	d4

	move	d3,(a0)+
	move	d4,(a0)
	sub	d2,(a0)+
	move	d7,(a0)+
	
	move	d0,(a0)+
	move	d4,(a0)
	sub	d2,(a0)+
	move	d7,(a0)+

	move	d0,(a0)+
	move	d1,(a0)
	sub	d2,(a0)+
	move	d7,(a0)+

	move	d3,(a0)+
	move	d1,(a0)
	sub	d2,(a0)+
	move	d7,(a0)+

	rts
;--------------

ntrans_limes3:	jmp	trans_limes3

o1003x	=	172*4/2
o1003y	=	45*4/2

obj1003:
	lea	t1_struct(pc),a0
	move	#4-1,(a0)+
	move	#2-1,(a0)

	move.l	t1_pkt_p(pc),a0
	move	#o1003x,d0
	move	#o1003y,d1
	moveq	#0,d2
	moveq	#0,d7
;	move	#-600*4,d7
	bsr.s	o_tri

	move.l	t1_tab_p(pc),a0
	move.l	a0,a1
	move.l	#$10004,(a0)+
	move.l	#$30001,(a0)+
	move.l	#$30002,(a0)+

;-
	moveq	#0,d0
	moveq	#0+63,d1
	moveq	#0+63,d2
	moveq	#0,d5
	lea	(0+63).w,a6
	moveq	#0,d6
	bsr	ntrans_limes3

	move.l	#192,d0
	move.l	#192+63,d1
	move.l	d1,d2
	moveq	#0,d5
	lea	(0+63).w,a6
	move.l	d0,d6
	bsr	ntrans_limes3

	moveq	#64,d0
	move.l	#64+127,d1
	move.l	d1,d2
	moveq	#0,d5
	lea	(0+63).w,a6
	move.l	d0,d6
	bsr	ntrans_limes3
;-
	move.l	t1_tl_p(pc),a1
	lea	t1_tl(pc),a0
	move.l	a1,(a0)

	lea	t_transtexmap,a0
	move.l	dummymap_p(pc),a6

	moveq	#0,d2
	move	#201,d3
	lea	172.w,a2
	lea	156.w,a3
	bra	do_143_132
	
;--------------

o1002x	=	76*3*4/2
o1002y	=	30*3*4/2
o1002r	=	-360*4

obj1002:
	lea	t1_struct(pc),a0
	move	#4*9-1,(a0)+
	move	#2*9-1,(a0)

	move.l	t1_pkt_p(pc),a0
	move	#o1002x,d0
	move	#o1002y,d1
	move	#o1002r,d2
	move	#100*4,d7
	bsr.w	o_tri

;-
	move.l	t1_tab_p(pc),a0
	move.l	a0,a1
	move.l	#$10004,(a0)+
	move.l	#$30001,(a0)+
	move.l	#$30002,(a0)+

	moveq	#8*6-1,d7
.h2:	move	(a1)+,d0
	addq	#4,d0
	move	d0,(a0)+
	dbf	d7,.h2
;-
	move.l	t1_tl_p(pc),a1
	lea	t1_tl(pc),a0
	move.l	a1,(a0)

	move	#t_transtexmap,a0
	move.l	dummymap_p(pc),a6

	moveq	#5-1,d7
	moveq	#0,d2
	moveq	#30,d3
	lea	78.w,a2
	sub.l	a3,a3

.h1:	bsr	do_143_132
	add	#128,d2
	add	#128,a2
	bsr	do_143_132
	moveq	#0,d2
	sub	#128,a2

	add	#30,d3
	add	#30,a3
	dbf	d7,.h1
;-
	lea	anzpkt(pc),a0
	move	#4-1,(a0)
	move.l	t1_pkt_p(pc),a0

	moveq	#8-1,d6
	move	#-$2000/9&$1ffe,d5
	lea	4*6(a0),a1

.a:	lea	tg_rotangle(pc),a5
	clr.l	(a5)
	move	d5,4(a5)
	move.l	a1,-(a7)
	bsr	tg_rotyx		; Punkte rotieren
	move.l	(a7)+,a1
	lea	4*6(a1),a1
	sub	#$2000/9,d5
	and	#$1ffe,d5
	dbf	d6,.a
	
	rts

;--------------------

anim144:
	lea	objobjpos(pc),a0
	clr	(a0)+
	clr.l	(a0)+

	lea	o144ang(pc),a5
	lea	st_odl+2*12(pc),a0
	move	(a0)+,d7
	move.l	(a0)+,d0
	bsr	rot_p_k
;-

	lea	objobjpos(pc),a0
	clr.l	(a0)+
	move	#-300*4,(a0)+

	lea	o14ang(pc),a5
	lea	st_odl+0*12(pc),a0
	move	(a0)+,d7
	move.l	(a0)+,d0
	bsr	rot_p_k

	lea	o14ang(pc),a5
	lea	st_odl+0*12(pc),a0
	move	(a0)+,d7
	move.l	(a0)+,d0
	bsr	rot_p_n

	lea	o14ang(pc),a5
	lea	st_odl+1*12(pc),a0
	move	(a0)+,d7
	move.l	(a0)+,d0
	bsr	rot_p_k

;	lea	o14ang(pc),a5
;	lea	st_odl+1*12(pc),a0
;	move	(a0)+,d7
;	move.l	(a0)+,d0
;	bsr	rot_p_n

	move.l	pointsp144(pc),a1
	lea	objobjpos(pc),a4
	addq.l	#2,a1
	move.l	slideoff144(pc),d0
	bsr	do_spline

	lea	st_odl+3*12(pc),a0
	move.l	koordxyz2_p(pc),a2
	move.l	koordxyz_sp_p(pc),a1
	move	(a0)+,d7
	move.l	(a0)+,d0
	add.l	d0,a1
	add.l	d0,a2

	movem	objobjpos(pc),d3-d5

.ha	move	(a2)+,d0
	move	(a2)+,d1
	move	(a2)+,d2
	add	d3,d0
	add	d4,d1
	add	d5,d2
	move	d0,(a1)+
	move	d1,(a1)+
	move	d2,(a1)+
	dbf	d7,.ha


	lea	bgmap,a1
	bra	copy_clear2

;--

adj_anim144:
	lea	o144ang+4(pc),a0
	add	#8,(a0)
	and	#$1ffe,(a0)

	lea	o14ang+2(pc),a0
	add	#16,(a0)
	and	#$1ffe,(a0)

	lea	slide144(pc),a1
	lea	pointsp144(pc),a0
	lea	slideadd144(pc),a2
	lea	slideoff144(pc),a3
	bsr	adj_t_spline

	bra	fade2_n_fro

;--

slide144:	dc	0
pointsp144:	dc.l	o144_o1
slideadd144:	dc.l	0
slideoff144:	dc.l	0


o14ang:	dc	$2000-$300,0,0
o144ang:	dc	0,0,0

;-------

cp_64k:	moveq	#0,d1
cp_add:	move	#256*256/4-1,d7
.ha	move.l	(a1)+,d0
	add.l	d1,d0
	move.l	d0,(a0)+
	dbf	d7,.ha
	rts

;------

o144r1p	dc.l	6
o144r2p	dc.l	12

obj144:
	lea	pointsp144(pc),a0
	lea	slide144(pc),a1
	lea	slideadd144(pc),a2
	lea	slideoff144(pc),a3
	moveq	#8,d1
	jsr	get_k

;---
	tst.b	o4o
	bne.s	.no3o
	lea	o144r1p+2(pc),a0
	move	#4,(a0)

.no3o:
	bsr	o144_prep_txt

	clr	fl_4_sort_st
	move	#1,clear_st
;-
	lea	bgmap,a0
	move.l	sm_map_p(pc),a1
	move	#yysize-1,d7
	move.l	#$7f7f7f7f,d4

.hs1	moveq	#256/4-1,d6
	move.l	a1,a2
.hs2	move.l	(a1)+,d0
	lsr.l	#1,d0
	and.l	d4,d0
	move.l	d0,(a0)+
	dbf	d6,.hs2
	moveq	#(320-256)/4-1,d6
.hs3	move.l	(a2)+,d0
	lsr.l	#1,d0
	and.l	d4,d0
	move.l	d0,(a0)+
	dbf	d6,.hs3
	dbf	d7,.hs1
;---

	lea	t1_m1(pc),a0
	move.l	#o144m,(a0)

	lea	anim_obj_rout_p(pc),a0
	lea	anim144(pc),a1
	move.l	a1,(a0)
	lea	anim_obj_adj_p(pc),a0
	lea	adj_anim144(pc),a1
	move.l	a1,(a0)

;---
	move.l	dummymap2_p(pc),a0
	move.l	marble_p(pc),a1
	move.l	#$40404040,d1
	bsr.w	cp_add
;-
	move.l	dummymap3_p(pc),a0
	move.l	cloud64_p(pc),a1
	move.l	#$c0c0c0c0,d1
	bsr.w	cp_add	

;---
	lea	braungruen(pc),a0
;	lea	obj2cols2(pc),a1
	lea	colsl(pc),a1
	moveq	#12,d4
	moveq	#63+1,d5
	bsr	ncalc_pal

	lea	gruengrau(pc),a0
;	lea	obj2cols2+64*4(pc),a1
	lea	colsl+64*4(pc),a1
	moveq	#12,d4
	moveq	#64+16+1,d5
	bsr	ncalc_pal

	lea	gruengrauweiss(pc),a0
;	lea	obj2cols2+64*4+(64+16)*4(pc),a1
	lea	colsl+64*4+(64+16)*4(pc),a1
	moveq	#4,d4
	moveq	#(63+1)-16,d5
	bsr	ncalc_pal

	lea	rostbraun(pc),a0
;	lea	obj2cols2+192*4(pc),a1
	lea	colsl+192*4(pc),a1
	moveq	#26,d4
	moveq	#63+1,d5
	bsr	ncalc_pal

;---
	lea	fade_amount(pc),a6
	move	#256,(a6)
	lea	fade_step(pc),a6
	move	#100,(a6)

	lea	obj2cols2(pc),a0
	lea	colsl(pc),a1
	bsr	fade_init

	lea	fade2_n_fro\.dir(pc),a0
	clr	(a0)+
	move	#5*50,(a0)+
	move	#100,(a0)
;-------

	move.l	o144r1p(pc),d0
	mulu	o144r2p+2(pc),d0
	add	#20,d0
	move	d0,d1
	add	d1,d1
	subq	#1,d0

	subq	#1,d1
	lea	t1_struct(pc),a0
	move	d0,(a0)+
	move	d1,(a0)+
		
	move.l	o144r1p(pc),d0
	move.l	o144r2p(pc),d1
	moveq	#20*4,d2
	move.l	#114*4,d3
	
	bsr	bf_torus_gen

	move.l	o144r1p(pc),d0
	mulu	o144r2p+2(pc),d0
	subq	#1,d0
	lea	anzpkt(pc),a0
	move	d0,(a0)
	move.l	t1_pkt_p(pc),a0
	lea	tg_rotangle(pc),a5
	move.l	a0,a1
	move.l	#$08000000,(a5)
	clr	4(a5)
	bsr	tg_rotyx		; Punkte rotieren

	move.l	t1_pkt_p(pc),a0
	move.l	o144r1p(pc),d0
	mulu	o144r2p+2(pc),d0
	mulu	#6,d0
	add	d0,a0
	lea	sternpkt(pc),a1
	moveq	#20*3-1,d7
o144_1:	move.b	(a1)+,d0
	ext	d0
	lsl	#subpixel,d0
	move	d0,(a0)+
	dbf	d7,o144_1

	move.l	t1_tab_p(pc),a0
	move.l	o144r1p(pc),d0
	mulu	o144r2p+2(pc),d0
	move.l	d0,d1
	mulu	#12,d0
	add	d0,a0
	lea	sterntab(pc),a1
	moveq	#40*3-1,d7
o144_2:	moveq	#0,d0
	move.b	(a1)+,d0
	add	d1,d0
	move	d0,(a0)+
	dbf	d7,o144_2

	move.l	t1_tl_p(pc),a1
	lea	t1_tl(pc),a0
	move.l	a1,(a0)

	lea	t_phong_tmap.w,a0
;	lea	t_gouraud_tmap.w,a0
	move.l	dummymap2_p(pc),a6

	move	t1_struct+2(pc),d7
	move.l	t1_pkt_p(pc),a2
	move.l	t1_tab_p(pc),a3

.ag	move	a0,(a1)+
	move.l	a6,(a1)+

	moveq	#3-1,d6
.ag2	move	(a3)+,d0
	subq	#1,d0
	mulu	#6,d0
	move.l	(a2,d0.l),d0
	move.l	d0,(a1)+
	dbf	d6,.ag2
	move.l	#phong_map,(a1)+
	dbf	d7,.ag
	
	moveq	#64,d0
	move	#64*2+63,d1
	jmp	init_gttab

;-----------

o21y	=	4
o21x	=	8


obj21:
	moveq	#o21x,d0
	moveq	#o21y,d1
	moveq	#10*2^subpixel,d2
	move.l	#40*2^subpixel,d3
	move.l	#150*2^subpixel,d4
	moveq	#%10,d7

	bsr	do_spikes

	lea	t1_tl(pc),a0
	move.l	t1_tl_p(pc),a1
	move.l	a1,(a0)

	lea	t_texmap.w,a0
	move.l	dummymap3_p(pc),a6
	move	t1_struct+2(pc),d7

	move.l	#(20+20)*$10000+0+20,d0
	move.l	#(0+20)*$10000+40+20,d1
	move.l	#(40+20)*$10000+40+20,d2

.a:	move	a0,(a1)+
	move.l	a6,(a1)+

	move.l	d0,(a1)+
	move.l	d1,(a1)+
	move.l	d2,(a1)+

	dbf	d7,.a
	rts

;-----------

anim1444:
	lea	objobjpos(pc),a0
	lea	.z(pc),a1
	clr.l	(a0)+
	move	(a1),(a0)+
	addq	#1,(a1)

	lea	o14ang4(pc),a5
	lea	st_odl+0*12(pc),a0
	move	(a0)+,d7
	move.l	(a0)+,d0
	bsr	rot_p_k

	lea	o14ang4(pc),a5
	lea	st_odl+0*12(pc),a0
	move	(a0)+,d7
	move.l	(a0)+,d0
	bsr	rot_p_n

	lea	o14ang42(pc),a5
	lea	st_odl+1*12(pc),a0
	move	(a0)+,d7
	move.l	(a0)+,d0
	bra	rot_p_k

.z	dc	400*4

adj_anim1444:
	lea	o14ang4(pc),a0
	add	#6,(a0)
	and	#$1ffe,(a0)
	add	#16,2(a0)
	and	#$1ffe,2(a0)
	add	#8,4(a0)
	and	#$1ffe,4(a0)

	lea	o14ang42(pc),a0
	add	#-6,(a0)
	and	#$1ffe,(a0)
	add	#-16,2(a0)
	and	#$1ffe,2(a0)
	add	#-8,4(a0)
	and	#$1ffe,4(a0)
	rts

o14ang4:	dc	0,0,0
o14ang42:	dc	0,0,0

;----

o1444_prep_txt:
	move.l	dummymap2_p(pc),a2
	lea	cscrs(pc),a0
	move.l	a2,(a0)
	bsr.w	clr_64k

	move.l	dummymap1_p(pc),a2
	lea	cscrs+4(pc),a0
	move.l	a2,(a0)
	bsr.w	clr_64k
;-
	lea	addtxt(pc),a0
	moveq	#2-1,d0
	move	#63-1,(a0)

.h1	move.l	d0,-(a7)

	move	#(30*0+10)*256+10,a0
	lea	txt12(pc),a1
	bsr.s	.ptd3

	bsr	smooth
	lea	cscrs(pc),a0
	move.l	(a0),d0
	move.l	4(a0),(a0)
	move.l	d0,4(a0)
	move.l	(a7)+,d0
	dbf	d0,.h1
	rts

.ptd3:	bra	ptd3

;------

o1444m:
	dc	0,	0,0,-150*4
	dc	0,	0,0,-150*4
	dc	0,	0,0,-150*4
	dc	0,	0,0,-150*4
	dc	0,	0,0,-150*4
	dc	-1

o1444r1p	dc.l	6
o1444r2p	dc.l	12

obj1444:
	bsr	o1444_prep_txt

	tst.b	o4o
	bne.s	.no3o
	lea	o1444r1p+2(pc),a0
	move	#4,(a0)

.no3o:
	clr	fl_4_sort_st
	clr	clear_st

	lea	t1_m1(pc),a0
	lea	o1444m(pc),a1
	move.l	a1,(a0)

	lea	t1_m2(pc),a0
	clr.l	(a0)

	lea	t1_m3(pc),a0
	clr.l	(a0)

	lea	anim_obj_rout_p(pc),a0
	lea	anim1444(pc),a1
	move.l	a1,(a0)
	lea	anim_obj_adj_p(pc),a0
	lea	adj_anim1444(pc),a1
	move.l	a1,(a0)

;---
	move.l	dummymap2_p(pc),a0
	move.l	marble_p(pc),a1
	bsr.w	cp_64k

	move.l	dummymap3_p(pc),a0
	move.l	cloud64_p(pc),a1
	move.l	#$80808080,d1
	bsr.w	cp_add	
;---

	lea	gruengrau(pc),a0
	lea	obj2cols2(pc),a1
	moveq	#12,d4
	moveq	#64+16+1,d5
	bsr	ncalc_pal

	lea	gruengrauweiss(pc),a0
	lea	obj2cols2+(64+16)*4(pc),a1
	moveq	#4,d4
	moveq	#(63+1)-16,d5
	bsr	ncalc_pal

	lea	milgruen(pc),a0
	lea	obj2cols2+128*4(pc),a1
	moveq	#14,d4
	moveq	#63+1,d5
	bsr	ncalc_pal

;-------

	move.l	o1444r1p(pc),d0
	mulu	o1444r2p+2(pc),d0
	add	#20,d0
	move	d0,d1
	add	d1,d1
	subq	#1,d0

	subq	#1,d1
	lea	t1_struct(pc),a0
	move	d0,(a0)+
	move	d1,(a0)+
		
	move.l	o1444r1p(pc),d0
	move.l	o1444r2p(pc),d1
	moveq	#20*4,d2
	move.l	#114*4,d3
	
	bsr	bf_torus_gen

	move.l	o1444r1p(pc),d0
	mulu	o1444r2p+2(pc),d0
	subq	#1,d0
	lea	anzpkt(pc),a0
	move	d0,(a0)
	move.l	t1_pkt_p(pc),a0
	lea	tg_rotangle(pc),a5
	move.l	a0,a1
	move.l	#$08000000,(a5)
	clr	4(a5)
	bsr	tg_rotyx		; Punkte rotieren

	move.l	t1_pkt_p(pc),a0
	move.l	o1444r1p(pc),d0
	mulu	o1444r2p+2(pc),d0
	mulu	#6,d0
	add	d0,a0
	lea	sternpkt(pc),a1
	moveq	#20*3-1,d7
.o144_1:
	move.b	(a1)+,d0
	ext	d0
	lsl	#subpixel,d0
	move	d0,(a0)+
	dbf	d7,.o144_1

	move.l	t1_tab_p(pc),a0
	move.l	o1444r1p(pc),d0
	mulu	o1444r2p+2(pc),d0
	move.l	d0,d1
	mulu	#12,d0
	add	d0,a0
	lea	sterntab(pc),a1
	moveq	#40*3-1,d7
.o144_2:
	moveq	#0,d0
	move.b	(a1)+,d0
	add	d1,d0
	move	d0,(a0)+
	dbf	d7,.o144_2

	move.l	t1_tl_p(pc),a1
	lea	t1_tl(pc),a0
	move.l	a1,(a0)

	lea	t_phong_tmap.w,a0
;	lea	t_gouraud_tmap.w,a0
	move.l	dummymap2_p(pc),a6

	move	t1_struct+2(pc),d7
	move.l	t1_pkt_p(pc),a2
	move.l	t1_tab_p(pc),a3

.ag	move	a0,(a1)+
	move.l	a6,(a1)+

	moveq	#3-1,d6
.ag2	move	(a3)+,d0
	subq	#1,d0
	mulu	#6,d0
	move.l	(a2,d0.l),d0
	move.l	d0,(a1)+
	dbf	d6,.ag2
	move.l	#phong_map,(a1)+
	dbf	d7,.ag
	
	moveq	#0,d0
	moveq	#0+127,d1
	moveq	#0,d5
	lea	(0+63).w,a6
	moveq	#0,d6
;	move.l	#128,d6
	move.l	d1,d2
	bsr	ntrans_limes2

	move.l	#128,d0
	move.l	#128+63,d1
	moveq	#0,d5
	lea	(0+63).w,a6
	move.l	d0,d6
	move.l	d1,d2
	bsr	ntrans_limes2

	move.l	addtab_p,a0
	moveq	#0,d0
	move	#256-1,d7
.l	move.b	d0,(a0)
	lea	256(a0),a0
	addq	#1,d0
	dbf	d7,.l

	moveq	#0,d0
	move	#64*1+63,d1
	jmp	init_gttab

;------------------------------------

coli

rostgrau:	; !
	dc	0,0
	dc	$110,$426
	DC.B	$02,$21,$08,$4C,$03,$32,$08,$48
	DC.B	$04,$43,$04,$48,$05,$54,$04,$4C
	DC.B	$06,$65,$00,$4C,$07,$76,$00,$4C
	DC.B	$07,$88,$0C,$40,$08,$99,$0C,$40
	DC.B	$09,$AA,$08,$00,$0A,$BB,$0C,$00
	DC.B	$0C,$CC,$00,$00,$0D,$DD,$00,$00
	DC.B	$0E,$ED,$04,$0C,$0F,$FE,$04,$0C
	DC.B	$0F,$FF,$0C,$CC,$0F,$FF,$0C,$CC


	dc	0,0
graulind:	; !
	DC.B	$00,$00,$0a,$aa,$01,$11,$04,$44
	DC.B	$03,$33,$00,$00,$04,$44,$08,$88
	DC.B	$06,$66,$00,$00,$07,$77,$08,$88
	DC.B	$08,$88,$04,$44,$09,$9A,$0C,$C8
	DC.B	$0A,$AA,$0C,$CC,$0B,$CB,$04,$44
	DC.B	$0C,$CC,$08,$88,$0C,$CE,$0C,$CC
	DC.B	$0E,$EE,$00,$00,$0E,$EE,$0C,$CC
	DC.B	$0F,$FF,$0C,$CC,$0F,$FF,$0C,$CC


;himmelblau:	; 16
;	DC.W	$0000,$0080,$0000,$0000,$0001,$0000,$0013,$0CC0
;	DC.W	$0135,$0C80,$0257,$0C40,$0379,$0C00,$048B,$0CC0
;	DC.W	$05AD,$0C80,$06CF,$0C40,$08CF,$04C0,$09DF,$0C44
;	DC.W	$0BEF,$0404,$0CEF,$0C88,$0EFF,$0408,$0FFF,$0CCC

braungruen:	; 12 !
	DC.B	$00,$00,$00,$00,$01,$00,$04,$40
	DC.B	$01,$10,$04,$4C,$02,$21,$04,$8C
	DC.B	$03,$32,$08,$88,$04,$43,$08,$44
	DC.B	$05,$53,$08,$0C,$06,$65,$08,$88
	DC.B	$07,$77,$04,$C0,$08,$88,$08,$C0
	DC.B	$09,$99,$08,$C0,$0A,$AA,$08,$C0

;tuerkisbeige:	; 32
;	DC.B	$00,$00,$00,$80,$00,$00,$00,$C0
;	DC.B	$00,$10,$00,$44,$01,$10,$00,$C8
;	DC.B	$02,$21,$04,$80,$03,$31,$08,$04
;	DC.B	$04,$31,$0C,$8C,$05,$42,$0C,$00
;	DC.B	$06,$52,$04,$08,$06,$63,$0C,$04
;	DC.B	$07,$74,$04,$40,$08,$84,$00,$0C
;	DC.B	$08,$85,$0C,$88,$09,$96,$08,$44
;	DC.B	$0A,$96,$00,$CC,$0A,$A7,$04,$00
;	DC.B	$0A,$A7,$08,$88,$0A,$A8,$08,$C0
;	DC.B	$0A,$B8,$0C,$48,$0A,$B9,$0C,$80
;	DC.B	$0B,$C9,$00,$08,$0B,$C9,$00,$4C
;	DC.B	$0B,$CA,$04,$C4,$0B,$DA,$04,$0C
;	DC.B	$0B,$DB,$04,$44,$0B,$DB,$08,$CC
;	DC.B	$0B,$EC,$08,$00,$0B,$EC,$0C,$88
;	DC.B	$0B,$ED,$0C,$C0,$0C,$FD,$00,$48
;	DC.B	$0C,$FE,$00,$80,$0C,$FE,$00,$C4


stahlblau:	; 12 !
	DC.B	$00,$00,$00,$00,$00,$00,$00,$08
	DC.B	$00,$11,$00,$08,$01,$22,$00,$48
	DC.B	$02,$33,$04,$44,$03,$44,$04,$00
	DC.B	$04,$44,$04,$C8,$05,$66,$04,$44
	DC.B	$06,$77,$00,$8C,$07,$88,$04,$8C
	DC.B	$08,$99,$04,$8C,$09,$AA,$04,$8C
	dc	$abb,$48c,$bcc,$48c
	dc	$cdd,$48c,$dee,$48c

;goldgelb:	; 8
;	DC.B	$00,$00,$00,$00,$07,$31,$04,$84
;	DC.B	$08,$51,$08,$00,$09,$60,$0C,$8C
;	DC.B	$0A,$70,$0C,$C8,$0C,$90,$00,$44
;	DC.B	$0D,$A0,$04,$C0,$0E,$C0,$04,$00
;
;dunkelrot:	; 16
;	DC.B	$01,$00,$00,$40,$01,$00,$0C,$84
;	DC.B	$02,$00,$04,$C8,$03,$10,$00,$08
;	DC.B	$03,$10,$08,$4C,$04,$11,$04,$80
;	DC.B	$04,$11,$0C,$C0,$05,$21,$08,$04
;	DC.B	$06,$21,$00,$08,$06,$21,$0C,$48
;	DC.B	$07,$21,$04,$8C,$08,$22,$00,$C0
;	DC.B	$08,$32,$08,$00,$09,$32,$04,$44
;	DC.B	$09,$32,$0C,$88,$0A,$32,$04,$88
;
gruenbeige:	; militarygruen-beige 16
	DC.B	$00,$00,$00,$00,$00,$00,$0C,$C8
	DC.B	$01,$10,$08,$8C,$02,$21,$00,$44
	DC.B	$03,$32,$00,$40,$04,$42,$00,$48
	DC.B	$04,$53,$0C,$00,$05,$53,$0C,$CC
	DC.B	$06,$64,$08,$88,$07,$75,$04,$00
	DC.B	$08,$85,$04,$0C,$09,$86,$04,$CC
	DC.B	$0A,$97,$04,$C8,$0B,$A8,$04,$84
	DC.B	$0C,$B9,$04,$40,$0D,$B9,$00,$C8
	dc	$0fdb,$0c8
;
;
;silberweiss:	; 32
;	DC.B	$00,$00,$00,$00,$00,$00,$00,$00
;	DC.B	$00,$00,$00,$00,$00,$00,$00,$04
;	DC.B	$00,$00,$04,$88,$00,$11,$0C,$00
;	DC.B	$01,$11,$04,$88,$01,$22,$0C,$00
;	DC.B	$02,$22,$00,$84,$03,$33,$04,$84
;	DC.B	$04,$44,$04,$84,$05,$55,$04,$80
;	DC.B	$06,$66,$04,$C0,$07,$77,$08,$C0
;	DC.B	$08,$88,$08,$C0,$09,$99,$08,$C0
;	DC.B	$0A,$A9,$00,$48,$0A,$AA,$08,$80
;	DC.B	$0A,$BA,$0C,$08,$0B,$BA,$04,$4C
;	DC.B	$0B,$BB,$08,$C4,$0C,$CB,$00,$0C
;	DC.B	$0C,$CC,$04,$80,$0C,$CC,$0C,$C8
;	DC.B	$0D,$DD,$04,$40,$0D,$DD,$08,$84
;	DC.B	$0E,$ED,$00,$0C,$0E,$EE,$04,$44
;	DC.B	$0E,$EE,$0C,$C8,$0F,$FF,$00,$00
;	DC.B	$0F,$FF,$08,$88,$0F,$FF,$0C,$CC
;
;
;dblaut:		; blau->tuerkis dunkel 8
;	DC.B	$00,$00,$00,$00,$00,$00,$00,$00
;	DC.B	$00,$12,$0C,$04,$01,$23,$0C,$80
;	DC.B	$03,$44,$04,$00,$04,$46,$08,$C0
;	DC.B	$05,$66,$04,$88,$06,$76,$04,$48
;;	dc	$787,$448,$898,$448
;;	dc	$9a9,$448,$aba,$448
;;	dc	$bcb,$448,$cdc,$448
;;	dc	$ded,$448,$efe,$448

beige:		; 12 !
	DC.B	$00,$00,$00,$00,$00,$00,$00,$80
	DC.B	$01,$21,$0C,$04,$03,$32,$04,$48
	DC.B	$04,$43,$0C,$8C,$06,$64,$04,$0C
	DC.B	$07,$76,$0C,$40,$09,$87,$08,$84
	DC.B	$0B,$A8,$00,$04,$0C,$B9,$08,$48
	DC.B	$0E,$CA,$00,$8C,$0F,$DB,$08,$CC
	dc	$fec,$8cc,$ffd,$8cc,$fff,$fff

gruengrau:	; 12	!
	DC.B	$00,$00,$00,$00,$00,$00,$04,$CC
	DC.B	$01,$21,$08,$0C,$02,$32,$08,$0C
	DC.B	$03,$43,$08,$08,$04,$54,$0C,$08
	DC.B	$05,$65,$0C,$08,$06,$76,$0C,$04
	DC.B	$07,$87,$0C,$44,$09,$98,$00,$44
	DC.B	$0A,$A9,$00,$44,$0B,$BA,$00,$44
gruengrauweiss:
	dc	$0ccb,$44,$ddc,$44
	dc	$eed,$44,$fff,$fff

;silbergrau:	; 16
;	DC.B	$00,$00,$00,$00,$01,$11,$04,$44
;	DC.B	$02,$22,$04,$44,$03,$33,$04,$44
;	DC.B	$04,$44,$04,$44,$05,$55,$04,$44
;	DC.B	$06,$66,$08,$88,$07,$77,$08,$88
;	DC.B	$08,$88,$08,$88,$09,$99,$08,$88
;	DC.B	$0A,$AA,$08,$88,$0B,$BB,$0C,$CC
;	DC.B	$0C,$CC,$0C,$CC,$0D,$DD,$0C,$CC
;	DC.B	$0E,$EE,$0C,$CC,$0F,$FF,$0C,$CC
;
;
;lachs:		; seltsam 32
;	DC.B	$00,$11,$00,$CC,$00,$00,$00,$44
;	DC.B	$01,$11,$00,$00,$02,$11,$0C,$C8
;	DC.B	$04,$22,$04,$C0,$05,$32,$08,$44
;	DC.B	$06,$32,$0C,$CC,$07,$43,$0C,$40
;	DC.B	$08,$53,$04,$48,$08,$64,$0C,$44
;	DC.B	$09,$75,$04,$80,$0A,$85,$00,$4C
;	DC.B	$0A,$86,$0C,$C8,$0B,$97,$08,$84
;	DC.B	$0C,$A7,$00,$0C,$0C,$A8,$04,$40
;	DC.B	$0C,$A8,$08,$C8,$0C,$B9,$08,$00
;	DC.B	$0C,$B9,$0C,$88,$0C,$BA,$0C,$C0
;	DC.B	$0D,$CA,$00,$48,$0D,$CA,$00,$8C
;	DC.B	$0D,$DB,$04,$04,$0D,$DB,$04,$4C
;	DC.B	$0D,$DC,$04,$84,$0D,$EC,$08,$0C
;	DC.B	$0D,$ED,$08,$40,$0D,$ED,$0C,$C8
;	DC.B	$0D,$FE,$0C,$00,$0D,$FE,$0C,$88
;	DC.B	$0D,$FF,$0C,$C0,$0D,$FF,$0C,$C4


milgruen:	; military gruen 12
	DC.B	$00,$00,$04,$C0,$01,$21,$08,$04
	DC.B	$02,$32,$08,$04,$03,$43,$0C,$04
	DC.B	$04,$54,$0C,$44,$05,$65,$0C,$44
	DC.B	$07,$76,$00,$48,$08,$87,$00,$48
	DC.B	$09,$98,$00,$88,$0A,$A9,$04,$88
	DC.B	$0B,$BA,$04,$88,$0C,$CB,$04,$88
	dc	$ddc,$488,$eed,$488
	
rostbraun:	; !
	DC.B	$00,$00,$00,$C0,$02,$11,$00,$C0
	DC.B	$02,$22,$0C,$C0,$03,$33,$0C,$C0
	DC.B	$04,$43,$08,$8C,$05,$54,$00,$04
	DC.B	$05,$54,$0C,$8C,$06,$65,$08,$04
	DC.B	$07,$65,$04,$48,$08,$66,$00,$C0
	DC.B	$08,$76,$0C,$04,$09,$77,$04,$C0
	DC.B	$09,$87,$0C,$8C,$0A,$98,$04,$48
	DC.B	$0A,$A9,$0C,$04,$0B,$A9,$04,$8C
	DC.B	$0B,$BA,$0C,$48,$0C,$CB,$04,$04
	DC.B	$0C,$CC,$0C,$C0,$0D,$DC,$04,$48
	DC.B	$0D,$DD,$0C,$C0,$0E,$ED,$08,$8C
	DC.B	$0F,$FE,$04,$48,$0F,$FF,$0C,$C0
	DC.B	$0F,$FF,$0C,$CC,$0F,$FF,$0C,$CC

;-----------------------------------------------

		;123456789012345678
txt0:	dc.b	'sco0pex',0
txt1:	dc.b	'antibyte',0
txt2:	dc.b	'optima',0
txt3:	dc.b	'deetsay',0
txt4:	dc.b	'acryl',0
txt5:	dc.b	'generations',0
txt6:	dc.b	'ahead',0
txt7:	dc.b	'since',0
txt8:	dc.b	'1988',0
txt9:	dc.b	'rangerism',0
txt10:	dc.b	'is not',0
txt11:	dc.b	'dead',0
txt12:	dc.b	'the end',0
txt100:	dc.b	'1oo%',0
txt1000:dc.b	'1ooo%',0

realchars:
	dc.b	'abcdefghijklmnopqrstuvwxyz©&1234567890!%()',':'
	even

;-----
; a0 = chunkybuffer
; a1 = textptr
	
printtxt:
.a	move.b	(a1)+,d0
	beq.s	.q
	cmp.b	#' ',d0
	bne.s	.w
	lea	11(a0),a0
	bra.s	.a
.w	lea	realchars(pc),a3
	moveq	#0,d1
.x	cmp.b	(a3)+,d0
	beq.s	.v
	addq.l	#1,d1
	bra.s	.x
.v	lea	font,a2
	cmp	#28,d1
	blt.s	.v1
	sub	#28,d1
	lea	320*22*2(a2),a2
	bra.s	.g
.v1	cmp	#14,d1
	blt.s	.g
	sub	#14,d1
	lea	320*22(a2),a2
.g	mulu	#22,d1
	add.l	d1,a2
	moveq	#22-1,d7
	move.l	a0,a3
	lea	18(a0),a0
.g2	moveq	#22-1,d6
.g4	move.b	(a2)+,d0
	beq.s	.g3
	add	addtxt(pc),d0
	move.b	d0,(a3)
.g3	addq.l	#1,a3
	dbf	d6,.g4
	add	scrtxt(pc),a3
	lea	320-22(a2),a2
	dbf	d7,.g2
	bra.s	.a
.q	rts

;---

addtxt:	dc	47-1
scrtxt:	dc	256-22
cscrs:	dc.l	dummymap2,dummymap

;------------

yysize_c2	=	256
xsize_c2	=	256

smooth:
	movem.l	cscrs(pc),a0-a1
smooth_ei:
	lea	xsize_c2+1(a0),a0
	lea	xsize_c2+1(a1),a1
	move	#yysize_c2-2-1,d7
	moveq	#0,d1

.w	move	#xsize_c2-2-1,d6

.v	moveq	#0,d0
	move.b	-xsize_c2-1(a1),d0
	move.b	-xsize_c2(a1),d1
	add	d1,d0
	move.b	-xsize_c2+1(a1),d1
	add	d1,d0

	move.b	-1(a1),d1
	add	d1,d0
	move.b	1(a1),d1
	add	d1,d0

	move.b	xsize_c2-1(a1),d1
	add	d1,d0
	move.b	xsize_c2(a1),d1
	add	d1,d0
	move.b	xsize_c2+1(a1),d1
	add	d1,d0

	lsr	#3,d0
	addq.l	#1,a1
	move.b	d0,(a0)+
	dbf	d6,.v

	addq.l	#2,a1
	addq.l	#2,a0
	dbf	d7,.w
	rts

;-------------------------------------------------------------

init_c2p_o4o:
	moveq	#0,d0
	moveq	#0,d1
	move	xsize_scr,d0
	moveq	#0,d3
	move	ysize_scr,d1
	move	d0,d5
	mulu	d1,d5
	lsr.l	#3,d5
	bra	c2p1x1_8_c5_040_init

;--------------------------------------------------------------------------

c2p_1x1:
	move.l	ps16_sbuf(pc),a0

	tst	blur_st(pc)
	beq.s	.nob
	bsr	do_blur

	move.l	dummymap5_p(pc),a0
.nob:	move.l	planeptr1+4,a1

	tst.b	o4o
	bne	c2p1x1_8_c5_040

	include	"i/c2p/c2p1x1_8_blit_030.s"
;---
	include	"i/c2p/c2p1x1_8_c5_040+_3.s"


;--------------------------------------------------------------------------

spoints1	=	2000
sflanz1		=	4000

	include	"geo-gen.s"


;---------------------------

blur_st:	dc	0

do_blur:
	move	#xsize,d7
	move.l	dummymap5_p(pc),a1
	mulu	ysize_scr,d7

	lea	blur_st(pc),a3
	cmp	#2,(a3)
	bne.s	.w

	moveq	#0,d0
	lsr	#1,d7

	subq	#1,d7
	move.l	dummymap2_p(pc),a6
.ag	move	(a1),d0
	move.b	(a0)+,d0
	move	(a6,d0.l),d1
	move	1(a1),d0
	move.b	(a0)+,d0
	move.b	(a6,d0.l),d1
	move	d1,(a1)+

	dbf	d7,.ag
	rts
;---
.w:	lsr	#4,d7
	move	d7,a2

;	clr	$dff106
;	move	#$f0f,$dff180
	
.a	move.l	(a0)+,d0
	move.l	(a0)+,d2
	move.l	(a0)+,d4
	move.l	(a0)+,d6
	move.l	(a1),d1
	move.l	4(a1),d3
	move.l	8(a1),d5
	move.l	12(a1),d7
	add.l	d0,d1
	add.l	d2,d3
	add.l	d4,d5
	add.l	d6,d7
	lsr.l	#1,d1
	lsr.l	#1,d3
	move.l	#$7f7f7f7f,d0
	lsr.l	#1,d5
	lsr.l	#1,d7
	and.l	d0,d1
	and.l	d0,d3
	and.l	d0,d5
	and.l	d0,d7
	move.l	d1,(a1)+
	move.l	d3,(a1)+
	move.l	d5,(a1)+
	move.l	d7,(a1)+
	subq	#1,a2
	tst	a2
	bne.s	.a

;	clr	$dff106
;	move	#$0,$dff180
	rts

;------------------------------

anim42:
	moveq	#4-1,d7

	lea	pointsp201(pc),a5
	lea	slideoff201(pc),a3
	lea	pointsp202(pc),a6
	lea	slideoff202(pc),a4
	moveq	#12*1,d0

.hq	movem.l	d0/d7/a3-a6,-(a7)
	move.l	(a5),a1
	move.l	(a6),a2
	bsr.w	rotmove_obj_n
	movem.l	(a7)+,d0/d7/a3-a6
	add	#12,d0
	movem.l	d0/d7/a3-a6,-(a7)
	move.l	(a5),a1
	move.l	(a6),a2
	bsr.w	rotmove_obj
	movem.l	(a7)+,d0/d7/a3-a6
	moveq	#14*2,d1
	add	#12,d0
	add.l	d1,a3
	add.l	d1,a4
	add.l	d1,a5
	add.l	d1,a6
	dbf	d7,.hq

	move.l	(a5),a1
	move.l	(a6),a2
	bsr.w	rotmove_obj_n
	rts

adj_anim42:
	lea	slide201(pc),a1
	moveq	#10-1,d7
	bra	adj_okeys

;------------------------

ntrans_limes2:
	jmp	trans_limes2

o42x	=	600*4
o42y	=	0
o42z	=	600*4

o42d	=	8		; anzahl der unterteilungen

fux42:
	dc	0,63+16,	0,63+16,	63+16,0
	dc	0,63+16,	80,80+47,	80+47,80
	dc	0,63+16,	128,128+63,	128+63,128
	dc	0,63+16,	192,192+63,	192+63,192

	dc	80,80+47,	0,63+16,	63+16,0
	dc	80,80+47,	80,80+47,	80+47,80
	dc	80,80+47,	128,128+63,	128+63,128
	dc	80,80+47,	192,192+63,	192+63,192

	dc	128,128+63,	0,63+16,	63+16,0
	dc	128,128+63,	80,80+47,	80+47,80
	dc	128,128+63,	128,128+63,	128+63,128
	dc	128,128+63,	192,192+63,	192+63,192

	dc	192,192+63,	0,63+16,	63+16,0
	dc	192,192+63,	80,80+47,	80+47,80
	dc	192,192+63,	128,128+63,	128+63,128
	dc	192,192+63,	192,192+63,	192+63,192

obj42:
;---
	move.l	addtab_p,a2
	bsr	clr_64k

	move.l	dummymap5_p,a2
	bsr	clr_64k

	lea	fux42(pc),a0
	moveq	#16-1,d7
.hq:	movem	(a0)+,d0/d1/d5
	movem	(a0)+,a6
	movem	(a0)+,d2/d6
	movem.l	a0/d7,-(a7)	
	bsr	ntrans_limes2
	movem.l	(a7)+,a0/d7
	dbf	d7,.hq

	move.l	dummymap2_p(pc),a0
	move.l	addtab_p,a1
	bsr	cp_64k
;---
	lea	pointsp201(pc),a0
	move.l	#o42_1m,(a0)
	move.l	#o42_1r,14*1(a0)

	move.l	#o42_2m,14*2(a0)
	lea	o42_2r,a1
	move.l	a1,14*3(a0)

	lea	o42_3m,a1
	move.l	a1,14*4(a0)
	lea	o42_3r,a1
	move.l	a1,14*5(a0)

	lea	o42_4m,a1
	move.l	a1,14*6(a0)
	lea	o42_4r,a1
	move.l	a1,14*7(a0)

	lea	o42_5m,a1
	move.l	a1,14*8(a0)
	lea	o42_5r,a1
	move.l	a1,14*9(a0)

	lea	slide201(pc),a1
	moveq	#10-1,d7
	bsr	init_okeys
;----
	clr	fl_4_sort_st
	clr	clear_st

	lea	t1_m1(pc),a0
	move.l	#obj42m,(a0)

	lea	t1_m2(pc),a0
	move.l	#obj42m2,(a0)

	lea	t1_m3(pc),a0
	move.l	#obj42m3,(a0)

	lea	anim42(pc),a1
	move.l	a1,anim_obj_rout_p
	lea	adj_anim42(pc),a1
	move.l	a1,anim_obj_adj_p
;---
	move.l	dummymap3_p(pc),a0
	move.l	circle_p2(pc),a1
	move	#256*256/4-1,d7
.hc	move.l	(a1)+,d0
	lsr.l	#1,d0
	and.l	#$7f7f7f7f,d0
	add.l	#$50505050,d0
	move.l	d0,(a0)+
	dbf	d7,.hc
;----
	move.l	dummymap4_p(pc),a0
	move.l	dummymap3_p(pc),a1
	move.l	#$30303030,d1
	bsr	cp_add
;----
	move.l	dummymap_p(pc),a0
	move.l	marble_p(pc),a1
	bsr	cp_64k
;----
	bsr	lichtkegelmap0

	move.l	dummymap1_p(pc),a0
	lea	dummymap0+$10000,a1
	move	#256*256/4-1,d7
	move.l	#$40404040,d0
.hcq	move.l	d0,(a0)+
	move.l	d0,(a1)+
	dbf	d7,.hcq

;-
	moveq	#0,d0
	moveq	#63,d1
	jsr	init_fogtab

;-
	move.l	dummymap_p(pc),a0
	move.l	circle_p,a2
	move.l	fogtab_p,a1

	moveq	#-1,d7
	moveq	#0,d0
.g	move.b	(a2)+,d0
	moveq	#109,d1
	sub.b	d0,d1
	add.b	d1,d1
	lsl	#8,d1
	move.b	(a0),d1
	move.b	(a1,d1.l),(a0)+
	dbf	d7,.g

;---
	lea	gruenbeige(pc),a0
	lea	obj2cols2(pc),a1
	moveq	#13,d4
	moveq	#64,d5
	bsr	ncalc_pal

	lea	gruenbeige+12*4(pc),a0
	lea	obj2cols2+64*4(pc),a1
	moveq	#5,d4
	moveq	#16,d5
	bsr	ncalc_pal

	lea	rostgrau(pc),a0
	lea	obj2cols2+80*4(pc),a1
	moveq	#14,d4
	moveq	#47+1,d5
	bsr	ncalc_pal

	lea	beige(pc),a0
	lea	obj2cols2+128*4(pc),a1
	moveq	#11,d4
	moveq	#42+1,d5
	bsr	ncalc_pal

	lea	beige+10*4(pc),a0
	lea	obj2cols2+(128+43)*4(pc),a1
	moveq	#3,d4
	moveq	#64-(42+1),d5
	bsr	ncalc_pal

	lea	graulind(pc),a0
	clr.l	(a0)
	lea	obj2cols2+192*4(pc),a1
	moveq	#12,d4
	moveq	#63+1,d5
	bsr	ncalc_pal
;---
	moveq	#0,d0
	moveq	#0+63+16,d1
	moveq	#64,d5
	lea	(64+63).w,a6
	moveq	#63+16,d2
	moveq	#0,d6
	bsr	ntrans_limes3

	moveq	#80,d0
	moveq	#80+47,d1
	moveq	#64,d5
	lea	(64+63).w,a6
	moveq	#80+47,d2
	moveq	#80,d6
	bsr	ntrans_limes3

	move.l	#128,d0
	move.l	#128+63,d1
	moveq	#64,d5
	lea	(64+63).w,a6
	move.l	d1,d2
	move.l	d0,d6
	bsr	ntrans_limes3

	move.l	#192,d0
	move.l	#192+63,d1
	moveq	#64,d5
	lea	(64+63).w,a6
	move.l	d1,d2
	move.l	d0,d6
	bsr	ntrans_limes3

	move.l	addtab_p,a0
	moveq	#64-1,d7
	lea	64(a0),a0
	move	#128+64,d0
.hcc	move.b	d0,(a0)+
	addq	#1,d0
	dbf	d7,.hcc

;---
	move.l	t1_pkt_p(pc),a0
	move	#o42x*2/o42d,d3
	move	#o42z*2/o42d,d5

o42_1:	move	#-o42y,d1
	move	#o42z,d2
	moveq	#o42d+1-1,d6
.b:	move	#-o42x,d0
	moveq	#o42d-1,d7
.a:	movem	d0-d2,(a0)
	add	d3,d0
	addq.l	#6,a0
	dbf	d7,.a
	movem	d0-d2,(a0)
	sub	d5,d2
	addq.l	#6,a0
	dbf	d6,.b

	move.l	t1_tab_p(pc),a0
	moveq	#1,d0
	bsr.w	o42_1side

;--
o42rest:
	move.l	t1_tl_p(pc),a1
	lea	t1_tl(pc),a0
	move.l	a1,(a0)

	lea	t_texmap.w,a0
	move.l	dummymap_p(pc),d5
	move.l	d5,a6

	lea	((256)/(o42d)).w,a4
	lea	((256-6)/(o42d)).w,a5
	moveq	#4,d0

.c:	moveq	#(o42d)-1,d6

.b:	moveq	#(o42d)-1,d7
	moveq	#0,d2		; xl
	move.l	d0,d3		; yo
	lea	(a4,d2.l),a2	; xr
	lea	(a5,d3.l),a3	; yu

.a:
	bsr	do_124_234
	exg	d5,a6

	add.l	a4,d2
	add.l	a4,a2
	dbf	d7,.a
	exg	d5,a6
	add.l	a5,d0
	dbf	d6,.b

;---

	move.l	t1_pkt_p(pc),a0
	addq.l	#2,a0
	move.l	cloud64_p(pc),a1
	move	#256/(o42d+1)*2,d0
	move.l	#256/(o42d+1)*256,d2
	moveq	#o42d+1-1,d6
.e:	moveq	#o42d+1-1,d7
	pea	(a1)
.d:	moveq	#0,d1
	move.b	(a1),d1
	sub	#32,d1
	neg	d1
	lsl	#1+subpixel,d1
	sub	#64,d1
	move	d1,(a0)
	addq.l	#6,a0
	add	d0,a1
	dbf	d7,.d
	move.l	(a7)+,a1
	add.l	d2,a1

	dbf	d6,.e

	lea	t1_struct(pc),a0
	move	#(o42d+1)^2*1-1,(a0)+
	move	#o42d^2*1*2-1,(a0)
	rts

;--

o42_1side:
	move	d0,d3
	add	#o42d+1,d3

	moveq	#o42d-1,d7
.t2:	moveq	#o42d-1,d2

.t1:	move	d0,(a0)+
	addq	#1,d0
	move	d0,(a0)+
	move	d3,(a0)+

	move	d0,(a0)+
	move	d3,2(a0)
	addq	#1,d3
	move	d3,(a0)+
	addq.l	#2,a0
	dbf	d2,.t1

	addq	#1,d0
	addq	#1,d3
	dbf	d7,.t2
	rts

;-------------------

o19pyp:	dc.l	6
o19pxp:	dc.l	4

o19anz:	dc	0

o19a	=	8
o19xoff	=	100*4

o19rad	=	40*4
o19yadd	=	20*4

obj26:
	tst.b	o4o
	bne.s	.no3o
	lea	o19pyp+2(pc),a0
	move	#5,(a0)
	move	#3,4(a0)

.no3o:	lea	st_obj_map(pc),a0
	move.l	dummymap4_p(pc),(a0)
;	move.l	circle_p(pc),(a0)
	lea	st_obj_type(pc),a0
	move.l	#t_phong,(a0)
	lea	t1_tl(pc),a0
	clr.l	(a0)

;--
	move.l	#o19rad,d3
	move.l	o19pyp(pc),d4
	move.l	o19pxp(pc),d6
	addq.l	#1,d6
	moveq	#%0010,d7
	lea	sphere_rot_ang(pc),a0
;	move.l	#$1ee01800,(a0)
	move.l	#$1800,(a0)
	bsr	do_lsphere
	lea	sphere_rot_ang(pc),a0
	move.l	#$08000800,(a0)

	move.l	d0,d2
	subq.l	#1,d0

	mulu	#3*2,d2

	lea	anzpkt,a2
	move	d0,(a2)
	move.l	t1_pkt_p(pc),a0
	move.l	a0,a2

.p:	sub	#o19xoff,(a2)
	addq.l	#6,a2
	dbf	d0,.p

	lea	(a0,d2.l),a1

	moveq	#o19a-1-1,d4
	move.l	#$2000/(o19a),d5
.p2:	lea	tg_rotangle(pc),a5
	move.l	d5,(a5)
	movem.l	d2/d4-d5/a0/a1,-(a7)
	bsr	tg_rotyx		; Punkte rotieren
	movem.l	(a7)+,d2/d4-d5/a0/a1
	add.l	d2,a1
	add.l	#$2000/(o19a),d5
	dbf	d4,.p2

	move.l	o19pyp(pc),d4
	move.l	o19pxp(pc),d6
	mulu	#o19a,d6
	add.l	#o19a,d6
	move.l	#o19rad,d3
	moveq	#%1100,d7
	lea	lsphere_param(pc),a0
	movem.l	d3/d4/d6,(a0)

	bsr	sph_calc_anz
	movem.l	d4/d5/d7,-(a7)

	move.l	t1_pkt_p(pc),a0
	move.l	t1_tab_p(pc),a1
;	lea	t1_lst(pc),a2
;	lea	t1_d(pc),a3
	lea	tg_anz1(pc),a6
	movem.l	d0-d3/a0-a3,(a6)
	bsr	torus_vert

	bsr	sph_beg_end

	movem.l	(a7)+,d4/d5/d7
	lea	t1_struct(pc),a0
	lea	o19anz(pc),a1
	subq.l	#1,d4
	subq.l	#1,d5
	move	d4,(a0)+
	move	d4,(a1)
	move	d5,(a0)

;---
	move	t1_struct(pc),d0
	lea	anzpkt,a0
	subq.l	#1,d0
	mulu	#6,d0
	move	#2-1,(a0)
	move.l	t1_pkt_p(pc),a0
	lea	tg_rotangle(pc),a5
	add.l	d0,a0
	move.l	a0,a1
;	move.l	#$1ee01800,(a5)
	move.l	#$1800,(a5)
	bsr	tg_rotyx		; Punkte rotieren
	sub	#o19xoff,(a0)

	addq.l	#6,a0
	lea	anzpkt,a1
	sub	#o19xoff,(a0)
	clr	(a1)
	move.l	a0,a1
	move.l	#($2000/(o19a))*(o19a-1)&$1fff,(a5)
	bsr	tg_rotyx		; Punkte rotieren

;---
	rts

;--------------------------

; Fade fuer Clist mit >=32 Cols

; a0 = Pointer auf Source-Colordaten ( dc.w 0RGB,0rgb )
; a1 = Pointer auf Destination-Colordaten

fade_init:
	move	fade_amount(pc),d6
	lea	fade_current(pc),a3
	subq.l	#1,d6
	move.l	a3,a2
	move	fade_step(pc),d5
	move	d6,d7
	lea	fade_add(pc),a4
	ext.l	d5

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
	dbf	d7,.a

.b:	move	(a1)+,d0
	move	(a1)+,d1
	move.l	d0,d2
	move.l	d1,d3
	and	#$f00,d2
	and	#$f00,d3
	lsr	#4,d2
	lsr	#8,d3
	move.l	(a3)+,d4
	or	d3,d2
	swap	d2
	sub.l	d4,d2
	divsl	d5,d2
	move.l	d2,(a4)+

	move.l	d0,d2
	move.l	d1,d3
	and	#$0f0,d2
	and	#$0f0,d3
	lsr	#4,d3
	or	d3,d2
	move.l	(a3)+,d4
	swap	d2
	sub.l	d4,d2
	divsl	d5,d2
	move.l	d2,(a4)+

	move.l	d0,d2
	move.l	d1,d3
	and	#$00f,d2
	and	#$00f,d3
	lsl	#4,d2
	or	d3,d2
	move.l	(a3)+,d4
	swap	d2
	sub.l	d4,d2
	divsl	d5,d2
	move.l	d2,(a4)+
	dbf	d6,.b

	rts


; a0 = Pointer auf Copperlistcolors

fade_do:
	addq.l	#6,a0
	move	fade_amount(pc),d7
	lea	fade_current(pc),a2
	move	d7,d6
	lsr	#1,d7
	lea	fade_add(pc),a1
	subq.l	#1,d7
	move.l	a2,a3

.a:	move.l	(a1)+,d0
	add.l	d0,(a2)+
	move.l	(a1)+,d0
	add.l	d0,(a2)+
	move.l	(a1)+,d0
	add.l	d0,(a2)+
	move.l	(a1)+,d0
	add.l	d0,(a2)+
	move.l	(a1)+,d0
	add.l	d0,(a2)+
	move.l	(a1)+,d0
	add.l	d0,(a2)+
	dbf	d7,.a

	lsr	#5,d6
	subq.l	#1,d6

.c:	moveq	#32-1,d4
.b:	move	(a3)+,d0
	addq.l	#2,a3
	move.l	d0,d1
	and	#$f0,d0
	and	#$f,d1
	lsl	#4,d0
	lsl	#8,d1
	move	(a3)+,d2
	addq.l	#2,a3
	move.l	d2,d3
	and	#$f0,d2
	and	#$f,d3
	or	d2,d0
	lsl	#4,d3
	or	d3,d1
	move	(a3)+,d2
	addq.l	#2,a3
	move.l	d2,d3
	and	#$f0,d2
	and	#$f,d3
	lsr	#4,d2
	or	d3,d1
	or	d2,d0
	move	d0,(a0)
	move	d1,32*4+4(a0)
	addq.l	#4,a0
	dbf	d4,.b
	lea	32*4+8(a0),a0
	dbf	d6,.c
	rts


fade_amount:	dc.w	256
fade_step:	dc.w	100

fade_current:	dcb.l	256*3,0
fade_add:	dcb.l	256*3,0

;--------------------------------------------------------------------------

	IFD	_3ds
obj3dsstruct:
	dc.w	781-1			; Anz. d. Punkte des Objekts
	dc.w	1464-1			; Anz. d. Flaechen des Objekts
	dc.l	obj3dspkt		; Pointer auf Punkte d. Objekts
	dc.l	obj3dstab		; Pointer auf Vertextabelle d. Obj.
	dc.l	0			; Pointer auf Liste d. gruppierten Fl.
					; des Objekts fuers Sortieren.
	dc.l	0			; Routine fuer lokale Init. d. Obj.
	dc.l	obj2cols2		; Farben des Objekts
	dc.l	obj3dslist		; Pointerliste der Tris auf Texturen
					; bei NULL standardmap von map_p
;	dc.l	obj3dsm			; Movementdaten der Kamera
;	dc.l	obj3dsm2		; bei '0' -> Blick gen Ursprung (0,0,0)
					; sonst ptr auf Movementdaten d. Kamera
	dc.l	obj3dscamera
	dc.l	obj3dscamtargt
	dc.l	0			; ptr auf Spline fuer Z-Rotation
	dc.l	obj3dstrackinv
	ENDC


maptab:	dc.l	_x1_chunkycloud64
	dc.l	furchen_map
	dc.l	marble
	dc.l	circle

z3ds	=	4000
y3ds	=	1000

obj3dsm:
	dc	0,y3ds,-z3ds
	dc	z3ds,y3ds,0
	dc	0,y3ds,z3ds
	dc	-z3ds,y3ds,0

	dc	0,y3ds,-z3ds
	dc	z3ds,y3ds,0
	dc	0,y3ds,z3ds
	dc	$abab


obj3dsm2:
	rept	7
	dc	0,0,0
	endr
	dc	$abab
	
;--------------------------------------------------------------------------

dummymap1_p:	dc.l	dummymap1
dummymap0_p:	dc.l	dummymap0
dummymap_p:	dc.l	dummymap
dummymap2_p:	dc.l	dummymap2
dummymap3_p:	dc.l	dummymap3
dummymap4_p:	dc.l	dummymap4
dummymap5_p:	dc.l	dummymap5

;--------------------------------------------------------------------------


obj2cols2:
	dcb.l	256,0
blackl:	dcb.l	256*3,0
colsl:	dcb.l	256*3,0


init_maps:
	jsr	calc_maps

	lea	rflare,a0
	move.l	origcircle_p(pc),a1
	lea	(256-62)/2*256+(256-62)/2(a1),a1
	moveq	#62-1,d2
.h2	moveq	#62-1,d0
.a	moveq	#0,d1
	move.b	(a1)+,d1
	sub	#255-31,d1
	bpl.s	.h1
	moveq	#0,d1
.h1	move.b	d1,(a0)+
	dbf	d0,.a
	lea	256-62(a1),a1
	dbf	d2,.h2
	
	lea	map_p,a0
	move.l	circle_p2(pc),(a0)
	rts

;------

	include	"calc_maps.s"

	section	calc_palette,code
	include	"calc_pal.s"

font:	incbin	"font.raw"
flare1:	incbin	"flare3.raw"

;-------------------------------------------------------------

do_optunnel:
		bsr	op_CopyTexture
		bsr	op_InitPerspective
		bsr	op_Ycalc
		bsr	op_CalcSQR
		bsr	op_Xcalc
		bsr	op_Perspektiv
		bsr	op_CalcNormals

		lea	op_resolution(pc),a0
		move	half_scr,(a0)
		tst.w	(a0)
		beq.s	.1x1
		lea	op_vertlines(pc),a0
		move.w	#96-1,(a0)
.1x1:
		rts


;---------------------------
op_RotoSpeed:	equ	256*1	;texturewidth
op_ZoomSpeed:	equ	1*2
;---------------------------

op_Zoom:	dc.l	0
op_Rot:		dc.l	0

op_Fetch:	move.l	op_Texturep(pc),a0

		add.l	op_Rot(pc),a0
		add.l	op_Zoom(pc),a0

op_fetch2:	move.l	#op_Normals,a1
;		move.l	#op_ChunkDest,a2
		move.l	ps16_sbuf,a2

		move.w	op_VertLines(pc),d7

.Vert:		move.w	#[320/4]-1,d6

.Horiz:		movem.l	(a1)+,d0-d3

		move.b	(a0,d0.l),d4
		lsl.w	#8,d4
		move.b	(a0,d1.l),d4
		swap	d4
		move.b	(a0,d2.l),d4
		lsl.w	#8,d4
		move.b	(a0,d3.l),d4

		move.l	d4,(a2)+

		dbra	d6,.Horiz

		tst.w	op_Resolution(pc)
		beq.w	.1x1

		add.l	#[320*4],a1

.1x1:		dbra	d7,.Vert
		rts

;-----------------------------------------
; 0 = 1*1
; 1 = 1*n
;-----------------------------------------
op_Resolution:	dc.w	0
;-----------------------------------------
op_VertLines:	dc.w	192-1
;---

op_CalcNormals:	move.l	#op_Ytable,a0
		move.l	#op_Xtable,a1

		move.l	#op_Normals+[160*4],a2
		move.l	#op_Normals+[160*4],a3
		move.l	#op_Normals+[[[320*192]-160]*4],a4
		move.l	#op_Normals+[[[320*192]-160]*4],a5

		move.l	#op_Poffset,a6

		move.w	#96-1,d7

		moveq	#0,d2

.Vert:		move.w	#160-1,d6

.Horiz:		moveq	#0,d0		;nødvendig?

		move.b	#64,d0
		sub.b	(a0),d0
		lsl.w	#8,d0		;texture 256*N
		move.b	(a1)+,d2
		add.w	(a6,d2.w*2),d0
		move.l	d0,(a2)+

		moveq	#0,d0		;nødvendig?

		move.b	#64,d0		;Der skal nok lige checkes for
		add.b	(a0),d0		;180 grader
		lsl.w	#8,d0
		add.w	(a6,d2.w*2),d0
		move.l	d0,(a4)+

		moveq	#0,d0
		moveq	#0,d1

		move.w	#[3*64],d0
		move.b	(a0),d1
		sub.w	d1,d0
		lsl.l	#8,d0
		add.w	(a6,d2.w*2),d0
		move.l	d0,-(a5)

		moveq	#0,d0
		moveq	#0,d1

		move.w	#[3*64],d0
		move.b	(a0)+,d1
		add.w	d1,d0
		lsl.l	#8,d0
		add.w	(a6,d2.w*2),d0
		move.l	d0,-(a3)

		dbra	d6,.Horiz

		add.l	#[160*4],a2
		sub.l	#[[3*160]*4],a4
		sub.l	#[160*4],a5
		add.l	#[[3*160]*4],a3

		dbra	d7,.Vert
		rts

;---

op_Perspektiv:	move.l	#op_Poffset,a0
		move.w	#320-1,d7
		clr.l	d0
		clr.l	d2
		move.l	op_tunx(pc),d0
		move.l	op_tunz(pc),d2
.horiz:		movem.l	d0/d2,-(a7)
		lsl.l	#8,d0
		lsl.l	#1,d0
		divs.l	d2,d0
		add.l	#160,d0
		move.w	d0,(a0)+
		movem.l	(a7)+,d0/d2
		add.l	op_tx(pc),d0
		add.l	op_tz(pc),d2
		dbra	d7,.horiz
		rts

;---

op_Xcalc:	move.l	#SQRtable,a0
		move.l	#op_Xtable,a1
		move.w	#96-1,d7
.Vert:		move.w	#160-1,d6
.Horiz:		moveq	#0,d1
		move.w	op_Dx(pc),d0
		move.w	op_Dy(pc),d1
		mulu.w	d0,d0
		mulu.w	d1,d1
		add.w	d0,d1
		move.b	(a0,d1.l),(a1)+	;afstandsformel
		addq.w	#1,op_Dx
		dbra	d6,.Horiz
		clr.w	op_Dx
		subq.w	#1,op_Dy
		dbra	d7,.Vert
		rts

;---

op_CalcSQR:	move.l	#SQRtable,a0
		clr.w	d0
.Alle:		move.w	d0,d1
		lsl.w	#1,d1		;antal skal vokse kvadratisk
.Rod:		move.b	d0,(a0)+
		dbra	d1,.Rod
		addq.b	#1,d0
		bcc.s	.Alle		;loop sålænge d0<=255
		rts

;---

op_Dx:		dc.w	0
op_Dy:		dc.w	95

op_Ycalc:	move.l	#op_ArcTan,a0
		move.l	#op_Ytable,a1
		move.l	#op_TextureAngles,a2
		move.w	#96-1,d7
.Vert:		move.w	#160-1,d6
.Horiz:		move.w	op_Dy(pc),d0
		mulu.w	#100,d0		;Faktor 100 -> ikke for små tal
		move.w	op_Dx(pc),d1
		bne.s	.DxGTzero
		move.b	#63,(a1)+	;Vinkelret, op_textureangles
		bra.s	.Next
.DxGTzero:	divu.w	d1,d0		;d0=a
		moveq	#0,d1
		move.b	(a0,d0.w),d1
		move.b	(a2,d1.w),(a1)+	;gem textureangle
.Next:		addq.w	#1,op_Dx
		dbra	d6,.Horiz
		clr.w	op_Dx
		subq.w	#1,op_Dy
		dbra	d7,.Vert
		move.w	#95,op_Dy		;Forbered op_Dy til radius-calc
		rts

;---

op_InitPerspective:
		tst	op_Perspective(pc)
		beq.s	.op_NoPerspective

		lea	op_tx(pc),a0
		move.l	#48,(a0)
		move.l	#48,(op_tz-op_tx)(a0)
.op_NoPerspective:
		rts		

;----------------------------
op_Perspective:	dc.w	1
;----------------------------
op_tunx:		dc.l	-160
op_tunz:		dc.l	512
op_tx:		dc.l	1
op_tz:		dc.l	1
;----------------------------

;---

op_CopyTexture:
	move.l	op_texturep(pc),a0
	move.l	marble_p,a1
	move	#256*256/4-1,d7
.hc	move.l	(a1)+,d0
	add.l	d0,d0
	move.l	d0,(a0)+
	dbf	d7,.hc

		move.l	op_Texturep(pc),a0
		move.l	a0,a1
		move.l	a0,a2
		add.l	#256*256,a1
		add.l	#256*256*2,a2
		move.w	#[[256*256]/4]-1,d7
.CopyLoop:	move.l	(a0),(a1)+
		move.l	(a0)+,(a2)+
		dbra	d7,.CopyLoop
		rts		

op_texturep:	dc.l	texture

op_ArcTan:	dc.b	 0, 1, 1, 2, 2, 3, 3, 4
		dc.b	 5, 5, 6, 6, 7, 7, 8, 8
		dc.b	 9, 9,10,10,11,12,12,13
		dc.b	13,14,15,15,16,16,17,17
		dc.b	18,18,18,19,20,20,21,21
		dc.b	22,22,23,23,23,24,25,25
		dc.b	25,26,26,27,27,28,28,29
		dc.b	29,29,30,30,31,31,32,32
		dc.b	32,33,33,34,34,34,35,35
		dc.b	35,36,36,37,37,37,38,38
		dc.b	38,39,39,39,40,40,40,41
		dc.b	41,41,42,42,42,43,43,43
		dc.b	43,44,44,44,45,45,45,45
		dc.b	46,46,46,47,47,47,47,48
		dc.b	48,48,48,49,49,49,49,50
		dc.b	50,50,50,50,51,51,51,51
		dc.b	52,52,52,52,52,53,53,53
		dc.b	53,53,53,54,54,54,54,55
		dc.b	55,55,55,55,56,56,56,56
		dc.b	56,56,57,57,57,57,57,57
		dc.b	57,57,58,58,58,58,58,58
		dc.b	59,59,59,59,59,59,59,60
		dc.b	60,60,60,60,60,60,61,61
		dc.b	61,61,61,61,62,62,62,62
		dc.b	62,62,62,62,63,63,63,63
		dc.b	63,63,63,63,63,63,64,64
		dc.b	64,64,64,64,64,64,64,64
		dc.b	65,65,65,65,65,65,65,65
		dc.b	65,65,65,65,66,66,66,66
		dc.b	66,66,66,66,66,67,67,67
		dc.b	67,67,67,67,67,67,67,67
		dc.b	67,67,68,68,68,68,68,68
		dc.b	68,68,68,68,68,69,69,69
		dc.b	69,69,69,69,69,69,69,69
		dc.b	69,69,69,69,69,69,70,70
		dc.b	70,70,70,70,70,70,70,70
		dc.b	70,70,71,71,71,71,71,71
		dc.b	71,71,71,71,71,71,71,71
		dc.b	71,71,71,71,71,71,71,71
		dc.b	72,72,72,72,72,72,72,72
		dc.b	72,72,72,72,72,72,72,72
		dc.b	73,73,73,73,73,73,73,73
		dc.b	73,73,73,73,73,73,73,73
		dc.b	73,73,73,73,73,73,73,73
		dc.b	73,73,73,74,74,74,74,74
		dc.b	74,74,74,74,74,74,74,74
		dc.b	74,74,74,74,74,74,74,74
		dc.b	75,75,75,75,75,75,75,75
		dc.b	75,75,75,75,75,75,75,75
		dc.b	75,75,75,75,75,75,75,75
		dc.b	75,75,75,75,75,75,75,75
		dc.b	75,75,75,75,76,76,76,76
		dc.b	76,76,76,76,76,76,76,76
		dc.b	76,76,76,76,76,76,76,76
		dc.b	76,76,76,76,76,76,76,76
		dc.b	76,77,77,77,77,77,77,77
		dc.b	77,77,77,77,77,77,77,77
		dc.b	77,77,77,77,77,77,77,77
		dc.b	77,77,77,77,77,77,77,77
		dc.b	77,77,78,78,78,78,78,78
		dc.b	78,78,78,78,78,78,78,78
		dc.b	78,78,78,78,78,78,78,78
		dc.b	78,78,78,78,78,78,78,78
		dc.b	78,78,78,78,78,78,78,78
		dc.b	78,78,78,78,78,78,78,78
		dc.b	78,78,78,78,78,78,78,78
		dc.b	78,78,78,78,78,79,79,79
		dc.b	79,79,79,79,79,79,79,79
		dc.b	79,79,79,79,79,79,79,79
		dc.b	79,79,79,79,79,79,79,79
		dc.b	79,79,79,79,79,79,79,79
		dc.b	79,79,79,79,79,79,79,79
		dc.b	79,79,79,79,79,80,80,80
		dc.b	80,80,80,80,80,80,80,80
		dc.b	80,80,80,80,80,80,80,80
		dc.b	80,80,80,80,80,80,80,80
		dc.b	80,80,80,80,80,80,80,80
		dc.b	80,80,80,80,80,80,80,80
		dc.b	80,80,80,80,80,80,80,80
		dc.b	80,80,80,80,80,80,80,80
		dc.b	81,81,81,81,81,81,81,81
		dc.b	81,81,81,81,81,81,81,81
		dc.b	81,81,81,81,81,81,81,81
		dc.b	81,81,81,81,81,81,81,81
		dc.b	81,81,81,81,81,81,81,81
		dc.b	81,81,81,81,81,81,81,81
		dc.b	81,81,81,81,81,81,81,81
		dc.b	81,81,81,81,81,81,81,81
		dc.b	81,81,81,81,81,81,81,81
		dcb.b	[5*8],81
		dc.b	82,82,82,82,82,82,82,82
		dcb.b	[5*8],82
		dc.b	82,82,82,82,82,82,82,82
		dcb.b	[5*8],82
		dc.b	82,82,82,82,82,83,83,83
		dcb.b	[7*8],83
		dc.b	83,83,83,83,83,83,83,83
		dcb.b	[8*8],83
		dc.b	84,84,84,84,84,84,84,84
		dc.b	84,84,84,84,84,84,84,84
		dcb.b	[8*8],84
		dc.b	84,84,84,84,84,84,84,84
		dcb.b	[11*8],84
		dc.b	85,85,85,85,85,85,85,85
		dcb.b	[14*8],85
		dc.b	85,85,85,85,85,85,85,85
		dcb.b	[16*8],85
		dc.b	85,85,85,85,85,85,85,85
		dcb.b	[50*8],85
		dc.b	85,85,85,85,86,86,86,86
		dcb.b	[37*8],86
		dc.b	86,86,86,86,86,87,87,87
		dcb.b	[21*8],87
		dcb.b	256,87
		dc.b	87,87,87,87,87,87,87,87
		dcb.b	632,87
		dc.b	88,88,88,88,88,88,88,88
		dcb.b	1058,88
		dc.b	88,88,88,88,88,88,88,88
		dcb.b	2126,88
		dc.b	89,89,89,89,89,89,89,89
		dcb.b	6392,89
		dc.b	89,89,89,89,89,89,89,89
		even

op_TextureAngles:	dc.b	0,1,1,2,3,4,4,5
		dc.b	6,6,7,8,9,9,10,10
		dc.b	11,12,13,14,14,15,16,16
		dc.b	17,18,18,19,20,21,21,22
		dc.b	23,23,24,25,26,26,27,28
		dc.b	28,29,30,31,31,32,33,33
		dc.b	34,35,36,36,37,38,38,39
		dc.b	40,41,41,42,43,43,44,45
		dc.b	46,46,47,48,48,49,50,50
		dc.b	51,52,53,53,54,55,55,56
		dc.b	57,58,58,59,60,60,61,62
		dc.b	63,63,64
		even

;--------------------------------------------------------------------------

	section	tunesphere,code

alloc_4:
	move.l	d0,-(a7)

	add.l	d0,d0
	add.l	d0,d0
	addq.l	#8,d0
	addq.l	#8,d0
;	move.l	#yysize_c*xsize_c*4+16,d0

	lea	c_scr_mem_size(pc),a0
	move.l	d0,(a0)

	jsr	gen_allocchip
	move.l	d0,c_scr_mem
	beq.s	.c_as_fail

	subq.l	#1,d0
.c_iag:	addq.l	#1,d0			;do 64bit alignment
	move.l	d0,d1
	and.b	#7,d1
	bne.s	.c_iag

	lea	planeptr1,a0
;	move.l	#yysize_c*xsize_c,d1
	move.l	(a7)+,d1
	move.l	d0,(a0)+
	add.l	d1,d0
	move.l	d0,(a0)+
	add.l	d1,d0
	move.l	d0,(a0)+
	add.l	d1,d0
	move.l	d0,(a0)+
	moveq	#0,d0
	rts

.c_as_fail:
	addq.l	#4,a7
	moveq	#-1,d0
	rts

c_scr_mem:	dc.l	0
c_scr_mem_size:dc.l	0

;---

free4:
	move.l	c_scr_mem(pc),a1
        move.l  c_scr_mem_size(pc),d0
	jmp	gen_free

;---

swop4:	lea	planeptr1,a0
	movem.l	(a0),d0-d3
	movem.l	d1-d3,(a0)
	move.l	d0,12(a0)

swop4_ei:
	move.l	#$1ff00,d2
.sw_1:	move.l	$dff004,d6
	and.l	d2,d6
	tst.l	d6			; Zeile 0?
	beq.s	.sw_1
.sw_2:	move.l	$dff004,d6
	and.l	d2,d6
	cmp.l	#$00100,d6		; Zeile 1?
	beq.s	.sw_2

	moveq	#8-1,d7
	move.l	a1,a0

.swapag:move	d0,4(a0)
	swap	d0
	move	d0,(a0)
	swap	d0
	addq.l	#8,a0
	add.l	d4,d0
	dbf	d7,.swapag
	rts

;-------------------------

yysize_c	=	yysize
xsize_c		=	xsize
	
do_tunsphere:
	move.l	#yysize_c*xsize_c,d0
	bsr	alloc_4
	bne.w	.credz_f

	lea	ps16_sbuf,a0
	move.l	(a0),-(a7)
	move.l	#credzscr,(a0)
	bsr	.prec

;-
	clr	irq_cnt

.ag:	lea	$dff002,a6
	bsr.w	.main

	btst	#6,$bfe001
	beq.s	.mainex

	lea	time_p,a0
	move.l	(a0),a1
	lea	abs_fr_cnt,a2
	move.l	(a1),d0
	cmp.l	(a2),d0
	bgt.s	.ag

	addq.l	#4,(a0)

	move.l	(a7)+,ps16_sbuf

.as:	tst	blit_st
	bne.s	.as
	lea	$dff002,a6
	wblit

	jsr	waitr
	move.l	#blackcl,$80-2(a6)
	jsr	waitr
;	clr	$88-2(a6)
	move	#xsize,xsize_scr

	bsr	free4
	moveq	#0,d0
	rts

.mainex:
	move.l	(a7)+,ps16_sbuf
	bsr.s	.as
	moveq	#-1,d0
	rts

.rraus:
	move.l	(a7)+,ps16_sbuf
	bsr.s	.as
	moveq	#1,d0
	rts

.credz_f:
	moveq	#1,d0
	rts

;-----------------

.prec1:
	move.l	sin_map_p,a0
	move.l	texture_p(pc),a1
	moveq	#-1,d7
.hr	move.b	(a0)+,d0
	cmp.b	#32,d0
	blt.s	.hs
	add	#128,d0
.hs	move.b	d0,(a1)+
	dbf	d7,.hr
;-
	move.l	marble_p,a0
	lea	bmap,a1
	jsr	bump2d
	jsr	corr_bmap

	moveq	#0,d0
	moveq	#127,d1
	jsr	init_gttab
	move.l	#128,d0
	move.l	#128+127,d1
	jsr	init_gttab

	lea	dummymap,a2
	moveq	#-1,d7
	lea	phong_map,a0
	moveq	#0,d0
	move.l	a2,a1
.db	move.b	(a0)+,d0
	cmp	#$d0,d0
	blt.s	.db1
	move.b	#$d0,d0
.db1:	move.b	d0,(a2)+
	dbf	d7,.db

	move.l	a1,a0
	move.l	a1,a2
	add.l	#256*256,a0
	add.l	#-256*256,a2

	move	#256*256/4-1,d7
	move.l	#$d0d0d0d0,d0
.ha	move.l	d0,(a0)+
	move.l	d0,(a2)+
	dbf	d7,.ha

	move.l	texture_p(pc),a0
	jsr	bump_tex
;-
	lea	milgruen,a0
	lea	obj2cols2,a1
	moveq	#13,d4
	move.l	#127+1,d5
	bsr.s	.ncalc_pal

	lea	gruengrau,a0
	lea	obj2cols2+128*4,a1
	moveq	#14,d4
	move.l	#127+1,d5
.ncalc_pal
	jmp	calc_pal

;----

.prec2:
	move.l	cloud64_p,a0
	move.l	texture_p(pc),a1
	moveq	#-1,d7
.hr2	move.b	(a0)+,d0
	cmp.b	#32,d0
	blt.s	.hs2
	sub.b	#32,d0
	eor.b	#$1f,d0
	add	#128,d0
.hs2	move.b	d0,(a1)+
	dbf	d7,.hr2
;-
	move.l	sm_map_p,a0
	move.l	a0,a1
	move	#256*256/4-1,d7
.ht	move.l	(a1),d0
	lsr.l	#2,d0
	and.l	#$3f3f3f3f,d0
	move.l	d0,(a1)+
	dbf	d7,.ht

	lea	bmap,a1
	jsr	bump2d
	jsr	corr_bmap

	moveq	#0,d0
	moveq	#127,d1
	jsr	init_gttab
	move.l	#128,d0
	move.l	#128+127,d1
	jsr	init_gttab

	lea	dummymap,a2
	moveq	#-1,d7
	lea	phong_map,a0
	moveq	#0,d0
	move.l	a2,a1
.db2	move.b	(a0)+,d0
	cmp	#$d0,d0
	blt.s	.db12
	move.b	#$d0,d0
.db12:	move.b	d0,(a2)+
	dbf	d7,.db2

	move.l	a1,a0
	move.l	a1,a2
	add.l	#256*256,a0
	add.l	#-256*256,a2

	move	#256*256/4-1,d7
	move.l	#$d0d0d0d0,d0
.ha2	move.l	d0,(a0)+
	move.l	d0,(a2)+
	dbf	d7,.ha2

	move.l	texture_p(pc),a0
	jsr	bump_tex
;-
	lea	rostbraun,a0
	lea	obj2cols2,a1
	moveq	#24,d4
	move.l	#127+1,d5
	bsr.w	.ncalc_pal

	lea	rostbraun,a0
	lea	obj2cols2+128*4,a1
	moveq	#24,d4
	move.l	#127+1,d5
	bra.w	.ncalc_pal

;-----------------

.precp:	dc.l	.prec1,.prec2
.precpp:dc.l	.precp

.prec:
	move	#yysize_c,d0
	tst	half_scr
	beq.s	.ph
	lsr	#1,d0

	lea	resolution(pc),a0
	move	#1,(a0)

.ph	move	d0,ysize_scr
	move	#xsize_c,xsize_scr

	move	#xsize_c/8,d0
	mulu	ysize_scr,d0
	move.l	d0,oneplanesize
	jsr	init_c2p_o4o
;-
	lea	.precpp(pc),a1
	move.l	(a1),a0
	addq.l	#4,(a1)
	move.l	(a0),a0
	jsr	(a0)
		

		bsr	CopyTexture

		bsr	FixCos
		bsr	FixSin
		bsr	CalcSQR
		bsr	CalcNormals

		bsr	InitRES

;-
	bsr	c_swop2
;-
	lea	colsl,a0
	move	#256-1,d7
.chc	clr.l	(a0)+
	dbf	d7,.chc

	move	#256,fade_amount
	move	#60,fade_step

	lea	obj2cols2,a0
	lea	colsl,a1
	jsr	fade_init
;-

	lea	obj2cols2,a0
	lea	cr_cfux2,a1
	moveq	#8,d7
	jsr	boc_ei
;-
	lea	cr_cfux3,a1
	lea	cr_rest,a2
	move	#(cr_reste-cr_rest)/4-1,d6

	tst	resolution(pc)
	beq.s	.cpra

	move	#yysize_c/2-1,d7
	move.l	#$48dffffe,d0
	move.l	#$01000000,d1

.cm	move.l	d0,(a1)+
	add.l	d1,d0
	move.l	#$0108ffd8,(a1)+
	move.l	#$010affd8,(a1)+
	move.l	d0,(a1)+
	add.l	d1,d0
	move.l	#$01080000,(a1)+
	move.l	#$010a0000,(a1)+
	dbf	d7,.cm

	addq.l	#4,a2
	subq	#1,d6

.cpra	move.l	(a2)+,(a1)+
	dbf	d6,.cpra

;-
.a:	lea	time_p,a0
	move.l	(a0),a1
	lea	abs_fr_cnt,a2
	move.l	(a1),d0
	cmp.l	(a2),d0
	bgt.s	.a

	addq.l	#4,(a0)

	lea	$dff002,a6
	move.l	#crlist2,$80-2(a6)
;	clr	$88-2(a6)
	move	#$7de0,$96-2(a6)
	move	#$83c0,$96-2(a6)
	move	#$c060,$9a-2(a6)
;-
	rts

;----

.main:	move	$1e-2(a6),d0		; Wait for Soft-bit in INTREQR
	and	#4,d0
	beq.s	.main
	move	#4,$9c-2(a6)		; Clear the bit

	bsr	fetch
	jsr	c2p_1x1

	bsr.s	adj_sphere
	bra	c_swop2

;-----

fsph:	dc	0
fcnt:	dc	22*50+25

adj_sphere:
	tst	fsph(pc)
	beq.s	.w

	lea	fcnt(pc),a0
	subq	#1,(a0)
	bpl.s	.w

	subq	#1,fade_step
	bmi.s	.q2
	lea	cr_cfux2,a0
	jsr	fade_do

.q2

.w		add.l	#ScrollSpeed,TextureScroll
		cmp.l	#[256*256],TextureScroll
		bne.s	.Njet
		clr.l	TextureScroll

.Njet:		add.w	#14/5,Speed_x1
		and.w	#2046,Speed_x1
		add.w	#18/5,Speed_y1
		and.w	#2046,Speed_y1

		add.w	#24/5,Speed_x2
		and.w	#2046,Speed_x2
		add.w	#30/5,Speed_y2
		and.w	#2046,Speed_y2

		add.w	#30/5,Speed_x3
		and.w	#2046,Speed_x3
		add.w	#20/5,Speed_y3
		and.w	#2046,Speed_y3

	subq	#1,irq_cnt
	bgt.w	adj_sphere
	rts

;----

c_swop2:move	#xsize_c/8,d4
	mulu	ysize_scr,d4
	lea	crplanes2+2,a1
	bra	swop4

;----

texture_p:	dc.l	texture

CopyTexture:	move.l	Texture_p(pc),a0
		move.l	#Texture+[256*256],a1
		move.w	#[[256*256]/4]-1,d7
.Copy:		move.l	(a0)+,(a1)+
		dbra	d7,.Copy
		rts		

;-----

ts_sc:		move.l	sinp,a2
		move.l	a0,a1
		lea	$800(a2),a2
		move	#1024-1,d7
.hc		move	d1,d0
		muls	(a2)+,d0
		swap	d0
		addq.l	#6,a2
		move	d0,(a1)+
		dbf	d7,.hc
		rts

FixCos:		lea	Cos(pc),a0

		move	#96*2,d1
		bsr.s	ts_sc

		move.w	#1024-1,d7
.Loop:		move.w	(a0),d0
		add.w	#96,d0
		lsl.w	#1,d0		;word-size
		move.w	d0,(a0)+
		dbra	d7,.Loop	
		rts
;---

FixSin:		lea	Sin(pc),a0

		moveq	#31*2,d1
		bsr.s	ts_sc

		move.w	#1024-1,d7
.Loop:		move.w	(a0),d0
		add.w	#32,d0
		mulu.w	#512,d0
		lsl.w	#1,d0		;word-size
		move.w	d0,(a0)+
		dbra	d7,.Loop
		rts
;----


CalcSQR:	move.l	#SQRtable,a0
		clr.w	d0
.Alle:		move.w	d0,d1
		lsl.w	#1,d1		;antal skal vokse kvadratisk
.Rod:		move.b	d0,(a0)+
		dbra	d1,.Rod
		addq.b	#1,d0
		bcc.s	.Alle		;loop sålænge d0<=255
		rts

;------

;----------------------------
xk:		equ	-160-96
yk:		equ	-100-32
;----------------------------
x:		dc.w	xk
y:		dc.w	yk
;----------------------------

CalcNormals:	move.l	#Normals,a0
		move.l	#SQRtable,a1

		move.w	#264-1,d7	;200+[2*32]

.Vert:		move.w	#512-1,d6	;320+[2*96]

.Horiz:		move.w	x(pc),d0
		move.w	y(pc),d1

		move.w	d0,d2
		move.w	d1,d3

		muls.w	d2,d2
		muls.w	d3,d3

		add.l	d2,d3
		beq.w	.Index

		cmp.l	#3500,d3	;Distortion eller lens?
.no_op		blt.s	.Lens		;Lens!

		muls.w	#7000,d0	;Perspektivforlængning
		muls.w	#7000,d1	;

		divs.l	d3,d0		;Distortion-normaler
		divs.l	d3,d1

		bra.s	.Index

.Lens:		move.l	#3900,d2
		sub.l	d3,d2
		lsl.l	#2,d2
		move.b	(a1,d2.l),d2
		and.w	#%0000000011111111,d2
		sub.w	#125,d2
		muls.w	d2,d2
		lsr.l	#2,d2
		add.l	d3,d2

		move.l	d2,d4

		lsr.l	#2,d4
		sub.l	#3900,d4
		neg.l	d4
		lsl.l	#2,d4
		move.b	(a1,d4.l),d4
		and.w	#%0000000011111111,d4
		sub.w	#125,d4
		muls.w	d4,d4
		lsr.l	#2,d4
		lsl.l	#4,d4

;;		divu.w	#3,d4		;hvor langt skal spheren stå foran
					;planet. 0 - > plan og sphere er
					;kontinuerte

		add.w	d2,d4

		muls.w	d4,d0
		muls.w	d4,d1

		divs.l	d3,d0
		divs.l	d3,d1

.Index:		lsl.w	#8,d1		;y*tx
		move.b	d0,d1		;y+x

		move.w	d1,(a0)+

		addq.w	#1,x

		dbra	d6,.Horiz

		move.w	#xk,x
		addq.w	#1,y

		dbra	d7,.Vert

		rts

;-------------

InitRES:	tst.w	Resolution(pc)
		beq.s	.1x1
		lea	vertlines(pc),a0
		move.w	#96-1,(a0)
.1x1:		rts

;-----------------------------------------
; 0 = 1*1
; 1 = 1*n
;-----------------------------------------
Resolution:	dc.w	0
;-----------------------------------------
VertLines:	dc.w	192-1
;-----------------------------------------

Modulus:	equ	[[2*96]*2]

Speed_x1:	dc.w	0
Speed_x2:	dc.w	256
Speed_x3:	dc.w	512
Speed_y1:	dc.w	768
Speed_y2:	dc.w	1024
Speed_y3:	dc.w	1280

;-------------------------------
ScrollSpeed:	equ	[4*256]		;TextureWidth
;-------------------------------

TextureScroll:	dc.l	0

Fetch:		move.l	Texture_p(pc),a0
		add.l	TextureScroll(pc),a0

		move.l	#Normals,a1
		move.l	a1,a2
		move.l	a1,a3

		move.l	ps16_sbuf,a4

		lea	sin(pc),a5
		lea	cos(pc),a6

		moveq	#0,d0
		moveq	#0,d1
		moveq	#0,d2
		moveq	#0,d3

		move.w	Speed_y1(pc),d0
		move.w	(a5,d0.w),d1
		move.w	Speed_x1(pc),d0
		add.w	(a6,d0.w),d1
		add.l	d1,a1

		move.w	Speed_y2(pc),d0
		move.w	(a5,d0.w),d1
		move.w	Speed_x2(pc),d0
		add.w	(a6,d0.w),d1
		add.l	d1,a2

		move.w	Speed_y3(pc),d0
		move.w	(a5,d0.w),d1
		move.w	Speed_x3(pc),d0
		add.w	(a6,d0.w),d1
		add.l	d1,a3

		move.w	VertLines(pc),d7

.Vert:		move.w	#[320/4]-1,d6

.Horiz:		move.w	(a1)+,d0
		move.w	(a1)+,d1
		move.w	(a1)+,d2
		move.w	(a1)+,d3

		add.w	(a2)+,d0
		add.w	(a2)+,d1
		add.w	(a2)+,d2
		add.w	(a2)+,d3
		add.w	(a3)+,d0
		add.w	(a3)+,d1
		add.w	(a3)+,d2
		add.w	(a3)+,d3

		move.b	(a0,d0.l),d4
		lsl.w	#8,d4
		move.b	(a0,d1.l),d4
		swap	d4
		move.b	(a0,d2.l),d4
		lsl.w	#8,d4
		move.b	(a0,d3.l),d4
		
		move.l	d4,(a4)+

		dbra	d6,.Horiz

		add.l	#Modulus,a1
		add.l	#Modulus,a2
		add.l	#Modulus,a3

		tst.w	Resolution(pc)
		beq.s	.1x1

		lea	512*2(a1),a1
		lea	512*2(a2),a2
		lea	512*2(a3),a3

.1x1:		dbra	d7,.Vert
		rts

;------------------------------

cos:	dcb.w	1024,0
sin:	dcb.w	1024,0

;----------------------------------------------------------------

deetsay:
	include	"deetsay.s"

;----------------------------------------------------------------

module:	incbin	"disco baby.sng"
module2:incbin	"hermot.sng"
module3:incbin	"laserdance.sng"

	IFD	dostxt
nomem:	dc.b	10,"Not enough memory!",10,10
	dc.b	"This intro requires 4mb fast",10
	dc.b	"Free some and try again.",10,10,0
endtxt:
	dc.b	10
	dc.b	"       _________________________________________________________",10
	dc.b	"       |                                                       |",10
	dc.b	"       |                     /¯¯¯¯¯¯¯¯¯¯¯\                     |",10
	dc.b	"       |      __       /¯¯¯¯¯| - SINCE - |¯¯¯¯¯\               |",10
	dc.b	"       |_____/_/ _____/   ___|    ____  _|______\ _________  __|_",10
	dc.b	"      _/  __  | /   _ |_ /   ¯\  /    \/        \/   _ |_  \/  ¯|©",10
	dc.b	"      |   \\  |/   /|__//   /| \/   /| \_  /|   /   /| ¯/  /    /\",10
	dc.b	"      ¯\ O \¯¯/ o /|/ // o //¯ / o //¯o / //¯o /)o__)\¯¯\  O  /¯\/",10
	dc.b	"    /¯¯¯¯|  \/   //¯¯¯¯\  //      //      ¯___/¯ /  ¯¯\  /    \¯¯",10
	dc.b	"   /    ¯°   \  °¯¯   _/_ ¯   /   ¯   /   /\/         /_/      \ ",10
	dc.b	"   \_________/\________¯/____/\______/___/ /\_________¯/   /\   \",10
	dc.b	"    \_______/\/_______//____/|\|_____|___|/  \________/   / /\___\",10
	dc.b	"       |              ¯\     |           |      /    /___/ /  \___\",10
	dc.b	"       |                \____|  1 9 8 8  |_____/     \___\/MåÐ@|",10
	dc.b	"       |                     \___________/                     |",10
	dc.b	"       | ¡                                                     |",10
	dc.b	"       | |         presents a 40k intro for TheParty98         |",10
	dc.b	"       | ||                      called:                       |",10
	dc.b	"       --++--                                                  |",10
	dc.b	"       --++------             -=) 1000% (=-                    |",10
	dc.b	"       |_||____________________________________________________|",10,10
	dc.b	"Code: Antibyte, Optima. Music+Samples Code: Deetsay. Colors+Flare: Acryl",10,10
	dc.b	"         Use cmdline parameter '0' to switch to 1x2 resolution.",10,10,0
	even
	ENDC

;----------------------------------------------------------------

	section	chipmem,data_c

blackcl:dc.w	$100,$201,$106,$20
	dc.w	$180,$0
	dc.l	-2,-2

;---

crlist2:
	dc.w    $8e,$4981,$90,$09c1,$92,$38,$94,$a0
        dc.w    $100
	dc.w	$211
	dc.w	$104,0,$1fc,3,$102,0

	dc.w	$010f,$fffe
crplanes2:
	dc.w    $e0,0,$e2,0,$e4,0,$e6,0
        dc.w    $e8,0,$ea,0,$ec,0,$ee,0
	dc.w	$f0,0,$f2,0,$f4,0,$f6,0
	dc.w	$f8,0,$fa,0,$fc,0,$fe,0

	dc.w	$108,0	;(plnr-1)*xsize/8
	dc.w	$10a,0	;(plnr-1)*xsize/8

cr_cfux2:dcb.l	(32+1)*8*2,0
	dc.w	$106,$20
cr_cfux3:
	dcb.l	yysize_c*3,0

cr_rest:dc.w	$ffdf,$fffe,$380f,$fffe,$9c,$8004
	dc.l	-2,-2
cr_reste:

;--------------------------------------------------------------------------

;	include	"i/objcode.s"

	IFD	_3ds
	section	obj3dsgack,data

obj3dspkt:
	include	"dh1:test2/vertlist.s"

obj3dstab:
	include	"dh1:test2/facelist.s"

obj3dslist:
	incbin	"dh1:test2/typelist.s"
obj3dscamera:
	include	"dh1:test2/camera.s"
obj3dscamtargt:
	include	"dh1:test2/camtargt.s"

obj3dstrackinv:
	include	"dh1:test2/trackinv.s"
	include	"dh1:test2/tracklst.s"
	ENDC
	
;-------------------------------------------------

	section	bss,bss

dummymap1:	ds.b	256*256
dummymap0:
normals:	ds.b	256*256		;Normals:	ds.w	[512*264]
op_normals:				;op_normals:	ds.l	[320*192]
		ds.b	256*256
dummymap:	ds.b	256*256
		ds.b	256*256
map2d:					;map2d:		ds.b	xb*yysize
dummymap2:	ds.b	256*256
sqrtable:	ds.b	256*256
texture:
dummymap3:	ds.b	256*256
		ds.b	256*256
dummymap4:	ds.b	256*256
stretchbuffer:				;stretchbuffer	ds.b	320*256
credzscr:	ds.b	256*256
dummymap5:	ds.b	256*256
op_ytable:				;op_ytable:	ds.b	[160*96]
op_poffset	=	op_ytable+(160*96)
op_xtable	=	op_ytable+256*256;op_xtable:	ds.b	[160*96]
bmap:		ds	256*256

;---

	IFD	m_fog
fogtab:	ds.b	256*256
	ENDC

	IFNE	m_gouraud_tmap_v|m_phong_tmap_v|m_tbump_v
gouraudtab:
	ds.b	256*256
	ENDC

	IFD	m_transparent
addtab:	ds.b	256*256
	ENDC

	IFD	m_gouraud_tmap
gouraud_map:
	ds.b	256*256
	ENDC

	IFD	m_phong_tmap
	ds.b	256*256
phong_map:
	ds.b	256*256
	ds.b	256*256
	ENDC

bgmap:	ds.b	xsize*yysize

sinvalues:	ds	$2800/2

t_tab:	ds	$8000*4

	IFD	_3ds
t_tab_3ds:	ds	$8000*4
	ENDC

	IFD	negdivtab
		ds	2^g_range	; negative werte
	ENDC
divtab:		ds	2^g_range	; mul 1/x, statt div x

	IFNE	m_gouraud_tmap_v|m_phong_tmap_v
circtab:	ds	363*363
	ENDC

;---

scene1_typelist:ds.l	sflanz1*6
scene1_pkt:	ds	spoints1*3
scene1_tab:	ds	sflanz1*3
t1_typelist:	ds.l	max_fl*6
t2_typelist:	ds.l	max_fl*6
t1_pkt:		ds	max_pkt*3
t2_pkt:		ds	max_pkt*3
t1_tab:		ds	max_fl*3
t2_tab:		ds	max_fl*3
t1_bbox_st:	ds.b	max_pkt

;---
	even
	
o1001o:	ds	o1001*3

rflare2:ds.b	64*64
rflare3:ds.b	64*64
rflare:	ds.b	62*62

;------------------------------------------------------------------------

	section	chip,bss_c

ax	ds.b	yysize*xsize/8*8
ay	ds.b	yysize*xsize/8*8

;----
	even
samples:
a	ds.b	$aa0
b	ds.b	$aa0
c	ds.b	$1000
d	ds.b	$100
e	ds.b	$1000
f	ds.b	$1000
g	ds.b	$1000
h	ds.b	$4000
i	ds.b	$aa0
j	ds.b	$aa0
k	ds.b	$4000
l	ds.b	$4000
m	ds.b	$4000
ac_a	ds.b	$1000
ac_b	ds.b	$1000
ac_c	ds.b	$1000
ac_d	ds.b	$1000
ac_e	ds.b	$1000
ac_f	ds.b	$1000
ac_g	ds.b	$1000
ac_h	ds.b	$1000
ac_i

;------------------------------------------------------------------------

	include	"trkpk.s"
