;
; arithmetic routines for 8048
;
;
			;example numbers
ADDLOW		.EQU 35H
AUGLOW		.EQU 5AH
ADDHI		.EQU 0A3H
AUGHI		.EQU 0CAH
SUBHND		.EQU 0CAH
SUBLOW		.EQU 074H
SUBHI		.EQU 021H
MINEND		.EQU 09EH
MINLOW		.EQU 0E6H
MINHI		.EQU 04BH
			;
			; subtract value in R4 from A
SUBR		CPL A					; complement accumulator
			ADD A,R4				; add to accumulator
			CPL A					; complement accumulator
			RET
			;
			; subtract 8 bit numbers A = R4 - A
SUBA		CPL A					; one's complement a
			INC A					; two's complement a
			ADD A,R4				; subtract and set carry flag
			RET
			;
			; subtract 16 bit numbers @R1(minuend) - @R0(subtrahend), result in R4R3
SUB16		MOV A,@R0				; load lower byte of subtrahend
			CPL A					; complement it
			ADD A,#1				; form two's complement
			MOV R4,A				; store temp subtrahend low two's complement
			INC R0					; move to higher byte of subtrahend
			MOV A,@R0				; load higher byte of subtrahend
			CPL A					; complement it
			ADDC A,#0				; pick up overflow and form two's complement
			MOV R3,A				; store temp subtrahend high complement
			MOV A,R4				; begin addition
			ADD A,@R1				; subtract lower bytes
			MOV R4,A				; store low-order diff
			MOV A,R3				; get higher complemented subtrahend's byte
			INC R1					; move to higher yte of minuend
			ADDC A,@R1				; subtract higher bytes
			MOV R3,A				; store high-order diff
			RET
			;
			; 8 by 8 unsigned multiply, multiplicand x multiplier 
			; Input
			; R6 multiplicand
			; R3 multiplier, low partial
			; Output
			; R2 high partial
MULT8		MOV R5,#9				; 8+1 loop counter
			CLR A					; clear A
			CLR C					; clear CY
M8LP		RRC A					; rotate
			XCH A,R3				; carry, acc, reg 3
			RRC A					; right
			XCH A,R3				; one bit
			JNC M8NOADD				; test carry
			ADD A,R6
M8NOADD		DJNZ R5,M8LP			; 9 shifts to justify
			MOV R2,A				; store high partial product
			RET
			;
			; 16 bit binary to BCD, A lower 8 bits, R2 higher 8 bits
			; R0 pointer to BCD string, C set if overflow
DIGPR		.EQU 2					; 4 packed BCD digits is 2 bytes
BINDEC16	XCH A,R0				; move pointer to result to A
			MOV R1,A				; back up to R1
			XCH A,R0				; restore A
			MOV R4,#DIGPR			; move number of digits to R4
BCDCLR		MOV @R1,#00				; clear result digits
			INC R1					; next digit
			DJNZ R4,BCDCLR			; loop
			MOV R3,#16				; R3 set to number of bits
			; BIN = 2*BIN
BCDOB		CLR C					; clear C
			RLC A					; shift lower 8 bits to left, set C
			XCH A,R2				; exchange
			RLC A					; shift higher 8 bits to left with C
			XCH A,R2				; exchange
			; BCD = 2*BCD+CARRY       add C from binary
			XCH A,R0				; pointer to BCD
			MOV R1,A				; move to R1
			XCH A,R0				; restore A
			MOV R4,#DIGPR			; precision
			MOV R5,A				; move A to temp
BCDOC		MOV A,@R1				; get digit
			ADDC A,@R1				; shift to left with C
			DA A					; decimal adjust
			MOV @R1,A				; save digit
			INC R1					; next digit
			DJNZ R4,BCDOC			; loop all digits
			MOV A,R5				; restore A from temp
			JC BCDOD				; overflow exit with C set
			DJNZ R3,BCDOB			; loop
			CLR C					; done, clear C
BCDOD		RET
			;
			; 8 by 8 unsigned multiply, multiplicand x multiplier 
			; Input
			; A lower eight bits of destination operand, multiplicand
			; R2 don't care
			; R1 pointer to source operand, multiplier
			; Output
			; A lower eight bits of result
			; R2 higher eight bits of result
			; C set if overflow
MULT8X		MOV R2,#0				; clear result hight bits
			MOV R3,#8				; count 8
M8LOOP		JB0 M8ADD
			XCH A,R2				; multiplicant /= 2
			CLR C
			RRC A
			XCH A,R2
			RRC A
			DJNZ R3,M8LOOP
			RET
M8ADD		XCH A,R2				; multiplicand(higher bits 8-15) += multiplier
			ADD A,@R1
			RRC A
			XCH A,R2
			RRC A
			DJNZ R3,M8LOOP
			RET
			;
			; divide 16-bit numbers
			; R1 pointer to 16-bit dividend, R2R3 16-bit divisor
			; on exit: R1 pointer to 16-bit result, R4R5 16-bit remainder
DIV16		MOV R6,#16				; loop count
			CLR A					; clear A
			CLR C					; clear CY
			MOV R4,A				; clear REMAINDER lower byte
			MOV R5,A				; clear REMAINDER higher byte
			; rotate left DIVIDEND 
