SAFE_VERSION = 0

ROWCRS	equ $54		;Row of cursor, 1 byte
COLCRS	equ $55		;Column of cursor, 2 bytes

OLDROW  equ $5A
OLDCOL  equ $5B     ; 2 bytes

SAVMSC  equ $58 ; screen address	

; Aliases, because orig reg names are hard to remember ;)
cursor_y    equ ROWCRS
cursor_x    equ COLCRS
prev_y      equ OLDROW
prev_x      equ OLDCOL

TIMER1  equ $13
TIMER2  equ $14

; colors

HPOSM0  equ $D004 ; Missile 0 Horizontal Position
GRAFM   equ  $D011

AUDF1	equ $D200
AUDC1	equ $D201
AUDCTL	equ $D208
SKCTL   equ $D20F      
RANDOM	equ $d20a

INSTRUMENT equ $A0   

COLOR   equ $2fb	;Color for graphics operations
VCOUNT	equ $D40B

SCREEN_WIDTH equ 40
SCREEN_HEIGHT equ 192

; OS functions
openmode  equ $ef9c
drawpoint equ $f1d8
drawto    equ $f9c2
ZXLY 	  equ $DA48 ; zero data on zero page

	icl "pal_notes.inc"
		
	org $80	
tree_width .ds[1]
tree_color .ds[1]
music_zero_addr ; from this address we zero 14 bytes
	.ds[2] ; buffer expand for zero
tree_count .ds[1]
delay .ds[4]
volume .ds[4]
index .ds[3]
index4	.byte $8c ; potentially set this one in delays and add it to all
delays	
	.byte 0   
	.byte 192
	.byte 128
	.byte 64      
notes
	.byte F_2, GS_2, C_3, CS_3
	.byte DS_3, F_3, GS_3, GS_2

.local screen
frame:

.local rain ; thnx to Koala for idea
infi:
	lda RANDOM	
	pha
	lda TIMER2	
	tax
loop   
	ldy $100,x
        sty GRAFM
	sty HPOSM0
    	dex
	cmp TIMER2
        beq loop        
.endl
	
	ldx #3
.IF SAFE_VERSION=1
	stx SKCTL ; 3 - init sound for proper loading from DOS
.ENDIF
channel_loop:
	; x=channel

	; channel*2 to y
	txa
	asl
	tay
	
	; check if delay
	dec delay,x
	bne play_note
new_note:	
	lda #128 ; channel volume
	sta volume,x
	lda delays,x ; opt to some my code or ROM location
	sta delay,x

	txa ; value to add is channel number
	sec ; +1, so moves
	adc index,x
	sta index,x
	and #7
	clc
	adc #notes
	sta note_smc
		
note_smc equ *+1
	lda notes
	sta AUDF1,y
		
play_note
	lda volume,x
	beq skip_playing
	:5 lsr        	
	adc #INSTRUMENT
	sta AUDC1,y
	dec volume,x
skip_playing
	
channel_next
	dex
	bpl channel_loop
	bmi frame
.endl
	
start:
	lda #9
	jsr openmode
	; A=00 X=15 Y=01

	; clear screen
	lda #175 ; set color to clear and at the same time size
	sta tree_color
	jsr draw_tree

	ldy #14
	sty tree_color
	; 5 bytes, zero music data + 1 for initial = 6, a bit shorter than having the 8
	ldx #music_zero_addr
	jsr ZXLY ; clear: x = adress on ZP, y = len
rom_address equ *-2	
	; A=0
	sta AUDCTL ; 0
	
.local draw_trees
	lda tree_color
.IF SAFE_VERSION=0
	asl
.ENDIF
	sta tree_count
loop

	.local dots
	lda tree_color
	cmp #5 ; limit to background layers
	bmi dots_end
dots_loop:
	lda RANDOM
	sta cursor_y
	jsr drawpoint
	inc cursor_x
	bpl dots_loop	
dots_end
	.endl	

	jsr draw_tree
	
	dec tree_count
	bpl loop

.local draw_terrain
	lda #79
	sta cursor_x
	sta prev_x

	lda tree_color
	:3 asl
	eor #$FF
	adc #160
	sta cursor_y
loop
	lda #SCREEN_HEIGHT
	sta prev_y	
	jsr drawto
	
	lda RANDOM
	bpl skip
	inc cursor_y
	inc cursor_y
skip
	dec cursor_y

	dec prev_x
	dec cursor_x
	bpl loop
.endl

	dec tree_color			
;	bne draw_trees
	bpl draw_trees
.endl

.local fix_top_line ; using spare bytes to fix the top line
	ldy #39
	lda #0
fix:
	sta (savmsc),y
	dey
	bpl fix
.endl
	
	jmp screen 
	
.proc draw_tree
	lda tree_color
	sta color
	bmi nonrandom
next_rand
.IF SAFE_VERSION=1
	lda RANDOM
.ELSE
	dec rom_address	
	lda (rom_address),y
	rol
.ENDIF
	lsr
	sta cursor_x
	sta prev_x
nonrandom
	lda tree_color
	eor #$FF
	adc #8
	sta tree_width

	lda #(SCREEN_HEIGHT-1)
	sta cursor_y
	
loop
	lda #0
	sta prev_y
	
	jsr drawto
	
	inc cursor_x
	dec tree_width
	bpl loop
	rts	
.endp
	; we have space for the RUN
	RUN start 