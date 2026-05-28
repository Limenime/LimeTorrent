@echo off
REM ─────────────────────────────────────────────────────────────────
REM LimeTorrent — Post-Download Logger (Windows Batch)
REM Set via: --post-cmd "C:\scripts\postcmd_log.bat"
REM      or: POST /postcmd/global {"command": "C:\\scripts\\postcmd_log.bat"}
REM ─────────────────────────────────────────────────────────────────

setlocal enabledelayedexpansion

set LOG_DIR=%APPDATA%\.limetorrent\logs
set LOG_FILE=%LOG_DIR%\download_history.log

if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

REM Timestamp from wmic (available on all Windows versions)
for /f "tokens=2 delims==" %%I in (
    'wmic os get localdatetime /value'
) do set DT=%%I
set TIMESTAMP=%DT:~0,4%-%DT:~4,2%-%DT:~6,2% %DT:~8,2%:%DT:~10,2%:%DT:~12,2%

(
    echo ────────────────────────────────────────
    echo   Completed : %TIMESTAMP%
    echo   Name      : %TORRENT_NAME%
    echo   Hash      : %TORRENT_HASH%
    echo   Location  : %TORRENT_SAVE_PATH%
    echo   Total     : %TORRENT_SIZE% bytes
    echo   File count: %TORRENT_FILE_COUNT%
    echo   Api Key   : %LIME_API_KEY%
    echo.

    REM ── Loop per-file using underscore-indexed env vars ──────────
    REM Accessible directly: %TORRENT_LISTFILE_NAME_0%, %TORRENT_LISTFILE_PATH_0%, etc.
    set /a LAST=%TORRENT_FILE_COUNT%-1
    for /l %%i in (0,1,!LAST!) do (
        echo   [%%i] Name : !TORRENT_LISTFILE_NAME_%%i!
        echo        Path : !TORRENT_LISTFILE_PATH_%%i!
        echo        Size : !TORRENT_LISTFILE_SIZE_%%i! bytes
    )

    echo.
) >> "%LOG_FILE%"

echo [postcmd] Log written to: %LOG_FILE%
endlocal
