COLOR0	equ $02c4
COLOR1	equ $02c5
COLOR2	equ $02c6
COLOR3	equ $02c7
COLOR4	equ $02c8

RANDOM	equ $d20a
SAVMSC  equ $58 ; screen address

; OS functions
openmode  equ $ef9c
drawto    equ $f9c2
drawto2    equ $f9c4
drawpoint equ $f1d8
drawpoint2 equ $f1dB
getpoint  equ $f18f

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

code_load equ $100-code_size

	org code_load
start:	
	lda #8
	jsr openmode
;	sty color2 ; bw
	ldx #$FF
;	stx color2 ; yellow	
	txs
	rol SAVMSC+1	
draw:
 	pla		
  	sta color	
	beq show
	sta cursor_x
 	pla		
	jsr drawto2 ; jumping to "middle of function" to avoid sta cursor_y
	stx color2 ; grey
	bvc draw
show
show_loop
	ror SAVMSC+1
	jsr drawpoint2 ; jumping to "middle of function" to avoid storing of color
	rol SAVMSC+1
	inc cursor_x
	lda RANDOM
	sta cursor_y
	jsr getpoint
	bvc show

code_size equ *-start
.print "CODE SIZE: ", code_size	

data:
	.byte 64,0,83,6,101,20,133,20,135,23,133,38,139,44,139,49,143,52,145,59,153,66,153,73,135,92
	.byte 125,112,125,131,137,152,135,174,133,178,137,182,147,182,151,191,217,178,253,171,231,99,215,84,189,83,185,80
	.byte 165,79,161,75,167,72,191,71,179,67,163,70,169,64,191,57,213,60,160,148,147,154
	