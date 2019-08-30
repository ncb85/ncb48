; archeocomp(2019) MCS-48 DCF-77 code
; with crystal 4.9152MHz timer interrupts 40 times per seconds
; as zero pulse is 100ms long and one pulse is 200ms long
; four interrupts correspond to 100ms
; thus 100ms pulses are sampled 4x, each sample is stored in shift register
; 100ms pulse should set all 4 bits of shift register to ones
; 200ms pulse should set all 8 bits of shift register to ones
			;
			.MODULE DCF77			; module name (for local _labels)
			;
BEGIN		.EQU 400H				; begin address
TSRADR		.EQU 4F0H				; TSR address
			; monitor routines
TXNIBB		.EQU 041H
TXCHAR		.EQU 031H
TXBYTE		.EQU 03CH
			;
; macro for subtract instruction A=A-Rx
#DEFINE SUB(Rx) CPL A \ ADD A,Rx \ CPL A
#DEFINE SUBI(Val) CPL A \ ADD A,#Val \ CPL A
; macro for serial log
#DEFINE LOGI(Val) MOV R2,#'Val' \ CALL TXCHAR
#DEFINE LOGA() MOV R2,A \ CALL TXBYTE
#DEFINE SERA(Val) MOV A,#'Val' \ MOV R0,#8 \ MOVX @R0,A
			;
			; hw constants
CRYSTAL		.EQU 4915200			; Hz, timer interrupts 40 times per second
TICKS		.EQU CRYSTAL/3/5/32/256 ; ticks per second
LOW_LEN		.EQU TICKS*4/5+1		; length of low (second) part of pulse
DATA_PIN	.EQU 01H				; data pin of display
CLOCK_PIN	.EQU 02H				; clock pin of display
LATCH_PIN	.EQU 04H				; latch pin of display
			;
			; variables
PULSE_HIST	.EQU 127				; pulse samples history register
SECOND		.EQU 126				; seconds
MINUTE		.EQU 125				; minutes
HOUR		.EQU 124				; hours
CURR_STAT	.EQU 123				; current state
PULSE_LEN	.EQU 122				; current pulse length detected
BIT_NUM		.EQU 121
RAD_MIN		.EQU 120				; radio time minutes
RAD_HOU		.EQU 119				; radio time hours
			;
			; state constants
PULSE_ZERO	.EQU 00H				; value zero pulse
PULSE_ONE	.EQU 10H				; value one pulse
PULSE_VALID	.EQU 01H				; valid pulse detected
PULSE_59	.EQU 02H				; last second detected
PULSE_ERR	.EQU 04H				; invalid input detected
ALL_DONE	.EQU 20H				; ready for new transmission
TIME_VAL	.EQU 40H				; radio time is valid
DISP_REFR	.EQU 80H				; refresh display
			;
			.ORG BEGIN				; reset vector
			JMP MAIN				; jump to main routine
			.ORG BEGIN+3			; external interrupt input
			JMP INTRPT				; jump to interrupt routine
			.ORG BEGIN+7			; timer interrupt
			; timer/counter interrupt
TIMR		JMP TCINTR				; call routine
			; external interrupt
INTRPT		RETR 					; restore PC and PSW
			;
			#INCLUDE "disp7seg.asm"	; seven segment display
			#INCLUDE "timer.asm"	; pulse sampling timer interrupt
			#INCLUDE "clock.asm"	; clock ticking
			#INCLUDE "decoder.asm"	; DCF-77 decoder
			;
			; program start
			.ORG BEGIN+200H
MAIN		CLR A					; clear A
			MOV R0,#CURR_STAT		; get address of current state variable
			MOV @R0,A				; clear CURR_STAT
			CALL CLOC_INI			; initialize clock
			STRT T					; start timer
			EN TCNTI				; enable interrupt from timer
_MAILOP		MOV R0,#CURR_STAT		; get address of current state variable
			MOV A,@R0				; get CURR_STAT
			JB0 _VALPUL				; valid pulse
			JB1 _SEC59				; 59 second pulse
			JB7 _DISPTIM			; refresh display
			JMP _MAILOP				; loop
_DISPTIM	CALL DISP_TIME			; display time
			JMP _MAILOP				; loop
_VALPUL		ANL A,#~PULSE_VALID		; clear flag bit
			MOV @R0,A				; clear pulse
			CLR F0					; clear F0
			CPL F0					; set F0 - pulse value one
			JB4 _VALPUL2			; pulse value one
			CLR F0					; pulse value zero
_VALPUL2	CALL DECODE				; decode pulses
			JMP _MAILOP				; loop
_SEC59		JB2 _SEC59E				; error in reception RAD_ERR, nothing to do
			JB5 _MAILOP				; frame done before, nothing to do
			; ALL_DONE not yet set, write data from reception frame
			ANL A,#~PULSE_59		; clear sec59 bit
			ORL A,#ALL_DONE			; set done bit(5)
			MOV @R0,A				; set CURR_STAT
			SERA($)
			MOV R0,#BIT_NUM			; address of bit number
			CLR A					; clear A
			MOV @R0,A				; clear bit number
			MOV R0,#CURR_STAT		; address of current state variable
			MOV A,@R0				; get CURR_STAT
			JB6 _SEC592				; flag TIME VALID set - new clock time
			JMP _MAILOP				; loop
_SEC592		ANL A,#~TIME_VAL		; clear flag
			MOV @R0,A				; set CURR_STAT
			CALL SETRADTIM			; set radio time as new time
			SERA(t)
			JMP _MAILOP				; loop
_SEC59E		ANL A,#~PULSE_ERR		; clear error on minute end
			MOV @R0,A				; set CURR_STAT
			SERA(e)
			JMP _MAILOP				; loop
			.ECHO "Size: "
			.ECHO $
			.ECHO "\n"
			.END
			;
