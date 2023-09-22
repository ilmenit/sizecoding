; OS
TIMER1  equ $13
TIMER2  equ $14
ATRACT  equ $4D          	
RANDOM	equ $d20a
;;;;;; SOUND 
AUDC2	equ $D203

; Aliases, because orig reg names are hard to remember ;)
ROWCRS	equ $54		;Row of cursor, 1 byte
COLCRS	equ $55		;Column of cursor, 2 bytes
cursor_y    equ ROWCRS
cursor_x    equ COLCRS

; OS functions
os_openmode  equ $ef9c
os_drawpoint_mid equ $F1DB
	
	org $80
		
start:
	lda #9		; 2 bytes
	jsr os_openmode	; 3 bytes
	sta TIMER1
LOOP:
	lda TIMER2
	sta cursor_x		
	isb cursor_y	
	eor cursor_x	
	sta ATRACT
	jsr os_drawpoint_mid
	lda TIMER2
	and #%00101000 
	eor TIMER1
	sta AUDC2   
	bvc loop    
