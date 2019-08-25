; archeocomp(2019) MCS-48 clock code
; clock counts HH MM SS in BCD code and ticks (in binary)
;
			; initialize clock
CLOC_INI	CLR A					; clear A
			MOV R0,#HOUR			; hours address to R0
			MOV @R0,A				; clear hours
			INC R0					; R0 points to minutes
			MOV @R0,A				; clear minutes
			INC R0					; R0 points to seconds
			MOV @R0,A				; clear seconds
			SEL RB1					; swith to alternate register bank
			MOV R6,A				; clear ticks
			SEL RB0					; back to standard register bank
			RET
			;
			; timer/counter interrupt
CLOC_INT	INC R6					; ticks
			MOV A,#TICKS			; ticks per second
			SUB(R6)					; A=A-R6
			JNZ _CLOC_IN1			; not yet one second
			MOV R0,#CURR_STAT		; get address of current state variable
			XCH A,@R0				; refresh display once per second
			ORL A,#DISP_REFR		; combine values
			MOV @R0,A				; set CURR_STAT
			CLR A					; clear A
			MOV R6,A				; clear ticks
			MOV R0,#SECOND			; seconds address to R0
			MOV A,@R0				; move seconds to A
			INC A					; increment seconds
			DA A					; decimal adjust
			MOV @R0,A				; save seconds
			SUBI(60H)				; subtract 60s (one minute)
			JNZ _CLOC_IN1			; not yet one minute
			CLR A					; clear A
			MOV @R0,A				; clear seconds
			DEC R0					; minutes address to R0
			MOV A,@R0				; move minutes to A
			INC A					; increment minutes
			DA A					; decimal adjust
			MOV @R0,A				; save minutes
			SUBI(60H)				; subtract 60m (one hour)
			JNZ _CLOC_IN1			; not yet one hour
			CLR A					; clear A
			MOV @R0,A				; clear minutes
			DEC R0					; hours address to R0
			MOV A,@R0				; move hours to A
			INC A					; increment hours
			DA A					; decimal adjust
			MOV @R0,A				; save hours
			SUBI(24H)				; subtract 24h (one minute)
			JNZ _CLOC_IN1			; not yet one minute
			CLR A					; clear A
			MOV @R0,A				; clear hours
_CLOC_IN1	RET
			;
