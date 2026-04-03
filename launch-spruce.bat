@echo off
REM ============================================
REM  ECI Spruce Desktop Launcher
REM  Opens Spruce POS in a desktop app window
REM ============================================

REM === SET YOUR SPRUCE URL HERE ===
set SPRUCE_URL=https://spruce.ecisolutions.com

REM Try Microsoft Edge first (preferred on Windows)
set EDGE_PATH=C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe
if exist "%EDGE_PATH%" (
    start "" "%EDGE_PATH%" --app=%SPRUCE_URL% --start-maximized
    exit /b
)

REM Fallback to Google Chrome
set CHROME_PATH=C:\Program Files\Google\Chrome\Application\chrome.exe
if exist "%CHROME_PATH%" (
    start "" "%CHROME_PATH%" --app=%SPRUCE_URL% --start-maximized
    exit /b
)

set CHROME_PATH_X86=C:\Program Files (x86)\Google\Chrome\Application\chrome.exe
if exist "%CHROME_PATH_X86%" (
    start "" "%CHROME_PATH_X86%" --app=%SPRUCE_URL% --start-maximized
    exit /b
)

REM Last resort: open in default browser
start %SPRUCE_URL%
