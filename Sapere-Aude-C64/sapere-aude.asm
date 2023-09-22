; @com.wudsn.ide.asm.hardware=C64

; My very first intro for C64, for Outline 2021
; Why C64? Well... there are not enough tiny intros for this platform!
; By the Compo Rules header size is not counted into the final size. Without the header it is 256 bytes.
; I used therefore 'safe header' (according to my limited C64 knowledge)
;
; The intro is not very well optimized, but I had limited time before the party deadline.
; With more optimizations I believe a better music could fit.
;
; Done in MADS Assembler but should easily work with any other.
;
; Ilmenit / Agenda, May 2021

SIDV3FREQLO = $d40e
SIDV3FREQHI = $d40f
SIDV3PWLO   = $d410
SIDV3PWHI   = $d411
SIDV3CTRL   = $d412
SIDV3AD     = $d413
SIDV3SR     = $d414

SIDFCLO     = $d415
SIDFCHI     = $d416

SIDRESFILT  = $d417
SIDMODEVOL  = $d418     ; Mute3/ HiPass/ BandPass/ LowPass | Main Volume 0-15


SCR_CTRL equ $D011
VIC_CTRL equ $D016
MEM_SETUP equ $D018
BORDER_COLOR equ $D020
BACKGROUND_COLOR equ $D021
COLOR0 equ $D022
COLOR1 equ $D023
COLOR2 equ $D024
FONT_RAM equ $3000
DITHER_SHIFTED equ 0

;TIMER_SLOW equ $A1
;TIMER_FAST equ $A2
NOTE_ID equ $FB
TIMER equ $FC
TIMER_SLOW equ $c2
TIMER_FAST equ $c3

EOR_VALUE equ $2
temp equ $3
Y_VALUE equ $87
sine equ $5

ADRESS equ $BB

SCREEN equ $400

	opt h-f+	;Disable ATARI headers, enable fill mode (no memory gaps)

	org $0801-2
	.word load	;BASIC load address

	;BASIC Tokens for "10 SYS2061"
load
	.word nextline
	.word 10
	.byte $9e, '2061', 0
nextline
	.word 0

	;start = $080d = 2061

start	

.local init_sid
	lda #15
	sta NOTE_ID
	sta SIDMODEVOL
	sta TIMER

;	lda #$F0
;	sta SIDV3SR
	lda #$2B
	sta SIDV3AD

.endl

	lda #%11011000 ; turn on multicolor mode
	sta VIC_CTRL
	
	lda #(%00010000 | %1100) ; keep memory at $400 (%00010000) and select character set to $3000 (%1100)
	sta MEM_SETUP

	;;;;;;;;;;; CLEAR FONT MEMORY
	ldx #0	; TAX
	stx BACKGROUND_COLOR
	stx BORDER_COLOR
	txa
loop0
	sta FONT_RAM+$80,x
	dex
	bne loop0

.local make_chars	
loop:
	txa ; a has byte index
.if DITHER_SHIFTED = 1
	:2 lsr ; /4
.else
	:3 lsr ; /8
	asl ; *2
.endif
	tay ; y has dither_index
	txa ; a has byte index
	ror ; move lowest bit to carry
	bcc skip
	iny ; increase dither_index
skip
	lda DITHER_DATA,y
	sta FONT_RAM,x
	inx
	bpl loop
.endl

	ldx #$FF
	stx TIMER_SLOW
	stx TIMER_FAST

NEXT_FRAME:
	inc TIMER_FAST
	bne skip_sine_generation
	
	inc COLOR1
	
.local gen_sine
	; X=FF, Y=0

	 inc TIMER_SLOW
	 lda TIMER_SLOW
	 and #15
	 tay
	 lda nice_patterns,y
	 sta EOR_VALUE

	 txa
	 ; a=ff
	 ldy #Y_VALUE
loop1:
	 dex
loop2:
	 sta sine-1,y
	 eor EOR_VALUE 
	 dey
	 beq exit_loops
	 stx temp
	 adc temp 
	 bmi loop1
	 inx
	 jmp loop2
exit_loops:
.endl
skip_sine_generation

	dec timer
	bne exit_irq
		
	lda note_id
	inc note_id
	and #7
	tax	

	asl SIDV3CTRL	
		
	lda freqlotab,x
	sta SIDV3FREQLO
	lda freqhitab,x
	sta SIDV3FREQHI
	
	lda #$21
	sta SIDV3CTRL				
	
	lda dt,x
	sta timer
	
exit_irq:

	; end of the screen
	lda #$07
	sta ADRESS+1 
	lda #$97
	sta ADRESS 


	ldx #24 ; row
NEXT_ROW:	
	LDA ADRESS
	SEC
	SBC #40
	STA ADRESS
 	BCS skip	;if no borrow
	DEC ADRESS+1	;adjust high byte
skip	
	
	ldy #40 ; column

ROW_LOOP:
	lda TIMER_FAST
	adc sine,y
	adc sine,x			
	and #$1F	
	sta (adress),y
	dey
	bne ROW_LOOP		
	dex	
	bpl NEXT_ROW			
	bmi NEXT_FRAME
	
DITHER_DATA ; 32 bytes
c0
	.byte %00000000
	.byte %00000000

	.byte %01000000 ; $40
	.byte %00000100 ; $4

	.byte %00010001 ; $11
	.byte %01000100 ; $44

	.byte %00010101 ; $15
	.byte %01010001 ; $51

c1
	.byte %01010101
	.byte %01010101

	.byte %10010101
	.byte %01011001

	.byte %01100110
	.byte %10011001

	.byte %01101010
	.byte %10100110
c2
	.byte %10101010
	.byte %10101010

	.byte %11101010
	.byte %10101110

	.byte %10111011
	.byte %11101110

	.byte %10111111
	.byte %11111011
c3
	.byte %11111111
	.byte %11111111

; dither back to c0
	.byte %00111111
	.byte %11110011

	.byte %11001100
	.byte %00110011

	.byte %11000000
	.byte %00001100

.if DITHER_SHIFTED = 1
; filler
	.byte %00000000
.endif


;       D#2, C2,  G2,  G2,  D#2, C2,  A#2, F2
freqlotab
    dta 251,48,71,251,48,119,152,0
freqhitab
    dta 4,4,6,4,4,7,5,0

dt
    dta 75,89,118,75,89,89,89,1
	
nice_patterns: ; 16
	.byte $80
	.byte $82
	.byte $83
	.byte $f8
	
	.byte $40
	.byte $10
	.byte $11	
	.byte $12
	
	.byte $c2
	.byte $74	
	.byte $f1
	.byte $e2
	
	.byte $60
	.byte $5f
	.byte $51
	.byte $00
    
	
.print "TOTAL: ", *-start