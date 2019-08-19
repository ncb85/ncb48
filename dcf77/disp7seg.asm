; archeocomp(2019) MCS-48 7-segment display 6 digits code
;
			;
			.MODULE SEVSEG			; module name (for local _labels)
			; display one byte - seven segment display pattern
DISP_BYTE	MOV R2,#8				; 8 segments with dot
_DIB1		ANL P1,#~DATA_PIN		; clear data pin
			RRC A					; shift bit 0 to CY
			JC _DIB2				; not set, shift it out
			ORL P1,#DATA_PIN		; set data pin
_DIB2		ORL P1,#CLOCK_PIN		; set clock pin
			ANL P1,#~CLOCK_PIN		; clear clock pin
			DJNZ R2,_DIB1			; shift out all segments
			RET
			;
			; diplay two BCD encoded numbers
DISP_BCD	MOV R4,A				; back up A
			ANL A,#0FH				; mask out higher BCD number
			CALL _DISP_B1			; send to display
			MOV A,R4				; restore A
			ANL A,#0F0H				; mask out lower BCD number
			SWAP A					; swap nibbles
_DISP_B1	MOV R3,A				; move param to R3
			MOV A,#DIGIT % 100H		; seven segment table
			ADD A,R3				; adjust position to actual digit
			MOVP A,@A				; get display segments
			CALL DISP_BYTE			; shift it out
			RET
			;
			; display HH MM SS
DISP_TIME	MOV R0,#SECOND			; seconds address to R0
			MOV A,@R0				; move seconds to A
			CALL DISP_BCD			; display SS
			DEC R0					; minutes address to R0
			MOV A,@R0				; move minutes to A
			CALL DISP_BCD			; display MM
			DEC R0					; hours address to R0
			MOV A,@R0				; move hours to A
			CALL DISP_BCD			; display HH
			;TODO LATCH_PIN
			MOV R0,#CURR_STAT		; get address of current state variable
			XCH A,@R0				; exchange values (set CURR_STAT)
			ANL A,#~DISP_REFR		; clear refresh display flag
			XCH A,@R0				; exchange values (set CURR_STAT)
			;
			MOV R2,#'.'
			CALL TXCHAR
			RET
			;
			;.ORG 03E8H				; page 3 end
			;
			; seven segment display table
DIGIT		.DB 0FCH				; 0
			.DB 060H				; 1
			.DB 0DAH				; 2
			.DB 0F2H				; 3
			.DB 066H				; 4
			.DB 0B6H				; 5
			.DB 0BEH				; 6
			.DB 0E0H				; 7
			.DB 0FEH				; 8
			.DB 0F6H				; 9
			.DB 00H					; space [10]
			.DB 01H					; . [11]
