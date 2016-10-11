; main.s
; Runs on any Cortex M processor
; A very simple first project implementing a random number generator
; Daniel Valvano
; May 4, 2012

;  This example accompanies the book
;  "Embedded Systems: Introduction to Arm Cortex M Microcontrollers",
;  ISBN: 978-1469998749, Jonathan Valvano, copyright (c) 2012
;  Section 3.3.10, Program 3.12
;
;Copyright 2012 by Jonathan W. Valvano, valvano@mail.utexas.edu
;   You may use, edit, run or distribute this file
;   as long as the above copyright notice remains
;THIS SOFTWARE IS PROVIDED "AS IS".  NO WARRANTIES, WHETHER EXPRESS, IMPLIED
;OR STATUTORY, INCLUDING, BUT NOT LIMITED TO, IMPLIED WARRANTIES OF
;MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE APPLY TO THIS SOFTWARE.
;VALVANO SHALL NOT, IN ANY CIRCUMSTANCES, BE LIABLE FOR SPECIAL, INCIDENTAL,
;OR CONSEQUENTIAL DAMAGES, FOR ANY REASON WHATSOEVER.
;For more information about my classes, my research, and my books, see
;http://users.ece.utexas.edu/~valvano/





       THUMB
       AREA    DATA, ALIGN=2
       ALIGN          
       AREA    |.text|, CODE, READONLY, ALIGN=2
       EXPORT  Start

MESSAGE DCB "Nope",0000000000000000000000000000000000000000
	DCB "You are doomed",000000000000000000000000000000
	DCB "Concentrate you fool",000000000000000000000000
	DCB "What a rubbish question",000000000000000000000
	DCB "Only in your dreams",0000000000000000000000000
	DCB "Yes now leave me alone",0000000000000000000000
	DCB "Heh you wish",00000000000000000000000000000000
	DCB "Oh yeah that will happen",00000000000000000000
	DCB "Stop bothering me",000000000000000000000000000
	DCB "Not if you were the last person on earth",0000
	ALIGN


RCGC2 equ 0x400FE108
RCGCUART EQU 0x400FE618
GPIOFBASE EQU 0x40025000
GPIOFDIR EQU 0x40025400
GPIOFDEN EQU 0x4002551C
GPIOFCR EQU 0x40025524
GPIOFLOCK EQU 0x40025520
GPIOFUNLOCK EQU 0x4C4F434B
UART1BASE EQU 0x4000D000
GPIOBAMSEL EQU 0x40005528
GPIOBBASE EQU 0x40005000
GPIOBAFSEL EQU 0x40005420
GPIOBDEN EQU	0x4000551C
UART1DR EQU 0x4000D000
UART1FR EQU 0x4000D018
UART1IBRD	EQU 0x4000D024
UART1FBRD	EQU 0x4000D028
UART1LCRH	EQU 0x4000D02C
UART1CTL	EQU 0x4000D030

	   
Start  
	mov32 R0, #0x400FE108 ; Enable GPIO Clock
	mov R1, #0x22         ; Enable GPIO B (for UART) and GPIO F (for SW2)
	str R1, [R0]
	
	; GPIOF Init
	mov32 R0, #0x40025000
	mov32 R1, #0x4C4F434B
	str R1, [R0,#0x520];GPIO unlock
	mov R1, #0x1F
	str R1, [R0,#0x524];GPIOCR
	mov R1, #0x11
	str R1, [R0,#0x510]
	mov R1, #0xFE       ; PF0 [SW2] is input
	str R1, [R0,#0x400] ;GPIODIR
	mov R1, #0x1F
	str R1, [R0,#0x51C] ;digital enable

	; UART Init
	LDR R0, =RCGCUART
	mov R1, #0x02
	str R1, [R0]       ; Activate UART0
	LDR R0, =UART1CTL
	MOV32 R1, 0xFFFFFFFE
	LDR R2, [R0] ; 
	AND R1, R2, R1       ;
	STR R1, [R0]  ;   Disable UART1
			
	; CFG UART	
	LDR R0, =UART1IBRD
	MOV R1, #0x68   ; IIBRD=int(16000000 / (16*9600)) = int(104.166666667) = 0x68
	STR R1, [R0]
	LDR R0, =UART1FBRD
	MOV R1, #0xB   ; int(0.166666667 * 64 + 0.5) = int(11.166666688) = 11  = 0xB
	STR R1, [R0]
	LDR R0, =UART1LCRH
	MOV R1, #0x70
	STRB R1, [R0, #0x0] ; enable FIFO buffers, 8-bits
	LDR R0, =UART1CTL
	MOV32 R1, 0x00000001
	LDR R2, [R0] ; 
	ORR R1, R2, R1       ;
	STR R1, [R0]  ;   ENable UART1

	; en alt func for PB[1:0]
	LDR R0, =GPIOBAMSEL
	LDR R1, [R0]
	AND R1, #3
	STRB R1, [R0, #0]     ; Enable alternative function for PB[1:0]
	LDR R0, =GPIOBAFSEL
	LDR R1, [R0]
	AND R1, #3
	STRB R1, [R0, #0]     ; Enable alternative function for PB[1:0]
	LDR R0, =GPIOBDEN
	MOV R1, #3
	STR R1, [R0]          ; Digital enable PB[1:0]

; Start coding sadly at 4pm

; start sighing heavily at 4:15pm

; Poll button & serial input section

; Modulo function
udiv10
; This function was taken from THUMB instruction set document from lab supplemental material
; takes argument in r1
; returns quotient in r1, remainder in r2
	PUSH {R4, R5, R6, R7, R8, R9, R10, LR}
	SUB R2, R1, #10
	SUB R1, R1, R1, lsr #2
	ADD R1, R1, R1, lsr #4
	ADD R1, R1, R1, lsr #8
	ADD R1, R1, R1, lsr #16
	MOV R1, R1, lsr #3
	ADD R3, R1, R1, lsl #2
	SUBS R2, R2, R3, lsl #1
	ADDPL R1, R1, #1
	ADDMI R2, R2, #10
	POP {R4, R5, R6, R7, R8, R9, R10, LR}	
	BX LR

; print message to serial port

; print carriage return and line feed function

       B   Start

       ALIGN      
       END  
           