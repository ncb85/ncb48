; archeocomp(2019) MCS-48 clock code (terminate, stay resident)
			;
BEGIN		.EQU 400H				; begin address
TSRADR		.EQU 0780H				; TSR address
			;
; macro for subtract instruction A=A-Rx
#DEFINE SUB(Rx) CPL A \ ADD A,Rx \ CPL A
			;
			; hw constants
;CRYSTAL		.EQU 9830400		; Hz
CRYSTAL		.EQU 11059200			; Hz
TICKS		.EQU CRYSTAL/3/5/32/256 ; ticks per second
			; variables
HOUR		.EQU 124				; hours
MINUTE		.EQU 125				; minutes
SECOND		.EQU 126				; seconds
			;
			.ORG BEGIN				; reset vector
			JMP MAIN				; jump to main routine
			.ORG BEGIN+3			; external interrupt input
			JMP INTRPT				; jump to interrupt routine
			.ORG BEGIN+7			; timer interrupt
			; timer/counter interrupt
TIMR		CALL TCINTR				; call routine
			RETR 					; restore PC and PSW
			;
			; external interrupt
INTRPT		;CALL EXINTR			; call routine
			RETR 					; restore PC and PSW
			;
			; start
MAIN		CLR A					; clear A
			MOV R0,#HOUR			; hours address to R0
			MOV @R0,A				; clear hours
			INC R0					; R0 points to minutes
			MOV @R0,A				; clear minutes
			INC R0					; R0 points to seconds
			MOV @R0,A				; clear seconds
			SEL RB1					; swith to alternate register bank
			MOV R6,A				; clear ticks
			SEL RB0					; back to standard register bank
			STRT T					; start timer
			EN TCNTI				; enable interrupt from timer
			RET
			;
			.ORG TSRADR
			; timer/counter interrupt
TCINTR		INC R6					; ticks
			MOV A,#TICKS			; ticks per second
			SUB(R6)					; A=A-R6
			JNZ TCINT1				; not yet one second
			CLR A					; clear A
			MOV R6,A				; clear ticks
			MOV R0,#SECOND			; seconds address to R0
			MOV A,@R0				; move seconds to A
			INC A					; increment seconds
			DA A					; decimal adjust
			MOV @R0,A				; save seconds
			MOV R2,#60H				; 60s (one minute)
			SUB(R2)					; A=A-R2
			JNZ TCINT1				; not yet one minute
			CLR A					; clear A
			MOV @R0,A				; clear seconds
			DEC R0					; minutes address to R0
			MOV A,@R0				; move minutes to A
			INC A					; increment minutes
			DA A					; decimal adjust
			MOV @R0,A				; save minutes
			MOV R2,#60H				; 60m (one hour)
			SUB(R2)					; A=A-R2
			JNZ TCINT1				; not yet one hour
			CLR A					; clear A
			MOV @R0,A				; clear minutes
			DEC R0					; hours address to R0
			MOV A,@R0				; move minutes to A
			INC A					; increment hours
			DA A					; decimal adjust
			MOV @R0,A				; save hours
TCINT1		RETR						; restore PC and PSW
			;
			.END
