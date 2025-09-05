# PrimeWinTools Installer

This directory contains the installer configuration and build scripts for PrimeWinTools.

## Prerequisites

1. **Inno Setup** - Download and install from [https://jrsoftware.org/isdl.php](https://jrsoftware.org/isdl.php)
2. **Built Flutter Application** - Make sure you've built your app with `flutter build windows --release`

## Quick Start

### Option 1: Using Batch File (Recommended)
1. Double-click `build_installer.bat`
2. The script will check prerequisites and build the installer automatically

### Option 2: Using PowerShell
1. Open PowerShell in this directory
2. Run: `.\build_installer.ps1`

### Option 3: Manual Build
1. Open Inno Setup
2. Load `installer.iss`
3. Click "Build" or press F9

## Output

The installer will be created in the `installer_output` folder as:
- `PrimeWinTools-Setup-v1.0.0.exe`

## Installer Features

✅ **Modern Windows Installer**
- Professional-looking wizard interface
- Automatic dependency detection
- Clean uninstall process

✅ **User Options**
- Desktop shortcut (optional)
- Quick Launch shortcut (optional)
- Start with Windows (optional)

✅ **Smart Installation**
- Installs to Program Files by default
- Creates Start Menu shortcuts
- Includes license and README
- Preserves app icon

✅ **Registry Integration**
- Optional startup entry
- Clean removal on uninstall

## Customization

Edit `installer.iss` to customize:
- App version and company info
- Installation options
- File associations
- Custom actions

## File Structure

```
installer.iss          # Main Inno Setup script
build_installer.ps1    # PowerShell build script
build_installer.bat    # Batch file wrapper
installer_output/      # Generated installer location
```

## Troubleshooting

**"Inno Setup not found"**
- Download and install Inno Setup from the official website
- Make sure it's installed in the default location

**"PrimeWinTools.exe not found"**
- Build your Flutter app first: `flutter build windows --release`
- Check that the exe exists in `build\windows\x64\runner\Release\`

**"Access denied" errors**
- Run as Administrator if needed
- Check file permissions in the build directory

## Distribution

The generated installer is a single executable file that can be:
- Shared directly with users
- Uploaded to your website
- Distributed via software repositories
- Code-signed for additional trust (optional)

## Version Updates

To create a new version:
1. Update the version number in `installer.iss`
2. Rebuild your Flutter app
3. Run the installer build script
4. The new installer will have the updated version in its filename
