; archeocomp(2019) MCS-48 DCF-77 pulse sampling code
; timer interrupt 40Hz is used for pulse sampling and processing
; each 100ms time period is sampled 4x, input T0
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
			; two nibbles represent last two 100ms periods sampled four times
			; count ones in both nibbles and detect 0->1 transition at
			; the beginning of each second, detect 59th second - all zero
PRPULS		MOV R4,A				; back up A
			ANL A,#0F0H				; get previous four samples
			CALL BCCNSB				; count ones in previous four samples
			XCH A,R4				; exchange result and R4
			ANL A,#0FH				; get latest four samples
			CALL BCCNSB				; count ones in latest four samples
			MOV R2,A				; back up A (count of lower nibble ones)
			MOV R0,#PULSE_LEN		; get pulse length variable address to R0
			SUBI(2)					; number of ones in current 100ms period 0 or 1?
			JC _PRPUL1				; yes, we have zero now, jump
			MOV A,R2				; restore count of latest four samples
			SUBI(3)					; is number of ones 3 or 4?
			JC _PRPUI1				; no, unable to decide (noise or in transition so ignore it)
			; current period (nibble) is one
_PRPUH1		MOV A,R4				; restore count of previous four samples
			SUBI(2)					; number of ones in previous 100ms period less then 2?
			JC _PRPUH2				; previous was low, beginning of new pulse (second)
			MOV A,@R0				; set new length
			XRL A,#0FFH				; complement A
			JZ _PRPUE1				; overflow, do not increment anymore
			XRL A,#0FFH				; complement A
			INC @R0					; previous was high, pulse still unfinished, increment length
			RET
_PRPUH2		MOV R0,#CURR_STAT		; get address of current state variable
			MOV A,@R0				; get state (PULSE_ZERO or PULSE_ONE)
			ANL A,#PULSE_ONE		; ignore other bits
			RR A					; divide by 2 (resulting in 4 or 0)
			MOV R0,#PULSE_LEN		; check low pulse length at least 800ms
			ADD A,@R0				; add length of high level period
			MOV R3,A				; back up A
			MOV @R0,#0				; start measuring pulse width
			SUBI(TICKS*2+4)			; last pulse more than two seconds ago? (error)
			JNC	_PRPERR				; yes, no incoming pulses error
			MOV A,R3				; restore A
			SUBI(TICKS*2-8)			; previous pulse two seconds ago? (sec.59)
			JNC	_PRPLST				; yes, it is last second nr.59
			MOV A,R3				; restore A
			SUBI(LOW_LEN)			; zero level present longer then 800ms? (completed pulse)
			JC _PRPUE1				; no, unable to decide (maybe state after transition)
			MOV R0,#PULSE_NEXT		; get address of pulse timeout
			MOV @R0,#PULTIMOUT		; set max time allowed for next pulse to come
_PRPUH3		MOV R0,#CURR_STAT		; get address of current state variable
			MOV A,#PULSE_VALID		; set valid pulse
			ORL A,@R0				; combine values
			MOV @R0,A				; save new state
_PRPUE1		RET
_PRPUE2		MOV R0,#BIT_NUM			; address of bit number
			MOV A,@R0				; get bit number
			SUBI(58)				; is it sec.58? (it has no real end, as sec.59 is all zero)
			JNZ _PRPUE1				; no, return
			MOV R0,#CURR_STAT		; get address of current state variable
			MOV A,@R0				; get state (PULSE_ZERO or PULSE_ONE)
			ANL A,#PULSE_ONE		; ignore other bits
			RR A					; divide by 2 (resulting in 4 or 0)
			MOV R0,#PULSE_LEN		; check low pulse length at least 800ms
			ADD A,@R0				; add length of high level period
			SUBI(LOW_LEN)			; zero level present longer then 800ms? (completed pulse)
			JC _PRPUE1				; no, unable to decide (maybe state after transition)
			JMP _PRPUH3				; set valid pulse for sec.58 now, as sec.59 never pulses(syntetize pulse end)
			; current period (nibble) is zero
_PRPUL1		INC @R0					; increment length variable address
			MOV A,R4				; restore count of previous four samples
			SUBI(2)					; number of ones in previous 100ms period less then 2?
			JC _PRPUE2				; yes, still no new pulse detected
			MOV A,R4				; restore count of previous four samples
			SUBI(3)					; is count above 2 (3 or 4)?
			JC _PRPUI1				; no, unable to decide (noise or in transition so ignore it)
			MOV A,@R0				; end of high level, get pulse length
			SUBI(10)				; is count above 9? (error - pulse much too long)
			JC _PRPUL3				; it is OK, high level duration is not too long
_PRPERR		JMP DECERR				; set error(pulse high too long))
_PRPUL3		MOV A,@R0				; get pulse length
			SUBI(6)					; is count above 5?
			MOV R0,#CURR_STAT		; get address of current state variable
			MOV A,@R0				; get current state
			JNC _PRPUL4				; yes, it is long pulse e.g. PULSE_ONE
			ANL A,#~PULSE_ONE		; it is PULSE_ZERO, clear value bit
			MOV @R0,A				; set CURR_STAT
			RET
_PRPUL4		ORL A,#PULSE_ONE		; PULSE_ONE, set value bit
			MOV @R0,A				; set CURR_STAT
			RET
_PRPLST		MOV R0,#PULSE_LEN		; address of pulse length variable
			MOV @R0,#0				; start measuring pulse width
			MOV R0,#CURR_STAT		; get current state variable address to R0
			MOV A,#PULSE_59			; set new state, we have detected second nr.59
			ORL A,@R0				; combine values
			ANL A,#~ALLOWAIT		; clear flag for checking time between pulses
			MOV @R0,A				; save new state
			MOV A,#4				; compensate shift register delay
			MOV R6,A				; preset ticks
			LOGI(l)
_PRPUI1		RET						; return
			;
			; decrement time to wait for a pulse (approx 1.1sec)
			; and raise error on timeout of maximum time allowed for next pulse
PULSE_TCK	MOV R0,#PULSE_NEXT		; get address of pulse timeout
			MOV A,@R0				; move timeout to A
			DEC A					; decrement wait period
			MOV @R0,A				; set decremented timeout
			JB7 _PULTIMT1			; timeout occurred, invalidate whole sequence
_PULTIMT2	RET						; return
_PULTIMT1	JMP DECERR				; waiting for next pulse timeout error
			;
			; timer/counter interrupt, fetch input T0
TCINTR		SEL RB1					; second register bank
			MOV R7,A				; backup A
			CALL CLOC_INT			; run the clock
			MOV R0,#CURR_STAT		; get address of current state variable
			MOV A,@R0				; get state
			JB5 _TCIN1				; flag set, check for check max allowed time
			JMP _TCIN2				; flag not set, jump over
_TCIN1		CALL PULSE_TCK			; flag set, check for check max allowed time
_TCIN2		CLR C					; clear carry
			JT0 _TCIN3				; jump on 1 (or JNT0 on negative pulses)
			CPL C					; set carry
_TCIN3		MOV R0,#PULSE_HIST		; pulse history address to R0
			MOV A,@R0				; pulse history to A
			RLC A					; shift in pulse value to A bit 0
			MOV @R0,A				; backup pulse history
			CALL PRPULS				; process pulse
			MOV A,R7				; restore A
			RETR					; restore PC and PSW
			;
