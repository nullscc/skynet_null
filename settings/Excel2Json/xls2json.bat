@echo off
for /f "delims=" %%i in ('dir /b /a-d /s ..\xls\"*.xls"') do (
rem @echo i %%i
call :process %%i
)
@echo ���ɳɹ�
pause
goto :eof
:process
rem @echo 111 %1
for /f "delims=" %%i in ("%1") do (
rem set filep=%%~dpi
set filen=%%~nxi
)
@echo ����xls�ļ� %filen%
call Excel2JSON.py %filen% 3 0 2 1
goto :eof

exit