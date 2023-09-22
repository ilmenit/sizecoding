SAFE_VERSION = 0

SCREEN_WIDTH equ 160
SCREEN_HEIGHT equ 96
screen_page_in_dl equ $AF9D

CAMERA_HEIGHT equ 110
MAX_DISTANCE equ 64
MAX_HEIGHT equ (SCREEN_HEIGHT/2)
LINES equ 8
DISTANCE_STEP equ (MAX_DISTANCE / LINES)

;;;;;;;;;;;;;;;;;
ROWCRS	equ $54		;Row of cursor, 1 byte
COLCRS	equ $55		;Column of cursor, 2 bytes
cursor_y    equ ROWCRS
cursor_x    equ COLCRS

ADRESS  equ $64 ; current plot address
SAVMSC  equ $58 ; screen address

;;;;;; GFX
COLOR0	equ $02c4

; SFX
AUDF1	equ $D200

RANDOM	equ $d20a

; OS functions
os_openmode  equ $ef9c
os_drawpoint equ $f1d8  
os_clrscr    equ $f420  ; clear ADRESS up
os_sms       equ $F9A6	; copy SAVMSC -> ADRESS		 
;;;;;;;;;;;;;;;;; CODE ;;;;;;;;;;;;;;;;;;;;

	org $3
line_step_hi
projected_distance_hi .ds[1]
line_step_lo
projected_distance_lo .ds[1]

	org $20
plot_y .ds[1]

line_x
calc_height .ds[2]

terrain_gen_val .ds[1]

line_index .ds[1]
move_counter .ds[1]

	org $42 ; should be 0, we need 0 for lower byte of the pointer
projection_table_ptr .ds[2]

	org $7B-1

program_data
.IF SAFE_VERSION=0
	bvc start
.ENDIF
delta_data equ *-1 ; $7B will become 0 on open_mode
	.byte 1, 3, 2
distance .byte MAX_DISTANCE-1 ; becomes -1 after calc_projection
	.byte -3,-2	
terrain_line_ptr .word (terrain_line + 256*(LINES-1)) ; lower byte must be 0 and we can use this 0 for the delta_data
delta_data_end

start:
.local init_gfx

	lda #7	; 2 bytes
	jsr os_openmode	; 3 bytes, Changes $7B (SWPFLG) on zero page to zero so we can't load data there
	; A=00 X=07 Y=01
.endl

.local calc_projection

	; for (distance = MAX_DISTANCE-1; distance < MAX_DISTANCE; --distance)
distance_loop:
	jsr set_projection_ptr_by_distance

	ldy #(CAMERA_HEIGHT-1)
	; for (height = CAMERA_HEIGHT-1; height < CAMERA_HEIGHT; --height)
height_loop:

	; high-byte
	; calc_height.B.h = CAMERA_HEIGHT - height;

	; reverse substraction 
	; https://wiki.nesdev.org/w/index.php/Synthetic_instructions#Reverse_subtraction
	tya
	sta AUDF1-3,y ; sound 6/10
	eor #$FF
	adc #(CAMERA_HEIGHT)
	
	STA calc_height+1
	
	; projected_distance.W = (word)distance * 16;
	; idea for *16 by barrym
	
	lda distance
    	sta projected_distance_lo
    	lda #$10
mul_loop:
    	asl projected_distance_lo
    	rol 
    	bcc mul_loop
    	sta projected_distance_hi
	
	; ++projected_distance.B.h;
	inc projected_distance_hi
	
	; plot_y = calc_height.W / (projected_distance.W);

	.local divide
	// *** dividend / divisor = quotient
	// result must fit in 1 byte (!)	
	ldx #$FF
loop:	
	inx
	jsr substract_word
	bcs loop
	.endl
	; result is in X, move to A
	txa		
	; store it
	sta (projection_table_ptr),y
	sta COLOR0-52,y ; set colors to red/pink

next_height:

dst_adr  ; in copy_buffer becomes ZP pointer $6088
dst_adr_hi equ dst_adr+1
	dey 
	bpl height_loop

next_distance:
	dec distance
	bpl distance_loop	
.endl

.local gen_lines

next_line_loop:
next_pixel_loop:	

;	if (random_byte() & 1)
;		++terrain_gen_delta;
;	else
;		--terrain_gen_delta;

	; X reg is terrain_gen_delta
	lda RANDOM
	bpl decrease_x
	inx
	inx
