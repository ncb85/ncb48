; archeocomp(2019) MCS-48 DCF-77 decoder
; evaluates received sequence, extracts time and does parity check
; evaluated bits are
; 0 - always zero, 20 - always one
; 21-24 - minutes(1,2,4,8), 25-27 - minutes higher digit, 28 - parity
; 29-32 - hours(1,2,4,8), 33-34 - hours higher digit, 35 - parity
;
			.MODULE DECODER			; module name (for local _labels)
			;
			; set bit - input A weight, F0 value
			;
SETBIT		JF0 _SETBI1				; bit value one
			JMP _SETBEN				; bit value zero, nothing to do
_SETBI1		MOV R3,A				; bit weight
			MOV A,#80H				; value for weight 0
			INC R3					; increment R3
_SETBI2		RL A					; rotate A
			DJNZ R3,_SETBI2			; loop
			ORL A,@R0				; combine bits
			MOV @R0,A				; update value
_SETBEN		RET						; return
			;
			; check hours; <24, last digit <10, sets CY on error
CHECKH		;MOV R0,#RAD_HOU			; address of hours ?? needed ??
			MOV A,@R0				; get value
			SUBI(24)				; less than 24?
			JNC _CHKERR				; no, return error
			JMP _CHKLD				; check last digit
			;
			; check minutes; <60, last digit <10, sets CY on error
CHECKM		;MOV R0,#RAD_MIN			; address of minutes ?? needed ??
			MOV A,@R0				; get value
			SUBI(60)				; less than 60?
			JNC _CHKERR				; no, return error
_CHKLD		MOV A,@R0				; get value
			ANL A,#0FH				; last digit
			SUBI(10)				; less than 10?
_CHKERR		CPL C					; sets/clears error flag
			RET
			;
			; process bits - input value in F0
DECODE		MOV R0,#BIT_NUM			; address of bit number
			MOV A,@R0				; get bit number
			MOV R4,A				; backup bit number
            INC @R0					; increment bit number
            JNZ _DECB20				; not very first bit
            JF0 _DECERR				; first bit always zero
			LOGI(*)
			RET
_DECB20		MOV R0,#RAD_HOU			; get address of hours digit to R0
            SUBI(20)				; bit number 20 - always one
			JNZ _DECH1				; not bit 20
			JF0 _DECCLR				; two checkpoints passed, clear HH and MM
			JMP _DECERR				; error on not one
_DECCLR		MOV @R0,A				; clear radio minutes
			INC R0					; hours address
			MOV @R0,A				; clear radio hours
			LOGI(#)
			RET						; return
_DECH1		MOV A,R4				; restore bit number
			SUBI(35)				; more than 35?
			JZ _DECPA				; hours parity bit
			JNC _DECEND				; yes, ignore
			MOV A,R4				; restore bit number
			SUBI(28)				; more than 28?
			JC _DECM1				; no, try minutes
			JZ _DECPA				; minutes parity bit
			DEC A					; adjust (hours >= bit nr.29)
			JMP SETBIT				; update hours digits
_DECM1		INC R0					; get address of minutes digit to R0
			MOV A,R4				; restore bit number
			SUBI(21)				; less than 21?
			JC _DECEND				; yes, ignore
			CALL SETBIT				; update minutes digits
			RET						; return
_DECPA		CLR C					; check parity - clear CY
			CPL C					; set CY
			JF0 _DECP1				; parity one
			CLR C					; parity zero, clear CY
_DECP1		MOV A,@R0				; get hours digit
			CALL BCCNSB				; count ones
			ADDC A,#0				; add CY
			JB0 _DECERR				; parity error
			LOGI(*)
			MOV A,R4				; restore bit number
			SUBI(28)				; is it 28? (minute parity bit)
			JNZ _DECP2				; not minute parity bit
			CALL CHECKH				; check hour value 0-23
			JC _DECERR				; set error
_DECP2		MOV A,R4				; restore bit number
			SUBI(35)				; is it 35?
			JNZ _DECEND				; no, return
			CALL CHECKM				; check minute value 0-59
			JC _DECERR				; set error
			MOV R0,#CURR_STAT		; get address of status
			MOV A,@R0				; get status
			JB2 _DECEND				; return on previous error(s)
			MOV A,#TIME_VAL			; flag radio time valid
			JMP _DECSTA				; set state
_DECERR		LOGI(!)
			MOV A,#PULSE_ERR		; set error flag for radio frame
_DECSTA		MOV R0,#CURR_STAT		; get address of status
	    	ORL A,@R0				; combine values
	    	MOV @R0,A				; set new value
_DECEND		RET						; return
			;
