@echo off
setlocal
if exist "%~dp0\.mvn\apache-maven\bin\mvn.cmd" (
  "%~dp0\.mvn\apache-maven\bin\mvn.cmd" %*
  exit /b %ERRORLEVEL%
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0\.mvn\bootstrap-maven.ps1" %*
exit /b %ERRORLEVEL%
