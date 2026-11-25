@echo off
rem Convenience wrapper: builds the Inno Setup 7 EXE installer for arm64.
rem
rem Bundling the plugin (PyInstaller) is a separate step that must run
rem beforehand and produce dist\git-file-shard.exe; the build aborts when the
rem payload was built for a different architecture. Extra arguments are
rem forwarded to ISCC.exe (for example /DMyAppVersion=1.2.3).
rem
rem Usage:
rem     build-exe-arm64.bat [extra ISCC.exe arguments...]

call "%~dp0_build-windows-installer.bat" exe arm64 %*
exit /b %ERRORLEVEL%
