COLOR0	equ $02c4
COLOR1	equ $02c5
COLOR2	equ $02c6
COLOR3	equ $02c7
COLOR4	equ $02c8

RANDOM	equ $d20a

; OS functions
openmode  equ $ef9c
drawto    equ $f9c2

COLOR   equ $2fb	;Color for graphics operations

ROWCRS	equ $54		;Row of cursor, 1 byte
COLCRS	equ $55		;Column of cursor, 2 bytes

OLDROW  equ $5A
OLDCOL  equ $5B     ; 2 bytes

; Aliases, because orig reg names are hard to remember ;)
cursor_y    equ ROWCRS
cursor_x    equ COLCRS
prev_y      equ OLDROW
prev_x      equ OLDCOL

; I had plenty of space so I didn't have to use stack like in https://www.pouet.net/prod.php?which=55951

	org $80	
start:
	lda #8
	jsr openmode
	sty COLOR2
draw:
	dec point
	ldy point
	lda point_y,y 
	sta cursor_y
	sta color
	lda point_x,y
	sta cursor_x
	jsr drawto
	bvc draw
	
;point .byte 45
point .byte 127
point_x:
	.byte 146,156,162,230,213,191,169,163,179,191,168,162,165,185,190,216
	.byte 231,254,218,174,174,151,148,138,134,136,137,125,125,135,153,153
	.byte 145,144,139,139,134,136,133,102,84,66,98,98,92
point_y:
	.byte 151,151,146,71,59,57,63,69,67,71,71,75,79,79,83,83
	.byte 99,171,177,191,191,189,181,181,177,173,151,131,111,91,73,65
	.byte 59,51,49,43,37,23,19,19,5,0,29,37,46
	