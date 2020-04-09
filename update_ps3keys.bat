@echo off
copy templat\key.dat .\keydat

echo Updating ps3keys...
set /p ver=Type in new PS3 Firmware Version (e.g. for 4.87 type 487): 
copy ps3keys\*-484 ps3keys\*-%ver%

echo Updating scetool keys...
set /p new=Type in new PS3 Firmware Version in special format (e.g. for 4.87 type 40087): 
tools\sfk.exe rep -pat /90099/%new%/ -dir . -file keydat -yes
tools\sfk.exe partcopy keydat -allfrom 0x0 data\keys -append -yes
tools\sfk.exe partcopy keydat -allfrom 0x0 ps3keys\keys -append -yes

del /F /Q keydat
echo Done!
pause
