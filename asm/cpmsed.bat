REM sed -b -e 's/\.ORG/ORG/g;s/\.EQU/EQU/g;s/\.END/END/g;s/~/NOT /g;s/CTRL_/CTRL/g;/\.ECHO/d' %1 > ncb48.cpm
REM use sed commands from file commands.sed
sed -b -f commands.sed %1.asm > %1.cpm
