@echo off
REM ============================================
REM  Creates a "Spruce POS" shortcut on your Desktop
REM  Run this once to set up the shortcut
REM ============================================

set SCRIPT_DIR=%~dp0
set SHORTCUT_NAME=Spruce POS
set DESKTOP=%USERPROFILE%\Desktop

echo Creating desktop shortcut for Spruce POS...

powershell -NoProfile -Command ^
  "$ws = New-Object -ComObject WScript.Shell; " ^
  "$s = $ws.CreateShortcut('%DESKTOP%\%SHORTCUT_NAME%.lnk'); " ^
  "$s.TargetPath = '%SCRIPT_DIR%launch-spruce.vbs'; " ^
  "$s.WorkingDirectory = '%SCRIPT_DIR%'; " ^
  "$s.IconLocation = 'shell32.dll,13'; " ^
  "$s.Description = 'Launch ECI Spruce POS'; " ^
  "$s.Save()"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo SUCCESS! "Spruce POS" shortcut created on your Desktop.
    echo Double-click it to open Spruce in a clean app window.
) else (
    echo.
    echo ERROR: Could not create shortcut. Try running as Administrator.
)

echo.
pause
