;;;;;; SOUND 
AUDF1	equ $D200
AUDC1	equ $D201
AUDCTL	equ $D208
SKCTL   equ $D20F

;;;;;; GFX
CHBAS equ $2F4

GPRIOR  equ $026F
ADRESS equ $64

; OS functions
TIMER1  equ $13
TIMER2  equ $14
SUBSTRACT equ $F57A

EOR_VALUE equ $4 ; RAMLO

COLOR4	equ $02c8

generated equ $4000

font equ $8000

	org $8A-$15 ; $8A is ptr address but also opcode for TXA
start:
; this chargen is inspired by Dotty Veil (Blueberry) which is sooo cool that it's a sin not to use it ;)
; here optimized for Atari font and for zero page
;;;;; font generator
	ldy #0
loop:
	tya
	asl
	asl
	asl
	beq next
	asl
	asl
	asl
	beq char
	bcc next
	dec ptr
	.byte $A9
next:
	inc ptr
char:

ptr equ *+1
	lda char_table-1
	
	sta font,y ; we use Y to have it zeroes
	iny
	bne loop
	
	; y=0
	sty TIMER1

;;;;; set gfx
	lda #$40
	sta GPRIOR 
	asl ; #$80
	sta CHBAS		
	sta COLOR4

		
NEXT_FRAME:
	; Y must be 0
	tya
	adc TIMER2
	adc #$40
	asl
	and #%10111000
	sta AUDC1
	bne skip_generation

.local gen_function
	; X=FF, Y=0
	lda TIMER1
	lsr
	and #7
	tax
	lda patterns,x
	sta AUDF1
	sta eor_value
loop
	adc #1
eor_value equ *+1
	eor #$0
	sta (generated_ptr),y ; tab on ZP? sty zp,x
	inc loop+1
	iny
	bne loop
.endl


skip_generation
	; end of the screen
	;y=0
	dey ; y=$FF
	sty ADRESS 
	lda #$BF
	sta ADRESS+1 
	ldx #23 ; row
NEXT_ROW:

	ldy #40 ; column
	tya
	jsr substract
ROW_LOOP:

	lda TIMER2
	adc (generated_ptr),y
generated_ptr equ *+1
	adc generated,x 	
	sta (adress),y
	dey
	bne ROW_LOOP		
	dex	
	bpl NEXT_ROW		
	bmi NEXT_FRAME	

char_table:
patterns equ *+3
	.byte $FF,$FF,$FF,$FF
	.byte $E7,$C3,$B1,$81,$61,$40,$31


	