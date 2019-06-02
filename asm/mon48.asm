; archeocomp(2019)
; simple monitor and loader for 8048
; designed for/on NCB48 SBC
;
; macro for subtract instruction A=A-Rx
#DEFINE SUB(Rx) CPL A \ ADD A,Rx \ CPL A
; subtract 8 bit numbers A=Rx-A
;SUBA		CPL A					; one's complement a
;			INC A					; two's complement a
;			ADD A,Rx				; subtract and set carry flag
;			RET
			;
			; hw constants
CSRAM		.EQU 00100000B			; P2.5 chip select RAM
IOM8155		.EQU 00010000B			; P2.4 data/ram 8155 select
ADRRIOT		.EQU 00H				; 8155 RIOT is selected by neg A3
DATUART		.EQU 08H				; UART is selected by line A3 and A0
CTRUART		.EQU 09H				; UART control register
			; code constants
CR			.EQU 0DH
LF			.EQU 0AH
CTRL_C		.EQU 03H
BELL		.EQU 07H
			; interrupt routines
EXINTR		.EQU 803H				; ex.interrupt routine
TCINTR		.EQU 807H				; timer interrupt routine
			; variables
IHADDR		.EQU 126				; lower byte overlaps with previous variable
			;
			.ORG 0					; reset vector
			JMP MAIN				; jump to main routine
			.ORG 3					; external interrupt input
			JMP INTRPT				; jump to interrupt routine
			.ORG 7					; timer interrupt
			; timer/counter interrupt
TIMR		SEL RB1					; select register bank 1
			MOV R7,A				; backup A to R7
			CALL TCINTR				; call routine
			MOV A,R7				; restore A
			SEL RB0					; select register bank 0
			RETR 					; restore PC and PSW
			;
			; external interrupt
INTRPT		SEL RB1					; select register bank 1
			MOV R7,A				; backup A to R7
			CALL EXINTR				; call routine
			MOV A,R7				; restore A
			SEL RB0					; select register bank 0
			RETR 					; restore PC and PSW
			;
			; 8251A initialisation, according to datasheet (3x 00h + RESET 040h)
INITSER		MOV R0,#CTRUART			; 8251A control register address
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
			; starts timer in 8155 RIOT chip
			; timer count rate 76800Hz, with divider 15360(3C00H)
			; is the resulting interrupt rate exactly 5Hz
INI8155	  	MOV R0,#ADRRIOT+4		; 8155 timer lower 8bits register address
			CLR A					; clear A
			MOVX @R0,A				; counter low 8 bits
			INC R0					; select counter high 6 bits + mode bits
			MOV A,#7FH				; counter high 6 bits 3CH + mode bits 0 1
			MOVX @R0,A				; send it
			MOV R0,#ADRRIOT			; control register
			MOV A,#0C3H				; start timer, ports A,B output, C set to input
			MOVX @R0,A				; send it
			RET
			;
			; push one char to serial out, input R2
			; before writing to Tx buffer waits for it to become empty
TXCHAR	 	MOV R0,#CTRUART			; 8251A control/status reg
TXC1		MOVX A,@R0				; status register to A
			JB0 TXC2				; bit 0 TxRDY - buffer empty - proceed sending
			JMP TXC1				; wait more
TXC2		DEC R0					; 8251A data reg
			MOV A,R2				; move char to A
			MOVX @R0,A				; send it
			RET
			;
			; push two HEX digits to serial out, input A
TXBYTE		MOV R3,A				; backup A to R3
			SWAP A					; move to lower nibble
			CALL TXNIBB				; send higher HEX digit
			MOV A,R3				; restore input value
TXNIBB		MOV R4,#10				; compare value
			ANL A,#0FH				; lower nibble
			MOV R5,A				; backup lower nibble to R5
			SUB(R4)					; compare R4 with A
			MOV A,R5				; restore lower nibble
			JNC TXBY3				; byte greater than binary 0AH
			ADD A,#'0'				; it is number 0..9, add '0'
			JMP TXBY4				; jump over
