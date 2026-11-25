@echo off
setlocal EnableExtensions

rem Build, tag and export the development container image.
rem
rem Usage:
rem     build-devcontainer-image.bat <version>

if "%~1"=="" (
    echo Error: Version not specified. 1>&2
    echo Usage: %~nx0 ^<version^> 1>&2
    exit /b 1
)
set "ProjectVersion=%~1"

rem Set variables
if not defined IMAGE_REGISTRY set "IMAGE_REGISTRY=ghcr.io/imesense"
set "ProjectName=git-file-shard-plugin"
set "ProjectTag=%ProjectName%-devcontainer"
set "ProjectOutputImage=%ProjectTag%-%ProjectVersion%-devcontainer-image.tar"

rem Create folders
if not exist "out\%ProjectVersion%" (
    mkdir "out\%ProjectVersion%"
)

rem Get commit timestamp
for /f "delims=" %%i in (
    'git show -s --pretty^=format:%%ct HEAD'
) do set "CommitTimestamp=%%i"
if not defined CommitTimestamp (
    echo Error: Cannot read the commit timestamp from Git. 1>&2
    exit /b 1
)
set "ProjectTimestamp=t%CommitTimestamp%"
echo %ProjectTimestamp%

rem Build devcontainer
docker compose ^
    --file .devcontainer\docker-compose.yaml ^
    --file .devcontainer\docker-compose.build.yaml ^
    --progress=plain ^
    build
if errorlevel 1 (
    echo Error: Image build failed. 1>&2
    exit /b 1
)

rem Tag image
docker tag "%IMAGE_REGISTRY%/%ProjectTag%:latest" "%IMAGE_REGISTRY%/%ProjectTag%:%ProjectTimestamp%"
if errorlevel 1 exit /b 1
docker tag "%IMAGE_REGISTRY%/%ProjectTag%:latest" "%IMAGE_REGISTRY%/%ProjectTag%:%ProjectVersion%"
if errorlevel 1 exit /b 1

rem Export image
docker save ^
    --output "%ProjectOutputImage%" ^
    "%IMAGE_REGISTRY%/%ProjectTag%:latest" ^
    "%IMAGE_REGISTRY%/%ProjectTag%:%ProjectTimestamp%" ^
    "%IMAGE_REGISTRY%/%ProjectTag%:%ProjectVersion%"
if errorlevel 1 (
    echo Error: Image export failed. 1>&2
    exit /b 1
)
move "%ProjectOutputImage%" "out\%ProjectVersion%\%ProjectOutputImage%"
if errorlevel 1 (
    echo Error: Cannot move the image archive to out\%ProjectVersion%\. 1>&2
    exit /b 1
)

endlocal
