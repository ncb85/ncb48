; archeocomp(2019) MCS-48 DCF-77 code
			;
BEGIN		.EQU 400H				; begin address
TSRADR		.EQU 0780H				; TSR address
			; monitor routines
TXNIBB		.EQU 041H
TXCHAR		.EQU 031H
TXBYTE		.EQU 03CH
			;
; macro for subtract instruction A=A-Rx
#DEFINE SUB(Rx) CPL A \ ADD A,Rx \ CPL A
			;
			; hw constants
;CRYSTAL		.EQU 6144000		; Hz
CRYSTAL		.EQU 4915200			; Hz
TICKS		.EQU CRYSTAL/3/5/32/256 ; ticks per second
			; variables
PULSE_HIST	.EQU 127				; pulse samples history register
SECOND		.EQU 126				; seconds
MINUTE		.EQU 125				; minutes
HOUR		.EQU 124				; hours
			;
			; pulse constants
PULSE_NONE	.EQU FFH				; no pulse detected
PULSE_ZERO	.EQU 00H				; zero pulse detected
PULSE_NONE	.EQU 01H				; one pulse detected
PULSE_59	.EQU 02H				; laste second detected
			;
			.ORG BEGIN				; reset vector
			JMP MAIN				; jump to main routine
			.ORG BEGIN+3			; external interrupt input
			JMP INTRPT				; jump to interrupt routine
			.ORG BEGIN+7			; timer interrupt
			; timer/counter interrupt
TIMR		JMP TCINTR				; call routine
			;
			; external interrupt
INTRPT		RETR 					; restore PC and PSW
			;
			; Brian Kernighan’s Algorithm to count set bits
			; Subtraction of 1 from a number toggles all the bits (from right to left)
			; till the rightmost set bit(including the rightmost set bit).
			; So if we subtract a number by 1 and do bitwise & with itself (n & (n-1)),
			; we unset the rightmost set bit. If we do n & (n-1) in a loop and
			; count the no of times loop executes we get the set bit count.
			; The beauty of this solution is the number of times it loops
			; is equal to the number of set bits in a given integer.
			CLR R2					; 1  Initialize count: = 0
BCBCN		JZ TCIN3				;   2  If integer n is not zero
			MOV R3,A				;      (a) Do bitwise & with (n-1) and assign the value back to n
			DEC R3					;
			ANL A,R3				;          n: = n&(n-1)
			INC R2					;      (b) Increment count by 1
			JMP TCIN2				;      (c) go to step 2
			MOV A,R2				;   3  Else return count
			;
			; start
MAIN		CLR A					; clear A
			SEL RB1					; swith to alternate register bank
			MOV R6,A				; clear ticks
			SEL RB0					; back to standard register bank
			STRT T					; start timer
			EN TCNTI				; enable interrupt from timer
			RET
			;
			.ORG TSRADR
			; timer/counter interrupt, test input T0, last value of T0 input is in F1
TCINTR		SEL RB1					; second register bank
			MOV R7,A				; backup A
			JT0 TCIN1				; jump on 1
			JF1 TCIN2				; new state 0 latest state 1
			CLR F0					; new and last state both 0, clear F0 to match T0
			JMP TCIN5				; continue processing, detected value is 0
TCIN1		JF1	TCIN3				; new and last state both 1
			CLR F1					; new state 1 last state 0
			CPL F1					; set F1 to match T0
			CLR F0					; clear F0, detected value is 0
			JMP TCIN5				; continue processing
TCIN2		CLR F1					; clear F1 to match T0
			CLR F0					; clear F0
			CPL F0					; detected value is 1
			JMP TCIN5				; continue processing
TCIN3		CLR F0					; clear F0
			CPL F0					; detected value is 1
			;JMP TCIN5				; continue processing
TCIN5
			RETR					; restore PC and PSW
			;
			; timer/counter interrupt, test input T0, last value of T0 input is in F1
TCINTR		SEL RB1					; second register bank
			MOV R7,A				; backup A
			CLR C					; clear carry
			JNT0 TCIN1				; jump on 1
			CPL C					; set carry
TCIN1		MOV R0,#PULSE_HIST		; pulse history address to R0
			MOV A,@R0				; pulse history to A
			RLC A					; shift in pulse value to A bit 0
			RETR					; restore PC and PSW
			.END