TXBY3		ADD A,#'A'-10			; it alpha digit A..F add 'A'
TXBY4		MOV R2,A				; move to R2
			CALL TXCHAR				; send HEX digit
			RET
			;
			; print zero terminated string
			; R3 string to print (should be on same 256 bytes page)
PRINT		MOV A,R3				; char address to A
			MOVP3 A,@A				; get char located at page 3 address A
			MOV R2,A				; move to R2
			INC R3					; inc addr of char
			JZ PRIRET				; return on string end
			CALL TXCHAR				; print char in R2
			JMP PRINT				; next char
PRIRET		RET
			;
			; receive one char from serial port
			; return character in A
RXCHAR		MOV R0,#CTRUART			; select 8251A control/status reg
RXC1		MOVX A,@R0				; status register to A
			JB1 RXC2				; bit 1 RxRDY - char received
			JMP RXC1				; wait more
RXC2		DEC R0					; 8251A data reg
			MOVX A,@R0				; fetch it
			RET
			;
			; receive char, convert a..z to UPPER A..Z, check HEX value
			; allows user abort
RXHEXC		CALL RXCHAR				; receive char
			MOV R2,A				; backup to R2
			MOV R4,#CTRL_C			; subtract CTRL_C
			SUB(R4)					; from A
			JNZ RXHEX1				; not user abort, continue
			CPL C					; indicate user abort
			RET
RXHEX1		MOV A,R2				; restore A
			MOV R4,#'Z'+1			; subtract ASCII value 'Z'+1
			SUB(R4)					; from A
			MOV A,R2				; restore A
			JC RXHEX2				; it is uppercase char
			ANL A,#11011111B		; to uppercase
RXHEX2		MOV R4,#'A'				; subtract ASCII value 'A'
			SUB(R4)					; from A
			JNC RXHEX3				; char greater than ASCII "A"
			ADD A,#'A'-'0'			; char is 0..9, so add back 17 (= 'A'-'0')
			JMP RXHEX4				; jump over
RXHEX3		ADD A,#0AH				; add 0AH
RXHEX4		MOV R4,#16				; check it is hexa number 0..15(0..F)
			MOV R2,A				; backup to R2
			SUB(R4)					; subtract 16, normally sets C
			MOV A,R2				; restore A
			JC RXHEX5				; HEX char, return
			MOV R2,#BELL			; bell sound
			CALL TXCHAR				; send it
			JMP RXHEXC				; get next char
RXHEX5		CLR C					; clear C
			RET
			;
			; receive one byte HEXA (e.i. two ASCII chars) "2F" --> 02Fh
			; return received byte in A
RXBYTE		CALL RXHEXC				; receive first char, upper nibble
			JC RXRET				; return on abort
			SWAP A					; move binary value to the upper nibble
			MOV R5,A				; backup preliminary value
			CALL RXHEXC				; receive second char, low nibble
			ADD A,R5				; add upper nibble
RXRET		RET						; A contains decoded byte
			;
			; receive INTEL HEX file
RCIHEX		MOV R2,#3				; try 3 chars
RCIHX1		CALL RXCHAR				; receive one char
			MOV R4,#':'				; wait for ':' the begining of each line
			SUB(R4)					; compare with A
			JZ RCIHLEN				; found beginning, receive rest of line
RCIHX2		DJNZ R2,RCIHX1			; ignore newlines/noise and try again
			RET						; give up
			;
			; receive one line of INTEL HEX
RCIHLEN		CALL RXBYTE				; receive length of data
			;JNZ RCIHX3				; length zero, last line of file
			;CPL F0					; set flag to indicate end of file
