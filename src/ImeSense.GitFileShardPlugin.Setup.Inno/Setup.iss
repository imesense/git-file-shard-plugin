#define MyAppName "ImeSense Git File Shard Plugin"
#define MyAppVersion "0.1"
#define MyAppPublisher "ImeSense"
#define MyAppURL "https://github.com/imesense/git-file-shard-plugin/"
#define MyAppExeName "git-file-shard.exe"
#define EscapeConstArgument(Value) StringChange(StringChange(StringChange(Value, "%", "%25"), ",", "%2c"), "}", "%7d")

[Setup]
AppId={{359E3F55-6620-4D88-B376-1636D7719F0A}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
;AppVerName={cm:NameAndVersion,{#EscapeConstArgument(MyAppName)},{#EscapeConstArgument(MyAppVersion)}}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\ImeSense\Git File Shard Plugin
UninstallDisplayIcon={app}\bin\{#MyAppExeName}
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
;SetupArchitecture=x64
DisableProgramGroupPage=yes
LicenseFile=..\..\LICENSE.txt
;PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=commandline
OutputDir=..\..\bin
OutputBaseFilename=GitFileShardPlugin
SolidCompression=yes
WizardStyle=modern dynamic

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl,Locales\Options.eng.isl"
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl,Locales\Options.rus.isl"

[Tasks]
Name: "addtopath"; Description: "{cm:TaskAddToPathDescription}"; GroupDescription: "{cm:TaskGroupDescription}"

[Files]
Source: "..\..\dist\{#MyAppExeName}"; DestDir: "{app}\bin"; Flags: ignoreversion
Source: "..\..\README.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\LICENSE.txt"; DestDir: "{app}"; Flags: ignoreversion

[Code]
const
    PathEnvironmentVariable = 'Path';
    PathSubkey = 'System\CurrentControlSet\Control\Session Manager\Environment';
    PathSeparator = ';';
    WM_SETTINGCHANGE = $001A;
    SMTO_ABORTIFHUNG = $0002;

{ Setup does not expose `SendMessageTimeout`, and `SendNotifyMessage` is unsafe
    for `WM_SETTINGCHANGE` broadcasts: the string in `lParam` may be freed before
    a receiving process reads it. Importing the API directly follows
    KB article 104011, like Setup itself does. }
function SendMessageTimeout(hWnd: HWND; Msg: UINT; wParam: WPARAM;
    lParam: String; fuFlags: UINT; uTimeout: UINT;
    var lpdwResult: DWORD_PTR): LRESULT;
    external 'SendMessageTimeoutW@user32.dll stdcall';

procedure RefreshEnvironment;
{ Notifies running applications (including Explorer) that environment
    variables have changed, so the updated PATH is picked up without a
    logoff or reboot. }
var
    MsgResult: DWORD_PTR;
begin
    SendMessageTimeout(HWND_BROADCAST, WM_SETTINGCHANGE, 0,
        'Environment', SMTO_ABORTIFHUNG, 5000, MsgResult);
end;

procedure GetPathValue(out Path: String; out PathExists: Boolean);
{ Reads the current PATH value. Both `REG_SZ` and `REG_EXPAND_SZ` types are
    accepted to not miss the entry if the value was not yet converted to
    `REG_EXPAND_SZ`. }
begin
    PathExists := RegQueryStringValue(HKA, PathSubkey, PathEnvironmentVariable, Path);
end;

procedure SetPathValue(const Path: String);
{ Writes the PATH value back as `REG_EXPAND_SZ` so entries like `%SystemRoot%`
    keep working after a manual edit. }
begin
    if not RegWriteExpandStringValue(HKA, PathSubkey, PathEnvironmentVariable, Path) then
        RaiseException('Failed to write the PATH environment variable value.');
end;

function PathEntry: String;
{ Returns `bin` folder of the application, the only PATH entry managed
    by this installer. }
begin
    Result := AddBackslash(ExpandConstant('{app}')) + 'bin';
end;

function PathEntriesToString(const Entries: TArrayOfString): String;
{ Joins PATH entries back into a single semicolon-separated value. }
var
    I: Integer;
begin
    Result := '';
    for I := 0 to GetArrayLength(Entries) - 1 do begin
        if I > 0 then
            Result := Result + PathSeparator;
        Result := Result + Entries[I];
    end;
end;

procedure StringToPathEntries(const Path: String; var Entries: TArrayOfString);
{ Splits PATH into entries and drops every occurrence of the application's
    bin folder, so it can be re-added exactly once. All other entries are
    preserved as-is. }
var
    Parts, NormalizedParts: TArrayOfString;
    I: Integer;
begin
    Parts := StringSplit(Path, [PathSeparator], stExcludeEmpty);
    SetArrayLength(NormalizedParts, 0);
    for I := 0 to GetArrayLength(Parts) - 1 do begin
        if not SameText(AddBackslash(Parts[I]), AddBackslash(PathEntry)) then begin
            SetArrayLength(NormalizedParts, GetArrayLength(NormalizedParts) + 1);
            NormalizedParts[GetArrayLength(NormalizedParts) - 1] := Parts[I];
        end;
    end;
    Entries := NormalizedParts;
end;

procedure UpdatePath(const AddEntry: Boolean);
{ Adds `bin` folder of the application to or removes it from PATH,
    keeping all other entries untouched. The write is skipped when the
    resulting value would be the same, to avoid touching the registry
    needlessly. }
var
    Path: String;
    PathExists: Boolean;
    Entries: TArrayOfString;
    NewPath: String;
begin
    GetPathValue(Path, PathExists);
    if not PathExists then
        Path := '';

    StringToPathEntries(Path, Entries);
    if AddEntry then begin
        SetArrayLength(Entries, GetArrayLength(Entries) + 1);
        Entries[GetArrayLength(Entries) - 1] := PathEntry;
    end;

    NewPath := PathEntriesToString(Entries);
    if NewPath <> Path then
        SetPathValue(NewPath);
end;

procedure CurStepChanged(CurStep: TSetupStep);
{ Setup event: once installation has finished, adds the bin folder to PATH
    when the addtopath task is selected and notifies running applications
    about the environment change. }
begin
    if CurStep = ssPostInstall then begin
        if WizardIsTaskSelected('addtopath') then begin
            UpdatePath(True);
            RefreshEnvironment;
        end;
    end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
{ Uninstall event: removes `bin` folder from PATH when uninstall starts,
    while the application folder still exists. }
begin
    if CurUninstallStep = usUninstall then
        UpdatePath(False);
end;
