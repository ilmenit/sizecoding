TIMER1  equ $13 ; slower one
TIMER2  equ $14 ; faster one
VCOUNT	equ $D40B
AUDC2	equ $D203
HPOSP0	equ $D000 ; Player 0 Horizontal Position
HPOSP1	equ $D001 ; Player 1 Horizontal Position
GRAFP0	equ $D00D ; Player 0 Graphics Pattern
COLPM0	equ $D012 ; Player/Missile 0 color, GTIA 9-color playfield color 0 for Background

openmode  equ $ef9c

	org $80
vc .ds[1]
start

	lda #1
	jsr openmode 	
loop:
	; x=0 to 3
	tax
	asl
	; y=0,2,4,6
	sta branch

	lda TIMER2
	and patterns,x
	sta AUDC2

	lda vcount
	sta vc ; because vcount address is 2 bytes long and we need it to be 1 byte long

 	lda TIMER2
	bcc @+
branch equ *-1
next
@
	adc vc
@	
	adc vc
@
	eor vc
@

	; x=0-3 
	inx
regs:
 	sta GRAFP0,x
	sta COLPM0,x
	dex
	bpl regs

    	sta HPOSP0
    	eor #$FF
    	sta HPOSP1
		
	lda TIMER1
	lsr
	eor #$FF
	and #3	
	bpl loop  ; infinite loop

patterns
	.byte %00101011 
	.byte %00111000 
	.byte %00101000 
	.byte %00111000 	
