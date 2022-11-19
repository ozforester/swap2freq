; Copyright (c) 2022 ozforester. All rights reserved.
; Use of this source code is goverened by a MIT license
; tiny13 internal@4MHz ( E:0xFF, H:0xFF, L:0x79 )
; si5351a swaps two predefined set of registers

#include <avr/io.h>
#undef  __SFR_OFFSET
#define __SFR_OFFSET 0
#define SHIT 0
#define SIADDR 0xC0 /* si5351a */
#define LCDADDR 0x78 /* ssd306 32x128*/
#define twi_port PORTB
#define twi_pin  PINB
#define twi_ddr  DDRB
#define scl PB3
#define sda PB4
#define ack 6 ; ack-bit

accL     = 0    ; mul low
accH     = 1    ; mul high
temp     = 16	; common reg
data     = 17	; twi data reg
char     = 18	; osc register number
memc	 = 19	; osc register value
rc       = 20	; registers counter
bytec    = 21	; i2c byte shift
state    = 22	; i2c status
twcntr   = 23	; i2c clock delay
dlcntr   = 24   ; time delay
address  = 25   ; current twi device
posX     = 26
posY     = 27

register = 18   ; osc register number
value    = 19   ; osc register value

.section .text

init1_seq:              ; stage1 init
.byte 11                ; sequency size
.byte 0x20, 0x00        ; set addressing mode horizontal
.byte 0x21, 0, 127      ; set column start 0 and stop 127
.byte 0x22, 0, 7        ; page start 0 and end 7
.byte 0                 ; pm dummy

init2_seq:              ; stage2 init
.byte 3                 ; sequency size
.byte 0x8d, 0x14, 0xaf  ; charge pump enable and display on

#define REG_SIZE 39

prim: ; 1 MHz -> clk0, 2 MHz -> clk1
.byte   3, 0xff ; clk outputs off
.byte  16, 0xcf ; drv outputs off
.byte  17, 0xef ; drv outputs off
.byte  26, 0xff ; plla
.byte  27, 0xff
.byte  28, 0x00
.byte  29, 0x10
.byte  30, 0x00
.byte  31, 0xf0
.byte  32, 0x00
.byte  33, 0x00
.byte  42, 0x00 ; ms0
.byte  43, 0x01
.byte  44, 0x01
.byte  45, 0xc0
.byte  46, 0x00
.byte  47, 0x00
.byte  48, 0x00
.byte  49, 0x00
.byte  34, 0xff ; pllb
.byte  35, 0xff
.byte  36, 0x00
.byte  37, 0x10
.byte  38, 0x00
.byte  39, 0xf0
.byte  40, 0x00
.byte  41, 0x00
.byte  50, 0x00 ; ms1
.byte  51, 0x01
.byte  52, 0x00
.byte  53, 0xdf
.byte  54, 0x00
.byte  55, 0x00
.byte  56, 0x00
.byte  57, 0x00
.byte 177, 0xa0 ; pll soft reset
.byte  16, 0x4f ; 0100 1111 ms0->clk0
.byte  17, 0x6f ; 0110 1111 ms1->clk1
.byte   3, 0xfc ; clk outputs on

cross: ; 2 MHz -> clk0, 1 MHz -> clk1
.byte   3, 0xff ; clk outputs off
.byte  16, 0xcf ; drv outputs off
.byte  17, 0xef ; drv outputs off
.byte  26, 0xff ; plla
.byte  27, 0xff
.byte  28, 0x00
.byte  29, 0x10
.byte  30, 0x00
.byte  31, 0xf0
.byte  32, 0x00
.byte  33, 0x00
.byte  42, 0x00 ; ms0
.byte  43, 0x01
.byte  44, 0x00
.byte  45, 0xdf
.byte  46, 0x00
.byte  47, 0x00
.byte  48, 0x00
.byte  49, 0x00
.byte  34, 0xff ; pllb
.byte  35, 0xff
.byte  36, 0x00
.byte  37, 0x10
.byte  38, 0x00
.byte  39, 0xf0
.byte  40, 0x00
.byte  41, 0x00
.byte  50, 0x00 ; ms1
.byte  51, 0x01
.byte  52, 0x01
.byte  53, 0xc0
.byte  54, 0x00
.byte  55, 0x00
.byte  56, 0x00
.byte  57, 0x00
.byte 177, 0xa0 ; pll reset
.byte  16, 0x4f ; 0100 1111 ms0->clk0
.byte  17, 0x6f ; 0110 1111 ms1->clk1
.byte   3, 0xfc ; clk outputs on

