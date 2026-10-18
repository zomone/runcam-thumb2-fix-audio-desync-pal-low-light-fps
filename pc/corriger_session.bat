@echo off
rem Glisser le dossier DCIM\100MEDIA (ou des fichiers MP4) sur ce fichier.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0corriger_session.ps1" %*
pause
