; archeocomp(2019) MCS-48 DCF-77 code
; with crystal 4.9152MHz timer interrupts 40 times per seconds
; as zero pulse is 100ms long and one pulse is 200ms long
; four interrupts correspond to 100ms
; thus 100ms pulses are sampled 4x, each sample is stored in shift register
; 100ms pulse should set all 4 bits of shift register to ones
; 200ms pulse should set all 8 bits of shift register to ones
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
#DEFINE SUBI(Val) CPL A \ ADD A,#Val \ CPL A
			;
			; hw constants
CRYSTAL		.EQU 4915200			; Hz, timer interrupts 40 times per second
TICKS		.EQU CRYSTAL/3/5/32/256 ; ticks per second
			; variables
PULSE_HIST	.EQU 127				; pulse samples history register
SECOND		.EQU 126				; seconds
MINUTE		.EQU 125				; minutes
HOUR		.EQU 124				; hours
CURR_STAT	.EQU 123				; current state
PULS_LEN	.EQU 122				; current pulse length detected
			;
			; pulse constants
PULSE_UNKN	.EQU 0FFH				; unknown pulse detected
PULSE_ZERO	.EQU 00H				; zero pulse detected
PULSE_ONE	.EQU 01H				; one pulse detected
PULSE_BEGIN	.EQU 01H				; begin of pulse detected
PULSE_END	.EQU 02H				; end of pulse detected
PULSE_59	.EQU 03H				; last second detected
PULSE_ERR	.EQU 04H				; invalid input detected
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
			; count the number of times loop executes we get the set bit count.
			; The beauty of this solution is the number of times it loops
			; is equal to the number of set bits in a given integer.
BCCNSB		MOV R2,#0				; 1  Initialize count: = 0
			JZ BCCNS3				;   2  If integer n is not zero
BCCNS2		MOV R3,A				;      (a) Do bitwise & with (n-1) and assign the value back to n
			DEC R3					;
			ANL A,R3				;          n: = n&(n-1)
			INC R2					;      (b) Increment count by 1
			JNZ BCCNS2				;      (c) go to step 2
BCCNS3		MOV A,R2				;   3  Else return count
			RET						; return number of 1 in shift register
			;
			; process pulse - shift register contains last 8 pulses
			; two nibbles represent last two pulses sampled four times
			; count ones in both nibbles and detect transition at the beggining of each second
			; detect 59th second - all zero
PRPULS		MOV R4,A				; back up A
			ANL A,#0F0H				; get previuos four samples
			CALL BCCNSB				; count ones in previous four samples
			XCH A,R4				; exchange result and R4
			ANL A,#0FH				; get latest four samples
			CALL BCCNSB				; count ones in latest four samples
			MOV R2,A				; back up A (count of lower nibble ones)
			MOV R0,#PULS_LEN		; get pulse length variable address to R0
			SUBI(2)					; number of ones in current 100ms period less then 2?
			JC PRPUL1				; yes, we have zero, continue
			MOV A,R2				; restore count of latest four samples
			SUBI(3)					; is count above 2 (3 or 4)?
			JC PRPUE1				; no, unable to decide (noise or in transition so ignore it)
PRPUH1		MOV A,R4				; restore count of previous four samples
			SUBI(2)					; number of ones in previous 100ms period less then 2?
			JC PRPUH2				; previous was low, begin of new pulse (second)
			INC @R0					; previous was high, pulse still unfinished, increment length
			RET
PRPUH2		MOV @R0,#PULS_LEN		; check low pulse length at least 800ms
			MOV A,@R0				; get pulse length
			SUBI(TICKS-TICKS*4/5+1)	; zero level present longer then 800ms? (completed pulse)
			JC	PRPUE1				; yes, it is second nr.59
			MOV @R0,#0				; start measuring pulse width
			MOV @R0,#CURR_STAT		; get address of current state variable
			MOV @R0,#PULSE_BEGIN	; set pulse begin
			RET
PRPUL1		INC @R0					; increment length variable address
			MOV A,R4				; restore count of previous four samples
			SUBI(2)					; number of ones in previous 100ms period less then 2?
			JC PRPUL2				; yes, still no new pulse detected
			MOV A,R2				; restore count of previous four samples
			SUBI(3)					; is count above 2 (3 or 4)?
			JC PRPUE1				; no, unable to decide (noise or in transition so ignore it)
			; fall through			  previous was high, we have end of pulse
			MOV @R0,#CURR_STAT		; get address of current state variable
			MOV @R0,#PULSE_END		; set pulse end
			RET
PRPUL2		MOV R0,#PULS_LEN		; get pulse length variable address to R0
			MOV A,@R0				; get pulse length
			SUBI(TICKS)				; zero level present longer then second? (sec.59)
			JNC	PRPUL9				; yes, it is second nr.59
			RET
PRPUL9		; second nr.59
			MOV R0,#CURR_STAT		; get current state variable address to R0
			MOV @R0,#PULSE_59		; set new state, we have detected second nr.59
			RET						; return
PRPUE1		MOV R0,#CURR_STAT		; get current state variable address to R0
			MOV @R0,#PULSE_ERR		; error state
			RET
			;
			; program start
MAIN		CLR A					; clear A
			SEL RB1					; swith to alternate register bank
			MOV R6,A				; clear ticks
			SEL RB0					; back to standard register bank
			STRT T					; start timer
			EN TCNTI				; enable interrupt from timer
			RET						; return
			;
			.ORG TSRADR
			; timer/counter interrupt, test input T0, last value of T0 input is in F1
TCINTR		SEL RB1					; second register bank
			MOV R7,A				; backup A
			CLR C					; clear carry
			JNT0 TCIN1				; jump on 1
			CPL C					; set carry
TCIN1		MOV R0,#PULSE_HIST		; pulse history address to R0
			MOV A,@R0				; pulse history to A
			RLC A					; shift in pulse value to A bit 0
			MOV A,@R0				; backup pulse history
			CALL PRPULS				; process pulse
			RETR					; restore PC and PSW
			;
			.END
			; timer/counter interrupt, test input T0, last value of T0 input is in F1
;TCINTR		SEL RB1					; second register bank
;			MOV R7,A				; backup A
;			JT0 TCIN1				; jump on 1
;			JF1 TCIN2				; new state 0 latest state 1
;			CLR F0					; new and last state both 0, clear F0 to match T0
;			JMP TCIN5				; continue processing, detected value is 0
;TCIN1		JF1	TCIN3				; new and last state both 1
;			CLR F1					; new state 1 last state 0
;			CPL F1					; set F1 to match T0
;			CLR F0					; clear F0, detected value is 0
;			JMP TCIN5				; continue processing
;TCIN2		CLR F1					; clear F1 to match T0
;			CLR F0					; clear F0
;			CPL F0					; detected value is 1
;			JMP TCIN5				; continue processing
;TCIN3		CLR F0					; clear F0
;			CPL F0					; detected value is 1
			;JMP TCIN5				; continue processing
;TCIN5
;			RETR					; restore PC and PSW
			;
