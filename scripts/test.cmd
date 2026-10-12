@echo off
cd /d "%~dp0.."
call scripts\build.cmd
if errorlevel 1 exit /b 1
java -cp "build;lib\ojdbc6.jar" Phase2Test config\database.properties
exit /b %errorlevel%