ascii:
.byte 0x3E, 0x51, 0x49, 0x45, 0x3E, 0x00 ; '0' 48
.byte 0x00, 0x00, 0x42, 0x7F, 0x40, 0x00 ; '1' 49
.byte 0x00, 0x61, 0x51, 0x49, 0x46, 0x00 ; '2' 50
.byte 0x21, 0x41, 0x45, 0x4B, 0x31, 0x00 ; '3' 51
.byte 0x18, 0x14, 0x12, 0x7F, 0x10, 0x00 ; '4' 52
.byte 0x27, 0x45, 0x45, 0x45, 0x39, 0x00 ; '5' 53
.byte 0x3C, 0x4A, 0x49, 0x49, 0x30, 0x00 ; '6' 54
.byte 0x01, 0x71, 0x09, 0x05, 0x03, 0x00 ; '7' 55
.byte 0x36, 0x49, 0x49, 0x49, 0x36, 0x00 ; '8' 56
.byte 0x06, 0x49, 0x49, 0x29, 0x1E, 0x00 ; '9' 57

msg1: .asciz "1000000"
msg2: .asciz "2000000"

.macro ssd1306_cur px, py       ; x=0..20, y=0..7
        ldi posX, \px           ; 1
        add posX, posX          ; 2
        add posX, posX          ; 3
        add posX, posX          ; 4
        add posX, posX          ; 5
        add posX, posX          ; 6
        ldi posY, \py           ;
        rcall ssd1306_pos       ;
.endm                           ;

.macro pulldown wire            ;
        sbi twi_ddr, \wire      ;
        cbi twi_port, \wire     ;
        nop                     ;
.endm                           ;

.macro release wire             ;
        cbi twi_ddr, \wire      ;
        cbi twi_port, \wire     ;
.endm                           ;

.macro latch                    ; clock pulse
        release scl             ;
        waitrelease scl         ; delayed till stable high
        nops                    ;
        pulldown scl            ;
        nops                    ;
.endm                           ;

.macro waitrelease wire         ;
        wf\@:                   ;
        sbis twi_pin, \wire     ;
        rjmp wf\@ ; if sinked   ;
.endm                           ;

.macro nops                     ; huge delay
        nop                     ;
        nop                     ;
        nop                     ;
        nop                     ;
        nop                     ;
        nop                     ;
        nop                     ;
        nop                     ;
        nop                     ;
        nop                     ;
        nop                     ;
        nop                     ;
        nop                     ;
        nop                     ;
        nop                     ;
        nop                     ;
        nop                     ;
        nop                     ;
        nop                     ;
        nop                     ;
        nop                     ;
.endm                           ;

.global main

main:				;
        rcall ssd1306_init      ;

	m1:

        ldi ZL, lo8(prim)      ; CLK0
        ldi ZH, hi8(prim)      ;
	ldi rc, REG_SIZE	; table size
        rcall burst             ;

        ldi ZH, hi8(msg1)        ;
        ldi ZL, lo8(msg1)        ;
        ssd1306_cur 0, 0        ;
        rcall ssd1306_string    ;
        ldi ZH, hi8(msg2)        ;
        ldi ZL, lo8(msg2)        ;
        ssd1306_cur 0, 1        ;
        rcall ssd1306_string    ;

        rcall delay_1s

        ldi ZL, lo8(cross)      ;
        ldi ZH, hi8(cross)      ;
        ldi rc, REG_SIZE        ; table size
        rcall burst             ;

        ldi ZH, hi8(msg2)        ;
        ldi ZL, lo8(msg2)        ;
        ssd1306_cur 0, 0        ;
        rcall ssd1306_string    ;
        ldi ZH, hi8(msg1)        ;
        ldi ZL, lo8(msg1)        ;
        ssd1306_cur 0, 1        ;
        rcall ssd1306_string    ;

        rcall delay_1s

	rjmp m1			;
ret				;

