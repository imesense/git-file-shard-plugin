@echo off
rem Internal helper shared by the architecture-specific Windows installer
rem wrappers. Builds the Inno Setup EXE or the WiX MSI installer for the
rem requested architecture and aborts when the PyInstaller payload was built
rem for a different architecture. Call it through build-exe-<arch>.bat or
rem build-msi-<arch>.bat instead of using it directly.
rem
rem Bundling the plugin (PyInstaller) is a separate step that must run
rem beforehand and produce dist\git-file-shard.exe.
rem
rem Usage:
rem     _build-windows-installer.bat ^<exe^|msi^> ^<x64^|arm64^> [extra arguments...]

setlocal EnableExtensions

set "REPO_ROOT=%~dp0.."
for %%I in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fI"

set "TARGET=%~1"
set "ARCH=%~2"
if not defined TARGET goto usage
if not defined ARCH goto usage

rem Forward everything after the two leading arguments verbatim: %1 splits on
rem "=", so the tail must come from %*.
set "EXTRA="
for /f "tokens=1,2*" %%A in ("%*") do set "EXTRA=%%C"

if /I not "%TARGET%"=="exe" if /I not "%TARGET%"=="msi" (
    echo Error: unsupported installer target "%TARGET%"; expected exe or msi. 1>&2
    exit /b 1
)
if /I not "%ARCH%"=="x64" if /I not "%ARCH%"=="arm64" (
    echo Error: unsupported architecture "%ARCH%"; expected x64 or arm64. 1>&2
    exit /b 1
)
if /I "%TARGET%"=="exe" set "TARGET=exe"
if /I "%TARGET%"=="msi" set "TARGET=msi"
if /I "%ARCH%"=="x64" set "ARCH=x64"
if /I "%ARCH%"=="arm64" set "ARCH=arm64"

call :require_file "%REPO_ROOT%\dist\git-file-shard.exe" "dist\git-file-shard.exe" || exit /b 1
call :require_file "%REPO_ROOT%\README.md" "README.md" || exit /b 1
call :require_file "%REPO_ROOT%\LICENSE.txt" "LICENSE.txt" || exit /b 1

set "PAYLOAD_ARCH="
for /f "usebackq delims=" %%A in (`powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%REPO_ROOT%\util\detect-payload-arch.ps1" "%REPO_ROOT%\dist\git-file-shard.exe"`) do set "PAYLOAD_ARCH=%%A"
if not defined PAYLOAD_ARCH (
    echo Error: failed to detect the architecture of dist\git-file-shard.exe. 1>&2
    exit /b 1
)

if /I not "%ARCH%"=="%PAYLOAD_ARCH%" (
    echo Error: dist\git-file-shard.exe is built for %PAYLOAD_ARCH%, not %ARCH%. 1>&2
    echo Build the payload for %ARCH% on a matching host. 1>&2
    exit /b 1
)

if /I "%TARGET%"=="exe" goto build_exe
goto build_msi

:build_exe
rem Prefer the default Inno Setup 7 install location, then fall back to PATH.
set "ISCC="
if exist "%ProgramFiles%\Inno Setup 7\ISCC.exe" set "ISCC=%ProgramFiles%\Inno Setup 7\ISCC.exe"
if not defined ISCC for %%I in (ISCC.exe) do if not "%%~$PATH:I"=="" set "ISCC=%%~$PATH:I"
if not defined ISCC (
    echo Error: ISCC.exe not found. Install Inno Setup 7 or add it to PATH. 1>&2
    exit /b 1
)

"%ISCC%" "%REPO_ROOT%\src\installer_windows_inno\Setup.iss" "/DArch=%ARCH%" %EXTRA%
if errorlevel 1 exit /b 1

echo Built %REPO_ROOT%\bin\GitFileShardPlugin.%ARCH%.exe
exit /b 0

:build_msi
where dotnet >nul 2>&1
if errorlevel 1 (
    echo Error: dotnet not found on PATH. Install the .NET 8 SDK or add it to PATH. 1>&2
    exit /b 1
)

dotnet build "%REPO_ROOT%\src\installer_windows_wix\GitFileShard.Installer.Wix.wixproj" -c Release -p:Platform=%ARCH% -o "%REPO_ROOT%\bin" %EXTRA%
if errorlevel 1 exit /b 1

echo Built %REPO_ROOT%\bin\en-US\GitFileShardPlugin.%ARCH%.msi and %REPO_ROOT%\bin\ru-RU\GitFileShardPlugin.%ARCH%.msi
exit /b 0

:usage
echo Usage: %~nx0 ^<exe^|msi^> ^<x64^|arm64^> [extra arguments...] 1>&2
exit /b 1

:require_file
if exist "%~1" exit /b 0
echo Error: %~2 not found. Build the plugin first: 1>&2
echo     uv run --locked pyinstaller git-file-shard.spec --noconfirm 1>&2
exit /b 1
