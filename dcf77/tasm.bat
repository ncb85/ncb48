SET HOME=%CD%
SET OLDPATH=%PATH%

REM assemble source
SET PATH=%PATH%;..\tasm32
SET TASMTABS=..\tasm32
SET TASMOPTS=-48 -o10
tasm.exe %HOME%\%1.asm
SET PATH=%OLDPATH%

REM offset program in hex file for EPROM emulator
REM .\..\..\srecord-1.64-win32\srec_cat %1.obj -Intel -offset 0x0A000 -Output %1.hex -Intel -address-length=2 -Output_Block_Size=16
REM .\..\..\srecord-1.64-win32\srec_cat %1.obj -Intel -offset 0x0E000 -Output %1.hex -Intel -address-length=2 -Output_Block_Size=16
.\..\..\srecord-1.64-win32\srec_cat %1.obj -Intel -offset 0x0000 -Output %1_000.hex -Intel -address-length=2 -Output_Block_Size=16