ssd1306_pos:                    ; cursor position
	ldi address, LCDADDR	;
        rcall i2c_start         ;
        rcall i2c_slaw          ;
        ldi data, 0x80          ; command
        rcall i2c_write         ;
        ldi data, 0x20          ; mode
        rcall i2c_write         ;
        ldi data, 0x80          ; command
        rcall i2c_write         ;
        ldi data, 0x00          ; horizon
        rcall i2c_write         ;
        ldi data, 0x80          ; command
        rcall i2c_write         ;
        ldi data, 0x21          ; col
        rcall i2c_write         ;
        ldi data, 0x80          ; command
        rcall i2c_write         ;
        mov data, posX          ; 0 - 127
        rcall i2c_write         ;
        ldi data, 0x80          ; command
        rcall i2c_write         ;
        ldi data, 127           ;
        rcall i2c_write         ;
        ldi data, 0x80          ; command
        rcall i2c_write         ;
        ldi data, 0x22          ; page
        rcall i2c_write         ;
        ldi data, 0x80          ; command
        rcall i2c_write         ;
        mov data, posY          ; 0 - 7
        rcall i2c_write         ;
        ldi data, 0x80          ; command
        rcall i2c_write         ;
        ldi data, 7             ;
        rcall i2c_write         ;
        rcall i2c_stop          ;
ret                             ;

ssd1306_string:                 ;
        ;ldi ZH, hi8(msg)        ; z *-> msg
        ;ldi ZL, lo8(msg)        ;
        ss1:                    ;
        lpm                     ; read msg word into r0
        mov char, accL          ; copy word into char register
        cpi char, 0             ;
        breq ss2                ;
        rcall ssd1306_ascii     ; write one char
        adiw ZL, 1              ;
        rjmp ss1                ; not zero
        ss2:                    ;
ret                             ;

ssd1306_ascii:                  ; got char reg
        push ZL                 ;
        push ZH                 ;
        ldi ZH, hi8(ascii)      ; z *-> ascii
        ldi ZL, lo8(ascii)      ;
        subi char, 48           ; 1
	mov temp, char		; 1
        add char, temp          ; 1+1
        add char, temp          ; 2+1
        add char, temp          ; 3+1
        add char, temp          ; 4+1
	add char, temp		; 5+1=6
        clr temp
        add ZL, char            ; add calculated offset
        adc ZH, temp            ; to pm table ptr
        ldi address, LCDADDR    ;
        ldi memc, 6             ; 1-st byte is a font width
        rcall i2c_start         ; twi
        rcall i2c_slaw          ; twi
        ldi data, 0x40          ; continuous data
        rcall i2c_write         ;
        pr1:                    ;
        lpm data, Z             ; read pm
        rcall i2c_write         ;
        dec memc                ;
        breq pr2                ;
        adiw Z, 1               ;
        rjmp pr1                ; next
        pr2:                    ;
        rcall i2c_stop          ; twi
        pop ZH                  ;
        pop ZL                  ;
ret                             ;

ssd1306_clear:                  ;
        ldi address, LCDADDR    ;
        rcall ssd1306_home      ;
        ldi YL, lo8(1024)       ;
        ldi YH, hi8(1024)       ;
        rcall i2c_start         ;
        rcall i2c_slaw          ;
        ldi data, 0x40          ; data continuous
        rcall i2c_write         ;
        clr1:                   ;
        clr data                ;
        rcall i2c_write         ; plot
        subi YL, 1              ;
        sbci YH, 0              ;
        brne clr1               ; continue data flow
        rcall i2c_stop          ;
        rcall ssd1306_home      ;
ret                             ;

ssd1306_home:                   ;
        ldi address, LCDADDR    ;
        rcall i2c_start         ;
        rcall i2c_slaw          ;
        ldi data, 0x80          ; cmd
        rcall i2c_write         ;
        ldi data, 0x20          ; mode
        rcall i2c_write         ;
        ldi data, 0x80          ; cmd
        rcall i2c_write         ;
        ldi data, 0x00          ; mhorizontal
        rcall i2c_write         ;
        ldi data, 0x80          ; cmd
        rcall i2c_write         ;
        ldi data, 0x21          ; lines 0 - 127
        rcall i2c_write         ;
        ldi data, 0x80          ; cmd
        rcall i2c_write         ;
        ldi data, 0             ;
        rcall i2c_write         ;
        ldi data, 0x80          ; cmd
        rcall i2c_write         ;
        ldi data, 127           ;
        rcall i2c_write         ;
        ldi data, 0x80          ; cmd
        rcall i2c_write         ;
        ldi data, 0x22          ; pages 0 - 7
        rcall i2c_write         ;
        ldi data, 0x80          ; cmd
        rcall i2c_write         ;
        ldi data, 0             ;
        rcall i2c_write         ;
        ldi data, 0x80          ; cmd
        rcall i2c_write         ;
        ldi data, 7             ;
        rcall i2c_write         ;
        rcall i2c_stop          ;