DIVIA		MOV A,@R1				; lower byte of dividend
			RLC A					; rotate left
			MOV @R1,A				; store result
			INC R1					; move to higher byte
			MOV A,@R1				; higher byte of dividend
			RLC A					; rotate left
			MOV @R1,A				; store result
			DEC R1					; restore R1
			; rotate left REMAINDER (with carry from highest bit of DIVISOR)
			MOV A,R4				; lower byte of REMAINDER
			RLC A					; rotate left
			MOV R4,A				; store result
			MOV A,R5				; higher byte of REMAINDER
			RLC A					; rotate left
			MOV R5,A				; store result
			; compare REMAINDER with DIVISOR
			MOV A,R4				; get lower byte of REMAINDER
			CPL A					; negate A
			ADD A,R2				; subtract lower byte of divisor
			CPL A					; finish subtract operation (no effect on CY)
			MOV R4,A				; store lower byte of subtraction to REMAINDER
			MOV A,R5				; get higher of byte REMAINDER
			CPL A					; negate A
			ADDC A,R3				; subtract higher byte of divisor
			CPL A					; finish subtract operation (no effect on CY)
			MOV R5,A				; store higher byte of subtraction to REMAINDER
			JNC DIVIB				; no borrow occured, it fits
			; borrow occured, undo subtract
			MOV A,R4				; get lower byte of REMAINDER
			ADD A,R2				; add lower byte of divisor
			MOV R4,A				; store result
			MOV A,R5				; get higher byte of REMAINDER
			ADDC A,R3				; add back higher byte of dividend
			MOV R5,A				; store result
			CLR C					; clear CY
			JMP DIVIC				; subtract undone, loop more
			; borrow did not occur, set lowest bit of DIVIDEND to 1 and loop more
DIVIB		MOV A,@R1				; lower byte of dividend
			ORL A,#1				; set bit 0
			MOV @R1,A				; store RESULT
DIVIC		DJNZ R6,DIVIA			; repeat for 16-bit divide
			RET
			;
            ; multiply 16-bit numbers (R1) = (R1) * R2R3
            ; R1 pointer to 16-bit multiplicand, R2R3(lowerhigher) 16-bit multiplier
            ; on exit: R1 pointer to 16-bit result(lowerhigher)
MUL16:      MOV A,@R1        		; lower byte of multiplicand
			MOV R4,A   				; backup lower byte
			INC R1                  ; move to higher byte
            MOV A,@R1               ; higher byte of multiplicand
            MOV R5,A         		; backup higher byte
            CLR A            		; clear A
			MOV @R1,A				; clear RESULT higher byte
			DEC R1					; back to lower byte
			MOV @R1,A				; clear RESULT lower byte
			; add multiplicand if lowest bit of multiplier is 1
MULIA:      MOV A,R4        		; lower byte of multiplier
			CLR C					; clear CY
			RRC A					; rotate right
			JNC MULIB				; jump over addition
			MOV A,@R1               ; lower byte of RESULT
			ADD A,R2				; add lower byte of multiplicand
			MOV @R1,A               ; store RESULT
			INC R1                  ; move to higher byte
			MOV A,@R1               ; higher byte of RESULT
			ADDC A,R3				; add higher byte of multiplicand
			MOV @R1,A               ; store result
			DEC R1					; back to lower byte
			; rotate right multiplier
MULIB:      CLR C					; clear CY
			MOV A,R5				; lower byte of multiplier
			RRC A                   ; rotate right
			MOV R5,A                ; store result
			MOV A,R4				; higher byte of multiplier
			RRC A                   ; rotate right
			MOV R4,A                ; store result
			; check for end condition
			MOV A,R4				; lower byte of multiplier
			ORL A,R5				; combine with higher byte of multiplier
			JZ MULEN				; rotate left multiplicand
			CLR C					; clear CY
			MOV A,R2				; lower byte of multiplier
			RLC A                   ; rotate left
			MOV R2,A                ; store result
			MOV A,R3				; higher byte of multiplier
			RLC A                   ; rotate left
			MOV R3,A                ; store result
			; check for end condition
			MOV A,R2				; lower byte of multiplier
			ORL A,R3				; combine with higher byte of multiplier
			JNZ MULIA				; loop again
			; all done, return
MULEN:		RET					
            ;
					; divide 16-bit number by 8-bit number
			; A lower 8 bits, R2 higher 8 bits, R1 pointer to divisor
			; on exit: A lower 8 bits, R2 remainder
DIV168		XCH A,R2				; start with higher 8 bits
			MOV R3,#8				; loop count
			; DIVIDEND[15-8] = DIVIDEND[15-8] - DIVISOR
			CPL A					; complement A
			ADD A,@R1				; subtract divisor from 
			CPL A					; complement A
			; IF BORROW THEN IT FITS
			JC DIV8A				; subtract with borrow
			CPL	C					; set C
			JMP DIV8B				; continue
DIV8A		; ELSE RESTORE DIVIDEND
			ADD A,@R1
			; DIVIDEND = DIVIDEND * 2
DIV8LP		CLR C					; clear C
			XCH A,R2				; exchange
			RLC A					; rotate left
			XCH A,R2				; exchange
			RLC A					; rotate left
			JNC DIV8E
			CPL A					; complement A
			ADD A,@R1				; subtract divisor from A
			CPL A					; complement A
			JMP DIV8C
DIV8E		; DIVIDEND[15-8] = DIVIDEND[15-8] - DIVISOR
			CPL A					; complement A
			ADD A,@R1				; subtract divisor from A
			CPL A					; complement A
			; IF BORROW = 1
			JNC DIV8C				; subtract without borrow
			; RESTORE DIVIDEND
			ADD A,@R1				; subtract with borrow, restore dividend
			JMP DIV8D				;
			; ELSE QUOTIENT[0] = 1
DIV8C		INC R2
DIV8D		DJNZ R3,DIV8LP
			CLR C
DIV8B		XCH A,R2
			RET
			;
			.END
			