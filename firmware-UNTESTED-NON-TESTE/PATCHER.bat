@echo off
rem Glisse le Thumb2.bin officiel V1.2.2 sur ce fichier / Drag the official V1.2.2 Thumb2.bin onto this file.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0patcher_firmware.ps1" "%~1"
pause