decrease_x:
	dex
	
	; terrain_gen_val += delta_vals[terrain_gen_delta & 7];
	
	txa
	and #7
	tax		
	lda delta_data,x	
	clc ; must be present (?) - adjust table?
	adc terrain_gen_val
	; if (terrain_gen_val > SCREEN_SIZE_Y) // below 0
	bmi negative
	cmp #MAX_HEIGHT
	bcc store

too_high:
	inx ; more peaks, less flat
	lda #MAX_HEIGHT
	bne store

negative:	
	lda #0
;	txa ; potential optimization by 1 byte, x is delta_data index 0-7, close enough to 0 
store:
	sta terrain_gen_val
	sta (terrain_line_ptr),y
next_pixel:
	dey
	bne next_pixel_loop
next_line:
	dec terrain_line_ptr+1
	bmi next_line_loop ; because terrain data starts at $8000
.endl


.local main_loop	
infinite_loop:

.local copy_buffer	        
init_addresses:        

	jsr os_sms ; copy SAVMSC -> ADRESS
	asl ; $60 ;        lda #>new_screen_memory
        sta screen_page_in_dl
        sta calc_projection.dst_adr_hi
        
;        ldx #$00 ; not needed, we don't care how much we copy from the first page
        ldx #14 ; pages to copy
copy_page:
	lda (adress),y	
	sta (calc_projection.dst_adr),y
        iny
        bne copy_page

        inc adress+1
        inc calc_projection.dst_adr_hi

	dex
        bpl copy_page
.endl

	jsr os_clrscr ; clear also y_buffer, which is placed after the screen memory

.local draw_lines	
	ldx #(LINES-1)
	stx line_index

	; distance = move_counter % LINES;
	lda move_counter
	sax distance ; and #(LINES-1) ; sta distance
	
	; for (line_index = LINES-1; line_index < LINES; --line_index)
loop:
	; current_line = ((move_counter/8) + line_index) % LINES;
	lda move_counter
	:3 lsr ; /8
	clc ; must be present
	adc line_index
	and #(LINES-1)
	
.local draw_line
	; set pointer to data
	adc #>terrain_line
	sta terrain_line_ptr+1
	
	; set pointer to projection
	jsr set_projection_ptr_by_distance

	; line_x.B.h = 64 + 127 + distance;
;	lda distance ; we set distance related value to A in set_projection_ptr_by_distance
	sta line_x+1
	; line_x.B.l = 0;
	ldy #0
	sty line_x
	;line_step.B.h = 1;
	iny 
	sty line_step_hi
	;line_step.B.l = distance * 4;
	lda distance
	:2 asl
	sta line_step_lo
	
	; cursor_x = SCREEN_SIZE_X - 1;
	lda #SCREEN_WIDTH-1
	sta cursor_x
plot_loop:

	; byte height = lines_height[current_line][line_x.B.h];	
	lda line_x+1
	tay
	lda (terrain_line_ptr),y
	; A = height
	
	; cursor_y = projection_table[distance][height];	
	tay
	lda (projection_table_ptr),y	
	sta cursor_y
	
	; if (cursor_y < y_buffer[cursor_x])	
	ldy cursor_x
	eor #$FF ; negate A (cursor_y), because we have y_buffer reversed
	cmp y_buffer,y
	bcc skip_drawing
	
	; y_buffer[cursor_x] = cursor_y;
	sta y_buffer,y
	
	; plot
	jsr os_drawpoint

skip_drawing
	; line_x.W -= line_step.W;
	jsr substract_word

next_plot:
	dec cursor_x
	bne plot_loop
.endl

	; distance += DISTANCE_STEP;
	clc
	lda distance
	adc #DISTANCE_STEP
	sta distance	
next_loop:
	dec line_index
	bpl loop
	
	; fly forward
	dec move_counter
.endl

	jmp infinite_loop
.endl


.proc substract_word
;	sec				
	lda calc_height
	sbc projected_distance_lo	
	sta calc_height
	lda calc_height+1		
	sbc projected_distance_hi
	sta calc_height+1
	rts
.endp

.proc set_projection_ptr_by_distance
	clc
	lda #>projection_table
	adc distance
	sta projection_table_ptr+1
	rts
.endp

	org $1000; $1000 - $5000 - projection table
projection_table .ds[256*MAX_DISTANCE]

	org $8000 ; now needs to be at $8000
terrain_line .ds[256*LINES]

	org $6088
new_screen_memory .ds[256*14]

	org $BF60 ; we clear it with the screen so we have to use reversed height here
y_buffer .ds[SCREEN_WIDTH] ; on the first/last line drawn set to max_height

.IF SAFE_VERSION=1
	RUN start
.ENDIF

