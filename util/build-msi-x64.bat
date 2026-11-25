@echo off
rem Convenience wrapper: builds the WiX Toolset 7 MSI installer for x64.
rem
rem Bundling the plugin (PyInstaller) is a separate step that must run
rem beforehand and produce dist\git-file-shard.exe; the build aborts when the
rem payload was built for a different architecture. Extra arguments are
rem forwarded to dotnet build.
rem
rem Usage:
rem     build-msi-x64.bat [extra dotnet build arguments...]

call "%~dp0_build-windows-installer.bat" msi x64 %*
exit /b %ERRORLEVEL%
