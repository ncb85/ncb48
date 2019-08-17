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
LOW_LEN		.EQU TICKS-(TICKS*4/5)+1 ; length of low (second) part of pulse
			; variables
PULSE_HIST	.EQU 127				; pulse samples history register
SECOND		.EQU 126				; seconds
MINUTE		.EQU 125				; minutes
HOUR		.EQU 124				; hours
CURR_STAT	.EQU 123				; current state
PULSE_LEN	.EQU 122				; current pulse length detected
			;
			; pulse constants
PULSE_UNKN	.EQU 0FFH				; unknown pulse detected
PULSE_ZERO	.EQU 00H				; zero pulse detected
PULSE_ONE	.EQU 10H				; one pulse detected
PULSE_BEGIN	.EQU 01H				; begin of pulse detected
PULSE_END	.EQU 02H				; end of pulse detected
PULSE_59	.EQU 04H				; last second detected
PULSE_ERR	.EQU 08H				; invalid input detected
			;
			#INCLUDE "timer.asm"	; pulse sampling - timer interrupt routine
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
			; program start
MAIN		CLR A					; clear A
			SEL RB1					; swith to alternate register bank
			MOV R6,A				; clear ticks
			SEL RB0					; back to standard register bank
			STRT T					; start timer
			EN TCNTI				; enable interrupt from timer
			RET						; return
			;
			.END
			;
