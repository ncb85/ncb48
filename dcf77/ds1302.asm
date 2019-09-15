; archeocomp(2019) MCS-48 trickle charge timekeeping chip DS1302 routines
; Simple 3-Wire Interface
; CE AND CLOCK CONTROLDriving the CE input high initiates all data transfers.
; The CE input serves two functions. First, CE turns on the control logic
; that allows access to the shift register for the address/command sequence.
; Second, the CE signal provides a method of terminating either single-byte or
; multiple-byte CE data transfer.A clock cycle is a sequence of a rising edge
; followed by a falling edge. For data inputs, data must be valid during
; the rising edge of the clock and data bits are output on the falling edge
; of clock. If the CE input is low, all data transfer terminates and the I/O pin
; goes to a high-impedance state. Figure 4 shows data transfer. At power-up,
; CE must be a logic 0 until VCC > 2.0V. Also, SCLK must be at a logic 0 when
; CE is driven to a logic 1 state.DATA INPUTFollowing the eight SCLK cycles that
; input a write command byte, a data byte is input on the rising edge of the next
; eight SCLK cycles. Additional SCLK cycles are ignored should they inadvertently
; occur. Data is input starting with bit 0.DATA OUTPUTFollowing the eight SCLK
; cycles that input a read command byte, a data byte is output on the falling
; edge of the next eight SCLK cycles. Note that the first data bit to be
; transmitted occurs on the first falling edge after the last bit of the command
; byte is written. Additional SCLK cycles retransmit the data bytes should they
; inadvertently occur so long as CE remains high. This operation permits continuous
; burst mode read capability. Also, the I/O pin is tristated upon each rising edge
; of SCLK. Data is output starting with bit 0.
; DS1302 can be run in either 12-hour or 24-hour mode. Bit 7 of the hours register
; is defined as the 12- or 24-hour mode-select bit. When high, the 12-hour mode
; is selected. In the 12-hour mode, bit 5 is the AM/PM  bit  with  logic high
; being PM. In the 24-hour mode, bit 5 is the second 10-hour bit (20–23 hours).
; The hours data must be re-initialized whenever the 12/24 bit is changed.
; Bit 7 of the seconds register is defined as the clock halt (CH) flag. When
; this bit is set to logic 1, the clock oscillator is stopped and the DS1302 is
; placed into a low-power standby mode with a current drain of less than 100nA,
; when this bit is written to logic 0, the clock will start.
; Initial power-on state is not defined.
;
			;
			.MODULE DS1302			; module name (for local _labels)
			; pin definitions
DS_SEC		.EQU 80H				; seconds register address
DS_MIN		.EQU 82H				; minutes register address
DS_HOUR		.EQU 84H				; hours	register address
			; bit definitions
DS_READ		.EQU 01H				; bit 0 set indicates READ
			;
			; send address byte to DS1302, data bit is input on the rising edge of clock pin
DSSE_BYTE	MOV R2,#8				; 8 bits serialy
_DSSB1		ANL P1,#~DSDAT_PIN		; clear data pin
			RRC A					; shift bit 0 to CY
			JC _DSSB2				; not set, shift it out
			ORL P1,#DSDAT_PIN		; set data pin
_DSSB2		ANL P1,#~DSCLK_PIN		; clear clock pin
			ORL P1,#DSCLK_PIN		; set clock pin
			DJNZ R2,_DSSB1			; shift out all bits
			RET
			;
			; send data byte to a DS1302 register, data bit is input on the rising edge of clock pin
			; input R1 DS1302 register address, A data
DSSE_REG	ORL P1,#DSCEN_PIN		; activate DS1302 - set CE pin
			XCH A,R1				; swap address to A
			CALL DSSE_BYTE			; send address byte to DS1302
			XCH A,R1				; swap data byte to A
			CALL DSSE_BYTE			; send data byte to DS1302
			ANL P1,#~DSCEN_PIN		; deactivate DS1302 - clear CE pin
			RET
			;
			; receive data byte from DS1302 register, data bit occurs on the falling edge
			; input R1 DS1302 register address, output A
DSRC_REG	MOV A,R1				; get address to R1
			ORL A,#DS_READ			; set read bit
			ORL P1,#DSCEN_PIN		; activate DS1302 - set CE pin
			CALL DSSE_BYTE			; send address byte to DS1302
			MOV R2,#7				; 8 bits serialy
			ORL P1,#DSCLK_PIN		; set clock pin
_DSRB1		ANL P1,#~DSCLK_PIN		; clear clock pin
			CLR C					; clear CY
			IN A,P1					; read data from port P1
			ORL P1,#DSCLK_PIN		; set clock pin
			JB3 _DSRB2				; bit set, set CY
			JMP _DSRB3				; jump over
_DSRB2		CPL C					; set CY
_DSRB3		RRC A					; shift bit into A
			DJNZ R2,_DSRB1			; shift in all bits
			ANL P1,#~DSCEN_PIN		; deactivate DS1302 - clear CE pin
			RET
			;
			; set and start clock (in 24h, bit7 hour reg. is 0)
			; (sec.reg bit 7 value 0 starts clock)
SSCLK		CLR A					; clear A
			MOV R1,#DS_HOUR			; get hours register address to R1
			CALL DSSE_REG			; set hours
			CLR A					; clear A
			MOV R1,#DS_MIN			; get minutes register address to R1
			CALL DSSE_REG			; set minutes
			CLR A					; clear A
			MOV R1,#DS_SEC			; get seconds register address to R1
			CALL DSSE_REG			; set seconds
			RET
			;