ret                             ;

ssd1306_init:                   ;
	ldi address, LCDADDR	;
        ldi ZL, lo8(init1_seq)  ;
        ldi ZH, hi8(init1_seq)  ;
        lpm memc, Z             ; read block size
        adiw Z, 1               ; next byte
        rcall i2c_start         ;
        rcall i2c_slaw          ;
        ssd1:                   ;
        ldi data, 0x80          ; command
        rcall i2c_write         ;
        lpm data, Z             ;
        rcall i2c_write         ; 0x20, 0x00   ; set addressing mode horizontal
        dec memc                ; 0x21, 0, 127 ; set column start 0 and stop 127
        breq ssd2               ; 0x22, 0, 7   ; page start 0 and end 7
        adiw Z, 1               ;
        rjmp ssd1               ; next
        ssd2:                   ;
        rcall i2c_stop          ;
        rcall ssd1306_clear     ;
        ldi ZL, lo8(init2_seq)  ;
        ldi ZH, hi8(init2_seq)  ;
        lpm memc, Z             ; read block size
        adiw Z, 1               ; next byte
        rcall i2c_start         ;
        rcall i2c_slaw          ;
        ssd3:                   ;
        ldi data, 0x80          ; command
        rcall i2c_write         ;
        lpm data, Z             ;
        rcall i2c_write         ; 0x8d, 0x14, 0xaf ; charge pump enable and display on
        dec memc                ;
        breq ssd4               ;
        adiw Z, 1               ;
        rjmp ssd3               ; next
        ssd4:                   ;
        rcall i2c_stop          ;
        rcall ssd1306_home      ;
ret                             ;

burst:			    	;
	push register
	push value
	ldi address, SIADDR	;
        burst1:                 ;
        lpm register, Z     	; read numb
        adiw Z, 1		;
        lpm value, Z        	; read value
        rcall write_reg         ;
        dec rc                  ;
	breq burst2		;
        adiw Z, 1		;
	rjmp burst1		; next reg
	burst2:			;
	pop value
	pop register
ret				;

write_reg:			;
        rcall i2c_start         ;
        rcall i2c_slaw          ;
	mov data, register	;
        rcall i2c_write         ;
        mov data, value		;
        rcall i2c_write         ;
        rcall i2c_stop          ;
ret				;

i2c_start: ; start condition
        waitrelease scl
        pulldown sda
        pulldown scl
ret

i2c_stop: ; stop condition
        release scl
        waitrelease scl
        release sda
ret

i2c_slaw:
	mov data, address
	rcall i2c_write
ret

i2c_write: ; send byte (<data)
        cbr state, 1<<ack ; clear ack bit
        ldi bytec, 8
	twn:
	sbrs data, 7 ; msb
        rjmp msb_low ; not set
        release sda ; set
        rjmp tws
	msb_low:
	pulldown sda
	tws:
	latch
        lsl data ; shift next to msb
        dec bytec
        brne twn ; next till zero
        release sda
        release scl ; and
        waitrelease scl ; wait
        sbis twi_port, sda ; ack
        sbr state, 1<<ack ; nacked
        nops
        pulldown scl ; ends ack clock
ret

delay_1s:
        rcall delay_100ms
        rcall delay_100ms
        rcall delay_100ms
        rcall delay_100ms
        rcall delay_100ms
        rcall delay_100ms
        rcall delay_100ms
        rcall delay_100ms
        rcall delay_100ms
        rcall delay_100ms
ret

delay_100ms:
        rcall delay_10ms
        rcall delay_10ms
        rcall delay_10ms
        rcall delay_10ms
        rcall delay_10ms
        rcall delay_10ms
        rcall delay_10ms
        rcall delay_10ms
        rcall delay_10ms
        rcall delay_10ms
ret

delay_10ms:
        ldi dlcntr, 255
        dl1:
        push dlcntr
        ldi dlcntr, 100
        dl2:
        dec dlcntr ; +1
        brne dl2 ; +1
        pop dlcntr
        dec dlcntr
        brne dl1
ret

.end
