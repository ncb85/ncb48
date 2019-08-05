@ECHO OFF
SET source=dcf77
REM create version for CP/M Avocet Assembler
REM call cpmsed.bat %source%
REM assemble using TASM
call tasm.bat %source%

REM SET source=math48
REM call cpmsed.bat %source%
REM call tasm.bat %source%
