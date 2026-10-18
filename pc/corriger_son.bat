@echo off
setlocal
rem Glisser une ou plusieurs videos sur ce fichier.
rem Decale le son sans reencodage (aucune perte de qualite).
rem Valeur = celle trouvee dans VLC (touches J/K), en ms. Ex: -350 si le son arrive trop tard.

set "FF=ffmpeg"
where ffmpeg >nul 2>nul || set "FF=%LOCALAPPDATA%\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-9.0.2-full_build\bin\ffmpeg.exe"

if "%~1"=="" (
  echo Glisse une video MP4 sur ce fichier.
  pause
  exit /b
)

set /p MS=Delai audio de VLC en ms (ex: -350) :
for /f %%s in ('powershell -NoProfile -Command "[double](%MS%)/1000"') do set "SEC=%%s"

:boucle
if "%~1"=="" goto fin
echo.
echo Correction de %~nx1 (son decale de %MS% ms)...
"%FF%" -v error -stats -y -i "%~1" -itsoffset %SEC% -i "%~1" -map 0:v:0 -map 1:a:0 -c copy -movflags +faststart "%~dpn1_synchro.mp4"
if errorlevel 1 (echo ECHEC pour %~nx1) else (echo OK : %~n1_synchro.mp4)
shift
goto boucle

:fin
echo.
pause