RCIHX3		MOV R6,A				; move length to R6
			MOV R7,A				; compute line checksum in R7
			CALL RXBYTE				; receive address
			MOV R1,#IHADDR+1		; address high byte variable
			MOV @R1,A				; backup address high byte
			ADD A,R7				; add first byte of address to checksum
			MOV R7,A				; update checksum
			CALL RXBYTE				; receive low byte address
			DEC R1					; address low byte variable
			MOV @R1,A				; backup address high byte
			ADD A,R7				; add second byte of address to checksum
			MOV R7,A				; update checksum
			CALL RXBYTE				; receive record type
			JZ RCVDATA				; record type data, load line
			;JF0	EOFREC				; flag indicates end of file
			;JMP RCVDATA				; continue receiving data - optimized out
EOFREC  	CALL RXBYTE				; receive last byte
			;CALL NEWLINE			; newline and return to prompt
			RET						; return on last line EOF
			; receive the data bytes from one line in HEX file
RCVDATA		CALL RXBYTE				; receive data byte
			MOV R3,A				; backup data byte
			ADD A,R7				; add data to checksum
			MOV R7,A				; update checksum
			MOV R0,#IHADDR			; address low byte variable A7-A0
			MOV A,@R0				; get address bits A7-A0
			MOV R1,A				; parameter R1 address
			MOV A,R3				; restore data byte
			CALL STOREP				; store byte to memory, par.page IHADDR+1
			MOV R0,#IHADDR			; address low byte variable A7-A0
			MOV A,#1				; increment 12 bit address
			ADD A,@R0				; add one to low address A7-A0
			MOV @R0,A				; update variable
			INC R0					; move to high address byte A11-A8
			CLR A					; clear A (flags not affected)
			ADDC A,@R0				; add carry to high address A11-A8
			MOV @R0,A				; update variable
			DJNZ R6,RCVDATA			; receive more bytes
			CALL RXBYTE				; receive last byte - checksum from file
			ADD A,R7				; add computed and received checksums
			JZ RCVCNF				; confirm line
			JMP ERROR				; checksum is not zero - error
RCVCNF		MOV R2,#'.'				; '.' confirmation char
			CALL TXCHAR				; send at the end of each line
			JMP RCIHEX				; receive next line
ERROR		MOV R2,#'e'				; checksum error
			CALL TXCHAR         	; send 'e'
NEXT		JMP RCIHEX				; next line of INTEL Hex-file
			;
			; print space
SPACE		MOV R2,#' '				; space
			JMP NEWLIN1
			;
			; print new line
NEWLINE		MOV R2,#CR				; carriage return
			CALL TXCHAR				; print
			MOV R2,#LF				; line feed
NEWLIN1		CALL TXCHAR				; print
			RET
			;
			; fetch byte from memory at R1 address
			; F0 flag distinguishes between RAM/ROM
			; F1 flag denotes external RAM
FETCHB		JF1	FETCHE				; external RAM
			JF0 FETCHP				; program ROM
			MOV A,@R1				; move RAM to A
			RET
FETCHE		ANL P2,#~IOM8155		; select 8155 RAM(deny UART, RIOT)
			MOVX A,@R1				; fetch byte from external RAM in 8155
			ORL P2,#IOM8155			; deselect 8155 RAM(allow UART, RIOT)
			RET
FETCHP		MOV R0,#IHADDR+1		; page number
			MOV A,@R0				; load it
			ANL A,#~CSRAM			; allow RW access to external program MEM(deny UART, RIOT)
			OUTL P2,A				; output page number to P20..P23
			MOVX A,@R1				; fetch byte from program memory
			ORL P2,#CSRAM+IOM8155	; deny RW access to external program MEM(allow UART, RIOT)
			RET
			;
			; dump MEM contents common routine, prints 16 bytes per line
			; R1 beginning of listing, R6 number of lines (bytes/16)
			; F0 flag distinguishes between RAM/ROM
			; F1 flag denotes external RAM
MEMDMP		CALL NEWLINE			; print newline
			JF0 MEMDP1				; program memory needs three address bytes
			JMP MEMDP2				; print 8 bit address
MEMDP1		MOV R0,#IHADDR+1		; page number
			MOV A,@R0				; load it
			CALL TXNIBB				; echo page number
