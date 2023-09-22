ROWCRS	EQU	$0054	;1-byte cursor row
COLCRS	EQU	$0055	;2-byte cursor column
OLDROW	EQU	$005A	;1-byte prior row
OLDCOL	EQU	$005B	;2-byte prior column

; Aliases, because orig reg names are hard to remember ;)
cursor_y    equ ROWCRS
cursor_x    equ COLCRS
prev_y      equ OLDROW
prev_x      equ OLDCOL

COLOR   equ $2fb	;Color for graphics operations

PCOLR0	equ $02C0				;p/m 0 color
PCOLR1	equ $02C1				;p/m 1 color
PCOLR2	equ $02C2				;p/m 2 color
PCOLR3	equ $02C3				;p/m 3 color
COLOR0	equ $02c4


COLPF0	equ $D016
COLPF1	equ $D017
COLPF2	equ $D018
COLPF3	equ $D019
COLBK	equ $D01A


HPOSP0 = $D000 ; Player 0 Horizontal Position
HPOSP1 = $D001 ; Player 1 Horizontal Position
HPOSP2 = $D002 ; Player 2 Horizontal Position
HPOSP3 = $D003 ; Player 3 Horizontal Position

SIZEP0 = $D008 ; Player 0 Size
COLPM2 = $D014 ; Player/Missile 2 color, GTIA 9-color playfield color 2

AUDCTL	equ $D208

WSYNC equ  $D40A ; Wait for Horizontal Sync

VCOUNT	equ $D40B

; OS functions
os_openmode  equ $ef9c
os_drawto    equ $f9c2

;; intro defines

STAIRS_BOTTOM equ $A2
;STAIRS_RIGHT equ $5D
STAIRS_RIGHT equ $50

;SAVMSC is $A150

screen_y equ $0
temp equ $3

	org $80
	bvc start

data
sky_hi_location
	.byte $FF ; yellow color p2 for rays
left 
	.byte $0F ; white for clouds
colors 
	.byte 7 ; gray
sky_lo_location
	.byte 0 ; black
	.byte $8F ; white
gate_height
	.byte $24 ; not used in this mode
	.byte $86 ; background middle-blue
start:
	lda #15
	
	jsr os_openmode
	; a=?/0, x=15, y=1

.local set_colors
loop:
	lda $C9A0,x
	sta AUDCTL-8,x

	lda #$FF
	sta SIZEP0-4,x 
	lda colors-(colors-data),x ; sets also colors of player
	sta color0-(colors-data),x
	dex
rom_location
	bpl loop
	; x = 0, A = last reg
.endl

	lda #STAIRS_BOTTOM

.local draw_stairs
	; last register A value from loop ; lda #STAIRS_BOTTOM
	sta cursor_y
	sta prev_y

	lda #STAIRS_RIGHT
	sta cursor_x	
loop:	
	inc color	
	dec cursor_y	
	
	lda left
	sta prev_x
	
	jsr os_drawto
	; x=2, y=1
next_loop:
	lda cursor_y
	and #%1000
	beq vertical
diagonal:
	dec color
	:2 inc left
	inc cursor_x	
vertical:
	bpl loop
.endl


.local draw_gate
loop:	
	lda left
	sta prev_x
	jsr os_drawto
next_loop:
	dec cursor_y
	dec prev_y
	dec gate_height
	bne loop
.endl

screen_loop:
	ldy VCOUNT
	tya
	asl
	sta COLPF2
	adc #$6D
	sta HPOSP2
	tya
	adc (sky_lo_location),y
	sta (sky_lo_location),y	
	lda (sky_hi_location),y
	sbc #0
	sta (sky_hi_location),y		
	adc (set_colors.rom_location),y	; add "random" rom value - 1 byte shorter version of "adc $F048,y"	 
	sta wsync
	sta HPOSP3
	jmp screen_loop
	