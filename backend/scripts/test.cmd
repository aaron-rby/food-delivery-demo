@echo off
cd /d "%~dp0..\.."
call backend\scripts\build.cmd
if errorlevel 1 exit /b 1
java -cp "build;backend\lib\ojdbc6.jar" Phase2Test backend\config\database.properties
exit /b %errorlevel%
