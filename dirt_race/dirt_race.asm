TIMER1  equ $13 ; slower one
TIMER2  equ $14 ; faster one

HPOSP0 = $D000 ; Player 0 Horizontal Position
HPOSP1 = $D001 ; Player 1 Horizontal Position
HPOSP2 = $D002 ; Player 2 Horizontal Position
;
HPOSM0 = $D004 ; Missile 0 Horizontal Position
HPOSM1 = $D005 ; Missile 1 Horizontal Position
HPOSM2 = $D006 ; Missile 2 Horizontal Position
HPOSM3 = $D007 ; Missile 3 Horizontal Position
;
SIZEP0 = $D008 ; Player 0 Size
SIZEP1 = $D009 ; Player 1 Size
SIZEP2 = $D00A ; Player 2 Size
SIZEP3 = $D00B ; Player 3 Size
SIZEM =  $D00C ; Missiles Sizes (2 bits per missile)
;
COLPM0 = $D012 ; Player/Missile 0 color, GTIA 9-color playfield color 0 for Background
COLPM1 = $D013 ; Player/Missile 1 color, GTIA 9-color playfield color 1
COLPM2 = $D014 ; Player/Missile 2 color, GTIA 9-color playfield color 2
COLPM3 = $D015 ; Player/Missile 3 color, GTIA 9-color playfield color 3

GRAFP0 = $D00D ; Player 0 Graphics Pattern
GRAFP1 = $D00E ; Player 1 Graphics Pattern
GRAFP2 = $D00F ; Player 2 Graphics Pattern
GRAFP3 = $D010 ; Player 3 Graphics Pattern
GRAFM =  $D011 ; Missile Graphics Pattern (2 bits per missile)

COLPF0	equ $D016
COLPF1	equ $D017
COLPF2	equ $D018
COLPF3	equ $D019
COLBK	equ $D01A
GRACTL  equ $D01D ; Graphics Control, P/M DMA and joystick trigger latches

AUDF1	equ $D200
AUDC1	equ $D201
AUDF2	equ $D202
AUDC2	equ $D203
AUDF3	equ $D204
AUDC3	equ $D205
AUDF4	equ $D206
AUDC4	equ $D207 
AUDCTL	equ $D208
RANDOM	equ $D20A
SKCTL   equ $D20F          	

PMBASE  equ $D407 ; Player/Missile Base Address (high) 
WSYNC	equ $D40A
VCOUNT	equ $D40B

SDMCTL  equ $022F          	

PCOLR0	equ $02C0				;p/m 0 color
PCOLR1	equ $02C1				;p/m 1 color
PCOLR2	equ $02C2				;p/m 2 color
PCOLR3	equ $02C3				;p/m 3 color

COLOR0	equ $02c4
COLOR1	equ $02c5
COLOR2	equ $02c6
COLOR3	equ $02c7
COLOR4	equ $02c8

rom_rnd equ $F711

road_pos equ $6a ; C0 on zero page

bike_pmg equ p0_shape+$60

	org $2000
start:

	ldx #%1101100 
	stx SDMCTL ; #%0001000 ; enable players, double resolution, no playfield so no color needed
	dex
	;lda #7 ; 2=players, 3=p&m
	stx GRACTL
	stx SIZEP1 ; road
	stx AUDC1 ; engine sound

.local init_loop
	;init colors, bike
	lda bike_data-1,x
	sta bike_pmg-1,x
	dex
	bne init_loop
.endl
	; A=$30
	sta PCOLR2 ; mud	
	sta PMBASE

.local init_table
loop:
	lda rom_rnd,x
	sta mud_pos,x

	and #%10
	clc
	adc road_pos,x 
	sbc #0
	sta road_pos+1,x
	
	lda #%11111111
	sta p1_shape,x ; alterantive - sta grafp0 in line

	inx
	bpl loop
.endl
	sta PCOLR0 ; bike 

screen_loop:
	; in A we have HPOSP1 (road) from the previous line
	ldy VCOUNT
	sta wsync
	; set bike
	cpy #$64 ; $5F - no bike move
	bne skip_pos
	adc #16-4
	sta HPOSP0 ; bike pos	
	sta AUDF1
skip_pos:
	tya ; vcount
	sbc TIMER2
	sta GRAFP2	
	
	lsr ; a=vcount/2
	tax ; move to index

	and #7
	eor #$E7 ; revert gradient - looks more like bumps
	sta COLPM1 ; road

	; ground color
	txa
	and #$30
	adc #$A4
	sta COLBK

	lda road_pos,x
	sbc VCOUNT
	sta HPOSP1	

	tay
	sbc mud_pos,x
	sta HPOSP2 ; mud pos
	tya
	bne screen_loop
	
bike_data:
	.byte %00110000 ; $30
	.byte %01100110 ; $66
	.byte %01111111 ; $7f
	.byte %11110110 ; $F6
	.byte %01110000 ; $70
	.byte %11000000 ; $C0
	.byte %11000000 ; $C0

	org $3000
pmg:
unused .ds [768/2]
missile .ds [256/2]
p0_shape .ds[256/2]
p1_shape .ds[256/2]
p2_shape .ds[256/2]
p3_shape .ds[256/2]
mud_pos .ds[256]	

