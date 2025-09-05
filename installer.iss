[Setup]
AppName=PrimeWinTools
AppVersion=1.0.3
AppPublisher=Your Company Name
AppPublisherURL=https://github.com/thechampusman/PrimeWinTools
AppSupportURL=https://github.com/thechampusman/PrimeWinTools/issues
AppUpdatesURL=https://github.com/thechampusman/PrimeWinTools/releases
DefaultDirName={autopf}\PrimeWinTools
DefaultGroupName=PrimeWinTools
AllowNoIcons=yes
LicenseFile=LICENSE.txt
InfoBeforeFile=README.md
OutputDir=installer_output
OutputBaseFilename=PrimeWinTools-Setup-v1.0.3
SetupIconFile=assets\app_icon.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "quicklaunchicon"; Description: "{cm:CreateQuickLaunchIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked; OnlyBelowVersion: 6.1
Name: "startup"; Description: "Start PrimeWinTools with Windows"; GroupDescription: "Additional options:"; Flags: unchecked

[Files]
Source: "build\windows\x64\runner\Release\PrimeWinTools.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\*.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "assets\app_icon.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "LICENSE.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: "README.md"; DestDir: "{app}"; Flags: ignoreversion isreadme

[Icons]
Name: "{group}\PrimeWinTools"; Filename: "{app}\PrimeWinTools.exe"; IconFilename: "{app}\app_icon.ico"
Name: "{group}\{cm:UninstallProgram,PrimeWinTools}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\PrimeWinTools"; Filename: "{app}\PrimeWinTools.exe"; IconFilename: "{app}\app_icon.ico"; Tasks: desktopicon
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\PrimeWinTools"; Filename: "{app}\PrimeWinTools.exe"; Tasks: quicklaunchicon

[Registry]
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "PrimeWinTools"; ValueData: "{app}\PrimeWinTools.exe"; Flags: uninsdeletevalue; Tasks: startup

[Run]
Filename: "{app}\PrimeWinTools.exe"; Description: "{cm:LaunchProgram,PrimeWinTools}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}"

[Code]
procedure InitializeWizard();
begin
  WizardForm.LicenseAcceptedRadio.Checked := True;
end;
