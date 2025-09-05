@echo off
title PrimeWinTools Installer Builder
echo.
echo =======================================
echo    PrimeWinTools Installer Builder
echo =======================================
echo.

REM Check if Inno Setup is installed
set "INNO_PATH="
if exist "G:\Program Files (x86)\Inno Setup 6\ISCC.exe" set "INNO_PATH=G:\Program Files (x86)\Inno Setup 6\ISCC.exe"
if exist "G:\Program Files\Inno Setup 6\ISCC.exe" set "INNO_PATH=G:\Program Files\Inno Setup 6\ISCC.exe"
if exist "%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe" set "INNO_PATH=%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe"
if exist "%ProgramFiles%\Inno Setup 6\ISCC.exe" set "INNO_PATH=%ProgramFiles%\Inno Setup 6\ISCC.exe"
if exist "%ProgramFiles(x86)%\Inno Setup 5\ISCC.exe" set "INNO_PATH=%ProgramFiles(x86)%\Inno Setup 5\ISCC.exe"
if exist "%ProgramFiles%\Inno Setup 5\ISCC.exe" set "INNO_PATH=%ProgramFiles%\Inno Setup 5\ISCC.exe"

if "%INNO_PATH%"=="" (
    echo [ERROR] Inno Setup not found!
    echo.
    echo Please download and install Inno Setup from:
    echo https://jrsoftware.org/isdl.php
    echo.
    echo After installation, run this script again.
    echo.
    pause
    exit /b 1
)

echo [OK] Found Inno Setup at: %INNO_PATH%

REM Check if Flutter app is built
if not exist "build\windows\x64\runner\Release\PrimeWinTools.exe" (
    echo [ERROR] PrimeWinTools.exe not found!
    echo.
    echo Please build your Flutter app first with:
    echo flutter build windows --release
    echo.
    pause
    exit /b 1
)

echo [OK] Found built application

REM Create output directory
if not exist "installer_output" mkdir "installer_output"
echo [OK] Output directory ready

REM Build the installer
echo.
echo Building installer...
echo.

"%INNO_PATH%" "installer.iss"

if %ERRORLEVEL% equ 0 (
    echo.
    echo [SUCCESS] Installer built successfully!
    echo Location: installer_output\PrimeWinTools-Setup-v1.0.0.exe
    echo.
    set /p choice="Open installer folder? (y/n): "
    if /i "%choice%"=="y" explorer "installer_output"
) else (
    echo.
    echo [ERROR] Installer build failed!
    echo.
)

pause
