; archeocomp(2019) MCS-48 DCF-77 code
; timer interrupt is used for pulse sampling and processing
; each 100ms time period is sampled 4x
			;
			.MODULE TIMER			; module name (for local _labels)
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
			JZ _BCCNS3				;   2  If integer n is not zero
_BCCNS2		MOV R3,A				;      (a) Do bitwise & with (n-1) and assign the value back to n
			DEC R3					;
			ANL A,R3				;          n: = n&(n-1)
			INC R2					;      (b) Increment count by 1
			JNZ _BCCNS2				;      (c) go to step 2
_BCCNS3		MOV A,R2				;   3  Else return count
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
			MOV R0,#PULSE_LEN		; get pulse length variable address to R0
			SUBI(2)					; number of ones in current 100ms period less then 2?
			JC _PRPUL1				; yes, we have zero, continue
			MOV A,R2				; restore count of latest four samples
			SUBI(3)					; is count above 2 (3 or 4)?
			JC _PRPUE1				; no, unable to decide (noise or in transition so ignore it)
_PRPUH1		MOV A,R4				; restore count of previous four samples
			SUBI(2)					; number of ones in previous 100ms period less then 2?
			JC _PRPUH2				; previous was low, beginning of new pulse (second)
			INC @R0					; previous was high, pulse still unfinished, increment length
			RET
_PRPUH2		MOV R0,#CURR_STAT		; get address of current state variable
			MOV A,@R0				; get state (PULSE_ZERO or PULSE_ONE)
			ANL A,#PULSE_ONE		; ignore other bits
			RR A					; divide by 2 (resulting in 4 or 0)
			MOV R0,#PULSE_LEN		; check low pulse length at least 800ms
			XCH A,@R0				; exchange values
			ADD A,@R0
			SUBI(LOW_LEN)			; zero level present longer then 800ms? (completed pulse)
			JC	_PRPUE1				; invalid pulse, low state was too short
			MOV @R0,#0				; start measuring pulse width
			MOV R0,#CURR_STAT		; get address of current state variable
			MOV @R0,#PULSE_BEGIN	; set pulse beginning
			CLR F1					; set pulse valid flag F1
			CPL F1					; pulse valid, start decoding
			RET
_PRPUL1		INC @R0					; increment length variable address
			MOV A,R4				; restore count of previous four samples
			SUBI(2)					; number of ones in previous 100ms period less then 2?
			JC _PRPUL4				; yes, still no new pulse detected
			MOV A,R2				; restore count of previous four samples
			SUBI(3)					; is count above 2 (3 or 4)?
			JC _PRPUE1				; no, unable to decide (noise or in transition so ignore it)
			 						; previous was high, we have end of pulse
			MOV R0,#CURR_STAT		; get address of current state variable
			MOV @R0,#PULSE_END		; set pulse end, evaluate it
			MOV R0,#PULSE_LEN		; get pulse length variable address to R0
			MOV A,@R0				; get pulse length
			SUBI(6)					; is count above 5?
			JNC _PRPUL2				; yes, it is long pulse e.g. PULSE_ONE
			MOV A,#PULSE_ZERO		; no, PULSE_ZERO
			JMP _PRPUL3
_PRPUL2		MOV A,#PULSE_ONE		; PULSE_ONE
_PRPUL3		MOV R0,#CURR_STAT		; get address of current state variable
			ORL A,@R0				; combine values
			XCH A,@R0				; exchange values (set CURR_STAT)
			RET
_PRPUL4		MOV R0,#PULSE_LEN		; get pulse length variable address to R0
			MOV A,@R0				; get pulse length
			SUBI(TICKS)				; zero level present longer then second? (sec.59)
			JNC	_PRPUL5				; yes, it is second nr.59
			RET
_PRPUL5		; second nr.59
			MOV R0,#CURR_STAT		; get current state variable address to R0
			MOV @R0,#PULSE_59		; set new state, we have detected second nr.59
			RET						; return
_PRPUE1		MOV R0,#CURR_STAT		; get current state variable address to R0
			MOV @R0,#PULSE_ERR		; error state
			RET
			;
			.ORG TSRADR
			; timer/counter interrupt, fetch input T0
TCINTR		SEL RB1					; second register bank
			MOV R7,A				; backup A
			CLR C					; clear carry
			JNT0 _TCIN1				; jump on 1
			CPL C					; set carry
_TCIN1		MOV R0,#PULSE_HIST		; pulse history address to R0
			MOV A,@R0				; pulse history to A
			RLC A					; shift in pulse value to A bit 0
			MOV A,@R0				; backup pulse history
			CALL PRPULS				; process pulse
			RETR					; restore PC and PSW
			JMP CLOC_INT			; process ticks
			;