MEMDP2		MOV A,R1				; address to A
			MOV R2,A				; address to R2 (param)
			CALL TXBYTE				; print address
			CALL SPACE				; print space
MEMDP3		CALL TXCHAR				; print space
			CALL FETCHB				; fetch byte from memory
			MOV R2,A				; param to TXBYTE
			CALL TXBYTE				; print it
			MOV R2,#' '				; space character
			INC R1					; next byte of RAM
			MOV A,R1				; address to A
			ANL A,#0FH				; modulo 16
			JZ MEMDP4				; 16 bytes written out
			JMP MEMDP3				; still the same line
MEMDP4		MOV R3,#16				; move address back to beginning of lines
			MOV A,R1				; get address to A
			SUB(R3)					; subtract 16
			MOV R1,A				; set adjusted address to R1
			CALL TXCHAR				; print space
			CALL TXCHAR				; print second space
MEMDP5		CALL FETCHB				; fetch byte from memory
			MOV R7,A				; backup byte
			MOV R2,#32				; non printable chars 0-31
			SUB(R2)					; subtract from A
			JC MEMDP6				; print dot
			MOV A,R7				; restore byte
			JB7 MEMDP6				; non ASCII character
			MOV R2,A				; printable character
			JMP MEMDP7				; print it
MEMDP6		MOV R2,#'.'				; dot char
MEMDP7		CALL TXCHAR				; print it
			INC R1					; next byte of RAM
			MOV A,R1				; address to A
			ANL A,#0FH				; modulo 16
			JZ MEMDP8				; 16 chars written out
			JMP MEMDP5				; still the same line
MEMDP8		DJNZ R6,MEMDMP			; print next line
			RET
			;
			; dump program memory, dumps one page 256 bytes
DUMPP		CALL RXHEXC				; get page number
			MOV R0,#IHADDR+1		; page number
			MOV @R0,A				; save it
			CPL F0					; set F0 - program code MEM
DUMCM		MOV R6,#16				; parameter number of lines
			MOV R1,#0				; parameter start address on page boundary
DUMCR		JMP MEMDMP				; dump routine
			;
			; dump internal memory, auto detect RAM size (64/128)
			; devices with 64 bytes RAM ignore bit 6 (and 7)
			; 8040/50 series with 256 RAM not checked as it has no EPROM member
DUMPI		MOV R0,#3FH				; minimum is 64 bytes size (8748)
			MOV A,@R0				; fetch RAM byte
			MOV R2,A				; back up RAM byte
			MOV R0,#7FH				; try 128 bytes size (8749)
			MOV A,@R0				; fetch RAM byte
			MOV R1,A				; back up RAM byte
			MOV A,#8				; 8x16 bytes lines of dump, total 128
			MOV @R0,A				; store to address 3F
			MOV R0,#3FH				; try to write to 64 bytes size (8748)
			MOV A,#4				; 4x16 bytes lines of dump, total 64
			MOV @R0,A				; store to address 7F
			MOV R0,#7FH				; try to read 128 bytes size (8749)
			MOV A,@R0				; fetch real value
			MOV R6,A				; parameter number of lines
			MOV A,R1				; get original RAM byte 7F
			MOV R0,#7FH				; 128 bytes size (8749)
			MOV @R0,A				; restore RAM byte original value
			MOV A,R2				; get original RAM byte 3F
			MOV R0,#3FH				; address of second RAM test byte
			MOV @R0,A				; restore RAM byte original value
			;MOV R1,#0				; parameter start address - optimized out
			JMP DUMCM+2				; dump routine
			;
			; dump external memory 256 byte RAM in 8155
DUMPE		;MOV R6,#16				; parameter number of lines - optimized out
			;MOV R1,#0				; parameter start address - optimized out
			CPL F1					; set F1 - external RAM
			JMP DUMCM				; dump routine
			;
			; store byte into internal memory at R1 address
			; F0 flag distinguishes between RAM/ROM
			; F1 flag denotes external RAM
