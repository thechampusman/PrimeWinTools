@echo off
echo Building clipboard popup executable...
flutter build windows --target=lib/clipboard_popup_main.dart --release
if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ Clipboard popup executable built successfully!
    echo Location: build\windows\x64\runner\Release\PrimeWinTool.exe
    echo.
    echo You can now use Win+Alt+V to open the independent clipboard popup!
) else (
    echo.
    echo ❌ Build failed!
)
pause
