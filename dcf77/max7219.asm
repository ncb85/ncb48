; archeocomp(2019) MCS-48 code
; for MAX7219 eight digits 7-segment display
			;
			.MODULE SEVSEGMAX		; module name (for local _labels)
			;
SCAN_LIMIT	.EQU 07				    ; all digits
INTENSITY	.EQU 01					; middle intensity
			;
DECODE_MODE_REG	.EQU    09H         ; MAX7219 register addresses
INTENSITY_REG	.EQU	0AH
SCAN_LIMIT_REG	.EQU	0BH
SHUTDOWN_REG	.EQU	0CH
			;
			; send one packet(8bit address + 8bit number)
			; address of display digit in R5
			; segment data in A
SEND_DGT	ANL P1,#~LATCH_PIN		; clear load pin
			MOV R2,A				; backup A
			MOV A,R5				; get address
			CALL _SNDG1				; send address byte to display
			MOV A,R2				; get segment byte
			CALL _SNDG1				; send segment byte to display
			ORL P1,#LATCH_PIN		; set load pin
			RET
_SNDG1		MOV R3,#8				; 8 segments with dot
_SNDG2		ANL P1,#~CLOCK_PIN		; clear clock pin
			ANL P1,#~DATA_PIN		; clear data pin
			RLC A					; shift bit 0 to CY
			JNC _SNDG3				; not set, shift it out
			ORL P1,#DATA_PIN		; set data pin
_SNDG3		ORL P1,#CLOCK_PIN		; set clock pin
			DJNZ R3,_SNDG2			; shift out all segments
			RET
			;
			; display BCD number - two digits
DISP_BCD	MOV R4,A				; back up A
			ANL A,#0FH				; mask out higher BCD number
			CALL _DISP_B1			; send to display
			INC R5					; move position to left
			MOV A,R4				; restore A
			ANL A,#0F0H				; mask out lower BCD number
			SWAP A					; swap nibbles
_DISP_B1	MOV R3,A				; move param to R3
			MOV A,#DIGIT % 100H		; seven segment table
			ADD A,R3				; adjust position to actual digit
			MOVP A,@A				; get display segments
			CALL SEND_DGT			; shift it out
			RET
			;
			; display HH MM SS
DISP_TIME	MOV R0,#SECOND			; seconds address to R0
			MOV R5,#1				; last position on display
			MOV A,@R0				; move seconds to A
			CALL DISP_BCD			; display SS
			DEC R0					; minutes address to R0
			INC R5					; skip one position
			MOV A,@R0				; move minutes to A
			CALL DISP_BCD			; display MM
			DEC R0					; hours address to R0
			INC R5					; skip one position
			MOV A,@R0				; move hours to A
			ANL A,#0F0H				; first digit zero?
			JNZ _DISP_TI1			; no, display two digits
			ORL A,#0A0H		        ; space on first digit
_DISP_TI1	ORL A,@R0				; move hours to A again
			CALL DISP_BCD			; display HH
			MOV R0,#CURR_STAT		; get address of current state variable
			XCH A,@R0				; exchange values (set CURR_STAT)
			ANL A,#~DISP_REFR		; clear refresh display flag
			XCH A,@R0				; exchange values (set CURR_STAT)
			RET
			;
			; initialize MAX7219
MAX7219_INIT
			MOV R5,#SHUTDOWN_REG	; wakeup call
			MOV A,#1
			CALL SEND_DGT
			MOV R5,#INTENSITY_REG	; Set the brightness to a medium values
			MOV A,#INTENSITY
			CALL SEND_DGT
			MOV R5,#SCAN_LIMIT_REG	; and set all digits on
			MOV A,#SCAN_LIMIT
			CALL SEND_DGT
			RET
			;

;B01111110,B00110000,B01101101,B01111001,B00110011,
;B01011011,B01011111,B01110000,B01111111,B01111011,
;B00000000
DIGIT		.DB 07EH				; 0
			.DB 030H				; 1
			.DB 06DH				; 2
			.DB 079H				; 3
			.DB 033H				; 4
			.DB 05BH				; 5
			.DB 05FH				; 6
			.DB 070H				; 7
			.DB 07FH				; 8
			.DB 07BH				; 9
			.DB 000H				; space