STOREB		JF1	STOREE				; external RAM
			JF0 STOREP				; program ROM
			MOV @R1,A				; move A to RAM indirect
			RET
			;
			; store byte into external memory at R1 address
STOREE		ANL P2,#~IOM8155		; select 8155 RAM(deny UART, RIOT)
			MOVX @R1,A				; store byte into external RAM in 8155
			ORL P2,#CSRAM+IOM8155	; de-select 8155 RAM(allow UART, RIOT)
			RET
			;
			; store byte into program memory at R1 address, page IHADDR+1
STOREP		MOV R3,A				; back up A
			MOV R0,#IHADDR+1		; page number address
			MOV A,@R0				; load it indirectly into A
			ANL A,#~CSRAM			; allow RW access to external program MEM(deny UART, RIOT)
			OUTL P2,A				; output page number to P20..P23
			MOV A,R3				; restore A
			MOVX @R1,A				; store byte into external program memory
			ORL P2,#CSRAM+IOM8155	; deny RW access to external program MEM(allow UART, RIOT)
			RET
			;
			; set memory contents common routine
MEMSET		CALL RXBYTE				; get address
			JC MEMSE2				; user abort
			MOV R1,A				; address to R1
			CALL TXBYTE				; echo it
MEMSE1		CALL SPACE				; send space
			CALL RXBYTE				; get value
			JC MEMSE2				; user abort
			CALL STOREB				; store value
			CALL TXBYTE				; echo it
			INC R1					; advance address to next byte
			JMP MEMSE1				; loop
MEMSE2		RET
			;
			; set program memory
SETP		CALL RXHEXC				; get page number
			MOV R0,#IHADDR+1		; save page number
			MOV @R0,A				; save it
			CALL TXNIBB				; echo page number
			CPL F0					; set F0 - program code MEM
			JMP MEMSET				; set mem routine
			;
			; execute external data mem
SETE		CPL F1					; set F1 - external RAM
			; fall through
			; execute set internal memory
SETM		JMP MEMSET				; set mem routine
			;
			; report ACC value, stack and flags
			; CfACfF0fF1f SP= A=
PSWREP		SEL RB1					; switch to alternate register bank
			MOV R1,A				; backup A
			CALL NEWLINE			; newline
			MOV A,PSW				; backup PSW
			MOV R4,A				; backup to R4
			MOV R5,#'C'				; CY flag
			MOV R6,#'Y'				; CY flag
			ADD A,R4				; bit 7 i carry
			MOV R4,A				; back up
			CALL BITREP				; print carry
			MOV R5,#'A'				; AC flag
			MOV R6,#'C'				; AC flag
			MOV A,R4				; restore A
			ADD A,R4				; bit 6 i AC
			MOV R4,A				; back up
			CALL BITREP				; print auxiliary carry
			MOV R5,#'F'				; F0 flag
			MOV R6,#'0'				; F0 flag
			MOV A,R4				; restore A
			ADD A,R4				; bit 5 i F0
			MOV R4,A				; back up
			CALL BITREP				; print F0
			CLR C					; clear carry
			JF1	PSWREP1				; if flag F1 is set, set C
			JMP PSWREP2
PSWREP1		CPL C					; set carry
PSWREP2		MOV R5,#'F'				; F0 flag
			MOV R6,#'1'				; F0 flag
			CALL BITREP				; print F1
			CALL SPACE				; print space
			MOV R2,#'S'				; stack pointer SP
			CALL TXCHAR				; print it
			MOV R2,#'P'				; stack pointer SP
			CALL TXCHAR				; print it
			MOV R2,#'='				; equals
			CALL TXCHAR				; print it
			MOV A,R4				; restore A
			RR A					; move SP back to bits 0..2
			RR A					; move SP back to bits 0..2
			RR A					; move SP back to bits 0..2
			ANL A,#00000111B		; mask out other bits
			CALL TXNIBB				; print it
			CALL SPACE				; print space
			MOV R2,#'A'				; accumulator
			CALL TXCHAR				; print it
			MOV R2,#'='				; equals
			CALL TXCHAR				; print it
			MOV A,R1				; restore A
			CALL TXBYTE				; print it
			SEL RB0					; switch back standard register bank
			RET
			;
			; print one flag
