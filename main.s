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


; Start coding
Start  
	BL CHIPINIT
	BL POLLBOTH

	LSL R0, #1
	LDR R1, =0x40025008  ; RED LED
LEDON
	STR R0, [R1]         ; LED ON
	B LEDON
	

;------------------------------------------
; Function to Poll button & serial input section
; INPUT: NOTHING   OUTPUT:  R0 = 1 if ready to send response
POLLBOTH
	PUSH {R4, R5, R6, R7, R8, R9, R10, LR}
	; Poll button
POLLLOOP
	LDR R1, =0x40025004    ; access PF[0] (SW2)
	LDR R2, [R1]
	CMP R2, #0x0           ; PF[0] == 0 if pressed
	BEQ READYTORESPOND
	; Poll Uart Rx Data
	; Check RXFE == 1, if empty, keep looping
	; if RXFE == 0 , then already received data from computer
	; bit [4] of 0x4000D018
	; 0x42000000 + 32*D018 + 4*4 = 0x421A0310
	LDR R1, =0x421A0310
	LDR R2, [R1]
	CMP R2, #0x1          ; 
	BEQ POLLLOOP
READYTORESPOND
	MOV R0, #1
	POP {R4, R5, R6, R7, R8, R9, R10, LR}	
	BX LR

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
; uses modulo10 to randomly select a message


; print carriage return and line feed function
PRINTCR
	PUSH {R4, R5, R6, R7, R8, R9, R10, LR}
	; First check if TXFF == 1 (full)
TXFULLLOOP
	; bit [7] of 0x4000D018
	; 0x42000000 + 32*D018 + 4*7 = 0x421A031C
	LDR R4, =0x421A031C  ; this is bit-banded TXFF
	LDR R5, [R4]         ; R5 will be 0x0 or 0x1 due to bit-banding
	CMP R5, #1
	BEQ TXFULLLOOP

	; This means ok to Tx
	; Tx 0x0D CR
	LDR R4, =UART1DR
	MOV R5, #0x0D     ; Carriage return
	STRB R5, [R4,#0x0]
	POP {R4, R5, R6, R7, R8, R9, R10, LR}	
	BX LR


	B   Start

	   
CHIPINIT
	PUSH {R4, R5, R6, R7, R8, R9, R10, LR}

	mov32 R0, #0x400FE108 ; Enable GPIO Clock
	mov R1, #0x20         ; GPIO F (for SW2)
	str R1, [R0]
	NOP
	NOP
	NOP

	; GPIOF Init
	mov32 R0, #0x40025000  ; GPIOF
	mov32 R1, #0x4C4F434B
	str R1, [R0,#0x520]   ;GPIO unlock
	mov R1, #0x3
	str R1, [R0,#0x524]  ;GPIOCR  
	mov R1, #0x1
	str R1, [R0,#0x510] ; pullup on [0]
	MOV R1, #0x10
	STR R1, [R0,#0x514] ; Pulldown LED so it is off initially
	mov R1, #0xFE       ; PF0 [SW2] is input, PF1 is output
	str R1, [R0,#0x400] ;GPIODIR
	mov R1, #0x1F
	str R1, [R0,#0x51C] ;digital enable

	; UART Init
	; Enable the UART module using the RCGCUART register
	LDR R0, =RCGCUART
	mov R1, #0x02
	str R1, [R0]       ; Activate UART1

	; Enable the clock to the appropriate GPIO module via the RCGCGPIO register
	;Enable GPIO B (for UART) and 
	MOV32 R0, #0x400FE108 ; Enable GPIO Clock
	mov R1, #0x22         ; Enable GPIOB
	str R1, [R0]


	; en alt func for PB[1:0]
	LDR R0, =GPIOBAMSEL
	LDR R1, [R0]
	MOV32 R2, #0xFFFFFFC    ; EXPLICITLY DO NOT ALLOW ANALOG ON PB[1:0]
	AND R1, R2
	STRB R1, [R0, #0]     ; Enable alternative function for PB[1:0]
	LDR R0, =GPIOBAFSEL
	LDR R1, [R0]
	AND R1, #3
	STRB R1, [R0, #0]     ; Enable alternative function for PB[1:0]
	; May not be needed?
	LDR R0, =GPIOBDEN
	MOV R1, #3
	STR R1, [R0]          ; Digital enable PB[1:0]

; Disable after enabling alt func and pin for GPIO
	LDR R0, =0x421A0600    
	; bitband UART1 to set UARTEN = 0 (turn off)
	; 0x42000000 + 32*D030 + 7*0 = 0x421A0600
	MOV R1, #0x0
	STR R1, [R0]  ;   Disable UART1

	; CFG UART
	MOV32 R2, #0x4000D024
	;LDR R2, =UART1IBRD
	MOV32 R1, #0x68   ; IIBRD=int(16000000 / (16*9600)) = int(104.166666667) = 0x68
	STR R1, [R2]
	LDR R0, =UART1FBRD
	MOV R1, #0xB   ; int(0.166666667 * 64 + 0.5) = int(11.166666688) = 11  = 0xB
	STR R1, [R0]
	LDR R0, =UART1LCRH
	MOV32 R1, #0x70
	STRB R1, [R0, #0x0] ; enable FIFO buffers, 8-bits
	LDR R0, =UART1CTL
	MOV32 R1, 0x00000001
	LDR R2, [R0] ; 
	ORR R1, R2, R1       ;
	STR R1, [R0]  ;   ENable UART1

	POP {R4, R5, R6, R7, R8, R9, R10, LR}	
	BX LR
	

       ALIGN      
       END  
           