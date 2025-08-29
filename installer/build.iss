#define AppName "Python Analytics Environment"
#define AppVersion "1.0.0"
#define RootDir "C:\\Tools\\python-analytics"           // change if you prefer
#define EnvName "Analytics"
#define EnvPath RootDir + "\\envs\\" + EnvName          // final env location

[Setup]
AppId={{2DDE0D5C-4A9D-4C2A-9E8B-4C3F1F7E9A8E}
AppName={#AppName}
AppVersion={#AppVersion}
DefaultDirName={#RootDir}
DisableDirPage=yes
DisableReadyPage=yes
ArchitecturesInstallIn64BitMode=x64
PrivilegesRequired=admin
OutputBaseFilename=Python-Analytics-Env-Setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
VersionInfoVersion={#AppVersion}
AppCopyright=Your Org
Uninstallable=yes

[Languages]
Name: "en"; MessagesFile: "compiler:Default.isl"

[Files]
; Bundle the payload created by fetch-payload.ps1
Source: "payload\micromamba.exe"; DestDir: "{tmp}"; Flags: ignoreversion
Source: "payload\environment.yml"; DestDir: "{tmp}"; Flags: ignoreversion

[Run]
; Ensure root exists (hidden)
Filename: "{cmd}"; Parameters: "/C mkdir \"\{#RootDir}\""; Flags: runhidden; \
  StatusMsg: "Preparing install directory..."

; Create environment from environment.yml
Filename: "{tmp}\micromamba.exe"; \
  Parameters: "create -y -p \"\{#EnvPath}\" -f \"\{tmp}\environment.yml\""; \
  Flags: runhidden waituntilterminated; \
  StatusMsg: "Creating Python environment (this may take a few minutes)..."

; Register Jupyter kernel using the env’s Python
Filename: "\{#EnvPath}\python.exe"; \
  Parameters: "-m ipykernel install --user --name \{#EnvName\} --display-name \"Python 3.11 (\{#EnvName\})\""; \
  Flags: runhidden waituntilterminated; \
  StatusMsg: "Registering Jupyter kernel..."

; Optional VS Code extensions (if VS Code is installed)
Filename: "{code:FindVSCode}"; \
  Parameters: "--install-extension ms-python.python"; \
  Flags: runhidden waituntilterminated; \
  Check: FileExists(ExpandConstant('{code:FindVSCode}')); \
  StatusMsg: "Installing VS Code Python extension..."

Filename: "{code:FindVSCode}"; \
  Parameters: "--install-extension ms-toolsai.jupyter"; \
  Flags: runhidden waituntilterminated; \
  Check: FileExists(ExpandConstant('{code:FindVSCode}')); \
  StatusMsg: "Installing VS Code Jupyter extension..."

[Icons]
; Optional shortcuts
Name: "{autoprograms}\{#AppName}\JupyterLab (\{#EnvName\})"; \
  Filename: "{#EnvPath}\python.exe"; \
  Parameters: "-m jupyterlab"; \
  WorkingDir: "{#EnvPath}"

[Code]
function FindVSCode(Param: string): string;
var
  Path1, Path2: string;
begin
  Path1 := ExpandConstant('{localappdata}\Programs\Microsoft VS Code\Code.exe');
  Path2 := ExpandConstant('{pf}\Microsoft VS Code\Code.exe');
  if FileExists(Path1) then Result := Path1
  else if FileExists(Path2) then Result := Path2
  else Result := '';
end;
