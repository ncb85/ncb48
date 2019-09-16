; archeocomp(2019) MCS-48 DCF-77 code
; with crystal 4.9152MHz timer interrupts 40 times per seconds
; as zero pulse is 100ms long and one pulse is 200ms long
; four interrupts correspond to 100ms
; thus 100ms pulses are sampled 4x, each sample is stored in shift register
; 100ms pulse should set all 4 bits of shift register to ones
; 200ms pulse should set all 8 bits of shift register to ones
;
; macros for subtract instruction A=A-Rx
#DEFINE SUB(Rx) CPL A \ ADD A,Rx \ CPL A
#DEFINE SUBI(Val) CPL A \ ADD A,#Val \ CPL A
;
; macros for serial log debugging
DEBUG		.EQU 1
#IF DEBUG
#DEFINE LOGA() CALL LOGACC
#DEFINE LOGI(Val) MOV R7,A \ MOV A,#'Val' \ CALL LOGIMD \ MOV A,R7
#DEFINE LOGINI() CALL LOGINIT
#ELSE
#DEFINE LOGA() ; nothing
#DEFINE LOGI(Val) ; nothing
#DEFINE LOGINI() ; nothing
#ENDIF
			;
			.MODULE DCF77			; module name (for local _labels)
			;
BEGIN		.EQU 000H				; begin address
			;
			; hw constants
CRYSTAL		.EQU 4915200			; Hz, timer interrupts 40 times per second
TICKS		.EQU CRYSTAL/3/5/32/256 ; ticks per second (40)
LOW_LEN		.EQU TICKS*4/5-1		; length of low (second) part of pulse
PULTIMOUT	.EQU TICKS+15			; 55 ticks, approx 1.4s
DATA_PIN	.EQU 01H				; data pin of display
CLOCK_PIN	.EQU 02H				; clock pin of display
LATCH_PIN	.EQU 04H				; latch pin of display
DSDAT_PIN	.EQU 08H				; data pin of DS1302
DSCLK_PIN	.EQU 10H				; clock pin of DS1302
DSCEN_PIN	.EQU 20H				; CE pin of DS1302
			;
			; variables
PULSE_HIST	.EQU 7FH				; pulse samples history register
PULSE_NEXT	.EQU 7EH				; timout to receive next valid pulse
SECOND		.EQU 7DH				; seconds
MINUTE		.EQU 7CH				; minutes
HOUR		.EQU 7BH				; hours
CURR_STAT	.EQU 7AH				; current state
PULSE_LEN	.EQU 79H				; current pulse length detected
BIT_NUM		.EQU 78H				; radio sequence bit number
RAD_MIN		.EQU 77H				; radio time minutes
RAD_HOU		.EQU 76H				; radio time hours
			;
			; state constants
PULSE_ZERO	.EQU 00H				; value zero pulse
PULSE_ONE	.EQU 10H				; value one pulse
PULSE_VALID	.EQU 01H				; valid pulse detected
PULSE_59	.EQU 02H				; last second detected
PULSE_ERR	.EQU 04H				; invalid input detected
;UNUSED		.EQU 08H				; unused bit (3)
ALLOWAIT	.EQU 20H				; check for max allowed time between two pulses
TIME_VAL	.EQU 40H				; radio time valid
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
			#INCLUDE "timer.asm"	; pulse sampling timer interrupt
			#INCLUDE "clock.asm"	; clock ticking
			#INCLUDE "decoder.asm"	; DCF-77 decoder
			#INCLUDE "ds1302.asm"	; RTC chip
			;
			;.ORG BEGIN+1C0H
			; program start
MAIN		ANL P1,#~DSCEN_PIN		; deactivate DS1302 - clear CE pin
			ANL P1,#~DSCLK_PIN		; clear clock pin
			LOGINI()
			CLR A					; clear A
			MOV R0,#CURR_STAT		; get address of current state variable
			MOV @R0,A				; clear CURR_STAT
			;CALL CLOC_INI			; initialize (cpu registers) clock
			CALL RDCLK				; set (cpu reg.) clock with time from DS1302
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
_VALPUL		ANL A,#~PULSE_VALID		; clear valid bit
			MOV @R0,A				; clear pulse
			CLR F0					; clear F0
			CPL F0					; set F0 - pulse value one
			JB4 _VALPUL2			; pulse value one
			CLR F0					; pulse value zero
_VALPUL2	;LOGI( )
			;LOGA()
			CALL DECODE				; decode pulses
			JMP _MAILOP				; loop
_SEC59		ANL A,#~PULSE_59		; clear sec59 bit
			JB2 _SEC59E				; error in reception RAD_ERR, nothing to do
			MOV @R0,A				; set CURR_STAT
			MOV R0,#BIT_NUM			; address of bit number
			MOV A,#-1				; preset counter to -1
			MOV @R0,A				; set bit number
			MOV R0,#CURR_STAT		; address of current state variable
			MOV A,@R0				; get CURR_STAT
			JB6 _SEC592				; flag TIME VALID set - new clock time
			JMP _MAILOP				; loop
_SEC592		ANL A,#~TIME_VAL		; clear flag
			MOV @R0,A				; set CURR_STAT
			CALL SETRADTIM			; set received radio time as new time
			LOGI(t)
			JMP _MAILOP				; loop
_SEC59E		ANL A,#~PULSE_ERR		; clear error on minute end
			ANL A,#~TIME_VAL		; clear flag
			MOV @R0,A				; set CURR_STAT
			JMP _MAILOP				; loop
			;
PART1S		.EQU $-BEGIN
#IF DEBUG
			#INCLUDE "debug.asm"	; DCF-77 decoder
#ENDIF
PART2B
			#INCLUDE "disp7seg.asm"	; seven segment display
			.ECHO "Size: "
PART2S		.ECHO PART1S+1024-PART2B
			.ECHO "\n"
			.END
			;
