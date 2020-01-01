; archeocomp(2019) MCS-48 clock code
; clock counts HH MM SS in BCD code and ticks (in binary)
			;
			.MODULE CLOCK			; module name (for local _labels)
			;
			; initialize clock
CLOC_INI	CLR A					; clear A
			MOV R0,#CURR_STAT		; get address of current state variable
			MOV @R0,A				; clear CURR_STAT
			DEC R0					; PULSE_LEN
			MOV @R0,A				; clear PULSE_LEN
			DEC R0					; BIT_NUM
			MOV @R0,A				; clear BIT_NUM
			MOV R0,#POSITION		; get address of display position variable
			MOV @R0,A				; clear POSITION
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
			; set decoded radio time as new clock time
SETRADTIM	MOV R0,#RAD_HOU			; radio time hours
			MOV R1,#HOUR			; clock time hours
			MOV A,@R0				; get radio time hours
			MOV @R1,A				; set clock time hours
			INC R0					; move to minutes
			INC R1					; move to minutes
			MOV A,@R0				; get radio time minutes
			MOV @R1,A				; set clock time minutes
			INC R1					; move to seconds
			CLR A					; clear A
			MOV @R1,A				; set clock time seconds
			JMP SSCLK				; set RTC
			;
			; increment BCD number
			; R0 address of variable
INCBCD		MOV A,@R0				; get value to A
			INC A					; increment value
			DA A					; decimal value
			MOV @R0,A				; save value
_INCB1		RET						;
			;
			; timer/counter interrupt
CLOC_INT	INC R6					; ticks
			MOV A,#TICKS			; ticks per second
			SUB(R6)					; A=A-R6
			JNZ _CLOI1				; not yet one second
#IF DISPTYP==STATIC
			MOV R0,#CURR_STAT		; get address of current state variable
			XCH A,@R0				; refresh display once per second
			ORL A,#DISP_REFR		; combine values
			MOV @R0,A				; set CURR_STAT
#ELSE
			JMP _CONT1				; fill space
			NOP \ NOP
_CONT1		NOP
#ENDIF
			CLR A					; clear A
			MOV R6,A				; clear ticks
			MOV R0,#SECOND			; seconds address to R0
			CALL INCBCD				; increment seconds
			SUBI(60H)				; subtract 60s (one minute)
			JNZ _CLOI1				; not yet one minute
			CLR A					; clear A
			MOV @R0,A				; clear seconds
			DEC R0					; minutes address to R0
			CALL INCBCD				; increment minutes
			SUBI(60H)				; subtract 60m (one hour)
			JNZ _CLOI1				; not yet one hour
			CLR A					; clear A
			MOV @R0,A				; clear minutes
			DEC R0					; hours address to R0
			CALL INCBCD				; increment hours
			SUBI(24H)				; subtract 24h (one minute)
			JNZ _CLOI1				; not yet one minute
			CLR A					; clear A
			MOV @R0,A				; clear hours
_CLOI1		RET						; return
			;