BITREP		MOV A,R5				; flag name
			MOV R2,A				; move to R2
			CALL TXCHAR				; print it
			MOV A,R6				; flag name
			;JZ BITRE2				; do not print
			MOV R2,A				; move to R2
			CALL TXCHAR				; print it
BITRE1		JC BITRE2				; carry is set
			MOV R2,#'-'				; flag not set
			JMP BITRE3				; print
BITRE2		MOV R2,#'1'				; flag set
BITRE3		CALL TXCHAR				; print value
			;CALL SPACE				; print space
			RET
			;
			; start
MAIN		;DIS I					; no ext.interrupt
			;DIS TCNTI				; no timer/counter interrupt
			CALL INITSER			; initialize 8251A
			CALL INI8155			; initialize 8155
			;
			; D dump program mem
			; I dump internal mem
			; E dump external data mem (8155 256bytes)
			; S set prog mem
			; M set internal data mem
			; X set external data mem (8155 256bytes)
			; G go 400, H go 800
			MOV R3,#WLCMTXT % 100H	; point to welcome message
			CALL PRINT				; print it
PROMPT		MOV R3,#PRMTXT % 100H	; point to prompt '>'
			CALL PRINT				; print it
PRMPT1		CALL RXCHAR				; receive char
			ANL A,#11011111B		; to uppercase
			MOV R2,A				; move to R2
			MOV R3,#-1				; index of command
PRMPT2		INC R3					; advance to next command
			MOV A,#COMMDLS % 100H	; command list
			ADD A,R3				; adjust position to actual command
			MOVP3 A,@A				; get char located at page 3 address A
			JZ PRMPT1				; invalid command, get another command
			SUB(R2)					; subtract R2
			JNZ PRMPT2				; try next command
			CALL TXCHAR				; echo command
			MOV A,R3				; command found, get index
			ADD A,#CMDVCT % 100H	; add address of command vectors
			CLR F0					; clear flag F0
			CLR F1					; clear flag F1
			CALL CMDIND				; call commmand indirectly
			JMP PROMPT				; next command
CMDIND		JMPP @A					; jump to command
			;
CMDVCT		.DB CMD1,CMD2,CMD3,CMD4	; command vector table
			.DB CMD5,CMD6,CMD7,CMD8	; continued
			.DB CMD9
			;
CMD1		JMP DUMPP				; execute dump program memory
CMD2		JMP DUMPI				; execute dump external RAM
CMD3		JMP DUMPE				; execute dump external RAM
CMD4		JMP SETP				; execute set program memory
CMD5		JMP SETM				; execute set internal memory
CMD6		JMP SETE				; execute external data mem
CMD9		JMP RCIHLEN				; load file, begins on ':' colon received
			;
			; call 400H address
CMD7		CALL 400H				; jump to external program memory
			JMP PSWREP				; report PSW
			;
			; call (GO) 800H address
CMD8		SEL MB1					; to go above 2k boundary, bit A11 must be set
			CALL 800H				; jump to external program memory, memory bank 1
			SEL MB0					; reset flip-flop to lower 2k memory bank
			JMP PSWREP				; report PSW
			;
LASTLN		.ECHO "The size of the loader is "
			.ECHO LASTLN
			.ECHO " bytes. "
			.ECHO COMMDLS-LASTLN
			.ECHO " bytes free.\n"
			;
			.ORG 03AEH
COMMDLS		.TEXT "DIESMXGH\032\000"
WLCMTXT		.DB 1BH,"[0m"			; reset terminal attributes
			.DB	1BH,"[2J"			; clear console
			.TEXT "MON48\r\n"
			.TEXT "DUMP/SET D/S-prgm I/M-intl, E/X-exnl, GO G/H, Upload\000"
PRMTXT		.TEXT "\r\n\>\000"
			.END
