; archeocomp(2019) MCS-48 7-segment display 6 digits code
;
			;
			.MODULE SEVSEG		; module name (for local _labels)
			; display one byte - two BCD encoded numbers
DISP_BYTE	MOV R2,#8			; 8 segments with dot
_DIB1			ANL P1,#0FEH		; clear data pin
			RRC A				; shift bit 0 to CY
			JNC _DIB2			; not set, shift it out
			ORL P1,#01H			; set data pin
_DIB2		ORL P1,#02FH		; set clock pin
			ANL P1,#0FDH		; clear clock pin
			DJNZ R2,_DIB1		; shift out all segments
			RET
			;
			;.ORG 03E8H			; page 3 end
			;
DIGIT		.DB 0FCH			; 0
			.DB 060H			; 1
			.DB 0DAH			; 2
			.DB 0F2H			; 3
			.DB 066H			; 4
			.DB 0B6H			; 5
			.DB 0BEH			; 6
			.DB 0E0H			; 7
			.DB 0FEH			; 8
			.DB 0F6H			; 9
			.DB 00H				; space [10]
			.DB 01H				; . [11]
