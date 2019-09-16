; archeocomp(2019) MCS-48 debug code
; uses UART 8251 and external RAM in 8155
; it uses flat structure to use only one level of stack
;
			.MODULE DEBUG			; module name (for local _labels)
			.ORG BEGIN+2F0H
			;
CSRAM		.EQU 00100000B			; P2.5 chip select RAM
IOM8155		.EQU 00010000B			; P2.4 data/ram 8155 select
ADRRIOT		.EQU 00H				; 8155 RIOT is selected by neg A3
			;
CTRUART		.EQU 09H				; UART control register
BACK_A		.EQU 0FFH				; register backup area FF-F9 in RIOT
			;
			; 8251A initialisation, according to datasheet (3x 00h + RESET 040h)
LOGINIT		MOV R0,#CTRUART			; 8251A control register address
			CLR A					; clear A
			MOVX @R0,A				; 00H to control regiter
			MOVX @R0,A				; 00H to control regiter
			MOVX @R0,A				; 3x 00H to control regiter
			MOV A,#40H				; reset 40h
			MOVX @R0,A				; register write
			MOV A,#4EH				; MODE: no parity, 8 databits, 1 stop bit, 16x
			MOVX @R0,A				; register write
			MOV A,#15H				; COMMAND: enable receive and transmit
			MOVX @R0,A				; register write
			RET
			;
			; log with registers preserved - R0 is changed though
LOGACC		ANL P2,#~IOM8155		; select 8155 RAM(deny UART, RIOT)
			MOV R0,#BACK_A			; backup RAM address
			MOVX @R0,A				; backup A
			MOV A,R7				; move R7 to A
			DEC R0
			MOVX @R0,A				; backup R7
			DEC R0
			MOV A,R6
			MOVX @R0,A				; backup R6
			DEC R0
			MOV A,R5
			MOVX @R0,A				; backup R5
			DEC R0
			MOV A,R4
			MOVX @R0,A				; backup R4
			DEC R0
			MOV A,R3
			MOVX @R0,A				; backup R3
			DEC R0
			MOV A,R2
			MOVX @R0,A				; backup R2
			DEC R0
			MOV A,R1
			MOVX @R0,A				; backup R1
			MOV R0,#BACK_A			; address of A
			MOVX A,@R0				; restore A
			ORL P2,#IOM8155			; deselect 8155 RAM(allow UART, RIOT)
			;
TXBYTE		MOV R3,A				; backup A to R3
			SWAP A					; move to lower nibble
			; push two HEX digits to serial out, input A
			MOV R4,#10				; compare value
			ANL A,#0FH				; higher nibble
			MOV R5,A				; backup lower nibble to R5
			SUB(R4)					; compare R4 with A
			MOV A,R5				; restore lower nibble
			JNC _TXBY3				; byte greater than binary 0AH
			ADD A,#'0'				; it is number 0..9, add '0'
			JMP _TXBY4				; jump over
_TXBY3		ADD A,#'A'-10			; it is alpha digit A..F add 'A'
_TXBY4		MOV R2,A				; move to R2
	 		MOV R0,#CTRUART			; 8251A control/status reg
_TXC1		MOVX A,@R0				; status register to A
			JB0 _TXC2				; bit 0 TxRDY - buffer empty - proceed sending
			JMP _TXC1				; wait more
_TXC2		DEC R0					; 8251A data reg
			MOV A,R2				; move char to A
			MOVX @R0,A				; send it
			; lower nibble
			MOV A,R3				; restore input value
TXNIBB		MOV R4,#10				; compare value
			ANL A,#0FH				; lower nibble
			MOV R5,A				; backup lower nibble to R5
			SUB(R4)					; compare R4 with A
			MOV A,R5				; restore lower nibble
			JNC TXBY3				; byte greater than binary 0AH
			ADD A,#'0'				; it is number 0..9, add '0'
			JMP TXBY4				; jump over
TXBY3		ADD A,#'A'-10			; it is alpha digit A..F add 'A'
TXBY4		MOV R2,A				; move to R2
	 		MOV R0,#CTRUART			; 8251A control/status reg
TXC1		MOVX A,@R0				; status register to A
			JB0 TXC2				; bit 0 TxRDY - buffer empty - proceed sending
			JMP TXC1				; wait more
TXC2		DEC R0					; 8251A data reg
			MOV A,R2				; move char to A
			MOVX @R0,A				; send it
			; restore registers
			ANL P2,#~IOM8155		; select 8155 RAM(deny UART, RIOT)
			MOV R0,#BACK_A-7		; backup RAM address
			MOVX A,@R0				; restore R1
			MOV R1,A				; move A to R1
			INC R0
			MOVX A,@R0				; restore R2
			MOV R2,A				; move A to R2
			INC R0
			MOVX A,@R0				; restore R3
			MOV R3,A
			INC R0
			MOVX A,@R0				; restore R4
			MOV R4,A
			INC R0
			MOVX A,@R0				; restore R5
			MOV R5,A
			INC R0
			MOVX A,@R0				; restore R6
			MOV R6,A
			INC R0
			MOVX A,@R0				; restore R7
			MOV R7,A				; move A to R7
			INC R0					; A backup address
			MOVX A,@R0				; restore A
			ORL P2,#IOM8155			; deselect 8155 RAM(allow UART, RIOT)
			RET
			;
			; logs char in A with registers preserved - R0 is changed though
LOGIMD		ANL P2,#~IOM8155		; select 8155 RAM(deny UART, RIOT)
			MOV R0,#BACK_A			; backup RAM address
			MOVX @R0,A				; backup A
			DEC R0
			MOV A,R2				; move R2 to A
			MOVX @R0,A				; backup R2
			MOV R0,#BACK_A			; backup RAM address
			MOVX A,@R0				; restore A
			ORL P2,#IOM8155			; deselect 8155 RAM(allow UART, RIOT)
			;
			MOV R2,A				; move to R2
	 		MOV R0,#CTRUART			; 8251A control/status reg
_LGI1		MOVX A,@R0				; status register to A
			JB0 _LGI2				; bit 0 TxRDY - buffer empty - proceed sending
			JMP _LGI1				; wait more
_LGI2		DEC R0					; 8251A data reg
			MOV A,R2				; move char to A
			MOVX @R0,A				; send it
			;
			; restore registers
			ANL P2,#~IOM8155		; select 8155 RAM(deny UART, RIOT)
			MOV R0,#BACK_A-1		; backup RAM address
			MOVX A,@R0				; restore R2
			MOV R2,A				; move A to R2
			INC R0
			MOVX A,@R0				; restore A
			ORL P2,#IOM8155			; deselect 8155 RAM(allow UART, RIOT)
			RET
			;
