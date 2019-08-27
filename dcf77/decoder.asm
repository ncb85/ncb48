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
			; process bits - input value in F0
DECODE		MOV R0,#BIT_NUM			; get address of bit number
			MOV A,@R0				; get bit number
			MOV R2,A				; backup bit number
            INC @R0					; increment bit number
            JNZ _DECB20				; not very first bit
            JF0 _DECERR				; first bit always zero
_DECB20		MOV R0,#RAD_MIN			; get address of minutes digit to R0
            SUBI(20)				; bit number 20 - always one
			JNZ _DECH1				; not bit 20
			JF0 _DECCLR				; clear HH and MM
			JMP _DECERR				; error on not one
			;CLR A					optimized out
_DECCLR		MOV @R0,A				; clear radio minutes
			DEC R0					; hours address
			MOV @R0,A				; clear radio hours
			JMP _DECEND				; return
_DECH1		MOV R0,#RAD_HOU			; get address of hours digit to R0
			MOV A,R2				; restore bit number
			SUBI(35)				; more than 35?
			JNC _DECEND				; yes, ignore
			JZ _DECPA				; hours parity bit
			MOV A,R2				; restore bit number
			SUBI(28)				; more than 28?
			JC _DECM1				; no, try minutes
			JZ _DECPA				; minutes parity bit
			CALL SETBIT				; update hours digits
			JMP _DECSET				; set and return
_DECM1		MOV A,R2				; restore bit number
			SUBI(21)				; less than 21?
			JC _DECEND				; yes, ignore
			CALL SETBIT				; update minutes digits
			JMP _DECEND				; return
_DECPA		CLR C					; check parity - clear CY
			CLR C					; set CY
			JF0 _DECP1				; parity one
			CPL C					; parity zero, clear CY
_DECP1		MOV A,@R0				; get hours digit
			CALL BCCNSB				; count ones
			ADDC A,#0				; add CY
			JB0 _DECERR				; parity error
			RET						; return
_DECSET	    MOV @R0,A				; set new value
_DECEND		RET						; return
_DECERR     MOV R0,#CURR_STAT		; get address of status
	    	MOV A,#RAD_ERR			; set error flag for radio frame
            ORL A,@R0				; combine values
            MOV @R0,A				; set state
            RET						;
			;
