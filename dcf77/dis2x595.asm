; archeocomp(2019) MCS-48 7-segment display 6 digits code
; eight digits are multiplexed by 2 595 serial registers
; one is for rows the other for columns - multiplexed mode
			;
			.MODULE SEVSEGMULT		; module name (for local _labels)
			; display one byte - seven segment display pattern
DISP_BYTE	MOV R2,#8				; 8 segments with dot
_DIB1		ANL P1,#~DATA_PIN		; clear data pin
			RLC A					; shift bit 0 to CY
			JNC _DIB2				; not set, shift it out
			ORL P1,#DATA_PIN		; set data pin
_DIB2		ORL P1,#CLOCK_PIN		; set clock pin
			ANL P1,#~CLOCK_PIN		; clear clock pin
			DJNZ R2,_DIB1			; shift out all segments
			RET
			;
			; display one digit according to current position on display
DISP_TIME	MOV R0,#POSITION		; get address of display position variable
_DISP_T1	MOV A,@R0				; move position to A
			MOV R4,#01H				; left display digit
			JNZ _DISP_T2			; first position on display
			MOV R1,#HOUR			; get address of hour variable
			MOV A,@R1				; fetch hours
			ANL A,#0F0H				; less than 10?
			JNZ _DISP_T5			; no, continue displaying
			INC @R0					; skip leading zero
			JMP _DISP_T1			; continue displaying
_DISP_T2	MOV R2,A				; move position to R2
			SUBI(2)					; third or fourth column?
			JC _DISP_T3				; no, jump
			INC R2					; skip one display position
			MOV A,R2				; move position to A
			SUBI(5)					; fifth or sixth column?
			JC _DISP_T3				; no, jump
			INC R2					; skip one display position
_DISP_T3	MOV A,R4				; get column to A
_DISP_T4	RL A					; shift column
			DJNZ R2,_DISP_T4		; decrement pos and loop
			MOV R4,A				; set column
_DISP_T5	MOV A,@R0				; get position to A
			RR A					; divide by 2
			ADD A,#HOUR				; add address of hour variable
			MOV R0,A				; result to R0
			MOV A,@R0				; get hour/minute/second
			MOV R2,A				; backup to R2
			MOV R0,#POSITION		; get address of display position variable
			MOV A,@R0				; move position to A
			RRC A					; bit 0 to CY
			MOV A,R2				; get value from R2
			JC _DISP_T6				; lower nibble
			SWAP A					; swap nibbles
_DISP_T6	ANL A,#0FH				; mask out higher BCD number
			;JMP DISP_BCD			; display at computed position
			; jump optimised out
			; diplay BCD encoded number, R4 position on display, A - bcd number
DISP_BCD	MOV R3,A				; move param to R3
			MOV A,R4				; get position
			CALL DISP_BYTE			; shift out position
			MOV A,#DIGIT % 100H		; seven segment table
			ADD A,R3				; adjust position to actual digit
			MOVP A,@A				; get display segments
			CALL DISP_BYTE			; shift out digit segments
			ORL P1,#LATCH_PIN		; set latch pin
			ANL P1,#~LATCH_PIN		; clear latch pin
			RET
			;
			;
			; seven segment display table
DIGIT		.DB ~03FH				; 0
			.DB ~006H				; 1
			.DB ~05BH				; 2
			.DB ~04FH				; 3
			.DB ~066H				; 4
			.DB ~06DH				; 5
			.DB ~07DH				; 6
			.DB ~007H				; 7
			.DB ~07FH				; 8
			.DB ~06FH				; 9
